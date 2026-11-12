--!strict
-- RateLimiter: sunucu tarafi istek frekansi sinirlayici.
--
-- Saat disaridan verilir (os.clock cagirmaz) — boylece saf ve deterministik
-- kalir. Reddedilen istek `last` alanini GUNCELLEMEZ: kotu niyetli istemci
-- istek yagdirarak kendi bekleme suresini uzatamaz.

export type Limiter = {
	minInterval: number,
	last: number?,
	allow: (any, number) -> boolean,
}

local RateLimiter = {}
RateLimiter.__index = RateLimiter

function RateLimiter.new(minInterval: number): Limiter
	return setmetatable({ minInterval = minInterval, last = nil }, RateLimiter) :: any
end

function RateLimiter.allow(self: any, now: number): boolean
	if self.last ~= nil and (now - self.last) < self.minInterval then
		return false
	end
	self.last = now
	return true
end

return RateLimiter
