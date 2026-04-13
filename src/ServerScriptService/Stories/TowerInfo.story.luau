local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)
local TowerInfo = require(RS.Components.TowerInfo)

local controls = {
	TowerName = "Potato",
	Level = 1,
}

type Props = { target: Instance, controls: typeof(controls) }

local story = {
	fusion = Fusion,
	controls = controls,
	story = function(props: Props)
		local scope = Fusion.scoped(Fusion)
		
		local component = TowerInfo(scope, {
			TowerName = props.controls.TowerName,
			Level = props.controls.Level,
			OnUpgrade = function()
				print("Upgrade requested in story!")
			end,
			OnClose = function()
				print("Close requested in story!")
			end,
		})
		
		if component then
			component.Parent = props.target
		end

		return function()
			scope:doCleanup()
			if component then
				component:Destroy()
			end
		end
	end,
}

return story
