-- Services
local RS = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local UserInputService = game:GetService("UserInputService")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

-- Modules
local Network = require(RS.Network)
local TowerConfig = require(RS.Configs.TowerConfig)

local PlacementSystem = {}
PlacementSystem.__index = PlacementSystem

-- Constants
local RAY_DISTANCE = 500

function PlacementSystem:Init()
	self.player = Players.LocalPlayer
	self.userInput = UserInputService
	self.mouse = self.player:GetMouse()

	-- Selection Highlight (Aura Style)
	self.selectionBox = Instance.new("Highlight")
	self.selectionBox.Name = "TowerHighlight"
	self.selectionBox.FillColor = Color3.fromRGB(100, 100, 255)
	self.selectionBox.FillTransparency = 0.8
	self.selectionBox.OutlineColor = Color3.fromRGB(255, 255, 255)
	self.selectionBox.OutlineTransparency = 0
	self.selectionBox.Parent = self.player:WaitForChild("PlayerGui")

	self.isPlacing = false
	self.currentTowerName = nil
	self.ghostModel = nil
	self.targetPosition = nil
	self.selectedTower = nil
	self.isValid = false

	self.rangeCircle = self:CreateRangeCircle()
end

function PlacementSystem:CreateRangeCircle()
	local part = Instance.new("Part")
	part.Name = "RangeCircle"
	part.Shape = Enum.PartType.Cylinder
	part.Material = Enum.Material.SmoothPlastic
	part.Transparency = 0.8
	part.Color = Color3.fromRGB(0, 255, 0) -- Green when holding
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.CastShadow = false

	-- Add dashed texture
	local texture = Instance.new("Texture")
	texture.Name = "DashedOutline"
	texture.Texture = "rbxassetid://13197669458"
	texture.Face = Enum.NormalId.Top
	texture.Transparency = 0.3
	texture.Parent = part

	return part
end

function PlacementSystem:ShowRange(position: Vector3, range: number)
	self.rangeCircle.Size = Vector3.new(0.1, range * 2, range * 2)

	local texture = self.rangeCircle:FindFirstChild("DashedOutline")
	if texture then
		texture.StudsPerTileU = range * 2
		texture.StudsPerTileV = range * 2
	end

	self.rangeCircle.CFrame = CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
	self.rangeCircle.Parent = Workspace
end

function PlacementSystem:HideRange()
	self.rangeCircle.Parent = nil
end

function PlacementSystem:Start()
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton1 then
			if self.isPlacing then
				self:ConfirmPlacement()
			else
				self:HandleSelection()
			end
		elseif input.KeyCode == Enum.KeyCode.R then
			self:RotateGhost()
		elseif input.KeyCode == Enum.KeyCode.Q then
			if self.isPlacing then
				self:CancelPlacement()
			else
				self:Deselect()
			end
		end
	end)

	RunService.RenderStepped:Connect(function()
		if self.isPlacing then
			self:UpdateGhost()
		else
			self:UpdateHover()
		end
	end)
end

function PlacementSystem:HandleSelection()
	local mouseRay = self.mouse.UnitRay
	local towersFolder = Workspace:FindFirstChild("Towers")
	if not towersFolder then
		return
	end

	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { towersFolder }

	local result = Workspace:Raycast(mouseRay.Origin, mouseRay.Direction * RAY_DISTANCE, raycastParams)

	if result then
		local model = result.Instance:FindFirstAncestorOfClass("Model")
		-- Ensure the model is actually a tower (in Workspace.Towers)
		if model and model.Parent == Workspace:FindFirstChild("Towers") then
			if self.selectedTower == model then return end
			self:Deselect()

			self.selectedTower = model
			self.selectionBox.Adornee = model
			
			local config = TowerConfig[model.Name]
			if config then
				local function updateRange()
					local currentLevel = model:GetAttribute("Level") or 1
					local levelConfig = config.Levels[currentLevel]
					if levelConfig then
						self:ShowRange(model:GetPivot().Position, levelConfig.Range)
					end
				end

				updateRange()
				-- ดักฟังเลเวลเพื่อขยายวง Range ทันทีที่อัปเกรดสำเร็จ
				self.selectedLevelConn = model:GetAttributeChangedSignal("Level"):Connect(updateRange)
			end
			return
		end
	end

	-- Deselect if click on nothing/ground
	self:Deselect()
end

function PlacementSystem:Deselect()
	self.selectedTower = nil
	self.selectionBox.Adornee = nil
	if self.selectedLevelConn then
		self.selectedLevelConn:Disconnect()
		self.selectedLevelConn = nil
	end
	self:HideRange()
end

function PlacementSystem:StartPlacement(towerName: string)
	self:CancelPlacement()
	self:Deselect()

	self.currentTowerName = towerName
	self.isPlacing = true

	local assets = RS:FindFirstChild("Assets")
	local towersFolder = assets and assets:FindFirstChild("Towers")
	local sourceModel = towersFolder and towersFolder:FindFirstChild(towerName)

	if sourceModel then
		self.ghostModel = sourceModel:Clone()
	else
		warn(`[PlacementSystem] Asset for {towerName} not found. Using fallback.`)
		self.ghostModel = Instance.new("Part")
		self.ghostModel.Name = "GhostTower"
		self.ghostModel.Size = Vector3.new(4, 6, 4)
		self.ghostModel.BrickColor = BrickColor.new("Baby blue")
	end

	-- Setup ghost appearance
	local function applyGhostStyle(obj: Instance)
		if obj:IsA("BasePart") then
			obj.Transparency = 0.5
			obj.CanCollide = false
			obj.CastShadow = false
			obj.Anchored = true
		elseif obj:IsA("Decal") or obj:IsA("Texture") then
			obj.Transparency = 0.5
		end
	end

	applyGhostStyle(self.ghostModel)
	for _, descendant in ipairs(self.ghostModel:GetDescendants()) do
		applyGhostStyle(descendant)
	end

	self.ghostModel.Parent = Workspace
	self.isValid = false
end

function PlacementSystem:SetGhostColor(isValid: boolean)
	if not self.ghostModel then
		return
	end

	local color = if isValid then Color3.fromRGB(255, 255, 255) else Color3.fromRGB(255, 0, 0)
	local transparency = if isValid then 0.5 else 0.7

	if self.ghostModel:IsA("BasePart") then
		self.ghostModel.Color = color
		self.ghostModel.Transparency = transparency
	end

	for _, descendant in ipairs(self.ghostModel:GetDescendants()) do
		if descendant:IsA("BasePart") then
			descendant.Color = color
			descendant.Transparency = transparency
		end
	end

	-- Update range circle color too
	self.rangeCircle.Color = if isValid then Color3.fromRGB(0, 255, 0) else Color3.fromRGB(255, 0, 0)
end

function PlacementSystem:UpdateGhost()
	if not self.isPlacing or not self.ghostModel then
		return
	end

	local result = self:GetPlacementResult()
	if result then
		local mousePos = result.Position
		local hitInstance = result.Instance

		self.targetPosition = mousePos

		-- Validation Logic: Must be on Workspace/Base/Land
		local land = Workspace:FindFirstChild("Base") and Workspace.Base:FindFirstChild("Land")
		self.isValid = hitInstance and land and (hitInstance == land or hitInstance:IsDescendantOf(land))

		self:SetGhostColor(self.isValid)

		local yOffset = 0
		if self.ghostModel:IsA("Model") then
			local _, size = self.ghostModel:GetBoundingBox()
			yOffset = size.Y / 2
		else
			yOffset = self.ghostModel.Size.Y / 2
		end

		local _, yRotation, _ = self.ghostModel:GetPivot():ToEulerAnglesXYZ()
		local targetCFrame = CFrame.new(mousePos + Vector3.new(0, yOffset, 0)) * CFrame.Angles(0, yRotation, 0)
		self.ghostModel:PivotTo(targetCFrame)

		-- Overlap check: Prevent towers from being placed on top of each other
		if self.isValid then
			local overlapParams = OverlapParams.new()
			overlapParams.FilterType = Enum.RaycastFilterType.Include
			local towersFolder = Workspace:FindFirstChild("Towers")
			overlapParams.FilterDescendantsInstances = if towersFolder then { towersFolder } else {}

			local parts = Workspace:GetPartBoundsInBox(targetCFrame, self.ghostModel:GetExtentsSize(), overlapParams)
			if #parts > 0 then
				self.isValid = false
			end
		end

		self:SetGhostColor(self.isValid)
		local config = TowerConfig[self.currentTowerName]
		if config then
			self:ShowRange(mousePos, config.Levels[1].Range)
		end
	else
		self.isValid = false
		self:SetGhostColor(false)
		self:HideRange()
	end
end

function PlacementSystem:UpdateHover()
	if self.selectedTower then
		return
	end

	local mouseRay = self.mouse.UnitRay
	local raycastParams = RaycastParams.new()
	local towersFolder = Workspace:FindFirstChild("Towers")

	if not towersFolder then
		self:HideRange()
		return
	end

	raycastParams.FilterType = Enum.RaycastFilterType.Include
	raycastParams.FilterDescendantsInstances = { towersFolder }

	local result = Workspace:Raycast(mouseRay.Origin, mouseRay.Direction * RAY_DISTANCE, raycastParams)
	if result then
		local model = result.Instance:FindFirstAncestorOfClass("Model")
		local config = model and TowerConfig[model.Name]
		if model and config then
			local currentLevel = model:GetAttribute("Level") or 1
			local levelConfig = config.Levels[currentLevel]
			if levelConfig then
				self:ShowRange(model:GetPivot().Position, levelConfig.Range)
			end
			return
		end
	end

	self:HideRange()
end

function PlacementSystem:GetPlacementResult(): RaycastResult?
	local mouseRay = self.mouse.UnitRay
	local raycastParams = RaycastParams.new()
	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
	raycastParams.FilterDescendantsInstances = { self.ghostModel, self.player.Character }

	return Workspace:Raycast(mouseRay.Origin, mouseRay.Direction * RAY_DISTANCE, raycastParams)
end

function PlacementSystem:ConfirmPlacement()
	if not self.isPlacing or not self.currentTowerName or not self.targetPosition or not self.isValid then
		return
	end

	Network.PlaceTower:FireServer({
		TowerName = self.currentTowerName,
		Position = self.targetPosition,
	})

	self:CancelPlacement()
end

function PlacementSystem:RotateGhost()
	if not self.ghostModel then
		return
	end
	self.ghostModel:PivotTo(self.ghostModel:GetPivot() * CFrame.Angles(0, math.rad(90), 0))
end

function PlacementSystem:CancelPlacement()
	self.isPlacing = false
	self.currentTowerName = nil
	if self.ghostModel then
		self.ghostModel:Destroy()
		self.ghostModel = nil
	end
	self:HideRange()
end

return PlacementSystem
