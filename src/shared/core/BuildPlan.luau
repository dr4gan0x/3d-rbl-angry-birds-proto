--!strict
-- BuildPlan: "hangi parca, hangi boyut/renk/konumda" kararini verir.
-- Saf Luau: Instance yaratmaz (Instance yasak). BuildService bu plani
-- Roblox parcalarina cevirir. Boylece yerlestirme karari test edilebilir.

export type ColorRGB = { number }
export type PlanEntry = {
	pieceId: string,
	size: { x: number, y: number, z: number },
	position: { x: number, y: number, z: number },
	rotation: { x: number, y: number, z: number },
	material: string,
	health: number,
	mass: number,
	color: ColorRGB,
	anchored: boolean,
}

export type MaterialDefinition = { health: number, density: number, multiplier: number }
export type MaterialTable = { [string]: MaterialDefinition }

-- Malzemeye ozgu renkler. Bunlar oyunun gorsel dilidir: sicak ahşap, soguk metal.
local COLORS: { [string]: ColorRGB } = {
	Wood = { 0.55, 0.32, 0.16 },
	Glass = { 0.72, 0.86, 0.90 },
	Stone = { 0.53, 0.53, 0.53 },
	Metal = { 0.42, 0.45, 0.49 },
}

local BuildPlan = {}

function BuildPlan.colorFor(materialName: string): ColorRGB
	local color = COLORS[materialName]
	if color == nil then
		error("bilinmeyen malzeme: " .. tostring(materialName), 2)
	end
	return color
end

-- Kütle tahmini: hacim * yogunluk (Roblox'un stud/m^3 birimine yakinsar).
-- Hasar hesabi bu kütleye ihtiyac duyar; fizik motoru gercek kutleyi ayri verir.
local function estimateMass(
	material: MaterialDefinition,
	size: { x: number, y: number, z: number }
): number
	local volume = size.x * size.y * size.z
	return math.max(0.1, volume * material.density / 40)
end

function BuildPlan.fromLevel(level: any, materials: MaterialTable): { PlanEntry }
	local plan: { PlanEntry } = {}
	for _, piece in ipairs(level.pieces) do
		local material = materials[piece.material]
		if material == nil then
			error("bilinmeyen malzeme: " .. tostring(piece.material), 2)
		end
		table.insert(plan, {
			pieceId = piece.id,
			size = piece.size,
			position = piece.position,
			rotation = piece.rotation or { x = 0, y = 0, z = 0 },
			material = piece.material,
			health = material.health,
			mass = estimateMass(material, piece.size),
			color = BuildPlan.colorFor(piece.material),
			anchored = true,
		})
	end
	return plan
end

return BuildPlan
