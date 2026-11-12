--!strict
-- Seviye 3 — "Tinhead Kalesi". 5 kus, 5 Tinhead, Metal iskelet + Stone duvar
-- ve iki patlayici varil. Zincirleme patlama icin tasarlandi.

return {
	id = "level-03",
	name = "Tinhead Kalesi",
	par = { two = 5200, three = 7800 },
	loadout = { "Wren", "Wren", "Swallow", "Puffin", "Wren" },
	slingshot = { position = { x = 0, y = 6, z = 0 }, facing = { x = 0, y = 0, z = -1 } },
	pieces = {
		{
			id = "m1",
			material = "Metal",
			size = { x = 2, y = 20, z = 2 },
			position = { x = -12, y = 10, z = -60 },
		},
		{
			id = "m2",
			material = "Metal",
			size = { x = 2, y = 20, z = 2 },
			position = { x = 12, y = 10, z = -60 },
		},
		{
			id = "st1",
			material = "Stone",
			size = { x = 22, y = 2, z = 6 },
			position = { x = 0, y = 21, z = -60 },
		},
		{
			id = "w1",
			material = "Wood",
			size = { x = 18, y = 8, z = 1 },
			position = { x = 0, y = 5, z = -56 },
		},
		{
			id = "g1",
			material = "Glass",
			size = { x = 6, y = 10, z = 6 },
			position = { x = -6, y = 5, z = -62 },
		},
		{
			id = "g2",
			material = "Glass",
			size = { x = 6, y = 10, z = 6 },
			position = { x = 6, y = 5, z = -62 },
		},
		{
			id = "roof2",
			material = "Wood",
			size = { x = 16, y = 2, z = 6 },
			position = { x = 0, y = 11, z = -62 },
		},
		{
			id = "tower",
			material = "Stone",
			size = { x = 4, y = 6, z = 4 },
			position = { x = 20, y = 3, z = -70 },
		},
	},
	targets = {
		{ id = "t1", position = { x = -6, y = 3, z = -62 }, health = 100 },
		{ id = "t2", position = { x = 6, y = 3, z = -62 }, health = 100 },
		{ id = "t3", position = { x = 0, y = 13, z = -62 }, health = 100 },
		{ id = "t4", position = { x = 20, y = 7, z = -70 }, health = 100 },
		{ id = "t5", position = { x = -16, y = 3, z = -66 }, health = 100 },
	},
	props = {
		{
			id = "barrel1",
			kind = "ExplosiveBarrel",
			position = { x = -10, y = 2.5, z = -58 },
			radius = 9,
			damage = 70,
			impulse = 100,
		},
		{
			id = "barrel2",
			kind = "ExplosiveBarrel",
			position = { x = 10, y = 2.5, z = -58 },
			radius = 9,
			damage = 70,
			impulse = 100,
		},
	},
}
