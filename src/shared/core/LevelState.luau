--!strict
-- LevelState: tur (round) durum makinesi. Saf Luau, Roblox API'si yok.
--
--   aiming  --fire()-->  flying  --notifyLanded()-->  settling
--      ^                                                |
--      |                      (hareket durdu / 4 sn)    |
--      +----------------------------------------------- +
--                        (hedef kaldi, kus kaldi)
--
--   herhangi bir faz --targetsLeft == 0--> won
--   settling --kus bitti + hedef kaldi--> lost
--
-- Kural: son hedef olunce faz DERHAL "won" olur; kus bitmesi bunu ezemez.

export type Target = { id: string, position: { x: number, y: number, z: number }, health: number }
export type LevelDefinition = {
	id: string,
	name: string,
	par: { two: number, three: number },
	loadout: { string },
	slingshot: { position: any, facing: any },
	pieces: { any },
	targets: { Target },
	props: { any },
}

local LevelState = {}
LevelState.__index = LevelState

-- Bu hizin altindaki enkaz "durdu" sayilir (stud/s).
local SETTLE_SPEED = 1.5
-- Bu sure icinde durmazsa zorla cozulur (sn).
local SETTLE_TIMEOUT = 4

function LevelState.new(level: LevelDefinition): any
	local self = setmetatable({}, LevelState)
	self.level = level
	self.phase = "aiming"
	self.birdsLeft = #level.loadout
	self.targetsLeft = #level.targets
	self.elapsed = 0
	return self
end

function LevelState.fire(self: any): boolean
	if self.phase ~= "aiming" or self.birdsLeft <= 0 then
		return false
	end
	self.birdsLeft -= 1
	self.phase = "flying"
	return true
end

function LevelState.notifyLanded(self: any): ()
	if self.phase == "flying" then
		self.phase = "settling"
		self.elapsed = 0
	end
end

function LevelState.destroyTarget(self: any, _targetId: string): ()
	if self.phase == "won" or self.phase == "lost" then
		return
	end
	self.targetsLeft = math.max(0, self.targetsLeft - 1)
	if self.targetsLeft == 0 then
		self.phase = "won"
	end
end

-- Enkaz durunca veya zaman asiminda cagrilir. Yeni fazi dondurur.
function LevelState.settleTick(self: any, dt: number, fastestSpeed: number): string
	if self.phase ~= "settling" then
		return self.phase
	end

	self.elapsed += dt

	if self.targetsLeft == 0 then
		self.phase = "won"
		return self.phase
	end

	if fastestSpeed < SETTLE_SPEED or self.elapsed >= SETTLE_TIMEOUT then
		if self.birdsLeft <= 0 then
			self.phase = "lost"
		else
			self.phase = "aiming"
			self.elapsed = 0
		end
	end

	return self.phase
end

function LevelState.result(self: any): { won: boolean, targetsLeft: number, birdsLeft: number }?
	if self.phase ~= "won" and self.phase ~= "lost" then
		return nil
	end
	return {
		won = self.phase == "won",
		targetsLeft = self.targetsLeft,
		birdsLeft = self.birdsLeft,
	}
end

return LevelState
