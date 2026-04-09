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
	
	for i = 1 , #sorted do
		local component = sorted[i]
		components[component.Name] = require(component.Object)
	end
	
	return components
end

return ComponentLoader