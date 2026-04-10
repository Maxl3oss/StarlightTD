local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)
local CoinsDisplay = require(RS.Components.CoinsDisplay)

local controls = {
	Coins = 300,
}

type Props = { target: Instance, controls: typeof(controls) }

local story = {
	fusion = Fusion,
	controls = controls,
	story = function(props: Props)
		local component = CoinsDisplay({
			Coins = props.controls.Coins,
			Parent = props.target,
		})

		return function()
			if component then
				component:Destroy()
			end
		end
	end,
}

return story
