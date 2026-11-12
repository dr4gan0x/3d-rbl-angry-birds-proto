--!strict
-- Trajectory: nisan alma sirasinda gosterilen yorunge onizlemesi.
--
-- Ayni formul Kinematics.positionAt ile ayni olmalidir; aksi halde oyuncu
-- "onizleme yalan soyledi" der. Kinematics'ten bagimsiz hesaplanir cunku
-- core katmaninda require yoktur — iki dosya ayni denklemi kullanir.

export type Vec3 = { x: number, y: number, z: number }

local Trajectory = {}

-- Baslangictan itibaren `steps` nokta; ilk nokta t = 0 (y = 0).
function Trajectory.sample(velocity: Vec3, gravity: number, steps: number, dt: number): { Vec3 }
	local points: { Vec3 } = {}
	for i = 1, steps do
		local t = (i - 1) * dt
		table.insert(points, {
			x = velocity.x * t,
			y = velocity.y * t - 0.5 * gravity * t * t,
			z = velocity.z * t,
		})
	end
	return points
end

-- Yorungenin tepe noktasi. Asagi yonlu hizda (0, 0, 0).
function Trajectory.apex(velocity: Vec3, gravity: number): Vec3
	if velocity.y <= 0 then
		return { x = 0, y = 0, z = 0 }
	end
	local t = velocity.y / gravity
	return {
		x = velocity.x * t,
		y = velocity.y * t - 0.5 * gravity * t * t,
		z = velocity.z * t,
	}
end

return Trajectory
