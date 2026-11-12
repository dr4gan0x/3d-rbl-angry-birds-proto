return function(T)
	local BuildPlan = T.require("BuildPlan")
	local Levels = T.require("Levels")
	local Materials = T.config("Materials")

	T.describe("BuildPlan.fromLevel", function()
		T.it("her parca icin bir plan uretir", function()
			local level = Levels.get("level-01")
			local plan = BuildPlan.fromLevel(level, Materials)
			T.expect(#plan):toBe(#level.pieces)
		end)

		T.it("Wood yapili olur", function()
			local level = Levels.get("level-01")
			local plan = BuildPlan.fromLevel(level, Materials)
			for _, entry in ipairs(plan) do
				if entry.material == "Wood" then
					T.expect(entry.anchored):toBeTrue()
				end
			end
		end)

		T.it("her parca icin agirlik ve malzeme bilgisi tasir", function()
			local level = Levels.get("level-02")
			local plan = BuildPlan.fromLevel(level, Materials)
			for _, entry in ipairs(plan) do
				T.expect(Materials[entry.material] ~= nil):toBeTrue()
				T.expect(entry.mass > 0):toBeTrue()
			end
		end)

		T.it("renkler malzemeye ozgu ve farkli", function()
			T.expect(BuildPlan.colorFor("Wood")):toEqual({ 0.55, 0.32, 0.16 })
			T.expect(BuildPlan.colorFor("Metal")):toEqual({ 0.42, 0.45, 0.49 })
		end)

		T.it("bilinmeyen malzeme hata verir", function()
			T.expect(function()
				BuildPlan.colorFor("Kagit")
			end):toThrow()
		end)
	end)
end
