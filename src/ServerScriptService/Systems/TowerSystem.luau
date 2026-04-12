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
local WaveSystem = require(SS.Systems.WaveSystem)

-- Constants
local TARGET_INTERVAL = 0.5

-- Debugging
local DEBUG = true
local function print(msg: string)
	if DEBUG then
		warn(`[TowerSystem]: {msg}`)
	end
end

function TowerSystem:Init()
	self.towers = {}
	self.towersFolder = Workspace:FindFirstChild("Towers") or Instance.new("Folder")
	self.towersFolder.Name = "Towers"
	self.towersFolder.Parent = Workspace

	-- Listen for placement requests
	Network.PlaceTower:OnEvent(function(player, data)
		self:HandlePlaceTower(player, data.TowerName, data.Position)
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

	-- Check coins (Assuming WaveSystem has a way to check/spend coins)
	if WaveSystem.coins < config.Cost then
		print("Not enough coins to place " .. towerName)
		return
	end

	-- Simple collision check (optional, but good for base logic)
	-- For a real TD, you'd use a grid or raycast check on the client

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

	towerModel:PivotTo(CFrame.new(position + Vector3.new(0, yOffset, 0)))
	towerModel.Parent = self.towersFolder

	-- Deduct coins
	WaveSystem:AddCoins(-config.Cost)

	-- Add to active towers
	local towerData = {
		Instance = towerModel,
		Config = config,
		NextShotTime = 0,
		Target = nil,
	}
	table.insert(self.towers, towerData)

	print(`Player {player.Name} placed {towerName}`)
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
		local towerPos = tower.Instance:GetPivot().Position

		-- Find target if needed
		if
			not tower.Target
			or not tower.Target.Parent
			or getDistance2D(tower.Target:GetPivot().Position, towerPos) > tower.Config.Range
		then
			tower.Target = self:GetClosestTarget(towerPos, tower.Config.Range)
		end

		-- Attack
		if tower.Target and now >= tower.NextShotTime then
			self:FireTower(tower)
			tower.NextShotTime = now + tower.Config.FireRate
		end
	end
end

function TowerSystem:FireTower(tower)
	local target = tower.Target
	if not target then
		return
	end

	local config = tower.Config
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
						humanoid:TakeDamage(config.Damage)

						-- Reward logic
						local enemyCfg = EnemyConfig[mob.Name]
						if enemyCfg then
							local rewardPerDamage = enemyCfg.Reward / enemyCfg.Health
							WaveSystem:AddCoins(config.Damage * rewardPerDamage)
						end
						hitCount += 1
					end
				end
			end
		end
		print(`[TowerSystem] {config.Name} AoE at {config.AoECenter} hit {hitCount} targets (Radius: {radius})`)
	else
		-- Single Target Damage
		local humanoid = target:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid:TakeDamage(config.Damage)

			-- Gradual Reward Logic
			local enemyCfg = EnemyConfig[target.Name]
			if enemyCfg then
				local rewardPerDamage = enemyCfg.Reward / enemyCfg.Health
				WaveSystem:AddCoins(config.Damage * rewardPerDamage)
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
