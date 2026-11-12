return function(T)
	local Trajectory = T.require("Trajectory")

	T.describe("Trajectory.sample", function()
		T.it("ilk nokta baslangictir", function()
			local points = Trajectory.sample({ x = 0, y = 10, z = 0 }, 196.2, 3, 0.1)
			T.expect(#points):toBe(3)
			T.expect(points[1].y):toBe(0)
		end)

		T.it("noktalar dusmeye baslar", function()
			local points = Trajectory.sample({ x = 0, y = 0, z = 0 }, 196.2, 4, 0.25)
			T.expect(points[2].y < points[1].y):toBeTrue()
			T.expect(points[4].y < points[2].y):toBeTrue()
		end)

		T.it("yatay ilerleme orantili", function()
			local points = Trajectory.sample({ x = 100, y = 0, z = 0 }, 196.2, 3, 0.5)
			T.expect(points[2].x):toBeCloseTo(50, 1e-6)
			T.expect(points[3].x):toBeCloseTo(100, 1e-6)
		end)
	end)

	T.describe("Trajectory.apex", function()
		T.it("tepe noktasi dogru yukseklikte", function()
			local p = Trajectory.apex({ x = 0, y = 100, z = 0 }, 196.2)
			T.expect(p.y):toBeCloseTo(25.484, 1e-3)
		end)

		T.it("asagi yonlu hiz icin tepe sifirdir", function()
			T.expect(Trajectory.apex({ x = 0, y = -10, z = 0 }, 196.2).y):toBe(0)
		end)
	end)
end
