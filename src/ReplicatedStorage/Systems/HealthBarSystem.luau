local RS = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

local HealthBarSystem = {}

function HealthBarSystem:Init()
	self.connections = {}
	self.billboards = {}
end

function HealthBarSystem:Start()
	-- Handle existing mobs and new ones
	Workspace.ChildAdded:Connect(function(child)
		self:HandleNewChild(child)
	end)

	for _, child in ipairs(Workspace:GetChildren()) do
		self:HandleNewChild(child)
	end

	-- Handle TowerCore
	local base = Workspace:WaitForChild("Base", 5)
	if base then
		local towerCore = base:WaitForChild("TowerCore", 5)
		if towerCore then
			self:SetupCoreHealthBar(towerCore)
		end
	end
end

function HealthBarSystem:HandleNewChild(child: Instance)
	if child:IsA("Model") and child:GetAttribute("IsMob") then
		self:SetupMobHealthBar(child)
	end

	-- In case attributes are set slightly after child added
	task.delay(0.1, function()
		if child:IsA("Model") and child:GetAttribute("IsMob") and not self.billboards[child] then
			self:SetupMobHealthBar(child)
		end
	end)
end

function HealthBarSystem:SetupMobHealthBar(mob: Model)
	local humanoid = mob:WaitForChild("Humanoid", 5) :: Humanoid
	if not humanoid then
		return
	end

	local enemyName = mob.Name
	local displayName = string.upper(enemyName)

	local billboard = self:CreateBillboardHP(mob, humanoid.Health, humanoid.MaxHealth, "MobHP", displayName)
	self.billboards[mob] = billboard

	local conn = humanoid.HealthChanged:Connect(function(health)
		self:UpdateBillboardHP(billboard, health, humanoid.MaxHealth)
	end)

	mob.Destroying:Connect(function()
		conn:Disconnect()
		self.billboards[mob] = nil
	end)
end

function HealthBarSystem:SetupCoreHealthBar(towerCore: Instance)
	-- The server broadcasts health via Network.UpdateBaseHealth
	-- But since the Humanoid might not exist on TowerCore, we listen to the network
	local Network = require(RS.Network)

	-- Find initial values
	local health = 100
	local maxHealth = 100

	local billboard = self:CreateBillboardHP(towerCore, health, maxHealth, "CoreHP", "BASE CORE")

	Network.UpdateBaseHealth.listen(function(data)
		self:UpdateBillboardHP(billboard, data.Health, data.MaxHealth)
	end)
end

function HealthBarSystem:CreateBillboardHP(
	adornee: Instance,
	health: number,
	maxHealth: number,
	name: string,
	displayName: string?
)
	local part = adornee:IsA("Model") and (adornee.PrimaryPart or adornee:FindFirstChildWhichIsA("BasePart")) or adornee
	if not part then
		return
	end

	-- Calculate size based on the model if applicable
	local scaleMultiplier = 1
	local heightOffset = 3.5
	if adornee:IsA("Model") then
		local extents = adornee:GetExtentsSize()
		scaleMultiplier = math.clamp(extents.X / 4, 0.8, 2.5)
		heightOffset = extents.Y + 1.5
	end

	local billboard = Instance.new("BillboardGui")
	billboard.Name = name
	billboard.Adornee = part
	billboard.Size = UDim2.fromOffset(60 * scaleMultiplier, 25 * scaleMultiplier)
	billboard.StudsOffset = Vector3.new(0, heightOffset, 0)
	billboard.AlwaysOnTop = true
	billboard.MaxDistance = 150
	billboard.Parent = part

	-- Main Container (HP Bar)
	local background = Instance.new("Frame")
	background.Name = "Background"
	background.Size = UDim2.new(0.8, 0, 0.3, 0)
	background.Position = UDim2.fromScale(0.5, 1)
	background.AnchorPoint = Vector2.new(0.5, 1)
	background.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	background.BackgroundTransparency = 0.2
	background.BorderSizePixel = 0
	background.Parent = billboard

	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 6)
	corner.Parent = background

	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(0, 0, 0)
	stroke.Thickness = 2
	stroke.ApplyStrokeMode = Enum.ApplyStrokeMode.Border
	stroke.Parent = background

	-- HP Fill
	local fill = Instance.new("Frame")
	fill.Name = "Fill"
	fill.Size = UDim2.fromScale(math.clamp(health / maxHealth, 0, 1), 1)
	fill.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
	fill.BorderSizePixel = 0
	fill.ZIndex = 2
	fill.Parent = background

	local fillCorner = Instance.new("UICorner")
	fillCorner.CornerRadius = UDim.new(0, 4)
	fillCorner.Parent = fill

	-- Glassy Shine Effect
	local shine = Instance.new("Frame")
	shine.Name = "Shine"
	shine.Size = UDim2.new(1, 0, 0.4, 0)
	shine.Position = UDim2.fromScale(0, 0)
	shine.BackgroundColor3 = Color3.new(1, 1, 1)
	shine.BackgroundTransparency = 0.8
	shine.BorderSizePixel = 0
	shine.ZIndex = 3
	shine.Parent = background

	local shineCorner = Instance.new("UICorner")
	shineCorner.CornerRadius = UDim.new(0, 4)
	shineCorner.Parent = shine

	-- Text HP
	local text = Instance.new("TextLabel")
	text.Name = "HPText"
	text.Size = UDim2.fromScale(1, 1)
	text.BackgroundTransparency = 1
	text.ZIndex = 4
	text.TextScaled = true
	text.Font = Enum.Font.FredokaOne
	text.TextColor3 = Color3.new(1, 1, 1)
	text.TextStrokeTransparency = 0.4
	text.Text = string.format("%d / %d", health, maxHealth)
	text.Parent = background

	-- Name Label
	if displayName then
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "NameLabel"
		nameLabel.Size = UDim2.new(1, 0, 0, 12)
		nameLabel.Position = UDim2.new(0.5, 0, 0, 0)
		nameLabel.AnchorPoint = Vector2.new(0.5, 0)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = displayName
		nameLabel.TextColor3 = Color3.new(1, 1, 1)
		nameLabel.Font = Enum.Font.FredokaOne
		nameLabel.TextSize = 10
		nameLabel.TextStrokeTransparency = 0.5
		nameLabel.Parent = billboard
	end

	return billboard
end

function HealthBarSystem:UpdateBillboardHP(billboard: BillboardGui, health: number, maxHealth: number)
	local background = billboard:FindFirstChild("Background")
	if not background then
		return
	end

	local fill = background:FindFirstChild("Fill")
	local text = background:FindFirstChild("HPText")
	if not fill or not text then
		return
	end

	local ratio = math.clamp(health / maxHealth, 0, 1)

	-- Tween bar locally (Smooth & No Lag)
	TweenService:Create(fill, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Size = UDim2.fromScale(ratio, 1),
	}):Play()

	-- Update text
	text.Text = string.format("%d / %d", math.floor(health), maxHealth)

	-- Hit effect (Pop)
	local originalScale = background:GetAttribute("OriginalScale") or background.Size
	if not background:GetAttribute("OriginalScale") then
		background:SetAttribute("OriginalScale", originalScale)
	end

	local popScale = UDim2.new(originalScale.X.Scale + 0.1, 0, originalScale.Y.Scale + 0.1, 0)

	local pop = TweenService:Create(background, TweenInfo.new(0.08), { Size = popScale })
	local back = TweenService:Create(background, TweenInfo.new(0.08), { Size = originalScale })

	pop:Play()
	pop.Completed:Connect(function()
		back:Play()
	end)
end

return HealthBarSystem
