import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { fileURLToPath } from "node:url";
import { promisify } from "node:util";
import { discoverCodexClientVersion } from "../../tools/couch-ai-codex.mjs";

const exec = promisify(execFile);
const helper = fileURLToPath(
	new URL("../../tools/couch-ai-codex.mjs", import.meta.url),
);
const preload = fileURLToPath(
	new URL("model-fetch-fixture.mjs", import.meta.url),
);
const stable = { tag_name: "rust-v0.159.2", draft: false, prerelease: false };

test("discovery requests official release metadata without credentials", async () => {
	const version = await discoverCodexClientVersion({
		fetchImpl: async (url, options) => {
			assert.equal(
				url,
				"https://api.github.com/repos/openai/codex/releases/latest",
			);
			assert.deepEqual(options.headers, {
				accept: "application/vnd.github+json",
				"User-Agent": "couch-shell",
			});
			assert.ok(options.signal instanceof AbortSignal);
			return Response.json(stable);
		},
	});
	assert.equal(version, "0.159.2");
});

for (const [name, response] of [
	["rate limit", () => new Response("rate limited", { status: 403 })],
	["server error", () => new Response("unavailable", { status: 503 })],
	["invalid JSON", () => new Response("invalid")],
	...[
		null,
		{},
		{ ...stable, draft: true },
		{ ...stable, prerelease: true },
		{ ...stable, tag_name: "rust-v0.160.0-alpha.1" },
		{ ...stable, tag_name: "rust-v01.2.3" },
		{ ...stable, tag_name: "v0.159.2" },
		{ ...stable, tag_name: ["rust-v0.159.2"] },
	].map((body, i) => [`invalid metadata ${i}`, () => Response.json(body)]),
]) {
	test(`discovery rejects ${name}`, async () => {
		await assert.rejects(
			discoverCodexClientVersion({ fetchImpl: async () => response() }),
			/Codex release discovery failed/,
		);
	});
}

test("discovery times out without falling back", async () => {
	await assert.rejects(
		discoverCodexClientVersion({
			timeoutMs: 10,
			fetchImpl: (_url, { signal }) =>
				new Promise((_resolve, reject) =>
					signal.addEventListener("abort", () => reject(signal.reason), {
						once: true,
					}),
				),
		}),
		/Codex release discovery failed: request timed out/,
	);
});

async function fixture(t, cache, network = { catalog: {} }) {
	const dir = await mkdtemp(join(tmpdir(), "couch-models-"));
	t.after(() => rm(dir, { recursive: true, force: true }));
	const auth = join(dir, "auth.json");
	const models = join(dir, "models.json");
	const log = join(dir, "requests.jsonl");
	await writeFile(
		auth,
		JSON.stringify({
			"openai-codex": {
				type: "oauth",
				access: "fake",
				refresh: "fake",
				accountId: "test",
				expires: Date.now() + 600000,
			},
		}),
	);
	if (cache) await writeFile(models, JSON.stringify(cache));
	const run = async (command = "models-refresh") => {
		try {
			const { stdout } = await exec(
				process.execPath,
				["--import", preload, helper, command],
				{
					env: {
						...process.env,
						COUCH_SHELL_AUTH_FILE: auth,
						COUCH_SHELL_AI_MODELS_FILE: models,
						COUCH_SHELL_CODEX_MODELS_URL:
							"https://models.test/catalog?client_version=0.1.0&custom=yes",
						COUCH_SHELL_CODEX_CLIENT_VERSION: "0.2.0",
						TEST_MODEL_FETCH: JSON.stringify(network),
						TEST_MODEL_REQUEST_LOG: log,
					},
				},
			);
			return { code: 0, event: JSON.parse(stdout) };
		} catch (error) {
			return { code: error.code, event: JSON.parse(error.stdout) };
		}
	};
	return {
		run,
		read: () => readFile(models, "utf8"),
		requests: async () => {
			try {
				return (await readFile(log, "utf8")).trim().split("\n").map(JSON.parse);
			} catch (error) {
				if (error.code === "ENOENT") return [];
				throw error;
			}
		},
	};
}
const oldCache = {
	version: 1,
	updatedAt: 1,
	etag: "old-etag",
	models: [{ model: "old-model" }],
};

for (const clientVersion of [undefined, "0.144.1", "0.159.2"]) {
	test(`refresh caches discovered version and scopes ETag (previous ${clientVersion})`, async (t) => {
		const f = await fixture(t, { ...oldCache, clientVersion });
		const result = await f.run();
		assert.equal(result.code, 0, result.event.message);
		assert.equal(result.event.source, "remote");
		assert.equal(result.event.models[0].model, "new-model");
		const [discovery, catalog] = await f.requests();
		assert.equal(discovery.authenticated, false);
		assert.equal(catalog.version, "0.159.2");
		assert.equal(
			new URL(catalog.url).searchParams.get("client_version"),
			"0.159.2",
		);
		assert.equal(new URL(catalog.url).searchParams.get("custom"), "yes");
		assert.equal(
			catalog.etag,
			clientVersion === "0.159.2" ? "old-etag" : undefined,
		);
		const saved = JSON.parse(await f.read());
		assert.equal(saved.clientVersion, "0.159.2");
		assert.equal(saved.etag, "new-etag");
		assert.ok(saved.updatedAt > 1);
	});
}

test("matching-version 304 retains models and updates timestamp", async (t) => {
	const f = await fixture(
		t,
		{ ...oldCache, clientVersion: "0.159.2" },
		{ catalog: { status: 304 } },
	);
	const result = await f.run();
	assert.equal(result.code, 0, result.event.message);
	assert.equal(result.event.source, "cache");
	assert.equal(result.event.models[0].model, "old-model");
	const saved = JSON.parse(await f.read());
	assert.equal(saved.etag, "old-etag");
	assert.equal(saved.clientVersion, "0.159.2");
	assert.ok(saved.updatedAt > 1);
});

for (const [name, network, cache] of [
	["discovery failure", { releaseStatus: 403 }, oldCache],
	["catalog failure", { catalog: { status: 503 } }, oldCache],
	["empty catalog", { catalog: { body: { models: [] } } }, oldCache],
	["unsolicited 304", { catalog: { status: 304 } }, oldCache],
	[
		"304 with no cached models",
		{ catalog: { status: 304 } },
		{ ...oldCache, clientVersion: "0.159.2", models: [] },
	],
]) {
	test(`${name} preserves cache and emits error`, async (t) => {
		const f = await fixture(t, cache, network);
		const before = await f.read();
		const result = await f.run();
		assert.notEqual(result.code, 0);
		assert.equal(result.event.type, "error");
		assert.match(
			result.event.message,
			name === "discovery failure"
				? /release discovery failed/
				: /model catalog refresh failed/,
		);
		assert.equal(await f.read(), before);
		if (name === "discovery failure")
			assert.equal((await f.requests()).length, 1);
	});
}

test("legacy cache loads offline", async (t) => {
	const f = await fixture(t, oldCache, { releaseStatus: 503 });
	const result = await f.run("models-load");
	assert.equal(result.code, 0, result.event.message);
	assert.equal(result.event.models[0].model, "old-model");
	assert.deepEqual(await f.requests(), []);
});

test("first refresh creates versioned cache", async (t) => {
	const f = await fixture(t);
	assert.equal((await f.run()).code, 0);
	assert.equal(JSON.parse(await f.read()).clientVersion, "0.159.2");
	assert.equal((await f.requests())[1].etag, undefined);
});

test("each refresh requires live discovery even with a successful cached version", async (t) => {
	const network = { catalog: {} };
	const f = await fixture(t, oldCache, network);
	assert.equal((await f.run()).code, 0);
	const before = await f.read();
	network.releaseStatus = 403;
	const result = await f.run();
	assert.notEqual(result.code, 0);
	assert.match(result.event.message, /release discovery failed/);
	assert.equal(await f.read(), before);
	assert.deepEqual(
		(await f.requests()).map((r) => r.discovery),
		[true, false, true],
	);
});

test("first-use discovery failure does not create a model cache", async (t) => {
	const f = await fixture(t, undefined, { releaseStatus: 503 });
	assert.notEqual((await f.run()).code, 0);
	await assert.rejects(f.read(), { code: "ENOENT" });
	assert.equal((await f.requests()).length, 1);
});
