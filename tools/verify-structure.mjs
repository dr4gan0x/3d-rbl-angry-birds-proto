// Yapi dogrulayicisi.
//
// (a) default.project.json gecerli JSON ve beklenen kokleri iceriyor mu,
// (b) src/ altindaki her .luau dosyasi bir kok eslemesinin altinda mi,
// (c) src/shared/core/** Roblox globali icermiyor mu (katman kurali),
// (d) yasakli IP adlari kodda gecmiyor mu (spec §1.2).

import fs from "node:fs";
import path from "node:path";

const ROOT = process.cwd();
const failures = [];

function fail(message) {
	failures.push(message);
}

function walk(dir, out = []) {
	if (!fs.existsSync(dir)) return out;
	for (const entry of fs.readdirSync(dir, { withFileTypes: true }).sort((a, b) => a.name.localeCompare(b.name))) {
		const full = path.join(dir, entry.name);
		if (entry.isDirectory()) walk(full, out);
		else out.push(full);
	}
	return out;
}

// (a) Proje dosyasi
const projectPath = path.join(ROOT, "default.project.json");
let project = null;
try {
	project = JSON.parse(fs.readFileSync(projectPath, "utf8"));
} catch (err) {
	fail(`default.project.json okunamadi: ${err.message}`);
}

if (project !== null) {
	const tree = project.tree ?? {};
	const required = [
		["ReplicatedStorage", "Shared"],
		["ServerScriptService", "Server"],
		["StarterPlayer", "StarterPlayerScripts", "Client"],
	];
	for (const chain of required) {
		let node = tree;
		for (const key of chain) {
			node = node?.[key];
			if (node === undefined) {
				fail(`default.project.json: eksik esleme ${chain.join(".")}`);
				break;
			}
		}
	}
}

// (b) Her .luau dosyasi bir eslemenin altinda mi
const mappedRoots = [
	path.join("src", "shared"),
	path.join("src", "server"),
	path.join("src", "client"),
	path.join("src", "shared", "testkit"),
];
const sourceFiles = walk(path.join(ROOT, "src")).filter((file) => file.endsWith(".luau"));
for (const file of sourceFiles) {
	const relative = path.relative(ROOT, file);
	if (!mappedRoots.some((root) => relative.startsWith(root))) {
		fail(`eslenmemis dosya: ${relative}`);
	}
}

// (c) Katman kurali: core/ icinde Roblox globali yasak
const CORE_FORBIDDEN = [
	/\bgame\./,
	/\bworkspace\b/,
	/\bInstance\.new\b/,
	/\bVector3\b/,
	/\bCFrame\b/,
	/\btask\./,
	/\bwait\s*\(/,
	/\bscript\./,
	/\bTweenService\b/,
	/\bDebris\b/,
	/\bRunService\b/,
];
const coreFiles = sourceFiles.filter((file) => path.relative(ROOT, file).startsWith(path.join("src", "shared", "core")));
for (const file of coreFiles) {
	const relative = path.relative(ROOT, file);
	const source = fs.readFileSync(file, "utf8");
	// Yorumlari ve string literallerini kabaca ayikla: satir basindaki -- sonrasi
	const lines = source.split("\n");
	for (let i = 0; i < lines.length; i += 1) {
		const line = lines[i];
		const code = line.split("--")[0];
		if (code.trim() === "") continue;
		for (const pattern of CORE_FORBIDDEN) {
			if (pattern.test(code)) {
				fail(`core katmani Roblox globali iceriyor: ${relative}:${i + 1} (${pattern})`);
			}
		}
	}
}

// (d) Yasakli IP adlari
const BANNED_TERMS = [
	"angry birds",
	"angrybirds",
	"rovio",
	"bad piggies",
	"chuck",
	"matilda",
	"terence",
	"bubbles",
	"leonard",
	"minion pig",
	"king pig",
];
// Politika metinleri bu adlari ornek olarak icerebilir.
const ALLOWLIST = [
	path.join("docs", "superpowers", "specs"),
	path.join("docs", "superpowers", "plans"),
	path.join("docs", "ASSETS.md"),
	path.join("docs", "PLAYTEST.md"),
	"Skills",
];
const scannedText = [
	...sourceFiles,
	...walk(path.join(ROOT, "docs")).filter((file) => file.endsWith(".md")),
	path.join(ROOT, "README.md"),
].filter((file) => fs.existsSync(file));

for (const file of scannedText) {
	const relative = path.relative(ROOT, file);
	if (ALLOWLIST.some((allowed) => relative.startsWith(allowed))) continue;
	const source = fs.readFileSync(file, "utf8").toLowerCase();
	for (const term of BANNED_TERMS) {
		if (source.includes(term)) {
			fail(`yasakli IP terimi "${term}": ${relative}`);
		}
	}
}

if (failures.length > 0) {
	console.error("YAPI DOGRULAMASI BASARISIZ:");
	for (const message of failures) {
		console.error("  - " + message);
	}
	process.exit(1);
}

console.log(`yapi dogrulandi: ${sourceFiles.length} luau dosyasi, ${coreFiles.length} core dosyasi`);
