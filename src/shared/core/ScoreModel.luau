--!strict
-- ScoreModel: skor ve yildiz hesabi. Saf Luau, bagimlilik yok.

export type Breakdown = {
	Tinhead: number?,
	Wood: number?,
	Glass: number?,
	Stone: number?,
}

export type Par = { two: number, three: number }

local POINTS_TINHEAD = 500
local POINTS_WOOD_OR_GLASS = 40
local POINTS_STONE = 90
local POINTS_BIRD_LEFT = 1000

local ScoreModel = {}

function ScoreModel.compute(breakdown: Breakdown, birdsLeft: number): number
	local tinheads = breakdown.Tinhead or 0
	local wood = breakdown.Wood or 0
	local glass = breakdown.Glass or 0
	local stone = breakdown.Stone or 0
	return POINTS_TINHEAD * tinheads
		+ POINTS_WOOD_OR_GLASS * (wood + glass)
		+ POINTS_STONE * stone
		+ POINTS_BIRD_LEFT * birdsLeft
end

-- Esikler dahildir. Seviye tamamlandigi surece en az 1 yildiz vardir.
function ScoreModel.stars(score: number, par: Par): number
	if score >= par.three then
		return 3
	end
	if score >= par.two then
		return 2
	end
	return 1
end

return ScoreModel
