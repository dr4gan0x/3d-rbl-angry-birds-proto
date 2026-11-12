--!strict
-- GameConfig: tum ayar sabitleri tek yerde (sihirli sayi yasak).
-- Core moduller bu tabloyu parametre olarak alir (dependency injection):
-- `script` bu katmanda yasak oldugu icin require kullanilamaz.

export type GameConfigType = {
	GRAVITY: number,
	MAX_SPEED: number,
	MAX_PULL: number,
	DEAD_ZONE: number,
	MIN_POWER: number,
	MAX_RANGE: number,
	BIRD_TYPES: { string },
	FIRE_COOLDOWN: number,
	SETTLE_SPEED: number,
	SETTLE_TIMEOUT: number,
}

local GameConfig: GameConfigType = {
	-- Roblox varsayilan yer cekimi (stud/s^2).
	GRAVITY = 196.2,
	-- Tam gucdeki firlatma hizi (stud/s).
	MAX_SPEED = 260,
	-- Sapanin cekilebilecegi en uzak mesafe (stud).
	MAX_PULL = 8,
	-- Bu mesafenin altindaki cekme parmak titremesidir, atis sayilmaz.
	DEAD_ZONE = 0.75,
	-- Bu gucun altindaki atis kusu sapanin dibine dusurur, iptal edilir.
	MIN_POWER = 0.12,
	-- Sapan menzili: hedefler bu yaricap icinde olmali (stud).
	MAX_RANGE = 420,
	BIRD_TYPES = { "Wren", "Swallow", "Puffin" },
	-- Ayni oyuncunun iki atisi arasindaki en kisa sure (sn) — sunucu tarafi.
	FIRE_COOLDOWN = 0.35,
	-- Enkaz bu hizin altina dusunce "durdu" sayilir (stud/s).
	SETTLE_SPEED = 1.5,
	-- Enkaz bu sure icinde durmazsa zorla cozulur (sn).
	SETTLE_TIMEOUT = 4,
}

return GameConfig
