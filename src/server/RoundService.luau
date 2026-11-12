--!strict
-- RoundService: seviye yasam dongusunun tek sahibi.
--
--   startLevel -> temizle -> kur -> LevelState.new -> yayinla
--   Heartbeat -> settling ise settleTick -> faz degisirse yayinla
--   won -> skor + yildiz -> yayinla
--
-- Skor ve faz karari LevelState/ScoreModel'dedir (test edilir); burada
-- yalnizca Roblox dunyasi ile baglanti vardir.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("config")
local Core = Shared:WaitForChild("core")

local Levels = require(Shared:WaitForChild("levels"))
local BuildService = require(script.Parent:WaitForChild("BuildService"))
local DamageService = require(script.Parent:WaitForChild("DamageService"))
local FireService = require(script.Parent:WaitForChild("FireService"))
local LevelState = require(Core:WaitForChild("LevelState"))
local ScoreModel = require(Core:WaitForChild("ScoreModel"))

local RoundService = {}

local container: Folder? = nil
local state: any = nil
local levelIndex = 1
local remotes: any = nil
local lastPhase = ""
local finalScore = 0
local finalStars = 1
local settling = false

local function publish(payload: any): ()
	if remotes == nil then
		return
	end
	remotes.LevelStateChanged:FireAllClients(payload)
end

local function currentLevel(): any
	local list = Levels.list()
	return list[levelIndex] or list[1]
end

local function buildPayload(extra: any?): any
	local payload = {
		phase = state and state.phase or "idle",
		levelId = currentLevel() and currentLevel().id,
		birdsLeft = state and state.birdsLeft or 0,
		targetsLeft = state and state.targetsLeft or 0,
		score = 0,
		stars = 0,
	}
	if state ~= nil and (state.phase == "won" or state.phase == "lost") then
		local breakdown = DamageService.getBreakdown()
		local score = ScoreModel.compute(breakdown, state.birdsLeft)
		local level = currentLevel()
		finalScore = score
		finalStars = ScoreModel.stars(score, level.par)
		payload.score = finalScore
		payload.stars = finalStars
	end
	if extra ~= nil then
		for key, value in pairs(extra) do
			payload[key] = value
		end
	end
	return payload
end

local function onTargetDestroyed(_targetId: string): ()
	if state == nil then
		return
	end
	state:destroyTarget(_targetId)
	if state.phase == "won" then
		publish(buildPayload())
	end
end

local function onExplosion(position: Vector3, radius: number, damage: number): ()
	for _, part in ipairs(workspace:GetPartBoundsInRadius(position, radius)) do
		if part:GetAttribute("health") ~= nil then
			part:SetAttribute("pendingDamage", (part:GetAttribute("pendingDamage") or 0) + damage)
		end
		if not part.Anchored then
			local direction = part.Position - position
			if direction.Magnitude > 0.1 then
				part:ApplyImpulse(direction.Unit * 90 * part.AssemblyMass)
			end
		end
	end
end

function RoundService.startLevel(index: number): ()
	levelIndex = math.clamp(index, 1, #Levels.list())

	if container == nil then
		container = Instance.new("Folder")
		container.Name = "FlockfallWorld"
		container.Parent = workspace
	end
	BuildService.cleanup(container :: Folder)

	local level = currentLevel()
	local buildResult = BuildService.build(level, container :: Folder)
	DamageService.register(buildResult)
	DamageService.attachWorld(buildResult)
	FireService.configure(level)

	state = LevelState.new(level)
	lastPhase = state.phase
	settling = false
	finalScore = 0
	finalStars = 1
	publish(buildPayload({ levelIndex = levelIndex }))
end

function RoundService.currentLevelIndex(): number
	return levelIndex
end

function RoundService.state(): any
	return state
end

function RoundService.start(remoteSet: any): ()
	remotes = remoteSet
	DamageService.start(remoteSet, onTargetDestroyed, onExplosion)

	RunService.Heartbeat:Connect(function(dt: number)
		if state == nil then
			return
		end

		local bird = FireService.activeBird()
		if state.phase == "flying" then
			if bird == nil or bird.Parent == nil then
				state:notifyLanded()
				settling = true
				FireService.clearActiveBird()
				publish(buildPayload())
			elseif bird.AssemblyLinearVelocity.Magnitude < 4 and bird.Position.Y < 40 then
				state:notifyLanded()
				settling = true
				FireService.clearActiveBird()
				publish(buildPayload())
			end
		elseif state.phase == "settling" then
			local fastest = DamageService.fastestSpeed()
			local phase = state:settleTick(dt, fastest)
			if phase ~= lastPhase then
				lastPhase = phase
				publish(buildPayload())
				if phase == "aiming" then
					-- FireService kus sirasini kendi kopyasinda tutar; paylasilan
					-- level tablosunu DEGISTIRMEYIZ (ikinci oynayista bozulurdu).
					FireService.clearActiveBird()
				end
			end
		end
	end)

	-- Yeni oyuncu geldiginde mevcut durumu gonder.
	Players.PlayerAdded:Connect(function(player: Player)
		task.wait(2)
		if remotes ~= nil and state ~= nil then
			remotes.LevelStateChanged:FireClient(player, buildPayload({ levelIndex = levelIndex }))
		end
	end)
end

return RoundService
