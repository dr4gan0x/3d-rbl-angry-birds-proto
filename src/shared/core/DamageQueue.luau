--!strict
-- DamageQueue: ayni karede gelen vuruslari parca basina toplar.
--
-- Sunucu, Touched olaylarindan gelen hasari burada biriktirir ve Heartbeat'te
-- tek seferde uygular: ayni parca bir karede 10 kez vurulursa 10 ayri
-- guncelleme degil 1 guncelleme olur.

export type Entry = { pieceId: string, damage: number }

local DamageQueue = {}
DamageQueue.__index = DamageQueue

function DamageQueue.new(): any
	return setmetatable({ order = {}, totals = {} }, DamageQueue)
end

function DamageQueue.push(self: any, pieceId: string, damage: number): ()
	if self.totals[pieceId] == nil then
		self.totals[pieceId] = damage
		table.insert(self.order, pieceId)
	else
		self.totals[pieceId] += damage
	end
end

function DamageQueue.size(self: any): number
	return #self.order
end

-- Kuyrugu bosaltir ve ekleme sirasini koruyan bir liste dondurur.
function DamageQueue.drain(self: any): { Entry }
	local entries: { Entry } = {}
	for _, pieceId in ipairs(self.order) do
		table.insert(entries, { pieceId = pieceId, damage = self.totals[pieceId] })
	end
	self.order = {}
	self.totals = {}
	return entries
end

return DamageQueue
