local TowerSystem = {}
TowerSystem.__index = TowerSystem

-- Services
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerScriptService")
local SStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")

-- Modules
local TowerConfig = require(RS.Configs.TowerConfig)
local EnemyConfig = require(SS.Configs.EnemyConfig)
local Network = require(RS.Network)
local GameConfig = require(SS.Configs.GameConfig)
local HttpService = game:GetService("HttpService")

-- Constants
local TARGET_INTERVAL = 0.5

-- Debugging
local DEBUG = true
local function print(msg: string)
	if DEBUG then
		warn(`[TowerSystem]: {msg}`)
	end
end

function TowerSystem:Init(framework)
	self.framework = framework
	self.towers = {}
	self.towersFolder = Workspace:FindFirstChild("Towers") or Instance.new("Folder")
	self.towersFolder.Name = "Towers"
	self.towersFolder.Parent = Workspace

	-- Listen for placement requests
	Network.PlaceTower:OnEvent(function(player, data)
		self:HandlePlaceTower(player, data.TowerName, data.Position)
	end)
	-- Upgrade Request
	Network.RequestUpgrade:OnEvent(function(requestingPlayer, data)
		local waveSystem = self.framework.systems["WaveSystem"]
		if not waveSystem then return end

		local towerData = nil
		for _, t in ipairs(self.towers) do
			if t.Id == data.TowerId then
				towerData = t
				break
			end
		end

		if not towerData then return end
		local config = towerData.Config
		local currentLevel = towerData.Level
		local nextLevel = currentLevel + 1

		if nextLevel > #config.Levels then
			Network.Notify:FireClient(requestingPlayer, { Message = "Already at max level!", Type = "Error" })
			return
		end

		local upgradeCost = config.Levels[currentLevel].UpgradeCost
		if waveSystem.coins < upgradeCost then
			Network.Notify:FireClient(requestingPlayer, { Message = `Not enough coins! (Need {upgradeCost})`, Type = "Error" })
			return
		end

		-- Apply Upgrade
		waveSystem:AddCoins(-upgradeCost)
		towerData.Level = nextLevel
		towerData.Instance:SetAttribute("Level", nextLevel)
		
		warn(`[TowerSystem] Upgrade: {config.Name} -> Lv {nextLevel} (Player: {requestingPlayer.Name})`)
		Network.Notify:FireClient(requestingPlayer, { Message = `{config.Name} upgraded to Level {nextLevel}!`, Type = "Success" })
	end)

	-- Sell Request
	Network.RequestSell:OnEvent(function(player, data)
		local waveSystem = self.framework.systems["WaveSystem"]
		if not waveSystem then return end

		local foundIdx, towerData = nil, nil
		for i, t in ipairs(self.towers) do
			if t.Id == data.TowerId then
				foundIdx, towerData = i, t
				break
			end
		end

		if not towerData then return end

		-- Calculate Refund (70% total investment)
		local totalInvested = towerData.Config.Cost
		for lv = 1, towerData.Level - 1 do
			totalInvested += towerData.Config.Levels[lv].UpgradeCost
		end
		local refundAmount = math.floor(totalInvested * 0.7)

		-- Execute Sell
		waveSystem:AddCoins(refundAmount)
		if towerData.Instance then towerData.Instance:Destroy() end
		table.remove(self.towers, foundIdx)

		-- Broadcast & Notify
		Network.TowerRemoved:FireAllClients({ TowerId = data.TowerId })
		warn(`[TowerSystem] Sell: {towerData.Config.Name} (+{refundAmount} Coins)`)
		Network.Notify:FireClient(player, { Message = `{towerData.Config.Name} sold for {refundAmount} coins!`, Type = "Success" })
	end)
end

function TowerSystem:Start()
	-- Main loop for tower combat
	task.spawn(function()
		while true do
			local dt = task.wait(0.1)
			self:UpdateTowers(dt)
		end
	end)
end

function TowerSystem:HandlePlaceTower(player: Player, towerName: string, position: Vector3)
	local config = TowerConfig[towerName]
	if not config then
		return
	end

	-- Check Max Towers (Global)
	local currentTowerCount = #self.towers
	if currentTowerCount >= (GameConfig.MaxTowers or 25) then
		Network.Notify:FireClient(player, {
			Message = "Global tower limit reached!",
			Type = "Error",
		})
		return
	end

	-- Check Max Towers (Per Type)
	local typeCount = 0
	for _, t in ipairs(self.towers) do
		if t.Config.Name == towerName then
			typeCount += 1
		end
	end
	if typeCount >= (config.MaxInstances or 99) then
		Network.Notify:FireClient(player, {
			Message = `Max {towerName} towers reached! ({config.MaxInstances})`,
			Type = "Error",
		})
		return
	end

	-- Check coins
	local waveSystem = self.framework.systems["WaveSystem"]
	if not waveSystem then
		return
	end

	if waveSystem.coins < config.Cost then
		Network.Notify:FireClient(player, {
			Message = `Not enough coins! (Need {config.Cost})`,
			Type = "Error",
		})
		print("Not enough coins to place " .. towerName)
		return
	end

	-- Validate placement surface (Must be on Workspace/Base/Land)
	local land = Workspace:FindFirstChild("Base") and Workspace.Base:FindFirstChild("Land")
	local rayParams = RaycastParams.new()
	rayParams.FilterType = Enum.RaycastFilterType.Include
	rayParams.FilterDescendantsInstances = { if land then land else Workspace }

	local rayResult = Workspace:Raycast(position + Vector3.new(0, 5, 0), Vector3.new(0, -10, 0), rayParams)
	if not rayResult or not land or not (rayResult.Instance == land or rayResult.Instance:IsDescendantOf(land)) then
		print(`Invalid placement for {towerName} - Not on Land`)
		return
	end

	-- Place tower
	local towerModel = self:GetTowerTemplate(towerName)
	print(towerModel)
	if not towerModel then
		-- Fallback to a placeholder part if model is missing
		towerModel = Instance.new("Part")
		towerModel.Name = towerName
		towerModel.Size = Vector3.new(4, 6, 4)
		towerModel.Anchored = true
		towerModel.BrickColor = BrickColor.new("Bright yellow")
	else
		towerModel = towerModel:Clone()
	end

	local yOffset = 0
	if towerModel:IsA("Model") then
		local _, size = towerModel:GetBoundingBox()
		yOffset = size.Y / 2
	else
		yOffset = towerModel.Size.Y / 2
	end

	local targetCFrame = CFrame.new(position + Vector3.new(0, yOffset, 0))

	-- Server-side Overlap Check (Security)
	local overlapParams = OverlapParams.new()
	overlapParams.FilterType = Enum.RaycastFilterType.Include
	overlapParams.FilterDescendantsInstances = { self.towersFolder }
	local overlapParts = Workspace:GetPartBoundsInBox(targetCFrame, towerModel:GetExtentsSize(), overlapParams)

	if #overlapParts > 0 then
		print(`Invalid placement for {towerName} - Overlapping another tower`)
		towerModel:Destroy()
		return
	end

	towerModel:PivotTo(targetCFrame)

	-- Set Collision Group
	for _, obj in ipairs(towerModel:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.CollisionGroup = "Towers"
		end
	end
	if towerModel:IsA("BasePart") then
		towerModel.CollisionGroup = "Towers"
	end

	towerModel.Parent = self.towersFolder

	-- Deduct coins
	waveSystem:AddCoins(-config.Cost)

	-- Add to active towers
	-- Set initial level attribute
	local towerId = HttpService:GenerateGUID(false)
	towerModel:SetAttribute("Level", 1)
	towerModel:SetAttribute("TowerId", towerId)

	local towerData = {
		Id = towerId,
		Instance = towerModel,
		Config = config,
		Level = 1,
		NextShotTime = 0,
		Target = nil,
	}
	table.insert(self.towers, towerData)

	-- Broadcast placement to all clients for World UI
	Network.TowerPlaced:FireAllClients({
		TowerInstance = towerModel,
		TowerName = towerName,
		TowerId = towerId,
	})

	warn(`[TowerSystem] Player {player.Name} placed {towerName} (ID: {towerId})`)
end

function TowerSystem:GetTowerTemplate(name: string): Model?
	local towersFolder = SStorage:FindFirstChild("Towers")
	if not towersFolder then
		return nil
	end
	return towersFolder:FindFirstChild(name)
end

local function getDistance2D(p1: Vector3, p2: Vector3)
	return (Vector2.new(p1.X, p1.Z) - Vector2.new(p2.X, p2.Z)).Magnitude
end

function TowerSystem:GetClosestTarget(position: Vector3, range: number): Model?
	local closestDist = range
	local closestTarget = nil

	for _, mob in ipairs(Workspace:GetChildren()) do
		if mob:GetAttribute("IsMob") and mob:FindFirstChild("HumanoidRootPart") then
			local dist = getDistance2D(mob.HumanoidRootPart.Position, position)
			if dist < closestDist then
				closestDist = dist
				closestTarget = mob
			end
		end
	end

	return closestTarget
end

function TowerSystem:UpdateTowers(dt: number)
	local now = tick()

	for _, tower in ipairs(self.towers) do
		local levelConfig = tower.Config.Levels[tower.Level]
		local towerPos = tower.Instance:GetPivot().Position

		-- Find target if needed
		local currentTarget = tower.Target
		local targetPos = if currentTarget and currentTarget:FindFirstChild("HumanoidRootPart")
			then currentTarget.HumanoidRootPart.Position
			else if currentTarget then currentTarget:GetPivot().Position else nil

		if
			not currentTarget
			or not currentTarget.Parent
			or (targetPos and getDistance2D(targetPos, towerPos) > levelConfig.Range)
		then
			tower.Target = self:GetClosestTarget(towerPos, levelConfig.Range)
		end

		-- Attack
		if tower.Target and now >= tower.NextShotTime then
			self:FireTower(tower)
			tower.NextShotTime = now + levelConfig.FireRate
		end
	end
end

function TowerSystem:FireTower(tower)
	local target = tower.Target
	if not target then
		return
	end

	-- Check for custom modular logic inside ServerScriptService.TowerLogic
	local towerLogicFolder = SS:FindFirstChild("TowerLogic")
	local logicModule = towerLogicFolder and towerLogicFolder:FindFirstChild(tower.Config.Name)

	if logicModule and logicModule:IsA("ModuleScript") then
		local success, Logic = pcall(require, logicModule)
		if success and Logic.Fire then
			local waveSystem = self.framework.systems["WaveSystem"]
			Logic.Fire(tower, target, waveSystem)
			return
		end
	end

	local config = tower.Config
	local levelConfig = config.Levels[tower.Level]
	local towerPos = tower.Instance:GetPivot().Position
	local centerPos = if config.AoECenter == "Tower" then towerPos else target:GetPivot().Position

	if config.AttackType == "AoE" then
		-- Area of Effect Damage
		local radius = config.BlastRadius or 10
		local hitCount = 0

		for _, mob in ipairs(Workspace:GetChildren()) do
			if mob:GetAttribute("IsMob") then
				local humanoid = mob:FindFirstChildOfClass("Humanoid")
				local hrp = mob:FindFirstChild("HumanoidRootPart")

				if humanoid and hrp then
					local dist = getDistance2D(hrp.Position, centerPos)
					if dist <= radius then
						humanoid:TakeDamage(levelConfig.Damage)

						-- Reward logic
						local enemyCfg = EnemyConfig[mob.Name]
						if enemyCfg then
							local rewardPerDamage = enemyCfg.Reward / enemyCfg.Health
							WaveSystem:AddCoins(levelConfig.Damage * rewardPerDamage)
						end
						hitCount += 1
					end
				end
			end
		end
		print(`[TowerSystem] {config.Name} (Lv {tower.Level}) AoE hit {hitCount} targets (DMG: {levelConfig.Damage})`)
	else
		-- Single Target Damage
		local humanoid = target:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:TakeDamage(levelConfig.Damage)

			-- Gradual Reward Logic
			local enemyCfg = EnemyConfig[target.Name]
			if enemyCfg then
				local rewardPerDamage = enemyCfg.Reward / enemyCfg.Health
				WaveSystem:AddCoins(levelConfig.Damage * rewardPerDamage)
			end
		end
	end

	-- Visuals
	Network.TowerShoot:FireAllClients({
		From = tower.Instance:GetPivot().Position + Vector3.new(0, 3, 0),
		To = centerPos,
		TowerName = config.Name,
		TowerInstance = tower.Instance,
	})
end

return TowerSystem
