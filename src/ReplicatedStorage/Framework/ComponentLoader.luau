local ComponentLoader = {}
ComponentLoader.__index = ComponentLoader

function ComponentLoader:sort(folders)
	if not folders then
		return {}
	end

	local lists = {}

	local function sort(folder)
		for _, child in pairs(folder:GetChildren()) do
			if child:IsA("ModuleScript") then
				table.insert(lists, {
					Name = child.Name,
					Object = child,
					Priority = child:GetAttribute("Priority") or 1,
				})
			elseif child:IsA("Folder") then
				sort(child)
			end
		end
	end

	sort(folders)

	table.sort(lists, function(a, b)
		return a.Priority < b.Priority
	end)

	return lists
end

function ComponentLoader:LoadComponents(folder)
	local components = {}
	local sorted = self:sort(folder)

	for i = 1, #sorted do
		local component = sorted[i]

		local ok, result = pcall(require, component.Object)

		if not ok then
			warn("[ComponentLoader] Failed to load:", component.Name)
			warn("Error:", result)
		else
			if result == nil then
				warn("[ComponentLoader] Module returned nil:", component.Name)
			else
				components[component.Name] = result
			end
		end
	end

	return components
end

return ComponentLoader
