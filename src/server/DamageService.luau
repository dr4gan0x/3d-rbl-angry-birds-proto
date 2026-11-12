--!strict
-- DamageService: carpismalari olcup hasara cevirir.
--
-- Akis: Touched -> DamageQueue (biriktir) -> Heartbeat (uygula) -> DamageEvent.
-- Boylece bir karede 20 temas 20 ayri guncelleme yerine 1 guncelleme olur.
-- Hedef parcalarin sagligini SUNUCU tutar; istemci sadece gorsel alir.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("config")
local Core = Shared:WaitForChild("core")

local Materials = require(Config:WaitForChild("Materials"))
local DamageModel = require(Core:WaitForChild("DamageModel"))
local DamageQueue = require(Core:WaitForChild("DamageQueue"))

local DamageService = {}

type PieceState = { pieceId: string, material: string, health: number, part: BasePart }

local queue = DamageQueue.new()
local pieces: { [string]: PieceState } = {}
local targets: { [string]: PieceState } = {}
local props: { [string]: BasePart } = {}
local breakdown = { Tinhead = 0, Wood = 0, Glass = 0, Stone = 0 }
local onTargetDestroyed: ((targetId: string) -> ())? = nil
local onExplosion: ((position: Vector3, radius: number, damage: number) -> ())? = nil
local remotes: any = nil
local started = false

local function resetState(): ()
	queue = DamageQueue.new()
	pieces = {}
	targets = {}
	props = {}
	breakdown = { Tinhead = 0, Wood = 0, Glass = 0, Stone = 0 }
end

-- Son karedeki en hizli parca (settling tespiti icin).
function DamageService.fastestSpeed(): number
	local fastest = 0
	for _, state in pairs(pieces) do
		if state.part.Parent ~= nil then
			local speed = state.part.AssemblyLinearVelocity.Magnitude
			if speed > fastest then
				fastest = speed
			end
		end
	end
	for _, state in pairs(targets) do
		if state.part.Parent ~= nil then
			local speed = state.part.AssemblyLinearVelocity.Magnitude
			if speed > fastest then
				fastest = speed
			end
		end
	end
	return fastest
end

function DamageService.getBreakdown(): any
	return breakdown
end

function DamageService.register(buildResult: any): ()
	resetState()
	for pieceId, built in pairs(buildResult.pieces) do
		pieces[pieceId] = {
			pieceId = pieceId,
			material = built.material,
			health = built.health,
			part = built.part,
		}
	end
	for targetId, built in pairs(buildResult.targets) do
		targets[targetId] = {
			pieceId = targetId,
			material = "Tinhead",
			health = built.health,
			part = built.part,
		}
	end
	for propId, part in pairs(buildResult.props) do
		props[propId] = part
	end
end

local function addDamage(pieceId: string, amount: number): ()
	if amount <= 0 then
		return
	end
	local state = pieces[pieceId] or targets[pieceId]
	if state == nil then
		return
	end
	queue:push(pieceId, amount)
end

-- Bir parcanin temas ettigi diger parcaya hasar verir.
local function handleTouch(hitter: BasePart, victim: BasePart): ()
	local victimKind = victim:GetAttribute("kind")

	-- Patlayici varil: carpma ile tetiklenir.
	if victimKind == "ExplosiveBarrel" then
		local speed = hitter.AssemblyLinearVelocity.Magnitude
		if speed > 25 then
			if onExplosion ~= nil then
				onExplosion(
					victim.Position,
					victim:GetAttribute("radius") or 8,
					victim:GetAttribute("damage") or 60
				)
			end
			victim:Destroy()
		end
		return
	end

	local material = victim:GetAttribute("material")
	if material == nil then
		return
	end

	local speed = (hitter.AssemblyLinearVelocity - victim.AssemblyLinearVelocity).Magnitude
	local damage =
		DamageModel.impactDamage(speed, hitter.AssemblyMass, material, Materials.definitions)
	addDamage(victim:GetAttribute("pieceId") or victim.Name, damage)

	-- Hedeflerde dusme hasari: hizli carpma ekstra hasar verir.
	if victimKind == "Tinhead" then
		local fall = DamageModel.fallDamage(speed)
		if fall > 0 then
			addDamage(victim:GetAttribute("targetId") or victim.Name, fall)
		end
	end
end

-- Bekleyen `pendingDamage` attribute'larini kuyruga aktarir.
local function collectPendingDamage(): ()
	local function scan(part: BasePart)
		local pending = part:GetAttribute("pendingDamage")
		if type(pending) == "number" and pending > 0 then
			part:SetAttribute("pendingDamage", 0)
			addDamage(
				part:GetAttribute("pieceId") or part:GetAttribute("targetId") or part.Name,
				pending
			)
		end
	end
	for _, state in pairs(pieces) do
		if state.part.Parent ~= nil then
			scan(state.part)
		end
	end
	for _, state in pairs(targets) do
		if state.part.Parent ~= nil then
			scan(state.part)
		end
	end
	for _, part in pairs(props) do
		if part.Parent ~= nil then
			scan(part)
		end
	end
end

local function flushQueue(): ()
	collectPendingDamage()

	local entries = queue:drain()
	if #entries == 0 then
		return
	end

	local affected = {}
	for _, entry in ipairs(entries) do
		local state = pieces[entry.pieceId] or targets[entry.pieceId]
		if state ~= nil and state.part.Parent ~= nil then
			table.insert(affected, { state = state, damage = entry.damage })
		end
	end

	local pieceList = {}
	for _, item in ipairs(affected) do
		table.insert(pieceList, item.state)
	end
	local outcomes = DamageModel.resolveHits(pieceList, entries)

	for _, outcome in ipairs(outcomes) do
		local state = pieces[outcome.pieceId] or targets[outcome.pieceId]
		if state == nil then
			continue
		end
		state.health = outcome.healthAfter
		state.part:SetAttribute("health", outcome.healthAfter)

		if remotes ~= nil then
			remotes.DamageEvent:FireAllClients(
				outcome.pieceId,
				outcome.healthAfter,
				outcome.destroyed
			)
		end

		if outcome.destroyed then
			local isTarget = targets[outcome.pieceId] ~= nil
			if isTarget then
				breakdown.Tinhead += 1
				state.part:Destroy()
				if onTargetDestroyed ~= nil then
					onTargetDestroyed(outcome.pieceId)
				end
			else
				if breakdown[state.material] ~= nil then
					breakdown[state.material] += 1
				end
				-- Enkaz: carpismayi kapat, kisa omur, sonra sil.
				state.part.CanCollide = false
				state.part.CanTouch = false
				state.part.Transparency = 0.35
				state.part.CollisionGroup = "Default"
				local debrisPart = state.part
				task.delay(2.5, function()
					if debrisPart.Parent ~= nil then
						debrisPart:Destroy()
					end
				end)
				pieces[outcome.pieceId] = nil
			end
		end
	end
end

local function connectTouches(buildResult: any): ()
	local function connect(part: BasePart)
		part.Touched:Connect(function(other: BasePart)
			-- Kumeden sayilar: cok yuksek frekansli temaslari sakinlestir.
			local now = os.clock()
			if
				part:GetAttribute("lastTouch") ~= nil
				and now - (part:GetAttribute("lastTouch") :: number) < 0.05
			then
				return
			end
			part:SetAttribute("lastTouch", now)
			pcall(handleTouch, part, other)
		end)
	end
	for _, built in pairs(buildResult.pieces) do
		connect(built.part)
	end
	for _, built in pairs(buildResult.targets) do
		connect(built.part)
	end
	for _, part in pairs(buildResult.props) do
		connect(part)
	end
end

function DamageService.start(
	remoteSet: any,
	targetDestroyed: ((string) -> ())?,
	explosion: ((Vector3, number, number) -> ())?
): ()
	remotes = remoteSet
	onTargetDestroyed = targetDestroyed
	onExplosion = explosion

	if started then
		return
	end
	started = true

	RunService.Heartbeat:Connect(function()
		pcall(flushQueue)
	end)
end

function DamageService.attachWorld(buildResult: any): ()
	connectTouches(buildResult)
end

return DamageService
