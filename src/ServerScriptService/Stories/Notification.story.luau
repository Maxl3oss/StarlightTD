local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)
local Notification = require(RS.Components.Notification)

local controls = {
	Message = "Example Notification Message",
	Type = "Info", -- Example types: "Info", "Error", "Success"
}

type Props = { target: Instance, controls: typeof(controls) }

local story = {
	fusion = Fusion,
	controls = controls,
	story = function(props: Props)
		local scope = Fusion.scoped(Fusion)
		
		-- Create and parent the notification
		local component = Notification.New(scope, {
			Message = props.controls.Message,
			Type = props.controls.Type,
		})
		component.Parent = props.target

		return function()
			scope:doCleanup()
			if component then
				component:Destroy()
			end
		end
	end,
}

return story
