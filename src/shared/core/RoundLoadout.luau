--!strict
-- RoundLoadout: turdaki kus sirasini tutar.
--
-- NEDEN VAR: `LevelDefinition.loadout` PAYLASILAN bir tablodur (levels/init
-- ayrica kaydediyor). Onu dogrudan `table.remove` ile tuketmek seviyeyi
-- kalici olarak bozar: ikinci oyunda eksik kus kalir. Bu modul kaynagi
-- KOPYALAR, tuketme yalnizca kopyada olur.

local RoundLoadout = {}
RoundLoadout.__index = RoundLoadout

export type Loadout = {
	source: { string },
	index: number,
	peek: (any) -> string?,
	take: (any) -> string?,
	remaining: (any) -> number,
	reset: (any) -> (),
}

function RoundLoadout.new(types: { string }): Loadout
	local source: { string } = {}
	for _, birdType in ipairs(types) do
		table.insert(source, birdType)
	end
	return setmetatable({ source = source, index = 1 }, RoundLoadout) :: any
end

-- Siradaki kus, tuketmeden. Bittiyse nil.
function RoundLoadout.peek(self: any): string?
	return self.source[self.index]
end

-- Siradaki kusu tuketir ve dondurur. Bittiyse nil.
function RoundLoadout.take(self: any): string?
	local birdType = self.source[self.index]
	if birdType ~= nil then
		self.index += 1
	end
	return birdType
end

function RoundLoadout.remaining(self: any): number
	return math.max(0, #self.source - self.index + 1)
end

function RoundLoadout.reset(self: any): ()
	self.index = 1
end

return RoundLoadout
