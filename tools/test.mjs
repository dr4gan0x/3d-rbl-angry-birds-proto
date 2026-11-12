// Luau test kosucusu.
//
// src/shared/**/*.luau dosyalarini ada gore bir modul kayit defterine, tests/**
// /*.spec.luau dosyalarini sirayla calistirilan spec kuyruguna cevirir ve
// hepsini TEK bir Luau chunk'i olarak WASM VM'de kosturur.
//
// Neden tek chunk: bu VM'de `loadstring` ve `require` yok; moduller ancak
// kayit defteri + kendi `require` shim'imizle yuklenebilir.

import { Lua } from "@luau-rs/luau";
import fs from "node:fs";
import path from "node:path";

const ROOT = process.cwd();
const MODULE_ROOT = "src/shared";
const SPEC_ROOT = "tests";
const filter = process.argv[2] ?? null;

function walk(dir, out = []) {
	if (!fs.existsSync(dir)) return out;
	for (const entry of fs.readdirSync(dir, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
		const full = path.join(dir, entry.name);
		if (entry.isDirectory()) walk(full, out);
		else if (full.endsWith(".luau")) out.push(full);
	}
	return out;
}

const moduleFiles = walk(path.join(ROOT, MODULE_ROOT));
const specFiles = walk(path.join(ROOT, SPEC_ROOT)).filter((file) => file.endsWith(".spec.luau"));

// Modul kayit defteri. `levels/init.luau` "init" adiyla kaydolur; baska bir
// klasordeki init.luau cakisma yaratacagi icin atlanir.
const registry = new Map();
for (const file of moduleFiles) {
	const name = path.basename(file, ".luau");
	const isLevelsInit = name === "init" && file.includes(path.join("shared", "levels"));
	if (name === "init" && !isLevelsInit) continue;
	if (registry.has(name)) {
		console.error(`HATA: ayni ada iki modul var: ${name}`);
		console.error(`  ${registry.get(name)}`);
		console.error(`  ${file}`);
		process.exit(1);
	}
	registry.set(name, file);
}

const selected = filter ? specFiles.filter((file) => file.includes(filter)) : specFiles;
if (selected.length === 0) {
	console.error("HATA: calistirilacak spec bulunamadi");
	process.exit(1);
}

const chunks = [];
chunks.push(`local __modules, __cache, __specs = {}, {}, {}`);
chunks.push(`
local function __require(name)
	local cached = __cache[name]
	if cached ~= nil then return cached end
	local factory = __modules[name]
	if factory == nil then error("modul bulunamadi: " .. tostring(name), 2) end
	local value = factory()
	__cache[name] = value
	return value
end
`);

for (const [name, file] of registry) {
	const source = fs.readFileSync(file, "utf8").replace(/^--!strict\s*$/m, "");
	chunks.push(`__modules[${JSON.stringify(name)}] = function()\n${source}\nend`);
}

chunks.push(`
local T = {}
function T.require(name) return __require(name) end

-- Enjeksiyon yardimcisi: Materials modulu .definitions tablosu dondurur,
-- digerleri modulun kendisini dondurur.
function T.config(name)
	local mod = __require(name)
	if name == "Materials" then return mod.definitions end
	return mod
end

-- levels/init.luau sirasi kendisi tutar; seviyeleri burada kaydediyoruz.
do
	local hasLevels = __modules["init"] ~= nil
	local levels = hasLevels and __require("init") or nil
	if levels ~= nil and levels.register ~= nil then
		for _, levelName in ipairs({ "Level01", "Level02", "Level03" }) do
			if __modules[levelName] ~= nil then
				levels.register(__require(levelName))
			end
		end
		__cache["Levels"] = levels
	end
end

local __suites, __current = {}, nil

function T.describe(name, fn)
	local suite = { name = name, tests = {} }
	table.insert(__suites, suite)
	local previous = __current
	__current = suite
	fn()
	__current = previous
end

function T.it(name, fn)
	if __current == nil then error("it() describe() icinde cagrilmali") end
	table.insert(__current.tests, { name = name, fn = fn })
end

local function __deepEqual(a, b)
	if a == b then return true end
	if type(a) ~= "table" or type(b) ~= "table" then return false end
	for key, value in pairs(a) do
		if not __deepEqual(value, b[key]) then return false end
	end
	for key in pairs(b) do
		if a[key] == nil then return false end
	end
	return true
end

-- Metotlar (self, expected) imzasi alir: expect(x):toBe(y) kolon sozdizimidir.
function T.expect(value)
	local api = {}

	function api.toBe(_, expected)
		if value ~= expected then
			error(string.format("beklenen %s, gelen %s", tostring(expected), tostring(value)), 2)
		end
	end

	function api.toBeCloseTo(_, expected, epsilon)
		local eps = epsilon or 1e-6
		if type(value) ~= "number" then
			error("sayi bekleniyordu, gelen " .. type(value), 2)
		end
		if math.abs(value - expected) > eps then
			error(string.format("beklenen ~%s, gelen %s", tostring(expected), tostring(value)), 2)
		end
	end

	function api.toBeTrue(_)
		if value ~= true then
			error("beklenen true, gelen " .. tostring(value), 2)
		end
	end

	function api.toBeFalse(_)
		if value ~= false then
			error("beklenen false, gelen " .. tostring(value), 2)
		end
	end

	function api.toEqual(_, expected)
		if not __deepEqual(value, expected) then
			error("tablolar esit degil", 2)
		end
	end

	function api.toThrow(_)
		if pcall(value) then
			error("hata bekleniyordu ama hata olmadi", 2)
		end
	end

	return api
end

function T.run()
	local pass, fail = 0, 0
	local failures = {}
	for _, suite in ipairs(__suites) do
		for _, test in ipairs(suite.tests) do
			local ok, err = pcall(test.fn)
			if ok then
				pass += 1
			else
				fail += 1
				table.insert(failures, suite.name .. " > " .. test.name .. ": " .. tostring(err))
			end
		end
	end
	return pass, fail, failures
end
`);

for (const file of selected) {
	const source = fs.readFileSync(file, "utf8");
	chunks.push(`__specs[#__specs + 1] = (function()\n${source}\nend)()`);
}

chunks.push(`
for _, spec in ipairs(__specs) do
	if type(spec) ~= "function" then
		error("spec bir fonksiyon dondurmeli (return function(T) ... end)")
	end
	spec(T)
end
local pass, fail, failures = T.run()
local lines = { string.format("PASS %d FAIL %d", pass, fail) }
for _, message in ipairs(failures) do
	table.insert(lines, "  x " .. message)
end
return table.concat(lines, "\\n")
`);

const lua = await Lua.create({ sandbox: true });
let report;
try {
	report = lua.execute(chunks.join("\n\n"));
} catch (err) {
	const message = String(err.message ?? err).split("\n").slice(0, 8).join("\n");
	console.error(message);
	process.exit(1);
}

const text = String(report[0]);
console.log(text);
const passing = /FAIL 0\b/.test(text) && !/FAIL [1-9]/.test(text);
process.exit(passing ? 0 : 1);
