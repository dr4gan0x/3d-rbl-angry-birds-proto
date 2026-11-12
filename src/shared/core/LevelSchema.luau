--!strict
-- LevelSchema: seviye verisini dogrular.
--
-- `validate` ASLA firlatmaz; hata kodlari listesi dondurur. Bozuk seviye verisi
-- oyunu cokertmez, yuklenmez. BuildMath'i require edemez (core'da require yok),
-- AABB mantigi burada tekrar eder — iki dosya arasinda fark olusmamasi icin
-- BuildMath.spec.luau'daki ayni kurallar burada da gecerlidir.

export type LevelConfig = { BIRD_TYPES: { string }, MAX_RANGE: number }
export type MaterialTable = { [string]: { health: number, density: number, multiplier: number } }

local LevelSchema = {}

local function aabb(piece: any): { min: any, max: any }
	local size = piece.size
	local rotation = piece.rotation
	local hx, hy, hz = size.x / 2, size.y / 2, size.z / 2
	if rotation ~= nil then
		local yaw = math.rad(rotation.y or 0)
		local c, s = math.abs(math.cos(yaw)), math.abs(math.sin(yaw))
		hx = (size.x * c + size.z * s) / 2
		hz = (size.x * s + size.z * c) / 2
	end
	local p = piece.position
	return {
		min = { x = p.x - hx, y = p.y - hy, z = p.z - hz },
		max = { x = p.x + hx, y = p.y + hy, z = p.z + hz },
	}
end

local function overlaps(a: any, b: any): boolean
	return a.min.x < b.max.x
		and b.min.x < a.max.x
		and a.min.y < b.max.y
		and b.min.y < a.max.y
		and a.min.z < b.max.z
		and b.min.z < a.max.z
end

local function contains(list: { string }, value: string): boolean
	for _, item in ipairs(list) do
		if item == value then
			return true
		end
	end
	return false
end

function LevelSchema.validate(
	def: any,
	config: LevelConfig,
	materials: MaterialTable
): (boolean, { string })
	local errors: { string } = {}

	if def == nil or type(def) ~= "table" then
		return false, { "missing_field:id" }
	end

	if def.id == nil then
		table.insert(errors, "missing_field:id")
	end

	if
		def.par == nil
		or type(def.par) ~= "table"
		or type(def.par.two) ~= "number"
		or type(def.par.three) ~= "number"
	then
		table.insert(errors, "bad_par")
	end

	if def.loadout == nil or #def.loadout == 0 then
		table.insert(errors, "empty_loadout")
	else
		for _, bird in ipairs(def.loadout) do
			if not contains(config.BIRD_TYPES, bird) then
				table.insert(errors, "unknown_bird:" .. tostring(bird))
			end
		end
	end

	local seen: { [string]: boolean } = {}
	local pieces = def.pieces or {}
	for _, piece in ipairs(pieces) do
		if seen[piece.id] then
			table.insert(errors, "duplicate_piece_id:" .. tostring(piece.id))
		end
		seen[piece.id] = true

		if materials[piece.material] == nil then
			table.insert(errors, "unknown_material:" .. tostring(piece.material))
		end

		if
			piece.size == nil
			or type(piece.size.x) ~= "number"
			or type(piece.size.y) ~= "number"
			or type(piece.size.z) ~= "number"
			or piece.size.x <= 0
			or piece.size.y <= 0
			or piece.size.z <= 0
		then
			table.insert(errors, "bad_size:" .. tostring(piece.id))
		end
	end

	local targets = def.targets or {}
	if #targets == 0 then
		table.insert(errors, "empty_targets")
	end

	local origin = (def.slingshot and def.slingshot.position) or { x = 0, y = 0, z = 0 }
	for _, target in ipairs(targets) do
		local dx = target.position.x - origin.x
		local dy = target.position.y - origin.y
		local dz = target.position.z - origin.z
		if math.sqrt(dx * dx + dy * dy + dz * dz) > config.MAX_RANGE then
			table.insert(errors, "target_out_of_range:" .. tostring(target.id))
		end
	end

	for i = 1, #pieces do
		if pieces[i].size ~= nil then
			local boxA = aabb(pieces[i])
			for j = i + 1, #pieces do
				if pieces[j].size ~= nil and overlaps(boxA, aabb(pieces[j])) then
					table.insert(
						errors,
						"overlapping_pieces:"
							.. tostring(pieces[i].id)
							.. ":"
							.. tostring(pieces[j].id)
					)
				end
			end
		end
	end

	return #errors == 0, errors
end

return LevelSchema
