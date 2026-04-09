local runs = game:GetService("RunService");
local frameworkServer = script.Server;
local frameworkClient = script.Client;

local framework = {};

local IsServer = runs:IsServer();
if IsServer then
	framework.server = require(frameworkServer);
	framework.context = "server";
else
	framework.client = require(frameworkClient);
	framework.context = "client";
end

return framework;