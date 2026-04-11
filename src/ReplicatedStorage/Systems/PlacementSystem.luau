-- -- Services
-- local RS = game:GetService("ReplicatedStorage")
-- local Players = game:GetService("Players")
-- local UserInputService = game:GetService("UserInputService")
-- local RunService = game:GetService("RunService")
-- local Workspace = game:GetService("Workspace")

-- -- Modules
-- local Network = require(RS.Network)
-- local TowerConfig = require(RS.Configs.TowerConfig)

-- local PlacementSystem = {}
-- PlacementSystem.__index = PlacementSystem

-- -- Constants
-- local RAY_DISTANCE = 500

-- function PlacementSystem:Init()
-- 	self.player = Players.LocalPlayer
-- 	self.mouse = self.player:GetMouse()
-- 	self.isPlacing = false
-- 	self.currentTowerName = nil
-- 	self.ghostModel = nil
-- 	self.targetPosition = nil
-- 	self.selectedTower = nil

-- 	self.rangeCircle = self:CreateRangeCircle()
-- end

-- function PlacementSystem:CreateRangeCircle()
-- 	local part = Instance.new("Part")
-- 	part.Name = "RangeCircle"
-- 	part.Shape = Enum.PartType.Cylinder
-- 	part.Material = Enum.Material.SmoothPlastic
-- 	part.Transparency = 0.8
-- 	part.Color = Color3.fromRGB(0, 255, 0) -- Green when holding
-- 	part.Anchored = true
-- 	part.CanCollide = false
-- 	part.CanTouch = false
-- 	part.CanQuery = false
-- 	part.CastShadow = false

-- 	-- Add dashed texture
-- 	local texture = Instance.new("Texture")
-- 	texture.Name = "DashedOutline"
-- 	texture.Texture = "rbxassetid://13197669458"
-- 	texture.Face = Enum.NormalId.Top
-- 	texture.Transparency = 0.3
-- 	texture.Parent = part

-- 	return part
-- end

-- function PlacementSystem:ShowRange(position: Vector3, range: number)
-- 	self.rangeCircle.Size = Vector3.new(0.1, range * 2, range * 2)

-- 	local texture = self.rangeCircle:FindFirstChild("DashedOutline")
-- 	if texture then
-- 		texture.StudsPerTileU = range * 2
-- 		texture.StudsPerTileV = range * 2
-- 	end

-- 	self.rangeCircle.CFrame = CFrame.new(position + Vector3.new(0, 0.1, 0)) * CFrame.Angles(0, 0, math.rad(90))
-- 	self.rangeCircle.Parent = Workspace
-- end

-- function PlacementSystem:HideRange()
-- 	self.rangeCircle.Parent = nil
-- end

-- function PlacementSystem:Start()
-- 	UserInputService.InputBegan:Connect(function(input, processed)
-- 		if processed then
-- 			return
-- 		end
-- 		if input.UserInputType == Enum.UserInputType.MouseButton1 then
-- 			if self.isPlacing then
-- 				self:ConfirmPlacement()
-- 			else
-- 				self:HandleSelection()
-- 			end
-- 		elseif input.KeyCode == Enum.KeyCode.R then
-- 			self:RotateGhost()
-- 		elseif input.KeyCode == Enum.KeyCode.Q then
-- 			if self.isPlacing then
-- 				self:CancelPlacement()
-- 			else
-- 				self:Deselect()
-- 			end
-- 		end
-- 	end)

-- 	RunService.RenderStepped:Connect(function()
-- 		if self.isPlacing then
-- 			self:UpdateGhost()
-- 		else
-- 			self:UpdateHover()
-- 		end
-- 	end)
-- end

-- function PlacementSystem:HandleSelection()
-- 	local mouseRay = self.mouse.UnitRay
-- 	local towersFolder = Workspace:FindFirstChild("Towers")
-- 	if not towersFolder then
-- 		return
-- 	end

-- 	local raycastParams = RaycastParams.new()
-- 	raycastParams.FilterType = Enum.RaycastFilterType.Include
-- 	raycastParams.FilterDescendantsInstances = { towersFolder }

-- 	local result = Workspace:Raycast(mouseRay.Origin, mouseRay.Direction * RAY_DISTANCE, raycastParams)
-- 	if result then
-- 		local model = result.Instance:FindFirstAncestorOfClass("Model")
-- 		if model and TowerConfig[model.Name] then
-- 			self.selectedTower = model
-- 			self:ShowRange(model:GetPivot().Position, TowerConfig[model.Name].Range)
-- 			return
-- 		end
-- 	end

-- 	self:Deselect()
-- end

-- function PlacementSystem:Deselect()
-- 	self.selectedTower = nil
-- 	self:HideRange()
-- end

-- function PlacementSystem:StartPlacement(towerName: string)
-- 	self:CancelPlacement()
-- 	self:Deselect()

-- 	self.currentTowerName = towerName
-- 	self.isPlacing = true

-- 	local assets = RS:FindFirstChild("Assets")
-- 	local towersFolder = assets and assets:FindFirstChild("Towers")
-- 	local sourceModel = towersFolder and towersFolder:FindFirstChild(towerName)

-- 	if sourceModel then
-- 		self.ghostModel = sourceModel:Clone()
-- 	else
-- 		warn(`[PlacementSystem] Asset for {towerName} not found. Using fallback.`)
-- 		self.ghostModel = Instance.new("Part")
-- 		self.ghostModel.Name = "GhostTower"
-- 		self.ghostModel.Size = Vector3.new(4, 6, 4)
-- 		self.ghostModel.BrickColor = BrickColor.new("Baby blue")
-- 	end

-- 	-- Setup ghost appearance
-- 	local function applyGhostStyle(obj: Instance)
-- 		if obj:IsA("BasePart") then
-- 			obj.Transparency = 0.5
-- 			obj.CanCollide = false
-- 			obj.CastShadow = false
-- 			obj.Anchored = true
-- 		elseif obj:IsA("Decal") or obj:IsA("Texture") then
-- 			obj.Transparency = 0.5
-- 		end
-- 	end

-- 	applyGhostStyle(self.ghostModel)
-- 	for _, descendant in ipairs(self.ghostModel:GetDescendants()) do
-- 		applyGhostStyle(descendant)
-- 	end

-- 	self.ghostModel.Parent = Workspace
-- end

-- function PlacementSystem:UpdateGhost()
-- 	if not self.isPlacing or not self.ghostModel then
-- 		return
-- 	end

-- 	local mousePos = self:GetMouseWorldPosition()
-- 	if mousePos then
-- 		self.targetPosition = mousePos

-- 		local yOffset = 0
-- 		if self.ghostModel:IsA("Model") then
-- 			local _, size = self.ghostModel:GetBoundingBox()
-- 			yOffset = size.Y / 2
-- 		else
-- 			yOffset = self.ghostModel.Size.Y / 2
-- 		end

-- 		local _, yRotation, _ = self.ghostModel:GetPivot():ToEulerAnglesXYZ()
-- 		local targetCFrame = CFrame.new(mousePos + Vector3.new(0, yOffset, 0)) * CFrame.Angles(0, yRotation, 0)
-- 		self.ghostModel:PivotTo(targetCFrame)

-- 		-- Show range
-- 		local config = TowerConfig[self.currentTowerName]
-- 		if config then
-- 			self:ShowRange(mousePos, config.Range)
-- 		end
-- 	else
-- 		self:HideRange()
-- 	end
-- end

-- function PlacementSystem:UpdateHover()
-- 	if self.selectedTower then
-- 		return
-- 	end

-- 	local mouseRay = self.mouse.UnitRay
-- 	local raycastParams = RaycastParams.new()
-- 	local towersFolder = Workspace:FindFirstChild("Towers")

-- 	if not towersFolder then
-- 		self:HideRange()
-- 		return
-- 	end

-- 	raycastParams.FilterType = Enum.RaycastFilterType.Include
-- 	raycastParams.FilterDescendantsInstances = { towersFolder }

-- 	local result = Workspace:Raycast(mouseRay.Origin, mouseRay.Direction * RAY_DISTANCE, raycastParams)
-- 	if result then
-- 		local model = result.Instance:FindFirstAncestorOfClass("Model")
-- 		if model and TowerConfig[model.Name] then
-- 			self:ShowRange(model:GetPivot().Position, TowerConfig[model.Name].Range)
-- 			return
-- 		end
-- 	end

-- 	self:HideRange()
-- end

-- function PlacementSystem:GetMouseWorldPosition(): Vector3?
-- 	local mouseRay = self.mouse.UnitRay
-- 	local raycastParams = RaycastParams.new()
-- 	raycastParams.FilterType = Enum.RaycastFilterType.Exclude
-- 	raycastParams.FilterDescendantsInstances = { self.ghostModel, self.player.Character }

-- 	local result = Workspace:Raycast(mouseRay.Origin, mouseRay.Direction * RAY_DISTANCE, raycastParams)
-- 	return result and result.Position
-- end

-- function PlacementSystem:ConfirmPlacement()
-- 	if not self.isPlacing or not self.currentTowerName or not self.targetPosition then
-- 		return
-- 	end

-- 	Network.PlaceTower.send({
-- 		TowerName = self.currentTowerName,
-- 		Position = self.targetPosition,
-- 	})

-- 	self:CancelPlacement()
-- end

-- function PlacementSystem:RotateGhost()
-- 	if not self.ghostModel then
-- 		return
-- 	end
-- 	self.ghostModel:PivotTo(self.ghostModel:GetPivot() * CFrame.Angles(0, math.rad(90), 0))
-- end

-- function PlacementSystem:CancelPlacement()
-- 	self.isPlacing = false
-- 	self.currentTowerName = nil
-- 	if self.ghostModel then
-- 		self.ghostModel:Destroy()
-- 		self.ghostModel = nil
-- 	end
-- 	self:HideRange()
-- end

-- return PlacementSystem
