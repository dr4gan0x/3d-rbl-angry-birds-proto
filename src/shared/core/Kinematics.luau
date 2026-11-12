--!strict
-- Kinematics: saf yorunge matematiği.
--
-- Roblox API'si YOKTUR (Vector3 de yok). Vektorler duz {x, y, z} tablolaridir;
-- Roblox katmani sinirda Vector3'e cevirir. Bu sayede modul Luau VM'inde
-- Roblox olmadan test edilebilir.

export type Vec3 = { x: number, y: number, z: number }

local Kinematics = {}

function Kinematics.vec(x: number, y: number, z: number): Vec3
	return { x = x, y = y, z = z }
end

function Kinematics.add(a: Vec3, b: Vec3): Vec3
	return { x = a.x + b.x, y = a.y + b.y, z = a.z + b.z }
end

function Kinematics.scale(a: Vec3, factor: number): Vec3
	return { x = a.x * factor, y = a.y * factor, z = a.z * factor }
end

function Kinematics.magnitude(a: Vec3): number
	return math.sqrt(a.x * a.x + a.y * a.y + a.z * a.z)
end

-- Firlatma hizi: yaw etrafinda donen, pitch ile yukselen birim vektor * hiz.
-- power 0..1 araligina kirpilir; maxSpeed stud/sn cinsindendir.
function Kinematics.launchVelocity(
	power: number,
	yawRad: number,
	pitchRad: number,
	maxSpeed: number
): Vec3
	local speed = math.clamp(power, 0, 1) * maxSpeed
	local horizontal = math.cos(pitchRad) * speed
	return {
		x = horizontal * math.sin(yawRad),
		y = speed * math.sin(pitchRad),
		z = horizontal * math.cos(yawRad),
	}
end

-- Baslangic y = 0 kabuluyle t anindaki konum.
function Kinematics.positionAt(v: Vec3, t: number, gravity: number): Vec3
	return {
		x = v.x * t,
		y = v.y * t - 0.5 * gravity * t * t,
		z = v.z * t,
	}
end

function Kinematics.speedAt(v: Vec3, t: number, gravity: number): number
	local vy = v.y - gravity * t
	return math.sqrt(v.x * v.x + vy * vy + v.z * v.z)
end

-- Yukari dogru atilmis cismin y = 0'a donus suresi. Asagi yonlu hizda 0.
function Kinematics.flightTime(v: Vec3, gravity: number): number
	if v.y <= 0 then
		return 0
	end
	return 2 * v.y / gravity
end

-- Semi-implicit Euler hiz adimi. Konum guncellemesi cagiranin isidir; bu ayrim
-- ozellik testinde dogrulanir.
function Kinematics.step(v: Vec3, dt: number, gravity: number): Vec3
	return { x = v.x, y = v.y - gravity * dt, z = v.z }
end

return Kinematics
