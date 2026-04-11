local RS = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local SSS = game:GetService("ServerScriptService")

local loader = require(script.Parent.ComponentLoader)

local Systems = SSS.Systems
local Components = SSS.Components

local frameworkServer = {
	systems = {},
	components = {},
	networks = {},
	flags = {
		init = false,
	},
}

frameworkServer.__index = frameworkServer

-- Debugging
function frameworkServer:Init()
	if self.flags.init then
		print("Already initialized")
		return
	end

	self.components = loader:LoadComponents(Components)
	self.systems = loader:LoadComponents(Systems)

	-- Init Systems
	for name, system in pairs(self.systems) do
		if system.Init then
			warn("[Framework Server]: Initializing :", name)
			system:Init(self)
		end
	end

	-- Start Systems
	for name, system in pairs(self.systems) do
		if system.Start then
			warn("[Framework Server]: Starting     :", name)
			system:Start(self)
		end
	end

	RunService.Heartbeat:Connect(function(dt)
		for _, system in pairs(self.systems) do
			if system.Heartbeat then
				system:Heartbeat(dt, self)
			end
		end
	end)

	self.flags.init = true
end

return frameworkServer
