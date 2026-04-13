local VfxSystem = {}

local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local TweenService = game:GetService("TweenService")
local Debris = game:GetService("Debris")

local Network = require(RS.Network)
local TowerConfig = require(RS.Configs.TowerConfig)
local Helper = require(RS.Utils.Helper)

-- ========================
-- INIT
-- ========================
function VfxSystem:Init() end

function VfxSystem:Start()
	Network.TowerShoot:OnEvent(function(data)
		local config = TowerConfig[data.TowerName]
		if not config then
			return
		end

		local visualRadius = data.Radius or config.BlastRadius or 12

		local startPos = data.From
		if data.TowerInstance then
			local muzzle = data.TowerInstance:FindFirstChild("Muzzle", true)
				or data.TowerInstance:FindFirstChild("Head", true)
			if muzzle then
				startPos = muzzle.Position
			end
		end

		local style = config.VfxStyle

		if style == "MeleePulse" then
			self:CreateMeleePulse(data.To, visualRadius)
			self:CameraShake(2)
		elseif style == "Arrow" then
			self:CreateArrow(startPos, data.To)
		elseif style == "Meteor" then
			self:CreateMeteor(data.To, visualRadius)
			self:CameraShake(3)
		else
			self:CreateLaser(startPos, data.To)
		end
	end)
end

-- ========================
-- CAMERA SHAKE
-- ========================
function VfxSystem:CameraShake(intensity)
	local cam = Workspace.CurrentCamera
	if not cam then
		return
	end

	local original = cam.CFrame

	for i = 1, 3 do
		cam.CFrame = original
			* CFrame.new(math.random(-intensity, intensity) / 12, math.random(-intensity, intensity) / 12, 0)
		task.wait(0.02)
	end

	cam.CFrame = original
end

-- ========================
-- BIG SPARK ✨
-- ========================
function VfxSystem:AddSpark(parent: Instance, color: Color3)
	local emitter = Instance.new("ParticleEmitter")

	emitter.Texture = "rbxasset://textures/particles/sparkles_main.dds"
	emitter.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, color),
		ColorSequenceKeypoint.new(1, Color3.new(1, 1, 1)),
	})

	emitter.LightEmission = 1

	-- 🔥 กระจายไกล + พุ่งแรง
	emitter.Speed = NumberRange.new(30, 80)
	emitter.Lifetime = NumberRange.new(0.4, 0.8)
	emitter.SpreadAngle = Vector2.new(360, 360)

	-- 🔥 ใหญ่ขึ้น
	emitter.Size = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 1.2),
		NumberSequenceKeypoint.new(0.3, 0.8),
		NumberSequenceKeypoint.new(1, 0),
	})

	-- fade
	emitter.Transparency = NumberSequence.new({
		NumberSequenceKeypoint.new(0, 0),
		NumberSequenceKeypoint.new(0.7, 0.3),
		NumberSequenceKeypoint.new(1, 1),
	})

	-- gravity
	emitter.Acceleration = Vector3.new(0, -20, 0)

	emitter.Rate = 0
	emitter.Parent = parent

	-- 🔥 ยิงเยอะขึ้น
	emitter:Emit(80)

	Debris:AddItem(emitter, 1.2)
end

-- ========================
-- LASER
-- ========================
function VfxSystem:CreateLaser(from: Vector3, to: Vector3)
	local p0 = Instance.new("Part")
	p0.Anchored = true
	p0.Transparency = 1
	p0.CanCollide = false
	p0.CastShadow = false
	p0.Position = from
	p0.Parent = Workspace

	local p1 = Instance.new("Part")
	p1.Anchored = true
	p1.Transparency = 1
	p1.CanCollide = false
	p1.CastShadow = false
	p1.Position = to
	p1.Parent = Workspace

	local att0 = Instance.new("Attachment", p0)
	local att1 = Instance.new("Attachment", p1)

	local beam = Instance.new("Beam")
	beam.Attachment0 = att0
	beam.Attachment1 = att1
	beam.Width0 = 0.6
	beam.Width1 = 0.2
	beam.LightEmission = 1
	beam.Transparency = NumberSequence.new(0)
	beam.Parent = p0

	task.delay(0.05, function()
		TweenService:Create(beam, TweenInfo.new(0.2), {
			Transparency = NumberSequence.new(1),
		}):Play()
	end)

	Debris:AddItem(p0, 0.3)
	Debris:AddItem(p1, 0.3)
end

-- ========================
-- ARROW
-- ========================
function VfxSystem:CreateArrow(from: Vector3, to: Vector3)
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.3, 0.3, 2)
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 200, 50)
	part.CFrame = CFrame.new(from, to)
	part.Parent = Workspace

	local att0 = Instance.new("Attachment", part)
	local att1 = Instance.new("Attachment", part)

	local trail = Instance.new("Trail")
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Lifetime = 0.25
	trail.Parent = part

	local duration = (to - from).Magnitude / 200

	TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(to, to + (to - from).Unit),
	}):Play()

	self:AddSpark(part, part.Color)

	task.delay(duration - 0.1, function()
		TweenService:Create(part, TweenInfo.new(0.15), {
			Transparency = 1,
		}):Play()
	end)

	Debris:AddItem(part, duration + 0.2)
end

-- ========================
-- METEOR
-- ========================
function VfxSystem:CreateMeteor(targetPos: Vector3, radius: number)
	local skyPos = targetPos + Vector3.new(0, 50, 0)

	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(3, 3, 3)
	part.Material = Enum.Material.Neon
	part.Color = Color3.fromRGB(255, 80, 50)
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Position = skyPos
	part.Parent = Workspace

	local att0 = Instance.new("Attachment", part)
	local att1 = Instance.new("Attachment", part)

	local trail = Instance.new("Trail")
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Lifetime = 0.3
	trail.Parent = part

	TweenService:Create(part, TweenInfo.new(0.6, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Position = targetPos,
	}):Play()

	task.delay(0.6, function()
		self:AddSpark(part, part.Color)
		part:Destroy()
		self:CreateExplosion(targetPos, radius, part.Color)
	end)
end

-- ========================
-- EXPLOSION
-- ========================
function VfxSystem:CreateExplosion(position: Vector3, radius: number, color: Color3)
	local core = Instance.new("Part")
	core.Shape = Enum.PartType.Ball
	core.Size = Vector3.new(1, 1, 1)
	core.Anchored = true
	core.CanCollide = false
	core.CastShadow = false
	core.Material = Enum.Material.Neon
	core.Color = color
	core.Transparency = 0.2
	core.Position = position
	core.Parent = Workspace

	local light = Instance.new("PointLight")
	light.Brightness = 8
	light.Range = radius * 5
	light.Color = color
	light.Parent = core

	local ring = Instance.new("Part")
	ring.Shape = Enum.PartType.Cylinder
	ring.Size = Vector3.new(0.2, 1, 1)
	ring.CFrame = CFrame.new(position) * CFrame.Angles(math.rad(90), 0, 0)
	ring.Anchored = true
	ring.CanCollide = false
	ring.CastShadow = false
	ring.Material = Enum.Material.Neon
	ring.Color = color
	ring.Transparency = 0.4
	ring.Parent = Workspace

	-- ⭐ spark 2 ชั้น
	self:AddSpark(core, color)
	self:AddSpark(core, Color3.new(1, 1, 1))

	TweenService:Create(core, TweenInfo.new(0.35, Enum.EasingStyle.Quad), {
		Size = Vector3.new(radius * 2, radius * 2, radius * 2),
	}):Play()

	TweenService:Create(ring, TweenInfo.new(0.4, Enum.EasingStyle.Quart), {
		Size = Vector3.new(0.2, radius * 4, radius * 4),
	}):Play()

	task.delay(0.2, function()
		TweenService:Create(core, TweenInfo.new(0.4), {
			Transparency = 1,
		}):Play()

		TweenService:Create(ring, TweenInfo.new(0.5), {
			Transparency = 1,
		}):Play()

		TweenService:Create(light, TweenInfo.new(0.4), {
			Brightness = 0,
		}):Play()
	end)

	Debris:AddItem(core, 0.8)
	Debris:AddItem(ring, 0.8)
end

-- ========================
-- MELEE
-- ========================
function VfxSystem:CreateMeleePulse(position: Vector3, radius: number)
	local diameter = Helper.getDiameter(radius)

	local part = Instance.new("Part")
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(1, 1, 1)
	part.Anchored = true
	part.CanCollide = false
	part.CastShadow = false
	part.Material = Enum.Material.ForceField
	part.Color = Color3.fromRGB(255, 170, 0)
	part.Transparency = 0.4
	part.Position = position
	part.Parent = Workspace

	self:AddSpark(part, part.Color)
	self:AddSpark(part, Color3.new(1, 1, 1))

	TweenService:Create(part, TweenInfo.new(0.5, Enum.EasingStyle.Quart), {
		Size = Vector3.new(diameter, diameter, diameter),
	}):Play()

	task.delay(0.25, function()
		TweenService:Create(part, TweenInfo.new(0.4), {
			Transparency = 1,
		}):Play()
	end)

	Debris:AddItem(part, 0.7)
end

return VfxSystem
