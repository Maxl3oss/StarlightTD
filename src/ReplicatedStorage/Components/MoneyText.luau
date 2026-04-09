local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)

local Scoped = Fusion.scoped
local Children = Fusion.Children

type UsedAs<T> = Fusion.UsedAs

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
	Money: UsedAs<number>,
	Parent: Instance?,
})
	local scope = Scoped({
		New = Fusion.New,
		Computed = Fusion.Computed,
	})

	local moneyText = scope:Computed(function(use)
		local currentMoney = use(props.Money) or 0
		return "💰 $" .. formatNumber(currentMoney)
	end)

	local component = scope:New("TextLabel")({
		Text = moneyText,
		TextScaled = true,
		BackgroundTransparency = 1,
		TextColor3 = Color3.fromRGB(241, 196, 15), -- Gold color
		TextXAlignment = Enum.TextXAlignment.Left,
		Parent = props.Parent,
		Font = Enum.Font.FredokaOne,

		Size = UDim2.fromOffset(250, 50),
		Position = UDim2.new(0, 20, 1, -20),
		AnchorPoint = Vector2.new(0, 1),

		[Children] = {
			scope:New("UIStroke")({
				Color = Color3.fromRGB(0, 0, 0),
				Thickness = 2.5,
			}),
		},
	})

	return component
end
