local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)

local Children = Fusion.Children

type UsedAs<T> = T | Fusion.Value<T> | Fusion.Computed<T>

return function(props: {
	Name: UsedAs<string>,
	Cost: UsedAs<number>,
	OnClick: () -> (),
	Parent: Instance?,
})
	local scope = Fusion.scoped({
		New = Fusion.New,
		OnEvent = Fusion.OnEvent,
		Computed = Fusion.Computed,
		Out = Fusion.Out,
		Value = Fusion.Value,
	})

	local buttonName = scope:Computed(function(use)
		return tostring(use(props.Name)) .. "Button"
	end)

	local displayText = scope:Computed(function(use)
		return tostring(use(props.Name)) .. "\n$" .. tostring(use(props.Cost))
	end)

	local towerNameValue = Fusion.peek(props.Name)
	local isModelReady = scope:Value(false)

	local centerText = scope:Computed(function(use)
		if use(isModelReady) then
			return ""
		end
		return tostring(use(props.Name))
	end)

	local camInstance = scope:New("Camera")({
		FieldOfView = 35,
	})

	local component = scope:New("TextButton")({
		Name = buttonName,
		Size = UDim2.fromOffset(110, 110),
		BackgroundColor3 = Color3.fromRGB(30, 39, 46),
		Text = centerText,
		TextColor3 = Color3.new(0.6, 0.6, 0.6),
		Font = Enum.Font.FredokaOne,
		TextSize = 20,

		[Fusion.OnEvent("Activated")] = props.OnClick,

		[Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(0, 15) }),
			scope:New("UIStroke")({ Thickness = 3, Color = Color3.fromRGB(241, 196, 15) }),

			scope:New("ViewportFrame")({
				Name = "ModelPreview",
				Size = UDim2.new(1, 0, 0.7, 0),
				Position = UDim2.fromScale(0, 0),
				BackgroundTransparency = 1,
				CurrentCamera = camInstance,
				LightColor = Color3.new(1, 1, 1),
				LightDirection = Vector3.new(-1, -1, -1),
				Ambient = Color3.fromRGB(150, 150, 150),

				[Children] = {
					camInstance,
				},
			}),

			scope:New("Frame")({
				Name = "TextContainer",
				Size = UDim2.new(1, 0, 0.3, 0),
				Position = UDim2.fromScale(0, 1),
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.4,

				[Children] = {
					scope:New("UICorner")({ CornerRadius = UDim.new(0, 15) }),
					scope:New("TextLabel")({
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = displayText,
						TextColor3 = Color3.new(1, 1, 1),
						Font = Enum.Font.FredokaOne,
						TextSize = 14,
						TextStrokeTransparency = 0.5,
					}),
				},
			}),
		},

		Parent = props.Parent,
	})

	task.spawn(function()
		local viewport = component:FindFirstChild("ModelPreview", true)
		if not viewport then
			return
		end

		local assets = RS:WaitForChild("Assets", 10)
		local towers = assets and assets:WaitForChild("Towers", 10)
		local modelTemplate = towers and towers:WaitForChild(towerNameValue, 10)

		if not modelTemplate then
			warn(`[TowerButton] Model {towerNameValue} not found in Assets/Towers after 10s timeout`)
			return
		end

		local clone = modelTemplate:Clone()
		if clone:IsA("Model") then
			isModelReady:set(true)

			for _, v in ipairs(clone:GetDescendants()) do
				if v:IsA("LuaSourceContainer") or v:IsA("Sound") then
					v:Destroy()
				end
			end

			clone:PivotTo(CFrame.new(0, 0, 0))
			clone.Parent = viewport

			local cam = viewport.CurrentCamera
			if cam then
				local cf, size = clone:GetBoundingBox()
				local radius = size.Magnitude / 2
				local offset = radius / math.tan(math.rad(cam.FieldOfView / 2))

				cam.CFrame = CFrame.new(Vector3.new(offset, offset * 0.5, offset), cf.Position)
			end
		end
	end)

	return component
end
