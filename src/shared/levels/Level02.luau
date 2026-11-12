--!strict
-- Seviye 2 — "Vincin Altinda". Dikey yigin: 4 kus (Swallow + Puffin tanitimi),
-- 3 Tinhead, Stone sutunlar ve kirilmaz Metal kiris.

return {
	id = "level-02",
	name = "Vincin Altinda",
	par = { two = 3600, three = 5600 },
	loadout = { "Wren", "Wren", "Swallow", "Puffin" },
	slingshot = { position = { x = 0, y = 6, z = 0 }, facing = { x = 0, y = 0, z = -1 } },
	pieces = {
		{
			id = "s1",
			material = "Stone",
			size = { x = 3, y = 14, z = 3 },
			position = { x = -8, y = 7, z = -52 },
		},
		{
			id = "s2",
			material = "Stone",
			size = { x = 3, y = 14, z = 3 },
			position = { x = 8, y = 7, z = -52 },
		},
		{
			id = "m1",
			material = "Metal",
			size = { x = 20, y = 1.5, z = 3 },
			position = { x = 0, y = 15, z = -52 },
		},
		{
			id = "w1",
			material = "Wood",
			size = { x = 12, y = 2, z = 8 },
			position = { x = 0, y = 17, z = -52 },
		},
		{
			id = "g1",
			material = "Glass",
			size = { x = 8, y = 6, z = 1 },
			position = { x = 0, y = 4, z = -49 },
		},
		{
			id = "w2",
			material = "Wood",
			size = { x = 4, y = 6, z = 4 },
			position = { x = -14, y = 3, z = -58 },
		},
	},
	targets = {
		{ id = "t1", position = { x = 0, y = 9, z = -52 }, health = 100 },
		{ id = "t2", position = { x = 0, y = 19.5, z = -52 }, health = 100 },
		{ id = "t3", position = { x = -14, y = 7, z = -58 }, health = 100 },
	},
	props = {
		{
			id = "barrel1",
			kind = "ExplosiveBarrel",
			position = { x = 12, y = 2.5, z = -56 },
			radius = 8,
			damage = 60,
			impulse = 90,
		},
	},
}
