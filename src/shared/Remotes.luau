--!strict
-- Remotes: ag olaylarinin tek kaynagi.
--
-- `ensure` Roblox katmaninda (sunucu/istemci boot) cagrilir; `Instance.new`
-- kullandigi icin core degildir. Adlar tablosu ise saftir ve test edilir.

local Remotes = {}

Remotes.NAMES = {
	"FireRequest",
	"AbilityRequest",
	"ShotFired",
	"DamageEvent",
	"LevelStateChanged",
}

export type RemoteSet = { [string]: any }

-- Sunucu: eksik RemoteEvent'leri olusturur ve hepsini dondurur.
-- Istemci: yalnizca var olanlari toplar (WaitForChild ile).
function Remotes.ensure(parent: any, create: boolean?): RemoteSet
	local set: RemoteSet = {}
	for _, name in ipairs(Remotes.NAMES) do
		local existing = parent:FindFirstChild(name)
		if existing == nil and create then
			local remote = Instance.new("RemoteEvent")
			remote.Name = name
			remote.Parent = parent
			existing = remote
		end
		if existing == nil then
			existing = parent:WaitForChild(name)
		end
		set[name] = existing
	end
	return set
end

return Remotes
