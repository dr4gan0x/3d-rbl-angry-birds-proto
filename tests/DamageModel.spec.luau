return function(T)
	local DamageModel = T.require("DamageModel")
	local Materials = T.config("Materials")

	T.describe("DamageModel.impactDamage", function()
		T.it("esik hizinda hasar yok", function()
			T.expect(DamageModel.impactDamage(18, 2.5, "Wood", Materials)):toBe(0)
		end)

		T.it("tam hiz, referans kutle, Wood: 100", function()
			T.expect(DamageModel.impactDamage(220, 2.5, "Wood", Materials)):toBe(100)
		end)

		T.it("orta hiz: 50", function()
			T.expect(DamageModel.impactDamage(119, 2.5, "Wood", Materials)):toBe(50)
		end)

		T.it("Glass iki kat hasar alir", function()
			T.expect(DamageModel.impactDamage(119, 2.5, "Glass", Materials)):toBe(100)
		end)

		T.it("Stone daha az hasar alir ve yuvarlanir", function()
			-- 0.5 * 1.0 * 0.65 * 100 = 32.5 ; math.round(32.5) == 33
			T.expect(DamageModel.impactDamage(119, 2.5, "Stone", Materials)):toBe(33)
		end)

		T.it("Metal hasar almaz", function()
			T.expect(DamageModel.impactDamage(260, 50, "Metal", Materials)):toBe(0)
		end)

		T.it("hafif kutle hasari azaltir", function()
			T.expect(DamageModel.impactDamage(220, 0.5, "Wood", Materials)):toBe(30)
		end)

		T.it("cok agir kutle hasari iki katla sinirlar", function()
			T.expect(DamageModel.impactDamage(220, 50, "Wood", Materials)):toBe(200)
		end)
	end)

	T.describe("DamageModel.fallDamage", function()
		T.it("40 altinda hasar yok", function()
			T.expect(DamageModel.fallDamage(39)):toBe(0)
		end)

		T.it("100 hizinda 72 hasar", function()
			T.expect(DamageModel.fallDamage(100)):toBeCloseTo(72, 1e-6)
		end)
	end)

	T.describe("DamageModel.resolveHits", function()
		T.it("saglik duser ve kirilma bildirilir", function()
			local pieces = { { id = "w1", material = "Wood", health = 55 } }
			local result = DamageModel.resolveHits(pieces, { { pieceId = "w1", damage = 60 } })
			T.expect(#result):toBe(1)
			T.expect(result[1].pieceId):toBe("w1")
			T.expect(result[1].healthAfter):toBe(0)
			T.expect(result[1].destroyed):toBeTrue()
		end)

		T.it("Metal parca math.huge ile NaN uretmez", function()
			local pieces = { { id = "m1", material = "Metal", health = math.huge } }
			local result = DamageModel.resolveHits(pieces, { { pieceId = "m1", damage = 900 } })
			T.expect(result[1].destroyed):toBeFalse()
			T.expect(result[1].healthAfter > 0):toBeTrue()
		end)

		T.it("bilinmeyen parca id'si sessizce atlanir", function()
			local result = DamageModel.resolveHits({}, { { pieceId = "yok", damage = 10 } })
			T.expect(#result):toBe(0)
		end)

		T.it("ayni karede iki vurus toplanir", function()
			local pieces = { { id = "g1", material = "Glass", health = 24 } }
			local result = DamageModel.resolveHits(pieces, {
				{ pieceId = "g1", damage = 15 },
				{ pieceId = "g1", damage = 15 },
			})
			T.expect(#result):toBe(1)
			T.expect(result[1].destroyed):toBeTrue()
		end)
	end)

	T.describe("DamageModel bilinmeyen malzeme", function()
		T.it("hata verir", function()
			T.expect(function()
				DamageModel.impactDamage(100, 1, "Kagit", Materials)
			end):toThrow()
		end)
	end)

	T.describe("Materials", function()
		T.it("Metal sonsuz saglik tasir", function()
			T.expect(Materials.Metal.health):toBe(math.huge)
		end)
	end)
end
