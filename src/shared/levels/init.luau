--!strict
-- Seviye sirasi. `register` deseni sayesinde bu dosya `script.Parent` kullanmaz
-- (core/ katmani degil ama test kosucusu da ayni modulu yukleyebilsin diye).

local Levels = {}

local ordered: { any } = {}

function Levels.register(level: any): ()
	table.insert(ordered, level)
end

function Levels.list(): { any }
	return ordered
end

function Levels.get(id: string): any?
	for _, level in ipairs(ordered) do
		if level.id == id then
			return level
		end
	end
	return nil
end

return Levels
