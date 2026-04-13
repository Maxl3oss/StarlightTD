local WaveSystem = {}
WaveSystem.__index = WaveSystem

export type WaveSystem = {
	waypointsFolder: Folder,
	mobsFolder: Folder,
	towerCore: Instance?,
	currentWave: number,
	isWaveRunning: boolean,
	isWaveSpawning: boolean,
	enemiesInWave: number,
	totalWaves: number,
	countdown: number,
	isGameOver: boolean,
	baseMaxHealth: number,
	baseHealth: number,
	coins: number,
	cachedWaypoints: { BasePart }?,
}

-- Services
local RS = game:GetService("ReplicatedStorage")
local SS = game:GetService("ServerScriptService")
local SStorage = game:GetService("ServerStorage")
local Workspace = game:GetService("Workspace")
local Base = Workspace:WaitForChild("Base")
local Players = game:GetService("Players")

-- Modules
local WaveConfig = require(SS.Configs.WaveConfig)
local EnemyConfig = require(SS.Configs.EnemyConfig)
local GameConfig = require(SS.Configs.GameConfig)
local Network = require(RS.Network)
local ProfileStoreSystem = require(SS.Systems.ProfileStoreSystem)
local Helper = require(RS.Utils.Helper)

-- Constants
local COUNTDOWN_DURATION = 10
local ARRIVE_THRESHOLD = 3
local CLOSE_ENOUGH = 6
local TIMEOUT = 6
local RETRY_LIMIT = 2

-- Debugging
local DEBUG = false
local function log(msg: string, level: ("info" | "warn" | "error")?)
	if not DEBUG then
		return
	end
	local prefix = "[WaveSystem]:"
	if level == "warn" then
		warn(`{prefix} {msg}`)
	elseif level == "error" then
		error(`{prefix} {msg}`)
	else
		print(`{prefix} {msg}`)
	end
end


-- ========== Framework Lifecycle ==========

function WaveSystem:Init(framework)
	self.framework = framework
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
	Network.RequestWave:OnEvent(function(player, _)
		self:BroadcastState(player)
		self:BroadcastHealth(player)
		self:BroadcastCoins(player)
	end)

	Network.RequestNextWave:OnEvent(function(player, _)
		self:NextWave()
	end)

	Network.RestartGame:OnEvent(function(player, _)
		self:RestartGame()
	end)
end

function WaveSystem:Start()
	self:BroadcastHealth()
	self:BroadcastCoins()

	self:StartCountdown(1)
end

-- ========== Broadcast Methods ==========

function WaveSystem:Broadcast(packetName: string, data: any, targetPlayer: Player?)
	local packet = Network[packetName]
	if not packet then
		return
	end

	if targetPlayer then
		packet:FireClient(targetPlayer, data)
	else
		packet:FireAllClients(data)
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

	Network.GameOver:FireAllClients({ Won = false, Reset = false })
	log("GAME OVER - Base Destroyed", "warn")
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

	for _, player in ipairs(Players:GetPlayers()) do
		ProfileStoreSystem:AddCash(player, GameConfig.VictoryCashReward or 100)
	end
	Network.GameOver:FireAllClients({ Won = true, Reset = false })
	log("VICTORY - All waves cleared", "info")
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
	Network.GameOver:FireAllClients({ Won = false, Reset = true })

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

	-- Throttle broadcasting to prevent network spam during AoE hits
	if not self._coinsUpdatePending then
		self._coinsUpdatePending = true
		task.defer(function()
			self._coinsUpdatePending = false
			self:BroadcastCoins()
		end)
	end
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
	if not humanoid or not mob or not mob.Parent then
		return
	end

	local waypoints = self:GetWaypoints()
	local mobName = mob.Name

	-- Helper for 2D distance
	local function getDistance(a: Vector3, b: Vector3): number
		return (Vector3.new(a.X, 0, a.Z) - Vector3.new(b.X, 0, b.Z)).Magnitude
	end

	local function moveToPos(targetPos: Vector3, index: number?): boolean
		local attempt = 0
		while attempt <= RETRY_LIMIT do
			attempt += 1

			local reached = false
			local success = false
			local connection = humanoid.MoveToFinished:Connect(function(moveSuccess)
				reached = true
				success = moveSuccess
			end)

			humanoid:MoveTo(targetPos)
			local startTime = tick()

			while not reached do
				if not mob.Parent or humanoid.Health <= 0 or self.isGameOver then
					connection:Disconnect()
					return false
				end

				local dist = getDistance(mob:GetPivot().Position, targetPos)
				if dist <= ARRIVE_THRESHOLD then
					connection:Disconnect()
					return true
				end

				-- Timeout fallback
				if tick() - startTime >= TIMEOUT then
					connection:Disconnect()
					if dist <= CLOSE_ENOUGH then
						return true -- Close enough, move to next
					end
					break -- Retry if too far
				end

				task.wait(0.1)
			end
			connection:Disconnect()

			if success then
				return true
			end
		end

		log(`Mob {mobName} failed to reach WP {index or "Core"} after retries`, "warn")
		return false
	end

	-- Traverse waypoints
	for i, waypoint in ipairs(waypoints) do
		if not moveToPos(waypoint.Position, i) then
			return
		end
	end

	-- Move to core
	if self.towerCore and mob.Parent and not self.isGameOver then
		local corePos = self.towerCore:IsA("Model") and self.towerCore:GetPivot().Position or self.towerCore.Position
		moveToPos(corePos)
	end

	-- Reached end (Logic handled by SpawnEnemy core detection)
end

function WaveSystem:SpawnEnemy(enemyName: string)
	local template = self.mobsFolder:FindFirstChild(enemyName)
	local config = EnemyConfig[enemyName]

	if not template or not config then
		log(`Mob "{enemyName}" template or config missing`, "warn")
		return
	end

	local waypoints = self:GetWaypoints()
	if #waypoints == 0 then
		return
	end

	local mob = template:Clone() :: Model
	Helper.setCollisionGroup(mob, "Mobs")

	mob:SetAttribute("IsMob", true)
	mob:SetAttribute("Killed", false)
	mob:SetAttribute("ReachedCore", false)
	mob:SetAttribute("MovementStarted", true)

	mob:PivotTo(CFrame.new(waypoints[1].Position))
	mob.Parent = Workspace

	local humanoid = mob:FindFirstChildOfClass("Humanoid")
	local root = mob.PrimaryPart or mob:FindFirstChild("HumanoidRootPart")

	local isDead = false
	local function onDeath(source: "killed" | "core")
		if isDead then
			return
		end
		isDead = true

		if source == "killed" and not self.isGameOver then
			mob:SetAttribute("Killed", true)
			self:AddCoins(config.Reward)
		elseif source == "core" then
			mob:SetAttribute("ReachedCore", true)
			self:TakeBaseDamage(config.Damage)
		end

		task.defer(function()
			if mob and mob.Parent then
				mob:Destroy()
			end
		end)
	end

	if humanoid then
		humanoid.MaxHealth = config.Health
		humanoid.Health = config.Health
		humanoid.WalkSpeed = config.WalkSpeed or 16
		humanoid.Died:Connect(function()
			onDeath("killed")
		end)
	end

	self.enemiesInWave += 1

	-- Core Detection (Touched + Distance Fallback)
	local hitConn
	if root then
		hitConn = root.Touched:Connect(function(hit)
			if not isDead and (hit:IsDescendantOf(self.towerCore) or hit == self.towerCore) then
				onDeath("core")
			end
		end)
	end

	task.spawn(function()
		while mob.Parent and not isDead and not self.isGameOver do
			if self.towerCore then
				local corePos = self.towerCore:IsA("Model") and self.towerCore:GetPivot().Position
					or self.towerCore.Position
				local ok, mobPos = pcall(function()
					return mob:GetPivot().Position
				end)
				if ok and (corePos - mobPos).Magnitude < 6 then
					onDeath("core")
					break
				end
			end
			task.wait(0.5) -- Increased wait slightly for performance
		end
	end)

	-- Cleanup
	mob.Destroying:Connect(function()
		if hitConn then
			hitConn:Disconnect()
		end
		self.enemiesInWave -= 1
		self:CheckWaveStatus()
	end)

	if humanoid then
		task.spawn(function()
			self:HandleMobMovement(humanoid)
		end)
	end
end

function WaveSystem:RunWave(waveNumber: number)
	local wave = WaveConfig[waveNumber]
	if not wave or self.isGameOver then
		log(`Cannot run wave {waveNumber}`, "warn")
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
