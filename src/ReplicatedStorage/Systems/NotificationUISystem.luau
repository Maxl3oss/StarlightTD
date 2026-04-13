local NotificationUISystem = {}
NotificationUISystem.__index = NotificationUISystem

local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Network = require(RS.Network)
local Notification = require(RS.Components.Notification)
local Fusion = require(RS.Packages.Fusion)

function NotificationUISystem:Init()
	self.player = Players.LocalPlayer
	self.playerGui = self.player:WaitForChild("PlayerGui")
	self.scope = Fusion.scoped(Fusion)
end

function NotificationUISystem:Start()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "NotificationUI"
	screenGui.DisplayOrder = 100 -- Ensure it's on top
	screenGui.Parent = self.playerGui

	Network.Notify:OnEvent(function(data)
		local component = Notification(self.scope, {
			Message = data.Message,
			Type = data.Type,
		})
		component.Parent = screenGui
	end)
end

return NotificationUISystem
