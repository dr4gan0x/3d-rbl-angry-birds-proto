return function(T)
	local RateLimiter = T.require("RateLimiter")

	T.describe("RateLimiter", function()
		T.it("ilk istek gecer", function()
			local limiter = RateLimiter.new(0.35)
			T.expect(limiter:allow(0)):toBeTrue()
		end)

		T.it("cok hizli ikinci istek reddedilir", function()
			local limiter = RateLimiter.new(0.35)
			limiter:allow(0)
			T.expect(limiter:allow(0.1)):toBeFalse()
		end)

		T.it("aralik dolunca tekrar gecer", function()
			local limiter = RateLimiter.new(0.35)
			limiter:allow(0)
			T.expect(limiter:allow(0.36)):toBeTrue()
		end)

		T.it("reddedilen istek zamani ilerletmez", function()
			local limiter = RateLimiter.new(0.35)
			limiter:allow(0)
			limiter:allow(0.3)
			T.expect(limiter:allow(0.36)):toBeTrue()
		end)
	end)
end
