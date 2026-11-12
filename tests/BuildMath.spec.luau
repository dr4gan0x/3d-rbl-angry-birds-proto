return function(T)
	local BuildMath = T.require("BuildMath")

	T.describe("BuildMath.aabb", function()
		T.it("rotasyonsuz kutu sinirlari", function()
			local box = BuildMath.aabb({
				position = { x = 0, y = 10, z = 0 },
				size = { x = 2, y = 4, z = 6 },
			})
			T.expect(box.min.y):toBeCloseTo(8, 1e-9)
			T.expect(box.max.y):toBeCloseTo(12, 1e-9)
			T.expect(box.max.z):toBeCloseTo(3, 1e-9)
		end)

		T.it("y ekseninde 90 derece x ve z'yi takas eder", function()
			local box = BuildMath.aabb({
				position = { x = 0, y = 0, z = 0 },
				size = { x = 2, y = 4, z = 6 },
				rotation = { x = 0, y = 90, z = 0 },
			})
			T.expect(box.max.x):toBeCloseTo(3, 1e-9)
			T.expect(box.max.z):toBeCloseTo(1, 1e-9)
		end)
	end)

	T.describe("BuildMath.overlaps", function()
		T.it("ayni yerde iki kutu cakisir", function()
			local a = BuildMath.aabb({
				position = { x = 0, y = 0, z = 0 },
				size = { x = 2, y = 2, z = 2 },
			})
			local b = BuildMath.aabb({
				position = { x = 1, y = 0, z = 0 },
				size = { x = 2, y = 2, z = 2 },
			})
			T.expect(BuildMath.overlaps(a, b)):toBeTrue()
		end)

		T.it("yan yana kutular cakismaz", function()
			local a = BuildMath.aabb({
				position = { x = 0, y = 0, z = 0 },
				size = { x = 2, y = 2, z = 2 },
			})
			local b = BuildMath.aabb({
				position = { x = 5, y = 0, z = 0 },
				size = { x = 2, y = 2, z = 2 },
			})
			T.expect(BuildMath.overlaps(a, b)):toBeFalse()
		end)

		T.it("tam kenar temas eden kutular cakismaz", function()
			local a = BuildMath.aabb({
				position = { x = 0, y = 0, z = 0 },
				size = { x = 2, y = 2, z = 2 },
			})
			local b = BuildMath.aabb({
				position = { x = 2, y = 0, z = 0 },
				size = { x = 2, y = 2, z = 2 },
			})
			T.expect(BuildMath.overlaps(a, b)):toBeFalse()
		end)
	end)
end
