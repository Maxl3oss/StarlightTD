local TowerUISystem = {}
TowerUISystem.__index = TowerUISystem

-- Services
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Fusion = require(RS.Packages.Fusion)

-- Modules
local TowerSelection = require(RS.Components.TowerSelection)
local Network = require(RS.Network)

function TowerUISystem:Init(framework)
	self.player = Players.LocalPlayer
	self.playerGui = self.player:WaitForChild("PlayerGui")
	self.framework = framework

	self.scope = Fusion.scoped(Fusion)
	self.ownedTowers = self.scope:Value({})
	self.selectedTower = self.scope:Value(nil :: string?)
end

function TowerUISystem:Start()
	warn("[TowerUISystem] Starting UI system...")

	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TowerUI"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.Parent = self.playerGui

	-- Listen update
	Network.UpdateOwnedTowers:OnEvent(function(data)
		print("[TowerUISystem] RAW:", data)

		local towerList = {}

		-- รองรับทั้ง string และ table
		if typeof(data.Towers) == "string" then
			for name in string.gmatch(data.Towers, "([^,]+)") do
				table.insert(towerList, name)
			end
		elseif typeof(data.Towers) == "table" then
			for _, name in ipairs(data.Towers) do
				table.insert(towerList, name)
			end
		else
			warn("[TowerUISystem] Invalid Towers format:", data.Towers)
			return
		end

		print("[TowerUISystem] Parsed:", towerList)

		--  IMPORTANT: clone ใหม่เสมอ
		local new = table.clone(towerList)

		self.ownedTowers:set(new)
	end)

	Network.RequestOwnedTowers:FireServer({ Req = 1 })

	TowerSelection({
		OwnedTowers = self.ownedTowers,
		SelectedTower = self.selectedTower,
		OnSelect = function(towerName)
			local placementSystem = self.framework.systems["PlacementSystem"]
			if not placementSystem then
				return
			end

			local current = Fusion.peek(self.selectedTower)
			if current == towerName then
				-- Toggle OFF
				self.selectedTower:set(nil)
				if placementSystem.isPlacing then
					placementSystem:CancelPlacement()
				end
			else
				-- Toggle ON
				self.selectedTower:set(towerName)
				placementSystem:StartPlacement(towerName)
			end
		end,
		Parent = screenGui,
	})

	-- Sync deselection if PlacementSystem cancels (e.g. Q key)
	task.spawn(function()
		while task.wait(0.1) do
			local placementSystem = self.framework.systems["PlacementSystem"]
			if placementSystem and not placementSystem.isPlacing and Fusion.peek(self.selectedTower) ~= nil then
				self.selectedTower:set(nil)
			end
		end
	end)

	warn("[TowerUISystem] UI Mounted")
end

return TowerUISystem
