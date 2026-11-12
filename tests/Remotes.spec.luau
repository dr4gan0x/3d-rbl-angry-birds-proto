return function(T)
	local Remotes = T.require("Remotes")

	T.describe("Remotes", function()
		T.it("bes olay adi tanimli", function()
			T.expect(#Remotes.NAMES):toBe(5)
		end)

		T.it("adlar spec ile ayni", function()
			T.expect(Remotes.NAMES):toEqual({
				"FireRequest",
				"AbilityRequest",
				"ShotFired",
				"DamageEvent",
				"LevelStateChanged",
			})
		end)
	end)
end
