local mob = script.Parent
local humanoid: Humanoid = mob:WaitForChild("Humanoid")
local root: BasePart = mob:WaitForChild("HumanoidRootPart")

local JUMP_INTERVAL = 1
local JUMP_POWER = 40

humanoid.UseJumpPower = true
humanoid.JumpPower = JUMP_POWER

root.Anchored = false
root:SetNetworkOwner(nil)

local function isMoving()
	return root.AssemblyLinearVelocity.Magnitude > 1
end

local function canJump()
	return humanoid.FloorMaterial ~= Enum.Material.Air
end

task.spawn(function()
	while humanoid and humanoid.Parent and humanoid.Health > 0 do
		if isMoving() and canJump() then
			humanoid:ChangeState(Enum.HumanoidStateType.Jumping)
		end

		task.wait(JUMP_INTERVAL)
	end
end)
