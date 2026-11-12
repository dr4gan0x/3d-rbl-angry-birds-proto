return function(T)
	local Kinematics = T.require("Kinematics")
	local G = 196.2
	local MAX = 260

	T.describe("Kinematics.launchVelocity", function()
		T.it("45 derece, tam guc: y ve z esit", function()
			local v = Kinematics.launchVelocity(1, 0, math.rad(45), MAX)
			T.expect(v.x):toBeCloseTo(0, 1e-9)
			T.expect(v.y):toBeCloseTo(183.84778, 1e-3)
			T.expect(v.z):toBeCloseTo(183.84778, 1e-3)
		end)

		T.it("yaw 90 derece: hiz +x yonune doner", function()
			local v = Kinematics.launchVelocity(1, math.rad(90), 0, MAX)
			T.expect(v.x):toBeCloseTo(260, 1e-6)
			T.expect(v.z):toBeCloseTo(0, 1e-6)
		end)

		T.it("sifir guc sifir hiz verir", function()
			local v = Kinematics.launchVelocity(0, 0, math.rad(30), MAX)
			T.expect(Kinematics.magnitude(v)):toBeCloseTo(0, 1e-9)
		end)

		T.it("guc 1 ustunde kirpilir", function()
			local v = Kinematics.launchVelocity(3, 0, 0, MAX)
			T.expect(Kinematics.magnitude(v)):toBeCloseTo(260, 1e-6)
		end)
	end)

	T.describe("Kinematics.positionAt", function()
		T.it("2 saniyede dusme", function()
			local p = Kinematics.positionAt({ x = 0, y = 100, z = 0 }, 2, G)
			T.expect(p.y):toBeCloseTo(-192.4, 1e-6)
		end)

		T.it("yatay hiz sabit", function()
			local p = Kinematics.positionAt({ x = 50, y = 0, z = 0 }, 3, G)
			T.expect(p.x):toBeCloseTo(150, 1e-9)
		end)
	end)

	T.describe("Kinematics.speedAt", function()
		T.it("1 saniyede hiz", function()
			T.expect(Kinematics.speedAt({ x = 0, y = 100, z = 0 }, 1, G)):toBeCloseTo(96.2, 1e-6)
		end)
	end)

	T.describe("Kinematics.flightTime", function()
		T.it("yukari 100 stud/s: 1.01937 sn", function()
			T.expect(Kinematics.flightTime({ x = 0, y = 100, z = 0 }, G)):toBeCloseTo(1.01937, 1e-4)
		end)

		T.it("asagi yonlu hiz icin sifir", function()
			T.expect(Kinematics.flightTime({ x = 0, y = -5, z = 0 }, G)):toBe(0)
		end)
	end)

	T.describe("Kinematics (ozellik testi)", function()
		T.it("240 Hz ayrik adim analitik yorungeye 0.5 stud icinde yakinsar", function()
			local v0 = Kinematics.launchVelocity(1, 0, math.rad(45), MAX)
			local dt = 1 / 240
			local p = { x = 0, y = 0, z = 0 }
			local v = v0
			for _ = 1, 240 do
				p = Kinematics.add(p, Kinematics.scale(v, dt))
				v = Kinematics.step(v, dt, G)
			end
			local analytic = Kinematics.positionAt(v0, 1, G)
			T.expect(p.y):toBeCloseTo(analytic.y, 0.5)
			T.expect(p.z):toBeCloseTo(analytic.z, 1e-6)
		end)
	end)
end
