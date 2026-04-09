local RS = game:GetService("ReplicatedStorage")
local Framework = require(RS.Framework)
local Server = Framework.server

Server:Init()

RS:SetAttribute("ServerReady", true)
