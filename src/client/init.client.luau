--!strict
-- Istemci giris noktasi: HUD, kamera, sapan kontrolu ve ag dinleyicileri.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Remotes = require(Shared:WaitForChild("Remotes"))
local Levels = require(Shared:WaitForChild("levels"))

local CameraRig = require(script.Parent:WaitForChild("CameraRig"))
local Hud = require(script.Parent:WaitForChild("Hud"))
local SlingshotController = require(script.Parent:WaitForChild("SlingshotController"))

local remotesFolder = ReplicatedStorage:WaitForChild("Remotes")
local remoteSet = Remotes.ensure(remotesFolder, false)

local currentLevelIndex = 1
local currentLevel = Levels.list()[1]

CameraRig.start(
	Vector3.new(
		currentLevel.slingshot.position.x,
		currentLevel.slingshot.position.y,
		currentLevel.slingshot.position.z
	)
)

-- Yetenek istegi: ucus sirasinda Space (klavye) veya ikinci parmak (mobil).
local lastAbilityRequest = 0
local function requestAbility(): ()
	local now = os.clock()
	if now - lastAbilityRequest < 0.5 then
		return
	end
	lastAbilityRequest = now
	remoteSet.AbilityRequest:FireServer()
end

UserInputService.InputBegan:Connect(function(input, processed)
	if processed then
		return
	end
	if input.KeyCode == Enum.KeyCode.Space then
		requestAbility()
	end
end)

-- Mobil: nisan alma ilk parmakta; yetenek icin ikinci parmak.
local aimingTouches = 0
UserInputService.TouchStarted:Connect(function(_touch, processed)
	if processed then
		return
	end
	aimingTouches += 1
	if aimingTouches >= 2 then
		requestAbility()
	end
end)
UserInputService.TouchEnded:Connect(function(_touch, processed)
	if processed then
		return
	end
	aimingTouches = math.max(0, aimingTouches - 1)
end)

Hud.attach({
	onPrimary = function()
		Hud.hideResult()
	end,
	onSecondary = function()
		Hud.hideResult()
	end,
})

SlingshotController.start(remoteSet, currentLevel)

remoteSet.LevelStateChanged.OnClientEvent:Connect(function(payload: any)
	if payload == nil then
		return
	end

	Hud.setBirds(payload.birdsLeft or 0)
	Hud.setScore(payload.score or 0)

	if payload.levelIndex ~= nil and payload.levelIndex ~= currentLevelIndex then
		currentLevelIndex = payload.levelIndex
		local level = Levels.list()[currentLevelIndex]
		if level ~= nil then
			currentLevel = level
			SlingshotController.setLevel(level)
			CameraRig.setFocus(
				Vector3.new(
					level.slingshot.position.x,
					level.slingshot.position.y,
					level.slingshot.position.z
				)
			)
		end
	end

	if payload.phase == "aiming" then
		Hud.hideResult()
		SlingshotController.setEnabled(true)
		CameraRig.orbitMode()
	elseif payload.phase == "flying" then
		SlingshotController.setEnabled(false)
		local bird: BasePart? = nil
		for _, candidate in ipairs(workspace:GetChildren()) do
			if candidate:IsA("BasePart") and candidate:GetAttribute("kind") == "Bird" then
				bird = candidate
				break
			end
		end
		if bird ~= nil then
			CameraRig.followMode(bird)
		else
			CameraRig.aimMode()
		end
	elseif payload.phase == "settling" then
		SlingshotController.setEnabled(false)
	elseif payload.phase == "won" or payload.phase == "lost" then
		SlingshotController.setEnabled(false)
		Hud.showResult(payload)
	end
end)

print("[flockfall] client boot — level " .. tostring(currentLevel.id))
