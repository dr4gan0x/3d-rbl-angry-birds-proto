--!strict
-- DamageModel: carpma hasari ve hasar cozumleme matematigi.
--
-- Roblox API'si yoktur. Malzeme tablosu PARAMETRE olarak gelir.

export type MaterialDefinition = { health: number, density: number, multiplier: number }
export type MaterialTable = { [string]: MaterialDefinition }
export type Piece = { id: string, material: string, health: number }
export type Hit = { pieceId: string, damage: number }
export type Outcome = { pieceId: string, healthAfter: number, destroyed: boolean }

-- Bu hizin altindaki temaslar hasar vermez: yapilar kendi kendine cokmesin.
local MIN_SPEED = 18
local REFERENCE_MAX_SPEED = 220
local REFERENCE_MASS = 2.5
local MIN_MASS_FACTOR = 0.3
local MAX_MASS_FACTOR = 2.0
local DAMAGE_SCALE = 100

local DamageModel = {}

-- Carpma hasari. Bilinmeyen malzeme bir programlama hatasidir: hata firlatir.
function DamageModel.impactDamage(
	relativeSpeed: number,
	mass: number,
	materialName: string,
	materials: MaterialTable
): number
	local definition = materials[materialName]
	if definition == nil then
		error("bilinmeyen malzeme: " .. tostring(materialName), 2)
	end

	local speedFactor =
		math.clamp((relativeSpeed - MIN_SPEED) / (REFERENCE_MAX_SPEED - MIN_SPEED), 0, 1)
	local massFactor = math.clamp(mass / REFERENCE_MASS, MIN_MASS_FACTOR, MAX_MASS_FACTOR)
	return math.round(speedFactor * massFactor * definition.multiplier * DAMAGE_SCALE)
end

-- Yuksekten dusme hasari (Tinhead gibi hedefler icin).
function DamageModel.fallDamage(impactSpeed: number): number
	return math.max(0, (impactSpeed - 40) * 1.2)
end

-- Ayni karedeki vuruslari parca basina toplar, girdi tablolarini DEGISTIRMEZ.
-- Sonuc, girdi parca sirasini korur; her parca en fazla bir kez gorunur.
function DamageModel.resolveHits(pieces: { Piece }, hits: { Hit }): { Outcome }
	local byId: { [string]: Piece } = {}
	local order: { string } = {}
	for _, piece in ipairs(pieces) do
		byId[piece.id] = piece
		table.insert(order, piece.id)
	end

	local totals: { [string]: number } = {}
	for _, hit in ipairs(hits) do
		if byId[hit.pieceId] ~= nil then
			totals[hit.pieceId] = (totals[hit.pieceId] or 0) + hit.damage
		end
	end

	local outcomes: { Outcome } = {}
	for _, pieceId in ipairs(order) do
		local total = totals[pieceId]
		if total ~= nil then
			-- math.huge - 900 == math.huge : Metal icin NaN uretmez.
			local healthAfter = math.max(0, byId[pieceId].health - total)
			table.insert(outcomes, {
				pieceId = pieceId,
				healthAfter = healthAfter,
				destroyed = healthAfter <= 0,
			})
		end
	end
	return outcomes
end

return DamageModel
