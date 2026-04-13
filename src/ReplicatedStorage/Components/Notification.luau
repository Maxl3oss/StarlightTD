local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)

local Notification = {}

function Notification.New(scope, data: { Message: string, Type: string })
	local Children = Fusion.Children
	local transparency = scope:Value(1)

	local color = Color3.fromRGB(44, 62, 80) -- Default Dark
	if data.Type == "Error" then
		color = Color3.fromRGB(192, 57, 43) -- Red
	elseif data.Type == "Success" then
		color = Color3.fromRGB(39, 174, 96) -- Green
	end

	local component = scope:New("Frame")({
		Name = "Notification",
		Size = UDim2.fromOffset(250, 50),
		BackgroundColor3 = color,
		BorderSizePixel = 0,
		BackgroundTransparency = transparency,
		Position = UDim2.new(0.5, 0, 0.1, 0),
		AnchorPoint = Vector2.new(0.5, 0),

		[Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(0, 8) }),
			scope:New("UIStroke")({
				Thickness = 2,
				Color = Color3.new(1, 1, 1),
				Transparency = transparency,
			}),
			scope:New("TextLabel")({
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = data.Message,
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 16,
				Font = Enum.Font.GothamBold,
				TextTransparency = transparency,
			}),
		},
	})

	-- Simple animation loop
	task.spawn(function()
		-- Fade in
		for i = 1, 0, -0.1 do
			transparency:set(i)
			task.wait(0.02)
		end
		transparency:set(0)

		task.wait(2)

		-- Fade out
		for i = 0, 1, 0.1 do
			transparency:set(i)
			task.wait(0.02)
		end
		
		-- Component will be cleaned up by scope or manually
		component:Destroy()
	end)

	return component
end

return Notification
