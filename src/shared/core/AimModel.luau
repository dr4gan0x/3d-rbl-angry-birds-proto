--!strict
-- AimModel: tek suruklemeden 3 serbestlik derecesi uretir.
--
--   yatay cekme   -> yaw    (soldan cekersen saga ucar)
--   dikey cekme   -> pitch  (asagi cekersen yukari ucar)
--   cekme mesafesi -> guc
--
-- Konfigurasyon PARAMETRE olarak gelir (dependency injection): core katmaninda
-- `script` ve `require` yoktur, bu yuzden modul kendi config'ini yukleyemez.

export type Vec3 = { x: number, y: number, z: number }

export type AimConfig = {
	DEAD_ZONE: number,
	MIN_POWER: number,
	MAX_PULL: number,
	MAX_SPEED: number,
}

export type AimResult = {
	accepted: boolean,
	reason: string?,
	power: number,
	yaw: number,
	pitch: number,
	velocity: Vec3,
}

local AimModel = {}

-- Hiz vektorunden (yaw, pitch) cikarir. Sifir hizda (0, 0).
function AimModel.aimAngles(velocity: Vec3): (number, number)
	local magnitude =
		math.sqrt(velocity.x * velocity.x + velocity.y * velocity.y + velocity.z * velocity.z)
	if magnitude == 0 then
		return 0, 0
	end
	local yaw = math.atan2(velocity.x, velocity.z)
	local pitch = math.asin(math.clamp(velocity.y / magnitude, -1, 1))
	return yaw, pitch
end

-- Cekme vektorunu atisa cevirir. Reddederse `accepted = false` ve `reason` doner.
function AimModel.evaluate(pull: Vec3, config: AimConfig): AimResult
	local magnitude = math.sqrt(pull.x * pull.x + pull.y * pull.y + pull.z * pull.z)

	if magnitude < config.DEAD_ZONE then
		return {
			accepted = false,
			reason = "dead_zone",
			power = 0,
			yaw = 0,
			pitch = 0,
			velocity = { x = 0, y = 0, z = 0 },
		}
	end

	local power = math.clamp(magnitude / config.MAX_PULL, 0, 1)

	if power < config.MIN_POWER then
		return {
			accepted = false,
			reason = "too_weak",
			power = power,
			yaw = 0,
			pitch = 0,
			velocity = { x = 0, y = 0, z = 0 },
		}
	end

	local speed = power * config.MAX_SPEED
	local velocity = {
		x = -(pull.x / magnitude) * speed,
		y = -(pull.y / magnitude) * speed,
		z = -(pull.z / magnitude) * speed,
	}

	local yaw, pitch = AimModel.aimAngles(velocity)
	return {
		accepted = true,
		power = power,
		yaw = yaw,
		pitch = pitch,
		velocity = velocity,
	}
end

return AimModel
