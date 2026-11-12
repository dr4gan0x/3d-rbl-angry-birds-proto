--!strict
-- FireService: atis isteklerini dogrular ve kusu dunyaya cikarir.
--
-- SUNUCU OTORITESI: istemci yalnizca (power, yaw, pitch) GONDERIR. Kuvvet,
-- yon, hiz ve carpisma sonucu sunucuda belirlenir. Istemci maksimum gucu
-- asan bir deger gonderirse kirpilir; sira disi atis reddedilir.

local Debris = game:GetService("Debris")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("config")
local Core = Shared:WaitForChild("core")

local GameConfig = require(Config:WaitForChild("GameConfig"))
local Kinematics = require(Core:WaitForChild("Kinematics"))
local RateLimiter = require(Core:WaitForChild("RateLimiter"))
local RoundLoadout = require(Core:WaitForChild("RoundLoadout"))

export type BirdSpec = {
	kind: string,
	mass: number,
	radius: number,
	color: Color3,
	ability: string?,
}

-- Kus tipleri: masa gore hasar, yetenek davranisi.
local BIRDS: { [string]: BirdSpec } = {
	Wren = { kind = "Wren", mass = 2.0, radius = 1.2, color = Color3.fromRGB(226, 178, 92) },
	Swallow = {
		kind = "Swallow",
		mass = 1.2,
		radius = 1.0,
		color = Color3.fromRGB(94, 168, 214),
		ability = "dash",
	},
	Puffin = {
		kind = "Puffin",
		mass = 3.5,
		radius = 1.5,
		color = Color3.fromRGB(232, 108, 74),
		ability = "burst",
	},
}

local FireService = {}

local limiters: { [Player]: any } = {}
local currentLevel: any = nil
local loadout: any = nil
local slingshotOrigin: Vector3 = Vector3.new(0, 6, 0)
local onBirdFired: ((Player, BasePart, BirdSpec) -> ())? = nil
local activeBird: BasePart? = nil

local function ensureLimiter(player: Player): any
	local limiter = limiters[player]
	if limiter == nil then
		limiter = RateLimiter.new(GameConfig.FIRE_COOLDOWN)
		limiters[player] = limiter
	end
	return limiter
end

local function spawnBird(player: Player, birdType: string, velocity: Vector3): BasePart
	local spec = BIRDS[birdType] or BIRDS.Wren
	local part = Instance.new("Part")
	part.Name = "Bird_" .. birdType
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(spec.radius * 2, spec.radius * 2, spec.radius * 2)
	part.Position = slingshotOrigin
	part.Color = spec.color
	part.Material = Enum.Material.SmoothPlastic
	part.CanCollide = true
	part.CollisionGroup = "Actors"
	part.CustomPhysicalProperties = PhysicalProperties.new(0.6, 0.4, 0.5, 1, 1)
	part:SetAttribute("kind", "Bird")
	part:SetAttribute("birdType", birdType)
	part:SetAttribute("mass", spec.mass)
	part:SetAttribute("ownerUserId", player.UserId)

	-- Yercekimi etkisi sunucuda: Roblox'un kendi simule ettigi kuvvet.
	-- Ag sahipligi sunucuda kalir; istemci kusu iteleyemez.
	part.Parent = workspace
	part:SetNetworkOwner(nil)
	part.AssemblyLinearVelocity = velocity

	Debris:AddItem(part, 12)
	activeBird = part

	if onBirdFired ~= nil then
		task.spawn(onBirdFired, player, part, spec)
	end
	return part
end

-- Seviye basinda sapan konumunu ve sirayi ayarlar.
function FireService.configure(level: any, onFired: ((Player, BasePart, BirdSpec) -> ())?): ()
	currentLevel = level
	slingshotOrigin = Vector3.new(
		level.slingshot.position.x,
		level.slingshot.position.y,
		level.slingshot.position.z
	)
	onBirdFired = onFired
	limiters = {}
	loadout = RoundLoadout.new(level.loadout)
	FireService.clearActiveBird()
end

function FireService.activeBird(): BasePart?
	return activeBird
end

-- Ucus bitti: yeni atisa izin vermek icin referansi birak.
function FireService.clearActiveBird(): ()
	activeBird = nil
end

function FireService.remainingBirds(): number
	if loadout == nil then
		return 0
	end
	return loadout:remaining()
end

-- Atis kabul edildiginde siradaki kusu tuketir (state machine ile ayni adimda).
function FireService.consumeBird(): ()
	if loadout ~= nil then
		loadout:take()
	end
end

-- Sunucu tarafi dogrulama: tip -> aralik -> frekans -> sira -> kus var mi.
function FireService.handleFire(player: Player, power: any, yaw: any, pitch: any): string?
	if type(power) ~= "number" or type(yaw) ~= "number" or type(pitch) ~= "number" then
		return nil
	end
	-- NaN ve sonsuz degerleri reddet.
	if power ~= power or yaw ~= yaw or pitch ~= pitch then
		return nil
	end
	if
		math.abs(power) == math.huge
		or math.abs(yaw) == math.huge
		or math.abs(pitch) == math.huge
	then
		return nil
	end
	if power < 0 or power > 1 then
		return nil
	end
	if math.abs(yaw) > math.pi + 0.001 or math.abs(pitch) > math.pi / 2 + 0.001 then
		return nil
	end
	if currentLevel == nil then
		return nil
	end

	local limiter = ensureLimiter(player)
	if not limiter:allow(os.clock()) then
		return nil
	end

	if activeBird ~= nil and activeBird.Parent ~= nil then
		return nil -- onceki kus hala havada
	end

	local birdType = (loadout and loadout:peek()) or "Wren"
	local velocity = Kinematics.launchVelocity(power, yaw, pitch, GameConfig.MAX_SPEED)
	local vector = Vector3.new(velocity.x, velocity.y, velocity.z)
	FireService.consumeBird()
	spawnBird(player, birdType, vector)
	return birdType
end

-- Ucus yetenegi: Swallow hiz patlamasi, Puffin patlama.
function FireService.handleAbility(player: Player): boolean
	local bird = activeBird
	if bird == nil or bird.Parent == nil then
		return false
	end
	if bird:GetAttribute("ownerUserId") ~= player.UserId then
		return false
	end
	if bird:GetAttribute("abilityUsed") == true then
		return false
	end
	bird:SetAttribute("abilityUsed", true)

	local birdType = bird:GetAttribute("birdType")
	if birdType == "Swallow" then
		local velocity = bird.AssemblyLinearVelocity
		if velocity.Magnitude > 1 then
			-- Yon korunur, hiz 1.9x; dikey bilesen yumusatilir (dalma etkisi).
			local horizontal = Vector3.new(velocity.X, 0, velocity.Z).Unit
			local speed = velocity.Magnitude * 1.9
			bird.AssemblyLinearVelocity = (horizontal * 0.92 + Vector3.new(0, 0.08, 0)) * speed
		end
		return true
	elseif birdType == "Puffin" then
		local position = bird.Position
		bird:SetAttribute("burstAt", true)
		task.delay(0.4, function()
			if bird.Parent == nil then
				return
			end
			local explosion = Instance.new("Explosion")
			explosion.BlastRadius = 14
			explosion.BlastPressure = 0
			explosion.DestroyJointRadiusPercent = 0
			explosion.Position = position
			explosion.ExplosionType = Enum.ExplosionType.NoCraters
			explosion.Parent = workspace
			explosion.Hit:Connect(function(part: BasePart)
				-- Patlama hasari DamageService tarafindan islenir (attribute ile).
				if part:GetAttribute("health") ~= nil then
					part:SetAttribute(
						"pendingDamage",
						(part:GetAttribute("pendingDamage") or 0) + 60
					)
				end
			end)
			for _, other in ipairs(workspace:GetPartBoundsInRadius(position, 14)) do
				if other:IsA("BasePart") and not other.Anchored then
					local direction = (other.Position - position)
					if direction.Magnitude < 0.1 then
						direction = Vector3.new(0, 1, 0)
					end
					other:ApplyImpulse(direction.Unit * 140 * other.AssemblyMass)
				end
			end
			bird:Destroy()
		end)
		return true
	end

	return false
end

function FireService.start(remotes: any): ()
	limiters = {}
	remotes.FireRequest.OnServerEvent:Connect(
		function(player: Player, power: any, yaw: any, pitch: any)
			local firedType: string? = nil
			local success, err = pcall(function()
				firedType = FireService.handleFire(player, power, yaw, pitch)
			end)
			if not success then
				warn("[FireService] atis hatasi: " .. tostring(err))
			end
			if firedType ~= nil then
				remotes.ShotFired:FireAllClients(player, firedType, slingshotOrigin)
			end
		end
	)

	remotes.AbilityRequest.OnServerEvent:Connect(function(player: Player, birdType: any)
		pcall(function()
			FireService.handleAbility(player)
		end)
	end)

	Players.PlayerRemoving:Connect(function(player: Player)
		limiters[player] = nil
	end)
end

return FireService
