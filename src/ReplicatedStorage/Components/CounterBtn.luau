local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)

local Scoped = Fusion.scoped
local Peek = Fusion.peek

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

type UsedAs<T> = Fusion.UsedAs

local scope = Scoped({
	New = Fusion.New,
	Value = Fusion.Value,
})

return function(props: {
	BackgroundColor3: UsedAs<Color3>?,
	Parent: Instance?,
})
	local counter = scope:Value(0)

	return scope:New("TextButton")({
		Text = counter,
		TextScaled = true,
		BackgroundColor3 = props.BackgroundColor3 or Color3.new(0.003921, 0.901960, 0.854901),
		Parent = props.Parent,

		Size = UDim2.fromScale(0.5, 0.5),
		Position = UDim2.fromScale(0.5, 0.5),
		AnchorPoint = Vector2.new(0.5, 0.5),

		[OnEvent("Activated")] = function()
			counter:set(Peek(counter) + 1)
		end,

		[Children] = {
			scope:New("UICorner")({
				CornerRadius = UDim.new(0, 10),
			}),
		},
	})
end
