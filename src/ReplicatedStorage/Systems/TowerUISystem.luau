-- local TowerUISystem = {}
-- TowerUISystem.__index = TowerUISystem

-- -- Services
-- local RS = game:GetService("ReplicatedStorage")
-- local Players = game:GetService("Players")
-- local Fusion = require(RS.Packages.Fusion)

-- -- Modules
-- local TowerSelection = require(RS.Components.TowerSelection)
-- local Network = require(RS.Network)

-- function TowerUISystem:Init(framework)
-- 	self.player = Players.LocalPlayer
-- 	self.playerGui = self.player:WaitForChild("PlayerGui")
-- 	self.framework = framework

-- 	self.ownedTowers = Fusion.Value({})
-- end

-- function TowerUISystem:Start()
-- 	warn("[TowerUISystem] Starting UI system...")

-- 	local screenGui = Instance.new("ScreenGui")
-- 	screenGui.Name = "TowerUI"
-- 	screenGui.IgnoreGuiInset = true
-- 	screenGui.ResetOnSpawn = false
-- 	screenGui.Parent = self.playerGui

-- 	-- Listen update
-- 	Network.UpdateOwnedTowers.listen(function(data)
-- 		print("[TowerUISystem] RAW:", data)

-- 		local towerList = {}

-- 		-- รองรับทั้ง string และ table
-- 		if typeof(data.Towers) == "string" then
-- 			for name in string.gmatch(data.Towers, "([^,]+)") do
-- 				table.insert(towerList, name)
-- 			end
-- 		elseif typeof(data.Towers) == "table" then
-- 			for _, name in ipairs(data.Towers) do
-- 				table.insert(towerList, name)
-- 			end
-- 		else
-- 			warn("[TowerUISystem] Invalid Towers format:", data.Towers)
-- 			return
-- 		end

-- 		print("[TowerUISystem] Parsed:", towerList)

-- 		--  IMPORTANT: clone ใหม่เสมอ
-- 		local new = table.clone(towerList)

-- 		self.ownedTowers:set(new)
-- 	end)

-- 	Network.RequestOwnedTowers.send({ Req = 1 })

-- 	TowerSelection({
-- 		OwnedTowers = self.ownedTowers,
-- 		OnSelect = function(towerName)
-- 			local placementSystem = self.framework.systems["PlacementSystem"]
-- 			if placementSystem then
-- 				placementSystem:StartPlacement(towerName)
-- 			end
-- 		end,
-- 		Parent = screenGui,
-- 	})

-- 	warn("[TowerUISystem] UI Mounted")
-- end

-- return TowerUISystem
