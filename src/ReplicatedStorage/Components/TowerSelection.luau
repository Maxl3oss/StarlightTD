local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)
local TowerButton = require(script.Parent.TowerButton)
local TowerConfig = require(RS.Configs.TowerConfig)

local Children = Fusion.Children

type UsedAs<T> = T | Fusion.Value<T> | Fusion.Computed<T>

return function(props: {
	OwnedTowers: UsedAs<{ string }>,
	SelectedTower: UsedAs<string?>?,
	OnSelect: (towerName: string) -> (),
	Parent: Instance?,
})
	local scope = Fusion.scoped({
		New = Fusion.New,
		ForPairs = Fusion.ForPairs,
		Computed = Fusion.Computed,
	})

	local sortedTowers = scope:Computed(function(use)
		local list = use(props.OwnedTowers)
		if typeof(list) ~= "table" then
			return {}
		end

		local towers = table.clone(list)
		table.sort(towers, function(a, b)
			local configA = TowerConfig[a]
			local configB = TowerConfig[b]
			local costA = if configA then configA.Cost else 0
			local costB = if configB then configB.Cost else 0
			
			if costA ~= costB then
				return costA < costB
			end
			return a < b
		end)

		local limited = {}
		for i = 1, 6 do
			if towers[i] then
				table.insert(limited, towers[i])
			end
		end
		return limited
	end)

	local slotData = scope:Computed(function(use)
		local towers = use(sortedTowers)
		local slots = {}
		for i = 1, 6 do
			slots[i] = towers[i] or "Empty"
		end
		return slots
	end)

	return scope:New("Frame")({
		Name = "TowerSelection",
		Size = UDim2.fromOffset(630, 110),
		Position = UDim2.new(0.5, 0, 1, -20),
		AnchorPoint = Vector2.new(0.5, 1),
		BackgroundColor3 = Color3.fromRGB(15, 15, 15),
		BackgroundTransparency = 0.2,

		[Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(0, 15) }),
			scope:New("UIStroke")({
				Thickness = 2,
				Color = Color3.fromRGB(50, 50, 50),
				Transparency = 0.5,
			}),
			scope:New("UIListLayout")({
				FillDirection = Enum.FillDirection.Horizontal,
				HorizontalAlignment = Enum.HorizontalAlignment.Left,
				VerticalAlignment = Enum.VerticalAlignment.Center,
				Padding = UDim.new(0, 15),
				SortOrder = Enum.SortOrder.LayoutOrder,
			}),
			scope:New("UIPadding")({
				PaddingLeft = UDim.new(0, 15),
				PaddingRight = UDim.new(0, 15),
			}),

			scope:ForPairs(slotData, function(_, _, index, towerName)
				local nameValue = Fusion.peek(towerName)
				if nameValue == "Empty" then
					return index, scope:New("Frame")({
						Name = "EmptySlot" .. tostring(index),
						Size = UDim2.fromOffset(85, 85),
						LayoutOrder = index,
						BackgroundColor3 = Color3.fromRGB(0, 0, 0),
						BackgroundTransparency = 0.7,
						[Children] = {
							scope:New("UICorner")({ CornerRadius = UDim.new(0, 10) }),
							scope:New("UIStroke")({
								Thickness = 1,
								Color = Color3.fromRGB(30, 30, 30),
								ApplyStrokeMode = Enum.ApplyStrokeMode.Border,
							}),
						}
					})
				end

				return index, TowerButton({
					Name = towerName,
					Cost = if TowerConfig[nameValue] then TowerConfig[nameValue].Cost else 0,
					LayoutOrder = index,
					IsActive = scope:Computed(function(use)
						return use(props.SelectedTower) == use(towerName)
					end),
					OnClick = function()
						props.OnSelect(Fusion.peek(towerName))
					end,
				})
			end),
		},

		Parent = props.Parent,
	})
end
