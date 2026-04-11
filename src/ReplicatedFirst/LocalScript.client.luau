local RF = game:GetService("ReplicatedFirst")
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

RF:RemoveDefaultLoadingScreen()

local Configs = RS:WaitForChild("Configs")
local GameConfigModule = Configs:WaitForChild("GameConfig")
local GameConfig = require(GameConfigModule)

if not GameConfig.EnableLoadingScreen then
	local loadingGui = script.Parent
	if loadingGui == RF or loadingGui.ClassName == "ReplicatedFirst" then
		loadingGui = RF:FindFirstChildOfClass("ScreenGui") or RF:WaitForChild("LoadingGui", 5)
	end
	if loadingGui then
		loadingGui:Destroy()
	end
	return
end

local loadingGui = script.Parent
if loadingGui == RF or loadingGui.ClassName == "ReplicatedFirst" then
	loadingGui = RF:FindFirstChildOfClass("ScreenGui") or RF:WaitForChild("LoadingGui", 5)
end

if not loadingGui or not loadingGui:IsA("ScreenGui") then
	warn("Could not find the LoadingGui ScreenGui! Make sure you have a ScreenGui in ReplicatedFirst.")
	return
end

loadingGui.Parent = playerGui

local bar = loadingGui:WaitForChild("ProgressBar"):WaitForChild("Bar")

local progress = 0

local function setProgress(value)
	local tween = TweenService:Create(bar, TweenInfo.new(0.3), { Size = UDim2.new(value, 0, 1, 0) })
	tween:Play()
end

for i = 1, 100 do
	progress = i / 100
	setProgress(progress)
	task.wait(0.02)
end

if not RS:GetAttribute("ServerReady") then
	RS:GetAttributeChangedSignal("ServerReady"):Wait()
end

task.wait(0.5)

loadingGui:Destroy()
