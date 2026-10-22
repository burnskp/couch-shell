import assert from "node:assert/strict";
import { execFile } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import test from "node:test";
import { promisify } from "node:util";
import {
	fetchSubscriptionUsage,
	normalizeSubscriptionUsage,
	subscriptionUsageUrl,
} from "../../tools/couch-ai-codex.mjs";

const window = {
	used_percent: 25.5,
	limit_window_seconds: 18000,
	reset_at: 2000,
};
const body = {
	plan_type: "plus",
	rate_limit: {
		primary_window: window,
		secondary_window: {
			...window,
			used_percent: 100,
			limit_window_seconds: 604800,
		},
	},
};
const credentials = { access: "secret-token", accountId: "test-account" };

test("normalizes quota windows, fractional usage, durations and epoch units", () => {
	const usage = normalizeSubscriptionUsage(body, 1000);
	assert.equal(usage.id, "openai-codex");
	assert.equal(usage.plan, "plus");
	assert.equal(usage.updatedAt, 1000);
	assert.deepEqual(
		usage.windows.map((w) => w.remainingPercent),
		[74.5, 0],
	);
	assert.equal(usage.windows[0].resetsAt, 2000000);
	assert.equal(usage.windows[1].durationSeconds, 604800);
});

test("handles single windows, relative resets, overage and unavailable metadata", () => {
	const usage = normalizeSubscriptionUsage(
		{
			rate_limit: {
				secondary_window: { used_percent: 120, reset_after_seconds: 60 },
			},
		},
		1000,
	);
	assert.deepEqual(usage.windows[0], {
		id: "secondary_window",
		remainingPercent: 0,
		durationSeconds: null,
		resetsAt: 61000,
	});
	assert.equal(
		normalizeSubscriptionUsage({
			rate_limit: { primary_window: { used_percent: 0 } },
		}).windows[0].resetsAt,
		null,
	);
});

for (const invalid of [
	undefined,
	{},
	{ rate_limit: {} },
	...[null, "20", -1, NaN, Infinity].map((used_percent) => ({
		rate_limit: { primary_window: { used_percent } },
	})),
]) {
	test(`rejects unavailable/invalid quota ${JSON.stringify(invalid)}`, () => {
		assert.throws(() => normalizeSubscriptionUsage(invalid));
	});
}

test("usage URL honors the existing backend base variants", () => {
	for (const suffix of [
		"",
		"/",
		"/codex",
		"/codex/responses",
		"/codex/models/",
	])
		assert.equal(
			subscriptionUsageUrl("https://example.test/backend-api" + suffix),
			"https://example.test/backend-api/wham/usage",
		);
});

test("sends credentials only in headers and returns normalized data", async () => {
	const result = await fetchSubscriptionUsage(credentials, {
		fetchImpl: async (url, options) => {
			assert.equal(url, "https://chatgpt.com/backend-api/wham/usage");
			assert.equal(options.headers.Authorization, "Bearer secret-token");
			assert.equal(options.headers["chatgpt-account-id"], "test-account");
			return Response.json(body);
		},
	});
	assert.equal(result.provider.windows.length, 2);
	assert.doesNotMatch(JSON.stringify(result), /secret-token/);
});

for (const status of [401, 403, 429, 500]) {
	test(`HTTP ${status} never includes response secrets`, async () => {
		const result = await fetchSubscriptionUsage(credentials, {
			fetchImpl: async () => new Response("secret-token", { status }),
		});
		assert.equal(result.unauthorized, status === 401);
		assert.match(result.error, new RegExp(String(status)));
		assert.doesNotMatch(JSON.stringify(result), /secret-token/);
	});
}

test("malformed JSON and network errors are sanitized", async () => {
	for (const fetchImpl of [
		async () => new Response("secret-token"),
		async () => {
			throw new Error("secret-token");
		},
	])
		assert.deepEqual(await fetchSubscriptionUsage(credentials, { fetchImpl }), {
			error: "Subscription usage unavailable",
		});
});

test("timeout aborts the request", async () => {
	const result = await fetchSubscriptionUsage(credentials, {
		timeoutMs: 5,
		fetchImpl: (_, { signal }) =>
			new Promise((_, reject) => {
				signal.addEventListener("abort", () => reject(signal.reason), {
					once: true,
				});
			}),
	});
	assert.equal(result.error, "Usage request timed out");
});

test("usage command refreshes expired credentials and retries a rejected token once", async (t) => {
	const dir = await mkdtemp(join(tmpdir(), "couch-usage-"));
	t.after(() => rm(dir, { recursive: true, force: true }));
	const auth = join(dir, "auth.json");
	const preload = join(dir, "fetch.mjs");
	await writeFile(
		auth,
		JSON.stringify({
			"openai-codex": {
				type: "oauth",
				access: "expired-secret",
				refresh: "refresh-secret",
				expires: 0,
				accountId: "test-account",
			},
		}),
	);
	await writeFile(
		preload,
		`
let tokens = 0, usages = 0;
const token = n => 'fresh-secret-' + n + '.' + Buffer.from(JSON.stringify({'https://api.openai.com/auth': {chatgpt_account_id:'test-account'}})).toString('base64url') + '.signature';
globalThis.fetch = async (url, options) => {
    if (url === 'https://auth.openai.com/oauth/token') {
        tokens++;
        return Response.json({ access_token: token(tokens), refresh_token: 'rotated-secret-' + tokens, expires_in: 3600 });
    }
    if (url.endsWith('/wham/usage')) {
        usages++;
        if (usages === 1) return new Response('private body', { status: 401 });
        if (tokens !== 2 || options.headers.Authorization !== 'Bearer ' + token(2)) throw new Error('unexpected credentials');
        return Response.json(${JSON.stringify(body)});
    }
    throw new Error('Unexpected network request');
};`,
	);
	const { stdout } = await promisify(execFile)(
		process.execPath,
		["--import", preload, "tools/couch-ai-codex.mjs", "usage"],
		{ env: { ...process.env, COUCH_SHELL_AUTH_FILE: auth } },
	);
	assert.equal(JSON.parse(stdout).type, "usage");
	assert.doesNotMatch(stdout, /secret|private body/);
	const saved = JSON.parse(await readFile(auth, "utf8"));
	assert.match(saved["openai-codex"].access, /^fresh-secret-2\./);
});
