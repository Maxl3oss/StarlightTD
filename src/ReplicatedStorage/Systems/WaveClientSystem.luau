local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Fusion = require(RS.Packages.Fusion)
local Network = require(RS.Network)

local WaveDisplay = require(RS.Components.WaveDisplay)
local GameOverScreen = require(RS.Components.GameOverScreen)
local CoinsDisplay = require(RS.Components.CoinsDisplay)

local WaveClientSystem = {}

function WaveClientSystem:Init()
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui")

	-- Ensure MainUI exists
	local mainUI = playerGui:FindFirstChild("MainUI")
	if not mainUI then
		mainUI = Instance.new("ScreenGui")
		mainUI.Name = "MainUI"
		mainUI.ResetOnSpawn = false
		mainUI.Parent = playerGui
	end

	-- State management using Fusion
	local scope = Fusion.scoped({ Value = Fusion.Value })
	self.waveState = scope:Value(0)
	self.isRunningState = scope:Value(false)
	self.countdownState = scope:Value(0)

	self.healthState = scope:Value(100)
	self.maxHealthState = scope:Value(100)
	self.isGameOverState = scope:Value(false)
	self.wonState = scope:Value(false)

	self.coinsState = scope:Value(300)

	-- Sync state from server broadcasts
	Network.UpdateWave:OnEvent(function(data)
		self.waveState:set(data.Wave)
		self.isRunningState:set(data.IsRunning)
		self.countdownState:set(data.Countdown)
	end)

	Network.UpdateBaseHealth:OnEvent(function(data)
		self.healthState:set(data.Health)
		self.maxHealthState:set(data.MaxHealth)
	end)

	Network.UpdateCoins:OnEvent(function(data)
		self.coinsState:set(data.Coins)
	end)

	Network.GameOver:OnEvent(function(data)
		if data.Reset then
			self.isGameOverState:set(false)
		else
			self.isGameOverState:set(true)
			self.wonState:set(data.Won)
		end
	end)

	-- Request current server state on initialization
	Network.RequestWave:FireServer({ Req = 1 })

	-- Mount UI Components
	self.display = WaveDisplay({
		Wave = self.waveState,
		IsRunning = self.isRunningState,
		Countdown = self.countdownState,
		OnNextWave = function()
			Network.RequestNextWave:FireServer({ Req = 1 })
		end,
		Parent = mainUI,
	})

	self.coinsDisplay = CoinsDisplay({
		Coins = self.coinsState,
		Parent = mainUI,
	})

	self.gameOver = GameOverScreen({
		Visible = self.isGameOverState,
		Won = self.wonState,
		OnRestart = function()
			self.isGameOverState:set(false)
			Network.RestartGame:FireServer({ Req = 1 })
		end,
		Parent = mainUI,
	})
end

return WaveClientSystem
