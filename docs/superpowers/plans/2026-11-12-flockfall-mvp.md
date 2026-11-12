# Flockfall — 3D Sapan Prototipi Uygulama Planı

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Roblox'ta çalışan, 3 seviyeli, 3D sapan fizik oyunu prototipi — tamamen özgün IP ve prosedürel varlıklarla.

**Architecture:** Saf Luau "core" modülleri (Roblox API'siz, CI'da test edilir) + ince Roblox katmanları (sunucu yetkili fizik, istemci giriş/kamera/HUD). Tüm oyun matematiği `src/shared/core/*` içinde düz `{x,y,z}` tablolarıyla yaşar; `Vector3`'e dönüşüm yalnızca sınırda yapılır.

**Tech Stack:** Luau (`--!strict`), Rojo 7.x proje eşlemesi, StyLua 2.6, Node.js 22 + `@luau-rs/luau` 0.739 (WASM Luau) test koşucusu. Sıfır dış Luau paketi.

> **Bu ortamda doğrulandı (2026-11-12):** `npm i @luau-rs/luau@0.739.0` çalışır; VM'de Luau 0.739 koşar (`math.round`, `math.clamp`, `table.find` mevcut). `@johnnymorganz/stylua-bin` 2.6.0 çalışır. Rojo/Lune **binary'leri indirilemez** (release-assets host'u engelli) — bu yüzden plan `rojo build` adımı içermez; Studio eşlemesi kullanıcı tarafında yapılır.

**Spec:** `docs/superpowers/specs/2026-11-12-flockfall-3d-slingshot-design.md`

## Global Constraints

- Luau `--!strict`; kök `.luaurc` içinde `"languageMode": "strict"`.
- `src/shared/core/*` dosyalarında Roblox globali yasak: `game`, `workspace`, `Instance`, `Vector3`, `CFrame`, `task`, `wait`, `tick`, `warn`, **`script`**. Yalnızca saf Luau (`math`, `table`, `string`, `ipairs`, `pcall`, `error`, `assert`) kullanılır.
- **Katman kuralı:** `script.Parent` / `require` yasağı yalnızca `src/shared/core/**` içindir; `src/server/**` ve `src/client/**` normal Roblox modülleridir ve `require(script.Parent.X)` kullanır.
- **Bağımlılık kuralı:** core modüller birbirini `require(script.Parent...)` ile **çağıramaz** (`script` yasak). Konfigürasyon ve malzeme tabloları **parametre olarak enjekte edilir** (dependency injection). Örnek: `AimModel.evaluate(pull, config)`; `DamageModel.impactDamage(speed, mass, material, materials)`.
- Dış Luau paketi yok. `package.json` yalnızca `devDependencies` içerir.
- Yerçekimi sabiti: `196.2` stud/s².
- `MAX_SPEED = 260` stud/s, `MAX_PULL = 8` stud, `DEAD_ZONE = 0.75` stud, `MIN_POWER = 0.12`.
- Malzeme çarpanları: Wood `1.0`, Glass `2.0`, Stone `0.65`, Metal `0` (kırılmaz).
- Yorumlar ve dokümanlar Türkçe; tanımlayıcılar İngilizce.
- Her görev `stylua --check src tests tools` temiz ve `node tools/test.mjs` yeşilken biter.
- Yasaklı IP (spec §1.2): "Angry Birds", "Rovio", Red/Chuck/Bomb/Matilda/Hal/Terence/Bubbles/Stella/Silver/Leonard ve domuz karakter adları kodda, yorumda veya varlık adında geçmez.
- Her görev kendi commit'i ile biter.

## Review Focus

1. **Sıfır güçte atış** — oyuncu kuşu hiç çekmeden bırakır; kuş sapanın dibine düşüp oyuncuyu bir kuş kaybettirmemeli, atış sessizce iptal edilmeli (Task 3).
2. **Ölü bölge sınırı** — parmak titremesiyle 0.5 stud'luk çekme atış sayılmamalı (Task 3).
3. **Metal parçaya hasar** — Metal `health = math.huge` taşır; hasar hesabı `0` dönmeli, `math.huge` ile aritmetik NaN üretmemeli (Task 4).
4. **Son kuşla son hedefin aynı karede ölmesi** — hem `won` hem `lost` koşulu sağlanırsa sonuç `won` olmalı (Task 7).
5. **Bilinmeyen kuş tipi / malzeme** — seviye verisi bozuksa `LevelSchema.validate` hata döndürmeli, oyun çökmemeli (Task 6).

> **Yazarken doğrulandi (2026-11-12):** Core modülde `require(script.Parent...)` kullanmak, `script` yasak olduğu için Luau VM'inde `attempt to index nil with 'Parent'` verir. Bu yuzden config/materials **parametre** olarak gecer. Task 3 ve 4'un spec'leri bunu zaten bu sekilde yazar; degistirmeyin.

---

### Task 1: Test altyapısı (koşucu + TestKit)

**Files:**
- Create: `package.json`, `.luaurc`, `stylua.toml`, `.gitignore`
- Create: `tools/test.mjs`, `src/shared/testkit/TestKit.luau`
- Test: `tests/Smoke.spec.luau`

**Interfaces:**
- Consumes: yok.
- Produces:
  - `node tools/test.mjs [filtre]` → çıkış kodu `0` (hepsi geçti) / `1` (hata veya hiç test yok). Çıktı: `PASS <n> FAIL <m>`.
  - Her spec dosyası şu şekli **döndürür**: `return function(T) ... end`.
  - `TestKit.luau` → tablo: `require(name)`, `describe(name, fn)`, `it(name, fn)`, `expect(value)`, `run() -> pass, fail, failures`.

- [ ] **Step 1: Write the failing test**

`tests/Smoke.spec.luau`:

```lua
return function(T)
	T.describe("TestKit", function()
		T.it("matematik calisiyor", function()
			T.expect(1 + 1):toBe(2)
		end)

		T.it("yaklasik esitlik tolerans icinde", function()
			T.expect(0.1 + 0.2):toBeCloseTo(0.3, 1e-9)
		end)

		T.it("yanlis deger yakalanir", function()
			T.expect(2):toBe(3)
		end)
	end)
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node tools/test.mjs`
Expected: FAIL — `Cannot find module .../tools/test.mjs`

- [ ] **Step 3: Implement the toolchain files**

`.gitignore`:
```
node_modules/
*.rbxl
*.rbxlx
*.rbxm
*.rbxmx
sourcemap.json
.superpowers/
```

`.luaurc`:
```json
{ "languageMode": "strict", "globals": ["Roblox"] }
```

`stylua.toml` (spec §6 biçim kuralları):
```toml
column_width = 100
line_endings = "Unix"
indent_type = "Tabs"
indent_width = 4
quote_style = "AutoPreferDouble"
call_parentheses = "Always"
```

`package.json`:
```json
{
  "name": "flockfall",
  "private": true,
  "type": "module",
  "scripts": {
    "test": "node tools/test.mjs",
    "fmt": "stylua src tests tools"
  },
  "devDependencies": {
    "@johnnymorganz/stylua-bin": "2.6.0",
    "@luau-rs/luau": "0.739.0"
  }
}
```

- [ ] **Step 4: Implement `TestKit.luau`**

Bu modül, saf mantık testlerinin ihtiyaç duyduğu **en küçük** API'dir. Tam gövde yerine davranış sözleşmesi:

| Fonksiyon | Davranış |
|---|---|
| `describe(name, fn)` | Yeni suite açar, `fn`'i hemen çalıştırır, içindeki `it` çağrılarını toplar |
| `it(name, fn)` | Testi suite'e ekler (çalıştırmaz). `describe` dışında çağrılırsa `assert` hatası |
| `expect(v):toBe(x)` | `v ~= x` ise `"beklenen <x>, gelen <v>"` hatası |
| `expect(v):toBeCloseTo(x, eps)` | `|v-x| > (eps or 1e-6)` ise hata; `v` sayı değilse `"sayi bekleniyordu..."` |
| `expect(v):toBeTrue/toBeFalse()` | Katı `== true` / `== false` |
| `expect(v):toEqual(x)` | Derin tablo eşitliği (anahtar sayısı dahil) |
| `expect(fn):toThrow()` | `pcall` ile hata **bekler**; hata yoksa testi patlatır |
| `run()` | Tüm testleri `pcall` ile koşar, `pass, fail, failures` döndürür |

> **Kritik (bu ortamda doğrulandı):** `expect(x):toBe(y)` kolon sözdizimidir; metotlar `function(self, expected)` imzası almalıdır. `function(expected)` yazılırsa Luau "attempt to perform arithmetic (sub) on number and table" verir. `toBeCloseTo` içinde `type(value) ~= "number"` kontrolü ayrıca yapılmalıdır.

`TestKit.luau`'nun `run()` + metot gövdeleri, Step 5'teki koşucunun içindeki `T` tablosuyla **birebir aynı** olmalıdır; iki kopya arasında davranış farkı olursa Studio ile CI farklı sonuç verir.

**Step 5: Implement `tools/test.mjs`**

Approach: `src/shared/**/*.luau` dosyalarını ada göre kayıt defterine, `tests/**/*.spec.luau` dosyalarını sırayla çalıştırılan spec kuyruğuna çevir; hepsini **tek Luau chunk'ı** olarak WASM VM'de koştur. `loadstring` ve `require` bu VM'de yok — bu yüzden registry zorunlu. Modül adı çakışırsa hata ver.

```js
import { Lua } from "@luau-rs/luau";
import fs from "node:fs";
import path from "node:path";

const ROOT = process.cwd();
const MODULE_ROOT = "src/shared";
const SPEC_ROOT = "tests";
const filter = process.argv[2] ?? null;

function walk(dir, out = []) {
	if (!fs.existsSync(dir)) return out;
	for (const e of fs.readdirSync(dir, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
		const p = path.join(dir, e.name);
		if (e.isDirectory()) walk(p, out);
		else if (p.endsWith(".luau")) out.push(p);
	}
	return out;
}

const moduleFiles = walk(path.join(ROOT, MODULE_ROOT));
const specFiles = walk(path.join(ROOT, SPEC_ROOT)).filter((f) => f.endsWith(".spec.luau"));

const registry = new Map();
for (const file of moduleFiles) {
	const name = path.basename(file, ".luau");
	if (name === "init" && !file.includes("levels")) continue;
	if (registry.has(name)) {
		console.error(`HATA: ayni ada iki modul var: ${name} (${registry.get(name)} ve ${file})`);
		process.exit(1);
	}
	registry.set(name, file);
}

const selected = filter ? specFiles.filter((f) => f.includes(filter)) : specFiles;
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
	const src = fs.readFileSync(file, "utf8").replace(/^--!strict\s*$/m, "");
	chunks.push(`__modules[${JSON.stringify(name)}] = function()\n${src}\nend`);
}
chunks.push(`
local T = {}
function T.require(name) return __require(name) end
function T.config(name)
	local mod = __require(name)
	if name == "Materials" then return mod.definitions end
	return mod
end
do
	local levels = __require("init")
	if levels.register ~= nil then
		for _, n in ipairs({ "Level01", "Level02", "Level03" }) do
			if __modules[n] ~= nil then levels.register(__require(n)) end
		end
	end
	__cache["Levels"] = levels
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
	for k, v in pairs(a) do if not __deepEqual(v, b[k]) then return false end end
	for k in pairs(b) do if a[k] == nil then return false end end
	return true
end
function T.expect(value)
	local api = {}
	function api.toBe(_, expected)
		if value ~= expected then error(string.format("beklenen %s, gelen %s", tostring(expected), tostring(value)), 2) end
	end
	function api.toBeCloseTo(_, expected, epsilon)
		local eps = epsilon or 1e-6
		if type(value) ~= "number" then error("sayi bekleniyordu, gelen " .. type(value), 2) end
		if math.abs(value - expected) > eps then
			error(string.format("beklenen ~%s, gelen %s", tostring(expected), tostring(value)), 2)
		end
	end
	function api.toBeTrue(_)
		if value ~= true then error("beklenen true, gelen " .. tostring(value), 2) end
	end
	function api.toBeFalse(_)
		if value ~= false then error("beklenen false, gelen " .. tostring(value), 2) end
	end
	function api.toEqual(_, expected)
		if not __deepEqual(value, expected) then error("tablolar esit degil", 2) end
	end
	function api.toThrow(_)
		if pcall(value) then error("hata bekleniyordu ama hata olmadi", 2) end
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
	const src = fs.readFileSync(file, "utf8");
	chunks.push(`__specs[#__specs + 1] = (function()\n${src}\nend)()`);
}
chunks.push(`
for _, spec in ipairs(__specs) do
	if type(spec) ~= "function" then error("spec bir fonksiyon dondurmeli") end
	spec(T)
end
local pass, fail, failures = T.run()
local lines = { string.format("PASS %d FAIL %d", pass, fail) }
for _, message in ipairs(failures) do table.insert(lines, "  x " .. message) end
return table.concat(lines, "\\n")
`);

const lua = await Lua.create({ sandbox: true });
let report;
try {
	report = lua.execute(chunks.join("\n\n"));
} catch (err) {
	console.error(String(err.message ?? err).split("\n").slice(0, 6).join("\n"));
	process.exit(1);
}
const text = String(report[0]);
console.log(text);
process.exit(/FAIL 0\b/.test(text) && !/FAIL [1-9]/.test(text) ? 0 : 1);
```

- [ ] **Step 6: Run test to verify the harness works but the bad assertion fails**

Run: `node tools/test.mjs`
Expected: `PASS 2 FAIL 1` ve `TestKit > yanlis deger yakalanir: beklenen 3, gelen 2` satırı, çıkış kodu `1`.

> Bu, koşucunun testleri gerçekten çalıştırdığını ve hataları yakaladığını kanıtlar.

- [ ] **Step 7: Fix the intentional failure**

`tests/Smoke.spec.luau` içindeki `T.expect(2):toBe(3)` satırını `T.expect(2):toBe(2)` yap.

- [ ] **Step 8: Run test to verify it passes**

Run: `node tools/test.mjs`
Expected: `PASS 3 FAIL 0`, çıkış kodu `0`.

> **Bu ortamda doğrulandı:** Task 1–8 tamamlandığında koşucu `PASS 88 FAIL 1` verdi (tek hata `Smoke.spec.luau`'nun kasıtlı hatası) ve ardından `PASS 88 FAIL 0` oldu. Koşucu ~10 sn'nin altında çalışır.

- [ ] **Step 9: Format and commit**

```bash
npm install
npx stylua src tests
git add package.json .luaurc stylua.toml .gitignore tools/test.mjs src/shared/testkit tests/Smoke.spec.luau
git commit -m "test: add Luau WASM test harness and TestKit"
```

---

### Task 2: Kinematics (yörünge matematiği)

**Files:**
- Create: `src/shared/core/Kinematics.luau`
- Test: `tests/Kinematics.spec.luau`

**Interfaces:**
- Consumes: yok.
- Produces (tümü `{x:number, y:number, z:number}` düz vektörler):
  - `Kinematics.vec(x, y, z) -> Vec3`
  - `Kinematics.add(a, b)`, `Kinematics.scale(a, s)`, `Kinematics.magnitude(a)` → `number`
  - `Kinematics.launchVelocity(power: number, yawRad: number, pitchRad: number, maxSpeed: number) -> Vec3`
  - `Kinematics.positionAt(v: Vec3, t: number, gravity: number) -> Vec3`
  - `Kinematics.speedAt(v: Vec3, t: number, gravity: number) -> number`
  - `Kinematics.flightTime(v: Vec3, gravity: number) -> number` (başlangıç y=0, y=0'a dönüş; `vy <= 0` ise `0`)
  - `Kinematics.step(v: Vec3, dt: number, gravity: number) -> Vec3` (semi-implicit Euler hız adımı)

- [ ] **Step 1: Write the failing test**

`tests/Kinematics.spec.luau`:

```lua
return function(T)
	local Kinematics = T.require("Kinematics")
	local G = 196.2
	local MAX = 260

	T.describe("Kinematics.launchVelocity", function()
		T.it("45 derece, tam guc: y ve z esit", function()
			local v = Kinematics.launchVelocity(1, 0, math.rad(45), MAX)
			T.expect(v.x):toBeCloseTo(0, 1e-9)
			T.expect(v.y):toBeCloseTo(183.84778, 1e-3)
			T.expect(v.z):toBeCloseTo(183.84778, 1e-3)
		end)

		T.it("yaw 90 derece: hiz +x yonune doner", function()
			local v = Kinematics.launchVelocity(1, math.rad(90), 0, MAX)
			T.expect(v.x):toBeCloseTo(260, 1e-6)
			T.expect(v.z):toBeCloseTo(0, 1e-6)
		end)

		T.it("sifir guc sifir hiz verir", function()
			local v = Kinematics.launchVelocity(0, 0, math.rad(30), MAX)
			T.expect(Kinematics.magnitude(v)):toBeCloseTo(0, 1e-9)
		end)

		T.it("guc 1 ustunde kirpilir", function()
			local v = Kinematics.launchVelocity(3, 0, 0, MAX)
			T.expect(Kinematics.magnitude(v)):toBeCloseTo(260, 1e-6)
		end)
	end)

	T.describe("Kinematics.positionAt", function()
		T.it("2 saniyede dusme", function()
			local p = Kinematics.positionAt({ x = 0, y = 100, z = 0 }, 2, G)
			T.expect(p.y):toBeCloseTo(-192.4, 1e-6)
		end)

		T.it("yatay hiz sabit", function()
			local p = Kinematics.positionAt({ x = 50, y = 0, z = 0 }, 3, G)
			T.expect(p.x):toBeCloseTo(150, 1e-9)
		end)
	end)

	T.describe("Kinematics.speedAt", function()
		T.it("1 saniyede hiz", function()
			T.expect(Kinematics.speedAt({ x = 0, y = 100, z = 0 }, 1, G)):toBeCloseTo(96.2, 1e-6)
		end)
	end)

	T.describe("Kinematics.flightTime", function()
		T.it("yukari 100 stud/s: 1.01937 sn", function()
			T.expect(Kinematics.flightTime({ x = 0, y = 100, z = 0 }, G)):toBeCloseTo(1.01937, 1e-4)
		end)

		T.it("asagi yonlu hiz icin sifir", function()
			T.expect(Kinematics.flightTime({ x = 0, y = -5, z = 0 }, G)):toBe(0)
		end)
	end)

	T.describe("Kinematics (ozellik testi)", function()
		T.it("240 Hz ayrik adim analitik yorungeye 0.5 stud icinde yakinsar", function()
			local v0 = Kinematics.launchVelocity(1, 0, math.rad(45), MAX)
			local dt = 1 / 240
			local p = { x = 0, y = 0, z = 0 }
			local v = v0
			for _ = 1, 240 do
				p = Kinematics.add(p, Kinematics.scale(v, dt))
				v = Kinematics.step(v, dt, G)
			end
			local analytic = Kinematics.positionAt(v0, 1, G)
			T.expect(p.y):toBeCloseTo(analytic.y, 0.5)
			T.expect(p.z):toBeCloseTo(analytic.z, 1e-6)
		end)
	end)
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node tools/test.mjs Kinematics`
Expected: FAIL — `modul bulunamadi: Kinematics`

- [ ] **Step 3: Implement `Kinematics.luau`**

İmzalar arayüzde sabit. Gövde için kararlar: `launchVelocity` gücü `math.clamp(power, 0, 1)` ile kırpar; yön `yaw` etrafında dönen ve `pitch` ile yükselen birim vektördür. `vertex` tabanlı `speedAt`, `|vx, vy - g t, vz|`'dir. `flightTime`, `2 * vy / g`. `step` yalnızca hızı günceller (konum çağıranın işi — özellik testi bunu doğrular).

- [ ] **Step 4: Run test to verify it passes**

Run: `node tools/test.mjs Kinematics`
Expected: `PASS 9 FAIL 0`

- [ ] **Step 5: Format and commit**

```bash
npx stylua src tests
git add src/shared/core/Kinematics.luau tests/Kinematics.spec.luau
git commit -m "feat: add pure projectile kinematics"
```

---

### Task 3: AimModel (3D nişan alma)

**Files:**
- Create: `src/shared/core/AimModel.luau`
- Create: `src/shared/config/GameConfig.luau`
- Test: `tests/AimModel.spec.luau`

**Interfaces:**
- Consumes: `Kinematics.magnitude`, `Kinematics.scale`.
- Produces:
  - `GameConfig.GRAVITY = 196.2`, `GameConfig.MAX_SPEED = 260`, `GameConfig.MAX_PULL = 8`, `GameConfig.DEAD_ZONE = 0.75`, `GameConfig.MIN_POWER = 0.12`, `GameConfig.MAX_RANGE = 420`, `GameConfig.BIRD_TYPES = { "Wren", "Swallow", "Puffin" }`
  - `AimModel.evaluate(pull: Vec3, config: AimConfig) -> { accepted: boolean, reason: string?, power: number, yaw: number, pitch: number, velocity: Vec3 }`  — `AimConfig` = `{ DEAD_ZONE, MIN_POWER, MAX_PULL, MAX_SPEED }` (yani `GameConfig` doğrudan geçirilebilir)
  - `AimModel.aimAngles(velocity: Vec3) -> (number, number)` → `(yaw, pitch)`

**Davranış (spec §3.2):** `magnitude = |pull|`. `magnitude < 0.75` → red `"dead_zone"`. `power = clamp(magnitude / 8, 0, 1)`; `power < 0.12` → red `"too_weak"`. Yön: `velocity = -(pull / magnitude) * power * 260`.

- [ ] **Step 1: Write the failing test**

`tests/AimModel.spec.luau`:

```lua
return function(T)
	local AimModel = T.require("AimModel")
	local GameConfig = T.config("GameConfig")

	T.describe("AimModel.evaluate", function()
		T.it("tam sola cekme saga 260 hiz verir", function()
			local r = AimModel.evaluate({ x = -8, y = 0, z = 0 }, GameConfig)
			T.expect(r.accepted):toBeTrue()
			T.expect(r.power):toBeCloseTo(1, 1e-9)
			T.expect(r.velocity.x):toBeCloseTo(260, 1e-6)
			T.expect(r.yaw):toBeCloseTo(math.rad(90), 1e-6)
		end)

		T.it("asagi cekme yukari firlatir", function()
			local r = AimModel.evaluate({ x = 0, y = -8, z = 0 }, GameConfig)
			T.expect(r.velocity.y):toBeCloseTo(260, 1e-6)
			T.expect(r.pitch):toBeCloseTo(math.rad(90), 1e-6)
		end)

		T.it("olu bolge: 0.5 stud cekme atis sayilmaz", function()
			local r = AimModel.evaluate({ x = 0.5, y = 0, z = 0 }, GameConfig)
			T.expect(r.accepted):toBeFalse()
			T.expect(r.reason):toBe("dead_zone")
		end)

		T.it("cok zayif: 0.9 stud cekme atis sayilmaz", function()
			local r = AimModel.evaluate({ x = 0.9, y = 0, z = 0 }, GameConfig)
			T.expect(r.accepted):toBeFalse()
			T.expect(r.reason):toBe("too_weak")
		end)

		T.it("esik ustu minimum atis kabul edilir", function()
			local r = AimModel.evaluate({ x = 1, y = 0, z = 0 }, GameConfig)
			T.expect(r.accepted):toBeTrue()
			T.expect(r.power):toBeCloseTo(0.125, 1e-9)
			T.expect(r.velocity.x):toBeCloseTo(-32.5, 1e-6)
		end)

		T.it("max cekme asla asilmaz", function()
			local r = AimModel.evaluate({ x = 0, y = 0, z = -40 }, GameConfig)
			T.expect(r.velocity.z):toBeCloseTo(260, 1e-6)
		end)

		T.it("capraz cekme yonu korunur", function()
			local r = AimModel.evaluate({ x = -4, y = 0, z = 4 }, GameConfig)
			T.expect(r.power):toBeCloseTo(0.707107, 1e-5)
			T.expect(r.velocity.x):toBeCloseTo(130, 1e-6)
			T.expect(r.velocity.z):toBeCloseTo(-130, 1e-6)
		end)
	end)

	T.describe("AimModel.aimAngles", function()
		T.it("dikey hiz pitch 90 verir", function()
			local _, pitch = AimModel.aimAngles({ x = 0, y = 10, z = 0 })
			T.expect(pitch):toBeCloseTo(math.rad(90), 1e-6)
		end)
	end)

	T.describe("GameConfig", function()
		T.it("sabitler spec ile ayni", function()
			T.expect(GameConfig.GRAVITY):toBe(196.2)
			T.expect(GameConfig.MAX_SPEED):toBe(260)
			T.expect(GameConfig.MAX_PULL):toBe(8)
			T.expect(GameConfig.MIN_POWER):toBe(0.12)
			T.expect(GameConfig.BIRD_TYPES):toEqual({ "Wren", "Swallow", "Puffin" })
		end)
	end)
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node tools/test.mjs AimModel`
Expected: FAIL — `modul bulunamadi: AimModel`

- [ ] **Step 3: Implement `GameConfig.luau` and `AimModel.luau`**

`GameConfig` düz sabit tablosudur (spec §6 kural 8). `AimModel` üç red/yön kararını yukarıdaki davranışa göre verir; `aimAngles` `yaw = atan2(v.x, v.z)`, `pitch = asin(clamp(v.y / |v|, -1, 1))`; `|v| == 0` ise `(0, 0)`.

- [ ] **Step 4: Run test to verify it passes**

Run: `node tools/test.mjs AimModel`
Expected: `PASS 10 FAIL 0`

- [ ] **Step 5: Format and commit**

```bash
npx stylua src tests
git add src/shared/core/AimModel.luau src/shared/config/GameConfig.luau tests/AimModel.spec.luau
git commit -m "feat: add 3D aim model with dead zone and power clamp"
```

---

### Task 4: DamageModel (yıkım matematiği)

**Files:**
- Create: `src/shared/core/DamageModel.luau`
- Create: `src/shared/config/Materials.luau`
- Test: `tests/DamageModel.spec.luau`

**Interfaces:**
- Consumes: yok.
- Produces:
  - `Materials.definitions` → `{ Wood = { health = 55, density = 0.6, multiplier = 1.0 }, Glass = { health = 24, density = 0.4, multiplier = 2.0 }, Stone = { health = 140, density = 1.8, multiplier = 0.65 }, Metal = { health = math.huge, density = 2.4, multiplier = 0 } }`
  - `DamageModel.impactDamage(relativeSpeed: number, mass: number, materialName: string, materials: MaterialTable) -> number`
  - `DamageModel.fallDamage(impactSpeed: number) -> number`
  - `DamageModel.resolveHits(pieces: { { id: string, material: string, health: number } }, hits: { { pieceId: string, damage: number } }) -> { { pieceId: string, healthAfter: number, destroyed: boolean } }`

**Formül (spec §3.5):** `speedFactor = clamp((speed - 18) / (220 - 18), 0, 1)`, `massFactor = clamp(mass / 2.5, 0.3, 2.0)`, `damage = round(speedFactor * massFactor * multiplier * 100)`. `fallDamage = max(0, (speed - 40) * 1.2)`.

- [ ] **Step 1: Write the failing test**

`tests/DamageModel.spec.luau`:

```lua
return function(T)
	local DamageModel = T.require("DamageModel")
	local Materials = T.config("Materials")

	T.describe("DamageModel.impactDamage", function()
		T.it("esik hizinda hasar yok", function()
			T.expect(DamageModel.impactDamage(18, 2.5, "Wood", Materials)):toBe(0)
		end)

		T.it("tam hiz, referans kutle, Wood: 100", function()
			T.expect(DamageModel.impactDamage(220, 2.5, "Wood", Materials)):toBe(100)
		end)

		T.it("orta hiz: 50", function()
			T.expect(DamageModel.impactDamage(119, 2.5, "Wood", Materials)):toBe(50)
		end)

		T.it("Glass iki kat hasar alir", function()
			T.expect(DamageModel.impactDamage(119, 2.5, "Glass", Materials)):toBe(100)
		end)

		T.it("Stone daha az hasar alir ve yuvarlanir", function()
			-- 0.5 * 1.0 * 0.65 * 100 = 32.5 ; math.round(32.5) == 33
			T.expect(DamageModel.impactDamage(119, 2.5, "Stone", Materials)):toBe(33)
		end)

		T.it("Metal hasar almaz", function()
			T.expect(DamageModel.impactDamage(260, 50, "Metal", Materials)):toBe(0)
		end)

		T.it("hafif kutle hasari azaltir", function()
			T.expect(DamageModel.impactDamage(220, 0.5, "Wood", Materials)):toBe(30)
		end)

		T.it("cok agir kutle hasari iki katla sinirlar", function()
			T.expect(DamageModel.impactDamage(220, 50, "Wood", Materials)):toBe(200)
		end)

		T.it("bilinmeyen malzeme hata verir", function()
			T.expect(function()
				DamageModel.impactDamage(100, 1, "Kagit", Materials)
			end):toThrow()
		end)
	end)

	T.describe("DamageModel.fallDamage", function()
		T.it("40 altinda hasar yok", function()
			T.expect(DamageModel.fallDamage(39)):toBe(0)
		end)

		T.it("100 hizinda 72 hasar", function()
			T.expect(DamageModel.fallDamage(100)):toBeCloseTo(72, 1e-6)
		end)
	end)

	T.describe("DamageModel.resolveHits", function()
		T.it("saglik duser ve kirilma bildirilir", function()
			local pieces = { { id = "w1", material = "Wood", health = 55 } }
			local result = DamageModel.resolveHits(pieces, { { pieceId = "w1", damage = 60 } })
			T.expect(#result):toBe(1)
			T.expect(result[1].pieceId):toBe("w1")
			T.expect(result[1].healthAfter):toBe(0)
			T.expect(result[1].destroyed):toBeTrue()
		end)

		T.it("Metal parca math.huge ile NaN uretmez", function()
			local pieces = { { id = "m1", material = "Metal", health = math.huge } }
			local result = DamageModel.resolveHits(pieces, { { pieceId = "m1", damage = 900 } })
			T.expect(result[1].destroyed):toBeFalse()
			T.expect(result[1].healthAfter > 0):toBeTrue()
		end)

		T.it("bilinmeyen parca id'si sessizce atlanir", function()
			local result = DamageModel.resolveHits({}, { { pieceId = "yok", damage = 10 } })
			T.expect(#result):toBe(0)
		end)

		T.it("ayni karede iki vurus toplanir", function()
			local pieces = { { id = "g1", material = "Glass", health = 24 } }
			local result = DamageModel.resolveHits(pieces, {
				{ pieceId = "g1", damage = 15 },
				{ pieceId = "g1", damage = 15 },
			})
			T.expect(#result):toBe(1)
			T.expect(result[1].destroyed):toBeTrue()
		end)
	end)

	T.describe("Materials", function()
		T.it("Metal sonsuz saglik tasir", function()
			T.expect(Materials.Metal.health):toBe(math.huge)
		end)
	end)
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node tools/test.mjs DamageModel`
Expected: FAIL — `modul bulunamadi: DamageModel`

- [ ] **Step 3: Implement `Materials.luau` and `DamageModel.luau`**

`resolveHits` girdi parçalarını **mutasyona uğratmaz**; sonuç listesi girdi sırasını korur ve her parçayı en fazla bir kez içerir. Metal için hasar toplanırken `math.huge` sağlıkla çıkarma yapılır (`math.huge - 900 == math.huge`, NaN yok) ama `destroyed` asla `true` olmaz.

- [ ] **Step 4: Run test to verify it passes**

Run: `node tools/test.mjs DamageModel`
Expected: `PASS 16 FAIL 0`

- [ ] **Step 5: Format and commit**

```bash
npx stylua src tests
git add src/shared/core/DamageModel.luau src/shared/config/Materials.luau tests/DamageModel.spec.luau
git commit -m "feat: add damage model with material multipliers and indestructible metal"
```

---

### Task 5: ScoreModel

**Files:**
- Create: `src/shared/core/ScoreModel.luau`
- Test: `tests/ScoreModel.spec.luau`

**Interfaces:**
- Consumes: yok.
- Produces:
  - `ScoreModel.compute(breakdown: { Tinhead: number, Wood: number, Glass: number, Stone: number }, birdsLeft: number) -> number`
  - `ScoreModel.stars(score: number, par: { two: number, three: number }) -> number` → `1 | 2 | 3`

**Formül (spec §3.7):** `500*tinheads + 40*(wood+glass) + 90*stone + 1000*birdsLeft`.

- [ ] **Step 1: Write the failing test**

`tests/ScoreModel.spec.luau`:

```lua
return function(T)
	local ScoreModel = T.require("ScoreModel")

	T.describe("ScoreModel.compute", function()
		T.it("bos kirilma, 3 kus kaldi: 3000", function()
			local s = ScoreModel.compute({ Tinhead = 0, Wood = 0, Glass = 0, Stone = 0 }, 3)
			T.expect(s):toBe(3000)
		end)

		T.it("karisik kirilma", function()
			local s = ScoreModel.compute({ Tinhead = 4, Wood = 10, Glass = 5, Stone = 2 }, 1)
			T.expect(s):toBe(3780)
		end)

		T.it("eksik alan sifir sayilir", function()
			T.expect(ScoreModel.compute({ Tinhead = 1 }, 0)):toBe(500)
		end)
	end)

	T.describe("ScoreModel.stars", function()
		local par = { two = 3200, three = 5400 }

		T.it("esik tam tutarsa 3 yildiz", function()
			T.expect(ScoreModel.stars(5400, par)):toBe(3)
		end)

		T.it("esik altinda 2 yildiz", function()
			T.expect(ScoreModel.stars(5399, par)):toBe(2)
		end)

		T.it("iki esigi de gecerse 1 yildiz", function()
			T.expect(ScoreModel.stars(100, par)):toBe(1)
		end)

		T.it("sifir skor 0 yildiz degil 1 yildiz", function()
			T.expect(ScoreModel.stars(0, par)):toBe(1)
		end)
	end)
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node tools/test.mjs ScoreModel`
Expected: FAIL — `modul bulunamadi: ScoreModel`

- [ ] **Step 3: Implement `ScoreModel.luau`**

Eksik alanlar `0` sayılır (`breakdown.Tinhead or 0`). Yıldız eşikleri **dahil** (`>=`).

- [ ] **Step 4: Run test to verify it passes**

Run: `node tools/test.mjs ScoreModel`
Expected: `PASS 7 FAIL 0`

- [ ] **Step 5: Format and commit**

```bash
npx stylua src tests
git add src/shared/core/ScoreModel.luau tests/ScoreModel.spec.luau
git commit -m "feat: add score and star computation"
```

---

### Task 6: LevelSchema ve üç seviye

**Files:**
- Create: `src/shared/core/LevelSchema.luau`
- Create: `src/shared/core/BuildMath.luau`
- Create: `src/shared/levels/Level01.luau`, `Level02.luau`, `Level03.luau`, `init.luau`
- Test: `tests/LevelSchema.spec.luau`, `tests/Levels.spec.luau`, `tests/BuildMath.spec.luau`

**Interfaces:**
- Consumes: `GameConfig.BIRD_TYPES`, `GameConfig.MAX_RANGE`, `Materials.definitions`.
- Produces:
  - `LevelSchema.validate(def: any, config: { BIRD_TYPES: {string}, MAX_RANGE: number }, materials: MaterialTable) -> (boolean, { string })` — hata kodları: `"missing_field:id"`, `"bad_par"`, `"unknown_bird:<ad>"`, `"empty_loadout"`, `"duplicate_piece_id:<id>"`, `"unknown_material:<ad>"`, `"bad_size:<id>"`, `"empty_targets"`, `"target_out_of_range:<id>"`, `"overlapping_pieces:<a>:<b>"`
  - `BuildMath.aabb(piece) -> { min: Vec3, max: Vec3 }`
  - `BuildMath.overlaps(a, b) -> boolean`
  - `BuildMath.toVector3(v) -> Vector3` (yalnızca Roblox katmanı kullanır; core içinde tanımlı ama `Vector3` çağırmaz — `v.x, v.y, v.z` sırasıyla döner tablo)
  - `Levels.register(level)`, `Levels.list() -> { LevelDefinition }`, `Levels.get(id: string) -> LevelDefinition?`
  - **Neden `register`:** `levels/init.luau` içinde `require(script.Parent.Level01)` yazmak `script` kuralını ihlal eder. `init.luau` sırayı tutar; kayıt `init.server.luau` (Roblox katmanı) ve test koşucusu (VM) tarafından ayrı ayrı yapılır.

**Seviye verisi (spec §4.5 şeması):** her seviye `id, name, par{two,three}, loadout, slingshot{position,facing}, pieces[], targets[], props[]` alanlarını taşır. Sapan menzili `MAX_RANGE = 420` stud; tüm hedefler sapan konumundan bu mesafe içinde olmalı.

- [ ] **Step 1: Write the failing tests**

`tests/BuildMath.spec.luau`:

```lua
return function(T)
	local BuildMath = T.require("BuildMath")

	T.describe("BuildMath.aabb", function()
		T.it("rotasyonsuz kutu sinirlari", function()
			local box = BuildMath.aabb({ position = { x = 0, y = 10, z = 0 }, size = { x = 2, y = 4, z = 6 } })
			T.expect(box.min.y):toBeCloseTo(8, 1e-9)
			T.expect(box.max.y):toBeCloseTo(12, 1e-9)
			T.expect(box.max.z):toBeCloseTo(3, 1e-9)
		end)

		T.it("y ekseninde 90 derece x ve z'yi takas eder", function()
			local box = BuildMath.aabb({
				position = { x = 0, y = 0, z = 0 },
				size = { x = 2, y = 4, z = 6 },
				rotation = { x = 0, y = 90, z = 0 },
			})
			T.expect(box.max.x):toBeCloseTo(3, 1e-9)
			T.expect(box.max.z):toBeCloseTo(1, 1e-9)
		end)
	end)

	T.describe("BuildMath.overlaps", function()
		T.it("ayni yerde iki kutu cakisir", function()
			local a = BuildMath.aabb({ position = { x = 0, y = 0, z = 0 }, size = { x = 2, y = 2, z = 2 } })
			local b = BuildMath.aabb({ position = { x = 1, y = 0, z = 0 }, size = { x = 2, y = 2, z = 2 } })
			T.expect(BuildMath.overlaps(a, b)):toBeTrue()
		end)

		T.it("yan yana kutular cakismaz", function()
			local a = BuildMath.aabb({ position = { x = 0, y = 0, z = 0 }, size = { x = 2, y = 2, z = 2 } })
			local b = BuildMath.aabb({ position = { x = 5, y = 0, z = 0 }, size = { x = 2, y = 2, z = 2 } })
			T.expect(BuildMath.overlaps(a, b)):toBeFalse()
		end)

		T.it("tam kenar temas eden kutular cakismaz", function()
			local a = BuildMath.aabb({ position = { x = 0, y = 0, z = 0 }, size = { x = 2, y = 2, z = 2 } })
			local b = BuildMath.aabb({ position = { x = 2, y = 0, z = 0 }, size = { x = 2, y = 2, z = 2 } })
			T.expect(BuildMath.overlaps(a, b)):toBeFalse()
		end)
	end)
end
```

`tests/Levels.spec.luau`:

```lua
return function(T)
	local Levels = T.require("Levels")
	local LevelSchema = T.require("LevelSchema")
	local GameConfig = T.config("GameConfig")
	local Materials = T.config("Materials")

	T.describe("Levels", function()
		T.it("uc seviye var", function()
			T.expect(#Levels.list()):toBe(3)
		end)

		for _, level in ipairs(Levels.list()) do
			T.it("seviye gecerli: " .. level.id, function()
				local ok, errors = LevelSchema.validate(level, GameConfig, Materials)
				T.expect(ok):toBeTrue()
				T.expect(#errors):toBe(0)
			end)

			T.it("seviyede en az bir Tinhead var: " .. level.id, function()
				T.expect(#level.targets > 0):toBeTrue()
			end)

			T.it("kuş yuku bilinen tiplerden: " .. level.id, function()
				T.expect(#level.loadout > 0):toBeTrue()
			end)
		end
	end)
end
```

`tests/LevelSchema.spec.luau` — taban bir seviye tablosundan türetilen **10 vaka**. Yardımcı:

```lua
	local function base()
		return {
			id = "test", name = "Test", par = { two = 100, three = 200 },
			loadout = { "Wren" },
			slingshot = { position = { x = 0, y = 0, z = 0 }, facing = { x = 0, y = 0, z = -1 } },
			pieces = { { id = "w1", material = "Wood", size = { x = 2, y = 2, z = 2 }, position = { x = 0, y = 1, z = -30 } } },
			targets = { { id = "t1", position = { x = 0, y = 1, z = -30 }, health = 100 } },
			props = {},
		}
	end
	local function contains(list, code)
		for _, item in ipairs(list) do if item == code then return true end end
		return false
	end
```

| # | Mutasyon | Beklenen hata kodu |
|---|---|---|
| 1 | (değişiklik yok) | `ok == true` |
| 2 | `def.par = nil` | `bad_par` |
| 3 | `def.loadout = { "Kartal" }` | `unknown_bird:Kartal` |
| 4 | `def.loadout = {}` | `empty_loadout` |
| 5 | aynı `id` ile ikinci parça | `duplicate_piece_id:w1` |
| 6 | `def.pieces[1].material = "Kagit"` | `unknown_material:Kagit` |
| 7 | `def.pieces[1].size = { x = 0, y = 2, z = 2 }` | `bad_size:w1` |
| 8 | `def.targets = {}` | `empty_targets` |
| 9 | `def.targets[1].position.z = -900` | `target_out_of_range:t1` |
| 10 | `position` aynı olan ikinci parça | `overlapping_pieces:w1:w2` |

Her satır tek bir `T.it(...)`; desen:

```lua
	T.it("menzil disi hedef hata", function()
		local def = base()
		def.targets[1].position = { x = 0, y = 0, z = -900 }
		local _, errors = LevelSchema.validate(def, GameConfig, Materials)
		T.expect(contains(errors, "target_out_of_range:t1")):toBeTrue()
	end)
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `node tools/test.mjs`
Expected: FAIL — `modul bulunamadi: BuildMath`, `LevelSchema`, `Levels`

- [ ] **Step 3: Implement `BuildMath.luau`**

`aabb`, yalnızca `rotation.y`'yi dikkate alır (`90`/`270` derecede `size.x` ve `size.z` takas edilir, ara açılar için `|cos|,|sin|` ile genişletilmiş sınır). `overlaps` kesin eşitsizlik kullanır (`>`), böylece tam kenar teması çakışma sayılmaz.

- [ ] **Step 4: Implement `LevelSchema.luau`**

`validate` **fırlatmaz**, hata listesi döndürür (Review Focus 5). Parça çakışması `BuildMath.overlaps` ile `O(n²)` — parça sayısı 60'ın altında olduğundan yeterli.

- [ ] **Step 5: Implement the three levels**

`Level01` — eğitim: 3 Wren kuşu, 2 Tinhead, yalnızca Wood/Glass, açık cephe. `Level02` — dikey yığın: 4 kuş (Wren, Wren, Swallow, Puffin), 3 Tinhead, Wood + Stone sütun, 1 Metal kiriş. `Level03` — kale: 5 kuş, 5 Tinhead, Metal iskelet + Stone duvar + 2 patlayıcı varil. Her seviyede `par.two` ve `par.three` gerçekçi skorlardan türetilir (kaba üst sınır: `1000*kuş + 500*hedef`).

- [ ] **Step 6: Implement `levels/init.luau`**

`list()` üç seviyeyi sırayla döndürür; `get(id)` id ile arar.

- [ ] **Step 7: Run tests to verify they pass**

Run: `node tools/test.mjs`
Expected: `PASS <toplam> FAIL 0` (BuildMath 7, LevelSchema 10, Levels 12, önceki görevler dahil)

- [ ] **Step 8: Format and commit**

```bash
npx stylua src tests
git add src/shared/core/BuildMath.luau src/shared/core/LevelSchema.luau src/shared/levels tests/BuildMath.spec.luau tests/LevelSchema.spec.luau tests/Levels.spec.luau
git commit -m "feat: add level schema, AABB math and three handcrafted levels"
```

---

### Task 7: LevelState (tur durum makinesi)

**Files:**
- Create: `src/shared/core/LevelState.luau`
- Test: `tests/LevelState.spec.luau`

**Interfaces:**
- Consumes: `LevelDefinition` (Task 6).
- Produces:
  - `LevelState.new(level) -> state`
  - `state.phase: string` — `"aiming" | "flying" | "settling" | "won" | "lost"`
  - `state.birdsLeft: number`, `state.targetsLeft: number`
  - `state:fire() -> boolean` (yalnızca `aiming` fazında `true`, kuş tüketir, `flying`'e geçer)
  - `state:notifyLanded() -> ()` (`flying` → `settling`, sayaç sıfırlanır)
  - `state:settleTick(dt: number, fastestSpeed: number) -> string` — `fastestSpeed < 1.5` veya `elapsed >= 4` ise sonucu çözer ve yeni fazı döndürür
  - `state:destroyTarget(id: string) -> ()`
  - `state:result() -> { won: boolean, targetsLeft: number, birdsLeft: number }?`

**Kural (Review Focus 4):** `destroyTarget` sonrası hedef sayısı sıfıra indiyse faz **derhal** `"won"` olur; kuş bitmesi bunu ezmez.

- [ ] **Step 1: Write the failing test**

`tests/LevelState.spec.luau`:

```lua
return function(T)
	local LevelState = T.require("LevelState")

	local function makeLevel(birds, targets)
		local loadout = {}
		for i = 1, birds do
			loadout[i] = "Wren"
		end
		local targetList = {}
		for i = 1, targets do
			targetList[i] = { id = "t" .. i, position = { x = 0, y = 1, z = -20 }, health = 100 }
		end
		return {
			id = "test",
			name = "Test",
			par = { two = 100, three = 200 },
			loadout = loadout,
			slingshot = { position = { x = 0, y = 0, z = 0 }, facing = { x = 0, y = 0, z = -1 } },
			pieces = {},
			targets = targetList,
			props = {},
		}
	end

	T.describe("LevelState", function()
		T.it("baslangicta aiming ve tam kuş sayisi", function()
			local s = LevelState.new(makeLevel(3, 2))
			T.expect(s.phase):toBe("aiming")
			T.expect(s.birdsLeft):toBe(3)
			T.expect(s.targetsLeft):toBe(2)
		end)

		T.it("atis kuş tuketir ve flying'e gecer", function()
			local s = LevelState.new(makeLevel(3, 1))
			T.expect(s:fire()):toBeTrue()
			T.expect(s.phase):toBe("flying")
			T.expect(s.birdsLeft):toBe(2)
		end)

		T.it("flying disinda atis reddedilir", function()
			local s = LevelState.new(makeLevel(3, 1))
			s:fire()
			T.expect(s:fire()):toBeFalse()
			T.expect(s.birdsLeft):toBe(2)
		end)

		T.it("son hedef olunce kazanilir", function()
			local s = LevelState.new(makeLevel(3, 1))
			s:fire()
			s:notifyLanded()
			s:destroyTarget("t1")
			T.expect(s.phase):toBe("won")
			T.expect(s.targetsLeft):toBe(0)
		end)

		T.it("son kuşla son hedef ayni anda olurse kazanilir", function()
			local s = LevelState.new(makeLevel(1, 1))
			s:fire()
			s:destroyTarget("t1")
			T.expect(s.phase):toBe("won")
			T.expect(s:result().won):toBeTrue()
		end)

		T.it("kuş bitince ve hedef kaldiysa kaybedilir", function()
			local s = LevelState.new(makeLevel(1, 1))
			s:fire()
			s:notifyLanded()
			s:settleTick(5, 0)
			T.expect(s.phase):toBe("lost")
			T.expect(s:result().won):toBeFalse()
		end)

		T.it("hareket durunca hemen cozulur", function()
			local s = LevelState.new(makeLevel(2, 1))
			s:fire()
			s:notifyLanded()
			T.expect(s:settleTick(0.1, 0.2)):toBe("aiming")
			T.expect(s.phase):toBe("aiming")
		end)

		T.it("4 saniye sonra hareket surse de cozulur", function()
			local s = LevelState.new(makeLevel(1, 1))
			s:fire()
			s:notifyLanded()
			for _ = 1, 50 do
				s:settleTick(0.1, 9.0)
			end
			T.expect(s.phase):toBe("lost")
		end)

		T.it("kazanildiktan sonra atis yok", function()
			local s = LevelState.new(makeLevel(3, 1))
			s:fire()
			s:destroyTarget("t1")
			T.expect(s:fire()):toBeFalse()
		end)

		T.it("sonuc fazlari dogru raporlanir", function()
			local s = LevelState.new(makeLevel(2, 1))
			T.expect(s:result()):toBe(nil)
			s:fire()
			s:destroyTarget("t1")
			T.expect(s:result().won):toBeTrue()
			T.expect(s:result().birdsLeft):toBe(1)
		end)
	end)
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node tools/test.mjs LevelState`
Expected: FAIL — `modul bulunamadi: LevelState`

- [ ] **Step 3: Implement `LevelState.luau`**

Yeni bir tablo + metatable döndür (kapalı state). `settleTick` her çağrıda `elapsed` biriktirir; çözüm sırası: önce `won` kontrolü, sonra `lost`. `notifyLanded` yalnızca `flying` fazında etkilidir.

- [ ] **Step 4: Run test to verify it passes**

Run: `node tools/test.mjs LevelState`
Expected: `PASS 10 FAIL 0`

- [ ] **Step 5: Format and commit**

```bash
npx stylua src tests
git add src/shared/core/LevelState.luau tests/LevelState.spec.luau
git commit -m "feat: add round state machine with settle timeout"
```

---

### Task 8: Rojo projesi ve sunucu/istemci iskeleti

**Files:**
- Create: `default.project.json`
- Create: `src/shared/Remotes.luau`
- Create: `src/server/init.server.luau`, `src/client/init.client.luau`
- Create: `tools/verify-structure.mjs`
- Test: `tests/Remotes.spec.luau`

**Interfaces:**
- Consumes: yok (Roblox katmanı).
- Produces:
  - `default.project.json` — `ReplicatedStorage.Shared`, `ServerScriptService.Server`, `StarterPlayer.StarterPlayerScripts.Client` eşlemesi; `globIgnorePaths` testleri dışlar.
  - `Remotes.NAMES = { "FireRequest", "AbilityRequest", "ShotFired", "DamageEvent", "LevelStateChanged" }`
  - `Remotes.ensure(parent) -> { [string]: RemoteEvent }` (sunucu tarafı oluşturur, istemci `WaitForChild`).
  - `node tools/verify-structure.mjs` → her `.luau` dosyasının proje eşlemesinde bir karşılığı olduğunu ve yasaklı global içermediğini doğrular.

- [ ] **Step 1: Write the failing test**

`tests/Remotes.spec.luau`:

```lua
return function(T)
	local Remotes = T.require("Remotes")

	T.describe("Remotes", function()
		T.it("bes olay adi tanimli", function()
			T.expect(#Remotes.NAMES):toBe(5)
		end)

		T.it("adlar spec ile ayni", function()
			T.expect(Remotes.NAMES):toEqual({
				"FireRequest",
				"AbilityRequest",
				"ShotFired",
				"DamageEvent",
				"LevelStateChanged",
			})
		end)
	end)
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node tools/test.mjs Remotes`
Expected: FAIL — `modul bulunamadi: Remotes`

- [ ] **Step 3: Implement `default.project.json`, `Remotes.luau`, boot dosyaları**

`default.project.json`:
```json
{
  "name": "flockfall",
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": {
      "$className": "ReplicatedStorage",
      "$ignoreUnknownInstances": true,
      "Shared": { "$path": "src/shared" },
      "Remotes": { "$className": "Folder" }
    },
    "ServerScriptService": {
      "$className": "ServerScriptService",
      "$ignoreUnknownInstances": true,
      "Server": { "$path": "src/server" }
    },
    "StarterPlayer": {
      "$className": "StarterPlayer",
      "$ignoreUnknownInstances": true,
      "StarterPlayerScripts": {
        "$className": "StarterPlayerScripts",
        "$ignoreUnknownInstances": true,
        "Client": { "$path": "src/client" }
      }
    }
  },
  "globIgnorePaths": ["**/*.spec.luau", "**/testkit/**"],
  "emitLegacyScripts": true
}
```

`Remotes.luau` saf tablo döndürür; `ensure` fonksiyonu içinde `Instance.new` çağırdığı için **bu modül core değil** — `src/shared/` altında ama `core/` dışında. Bu nedenle `tools/verify-structure.mjs` yasaklı global kontrolünü yalnızca `src/shared/core/**` için uygular.

Boot dosyaları ilk aşamada yalnızca `print("[flockfall] server boot")` / `print("[flockfall] client boot")` çalıştırır; sonraki görevlerde doldurulur.

- [ ] **Step 4: Implement `tools/verify-structure.mjs`**

Kontroller: (a) `default.project.json` geçerli JSON, (b) `src/` altındaki her `.luau` dosyası üç kök eşlemeden birinin altında, (c) `src/shared/core/**/*.luau` içinde `game`,`workspace`,`Instance`,`Vector3`,`CFrame`,`task.`,`wait(` geçmiyor, (d) spec dosyalarında yasaklı IP adları geçmiyor. İhlalde çıkış kodu `1`.

- [ ] **Step 5: Run tests and structure check**

Run: `node tools/test.mjs Remotes && node tools/verify-structure.mjs`
Expected: `PASS 2 FAIL 0` ardından `yapi dogrulandi: <n> dosya`

- [ ] **Step 6: Format and commit**

```bash
npx stylua src tests tools 2>/dev/null || true
git add default.project.json src/shared/Remotes.luau src/server src/client tools/verify-structure.mjs tests/Remotes.spec.luau
git commit -m "feat: add rojo project mapping, remotes and structure verifier"
```

---

### Task 9: BuildService (yapıları dünyaya kurma)

**Files:**
- Create: `src/server/BuildService.luau`
- Create: `src/shared/core/BuildPlan.luau`
- Test: `tests/BuildPlan.spec.luau`

**Interfaces:**
- Consumes: `BuildMath`, `Materials`, `LevelDefinition`.
- Produces:
  - `BuildPlan.fromLevel(level, materials: MaterialTable) -> { { pieceId: string, size: Vec3, cframe: { position: Vec3, rotation: Vec3 }, material: string, color: { number }, anchored: boolean } }`
  - `BuildPlan.colorFor(materialName) -> { number }` (3 elemanlı renk dizisi; `{ number, number, number }` Luau'da geçersizdir)
  - `BuildService.build(level, container: Instance) -> { [string]: BasePart }` (Roblox katmanı, test edilmez)
  - `BuildService.cleanup(container: Instance) -> ()`

**Amaç:** "Hangi parça, hangi boyut/renk/konumda" kararı **saf** `BuildPlan`'da verilir ve test edilir; `BuildService` yalnızca `Instance.new("Part")` çağırır.

- [ ] **Step 1: Write the failing test**

`tests/BuildPlan.spec.luau`:

```lua
return function(T)
	local BuildPlan = T.require("BuildPlan")
	local Levels = T.require("Levels")
	local Materials = T.config("Materials")

	T.describe("BuildPlan.fromLevel", function()
		T.it("her parca icin bir plan uretir", function()
			local level = Levels.get("level-01")
			local plan = BuildPlan.fromLevel(level, Materials)
			T.expect(#plan):toBe(#level.pieces)
		end)

		T.it("Wood yapili olur, Glass yapili degil", function()
			local level = Levels.get("level-01")
			local plan = BuildPlan.fromLevel(level, Materials)
			for _, entry in ipairs(plan) do
				if entry.material == "Wood" then
					T.expect(entry.anchored):toBeTrue()
				end
			end
		end)

		T.it("renkler malzemeye ozgu ve farkli", function()
			T.expect(BuildPlan.colorFor("Wood")):toEqual({ 0.55, 0.32, 0.16 })
			T.expect(BuildPlan.colorFor("Metal")):toEqual({ 0.42, 0.45, 0.49 })
		end)

		T.it("bilinmeyen malzeme hata verir", function()
			T.expect(function()
				BuildPlan.colorFor("Kagit")
			end):toThrow()
		end)
	end)
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node tools/test.mjs BuildPlan`
Expected: FAIL — `modul bulunamadi: BuildPlan`

- [ ] **Step 3: Implement `BuildPlan.luau`**

Renk paleti: Wood `{0.55, 0.32, 0.16}`, Glass `{0.72, 0.86, 0.90}`, Stone `{0.53, 0.53, 0.53}`, Metal `{0.42, 0.45, 0.49}`. `fromLevel`, `level.pieces` sırasını korur ve `BuildMath.aabb` ile doğrulanmış boyutları taşır.

- [ ] **Step 4: Run test to verify it passes**

Run: `node tools/test.mjs BuildPlan`
Expected: `PASS 4 FAIL 0`

- [ ] **Step 5: Implement `BuildService.luau`**

`Instance.new("Part")` ile her planı kurar: `Anchored = plan.anchored`, `CanCollide = true`, `Material` eşlemesi (Wood→Wood, Glass→Glass, Stone→Slate, Metal→Metal), `CustomPhysicalProperties = PhysicalProperties.new(density, 0.7, 0.5, 1, 1)`, `SetAttribute("pieceId", …)`, `SetAttribute("material", …)`. Tinhead'ler için Neon göz parçası ekler. Tüm parçalar tek bir `Folder` altında toplanır.

- [ ] **Step 6: Verify and commit**

Run: `node tools/test.mjs && node tools/verify-structure.mjs`
Expected: hepsi yeşil

```bash
npx stylua src tests
git add src/shared/core/BuildPlan.luau src/server/BuildService.luau tests/BuildPlan.spec.luau
git commit -m "feat: add build plan and world construction service"
```

---

### Task 10: DamageService ve FireService (sunucu otoritesi)

**Files:**
- Create: `src/server/FireService.luau`
- Create: `src/server/DamageService.luau`
- Create: `src/shared/core/RateLimiter.luau`
- Test: `tests/RateLimiter.spec.luau`, `tests/DamageQueue.spec.luau`
- Create: `src/shared/core/DamageQueue.luau`

**Interfaces:**
- Consumes: `AimModel`, `DamageModel`, `Kinematics`, `GameConfig`, `Remotes`.
- Produces:
  - `RateLimiter.new(minInterval: number) -> { allow: (now: number) -> boolean }`
  - `DamageQueue.new() -> queue`; `queue:push(pieceId, damage)`, `queue:drain() -> { { pieceId, damage } }`, `queue:size() -> number`
  - `FireService.handleFire(player, power, yaw, pitch) -> boolean`
  - `DamageService.applyImpact(part, otherPart) -> ()`

**Neden bu ayrım:** rate limit ve hasar biriktirme saf mantıktır → test edilir. Roblox'a bağlı kısım (spawn, `Touched` bağlama) incedir.

**Katman kuralı:** `src/server/**` ve `src/client/**` dosyaları normal Roblox kurallarıyla `require` kullanabilir (`script.Parent`). Yasak yalnızca `src/shared/core/**` içindir. `DamageService`, `DamageModel.impactDamage(...)` çağırırken `Materials.definitions` tablosunu **açıkça geçirir**.

- [ ] **Step 1: Write the failing tests**

`tests/RateLimiter.spec.luau`:

```lua
return function(T)
	local RateLimiter = T.require("RateLimiter")

	T.describe("RateLimiter", function()
		T.it("ilk istek gecer", function()
			local limiter = RateLimiter.new(0.35)
			T.expect(limiter:allow(0)):toBeTrue()
		end)

		T.it("cok hizli ikinci istek reddedilir", function()
			local limiter = RateLimiter.new(0.35)
			limiter:allow(0)
			T.expect(limiter:allow(0.1)):toBeFalse()
		end)

		T.it("aralik dolunca tekrar gecer", function()
			local limiter = RateLimiter.new(0.35)
			limiter:allow(0)
			T.expect(limiter:allow(0.36)):toBeTrue()
		end)

		T.it("reddedilen istek zamani ilerletmez", function()
			local limiter = RateLimiter.new(0.35)
			limiter:allow(0)
			limiter:allow(0.3)
			T.expect(limiter:allow(0.36)):toBeTrue()
		end)
	end)
end
```

`tests/DamageQueue.spec.luau`:

```lua
return function(T)
	local DamageQueue = T.require("DamageQueue")

	T.describe("DamageQueue", function()
		T.it("bos kuyruk bosaltilir", function()
			T.expect(#DamageQueue.new():drain()):toBe(0)
		end)

		T.it("ayni parca icin hasar toplanir", function()
			local q = DamageQueue.new()
			q:push("w1", 10)
			q:push("w1", 15)
			local entries = q:drain()
			T.expect(#entries):toBe(1)
			T.expect(entries[1].damage):toBe(25)
		end)

		T.it("bosaltma kuyrugu temizler", function()
			local q = DamageQueue.new()
			q:push("w1", 10)
			q:drain()
			T.expect(q:size()):toBe(0)
		end)

		T.it("farkli parcalar ayri tutulur", function()
			local q = DamageQueue.new()
			q:push("w1", 10)
			q:push("g1", 5)
			T.expect(#q:drain()):toBe(2)
		end)
	end)
end
```

- [ ] **Step 2: Run tests to verify they fail**

Run: `node tools/test.mjs`
Expected: FAIL — `modul bulunamadi: RateLimiter`, `DamageQueue`

- [ ] **Step 3: Implement `RateLimiter.luau` and `DamageQueue.luau`**

`RateLimiter`, reddedilen çağrılarda `last` alanını güncellemez. `DamageQueue` içinde sıra korunur (ilk eklenen parça önce).

- [ ] **Step 4: Run tests to verify they pass**

Run: `node tools/test.mjs`
Expected: yeşil

- [ ] **Step 5: Implement `FireService.luau`**

`FireRequest.OnServerEvent` içinde sırasıyla: tip kontrolü (`type(power) == "number"`), aralık (`0..1`, `-π..π`), `playersLimiter[player]:allow(os.clock())`, `LevelState:fire()`. Hepsi geçerse `AimModel.evaluate` yerine doğrudan `Kinematics.launchVelocity(power, yaw, pitch, GameConfig.MAX_SPEED)` kullanılır (istemci zaten açı gönderiyor). Kuş `Part`'ı sapan konumunda oluşturulur, `AssemblyLinearVelocity = velocity`, `SetNetworkOwner(nil)`, `Debris:AddItem(bird, 12)`.

- [ ] **Step 6: Implement `DamageService.luau`**

Kuş `Touched` olayında: `relativeSpeed = (part.AssemblyLinearVelocity - other.AssemblyLinearVelocity).Magnitude`, `mass = part.AssemblyMass`, `material = other:GetAttribute("material")`. Hasar > 0 ise `DamageQueue`'ya eklenir; `Heartbeat`'te kuyruk boşaltılır ve `DamageModel.resolveHits` sonucu parçalara uygulanır (`health` attribute, `destroyed` ise `Debris:AddItem(part, 0.05)`), ardından `DamageEvent:FireAllClients`.

- [ ] **Step 7: Verify and commit**

Run: `node tools/test.mjs && node tools/verify-structure.mjs`
Expected: yeşil

```bash
npx stylua src tests
git add src/server/FireService.luau src/server/DamageService.luau src/shared/core/RateLimiter.luau src/shared/core/DamageQueue.luau tests
git commit -m "feat: add server-authoritative fire and damage services with rate limiting"
```

---

### Task 11: RoundService (tur akışı ve seviye geçişi)

**Files:**
- Create: `src/server/RoundService.luau`
- Modify: `src/server/init.server.luau`

**Interfaces:**
- Consumes: `Levels`, `LevelState`, `BuildService`, `FireService`, `Remotes.LevelStateChanged`.
- Produces:
  - `RoundService.startLevel(index: number) -> ()`
  - `RoundService.currentLevel() -> number`
  - `RoundService.onStateChanged(fn)` — istemciye yayın için.
  - `LevelStateChanged` payload: `{ phase, levelId, birdsLeft, targetsLeft, score, stars }`

- [ ] **Step 1: Implement `RoundService.luau`**

Akış: `startLevel(index)` → `BuildService.cleanup` → `BuildService.build` → `LevelState.new` → `LevelStateChanged:FireAllClients`. `Heartbeat`'te `levelState.phase == "settling"` ise `settleTick(dt, enHızlıParçaHızı)` çağrılır (en hızlı hız `workspace:GetPartBoundsInBox` yerine, `container:GetDescendants()` üzerinden `AssemblyLinearVelocity.Magnitude` maksimumu). Faz değişirse yayınlanır. `"won"` olunca skor ve yıldız hesaplanıp yayınlanır; `"lost"` olunca yalnızca faz yayınlanır.

- [ ] **Step 2: Verify by structure check**

Run: `node tools/test.mjs && node tools/verify-structure.mjs`
Expected: yeşil; `RoundService` `src/server` altında olduğu için yasaklı global kontrolüne girmez.

- [ ] **Step 3: Commit**

```bash
npx stylua src tests
git add src/server/RoundService.luau src/server/init.server.luau
git commit -m "feat: add round service driving level lifecycle"
```

---

### Task 12: İstemci — sapan kontrolü, kamera, yörünge önizlemesi, HUD

**Files:**
- Create: `src/client/SlingshotController.luau`
- Create: `src/client/CameraRig.luau`
- Create: `src/client/TrajectoryPreview.luau`
- Create: `src/client/Hud.luau`
- Modify: `src/client/init.client.luau`
- Create: `src/shared/core/Trajectory.luau`
- Test: `tests/Trajectory.spec.luau`

**Interfaces:**
- Consumes: `AimModel`, `Kinematics`, `GameConfig`, `Remotes`, `Levels`.
- Produces:
  - `Trajectory.sample(velocity: Vec3, gravity: number, steps: number, dt: number) -> { Vec3 }`
  - `Trajectory.apex(velocity: Vec3, gravity: number) -> Vec3`
  - `SlingshotController.start()`, `:stop()`
  - `TrajectoryPreview.show(origin: Vec3, velocity: Vec3)`, `:hide()`
  - `CameraRig.aimMode()`, `CameraRig.followMode(target)`, `CameraRig.orbitMode()`
  - `Hud.setBirds(n)`, `Hud.setScore(n)`, `Hud.showResult(payload)`, `Hud.hideResult()`

- [ ] **Step 1: Write the failing test**

`tests/Trajectory.spec.luau`:

```lua
return function(T)
	local Trajectory = T.require("Trajectory")

	T.describe("Trajectory.sample", function()
		T.it("ilk nokta baslangictir", function()
			local points = Trajectory.sample({ x = 0, y = 10, z = 0 }, 196.2, 3, 0.1)
			T.expect(#points):toBe(3)
			T.expect(points[1].y):toBe(0)
		end)

		T.it("noktalar dusmeye baslar", function()
			local points = Trajectory.sample({ x = 0, y = 0, z = 0 }, 196.2, 4, 0.25)
			T.expect(points[2].y < points[1].y):toBeTrue()
			T.expect(points[4].y < points[2].y):toBeTrue()
		end)

		T.it("yatay ilerleme orantili", function()
			local points = Trajectory.sample({ x = 100, y = 0, z = 0 }, 196.2, 3, 0.5)
			T.expect(points[2].x):toBeCloseTo(50, 1e-6)
			T.expect(points[3].x):toBeCloseTo(100, 1e-6)
		end)
	end)

	T.describe("Trajectory.apex", function()
		T.it("tepe noktasi dogru yukseklikte", function()
			local p = Trajectory.apex({ x = 0, y = 100, z = 0 }, 196.2)
			T.expect(p.y):toBeCloseTo(25.484, 1e-3)
		end)

		T.it("asagi yonlu hiz icin tepe sifirdir", function()
			T.expect(Trajectory.apex({ x = 0, y = -10, z = 0 }, 196.2).y):toBe(0)
		end)
	end)
end
```

- [ ] **Step 2: Run test to verify it fails**

Run: `node tools/test.mjs Trajectory`
Expected: FAIL — `modul bulunamadi: Trajectory`

- [ ] **Step 3: Implement `Trajectory.luau`**

`sample`, `Kinematics.positionAt`'i `i*dt` için çağırır (düz vektör döner). `apex`, `t = vy/g` (negatifse `0`) ve o `t`'deki konumu döndürür.

- [ ] **Step 4: Run test to verify it passes**

Run: `node tools/test.mjs Trajectory`
Expected: `PASS 5 FAIL 0`

- [ ] **Step 5: Implement `SlingshotController.luau`**

`ContextActionService:BindAction("FlockfallAim", handler, false, Enum.UserInputType.MouseButton1, Enum.UserInputType.Touch, Enum.KeyCode.ButtonA)`. `Begin`'de `Mouse.Hit`/`input.Position` ile sapan çevresinde raycast; isabet sapan bölgesindeyse nişan modu açılır, değilse kamera yörüngesine devredilir. `Change`'te dünya düzlemine projeksiyonla `pull` vektörü hesaplanır, `AimModel.evaluate(pull, GameConfig)` ile önizleme güncellenir. `End`'de kabul edildiyse `FireRequest:FireServer(power, yaw, pitch)`, ardından kamera takip moduna geçer.

- [ ] **Step 6: Implement `CameraRig.luau` and `TrajectoryPreview.luau`**

`CameraRig` `Scriptable` kamera kullanır ve `RunService:BindToRenderStep("FlockfallCamera", Enum.RenderPriority.Camera.Value + 1, …)` ile günceller; üç mod arasında `TweenService` ile geçer. `TrajectoryPreview`, 24 adet küçük `Part` (pooled) ile noktaları gösterir; `CanCollide = false`, `CanQuery = false`, `Anchored = true`; renk `Color3.fromRGB(255, 255, 255)`, şeffaflık mesafeye göre artar.

- [ ] **Step 7: Implement `Hud.luau`**

`ScreenGui` kodla kurulur (Studio'da elle tasarım yok — sürüm kontrolü kolaylığı). Tüm boyutlar `UDim2.fromScale`. Kuş sayacı sol üst, skor sağ üst, sonuç paneli ortalı ve `UIAspectRatioConstraint` ile. Sonuç panelinde yıldız sayısı `Label` metni olarak (`"★"` tekrarı) gösterilir.

- [ ] **Step 8: Wire `init.client.luau`**

Sırayla: `Remotes.ensure` beklenir, `Hud` kurulur, `CameraRig` ve `SlingshotController` başlatılır, `LevelStateChanged` ve `DamageEvent` dinlenir.

- [ ] **Step 9: Verify**

Run: `node tools/test.mjs && node tools/verify-structure.mjs && npx stylua --check src tests`
Expected: tümü yeşil

- [ ] **Step 10: Commit**

```bash
git add src/client src/shared/core/Trajectory.luau tests/Trajectory.spec.luau
git commit -m "feat: add client slingshot input, camera rig, trajectory preview and HUD"
```

---

### Task 13: Dokümantasyon ve son doğrulama

**Files:**
- Create: `README.md` (üzerine yaz), `docs/ASSETS.md`, `docs/PLAYTEST.md`
- Modify: `tools/verify-structure.mjs` (yasaklı isim taramasını genişlet)

**Interfaces:**
- Consumes: tüm önceki görevler.
- Produces: çalıştırma talimatları, varlık kayıt defteri, elle test kontrol listesi.

- [ ] **Step 1: Write `README.md`**

Bölümler: proje nedir, IP politikası özeti, gereksinimler (Node 22, Roblox Studio), `npm install`, `npm test`, Studio'da açma (Rojo eklentisi + `rojo serve`), oynama kontrolleri (fare/sürükleme, dokunma, gamepad), seviye listesi, klasör haritası.

- [ ] **Step 2: Write `docs/ASSETS.md`**

Boş varlık tablosu + "prototipte tüm görseller ve sesler kodla üretilir; tablo bilinçli olarak boştur" notu + gelecekte varlık ekleme kuralları (spec §1.5).

- [ ] **Step 3: Write `docs/PLAYTEST.md`**

Studio'da elle doğrulanacak 12 madde: fare ile nişan, dokunma ile nişan, gamepad ile nişan, ölü bölge, güç sınırı, yörünge önizlemesi gerçek uçuşla uyuşuyor mu, çarpma hasarı, Glass kolay kırılıyor, Metal kırılmıyor, Tinhead ölümü + skor, seviye kazanma, kuş bitince kaybetme, yeniden dene, sonraki seviye, mobil HUD okunabilirliği.

- [ ] **Step 4: Extend `verify-structure.mjs`**

`BANNED_TERMS` listesine spec §1.2'deki adları ekle; tarama `src/`, `docs/`, `README.md` üzerinde büyük/küçük harf duyarsız yapılır. `docs/ASSETS.md` ve spec dosyası taranmaz (politika metni bu adları örnek olarak içerir) — `ALLOWLIST` bunu açar.

- [ ] **Step 5: Run full verification**

Run: `npm test && node tools/verify-structure.mjs && npx stylua --check src tests`
Expected: `PASS <n> FAIL 0`, `yapi dogrulandi: <n> dosya`, stylua çıktısız (temiz)

- [ ] **Step 6: Commit**

```bash
git add README.md docs tools/verify-structure.mjs
git commit -m "docs: add readme, asset ledger and studio playtest checklist"
```

---

## Kapsam Dışı Bırakılanlar (bilinçli)

Çok oyunculu, DataStore, monetizasyon, ses kaydı, düşman yapay zekâsı, seviye editörü — spec §2.2. Bunlar için görev yoktur; eklenmesi gerekiyorsa ayrı bir plan açılır.
