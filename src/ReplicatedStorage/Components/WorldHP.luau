local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)

local Scoped = Fusion.scoped
local Children = Fusion.Children

type UsedAs<T> = Fusion.Value<T> | Fusion.Computed<T>

return function(props: {
	Health: UsedAs<number>,
	MaxHealth: UsedAs<number>,
	Adornee: Instance,
	Offset: Vector3?,
	Name: string?,
})
	local scope = Scoped({
		New = Fusion.New,
		Computed = Fusion.Computed,
		Spring = Fusion.Spring,
	})

	local healthPercent = scope:Computed(function(use)
		local current = use(props.Health) or 1
		local max = use(props.MaxHealth) or 1
		return math.clamp(current / max, 0, 1)
	end)

	local barScale = scope:Spring(scope:Computed(function(use)
		return UDim2.fromScale(use(healthPercent), 1)
	end), 25, 0.8)

	return scope:New("BillboardGui")({
		Name = props.Name or "WorldHP",
		Adornee = props.Adornee,
		Size = UDim2.fromOffset(60, 10),
		StudsOffset = props.Offset or Vector3.new(0, 3, 0),
		AlwaysOnTop = true,
		Parent = props.Adornee,

		[Children] = {
			scope:New("Frame")({
				Name = "Background",
				Size = UDim2.fromScale(1, 1),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BorderSizePixel = 0,

				[Children] = {
					scope:New("UICorner")({ CornerRadius = UDim.new(0.5, 0) }),
					scope:New("Frame")({
						Name = "Fill",
						Size = barScale,
						BackgroundColor3 = Color3.fromRGB(255, 50, 50),
						BorderSizePixel = 0,

						[Children] = {
							scope:New("UICorner")({ CornerRadius = UDim.new(0.5, 0) }),
						}
					})
				}
			})
		}
	})
end
