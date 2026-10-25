import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { cp, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

test("shared usage lifecycle, reset refresh, failures, account changes and cancellation", {
	timeout: 15000,
}, async (t) => {
	const dir = await mkdtemp(join(tmpdir(), "couch-usage-service-"));
	t.after(() => rm(dir, { recursive: true, force: true }));
	for (const path of [
		"services",
		"modules",
		"components",
		"animations",
		"theme",
		"ui",
		"lib",
	])
		await cp(path, join(dir, path), { recursive: true });
	await writeFile(
		join(dir, "smoke.qml"),
		(await readFile("tests/smoke/usage.qml", "utf8")).replaceAll(
			'"../../',
			'"./',
		),
	);
	const helper = join(dir, "helper");
	await writeFile(
		helper,
		`#!${process.execPath}
import { existsSync, readFileSync, writeFileSync } from 'node:fs';
const emit = value => console.log(JSON.stringify(value));
const command = process.argv[2];
if (command === 'status') emit({type:'status', configured:true, accountId:'original'});
else if (command === 'usage') {
    const file = process.env.COUCH_USAGE_COUNT;
    const count = existsSync(file) ? Number(readFileSync(file, 'utf8')) + 1 : 1;
    writeFileSync(file, String(count));
    const report = () => emit({type:'usage', provider:{id:'openai-codex', name:'ChatGPT', plan:'plus', updatedAt:Date.now(), windows:[{id:'primary_window', remainingPercent:count === 1 ? 0 : 70, durationSeconds:18000, resetsAt:Date.now() + (count === 1 ? 700 : 600000)}]}});
    if (count === 2 || count === 6) {
        const timer = setInterval(() => {}, 1000);
        process.on('SIGTERM', () => { report(); console.error('late usage stderr'); clearInterval(timer); });
    } else if (count === 5) process.exitCode = 1;
    else setTimeout(report, 100);
} else if (command === 'claude-usage') setTimeout(() => emit({type:'usage', provider:{id:'claude', name:'Claude', plan:'pro', updatedAt:Date.now(), windows:[{id:'five_hour', remainingPercent:40, durationSeconds:18000, resetsAt:Date.now() + 600000}]}}), 100);
else if (command === 'logout') setTimeout(() => emit({type:'logout_complete'}), 100);
`,
		{ mode: 0o700 },
	);
	const config = join(dir, "services/ShellConfig.qml");
	await writeFile(
		config,
		(await readFile(config, "utf8")).replace("__AI_CODEX_HELPER__", helper),
	);
	const child = spawn(
		"quickshell",
		["-p", join(dir, "smoke.qml"), "--no-color"],
		{
			env: {
				...process.env,
				QT_QPA_PLATFORM: "offscreen",
				QSG_RHI_BACKEND: "software",
				QT_QPA_PLATFORMTHEME: "",
				QT_STYLE_OVERRIDE: "",
				COUCH_USAGE_COUNT: join(dir, "count"),
			},
			stdio: ["ignore", "pipe", "pipe"],
		},
	);
	t.after(() => {
		if (child.exitCode === null) child.kill("SIGKILL");
	});
	let output = "";
	child.stdout.on("data", (data) => (output += data));
	child.stderr.on("data", (data) => (output += data));
	const [code] = await once(child, "exit");
	assert.equal(code, 0, output);
	assert.match(output, /USAGE_OK/, output);
	assert.doesNotMatch(
		output,
		/USAGE_FAILURE|ReferenceError|TypeError|Binding loop/,
	);
	assert.equal(await readFile(join(dir, "count"), "utf8"), "6", output);
});
