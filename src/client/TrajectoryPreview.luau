--!strict
-- TrajectoryPreview: nisan alma sirasinda nokta nokta yorunge gosterir.
--
-- Parcalar havuzlanir (pool): her karede Instance.new cagirmak yerine ayni
-- 24 parcayi tasiriz. Parcalar CanCollide/CanTouch/CanQuery kapali — fizige
-- ve raycast'e hic dokunmaz.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("config")
local Core = Shared:WaitForChild("core")

local GameConfig = require(Config:WaitForChild("GameConfig"))
local Trajectory = require(Core:WaitForChild("Trajectory"))

local POINT_COUNT = 24
local STEP_SECONDS = 0.08

local TrajectoryPreview = {}

local folder: Folder? = nil
local pool: { BasePart } = {}
local visible = false

local function ensurePool(): ()
	if folder ~= nil then
		return
	end
	local newFolder = Instance.new("Folder")
	newFolder.Name = "FlockfallTrajectory"
	newFolder.Parent = workspace
	folder = newFolder

	for _ = 1, POINT_COUNT do
		local dot = Instance.new("Part")
		dot.Shape = Enum.PartType.Ball
		dot.Size = Vector3.new(0.45, 0.45, 0.45)
		dot.Color = Color3.fromRGB(255, 248, 220)
		dot.Material = Enum.Material.Neon
		dot.Anchored = true
		dot.CanCollide = false
		dot.CanTouch = false
		dot.CanQuery = false
		dot.Transparency = 1
		dot.Parent = folder
		table.insert(pool, dot)
	end
end

function TrajectoryPreview.show(origin: Vector3, velocity: Vector3): ()
	ensurePool()
	visible = true

	local points = Trajectory.sample(
		{ x = velocity.X, y = velocity.Y, z = velocity.Z },
		GameConfig.GRAVITY,
		POINT_COUNT,
		STEP_SECONDS
	)

	for index, dot in ipairs(pool) do
		local point = points[index]
		local distance = Vector3.new(point.x, point.y, point.z).Magnitude
		-- Uzadikca soluklas: yorungenin nerede bittigini okumak kolaylasir.
		if distance > GameConfig.MAX_RANGE or point.y < -60 then
			dot.Transparency = 1
		else
			dot.CFrame = CFrame.new(origin.X + point.x, origin.Y + point.y, origin.Z + point.z)
			dot.Transparency = math.clamp(0.1 + distance / 400, 0.1, 0.75)
		end
	end
end

function TrajectoryPreview.hide(): ()
	visible = false
	for _, dot in ipairs(pool) do
		dot.Transparency = 1
	end
end

function TrajectoryPreview.isVisible(): boolean
	return visible
end

return TrajectoryPreview
