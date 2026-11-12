return function(T)
	local ScoreModel = T.require("ScoreModel")

	T.describe("ScoreModel.compute", function()
		T.it("bos kirilma, 3 kus kaldi: 3000", function()
			local s = ScoreModel.compute({ Tinhead = 0, Wood = 0, Glass = 0, Stone = 0 }, 3)
			T.expect(s):toBe(3000)
		end)

		T.it("karisik kirilma", function()
			local s = ScoreModel.compute({ Tinhead = 4, Wood = 10, Glass = 5, Stone = 2 }, 1)
			T.expect(s):toBe(3780)
		end)

		T.it("eksik alan sifir sayilir", function()
			T.expect(ScoreModel.compute({ Tinhead = 1 }, 0)):toBe(500)
		end)
	end)

	T.describe("ScoreModel.stars", function()
		local par = { two = 3200, three = 5400 }

		T.it("esik tam tutarsa 3 yildiz", function()
			T.expect(ScoreModel.stars(5400, par)):toBe(3)
		end)

		T.it("esik altinda 2 yildiz", function()
			T.expect(ScoreModel.stars(5399, par)):toBe(2)
		end)

		T.it("iki esigi de gecerse 1 yildiz", function()
			T.expect(ScoreModel.stars(100, par)):toBe(1)
		end)

		T.it("sifir skor 0 yildiz degil 1 yildiz", function()
			T.expect(ScoreModel.stars(0, par)):toBe(1)
		end)
	end)
end
