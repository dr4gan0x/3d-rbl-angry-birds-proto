import { Lua } from "@luau-rs/luau";
import fs from "node:fs";
import path from "node:path";

function walk(dir, out = []) {
	for (const e of fs.readdirSync(dir, { withFileTypes: true }).sort((a,b)=>a.name.localeCompare(b.name))) {
		const p = path.join(dir, e.name);
		if (e.isDirectory()) walk(p, out); else if (p.endsWith(".luau")) out.push(p);
	}
	return out;
}

const lua = await Lua.create({ sandbox: true });
const files = walk("src");
let bad = 0;
for (const f of files) {
	const src = fs.readFileSync(f, "utf8").replace(/^--!strict\s*$/m, "");
	// Parse only: wrap in a function so top-level `return` is legal.
	const chunk = `local __f = function()\n${src}\nend\nreturn __f`;
	try {
		lua.execute(chunk);
		console.log(`OK   ${f}`);
	} catch (e) {
		bad++;
		console.log(`FAIL ${f}\n     ${String(e.message).split("\n")[0].slice(0,140)}`);
	}
}
console.log(`\n${files.length - bad}/${files.length} derlendi`);
process.exit(bad === 0 ? 0 : 1);
