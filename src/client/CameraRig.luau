--!strict
-- CameraRig: uc kamera modu.
--
--   orbit  — hazirlik: sapan etrafinda doner
--   aim    — nisan: sapanin arkasindan hedefe bakar
--   follow — ucus: kusu yumusak takip eder
--
-- Kamera BindToRenderStep ile guncellenir (Heartbeat'te degil): render
-- sirasinda calisir, titreme olmaz.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local CameraRig = {}

local camera = workspace.CurrentCamera
local mode = "orbit"
local focus = Vector3.new(0, 6, 0)
local orbitAngle = 0
local followTarget: BasePart? = nil
local smoothedPosition = focus

local ORBIT_DISTANCE = 34
local ORBIT_HEIGHT = 16
local AIM_DISTANCE = 26
local AIM_HEIGHT = 10

local function computeOrbit(): CFrame
	local offset = Vector3.new(
		math.sin(orbitAngle) * ORBIT_DISTANCE,
		ORBIT_HEIGHT,
		math.cos(orbitAngle) * ORBIT_DISTANCE
	)
	return CFrame.lookAt(focus + offset, focus)
end

local function computeAim(): CFrame
	-- Sapanin arkasinda, hedefe (kusun ucus yonune) bakar.
	local behind = focus + Vector3.new(0, AIM_HEIGHT, AIM_DISTANCE)
	return CFrame.lookAt(behind, focus + Vector3.new(0, 4, -60))
end

local function computeFollow(): CFrame
	local target = followTarget
	if target == nil or target.Parent == nil then
		return computeAim()
	end
	local targetPosition = target.Position
	smoothedPosition = smoothedPosition:Lerp(targetPosition, 0.12)
	local behind = smoothedPosition + Vector3.new(0, 9, 22)
	return CFrame.lookAt(behind, smoothedPosition)
end

local function update(): ()
	if camera == nil then
		return
	end
	local cframe: CFrame
	if mode == "follow" then
		cframe = computeFollow()
	elseif mode == "aim" then
		cframe = computeAim()
	else
		cframe = computeOrbit()
	end
	camera.CFrame = camera.CFrame:Lerp(cframe, 0.25)
end

function CameraRig.start(slingshotPosition: Vector3): ()
	focus = slingshotPosition
	smoothedPosition = slingshotPosition
	camera = workspace.CurrentCamera
	camera.CameraType = Enum.CameraType.Scriptable
	RunService:BindToRenderStep("FlockfallCamera", Enum.RenderPriority.Camera.Value + 1, update)

	-- Bos alanda fare surukleme = kamera dondurme.
	local dragging = false
	local lastX = 0
	UserInputService.InputBegan:Connect(function(input, processed)
		if processed then
			return
		end
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			dragging = true
			lastX = input.Position.X
		end
	end)
	UserInputService.InputChanged:Connect(function(input)
		if dragging and input.UserInputType == Enum.UserInputType.MouseMovement then
			orbitAngle -= (input.Position.X - lastX) * 0.01
			lastX = input.Position.X
		end
	end)
	UserInputService.InputEnded:Connect(function(input)
		if input.UserInputType == Enum.UserInputType.MouseButton2 then
			dragging = false
		end
	end)
end

function CameraRig.setFocus(position: Vector3): ()
	focus = position
end

function CameraRig.orbitMode(): ()
	mode = "orbit"
	followTarget = nil
end

function CameraRig.aimMode(): ()
	mode = "aim"
	followTarget = nil
end

function CameraRig.followMode(target: BasePart): ()
	mode = "follow"
	followTarget = target
	smoothedPosition = target.Position
end

function CameraRig.restore(): ()
	RunService:UnbindFromRenderStep("FlockfallCamera")
	if camera ~= nil then
		camera.CameraType = Enum.CameraType.Custom
	end
end

return CameraRig
