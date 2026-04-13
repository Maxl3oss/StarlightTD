local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)
local TowerConfig = require(RS.Configs.TowerConfig)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

return function(scope, props: {
	Tower: Instance,
	OnUpgrade: () -> (),
	OnClose: () -> (),
})
	local config = TowerConfig[props.Tower.Name]
	if not config then return nil end
	
	-- Reactive Level State (Observe Attribute)
	local level = scope:Value(props.Tower:GetAttribute("Level") or 1)
	
	-- Sync level when attribute changes
	task.spawn(function()
		local connection
		connection = props.Tower:GetAttributeChangedSignal("Level"):Connect(function()
			if props.Tower:GetAttribute("Level") then
				level:set(props.Tower:GetAttribute("Level"))
			end
		end)
		
		-- Cleanup connection when scope is destroyed
		table.insert(scope, function()
			connection:Disconnect()
		end)
	end)

	local currentLevelCfg = scope:Computed(function(use)
		local lv = use(level)
		return config.Levels[lv]
	end)

	local nextLevelCfg = scope:Computed(function(use)
		local lv = use(level)
		return config.Levels[lv + 1]
	end)

	local isMaxLevel = scope:Computed(function(use)
		return use(level) >= 5
	end)

	return scope:New "Frame" {
		Name = "TowerInfo",
		Size = UDim2.fromOffset(285, 240),
		Position = UDim2.new(1, -20, 0.5, 0),
		AnchorPoint = Vector2.new(1, 0.5),
		BackgroundColor3 = Color3.fromRGB(20, 20, 21),
		BackgroundTransparency = 0.1,
		
		[Children] = {
			scope:New "UICorner" { CornerRadius = UDim.new(0, 15) },
			scope:New "UIStroke" {
				Thickness = 2,
				Color = Color3.fromRGB(120, 120, 255),
				Transparency = 0.4,
			},
			
			-- Header
			scope:New "TextLabel" {
				Name = "Title",
				Size = UDim2.new(1, 0, 0, 50),
				BackgroundTransparency = 1,
				Text = scope:Computed(function(use)
					return props.Tower.Name .. " (Lv " .. use(level) .. ")"
				end),
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 22,
				Font = Enum.Font.GothamBold,
			},
			
			-- Close Button
			scope:New "TextButton" {
				Name = "CloseBtn",
				Size = UDim2.fromOffset(30, 30),
				Position = UDim2.new(1, -10, 0, 10),
				AnchorPoint = Vector2.new(1, 0),
				BackgroundTransparency = 1,
				Text = "✕",
				TextColor3 = Color3.new(0.7, 0.7, 0.7),
				TextSize = 20,
				Font = Enum.Font.GothamBold,
				[OnEvent "Activated"] = props.OnClose,
			},

			-- Stats List
			scope:New "Frame" {
				Name = "Stats",
				Size = UDim2.new(1, -30, 0, 100),
				Position = UDim2.fromOffset(20, 60),
				BackgroundTransparency = 1,
				[Children] = {
					scope:New "UIListLayout" { Padding = UDim.new(0, 8) },
					
					-- Damage
					scope:New "TextLabel" {
						Size = UDim2.new(1, 0, 0, 25),
						BackgroundTransparency = 1,
						Text = scope:Computed(function(use)
							local cur = use(currentLevelCfg).Damage
							local nxt = use(nextLevelCfg)
							return "Damage: " .. cur .. (nxt and " -> " .. nxt.Damage or "")
						end),
						TextColor3 = Color3.fromRGB(220, 220, 220),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextSize = 15,
						Font = Enum.Font.Gotham,
					},
					
					-- Range
					scope:New "TextLabel" {
						Size = UDim2.new(1, 0, 0, 25),
						BackgroundTransparency = 1,
						Text = scope:Computed(function(use)
							local cur = use(currentLevelCfg).Range
							local nxt = use(nextLevelCfg)
							return "Range: " .. cur .. (nxt and " -> " .. nxt.Range or "")
						end),
						TextColor3 = Color3.fromRGB(220, 220, 220),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextSize = 15,
						Font = Enum.Font.Gotham,
					},
					
					-- Fire Rate
					scope:New "TextLabel" {
						Size = UDim2.new(1, 0, 0, 25),
						BackgroundTransparency = 1,
						Text = scope:Computed(function(use)
							local cur = use(currentLevelCfg).FireRate
							local nxt = use(nextLevelCfg)
							return "Speed: " .. cur .. "s" .. (nxt and " -> " .. nxt.FireRate .. "s" or "")
						end),
						TextColor3 = Color3.fromRGB(220, 220, 220),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextSize = 15,
						Font = Enum.Font.Gotham,
					},
				}
			},
			
			-- Upgrade Button
			scope:New "TextButton" {
				Name = "UpgradeBtn",
				Size = UDim2.new(1, -40, 0, 50),
				Position = UDim2.new(0.5, 0, 1, -20),
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundColor3 = scope:Computed(function(use)
					return if use(isMaxLevel) then Color3.fromRGB(60, 60, 60) else Color3.fromRGB(46, 204, 113)
				end),
				Text = scope:Computed(function(use)
					if use(isMaxLevel) then return "MAX LEVEL" end
					return "UPGRADE (" .. use(currentLevelCfg).UpgradeCost .. " Coins)"
				end),
				TextColor3 = Color3.new(1, 1, 1),
				TextSize = 15,
				Font = Enum.Font.GothamBold,
				AutoButtonColor = true,
				[OnEvent "Activated"] = function()
					if not Fusion.peek(isMaxLevel) then
						props.OnUpgrade()
					end
				end,
				[Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0, 10) } }
			}
		}
	}
end
