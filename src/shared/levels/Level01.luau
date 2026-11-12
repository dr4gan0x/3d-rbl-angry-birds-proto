--!strict
-- Seviye 1 — "Kirik Avlu". Egitim seviyesi: 3 Wren, 2 Tinhead, sadece Wood/Glass.
-- Acik cephe: oyuncu nisan almayi burada ogrenir.

return {
	id = "level-01",
	name = "Kirik Avlu",
	par = { two = 2600, three = 4200 },
	loadout = { "Wren", "Wren", "Wren" },
	slingshot = { position = { x = 0, y = 6, z = 0 }, facing = { x = 0, y = 0, z = -1 } },
	pieces = {
		{
			id = "l1",
			material = "Wood",
			size = { x = 2, y = 12, z = 2 },
			position = { x = -6, y = 6, z = -46 },
		},
		{
			id = "r1",
			material = "Wood",
			size = { x = 2, y = 12, z = 2 },
			position = { x = 6, y = 6, z = -46 },
		},
		{
			id = "roof",
			material = "Wood",
			size = { x = 16, y = 2, z = 4 },
			position = { x = 0, y = 13, z = -46 },
		},
		{
			id = "g1",
			material = "Glass",
			size = { x = 6, y = 8, z = 1 },
			position = { x = 0, y = 4, z = -44 },
		},
		{
			id = "box",
			material = "Wood",
			size = { x = 5, y = 5, z = 5 },
			position = { x = 14, y = 2.5, z = -52 },
		},
	},
	targets = {
		{ id = "t1", position = { x = -3, y = 8, z = -46 }, health = 100 },
		{ id = "t2", position = { x = 3, y = 8, z = -46 }, health = 100 },
	},
	props = {},
}
