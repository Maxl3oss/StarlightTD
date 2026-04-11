local RS = game:GetService("ReplicatedStorage")
local Fusion = require(RS.Packages.Fusion)
local TowerSelection = require(RS.Components.TowerSelection)

local controls = {}

type Props = { target: Instance, controls: typeof(controls) }

local story = {
	fusion = Fusion,
	controls = controls,
	story = function(props: Props)
		-- Setup temporary assets for the story preview
		local assets = RS:FindFirstChild("Assets") or Instance.new("Folder", RS)
		assets.Name = "Assets"
		local towers = assets:FindFirstChild("Towers") or Instance.new("Folder", assets)
		towers.Name = "Towers"
		
		local names = {"Potato", "Archer", "Mage"}
		local createdModels = {}
		
		for _, name in ipairs(names) do
			if not towers:FindFirstChild(name) then
				local m = Instance.new("Model", towers)
				m.Name = name
				local p = Instance.new("Part", m)
				p.Size = Vector3.new(4, 4, 4)
				p.BrickColor = BrickColor.random()
				table.insert(createdModels, m)
			end
		end

		local component = TowerSelection({
			OnSelect = function(towerName)
				print("Selected tower in story: " .. towerName)
			end,
			Parent = props.target,
		})

		return function()
			if component then component:Destroy() end
			for _, m in ipairs(createdModels) do
				m:Destroy()
			end
		end
	end,
}

return story
