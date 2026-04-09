local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)
local MoneyText = require(RS.Components.MoneyText)

local controls = {
	Money = 1500,
}

type Props = { target: Instance, controls: typeof(controls) }

local story = {
	fusion = Fusion,
	controls = controls,
	story = function(props: Props)
		local component = MoneyText({
			Money = props.controls.Money,
			Parent = props.target,
			State = "Story",
		})

		return function()
			if component then
				component:Destroy()
			end
		end
	end,
}

return story
