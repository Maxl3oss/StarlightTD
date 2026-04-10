local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)

local Scoped = Fusion.scoped
local Children = Fusion.Children

type UsedAs<T> = Fusion.Value<T> | Fusion.Computed<T>

local function formatNumber(n: number)
	local formatted = tostring(math.floor(tonumber(n) or 0))
	local k
	while true do  
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then
			break
		end
	end
	return formatted
end

return function(props: {
	Coins: UsedAs<number>,
	Parent: Instance?,
})
	local scope = Scoped({
		New = Fusion.New,
		Computed = Fusion.Computed,
	})

	local coinText = scope:Computed(function(use)
		return "🟡 " .. formatNumber(use(props.Coins))
	end)

	local component = scope:New("TextLabel")({
		Name = "CoinsDisplay",
		Size = UDim2.fromOffset(250, 50),
		Position = UDim2.new(0, 20, 1, -20),
		AnchorPoint = Vector2.new(0, 1),
		BackgroundTransparency = 1,
		Text = coinText,
		TextColor3 = Color3.fromRGB(241, 196, 15), -- Gold
		Font = Enum.Font.FredokaOne,
		TextSize = 32,
		TextXAlignment = Enum.TextXAlignment.Left,
		TextScaled = true,
		Parent = props.Parent,

		[Children] = {
			scope:New("UIStroke")({ Thickness = 2.5, Color = Color3.fromRGB(0, 0, 0) }),
		}
	})

	return component
end
