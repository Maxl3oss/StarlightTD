local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)

local Scoped = Fusion.scoped
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

type UsedAs<T> = Fusion.Value<T> | Fusion.Computed<T>

return function(props: {
	Visible: UsedAs<boolean>,
	Won: UsedAs<boolean>,
	OnRestart: () -> (),
	Parent: Instance?,
})
	local scope = Scoped({
		New = Fusion.New,
		Computed = Fusion.Computed,
		Spring = Fusion.Spring,
	})

	local transparency = scope:Spring(scope:Computed(function(use)
		return use(props.Visible) and 0 or 1
	end), 15, 1)

	local component = scope:New("Frame")({
		Name = "GameOverScreen",
		Size = UDim2.fromScale(1, 1),
		BackgroundColor3 = Color3.fromRGB(0, 0, 0),
		BackgroundTransparency = scope:Computed(function(use)
			return 0.4 + (use(transparency) * 0.6)
		end),
		Visible = props.Visible,
		Parent = props.Parent,
		ZIndex = 100,

		[Children] = {
			scope:New("Frame")({
				Name = "Content",
				Size = UDim2.fromOffset(400, 300),
				Position = UDim2.new(0.5, 0, 0.5, 0),
				AnchorPoint = Vector2.new(0.5, 0.5),
				BackgroundColor3 = Color3.fromRGB(44, 62, 80),

				[Children] = {
					scope:New("UICorner")({ CornerRadius = UDim.new(0, 16) }),
					scope:New("UIStroke")({ Thickness = 4, Color = Color3.fromRGB(0, 0, 0) }),

					scope:New("TextLabel")({
						Size = UDim2.new(1, 0, 0, 100),
						BackgroundTransparency = 1,
						Text = scope:Computed(function(use)
							return use(props.Won) and "VICTORY" or "DEFEAT"
						end),
						TextColor3 = scope:Computed(function(use)
							return use(props.Won) and Color3.fromRGB(46, 204, 113) or Color3.fromRGB(231, 76, 60)
						end),
						Font = Enum.Font.FredokaOne,
						TextSize = 80,

						[Children] = {
							scope:New("UIStroke")({ Thickness = 3, Color = Color3.fromRGB(0, 0, 0) })
						}
					}),

					scope:New("TextLabel")({
						Size = UDim2.new(1, 0, 0, 40),
						Position = UDim2.new(0, 0, 0, 100),
						BackgroundTransparency = 1,
						Text = scope:Computed(function(use)
							return use(props.Won) and "ALL WAVES CLEARED!" or "THE BASE HAS FALLEN"
						end),
						TextColor3 = Color3.fromRGB(189, 195, 199),
						Font = Enum.Font.FredokaOne,
						TextSize = 24,
					}),

					scope:New("TextButton")({
						Name = "RestartButton",
						Size = UDim2.new(0, 240, 0, 60),
						Position = UDim2.new(0.5, 0, 1, -80),
						AnchorPoint = Vector2.new(0.5, 0),
						BackgroundColor3 = Color3.fromRGB(46, 204, 113),
						Text = "RESTART",
						TextColor3 = Color3.fromRGB(255, 255, 255),
						Font = Enum.Font.FredokaOne,
						TextSize = 30,

						[Children] = {
							scope:New("UICorner")({ CornerRadius = UDim.new(0, 12) }),
							scope:New("UIStroke")({ Thickness = 3, Color = Color3.fromRGB(0, 0, 0) }),
							scope:New("UIGradient")({
								Color = ColorSequence.new({
									ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
									ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200)),
								}),
								Rotation = 90,
							})
						},

						[OnEvent("Activated")] = function()
							props.OnRestart()
						end
					})
				}
			})
		}
	})

	return component
end
