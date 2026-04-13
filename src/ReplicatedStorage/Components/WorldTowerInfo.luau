local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)

local Children = Fusion.Children

return function(scope, props: {
	Tower: Instance,
})
	-- Reactive Level (Observe attribute)
	local level = scope:Value(props.Tower:GetAttribute("Level") or 1)
	
	-- Sync level
	task.spawn(function()
		local connection
		connection = props.Tower:GetAttributeChangedSignal("Level"):Connect(function()
			level:set(props.Tower:GetAttribute("Level") or 1)
		end)
		
		table.insert(scope, function()
			connection:Disconnect()
		end)
	end)

	local displayText = scope:Computed(function(use)
		return props.Tower.Name .. " [Lv " .. use(level) .. "]"
	end)

	return scope:New "BillboardGui" {
		Name = "WorldTowerInfo",
		Adornee = props.Tower,
		Size = UDim2.fromOffset(150, 40),
		StudsOffset = Vector3.new(0, 5, 0), -- ลอยอยู่เหนือหอคอย 5 units
		AlwaysOnTop = true,
		MaxDistance = 60, -- หายไปเมื่ออยู่ไกลเกิน 60 studs
		Parent = props.Tower,
		
		[Children] = {
			scope:New "TextLabel" {
				Size = UDim2.fromScale(1, 1),
				BackgroundTransparency = 1,
				Text = displayText,
				TextColor3 = Color3.fromRGB(255, 255, 255),
				TextStrokeTransparency = 0,
				TextStrokeColor3 = Color3.fromRGB(0, 0, 0),
				Font = Enum.Font.FredokaOne,
				TextSize = 14,
				TextYAlignment = Enum.TextYAlignment.Bottom,
			}
		}
	}
end
