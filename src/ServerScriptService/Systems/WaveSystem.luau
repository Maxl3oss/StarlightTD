local WaveSystem = {}
WaveSystem.__index = WaveSystem

-- Services
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerScriptService")
local SStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Base = Workspace:WaitForChild("Base")
local Players = game:GetService("Players")

-- Modules
local WaveConfig = require(RS.Configs.WaveConfig)
local EnemyConfig = require(RS.Configs.EnemyConfig)
local GameConfig = require(RS.Configs.GameConfig)
local Network = require(RS.Network)
local ProfileStoreSystem = require(SS.Systems.ProfileStoreSystem)

-- Constants
local COUNTDOWN_DURATION = 10

-- Debugging
local DEBUG = true
local function log(msg: string)
	if DEBUG then
		warn(`[WaveSystem]: {msg}`)
	end
end

local function setCollisionGroup(model: Instance, group: string)
	for _, obj in ipairs(model:GetDescendants()) do
		if obj:IsA("BasePart") then
			obj.CollisionGroup = group
		end
	end
end

-- ========== Framework Lifecycle ==========

function WaveSystem:Init()
	-- Cache folder references once
	self.waypointsFolder = Base:FindFirstChild("Waypoints") or Base:WaitForChild("Waypoints", 5)

	if not self.waypointsFolder then
		warn("Waypoints folder not found in Base! Creating a temporary one.")
		self.waypointsFolder = Instance.new("Folder")
		self.waypointsFolder.Name = "Waypoints"
		self.waypointsFolder.Parent = Base
	end

	-- Cache waypoints list
	self:RefreshWaypoints()

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

	self:StartCountdown(1)
end

-- ========== Internal Methods ==========

function WaveSystem:Broadcast(packetName: string, data: any, targetPlayer: Player?)
	local packet = Network[packetName]
	if not packet then
		return
	end

	if targetPlayer then
		packet.sendTo(data, targetPlayer)
	else
		for _, player in ipairs(Players:GetPlayers()) do
			packet.sendTo(data, player)
		end
	end
end

function WaveSystem:BroadcastState(targetPlayer: Player?)
	self:Broadcast("UpdateWave", {
		Wave = self.currentWave,
		IsRunning = self.isWaveRunning,
		Countdown = math.max(0, math.floor(self.countdown)),
	}, targetPlayer)
end

function WaveSystem:BroadcastHealth(targetPlayer: Player?)
	self:Broadcast("UpdateBaseHealth", {
		Health = self.baseHealth,
		MaxHealth = self.baseMaxHealth,
	}, targetPlayer)
end

function WaveSystem:BroadcastCoins(targetPlayer: Player?)
	self:Broadcast("UpdateCoins", {
		Coins = self.coins,
	}, targetPlayer)
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
	log("GAME OVER - Base Destroyed")
end

function WaveSystem:CheckWaveStatus()
	if self.enemiesInWave <= 0 and not self.isWaveSpawning and not self.isGameOver then
		if self.currentWave >= self.totalWaves then
			self:HandleVictory()
		else
			self.isWaveRunning = false
			self:StartCountdown(self.currentWave + 1)
		end
	end
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
	log("VICTORY - All waves cleared")
end

function WaveSystem:RestartGame()
	log("Restarting game...")

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
	log(`Base health: {self.baseHealth} / {self.baseMaxHealth}`)
	if self.baseHealth <= 0 then
		self:HandleGameOver()
	end
end

function WaveSystem:AddCoins(amount: number)
	self.coins += amount
	self:BroadcastCoins()
	log(`Added {amount} coins. Total: {self.coins}`)
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

function WaveSystem:RefreshWaypoints()
	local waypoints = {}
	for _, child in ipairs(self.waypointsFolder:GetChildren()) do
		if tonumber(child.Name) then
			table.insert(waypoints, child)
		end
	end

	table.sort(waypoints, function(a, b)
		return tonumber(a.Name) < tonumber(b.Name)
	end)

	self.cachedWaypoints = waypoints
	return waypoints
end

function WaveSystem:GetWaypoints(): { BasePart }
	return self.cachedWaypoints or self:RefreshWaypoints()
end

function WaveSystem:HandleMobMovement(humanoid: Humanoid)
	local mob = humanoid.Parent
	local mobName = mob and mob.Name or "Unknown"

	if not humanoid or not mob or not mob.Parent then
		return
	end

	-- Local helper for 2D distance check
	local function getFlatDistance(pos1: Vector3, pos2: Vector3): number
		return (Vector2.new(pos1.X, pos1.Z) - Vector2.new(pos2.X, pos2.Z)).Magnitude
	end

	local function moveToAndWait(targetPos: Vector3, label: string): boolean
		if not mob.Parent or humanoid.Health <= 0 or self.isGameOver then
			return false
		end

		local currentPos = mob:GetPivot().Position
		local initialDist = getFlatDistance(targetPos, currentPos)

		-- Threshold of 2.5 studs (2D)
		if initialDist <= 2.5 then
			return true
		end

		humanoid:MoveTo(targetPos)

		local stuckCheckSeconds = 1.0
		local stuckThreshold = 0.5
		local lastPos = currentPos
		local timer = 0
		local totalElapsed = 0

		while mob.Parent and humanoid.Health > 0 and not self.isGameOver do
			local nowPos = mob:GetPivot().Position
			local dist = getFlatDistance(targetPos, nowPos)

			if dist <= 2.5 then
				return true
			end

			totalElapsed += 0.1
			timer += 0.1

			if timer >= stuckCheckSeconds then
				local moved = (lastPos - nowPos).Magnitude
				if moved < stuckThreshold then
					-- Still re-issue if we haven't reached but aren't moving much
					humanoid:MoveTo(targetPos)
				end
				lastPos = nowPos
				timer = 0
			end

			task.wait(0.1)
		end

		return false
	end

	local waypoints = self:GetWaypoints()

	for i, waypoint in ipairs(waypoints) do
		if not moveToAndWait(waypoint.Position, `WP{i}`) then
			return
		end
	end

	if self.towerCore and mob.Parent and not self.isGameOver then
		local corePos = self.towerCore:IsA("Model") and self.towerCore:GetPivot().Position or self.towerCore.Position
		moveToAndWait(corePos, "TowerCore")
	end

	if mob.Parent and not self.isGameOver then
		mob:Destroy()
	end
end

function WaveSystem:SpawnEnemy(enemyName: string)
	local template = self.mobsFolder:FindFirstChild(enemyName)
	local config = EnemyConfig[enemyName]

	if not template or not config then
		warn(`Mob "{enemyName}" template or config missing`)
		return
	end

	local waypoints = self:GetWaypoints()
	if #waypoints == 0 then
		return
	end

	local mob = template:Clone() :: Model
	setCollisionGroup(mob, "Mobs")

	mob:SetAttribute("IsMob", true)
	mob:SetAttribute("Killed", false)
	mob:SetAttribute("ReachedCore", false)

	mob:PivotTo(CFrame.new(waypoints[1].Position))
	mob.Parent = Workspace

	local humanoid = mob:FindFirstChildOfClass("Humanoid")
	local root = mob.PrimaryPart or mob:FindFirstChild("HumanoidRootPart")

	-- Single atomic flag — prevents ALL duplicate execution paths
	local isDead = false

	local function onDeath(source: string)
		if isDead then
			return
		end
		isDead = true

		-- Reward only if killed (not if reached core)
		if source == "killed" and not self.isGameOver then
			mob:SetAttribute("Killed", true)
			self:AddCoins(config.Reward)
		end

		-- Base damage only if reached core
		if source == "core" then
			mob:SetAttribute("ReachedCore", true)
			self:TakeBaseDamage(config.Damage)
		end

		task.defer(function()
			if mob and mob.Parent then
				mob:Destroy()
			end
		end)
	end

	-- Apply stats + Billboard
	if humanoid then
		humanoid.MaxHealth = config.Health
		humanoid.Health = config.Health
		humanoid.WalkSpeed = config.WalkSpeed or 16

		-- Health bar handled by Client/HealthBarSystem via IsMob attribute

		-- Only one death listener needed (Died fires once, HealthChanged can fire multiple times)
		humanoid.Died:Connect(function()
			onDeath("killed")
		end)
	end

	self.enemiesInWave += 1

	-- Core Detection via Touched
	local hitConn
	if root then
		hitConn = root.Touched:Connect(function(hit)
			if isDead then
				return
			end
			if hit:IsDescendantOf(self.towerCore) or hit == self.towerCore then
				onDeath("core")
			end
		end)
	end

	-- Distance fallback — safe because isDead guards all paths
	task.spawn(function()
		while mob.Parent ~= nil and not isDead and not self.isGameOver do
			if self.towerCore then
				local corePos = self.towerCore:IsA("Model") and self.towerCore:GetPivot().Position
					or self.towerCore.Position

				-- pcall guards against destroyed mob mid-loop
				local ok, mobPos = pcall(function()
					return mob:GetPivot().Position
				end)

				if ok and (corePos - mobPos).Magnitude < 6 then
					onDeath("core")
					break
				end
			end
			task.wait(0.2)
		end
	end)

	-- Cleanup
	mob.Destroying:Connect(function()
		if hitConn then
			hitConn:Disconnect()
		end
		hitConn = nil

		self.enemiesInWave -= 1
		self:CheckWaveStatus()
	end)

	if not mob:GetAttribute("MovementStarted") then
		mob:SetAttribute("MovementStarted", true)
		task.spawn(function()
			self:HandleMobMovement(humanoid)
		end)
	end
end

function WaveSystem:RunWave(waveNumber: number)
	local wave = WaveConfig[waveNumber]
	if not wave or self.isGameOver then
		warn(`Cannot run wave {waveNumber}`)
		self.isWaveRunning = false
		self:BroadcastState()
		return
	end

	self.isWaveSpawning = true
	log(`Wave {waveNumber} started`)

	for _, group in ipairs(wave.enemies) do
		for _ = 1, group.count do
			if not self.isWaveRunning or self.isGameOver then
				break
			end
			self:SpawnEnemy(group.name)
			task.wait(group.delay)
		end
		if not self.isWaveRunning or self.isGameOver then
			break
		end
	end

	self.isWaveSpawning = false
	log(`Wave {waveNumber} spawning complete`)

	self:CheckWaveStatus()
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
