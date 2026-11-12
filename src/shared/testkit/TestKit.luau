--!strict
-- TestKit: saf Luau test API'si.
--
-- Bu modul Roblox icinde (bir Script'ten) calisir; CI'daki ayni API
-- tools/test.mjs icinde gomulu olarak durur. Iki kopyanin davranisi
-- ayni olmalidir, aksi halde Studio ile CI farkli sonuc verir.

export type Failure = string
export type TestFn = () -> ()
export type Suite = { name: string, tests: { { name: string, fn: TestFn } } }
export type Expect = {
	toBe: (any, any) -> (),
	toBeCloseTo: (any, number, number?) -> (),
	toBeTrue: (any) -> (),
	toBeFalse: (any) -> (),
	toEqual: (any, any) -> (),
	toThrow: (any) -> (),
}

local TestKit = {}

local suites: { Suite } = {}
local current: Suite? = nil

function TestKit.describe(name: string, fn: TestFn): ()
	local suite: Suite = { name = name, tests = {} }
	table.insert(suites, suite)
	local previous = current
	current = suite
	fn()
	current = previous
end

function TestKit.it(name: string, fn: TestFn): ()
	assert(current ~= nil, "it() describe() icinde cagrilmali")
	table.insert((current :: Suite).tests, { name = name, fn = fn })
end

local function deepEqual(a: any, b: any): boolean
	if a == b then
		return true
	end
	if type(a) ~= "table" or type(b) ~= "table" then
		return false
	end
	for key, value in pairs(a) do
		if not deepEqual(value, b[key]) then
			return false
		end
	end
	for key in pairs(b) do
		if a[key] == nil then
			return false
		end
	end
	return true
end

-- Metotlar (self, expected) imzasi alir: expect(x):toBe(y) kolon sozdizimidir.
function TestKit.expect(value: any): Expect
	local api = {}

	function api.toBe(_self: any, expected: any): ()
		if value ~= expected then
			error(string.format("beklenen %s, gelen %s", tostring(expected), tostring(value)), 2)
		end
	end

	function api.toBeCloseTo(_self: any, expected: number, epsilon: number?): ()
		local eps = epsilon or 1e-6
		if type(value) ~= "number" then
			error("sayi bekleniyordu, gelen " .. type(value), 2)
		end
		if math.abs(value - expected) > eps then
			error(string.format("beklenen ~%s, gelen %s", tostring(expected), tostring(value)), 2)
		end
	end

	function api.toBeTrue(_self: any): ()
		if value ~= true then
			error("beklenen true, gelen " .. tostring(value), 2)
		end
	end

	function api.toBeFalse(_self: any): ()
		if value ~= false then
			error("beklenen false, gelen " .. tostring(value), 2)
		end
	end

	function api.toEqual(_self: any, expected: any): ()
		if not deepEqual(value, expected) then
			error("tablolar esit degil", 2)
		end
	end

	function api.toThrow(_self: any): ()
		if pcall(value) then
			error("hata bekleniyordu ama hata olmadi", 2)
		end
	end

	return api :: Expect
end

function TestKit.run(): (number, number, { Failure })
	local pass, fail = 0, 0
	local failures: { Failure } = {}
	for _, suite in ipairs(suites) do
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

return TestKit
