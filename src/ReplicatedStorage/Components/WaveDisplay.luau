local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)

local Scoped = Fusion.scoped
local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

type UsedAs<T> = Fusion.Value<T> | Fusion.Computed<T>

return function(props: {
	Wave: UsedAs<number>,
	IsRunning: UsedAs<boolean>,
	Countdown: UsedAs<number>,
	OnNextWave: () -> (),
	Parent: Instance?,
})
	local scope = Scoped({
		New = Fusion.New,
		Computed = Fusion.Computed,
		Spring = Fusion.Spring,
	})

	local waveText = scope:Computed(function(use)
		local wave = use(props.Wave)
		local isRunning = use(props.IsRunning)
		local countdown = use(props.Countdown)

		if countdown > 0 then
			if wave > 0 then
				return "WAVE " .. tostring(wave) .. " STARTS IN " .. tostring(countdown) .. "s"
			else
				return "GAME STARTING IN " .. tostring(countdown) .. "s"
			end
		elseif isRunning then
			return "WAVE " .. tostring(wave)
		else
			return "WAVE " .. tostring(wave) .. " COMPLETE"
		end
	end)

	local buttonVisible = scope:Computed(function(use)
		-- Show button (Skip) if counting down, or show (Start) if wave is not running and no countdown
		return not use(props.IsRunning)
	end)

	local buttonText = scope:Computed(function(use)
		if use(props.Countdown) > 0 then
			return "SKIP COUNTDOWN"
		else
			return "START NEXT WAVE"
		end
	end)

	local component = scope:New("Frame")({
		Name = "WaveDisplay",
		Size = UDim2.fromOffset(300, 100),
		Position = UDim2.new(0.5, 0, 0, 20),
		AnchorPoint = Vector2.new(0.5, 0),
		BackgroundTransparency = 1,
		Parent = props.Parent,

		[Children] = {
			scope:New("UIListLayout")({
				SortOrder = Enum.SortOrder.LayoutOrder,
				FillDirection = Enum.FillDirection.Vertical,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				Padding = UDim.new(0, 8),
			}),

			scope:New("TextLabel")({
				Name = "WaveLabel",
				LayoutOrder = 1,
				Text = waveText,
				Size = UDim2.new(1, 0, 0, 40),
				TextScaled = true,
				BackgroundTransparency = 1,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.FredokaOne,

				[Children] = {
					scope:New("UIStroke")({
						Thickness = 2.5,
						Color = Color3.fromRGB(0, 0, 0),
					}),
				},
			}),

			scope:New("TextButton")({
				Name = "NextWaveButton",
				LayoutOrder = 2,
				Text = buttonText,
				Visible = buttonVisible,
				Size = UDim2.new(0, 200, 0, 40),
				BackgroundColor3 = Color3.fromRGB(46, 204, 113),
				TextColor3 = Color3.fromRGB(255, 255, 255),
				Font = Enum.Font.FredokaOne,
				TextSize = 18,

				[Children] = {
					scope:New("UICorner")({
						CornerRadius = UDim.new(0, 8),
					}),
					scope:New("UIStroke")({
						Thickness = 2,
						Color = Color3.fromRGB(39, 174, 96),
					}),
					scope:New("UIGradient")({
						Color = ColorSequence.new({
							ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 255, 255)),
							ColorSequenceKeypoint.new(1, Color3.fromRGB(200, 200, 200)),
						}),
						Rotation = 90,
					}),
				},

				[OnEvent("Activated")] = function()
					props.OnNextWave()
				end,
			}),
		},
	})

	return component
end
