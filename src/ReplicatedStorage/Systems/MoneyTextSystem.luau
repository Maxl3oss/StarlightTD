local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Fusion = require(RS.Packages.Fusion)
local MoneyText = require(RS.Components.MoneyText)

local MoneyTextSystem = {}

function MoneyTextSystem:Init()
	local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

	-- Create or find MainUI ScreenGui
	local mainUI = playerGui:FindFirstChild("MainUI")
	if not mainUI then
		mainUI = Instance.new("ScreenGui")
		mainUI.Name = "MainUI"
		mainUI.ResetOnSpawn = false
		mainUI.Parent = playerGui
	end

	local scope = Fusion.scoped({ Value = Fusion.Value })
	self.moneyState = scope:Value(0)

	local Network = require(RS.Network)

	-- Listen for Cash updates from Server (via ByteNet)
	Network.UpdateCash.listen(function(data)
		self.moneyState:set(data.Cash)
	end)

	-- Request initial cash value from the server
	if Players.LocalPlayer then
		Network.RequestCash.send({ Req = 1 })
	end

	self.component = MoneyText({
		Money = self.moneyState,
		Parent = mainUI,
	})
end

return MoneyTextSystem
