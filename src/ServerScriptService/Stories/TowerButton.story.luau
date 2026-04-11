local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)
local TowerButton = require(RS.Components.TowerButton)

local controls = {
	Name = "Archer",
	Cost = 150,
}

type Props = { target: Instance, controls: typeof(controls) }

local story = {
	fusion = Fusion,
	controls = controls,
	story = function(props: Props)
		-- Setup a temporary dummy model for story preview if it doesn't exist
		local assets = RS:FindFirstChild("Assets") or Instance.new("Folder", RS)
		assets.Name = "Assets"
		local towers = assets:FindFirstChild("Towers") or Instance.new("Folder", assets)
		towers.Name = "Towers"
		
		local name = Fusion.peek(props.controls.Name)
		local dummy = towers:FindFirstChild(name)
		local createdDummy = false
		if not dummy then
			dummy = Instance.new("Model", towers)
			dummy.Name = name
			local p = Instance.new("Part", dummy)
			p.Size = Vector3.new(4, 4, 4)
			p.BrickColor = BrickColor.random()
			createdDummy = true
		end

		local component = TowerButton({
			Name = props.controls.Name,
			Cost = props.controls.Cost,
			OnClick = function()
				print("Tower clicked in story")
			end,
			Parent = props.target,
		})

		return function()
			if component then component:Destroy() end
			if createdDummy and dummy then dummy:Destroy() end
		end
	end,
}

return story
