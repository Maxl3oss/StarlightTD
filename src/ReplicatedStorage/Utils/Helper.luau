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

-- คำนวณเส้นผ่านศูนย์กลาง (สำหรับ Size ของ Part/Circle)
function Helper.getDiameter(radius: number): number
	return radius * 2
end

-- คำนวณเงินคืนจากการขาย (70% ของเงินที่ลงทุนไป)
function Helper.calculateRefund(totalInvested: number): number
	return math.floor(totalInvested * 0.7)
end

-- หาตำแหน่งกึ่งกลางของหอคอย (สำหรับ From/To ของ VFX)
function Helper.getTowerCenter(towerInstance: Model): Vector3
	return towerInstance:GetPivot().Position + Vector3.new(0, 3, 0)
end

-- หาตำแหน่งฐานของหอคอย (สำหรับ Pulse/Shockwave)
function Helper.getTowerBase(towerInstance: Model): Vector3
	return towerInstance:GetPivot().Position + Vector3.new(0, 1.0, 0) -- ยกสูงขึ้นอีกนิดเป็น 1.0 กันจม
end

return Helper
