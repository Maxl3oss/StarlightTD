local RS = game:GetService("ReplicatedStorage")

-- ByteNet yield fix for Storybook/Studio context
if not RS:FindFirstChild("BytenetStorage") then
	local folder = Instance.new("Folder")
	folder.Name = "BytenetStorage"
	folder.Parent = RS
end

local VfxSystem = require(RS.Systems.VfxSystem)

local controls = {}

local story = {
	controls = controls,
	story = function(props)
		local frame = Instance.new("Frame")
		frame.Size = UDim2.fromScale(1, 1)
		frame.BackgroundTransparency = 1
		frame.Parent = props.target

		local textLabel = Instance.new("TextLabel")
		textLabel.Size = UDim2.new(1, 0, 0, 50)
		textLabel.Text = "VfxSystem Story: Click the button to test laser effect"
		textLabel.BackgroundTransparency = 1
		textLabel.TextColor3 = Color3.new(1, 1, 1)
		textLabel.Font = Enum.Font.FredokaOne
		textLabel.TextSize = 20
		textLabel.Parent = frame

		local button = Instance.new("TextButton")
		button.Size = UDim2.fromOffset(200, 60)
		button.Position = UDim2.fromScale(0.5, 0.5)
		button.AnchorPoint = Vector2.new(0.5, 0.5)
		button.Text = "SHOOT LASER"
		button.BackgroundColor3 = Color3.fromRGB(231, 76, 60)
		button.TextColor3 = Color3.new(1, 1, 1)
		button.Font = Enum.Font.FredokaOne
		button.TextSize = 24
		button.Parent = frame

		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 12)
		corner.Parent = button

		local connection = button.Activated:Connect(function()
			-- Shoot from a high point to a random point on ground
			local from = Vector3.new(0, 15, 0)
			local to = Vector3.new(math.random(-25, 25), 0, math.random(-25, 25))
			VfxSystem:CreateLaser(from, to)
		end)

		return function()
			connection:Disconnect()
			frame:Destroy()
		end
	end,
}

return story
