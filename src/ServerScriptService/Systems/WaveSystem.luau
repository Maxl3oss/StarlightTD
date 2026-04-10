local WaveSystem = {}
WaveSystem.__index = WaveSystem

-- Services
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerScriptService")
local SStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Base = Workspace:WaitForChild("Base")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

-- Modules
local WaveConfig = require(RS.Configs.WaveConfig)
local EnemyConfig = require(RS.Configs.EnemyConfig)
local GameConfig = require(RS.Configs.GameConfig)
local Network = require(RS.Network)
local ProfileStoreSystem = require(SS.Systems.ProfileStoreSystem)

-- Constants
local COUNTDOWN_DURATION = 10 -- Seconds between waves

-- ========== Framework Lifecycle ==========

function WaveSystem:Init()
	-- Cache folder references once
	self.waypointsFolder = Base:FindFirstChild("Waypoints") or Base:WaitForChild("Waypoints", 5)

	if not self.waypointsFolder then
		warn("[WaveSystem]: Waypoints folder not found in Base! Creating a temporary one.")
		self.waypointsFolder = Instance.new("Folder")
		self.waypointsFolder.Name = "Waypoints"
		self.waypointsFolder.Parent = Base
	end

	self.mobsFolder = SStorage:WaitForChild("Mobs")
	self.towerCore = Base:FindFirstChild("TowerCore") or Base:WaitForChild("TowerCore", 5)

	-- Gameplay State
	self.currentWave = 0
	self.isWaveRunning = false
	self.isWaveSpawning = false
	self.enemiesInWave = 0
	self.totalWaves = #WaveConfig
	self.countdown = 0
	self.isGameOver = false

	self.baseMaxHealth = GameConfig.BaseMaxHealth or 100
	self.baseHealth = self.baseMaxHealth

	self.coins = GameConfig.StartingCoins or 300

	-- Network Listeners
	Network.RequestWave.listen(function(_, player)
		self:BroadcastState(player)
		self:BroadcastHealth(player)
		self:BroadcastCoins(player)
	end)

	Network.RequestNextWave.listen(function(_, player)
		self:NextWave()
	end)

	Network.RestartGame.listen(function(_, player)
		self:RestartGame()
	end)
end

function WaveSystem:Start()
	self:BroadcastHealth()
	self:BroadcastCoins()

	if self.towerCore then
		self:CreateBillboardHP(self.towerCore, self.baseHealth, self.baseMaxHealth, "CoreHP", "BASE CORE")
	end

	self:StartCountdown(1)
end

-- ========== Internal Methods ==========

function WaveSystem:BroadcastState(targetPlayer: Player?)
	local data = {
		Wave = self.currentWave,
		IsRunning = self.isWaveRunning,
		Countdown = math.max(0, math.floor(self.countdown)),
	}

	if targetPlayer then
		Network.UpdateWave.sendTo(data, targetPlayer)
	else
		for _, player in ipairs(Players:GetPlayers()) do
			Network.UpdateWave.sendTo(data, player)
		end
	end
end

function WaveSystem:BroadcastHealth(targetPlayer: Player?)
	local data = {
		Health = self.baseHealth,
		MaxHealth = self.baseMaxHealth,
	}

	if targetPlayer then
		Network.UpdateBaseHealth.sendTo(data, targetPlayer)
	else
		for _, player in ipairs(Players:GetPlayers()) do
			Network.UpdateBaseHealth.sendTo(data, player)
		end
	end

	-- Update World Billboard if exists
	if self.towerCore then
		local billboard = self.towerCore:FindFirstChild("CoreHP", true)
		if billboard then
			-- print(`[WaveSystem]: Updating world billboard CoreHP to {self.baseHealth}`)
			self:UpdateBillboardHP(billboard, self.baseHealth, self.baseMaxHealth)
		else
			-- warn(`[WaveSystem]: Could not find CoreHP billboard in {self.towerCore:GetFullName()}`)
		end
	end
end

function WaveSystem:BroadcastCoins(targetPlayer: Player?)
	local data = {
		Coins = self.coins,
	}

	if targetPlayer then
		Network.UpdateCoins.sendTo(data, targetPlayer)
	else
		for _, player in ipairs(Players:GetPlayers()) do
			Network.UpdateCoins.sendTo(data, player)
		end
	end
end

function WaveSystem:CreateBillboardHP(
	adornee: Instance,
	health: number,
	maxHealth: number,
	name: string,
	displayName: string?
)
	local part = adornee:IsA("Model") and (adornee.PrimaryPart or adornee:FindFirstChildWhichIsA("BasePart")) or adornee
	if not part then
		return
	end

	-- Calculate size based on the model if applicable
	local scaleMultiplier = 1
	local heightOffset = 3.5
	if adornee:IsA("Model") then
		local extents = adornee:GetExtentsSize()
		scaleMultiplier = math.clamp(extents.X / 4, 0.8, 2.5) -- Scaled relative to a ~4 stud wide model
		heightOffset = extents.Y + 1.5
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = name
	billboard.Adornee = part
	billboard.Size = UDim2.fromOffset(60 * scaleMultiplier, 25 * scaleMultiplier)
	billboard.StudsOffset = Vector3.new(0, heightOffset, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 150
	billboard.Parent = part

	-- Main Container (HP Bar)
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(0.8, 0, 0.3, 0) -- Scaled inside the billboard
	background.Position = UDim2.fromScale(0.5, 1)
	background.AnchorPoint = Vector2.new(0.5, 1)
	background.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	background.BackgroundTransparency = 0.2
	background.BorderSizePixel = 0
	background.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = background

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = background

	-- HP Fill
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(math.clamp(health / maxHealth, 0, 1), 1)
	fill.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
	fill.BorderSizePixel = 0
	fill.ZIndex = 2
	fill.Parent = background

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = fill

	-- Glassy Shine Effect
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.Size = UDim2.new(1, 0, 0.4, 0)
	shine.Position = UDim2.fromScale(0, 0)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.8
	shine.BorderSizePixel = 0
	shine.ZIndex = 3
	shine.Parent = background

	local shineCorner = Instance.new("UICorner")
	shineCorner.CornerRadius = UDim.new(0, 4)
	shineCorner.Parent = shine

	-- Text HP
	local text = Instance.new("TextLabel")
	text.Name = "HPText"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.ZIndex = 4
	text.TextScaled = true
	text.Font = Enum.Font.FredokaOne
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0.4
	text.Text = string.format("%d / %d", health, maxHealth)
	text.Parent = background -- Put inside background to align with bar

	-- Name Label
	if displayName then
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(1, 0, 0, 12)
		nameLabel.Position = UDim2.new(0.5, 0, 0, 0)
		nameLabel.AnchorPoint = Vector2.new(0.5, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = displayName
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.Font = Enum.Font.FredokaOne
		nameLabel.TextSize = 10
		nameLabel.TextStrokeTransparency = 0.5
		nameLabel.Parent = billboard
	end

	return billboard
end

function WaveSystem:UpdateBillboardHP(billboard: BillboardGui, health: number, maxHealth: number)
	local background = billboard:FindFirstChild("Background")
	if not background then
		warn(`[WaveSystem]: UpdateBillboardHP failed - Background missing in {billboard:GetFullName()}`)
		return
	end

	local fill = background:FindFirstChild("Fill")
	local text = background:FindFirstChild("HPText") -- Fixed: inside background
	if not fill or not text then
		warn(`[WaveSystem]: UpdateBillboardHP failed - Fill or Text missing in {billboard:GetFullName()}`)
		return
	end

	local ratio = math.clamp(health / maxHealth, 0, 1)

	-- Tween bar (ลื่น)
	TweenService:Create(fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(ratio, 1),
	}):Play()

	-- Update text
	text.Text = string.format("%d / %d", math.floor(health), maxHealth)

	-- Hit effect (เด้งนิด ๆ)
	local originalScale = background.Size
	local popScale = UDim2.new(originalScale.X.Scale + 0.1, 0, originalScale.Y.Scale + 0.1, 0)

	local pop = TweenService:Create(background, TweenInfo.new(0.08), {
		Size = popScale,
	})
	local back = TweenService:Create(background, TweenInfo.new(0.08), {
		Size = originalScale,
	})

	pop:Play()
	pop.Completed:Connect(function()
		back:Play()
	end)
end

function WaveSystem:HandleGameOver()
	if self.isGameOver then
		return
	end
	self.isGameOver = true
	self.isWaveRunning = false
	self.isWaveSpawning = false

	-- Destroy all active mobs
	for _, mob in ipairs(Workspace:GetChildren()) do
		if mob:GetAttribute("IsMob") then
			mob:Destroy()
		end
	end

	for _, player in ipairs(Players:GetPlayers()) do
		Network.GameOver.sendTo({ Won = false, Reset = false }, player)
	end
	print("[WaveSystem]: GAME OVER - Base Destroyed")
end

function WaveSystem:HandleVictory()
	if self.isGameOver then
		return
	end
	self.isGameOver = true
	self.isWaveRunning = false
	self.isWaveSpawning = false

	-- Grant global Cash reward for winning the game
	for _, player in ipairs(Players:GetPlayers()) do
		ProfileStoreSystem:AddCash(player, GameConfig.VictoryCashReward or 100)
		Network.GameOver.sendTo({ Won = true, Reset = false }, player)
	end
	print("[WaveSystem]: VICTORY - All waves cleared")
end

function WaveSystem:RestartGame()
	print("[WaveSystem]: Restarting game...")

	-- Reset state
	self.isGameOver = false
	self.currentWave = 0
	self.isWaveRunning = false
	self.isWaveSpawning = false
	self.enemiesInWave = 0
	self.baseHealth = self.baseMaxHealth
	self.coins = GameConfig.StartingCoins or 300
	self.countdown = 0

	-- Destroy all old mobs just in case
	for _, mob in ipairs(Workspace:GetChildren()) do
		if mob:GetAttribute("IsMob") then
			mob:Destroy()
		end
	end

	self:BroadcastHealth()
	self:BroadcastCoins()
	for _, player in ipairs(Players:GetPlayers()) do
		Network.GameOver.sendTo({ Won = false, Reset = true }, player)
	end

	-- Sync game state
	self:BroadcastState()

	-- Start fresh
	self:StartCountdown(1)
end

function WaveSystem:TakeBaseDamage(amount: number)
	if self.isGameOver then
		return
	end
	self.baseHealth = math.max(0, self.baseHealth - amount)
	self:BroadcastHealth()
	print(`[WaveSystem]: Base health: {self.baseHealth} / {self.baseMaxHealth}`)
	if self.baseHealth <= 0 then
		self:HandleGameOver()
	end
end

function WaveSystem:AddCoins(amount: number)
	self.coins += amount
	self:BroadcastCoins()
	print(`[WaveSystem]: Added {amount} coins. Total: {self.coins}`)
end

function WaveSystem:StartCountdown(waveNumber: number)
	if self.isWaveRunning or self.countdown > 0 or self.isGameOver then
		return
	end

	self.countdown = COUNTDOWN_DURATION

	task.spawn(function()
		while self.countdown > 0 and not self.isGameOver do
			self:BroadcastState()
			task.wait(1)
			self.countdown -= 1
		end

		if not self.isGameOver then
			self.countdown = 0
			self:StartWave(waveNumber)
		else
			self.countdown = 0
			self:BroadcastState()
		end
	end)
end

function WaveSystem:GetWaypoints(): { BasePart }
	local waypoints = {}
	for i = 1, 8 do
		local wp = self.waypointsFolder:FindFirstChild(tostring(i))
		if wp then
			table.insert(waypoints, wp)
		end
	end
	return waypoints
end

function WaveSystem:HandleMobMovement(mob: Model)
	local humanoid = mob:FindFirstChildOfClass("Humanoid")
	if not humanoid then
		mob:Destroy()
		return
	end

	local waypoints = self:GetWaypoints()
	for _, waypoint in ipairs(waypoints) do
		if not mob.Parent or self.isGameOver then
			return
		end
		humanoid:MoveTo(waypoint.Position)
		humanoid.MoveToFinished:Wait()
	end

	-- Move to TowerCore specifically if we finished waypoints
	if self.towerCore and mob.Parent and not self.isGameOver then
		local targetPos = self.towerCore:IsA("Model") and self.towerCore:GetPivot().Position or self.towerCore.Position
		humanoid:MoveTo(targetPos)
		humanoid.MoveToFinished:Wait()
	end

	-- Reached the end but didn't hit TowerCore (fall-back)
	if mob.Parent and not self.isGameOver then
		print(`[WaveSystem]: Mob {mob.Name} timed out at core. ReachedCore: {mob:GetAttribute("ReachedCore")}`)
		mob:Destroy()
	end
end

function WaveSystem:SpawnEnemy(enemyType: string)
	local template = self.mobsFolder:FindFirstChild(enemyType)
	local config = EnemyConfig[enemyType]

	if not template or not config then
		warn(`[WaveSystem]: Mob "{enemyType}" template or config missing`)
		return
	end

	local waypoints = self:GetWaypoints()
	if #waypoints == 0 then
		return
	end

	local mob = template:Clone() :: Model
	mob:SetAttribute("IsMob", true)
	mob:PivotTo(CFrame.new(waypoints[1].Position))
	mob.Parent = Workspace

	-- Apply HP from config
	local humanoid = mob:FindFirstChildOfClass("Humanoid")
	local head = mob:FindFirstChild("Head")
	if humanoid then
		humanoid.MaxHealth = config.Health
		humanoid.Health = config.Health
		humanoid.WalkSpeed = config.WalkSpeed or 16

		-- Create Billboard HP
		local billboard =
			self:CreateBillboardHP(mob, humanoid.Health, humanoid.MaxHealth, "MobHP", string.upper(enemyType))

		humanoid.HealthChanged:Connect(function(health)
			self:UpdateBillboardHP(billboard, health, humanoid.MaxHealth)
		end)
	end

	self.enemiesInWave += 1

	-- Collision with TowerCore Detection - Connect to all parts for robustness
	local hitConns = {}
	local function onTouched(hit)
		if hit:IsDescendantOf(self.towerCore) or hit == self.towerCore then
			print(`[WaveSystem]: Mob {mob.Name} TOUCHED core! Dealing {config.Damage} damage.`)
			mob:SetAttribute("ReachedCore", true) -- Prevent reward
			for _, conn in ipairs(hitConns) do
				conn:Disconnect()
			end
			self:TakeBaseDamage(config.Damage)
			mob:Destroy()
		end
	end

	for _, part in ipairs(mob:GetDescendants()) do
		if part:IsA("BasePart") then
			table.insert(hitConns, part.Touched:Connect(onTouched))
		end
	end

	-- Distance Fallback (Backup for Touched)
	task.spawn(function()
		while mob.Parent and not mob:GetAttribute("ReachedCore") and not self.isGameOver do
			if self.towerCore then
				local corePos = self.towerCore:IsA("Model") and self.towerCore:GetPivot().Position
					or self.towerCore.Position
				local mobPos = mob:GetPivot().Position
				local dist = (corePos - mobPos).Magnitude

				if dist < 6 then -- 6 studs threshold
					print(`[WaveSystem]: Mob {mob.Name} REACHED core (Distance check). Dealing {config.Damage} damage.`)
					mob:SetAttribute("ReachedCore", true)
					self:TakeBaseDamage(config.Damage)
					mob:Destroy()
					break
				end
			end
			task.wait(0.2)
		end
	end)

	-- Reward Logic
	if humanoid then
		humanoid.Died:Connect(function()
			if not self.isGameOver and not mob:GetAttribute("ReachedCore") and not mob:GetAttribute("Killed") then
				mob:SetAttribute("Killed", true)
				print(`[WaveSystem]: Mob killed (Died event). Reward: {config.Reward}`)
				self:AddCoins(config.Reward)
			end
		end)

		humanoid.HealthChanged:Connect(function(health)
			if health <= 0 and not mob:GetAttribute("Killed") and not mob:GetAttribute("ReachedCore") then
				mob:SetAttribute("Killed", true)
				print(`[WaveSystem]: Mob killed (HealthChanged <= 0). Reward: {config.Reward}`)
				if not self.isGameOver then
					self:AddCoins(config.Reward)
				end
			end
		end)
	end

	mob.Destroying:Connect(function()
		for _, conn in ipairs(hitConns) do
			conn:Disconnect()
		end
		self.enemiesInWave -= 1

		-- If all enemies are dead and we're done spawning
		if self.enemiesInWave <= 0 and not self.isWaveSpawning and not self.isGameOver then
			if self.currentWave >= self.totalWaves then
				-- Final wave cleared!
				self:HandleVictory()
			else
				self.isWaveRunning = false
				self:StartCountdown(self.currentWave + 1)
			end
		end
	end)

	task.spawn(function()
		self:HandleMobMovement(mob)
	end)
end

function WaveSystem:RunWave(waveNumber: number)
	local wave = WaveConfig[waveNumber]
	if not wave or self.isGameOver then
		warn(`[WaveSystem]: Cannot run wave {waveNumber}`)
		self.isWaveRunning = false
		self:BroadcastState()
		return
	end

	self.isWaveSpawning = true
	print(`[WaveSystem]: Wave {waveNumber} started`)

	for _, group in ipairs(wave.enemies) do
		for _ = 1, group.count do
			if not self.isWaveRunning or self.isGameOver then
				break
			end
			self:SpawnEnemy(group.type)
			task.wait(group.delay)
		end
		if not self.isWaveRunning or self.isGameOver then
			break
		end
	end

	self.isWaveSpawning = false
	print(`[WaveSystem]: Wave {waveNumber} spawning complete`)

	if self.enemiesInWave <= 0 and not self.isGameOver then
		if self.currentWave >= self.totalWaves then
			self:HandleVictory()
		else
			self.isWaveRunning = false
			self:StartCountdown(self.currentWave + 1)
		end
	end
end

-- ========== Public API ==========

function WaveSystem:StartWave(waveNumber: number)
	if self.isWaveRunning or self.isGameOver then
		return
	end

	self.isWaveRunning = true
	self.currentWave = waveNumber
	self.countdown = 0

	self:BroadcastState()
	task.spawn(function()
		self:RunWave(waveNumber)
	end)
end

function WaveSystem:NextWave()
	if self.countdown > 0 then
		self.countdown = 0
	elseif not self.isWaveRunning and not self.isGameOver then
		self:StartWave(self.currentWave + 1)
	end
end

return WaveSystem
