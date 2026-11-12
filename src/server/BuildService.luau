--!strict
-- BuildService: seviye verisini gercek Roblox parcalarina cevirir.
--
-- Karar mantigi BuildPlan'dadir (test edilir); burada yalnizca Instance
-- yaratma, materyal/fizik atamasi ve temizlik vardir.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local Config = Shared:WaitForChild("config")
local Core = Shared:WaitForChild("core")

local Materials = require(Config:WaitForChild("Materials"))
local BuildPlan = require(Core:WaitForChild("BuildPlan"))

export type BuiltPiece = { part: BasePart, pieceId: string, material: string, health: number }

export type BuildResult = {
	folder: Folder,
	pieces: { [string]: BuiltPiece },
	targets: { [string]: BuiltPiece },
	props: { [string]: BasePart },
}

local BuildService = {}

-- Malzeme adi -> Roblox materyali.
local ROBLOX_MATERIAL: { [string]: Enum.Material } = {
	Wood = Enum.Material.Wood,
	Glass = Enum.Material.Glass,
	Stone = Enum.Material.Slate,
	Metal = Enum.Material.Metal,
}

-- Yikilabilir govde parcalari ile hedef/kuslarin birbirine takilmamasi icin
-- ayri carpisma gruplari kullanilir.
local function ensureCollisionGroups(): ()
	local PhysicsService = game:GetService("PhysicsService")
	local ok = pcall(function()
		PhysicsService:RegisterCollisionGroup("Structure")
	end)
	pcall(function()
		PhysicsService:RegisterCollisionGroup("Actors")
	end)
	if ok then
		pcall(function()
			PhysicsService:CollisionGroupSetCollidable("Structure", "Actors", true)
		end)
	end
end

local function makeColor(color: { number }): Color3
	return Color3.new(color[1], color[2], color[3])
end

local function buildPiece(entry: BuildPlan.PlanEntry, parent: Instance, group: string): BasePart
	local part = Instance.new("Part")
	part.Name = entry.pieceId
	part.Size = Vector3.new(entry.size.x, entry.size.y, entry.size.z)
	part.CFrame = CFrame.new(entry.position.x, entry.position.y, entry.position.z)
		* CFrame.Angles(
			math.rad(entry.rotation.x),
			math.rad(entry.rotation.y),
			math.rad(entry.rotation.z)
		)
	part.Color = makeColor(entry.color)
	part.Material = ROBLOX_MATERIAL[entry.material] or Enum.Material.SmoothPlastic
	part.Anchored = entry.anchored
	part.TopSurface = Enum.SurfaceType.Smooth
	part.BottomSurface = Enum.SurfaceType.Smooth
	part.CollisionGroup = group
	part:SetAttribute("pieceId", entry.pieceId)
	part:SetAttribute("material", entry.material)
	part:SetAttribute("health", entry.health)
	part.Parent = parent
	return part
end

local function buildTarget(target: any, parent: Instance, group: string): BasePart
	local body = Instance.new("Part")
	body.Name = target.id
	body.Size = Vector3.new(3, 3, 3)
	body.Position = Vector3.new(target.position.x, target.position.y, target.position.z)
	body.Color = Color3.fromRGB(150, 168, 184)
	body.Material = Enum.Material.CorrodedMetal
	body.Anchored = true
	body.CollisionGroup = group
	body:SetAttribute("kind", "Tinhead")
	body:SetAttribute("health", target.health)
	body:SetAttribute("targetId", target.id)
	body.Parent = parent

	-- Tek goz: kasten farkli bir siluet (organik kuslara karsi kose/t metal).
	local eye = Instance.new("Part")
	eye.Name = "eye"
	eye.Shape = Enum.PartType.Ball
	eye.Size = Vector3.new(1.2, 1.2, 1.2)
	eye.Color = Color3.fromRGB(255, 96, 72)
	eye.Material = Enum.Material.Neon
	eye.Anchored = true
	eye.CanCollide = false
	eye.CanTouch = false
	eye.CanQuery = false
	eye.CFrame = body.CFrame * CFrame.new(0, 0.4, -1.5)
	eye.Parent = body

	return body
end

local function buildBarrel(prop: any, parent: Instance, group: string): BasePart
	local barrel = Instance.new("Part")
	barrel.Shape = Enum.PartType.Cylinder
	barrel.Name = prop.id
	barrel.Size = Vector3.new(5, 3, 3)
	barrel.CFrame = CFrame.new(prop.position.x, prop.position.y, prop.position.z)
		* CFrame.Angles(0, 0, math.rad(90))
	barrel.Color = Color3.fromRGB(214, 138, 46)
	barrel.Material = Enum.Material.Metal
	barrel.Anchored = true
	barrel.CollisionGroup = group
	barrel:SetAttribute("kind", "ExplosiveBarrel")
	barrel:SetAttribute("radius", prop.radius)
	barrel:SetAttribute("damage", prop.damage)
	barrel:SetAttribute("impulse", prop.impulse)
	barrel.Parent = parent
	return barrel
end

-- Seviyeyi dunyaya kurar. Onceki yapiyi temizlemek cagiranin isidir.
function BuildService.build(level: any, container: Instance): BuildResult
	ensureCollisionGroups()

	local folder = Instance.new("Folder")
	folder.Name = "Level_" .. level.id
	folder.Parent = container

	local result: BuildResult = {
		folder = folder,
		pieces = {},
		targets = {},
		props = {},
	}

	local plan = BuildPlan.fromLevel(level, Materials.definitions)
	for _, entry in ipairs(plan) do
		local part = buildPiece(entry, folder, "Structure")
		result.pieces[entry.pieceId] = {
			part = part,
			pieceId = entry.pieceId,
			material = entry.material,
			health = entry.health,
		}
	end

	for _, target in ipairs(level.targets) do
		local part = buildTarget(target, folder, "Actors")
		result.targets[target.id] = {
			part = part,
			pieceId = target.id,
			material = "Tinhead",
			health = target.health,
		}
	end

	for _, prop in ipairs(level.props or {}) do
		if prop.kind == "ExplosiveBarrel" then
			result.props[prop.id] = buildBarrel(prop, folder, "Actors")
		end
	end

	return result
end

function BuildService.cleanup(container: Instance): ()
	for _, child in ipairs(container:GetChildren()) do
		child:Destroy()
	end
end

return BuildService
