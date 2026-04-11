local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)
local WorldHP = require(RS.Components.WorldHP)

local controls = {
	Health = 75,
	MaxHealth = 100,
}

type Props = { target: Instance, controls: typeof(controls) }

local story = {
	fusion = Fusion,
	controls = controls,
	story = function(props: Props)
		local part = Instance.new("Part")
		part.Size = Vector3.new(4, 4, 4)
		part.Position = Vector3.new(0, 5, 0)
		part.Anchored = true
		part.Parent = props.target
		
		local component = WorldHP({
			Health = props.controls.Health,
			MaxHealth = props.controls.MaxHealth,
			Adornee = part,
			Name = "BossHP"
		})

		return function()
			part:Destroy()
			if component then
				component:Destroy()
			end
		end
	end,
}

return story
