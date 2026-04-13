local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)
local TowerConfig = require(RS.Configs.TowerConfig)

local Children = Fusion.Children
local OnEvent = Fusion.OnEvent

-- ใช้ scope จากระบบหลักเพื่อให้ Listener ไม่หลุด
return function(scope, props: {
	Tower: Instance,
	OnUpgrade: () -> (),
	OnSell: () -> (),
	OnClose: () -> (),
})
	local config = TowerConfig[props.Tower.Name]
	if not config then return nil end
	
	-- ใช้ Value จาก scope หลักที่ส่งมา
	local level = scope:Value(props.Tower:GetAttribute("Level") or 1)
	
	-- สร้าง Listener แบบ Task-safe
	task.spawn(function()
		local connection
		connection = props.Tower:GetAttributeChangedSignal("Level"):Connect(function()
			local newLv = props.Tower:GetAttribute("Level") or 1
			level:set(newLv)
		end)
		
		-- จัดการตัดการเชื่อมต่อเมื่อต้องการ
		table.insert(scope, function()
			if connection then connection:Disconnect() end
		end)
	end)

	local currentLevelCfg = scope:Computed(function(use)
		local lv = use(level)
		return config.Levels[lv] or config.Levels[1]
	end)

	local nextLevelCfg = scope:Computed(function(use)
		local lv = use(level)
		return config.Levels[lv + 1]
	end)

	local isMaxLevel = scope:Computed(function(use)
		return use(level) >= 5
	end)

	local sellRefund = scope:Computed(function(use)
		local lv = use(level)
		local total = config.Cost
		for i = 1, lv - 1 do
			total += config.Levels[i].UpgradeCost
		end
		return math.floor(total * 0.7)
	end)

	return scope:New "Frame" {
		Name = "TowerInfo",
		Size = UDim2.fromOffset(285, 280), -- เพิ่มความสูงเพื่อปุ่มขาย
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
				[OnEvent "Activated"] = function()
					props.OnClose()
				end,
			},

			scope:New "Frame" {
				Name = "Stats",
				Size = UDim2.new(1, -30, 0, 100),
				Position = UDim2.fromOffset(20, 60),
				BackgroundTransparency = 1,
				[Children] = {
					scope:New "UIListLayout" { Padding = UDim.new(0, 8) },
					
					scope:New "TextLabel" {
						Size = UDim2.new(1, 0, 0, 25),
						BackgroundTransparency = 1,
						Text = scope:Computed(function(use)
							local cfg = use(currentLevelCfg)
							local nxt = use(nextLevelCfg)
							return "Damage: " .. cfg.Damage .. (nxt and " -> " .. nxt.Damage or "")
						end),
						TextColor3 = Color3.fromRGB(220, 220, 220),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextSize = 15,
						Font = Enum.Font.Gotham,
					},
					
					scope:New "TextLabel" {
						Size = UDim2.new(1, 0, 0, 25),
						BackgroundTransparency = 1,
						Text = scope:Computed(function(use)
							local cfg = use(currentLevelCfg)
							local nxt = use(nextLevelCfg)
							return "Range: " .. cfg.Range .. (nxt and " -> " .. nxt.Range or "")
						end),
						TextColor3 = Color3.fromRGB(220, 220, 220),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextSize = 15,
						Font = Enum.Font.Gotham,
					},
					
					scope:New "TextLabel" {
						Size = UDim2.new(1, 0, 0, 25),
						BackgroundTransparency = 1,
						Text = scope:Computed(function(use)
							local cfg = use(currentLevelCfg)
							local nxt = use(nextLevelCfg)
							return "Speed: " .. cfg.FireRate .. "s" .. (nxt and " -> " .. nxt.FireRate .. "s" or "")
						end),
						TextColor3 = Color3.fromRGB(220, 220, 220),
						TextXAlignment = Enum.TextXAlignment.Left,
						TextSize = 15,
						Font = Enum.Font.Gotham,
					},
				}
			},
			
			-- Buttons Container
			scope:New "Frame" {
				Name = "ActionButtons",
				Size = UDim2.new(1, -40, 0, 95),
				Position = UDim2.new(0.5, 0, 1, -15),
				AnchorPoint = Vector2.new(0.5, 1),
				BackgroundTransparency = 1,
				[Children] = {
					scope:New "UIListLayout" { 
						Padding = UDim.new(0, 10),
						VerticalAlignment = Enum.VerticalAlignment.Bottom
					},
					
					scope:New "TextButton" {
						Name = "UpgradeBtn",
						Size = UDim2.new(1, 0, 0, 42),
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
						[OnEvent "Activated"] = function()
							if not Fusion.peek(isMaxLevel) then
								props.OnUpgrade()
							end
						end,
						[Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0, 10) } }
					},

					scope:New "TextButton" {
						Name = "SellBtn",
						Size = UDim2.new(1, 0, 0, 42),
						BackgroundColor3 = Color3.fromRGB(192, 57, 43),
						Text = scope:Computed(function(use)
							return "SELL (+" .. use(sellRefund) .. " Coins)"
						end),
						TextColor3 = Color3.new(1, 1, 1),
						TextSize = 14,
						Font = Enum.Font.GothamBold,
						[OnEvent "Activated"] = props.OnSell,
						[Children] = { scope:New "UICorner" { CornerRadius = UDim.new(0, 10) } }
					}
				}
			}
		}
	}
end
