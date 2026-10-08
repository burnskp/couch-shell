import assert from "node:assert/strict";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { cp, mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";

test("real shell Markdown streams without requests and copies literal code", {
	timeout: 15000,
}, async (t) => {
	const dir = await mkdtemp(join(tmpdir(), "couch-markdown-"));
	t.after(() => rm(dir, { recursive: true, force: true }));
	for (const path of [
		"services",
		"modules",
		"components",
		"animations",
		"theme",
		"ui",
		"lib",
		"tools",
	])
		await cp(path, join(dir, path), { recursive: true });
	await writeFile(
		join(dir, "smoke.qml"),
		(await readFile("tests/smoke/markdown.qml", "utf8")).replaceAll(
			'"../../',
			'"./',
		),
	);
	let requests = 0;
	const server = createServer((_req, res) => {
		requests++;
		res.end();
	});
	server.listen(0, "127.0.0.1");
	await once(server, "listening");
	t.after(() => server.close());
	const copied = join(dir, "copied");
	const code =
		'printf "%s" "$HOME"; echo `literal`\n![literal](file:///secret)';
	await writeFile(
		join(dir, "wl-copy"),
		`#!${process.execPath}\nimport {writeFileSync} from 'node:fs';\nlet text=''; for await (const chunk of process.stdin) text+=chunk; writeFileSync(process.env.COUCH_COPY_DEST, text);\n`,
		{ mode: 0o700 },
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
				PATH: `${dir}:${process.env.PATH}`,
				COUCH_SHELL_AUTH_FILE: join(dir, "auth.json"),
				COUCH_MARKDOWN_URL: `http://127.0.0.1:${server.address().port}/image`,
				COUCH_COPY_DEST: copied,
				COUCH_COPY_TEXT: code,
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
	assert.match(output, /MARKDOWN_OK/);
	assert.doesNotMatch(output, /MARKDOWN_FAILURE/);
	assert.equal(requests, 0);
	assert.equal(await readFile(copied, "utf8"), code);
});
