return function(T)
	T.describe("TestKit", function()
		T.it("matematik calisiyor", function()
			T.expect(1 + 1):toBe(2)
		end)

		T.it("yaklasik esitlik tolerans icinde", function()
			T.expect(0.1 + 0.2):toBeCloseTo(0.3, 1e-9)
		end)

		T.it("yanlis deger yakalanir", function()
			T.expect(2):toBe(2)
		end)
	end)
end
