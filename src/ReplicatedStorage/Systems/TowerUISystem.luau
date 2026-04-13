local TowerUISystem = {}
TowerUISystem.__index = TowerUISystem

-- Services
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Fusion = require(RS.Packages.Fusion)

-- Modules
local TowerSelection = require(RS.Components.TowerSelection)
local TowerInfo = require(RS.Components.TowerInfo)
local Network = require(RS.Network)

function TowerUISystem:Init(framework)
	self.player = Players.LocalPlayer
	self.playerGui = self.player:WaitForChild("PlayerGui")
	self.framework = framework

	self.scope = Fusion.scoped(Fusion)
	self.ownedTowers = self.scope:Value({})
	self.selectedTower = self.scope:Value(nil :: string?)
	self.inspectingTower = self.scope:Value(nil :: Model?)
end

function TowerUISystem:Start()
	warn("[TowerUISystem] Starting UI system...")

	-- Main UI Frame
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "TowerUI"
	screenGui.IgnoreGuiInset = true
	screenGui.ResetOnSpawn = false
	screenGui.Parent = self.playerGui

	-- Listen update
	Network.UpdateOwnedTowers:OnEvent(function(data)
		local towerList = {}
		if typeof(data.Towers) == "string" then
			for name in string.gmatch(data.Towers, "([^,]+)") do
				table.insert(towerList, name)
			end
		elseif typeof(data.Towers) == "table" then
			for _, name in ipairs(data.Towers) do
				table.insert(towerList, name)
			end
		end
		self.ownedTowers:set(table.clone(towerList))
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
				self.inspectingTower:set(nil) -- ปิดหน้าต่างข้อมูลเวลาจะวางของใหม่
			end
		end,
		Parent = screenGui,
	})

	-- Add Tower Info and connect to ScreenGui
	self.scope:New("Folder")({
		Name = "TowerInfoContainer",
		Parent = screenGui,
		[Fusion.Children] = {
			self.scope:Computed(function(use)
				local tower = use(self.inspectingTower)
				if not tower then
					return
				end

				return TowerInfo(self.scope, {
					Tower = tower,
					OnUpgrade = function()
						Network.RequestUpgrade:FireServer({ TowerInstance = tower })
					end,
					OnClose = function()
						self.inspectingTower:set(nil)
						local placementSystem = self.framework.systems["PlacementSystem"]
						if placementSystem then
							placementSystem:Deselect()
						end
					end,
				})
			end),
		},
	})

	-- Sync deselection and inspection
	task.spawn(function()
		while task.wait(0.1) do
			local placementSystem = self.framework.systems["PlacementSystem"]
			if placementSystem then
				-- Sync placement UI
				if not placementSystem.isPlacing and Fusion.peek(self.selectedTower) ~= nil then
					self.selectedTower:set(nil)
				end

				-- Sync inspection UI
				local currentSelected = placementSystem.selectedTower
				if currentSelected ~= Fusion.peek(self.inspectingTower) then
					self.inspectingTower:set(currentSelected)
				end
			end
		end
	end)

	warn("[TowerUISystem] UI Mounted")
end

return TowerUISystem
