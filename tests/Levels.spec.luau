return function(T)
	local Levels = T.require("Levels")
	local LevelSchema = T.require("LevelSchema")
	local GameConfig = T.config("GameConfig")
	local Materials = T.config("Materials")

	T.describe("Levels", function()
		T.it("uc seviye var", function()
			T.expect(#Levels.list()):toBe(3)
		end)

		for _, level in ipairs(Levels.list()) do
			T.it("seviye gecerli: " .. level.id, function()
				local ok, errors = LevelSchema.validate(level, GameConfig, Materials)
				T.expect(ok):toBeTrue()
				T.expect(#errors):toBe(0)
			end)

			T.it("seviyede en az bir Tinhead var: " .. level.id, function()
				T.expect(#level.targets > 0):toBeTrue()
			end)

			T.it("kus yuku bilinen tiplerden: " .. level.id, function()
				T.expect(#level.loadout > 0):toBeTrue()
				for _, bird in ipairs(level.loadout) do
					local known = false
					for _, allowed in ipairs(GameConfig.BIRD_TYPES) do
						if bird == allowed then
							known = true
						end
					end
					T.expect(known):toBeTrue()
				end
			end)

			T.it("id ile erisilebilir: " .. level.id, function()
				T.expect(Levels.get(level.id).id):toBe(level.id)
			end)
		end
	end)
end
