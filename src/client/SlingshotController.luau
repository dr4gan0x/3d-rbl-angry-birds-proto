--!strict
-- SlingshotController: 3D nisan alma girdisi.
--
-- Tek surukleme, uc kontrol:
--   yatay  -> yaw      (soldan cekersen saga ucar)
--   dikey  -> pitch    (asagi cekersen yukari ucar)
--   mesafe -> guc
--
-- ContextActionService kullanilir: ayni kod fare, dokunma ve gamepad'i baglar.
-- Karar mantigi AimModel'de (test edilir); burada yalnizca ekran -> dunya
-- cevirisi ve gorsel geri bildirim vardir.

local ContextActionService = game:GetService("ContextActionService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("config")
local Core = Shared:WaitForChild("core")

local GameConfig = require(Config:WaitForChild("GameConfig"))
local AimModel = require(Core:WaitForChild("AimModel"))

local CameraRig = require(script.Parent:WaitForChild("CameraRig"))
local TrajectoryPreview = require(script.Parent:WaitForChild("TrajectoryPreview"))

local SlingshotController = {}

local remotes: any = nil
local enabled = false
local dragging = false
local slingshotOrigin = Vector3.new(0, 6, 0)
local marker: Part? = nil
local lastPreviewAt = 0

local function ensureMarker(): Part
	if marker ~= nil and marker.Parent ~= nil then
		return marker :: Part
	end
	local part = Instance.new("Part")
	part.Name = "FlockfallAimMarker"
	part.Shape = Enum.PartType.Ball
	part.Size = Vector3.new(1.1, 1.1, 1.1)
	part.Color = Color3.fromRGB(255, 236, 180)
	part.Material = Enum.Material.Neon
	part.Anchored = true
	part.CanCollide = false
	part.CanTouch = false
	part.CanQuery = false
	part.Transparency = 1
	part.Parent = workspace
	marker = part
	return part
end

-- Ekran noktasini sapandan gecen dunya duzlemine izduser.
-- Kameranin baktigi yon ile sapan arasindaki duzlem kullanilir: boylece
-- oyuncu kamerayi cevirdiginde cekme yonu sezgisel kalir.
local function screenToPull(screenPosition: Vector2): Vector3
	local camera = workspace.CurrentCamera
	local ray = camera:ViewportPointToRay(screenPosition.X, screenPosition.Y)
	local planeNormal = camera.CFrame.LookVector
	local denominator = planeNormal:Dot(ray.Direction)
	if math.abs(denominator) < 1e-4 then
		return Vector3.new(0, 0, 0)
	end
	local t = planeNormal:Dot(slingshotOrigin - ray.Origin) / denominator
	if t < 0 then
		return Vector3.new(0, 0, 0)
	end
	local hit = ray.Origin + ray.Direction * t
	return hit - slingshotOrigin
end

local function updatePreview(pull: Vector3): ()
	local result = AimModel.evaluate({ x = pull.X, y = pull.Y, z = pull.Z }, GameConfig)
	local dot = ensureMarker()

	if not result.accepted then
		dot.Transparency = 1
		TrajectoryPreview.hide()
		return
	end

	dot.CFrame = CFrame.new(slingshotOrigin - pull)
	dot.Transparency = 0.35

	-- Onizlemeyi her karede degil ~30 Hz guncelle: mobilde CPU tasarrufu.
	local now = os.clock()
	if now - lastPreviewAt < 0.033 then
		return
	end
	lastPreviewAt = now
	TrajectoryPreview.show(
		slingshotOrigin,
		Vector3.new(result.velocity.x, result.velocity.y, result.velocity.z)
	)
end

local function clearAim(): ()
	dragging = false
	TrajectoryPreview.hide()
	if marker ~= nil then
		marker.Transparency = 1
	end
end

local function onInput(
	_actionName: string,
	inputState: Enum.UserInputState,
	inputObject: InputObject
)
	if not enabled then
		return Enum.ContextActionResult.Pass
	end

	if inputState == Enum.UserInputState.Begin then
		dragging = true
		CameraRig.aimMode()
		updatePreview(screenToPull(inputObject.Position))
		return Enum.ContextActionResult.Sink
	elseif inputState == Enum.UserInputState.Change then
		if dragging then
			updatePreview(screenToPull(inputObject.Position))
			return Enum.ContextActionResult.Sink
		end
		return Enum.ContextActionResult.Pass
	elseif inputState == Enum.UserInputState.End then
		if not dragging then
			return Enum.ContextActionResult.Pass
		end
		local pull = screenToPull(inputObject.Position)
		clearAim()

		local result = AimModel.evaluate({ x = pull.X, y = pull.Y, z = pull.Z }, GameConfig)
		if result.accepted and remotes ~= nil then
			remotes.FireRequest:FireServer(result.power, result.yaw, result.pitch)
		end
		CameraRig.orbitMode()
		return Enum.ContextActionResult.Sink
	end

	return Enum.ContextActionResult.Pass
end

function SlingshotController.start(remoteSet: any, level: any): ()
	remotes = remoteSet
	slingshotOrigin = Vector3.new(
		level.slingshot.position.x,
		level.slingshot.position.y,
		level.slingshot.position.z
	)
	CameraRig.setFocus(slingshotOrigin)

	ContextActionService:BindAction(
		"FlockfallAim",
		onInput,
		false,
		Enum.UserInputType.MouseButton1,
		Enum.UserInputType.Touch,
		Enum.KeyCode.ButtonA
	)
	enabled = true
end

function SlingshotController.setEnabled(value: boolean): ()
	enabled = value
	if not value then
		clearAim()
	end
end

function SlingshotController.setLevel(level: any): ()
	slingshotOrigin = Vector3.new(
		level.slingshot.position.x,
		level.slingshot.position.y,
		level.slingshot.position.z
	)
	CameraRig.setFocus(slingshotOrigin)
end

function SlingshotController.slingshotPosition(): Vector3
	return slingshotOrigin
end

function SlingshotController.stop(): ()
	ContextActionService:UnbindAction("FlockfallAim")
	clearAim()
end

return SlingshotController
