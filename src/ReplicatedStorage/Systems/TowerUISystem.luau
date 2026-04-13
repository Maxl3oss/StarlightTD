local TowerUISystem = {}
TowerUISystem.__index = TowerUISystem

-- Services
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Fusion = require(RS.Packages.Fusion)

-- Modules
local TowerSelection = require(RS.Components.TowerSelection)
local TowerInfo = require(RS.Components.TowerInfo)
local TowerDraftInfo = require(RS.Components.TowerDraftInfo)
local WorldTowerInfo = require(RS.Components.WorldTowerInfo)
local Network = require(RS.Network)

function TowerUISystem:Init(framework)
	self.player = Players.LocalPlayer
	self.playerGui = self.player:WaitForChild("PlayerGui")
	self.framework = framework

	self.scope = Fusion.scoped(Fusion)
	self.ownedTowers = self.scope:Value({})
	self.selectedTower = self.scope:Value(nil :: string?)
	self.inspectingTower = self.scope:Value(nil :: Model?)
	self.isPlacingUI = self.scope:Value(false)
	self.infoScope = nil -- Will hold the scope for the current info panel
end

function TowerUISystem:Start()
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

	-- Tower Draft Info (Left side when placing)
	self.scope:New("Folder")({
		Name = "TowerDraftContainer",
		Parent = screenGui,
		[Fusion.Children] = {
			self.scope:Computed(function(use)
				local towerName = use(self.selectedTower)
				local isPlacing = use(self.isPlacingUI)

				if not towerName or not isPlacing then
					return
				end

				return TowerDraftInfo(self.scope, {
					TowerName = towerName,
				})
			end),
		},
	})

	-- Tower Info Display (Right side)
	self.scope:New("Folder")({
		Name = "TowerInfoContainer",
		Parent = screenGui,
		[Fusion.Children] = {
			self.scope:Computed(function(use)
				local tower = use(self.inspectingTower)

				-- อาวุธลับ: ทำลาย Scope เก่าทิ้งทุกครั้งที่เปลี่ยนการเลือก
				if self.infoScope then
					Fusion.doCleanup(self.infoScope)
					self.infoScope = nil
				end

				if not tower then
					return
				end

				-- สร้าง Scope ใหม่เฉพาะกิจ
				self.infoScope = Fusion.scoped(Fusion)

				return TowerInfo(self.infoScope, {
					Tower = tower,
					OnUpgrade = function()
						local towerId = tower:GetAttribute("TowerId")
						Network.RequestUpgrade:FireServer({ TowerId = towerId })
					end,
					OnSell = function()
						local towerId = tower:GetAttribute("TowerId")
						Network.RequestSell:FireServer({ TowerId = towerId })
					end,
					OnClose = function()
						self.inspectingTower:set(nil)
						-- ตัดวงจร: สั่งยกเลิกการเลือกในระบบ Placement ด้วย
						local placementSystem = self.framework.systems["PlacementSystem"]
						if placementSystem then
							placementSystem:Deselect()
						end
					end,
				})
			end),
		},
	})

	-- Listen for removals (Sync with sell)
	Network.TowerRemoved:OnEvent(function(data)
		local current = Fusion.peek(self.inspectingTower)
		if current and current:GetAttribute("TowerId") == data.TowerId then
			self.inspectingTower:set(nil)
			local placementSystem = self.framework.systems["PlacementSystem"]
			if placementSystem then
				placementSystem:Deselect()
			end
		end
	end)

	-- Sync deselection and inspection
	task.spawn(function()
		while task.wait(0.1) do
			local placementSystem = self.framework.systems["PlacementSystem"]
			if placementSystem then
				-- Sync placement UI
				if not placementSystem.isPlacing and Fusion.peek(self.selectedTower) ~= nil then
					self.selectedTower:set(nil)
				end
				self.isPlacingUI:set(placementSystem.isPlacing)

				-- Sync inspection UI
				local currentSelected = placementSystem.selectedTower
				if currentSelected ~= Fusion.peek(self.inspectingTower) then
					self.inspectingTower:set(currentSelected)
				end
			end
		end
	end)

	-- Handle World UI for Tower Names/Levels
	local function setupWorldUI(towerInstance: Model)
		if not towerInstance or not towerInstance:IsA("Model") then
			return
		end

		-- ป้องกันการสร้างซ้ำถ้ามีอยู่แล้ว
		if towerInstance:FindFirstChild("WorldTowerInfo") then
			return
		end

		WorldTowerInfo(self.scope, {
			Tower = towerInstance,
		})
	end

	Network.TowerPlaced:OnEvent(function(data)
		-- รอให้ Instance มาถึง Client จริงๆ ก่อนเริ่มงาน
		if not data.TowerInstance then
			warn("[TowerUISystem] TowerInstance was nil in event, waiting for ChildAdded instead")
			return
		end
		setupWorldUI(data.TowerInstance)
	end)

	-- Check already placed towers and listen for new ones
	task.spawn(function()
		local towersFolder = Workspace:WaitForChild("Towers", 5)
		if towersFolder then
			-- ดักฟังหอคอยใหม่ที่โหลดเข้ามาในโฟลเดอร์โดยตรง
			towersFolder.ChildAdded:Connect(function(child)
				if child:IsA("Model") then
					task.wait(0.1) -- รอให้ Attributes โหลดเสร็จ
					setupWorldUI(child)
				end
			end)

			-- จัดการหอคอยที่มีอยู่แล้ว
			for _, tower in ipairs(towersFolder:GetChildren()) do
				if tower:IsA("Model") then
					setupWorldUI(tower)
				end
			end
		end
	end)
end

return TowerUISystem
