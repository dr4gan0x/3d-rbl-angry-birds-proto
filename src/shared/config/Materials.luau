--!strict
-- Materials: yikim parametreleri. Core modul DEGILDIR (config katmani);
-- DamageModel bu tabloyu parametre olarak alir.

export type MaterialDefinition = {
	health: number,
	density: number,
	multiplier: number,
}

export type MaterialTable = { [string]: MaterialDefinition }

local Materials = {}

Materials.definitions = {
	Wood = { health = 55, density = 0.6, multiplier = 1.0 },
	Glass = { health = 24, density = 0.4, multiplier = 2.0 },
	Stone = { health = 140, density = 1.8, multiplier = 0.65 },
	-- Metal kirilmaz: sonsuz saglik, sifir hasar carpani.
	Metal = { health = math.huge, density = 2.4, multiplier = 0 },
} :: MaterialTable

return Materials
