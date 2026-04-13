local VfxSystem = {}
VfxSystem.__index = VfxSystem

local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Network = require(RS.Network)
local TowerConfig = require(RS.Configs.TowerConfig)
local TweenService = game:GetService("TweenService")

function VfxSystem:Init() end

function VfxSystem:Start()
	Network.TowerShoot:OnEvent(
		function(data: { From: Vector3, To: Vector3, TowerName: string, TowerInstance: Instance })
			local config = TowerConfig[data.TowerName]
			if not config then
				return
			end

			-- Detect muzzle for accurate start
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
				self:CreateMeleePulse(data.To, config.BlastRadius or 12)
				if data.TowerInstance and data.TowerName == "Potato" then
					self:AnimatePotato(data.TowerInstance, config.FireRate or 0.8)
				end
			elseif style == "Arrow" then
				self:CreateArrow(startPos, data.To)
			elseif style == "Meteor" then
				self:CreateMeteor(data.To, config.BlastRadius or 15)
			else
				-- Fallback
				self:CreateLaser(startPos, data.To)
			end
		end
	)
end

function VfxSystem:CreateLaser(from: Vector3, to: Vector3)
	local distance = (from - to).Magnitude
	if distance < 0.1 then
		return
	end

	local part = Instance.new("Part")
	part.Name = "LaserEffect"
	part.Size = Vector3.new(0.2, 0.2, distance)
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Color = Color3.fromRGB(255, 0, 0)
	part.Material = Enum.Material.Neon
	part.Transparency = 0.2
	part.CFrame = CFrame.new(from:Lerp(to, 0.5), to)
	part.Parent = Workspace

	task.delay(0.05, function()
		if part.Parent then
			part:Destroy()
		end
	end)
end

function VfxSystem:CreateArrow(from: Vector3, to: Vector3)
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.3, 0.3, 2)
	part.Color = Color3.fromRGB(241, 196, 15)
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false
	part.CFrame = CFrame.new(from, to)
	part.Parent = Workspace

	local duration = (to - from).Magnitude / 200
	local tween = TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.Linear), {
		CFrame = CFrame.new(to, to + (to - from).Unit),
	})
	tween:Play()
	tween.Completed:Connect(function()
		part:Destroy()
	end)
end

function VfxSystem:CreateMeteor(targetPos: Vector3, radius: number)
	local skyPos = targetPos + Vector3.new(0, 50, 0)
	local part = Instance.new("Part")
	part.Size = Vector3.new(3, 3, 3)
	part.Shape = Enum.PartType.Ball
	part.Color = Color3.fromRGB(231, 76, 60)
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false
	part.Position = skyPos
	part.Parent = Workspace

	local duration = 0.5
	local tween = TweenService:Create(part, TweenInfo.new(duration, Enum.EasingStyle.QuadIn), {
		Position = targetPos,
	})

	tween:Play()
	tween.Completed:Connect(function()
		part:Destroy()
		self:CreateExplosion(targetPos, radius, Color3.fromRGB(231, 76, 60))
	end)
end

local Debris = game:GetService("Debris")

function VfxSystem:CreateMeleePulse(position: Vector3, radius: number)
	-- Shockwave Disc (Faint & Ghostly)
	local part = Instance.new("Part")
	part.Size = Vector3.new(0.05, radius * 1.5, radius * 1.5)
	part.Shape = Enum.PartType.Cylinder
	part.Anchored = true
	part.CanCollide = false
	part.Position = position
	part.CFrame = CFrame.new(part.Position) * CFrame.Angles(0, 0, math.rad(90))

	part.Color = Color3.fromRGB(255, 0, 0)
	part.Material = Enum.Material.Neon
	part.Transparency = 0.7 -- Fainter visibility
	part.Parent = Workspace

	-- Safe cleanup
	Debris:AddItem(part, 0.4)

	local tween = TweenService:Create(part, TweenInfo.new(0.2, Enum.EasingStyle.QuartOut), {
		Size = Vector3.new(0.05, radius * 2.8, radius * 2.8),
		Transparency = 1,
	})
	tween:Play()
end

function VfxSystem:AnimatePotato(model: Instance, fireRate: number)
	local originalCFrame = model:GetPivot()
	local jumpHeight = 2
	local jumpCFrame = originalCFrame * CFrame.new(0, jumpHeight, 0)

	-- Scale animation to 50% of fire rate to ensure it finishes before next shot
	local totalAnimTime = math.min(fireRate * 0.5, 0.4)
	local jumpTime = totalAnimTime * 0.4
	local fallTime = totalAnimTime * 0.6

	local jump = TweenService:Create(model, TweenInfo.new(jumpTime, Enum.EasingStyle.Sine, Enum.EasingDirection.Out), {
		CFrame = jumpCFrame,
	})

	jump:Play()
	jump.Completed:Connect(function()
		local fall =
			TweenService:Create(model, TweenInfo.new(fallTime, Enum.EasingStyle.Bounce, Enum.EasingDirection.Out), {
				CFrame = originalCFrame,
			})
		fall:Play()
	end)
end

function VfxSystem:CreateExplosion(position: Vector3, radius: number, color: Color3)
	local part = Instance.new("Part")
	part.Size = Vector3.new(1, 1, 1)
	part.Shape = Enum.PartType.Ball
	part.Anchored = true
	part.CanCollide = false
	part.Position = position
	part.Color = color or Color3.fromRGB(155, 89, 182)
	part.Material = Enum.Material.Neon
	part.Transparency = 0.3
	part.Parent = Workspace

	local tween = TweenService:Create(part, TweenInfo.new(0.3, Enum.EasingStyle.QuartOut), {
		Size = Vector3.new(radius * 2, radius * 2, radius * 2),
		Transparency = 1,
	})

	tween:Play()
	tween.Completed:Connect(function()
		part:Destroy()
	end)
end

return VfxSystem
