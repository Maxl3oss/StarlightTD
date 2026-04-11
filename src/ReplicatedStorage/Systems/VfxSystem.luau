local VfxSystem = {}
VfxSystem.__index = VfxSystem

local RS = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")
local Network = require(RS.Network)

function VfxSystem:Init()
end

function VfxSystem:Start()
	Network.TowerShoot.listen(function(data)
		self:CreateLaser(data.From, data.To)
	end)
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

return VfxSystem
