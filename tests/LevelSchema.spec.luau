return function(T)
	local LevelSchema = T.require("LevelSchema")
	local GameConfig = T.config("GameConfig")
	local Materials = T.config("Materials")

	local function base()
		return {
			id = "test",
			name = "Test",
			par = { two = 100, three = 200 },
			loadout = { "Wren" },
			slingshot = { position = { x = 0, y = 0, z = 0 }, facing = { x = 0, y = 0, z = -1 } },
			pieces = {
				{
					id = "w1",
					material = "Wood",
					size = { x = 2, y = 2, z = 2 },
					position = { x = 0, y = 1, z = -30 },
				},
			},
			targets = { { id = "t1", position = { x = 0, y = 1, z = -30 }, health = 100 } },
			props = {},
		}
	end

	local function contains(list, code)
		for _, item in ipairs(list) do
			if item == code then
				return true
			end
		end
		return false
	end

	T.describe("LevelSchema.validate", function()
		T.it("gecerli taban gecer", function()
			local ok = LevelSchema.validate(base(), GameConfig, Materials)
			T.expect(ok):toBeTrue()
		end)

		T.it("par eksikse hata", function()
			local def = base()
			def.par = nil
			local ok, errors = LevelSchema.validate(def, GameConfig, Materials)
			T.expect(ok):toBeFalse()
			T.expect(contains(errors, "bad_par")):toBeTrue()
		end)

		T.it("bilinmeyen kus tipi hata", function()
			local def = base()
			def.loadout = { "Kartal" }
			local _, errors = LevelSchema.validate(def, GameConfig, Materials)
			T.expect(contains(errors, "unknown_bird:Kartal")):toBeTrue()
		end)

		T.it("bos kus yuku hata", function()
			local def = base()
			def.loadout = {}
			local _, errors = LevelSchema.validate(def, GameConfig, Materials)
			T.expect(contains(errors, "empty_loadout")):toBeTrue()
		end)

		T.it("ayni id iki kez hata", function()
			local def = base()
			table.insert(
				def.pieces,
				{
					id = "w1",
					material = "Wood",
					size = { x = 2, y = 2, z = 2 },
					position = { x = 20, y = 1, z = -30 },
				}
			)
			local _, errors = LevelSchema.validate(def, GameConfig, Materials)
			T.expect(contains(errors, "duplicate_piece_id:w1")):toBeTrue()
		end)

		T.it("bilinmeyen malzeme hata", function()
			local def = base()
			def.pieces[1].material = "Kagit"
			local _, errors = LevelSchema.validate(def, GameConfig, Materials)
			T.expect(contains(errors, "unknown_material:Kagit")):toBeTrue()
		end)

		T.it("sifir boyut hata", function()
			local def = base()
			def.pieces[1].size = { x = 0, y = 2, z = 2 }
			local _, errors = LevelSchema.validate(def, GameConfig, Materials)
			T.expect(contains(errors, "bad_size:w1")):toBeTrue()
		end)

		T.it("hedef yoksa hata", function()
			local def = base()
			def.targets = {}
			local _, errors = LevelSchema.validate(def, GameConfig, Materials)
			T.expect(contains(errors, "empty_targets")):toBeTrue()
		end)

		T.it("menzil disi hedef hata", function()
			local def = base()
			def.targets[1].position = { x = 0, y = 0, z = -900 }
			local _, errors = LevelSchema.validate(def, GameConfig, Materials)
			T.expect(contains(errors, "target_out_of_range:t1")):toBeTrue()
		end)

		T.it("cakisan parcalar hata", function()
			local def = base()
			table.insert(
				def.pieces,
				{
					id = "w2",
					material = "Wood",
					size = { x = 2, y = 2, z = 2 },
					position = { x = 0, y = 1, z = -30 },
				}
			)
			local _, errors = LevelSchema.validate(def, GameConfig, Materials)
			T.expect(contains(errors, "overlapping_pieces:w1:w2")):toBeTrue()
		end)
	end)
end
