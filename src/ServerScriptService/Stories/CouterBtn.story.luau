local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)
local CouterBtn = require(RS.Components.CounterBtn)

local controls = {
	BackgroundColor = Color3.new(0.050980, 0.839215, 0.050980),
}

type Props = { target: Instance, controls: typeof(controls) }

local story = {
	fusion = Fusion,
	controls = controls,
	story = function(props: Props)
		local component = CouterBtn({
			BackgroundColor3 = props.controls.BackgroundColor,
			Parent = props.target,
		})
	end,
}

return story
