import assert from "node:assert/strict";
import { fork, spawn } from "node:child_process";
import { once } from "node:events";
import { mkdtemp, readFile, rm, stat, writeFile } from "node:fs/promises";
import { createServer } from "node:http";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { waitForCallback } from "../../tools/couch-ai-codex.mjs";

const helper = fileURLToPath(
	new URL("../../tools/couch-ai-codex.mjs", import.meta.url),
);
const worker = fileURLToPath(new URL("auth-worker.mjs", import.meta.url));
const provider = "openai-codex";
const credentials = {
	type: "oauth",
	access: "fake",
	refresh: "original",
	expires: 0,
};

async function fixture(t) {
	const dir = await mkdtemp(join(tmpdir(), "couch-auth-"));
	t.after(() => rm(dir, { recursive: true, force: true }));
	const path = join(dir, "auth.json");
	await writeFile(
		path,
		JSON.stringify({
			unrelated: { secret: "preserved" },
			[provider]: credentials,
		}),
		{ mode: 0o600 },
	);
	const env = { ...process.env, COUCH_SHELL_AUTH_FILE: path };
	const read = async () => JSON.parse(await readFile(path, "utf8"));
	const run = (command) =>
		new Promise((resolve, reject) => {
			const child = spawn(process.execPath, [helper, command], { env });
			let output = "";
			child.stdout.on("data", (chunk) => (output += chunk));
			child.on("error", reject);
			child.on("exit", (code) => resolve({ code, output }));
		});
	const start = (command, value = "") => {
		const child = fork(worker, [command, value], {
			env,
			stdio: ["ignore", "ignore", "inherit", "ipc"],
		});
		t.after(() => {
			if (child.exitCode === null) child.kill("SIGKILL");
		});
		child.done = once(child, "exit");
		return child;
	};
	return { path, read, run, start };
}

for (const replacement of ["logout", "login"]) {
	test(`delayed refresh cannot overwrite ${replacement}`, async (t) => {
		const f = await fixture(t);
		const child = f.start("refresh");
		assert.equal((await once(child, "message"))[0].ready, true);
		const before = await f.read();
		if (replacement === "logout") assert.equal((await f.run("logout")).code, 0);
		else assert.equal((await f.start("login", "new-login").done)[0], 0);
		child.send("complete exchange");
		assert.equal((await child.done)[0], 1);
		const after = await f.read();
		assert.notEqual(
			after._couchShellAuthGeneration,
			before._couchShellAuthGeneration,
		);
		assert.equal(
			after[provider]?.refresh,
			replacement === "logout" ? undefined : "new-login",
		);
		assert.deepEqual(after.unrelated, { secret: "preserved" });
		assert.equal((await stat(f.path)).mode & 0o777, 0o600);
	});
}

test("legacy migration and refresh retain generation; concurrent writers serialize", async (t) => {
	const f = await fixture(t);
	assert.equal((await f.run("status")).code, 0);
	const generation = (await f.read())._couchShellAuthGeneration;
	assert.equal(typeof generation, "string");
	const first = f.start("refresh");
	await once(first, "message");
	const second = f.start("refresh");
	await once(second, "message");
	first.send("finish");
	assert.equal((await first.done)[0], 0);
	second.send("finish");
	assert.equal((await second.done)[0], 1);
	assert.equal((await f.read())._couchShellAuthGeneration, generation);
	const writers = Array.from({ length: 8 }, (_, i) =>
		f.start("login", `login-${i}`),
	);
	for (const writer of writers) assert.equal((await writer.done)[0], 0);
	const after = await f.read();
	assert.match(after[provider].refresh, /^login-\d$/);
	assert.deepEqual(after.unrelated, { secret: "preserved" });
});

test("lock times out in five seconds and releases on owner termination", async (t) => {
	const f = await fixture(t);
	const holder = f.start("hold");
	await once(holder, "message");
	const started = Date.now();
	const blocked = await f.run("logout");
	assert.equal(blocked.code, 1);
	assert.match(blocked.output, /lock acquisition failed/);
	assert.ok(Date.now() - started >= 4900);
	holder.kill("SIGKILL");
	await holder.done;
	assert.equal((await f.run("logout")).code, 0);
	assert.equal((await f.read())[provider], undefined);
});

async function callbackFlow(options = {}) {
	let ready;
	const listening = new Promise((resolve) => (ready = resolve));
	const completion = waitForCallback("expected", {
		port: 0,
		timeoutMs: 2000,
		onListening: ready,
		...options,
	});
	completion.catch(() => {});
	const address = await listening;
	const base = `http://127.0.0.1:${address.port}`;
	return { completion, base };
}

test("invalid callbacks do not terminate login, followed by valid callback and cleanup", async () => {
	const { completion, base } = await callbackFlow();
	for (const query of [
		"?code=bad",
		"?state=wrong&code=bad",
		"?state=wrong&error=denied",
		"?state=expected",
		"?state=expected&code=%20",
	]) {
		const response = await fetch(`${base}/auth/callback${query}`);
		assert.equal(response.status, 400);
		await response.text();
	}
	assert.equal(
		(await fetch(`${base}/auth/callback?state=expected&code=valid`)).status,
		200,
	);
	assert.deepEqual(await completion, { code: "valid" });
	await assert.rejects(fetch(base));
});

test("matching provider error is terminal and closes listener", async () => {
	const { completion, base } = await callbackFlow();
	assert.equal(
		(await fetch(`${base}/auth/callback?state=expected&error=access_denied`))
			.status,
		400,
	);
	await assert.rejects(completion, /provider rejected/);
	await assert.rejects(fetch(base));
});

test("login timeout closes listener", async () => {
	const { completion, base } = await callbackFlow({ timeoutMs: 80 });
	await assert.rejects(completion, /timed out/);
	await assert.rejects(fetch(base));
});

test("listener startup failures settle and close without advertising login", async (t) => {
	let announced = false;
	await assert.rejects(
		waitForCallback("expected", {
			port: -1,
			onListening: () => (announced = true),
		}),
		/port/i,
	);
	const server = createServer();
	server.listen(0, "127.0.0.1");
	await once(server, "listening");
	t.after(() => server.close());
	await assert.rejects(
		waitForCallback("expected", {
			port: server.address().port,
			onListening: () => (announced = true),
		}),
		/EADDRINUSE/,
	);
	assert.equal(announced, false);
});
