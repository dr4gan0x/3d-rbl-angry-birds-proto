return function(T)
	local LevelState = T.require("LevelState")

	local function makeLevel(birds, targets)
		local loadout = {}
		for i = 1, birds do
			loadout[i] = "Wren"
		end
		local targetList = {}
		for i = 1, targets do
			targetList[i] = { id = "t" .. i, position = { x = 0, y = 1, z = -20 }, health = 100 }
		end
		return {
			id = "test",
			name = "Test",
			par = { two = 100, three = 200 },
			loadout = loadout,
			slingshot = { position = { x = 0, y = 0, z = 0 }, facing = { x = 0, y = 0, z = -1 } },
			pieces = {},
			targets = targetList,
			props = {},
		}
	end

	T.describe("LevelState", function()
		T.it("baslangicta aiming ve tam kus sayisi", function()
			local s = LevelState.new(makeLevel(3, 2))
			T.expect(s.phase):toBe("aiming")
			T.expect(s.birdsLeft):toBe(3)
			T.expect(s.targetsLeft):toBe(2)
		end)

		T.it("atis kus tuketir ve flying'e gecer", function()
			local s = LevelState.new(makeLevel(3, 1))
			T.expect(s:fire()):toBeTrue()
			T.expect(s.phase):toBe("flying")
			T.expect(s.birdsLeft):toBe(2)
		end)

		T.it("flying disinda atis reddedilir", function()
			local s = LevelState.new(makeLevel(3, 1))
			s:fire()
			T.expect(s:fire()):toBeFalse()
			T.expect(s.birdsLeft):toBe(2)
		end)

		T.it("son hedef olunce kazanilir", function()
			local s = LevelState.new(makeLevel(3, 1))
			s:fire()
			s:notifyLanded()
			s:destroyTarget("t1")
			T.expect(s.phase):toBe("won")
			T.expect(s.targetsLeft):toBe(0)
		end)

		T.it("son kusla son hedef ayni anda olurse kazanilir", function()
			local s = LevelState.new(makeLevel(1, 1))
			s:fire()
			s:destroyTarget("t1")
			T.expect(s.phase):toBe("won")
			T.expect(s:result().won):toBeTrue()
		end)

		T.it("kus bitince ve hedef kaldiysa kaybedilir", function()
			local s = LevelState.new(makeLevel(1, 1))
			s:fire()
			s:notifyLanded()
			s:settleTick(5, 0)
			T.expect(s.phase):toBe("lost")
			T.expect(s:result().won):toBeFalse()
		end)

		T.it("hareket durunca hemen cozulur", function()
			local s = LevelState.new(makeLevel(2, 1))
			s:fire()
			s:notifyLanded()
			T.expect(s:settleTick(0.1, 0.2)):toBe("aiming")
			T.expect(s.phase):toBe("aiming")
		end)

		T.it("4 saniye sonra hareket surse de cozulur", function()
			local s = LevelState.new(makeLevel(1, 1))
			s:fire()
			s:notifyLanded()
			for _ = 1, 50 do
				s:settleTick(0.1, 9.0)
			end
			T.expect(s.phase):toBe("lost")
		end)

		T.it("kazanildiktan sonra atis yok", function()
			local s = LevelState.new(makeLevel(3, 1))
			s:fire()
			s:destroyTarget("t1")
			T.expect(s:fire()):toBeFalse()
		end)

		T.it("sonuc fazlari dogru raporlanir", function()
			local s = LevelState.new(makeLevel(2, 1))
			T.expect(s:result()):toBe(nil)
			s:fire()
			s:destroyTarget("t1")
			T.expect(s:result().won):toBeTrue()
			T.expect(s:result().birdsLeft):toBe(1)
		end)
	end)
end
