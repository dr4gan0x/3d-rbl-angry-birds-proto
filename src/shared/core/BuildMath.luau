--!strict
-- BuildMath: eksen hizali kutu (AABB) matematigi.
--
-- Sadece y ekseni etrafindaki donus (yaw) desteklenir: seviye parcalari
-- Roblox'ta yaw ile yerlestirilir, egimli parca kullanilmaz.

export type Vec3 = { x: number, y: number, z: number }
export type Aabb = { min: Vec3, max: Vec3 }
export type Piece = { position: Vec3, size: Vec3, rotation: Vec3? }

local BuildMath = {}

local function halfExtents(piece: Piece): Vec3
	local size = piece.size
	local rotation = piece.rotation
	if rotation == nil then
		return { x = size.x / 2, y = size.y / 2, z = size.z / 2 }
	end
	-- Yaw donusunde kutunun izdusumu |cos|, |sin| ile genisler.
	local yaw = math.rad(rotation.y or 0)
	local c, s = math.abs(math.cos(yaw)), math.abs(math.sin(yaw))
	return {
		x = (size.x * c + size.z * s) / 2,
		y = size.y / 2,
		z = (size.x * s + size.z * c) / 2,
	}
end

function BuildMath.aabb(piece: Piece): Aabb
	local half = halfExtents(piece)
	local p = piece.position
	return {
		min = { x = p.x - half.x, y = p.y - half.y, z = p.z - half.z },
		max = { x = p.x + half.x, y = p.y + half.y, z = p.z + half.z },
	}
end

-- Kati esitsizlik: tam kenar temasi cakisma sayilmaz (yapisal olarak bitisik
-- parcalar seviye dogrulamasinda hata vermesin).
function BuildMath.overlaps(a: Aabb, b: Aabb): boolean
	return a.min.x < b.max.x
		and b.min.x < a.max.x
		and a.min.y < b.max.y
		and b.min.y < a.max.y
		and a.min.z < b.max.z
		and b.min.z < a.max.z
end

return BuildMath
