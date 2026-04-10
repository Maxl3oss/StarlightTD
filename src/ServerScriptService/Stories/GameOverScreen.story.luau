local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)
local GameOverScreen = require(RS.Components.GameOverScreen)

local controls = {
	Visible = true,
}

type Props = { target: Instance, controls: typeof(controls) }

local story = {
	fusion = Fusion,
	controls = controls,
	story = function(props: Props)
		local component = GameOverScreen({
			Visible = props.controls.Visible,
			OnRestart = function()
				print("Restart clicked in Story!")
			end,
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
