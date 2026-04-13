local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)

local Children = Fusion.Children

return function(scope, props: {
	Message: string,
	Type: string, -- "Info", "Error", "Success"
})
	local transparency = scope:Value(1)

	local color = Color3.fromRGB(44, 62, 80) -- Default Dark
	if props.Type == "Error" then
		color = Color3.fromRGB(192, 57, 43) -- Red
	elseif props.Type == "Success" then
		color = Color3.fromRGB(39, 174, 96) -- Green
	end

	local component = scope:New("Frame")({
		Name = "Notification",
		Size = UDim2.fromOffset(280, 55),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		BackgroundTransparency = transparency,
		Position = UDim2.new(0.5, 0, 0.1, 0),
		AnchorPoint = Vector2.new(0.5, 0),

		[Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(0, 10) }),
			scope:New("UIStroke")({
				Thickness = 2.5,
				Color = Color3.new(1, 1, 1),
				Transparency = transparency,
			}),
			scope:New("TextLabel")({
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = props.Message,
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 16,
				Font = Enum.Font.GothamBold,
				TextTransparency = transparency,
			}),
		},
	})

	-- Animation loop
	task.spawn(function()
		-- Fade in
		for i = 1, 0, -0.1 do
			transparency:set(i)
			task.wait(0.02)
		end
		transparency:set(0)

		task.wait(2.5)

		-- Fade out
		for i = 0, 1, 0.1 do
			transparency:set(i)
			task.wait(0.02)
		end
		
		component:Destroy()
	end)

	return component
end
