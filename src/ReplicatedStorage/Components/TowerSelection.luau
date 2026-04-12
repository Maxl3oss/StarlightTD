local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)
local TowerButton = require(script.Parent.TowerButton)
local TowerConfig = require(RS.Configs.TowerConfig)

local Children = Fusion.Children

type UsedAs<T> = T | Fusion.Value<T> | Fusion.Computed<T>
type TowerName = "Potato" | "Archer" | "Mage"

return function(props: {
	OwnedTowers: UsedAs<{ TowerName }>,
	OnSelect: (towerName: TowerName) -> (),
	Parent: Instance?,
})
	local scope = Fusion.scoped({
		New = Fusion.New,
		ForPairs = Fusion.ForPairs,
		Computed = Fusion.Computed,
	})

	local safeList = scope:Computed(function(use)
		local list = use(props.OwnedTowers)
		if typeof(list) ~= "table" then
			return {}
		end
		return list
	end)

	return scope:New("Frame")({
		Name = "TowerSelection",
		Size = UDim2.fromOffset(600, 150),
		Position = UDim2.new(0.5, 0, 1, -20),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Color3.new(0, 0, 0),
		BackgroundTransparency = 0.5,

		[Children] = {
			scope:New("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Center,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 15),
			}),

			scope:ForPairs(safeList, function(_, _, index, towerName: TowerName)
				local config = TowerConfig[towerName]
				if not config then
					warn("[TowerSelection] No config for:", towerName)
					return index, nil
				end

				return index,
					TowerButton({
						Name = towerName,
						Cost = config.Cost,
						OnClick = function()
							props.OnSelect(towerName)
						end,
					})
			end),
		},

		Parent = props.Parent,
	})
end
