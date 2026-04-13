local AssetSystem = {}
AssetSystem.__index = AssetSystem

-- Services
local RS = game:GetService("ReplicatedStorage")
local SStorage = game:GetService("ServerStorage")

function AssetSystem:Init()
	-- Create Assets folder in ReplicatedStorage if it doesn't exist
	local assets = RS:FindFirstChild("Assets") or Instance.new("Folder")
	assets.Name = "Assets"
	assets.Parent = RS

	local towers = assets:FindFirstChild("Towers") or Instance.new("Folder")
	towers.Name = "Towers"
	towers.Parent = assets

	-- Move tower models from ServerStorage to ReplicatedStorage (Stripped of logic)
	local sourceTowers = SStorage:FindFirstChild("Towers")
	if sourceTowers then
		for _, tower in ipairs(sourceTowers:GetChildren()) do
			local clone = tower:Clone()
			
			-- Remove server-side logic scripts before sending to Client
			local logic = clone:FindFirstChild("Logic")
			if logic then
				logic:Destroy()
			end
			
			clone.Parent = towers
		end
	end
end

return AssetSystem
