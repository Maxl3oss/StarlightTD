local PhysicsSystemGroup = {}
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

PhysicsService:RegisterCollisionGroup("Mobs")
PhysicsService:RegisterCollisionGroup("Towers")
PhysicsService:RegisterCollisionGroup("Players")

function PhysicsSystemGroup:Init()
	PhysicsService:CollisionGroupSetCollidable("Mobs", "Players", false)
	PhysicsService:CollisionGroupSetCollidable("Mobs", "Mobs", false)
	PhysicsService:CollisionGroupSetCollidable("Towers", "Mobs", false)
	PhysicsService:CollisionGroupSetCollidable("Towers", "Players", false)

	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function(character)
			for _, obj in ipairs(character:GetDescendants()) do
				if obj:IsA("BasePart") then
					obj.CollisionGroup = "Players"
				end
			end
		end)
	end)
end

return PhysicsSystemGroup
