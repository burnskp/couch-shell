import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { cp, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

for (const fails of [false, true, "start"]) {
	test(`service logout cancels helpers and ${fails === "start" ? "reports helper startup failure" : fails ? "reports removal failure" : "clears account"}`, {
		timeout: 10000,
	}, async (t) => {
		const dir = await mkdtemp(join(tmpdir(), "couch-service-"));
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
			(await readFile("tests/smoke/auth.qml", "utf8")).replaceAll(
				'"../../',
				'"./',
			),
		);
		const helper = join(dir, "helper");
		await writeFile(
			helper,
			`#!${process.execPath}
import {existsSync, writeFileSync, unlinkSync} from 'node:fs';
const emit = event => console.log(JSON.stringify(event));
const command = process.argv[2];
if (command === 'status' && !existsSync(process.env.COUCH_TEST_STATUS_MARKER)) {
    writeFileSync(process.env.COUCH_TEST_STATUS_MARKER, '1');
    emit({type:'status', configured:true, accountId:'original'});
} else if (command === 'logout') {
    setTimeout(() => {
        if (process.env.COUCH_TEST_REMOVE_FAIL === '1') {
            emit({type:'error', message:'removal denied'}); process.exitCode=1;
        } else emit({type:'logout_complete'});
    }, 400);
} else {
    if (command === 'status' && process.env.COUCH_TEST_REMOVE_FAIL === 'start') setTimeout(() => unlinkSync(process.argv[1]), 50);
    const timer = setInterval(() => {}, 1000);
    process.on('SIGTERM', () => {
        emit({type:'text_delta', delta:'late'});
        emit({type:'models', models:[{model:'late'}]});
        emit({type:'status', configured:true, accountId:'late'});
        console.error('late stderr');
        clearInterval(timer);
    });
}
`,
			{ mode: 0o700 },
		);
		const config = join(dir, "services/ShellConfig.qml");
		await writeFile(
			config,
			(await readFile(config, "utf8")).replace("__AI_CODEX_HELPER__", helper),
		);
		const history = join(dir, "ai-state.json");
		await writeFile(history, '{"sessions":[{"id":"preserved"}]}');
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
					COUCH_TEST_REMOVE_FAIL:
						fails === "start" ? "start" : fails ? "1" : "0",
					COUCH_TEST_STATUS_MARKER: join(dir, "status"),
					COUCH_SHELL_AI_STATE_FILE: history,
				},
				stdio: ["ignore", "pipe", "pipe"],
			},
		);
		t.after(() => {
			if (child.exitCode === null) child.kill("SIGKILL");
		});
		let output = "";
		child.stdout.on("data", (chunk) => (output += chunk));
		child.stderr.on("data", (chunk) => (output += chunk));
		const [exit] = await once(child, "exit");
		assert.equal(exit, 0, output);
		assert.match(output, /AUTH_OK/);
		assert.doesNotMatch(output, /AUTH_FAILURE/);
		assert.equal(
			await readFile(history, "utf8"),
			'{"sessions":[{"id":"preserved"}]}',
		);
	});
}
