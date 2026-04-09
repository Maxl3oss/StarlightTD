local ReplicatedFirst = game:GetService("ReplicatedFirst")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- remove roblox default loading
ReplicatedFirst:RemoveDefaultLoadingScreen()

-- Wait for GameConfig to be available since ReplicatedFirst loads before ReplicatedStorage
local Configs = ReplicatedStorage:WaitForChild("Configs")
local GameConfigModule = Configs:WaitForChild("GameConfig")
local GameConfig = require(GameConfigModule)

if not GameConfig.EnableLoadingScreen then
	local loadingGui = script.Parent
	if loadingGui == ReplicatedFirst or loadingGui.ClassName == "ReplicatedFirst" then
		loadingGui = ReplicatedFirst:FindFirstChildOfClass("ScreenGui") or ReplicatedFirst:WaitForChild("LoadingGui", 5)
	end
	if loadingGui then
		loadingGui:Destroy()
	end
	return
end

-- Find the actual loading GUI object
local loadingGui = script.Parent
if loadingGui == ReplicatedFirst or loadingGui.ClassName == "ReplicatedFirst" then
	-- If the script is placed directly in ReplicatedFirst, find the ScreenGui instead
	loadingGui = ReplicatedFirst:FindFirstChildOfClass("ScreenGui") or ReplicatedFirst:WaitForChild("LoadingGui", 5)
end

if not loadingGui or not loadingGui:IsA("ScreenGui") then
	warn("Could not find the LoadingGui ScreenGui! Make sure you have a ScreenGui in ReplicatedFirst.")
	return
end

loadingGui.Parent = playerGui

local bar = loadingGui:WaitForChild("ProgressBar"):WaitForChild("Bar")

local progress = 0

local function setProgress(value)
	local tween = TweenService:Create(
		bar,
		TweenInfo.new(0.3),
		{Size = UDim2.new(value,0,1,0)}
	)
	tween:Play()
end

-- fake loading example
for i = 1,100 do
	progress = i/100
	setProgress(progress)
	task.wait(0.02)
end

-- wait server ready
local RS = game:GetService("ReplicatedStorage")

if not RS:GetAttribute("ServerReady") then
	RS:GetAttributeChangedSignal("ServerReady"):Wait()
end

task.wait(0.5)

loadingGui:Destroy()
