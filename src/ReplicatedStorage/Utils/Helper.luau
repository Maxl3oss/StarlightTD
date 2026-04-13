local Helper = {}

-- คำนวณระยะทางแบบ 2D (ระนาบ XZ) สำหรับหอคอย
function Helper.getDistance2D(p1: Vector3, p2: Vector3): number
	return (Vector2.new(p1.X, p1.Z) - Vector2.new(p2.X, p2.Z)).Magnitude
end

-- จัดรูปแบบตัวเลขให้มี Commas (เช่น 1000 -> 1,000)
function Helper.formatNumber(n: number): string
	local formatted = tostring(math.floor(tonumber(n) or 0))
	local k
	while true do  
		formatted, k = string.gsub(formatted, "^(-?%d+)(%d%d%d)", '%1,%2')
		if k == 0 then
			break
		end
	end
	return formatted
end

-- ตั้งค่า Collision Group ให้กับ Instance และทายาททั้งหมด
function Helper.setCollisionGroup(instance: Instance, groupName: string)
	if instance:IsA("BasePart") then
		instance.CollisionGroup = groupName
	end
	for _, child in ipairs(instance:GetDescendants()) do
		if child:IsA("BasePart") then
			child.CollisionGroup = groupName
		end
	end
end

-- สุ่มตำแหน่งภายในรัศมี (สำหรับเอฟเฟกต์)
function Helper.randomOffset(position: Vector3, radius: number): Vector3
	local offset = Vector3.new(
		math.random(-radius, radius),
		0,
		math.random(-radius, radius)
	)
	return position + offset
end

return Helper
