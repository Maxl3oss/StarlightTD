local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local loader = require(script.Parent.ComponentLoader)
local Systems = RS.Systems
local Components = RS.Components

local frameworkClient = {
	systems = {},
	components = {},
	networks = {},
	flages = {
		init = false,
	},
}

frameworkClient.__index = frameworkClient

function frameworkClient:Init()
	if self.flages.init then
		print("Already initialized")
		return
	end

	self.systems = loader:LoadComponents(Systems)
	self.components = loader:LoadComponents(Components)

	for name, system in pairs(self.systems) do
		if system.Init then
			warn("[Framework Client]: Initializing : ", name)
			system:Init(self)
		end
	end

	for name, system in pairs(self.systems) do
		if system.Start then
			warn("[Framework Client]:Starting : ", name)
			system:Start(self)
		end
	end

	RunService.Heartbeat:Connect(function(dt)
		for name, system in pairs(self.systems) do
			if system.Heartbeat then
				system:Heartbeat(dt, self)
			end
		end
	end)

	self.flages.init = true
end

return frameworkClient
