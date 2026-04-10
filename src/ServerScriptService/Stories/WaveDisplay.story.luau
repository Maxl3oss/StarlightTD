local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)
local WaveDisplay = require(RS.Components.WaveDisplay)

local controls = {
	Wave = 1,
	IsRunning = false,
	Countdown = 0,
}

type Props = { target: Instance, controls: typeof(controls) }

local story = {
	fusion = Fusion,
	controls = controls,
	story = function(props: Props)
		local component = WaveDisplay({
			Wave = props.controls.Wave,
			IsRunning = props.controls.IsRunning,
			Countdown = props.controls.Countdown,
			OnNextWave = function()
				print("Next wave clicked!")
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
