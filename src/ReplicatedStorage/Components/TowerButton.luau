local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)

local Children = Fusion.Children

type UsedAs<T> = T | Fusion.Value<T> | Fusion.Computed<T>

return function(props: {
	Name: UsedAs<string>,
	Cost: UsedAs<number>,
	IsActive: UsedAs<boolean>?,
	OnClick: () -> (),
	Parent: Instance?,
})
	local scope = Fusion.scoped({
		New = Fusion.New,
		OnEvent = Fusion.OnEvent,
		Computed = Fusion.Computed,
		Out = Fusion.Out,
		Value = Fusion.Value,
		Observer = Fusion.Observer,
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

	local isActive = scope:Computed(function(use)
		return use(props.IsActive) or false
	end)

	local strokeColor = scope:Computed(function(use)
		return if use(isActive) then Color3.fromRGB(46, 204, 113) else Color3.fromRGB(241, 196, 15)
	end)

	local bgColor = scope:Computed(function(use)
		return if use(isActive) then Color3.fromRGB(44, 58, 71) else Color3.fromRGB(30, 39, 46)
	end)

	local camInstance = scope:New("Camera")({
		FieldOfView = 35,
	})

	local component = scope:New("TextButton")({
		Name = buttonName,
		Size = UDim2.fromOffset(85, 85),
		BackgroundColor3 = bgColor,
		Text = centerText,
		TextColor3 = Color3.new(0.6, 0.6, 0.6),
		Font = Enum.Font.FredokaOne,
		TextSize = 16,

		[Fusion.OnEvent("Activated")] = props.OnClick,

		[Children] = {
			scope:New("UICorner")({ CornerRadius = UDim.new(0, 10) }),
			scope:New("UIStroke")({
				Thickness = 2,
				Color = strokeColor,
				Transparency = scope:Computed(function(use)
					return if use(isActive) then 0 else 0.4
				end),
			}),

			scope:New("ViewportFrame")({
				Name = "ModelPreview",
				Size = UDim2.new(1, 0, 0.65, 0),
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
				Size = UDim2.new(1, 0, 0.35, 0),
				Position = UDim2.fromScale(0, 1),
				AnchorPoint = Vector2.new(0, 1),
				BackgroundColor3 = Color3.fromRGB(0, 0, 0),
				BackgroundTransparency = 0.4,

				[Children] = {
					scope:New("UICorner")({ CornerRadius = UDim.new(0, 10) }),
					scope:New("TextLabel")({
						Size = UDim2.fromScale(1, 1),
						BackgroundTransparency = 1,
						Text = displayText,
						TextColor3 = Color3.new(1, 1, 1),
						Font = Enum.Font.FredokaOne,
						TextSize = 11,
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

		-- React to name changes
		local currentModel: Instance? = nil

		local function updateModel()
			local name = tostring(Fusion.peek(props.Name))
			if name == "" or name == "Empty" then
				if currentModel then
					currentModel:Destroy()
					currentModel = nil
				end
				isModelReady:set(false)
				return
			end

			local modelTemplate = towers and towers:WaitForChild(name, 5)
			if not modelTemplate then
				warn(`[TowerButton] Model {name} not found in Assets/Towers`)
				return
			end

			if currentModel then
				currentModel:Destroy()
			end

			local clone = modelTemplate:Clone()
			if clone:IsA("Model") then
				currentModel = clone
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
		end

		-- Load initial
		updateModel()

		-- Watch for changes
		local observer = scope:Observer(props.Name)
		observer:onChange(updateModel)
	end)

	return component
end
