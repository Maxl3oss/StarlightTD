local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)
local TowerConfig = require(RS.Configs.TowerConfig)

local Children = Fusion.Children

return function(scope, props: {
	TowerName: string,
})
	local config = TowerConfig[props.TowerName]
	if not config then return nil end
	
	local lv1 = config.Levels[1]

	return scope:New "Frame" {
		Name = "TowerDraftInfo",
		Size = UDim2.fromOffset(260, 180),
		Position = UDim2.new(0, 20, 0.5, 0),
		AnchorPoint = Vector2.new(0, 0.5),
		BackgroundColor3 = Color3.fromRGB(15, 15, 15),
		BackgroundTransparency = 0.2,
		
		[Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0, 15) },
			scope:New "UIStroke" {
				Thickness = 2,
				Color = Color3.fromRGB(241, 196, 15), -- Gold for Draft
				Transparency = 0.5,
			},
			
			-- Header
			scope:New "TextLabel" {
				Name = "Title",
				Size = UDim2.new(1, 0, 0, 45),
				BackgroundTransparency = 1,
				Text = props.TowerName .. " (Lv 1)",
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 22,
				Font = Enum.Font.GothamBold,
			},

			-- Stats List
			scope:New "Frame" {
				Name = "Stats",
				Size = UDim2.new(1, -30, 0, 100),
				Position = UDim2.fromOffset(20, 50),
				BackgroundTransparency = 1,
				[Children] = {
					scope:New "UIListLayout" { Padding = UDim.new(0, 8) },
					
					scope:New "TextLabel" {
						Size = UDim2.new(1, 0, 0, 25),
						BackgroundTransparency = 1,
						Text = "⚔️ Damage: " .. lv1.Damage,
						TextColor3 = Color3.fromRGB(220, 220, 220),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextSize = 15,
						Font = Enum.Font.Gotham,
					},
					
					scope:New "TextLabel" {
						Size = UDim2.new(1, 0, 0, 25),
						BackgroundTransparency = 1,
						Text = "🔭 Range: " .. lv1.Range,
						TextColor3 = Color3.fromRGB(220, 220, 220),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextSize = 15,
						Font = Enum.Font.Gotham,
					},
					
					scope:New "TextLabel" {
						Size = UDim2.new(1, 0, 0, 25),
						BackgroundTransparency = 1,
						Text = "⏱️ Speed: " .. lv1.FireRate .. "s",
						TextColor3 = Color3.fromRGB(220, 220, 220),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextSize = 15,
						Font = Enum.Font.Gotham,
					},
				}
			},
			
			-- Cost Hint
			scope:New "TextLabel" {
				Size = UDim2.new(1, -20, 0, 30),
				Position = UDim2.new(0, 10, 1, -10),
				AnchorPoint = Vector2.new(0, 1),
				BackgroundTransparency = 1,
				Text = "Cost: " .. config.Cost .. " Coins",
				TextColor3 = Color3.fromRGB(46, 204, 113),
				TextSize = 14,
				Font = Enum.Font.GothamBold,
			}
		}
	}
end
