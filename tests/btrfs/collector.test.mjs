import assert from "node:assert/strict";
import { mkdtemp, readdir, readFile, rm, writeFile } from "node:fs/promises";
import net from "node:net";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { test } from "node:test";
import {
	accounting,
	collect,
	markMounted,
	parseSubvolumes,
	runCommand,
} from "../../tools/btrfs/collector.mjs";
import { createServer, loadCache, publish } from "../../tools/btrfs/server.mjs";

const ok = (stdout) => ({ code: 0, stdout, stderr: "" });
const uuid = "11111111-1111-1111-1111-111111111111";
const rows = [
	{ id: 256, path: "<FS_TREE>/root", uuid: "root", parent_uuid: null },
	{ id: 257, path: "<FS_TREE>/persist", uuid: "persist", parent_uuid: null },
	{
		id: 258,
		path: "<FS_TREE>/snapshots/root-1",
		uuid: "snapshot",
		parent_uuid: "root",
	},
	{
		id: 259,
		path: '<FS_TREE>/spaces "quotes" \\ slash\nand newline',
		uuid: "odd",
		parent_uuid: null,
	},
	{ id: 260, path: "<FS_TREE>/orphan", uuid: "orphan", parent_uuid: "deleted" },
];
const subvolumes = JSON.stringify({ "subvolume-list": rows });
const qgroups =
	"qgroupid rfer excl\n-------- ---- ----\n0/5 16384 16384\n0/256 100 50\n0/257 200 100\n0/258 100 50\n1/999 400 200\n";
const idle = ok("no rescan operation in progress\n");

test("cryptroot aliases, independent filesystems, snapshots, unusual paths, and ID joins", async () => {
	const calls = [];
	const mounts = [
		{
			uuid,
			label: "cryptroot",
			source: "/dev/mapper/cryptroot[/root]",
			target: "/",
			fsroot: "/root",
		},
		{
			uuid,
			label: "cryptroot",
			source: "/dev/mapper/cryptroot[/persist]",
			target: "/persist",
			fsroot: "/persist",
		},
		{
			uuid,
			label: "cryptroot",
			source: "/dev/mapper/cryptroot[/persist]",
			target: "/home",
			fsroot: "/persist/home",
		},
		{
			uuid: "other",
			label: "cryptroot",
			source: "/dev/sdb",
			target: "/other",
			fsroot: "/",
		},
	];
	const report = await collect(new AbortController().signal, {
		run: async (name, args) => {
			calls.push([name, args]);
			if (name === "findmnt")
				return ok(
					JSON.stringify({
						filesystems: args.includes("--list")
							? mounts
							: [{ uuid: args.includes("/other") ? "other" : uuid }],
					}),
				);
			if (args.includes("list")) return ok(subvolumes);
			if (args.includes("show")) return ok(qgroups);
			return idle;
		},
		capacity: async () => ({ availableBytes: 1000, totalBytes: 2000 }),
		quotaMode: async () => "qgroup\n",
	});
	assert.equal(report.filesystems.length, 2);
	assert.equal(calls.filter((c) => c[1].includes("list")).length, 2);
	assert.equal(report.filesystems[0].subvolumes.length, 5);
	assert.deepEqual(
		report.filesystems[0].subvolumes
			.filter((s) => s.mounted)
			.map((s) => s.path),
		["persist", "root"],
	);
	assert.equal(report.filesystems[1].subvolumes.length, 6);
	assert.equal(
		report.filesystems[0].subvolumes.find((s) => s.id === 256).exclusiveBytes,
		50,
	);
	assert.equal(
		report.filesystems[0].subvolumes.find((s) => s.id === 259).path,
		rows[3].path.replace("<FS_TREE>/", ""),
	);
	assert.equal(
		report.filesystems[0].subvolumes.find((s) => s.id === 258).parentUuid,
		"root",
	);
});

test("quota states suppress invalid values", () => {
	for (const [result, mode, rescan, expected] of [
		[ok(qgroups), "qgroup", idle, "valid"],
		[
			{ code: 1, stdout: "", stderr: "ERROR: quotas not enabled" },
			"",
			idle,
			"disabled",
		],
		[ok(qgroups), "squota", idle, "simple"],
		[
			{ ...ok(qgroups), stderr: "WARNING: qgroup data inconsistent" },
			"qgroup",
			idle,
			"inconsistent",
		],
		[
			ok(qgroups),
			"qgroup",
			ok("rescan operation running (current key 12)"),
			"scanning",
		],
		[{ code: 1, stdout: "", stderr: "error" }, "qgroup", idle, "unavailable"],
		[ok(qgroups), "", idle, "unavailable"],
	]) {
		const state = accounting(result, mode, rescan);
		assert.equal(state.status, expected);
		assert.equal(state.usage.size > 0, expected === "valid");
	}
});

test("disappearing mount retries alias; partial failures retain capacity", async () => {
	let attempts = 0;
	const dependencies = {
		run: async (name, args) => {
			if (name === "findmnt")
				return ok(
					JSON.stringify({
						filesystems: args.includes("--list")
							? ["/gone", "/live"].map((target) => ({
									uuid,
									target,
									fsroot: "/root",
								}))
							: [{ uuid }],
					}),
				);
			if (args.includes("list")) {
				attempts++;
				return args.includes("/gone") ? { code: 1 } : ok(subvolumes);
			}
			if (args.includes("show"))
				return { code: 1, stdout: "", stderr: "failed" };
			return idle;
		},
		capacity: async () => ({ availableBytes: 1, totalBytes: 2 }),
		quotaMode: async () => "qgroup",
	};
	const report = await collect(new AbortController().signal, dependencies);
	assert.equal(attempts, 2);
	assert.equal(report.filesystems[0].subvolumes.length, 5);
	assert.equal(report.filesystems[0].accounting, "unavailable");
	dependencies.run = async (name, args) =>
		name === "findmnt"
			? ok(
					JSON.stringify({
						filesystems: [{ uuid, target: "/gone", fsroot: "/root" }],
					}),
				)
			: { code: 1 };
	const partial = await collect(new AbortController().signal, dependencies);
	assert.equal(partial.status, "partial");
	assert.equal(partial.filesystems[0].totalBytes, 2);
});

test("empty discovery and invalid subvolume output", async () => {
	const result = await collect(new AbortController().signal, {
		run: async () => ({ code: 1, stdout: "", stderr: "" }),
	});
	assert.deepEqual(result.filesystems, []);
	assert.equal(result.status, "ok");
	assert.throws(() => parseSubvolumes("{}", false));
});

test("subprocess timeout and cancellation are bounded", async () => {
	const result = await runCommand(
		process.execPath,
		["-e", "setTimeout(() => {}, 10000)"],
		undefined,
		20,
	);
	assert.notEqual(result.code, 0);
	const controller = new AbortController();
	const job = runCommand(
		process.execPath,
		["-e", "setTimeout(() => {}, 10000)"],
		controller.signal,
	);
	controller.abort(new Error("cancelled"));
	await assert.rejects(job, /cancelled/);
});

function request(path) {
	return new Promise((resolve, reject) => {
		const socket = net.createConnection(path);
		let data = "";
		socket.on("data", (chunk) => {
			data += chunk;
		});
		socket.on("error", reject);
		socket.on("end", () => {
			try {
				resolve(JSON.parse(data));
			} catch (error) {
				reject(error);
			}
		});
	});
}
async function withServer(t, options) {
	const directory = await mkdtemp(join(tmpdir(), "couch-btrfs-"));
	const cachePath = join(directory, "report.json");
	const path = join(directory, "report.sock");
	const server = createServer({ ...options, cachePath });
	await new Promise((resolve) => server.listen(path, resolve));
	t.after(async () => {
		await new Promise((resolve) => server.close(resolve));
		await rm(directory, { recursive: true, force: true });
	});
	return { path, cachePath, directory };
}
const report = () => ({
	version: 1,
	collectedAt: Date.now(),
	status: "ok",
	filesystems: [],
});
test("socket coalescing, cache, failure backoff, atomic publication", async (t) => {
	let calls = 0;
	let now = 0;
	let release;
	const context = await withServer(t, {
		interval: 100,
		now: () => now,
		collector: async () => {
			calls++;
			if (calls > 1) throw new Error("failed");
			await new Promise((resolve) => {
				release = resolve;
			});
			return report();
		},
	});
	const first = request(context.path);
	const second = request(context.path);
	while (!release) await new Promise((resolve) => setTimeout(resolve, 2));
	release();
	const [a, b] = await Promise.all([first, second]);
	assert.deepEqual(a, b);
	assert.equal(calls, 1);
	assert.deepEqual(await request(context.path), a);
	assert.deepEqual(JSON.parse(await readFile(context.cachePath)), a);
	assert.deepEqual((await readdir(context.directory)).sort(), [
		"report.json",
		"report.sock",
	]);
	now = 101;
	assert.equal((await request(context.path)).status, "unavailable");
	await request(context.path);
	assert.equal(calls, 2);
});

const delay = (ms) => new Promise((resolve) => setTimeout(resolve, ms));
async function until(predicate) {
	for (let i = 0; i < 1000; i++) {
		if (predicate()) return;
		await delay(2);
	}
	throw new Error("Timed out waiting for condition");
}
test("last waiter cancellation retains cache; reconnect during abort waits one second", async (t) => {
	let signal, finishAbort;
	let calls = 0;
	const initial = { ...report(), collectedAt: 0 };
	const context = await withServer(t, {
		initial,
		collector: async (abortSignal) => {
			calls++;
			if (calls > 1) return report();
			signal = abortSignal;
			await new Promise((resolve) => {
				finishAbort = resolve;
			});
			signal.throwIfAborted();
		},
	});
	await publish(context.cachePath, initial);
	const a = net.createConnection(context.path);
	const b = net.createConnection(context.path);
	await Promise.all(
		[a, b].map((s) => new Promise((resolve) => s.on("connect", resolve))),
	);
	await until(() => signal);
	a.destroy();
	await delay(20);
	assert.equal(signal.aborted, false);
	b.destroy();
	await until(() => signal.aborted);
	const reconnect = request(context.path);
	await delay(20);
	assert.equal(calls, 1);
	finishAbort();
	await delay(100);
	assert.deepEqual(JSON.parse(await readFile(context.cachePath)), initial);
	assert.equal(calls, 1);
	const duringCooldown = request(context.path);
	const results = await Promise.all([reconnect, duringCooldown]);
	assert.equal(results[0].status, "ok");
	assert.deepEqual(results[0], results[1]);
	assert.equal(calls, 2);
});

test("cancelled collection does no work without waiters; immediate reconnect retries", async (t) => {
	let calls = 0,
		signal;
	const context = await withServer(t, {
		cancelCooldown: 40,
		collector: async (s) => {
			if (++calls > 1) return report();
			signal = s;
			await new Promise((resolve, reject) =>
				s.addEventListener("abort", () => reject(s.reason), { once: true }),
			);
		},
	});
	const client = net.createConnection(context.path);
	await until(() => signal);
	client.destroy();
	await until(() => signal.aborted);
	await delay(80);
	assert.equal(calls, 1);
	assert.equal((await request(context.path)).status, "ok");
	assert.equal(calls, 2);
});

test("overall timeout returns unavailable; retained data becomes stale", async (t) => {
	const context = await withServer(t, {
		timeout: 20,
		initial: {
			...report(),
			collectedAt: 0,
			filesystems: [{ uuid, status: "ok" }],
		},
		collector: async (signal) => {
			await new Promise((resolve, reject) =>
				signal.addEventListener("abort", () => reject(signal.reason), {
					once: true,
				}),
			);
		},
	});
	const result = await request(context.path);
	assert.equal(result.status, "unavailable");
	assert.equal(result.stale, true);
	assert.equal(result.filesystems[0].uuid, uuid);
});

test("atomic replacement leaves complete report and correct permissions", async (t) => {
	const directory = await mkdtemp(join(tmpdir(), "couch-publish-"));
	t.after(() => rm(directory, { recursive: true, force: true }));
	const path = join(directory, "report.json");
	await publish(path, report());
	await publish(path, { ...report(), status: "unavailable" });
	assert.equal(JSON.parse(await readFile(path)).status, "unavailable");
	const { stat } = await import("node:fs/promises");
	assert.equal((await stat(path)).mode & 0o777, 0o640);
});

test("mounted rollback, deleted parent, bind mounts, aliases and prefix boundaries", () => {
	const volumes = parseSubvolumes(subvolumes, true);
	markMounted(volumes, [
		{ fsroot: "/snapshots/root-1/etc" },
		{ fsroot: "/snapshots/root-1" },
		{ fsroot: "/orphan" },
		{ fsroot: "/persistent" },
	]);
	assert.deepEqual(
		volumes.filter((s) => s.mounted).map((s) => s.path),
		["/", "orphan", "snapshots/root-1"],
	);
	const nested = [{ path: "/" }, { path: "a" }, { path: "a/b" }];
	markMounted(nested, [{ fsroot: "/a/b/inside" }]);
	assert.deepEqual(
		nested.map((s) => s.mounted),
		[false, false, true],
	);
});

test("connection cap rejects excess and recovers", async (t) => {
	let release;
	const context = await withServer(t, {
		maxConnections: 2,
		collector: async () => {
			await new Promise((r) => {
				release = r;
			});
			return report();
		},
	});
	const a = request(context.path),
		b = request(context.path);
	await until(() => release);
	await assert.rejects(request(context.path));
	release();
	await Promise.all([a, b]);
	await delay(20);
	assert.equal((await request(context.path)).status, "ok");
});

test("global request bucket rejects bursts and refills", async (t) => {
	const context = await withServer(t, {
		initial: report(),
		requestBurst: 2,
		requestsPerSecond: 20,
	});
	await request(context.path);
	await request(context.path);
	await assert.rejects(request(context.path));
	await delay(60);
	assert.equal((await request(context.path)).status, "ok");
});

test("slow readers hit absolute deadline and release response budget", async (t) => {
	const initial = { ...report(), padding: "x".repeat(4 * 1024 * 1024) };
	const size = Buffer.byteLength(JSON.stringify(initial)) + 1;
	const context = await withServer(t, {
		initial,
		maxResponseBytes: size,
		deliveryTimeout: 150,
	});
	const slow = net.createConnection(context.path);
	slow.pause();
	t.after(() => slow.destroy());
	await new Promise((r) => slow.on("connect", r));
	await delay(20);
	await assert.rejects(request(context.path));
	await delay(180);
	assert.equal(
		(await request(context.path)).padding.length,
		initial.padding.length,
	);
	slow.destroy();
});

test("disconnect releases response reservation before deadline", async (t) => {
	const initial = { ...report(), padding: "x".repeat(4 * 1024 * 1024) };
	const context = await withServer(t, {
		initial,
		maxResponseBytes: Buffer.byteLength(JSON.stringify(initial)) + 1,
	});
	const slow = net.createConnection(context.path);
	slow.pause();
	await new Promise((r) => slow.on("connect", r));
	await delay(20);
	slow.destroy();
	await delay(20);
	assert.equal((await request(context.path)).status, "ok");
});

test("oversized collection fails with backoff and never publishes oversized data", async (t) => {
	let calls = 0;
	const context = await withServer(t, {
		maxReportBytes: 512,
		collector: async () => {
			calls++;
			return { ...report(), padding: "x".repeat(1024) };
		},
	});
	assert.equal((await request(context.path)).status, "unavailable");
	await request(context.path);
	assert.equal(calls, 1);
	assert.ok((await readFile(context.cachePath)).length <= 512);
	await writeFile(
		context.cachePath,
		JSON.stringify({ ...report(), padding: "x".repeat(1024) }),
	);
	assert.equal(await loadCache(context.cachePath, 512), null);
	await publish(context.cachePath, report());
	assert.equal((await loadCache(context.cachePath, 512)).status, "ok");
});

test("response recipients do not keep a new collection alive", async (t) => {
	let time = Date.now(),
		signal;
	const context = await withServer(t, {
		initial: { ...report(), padding: "x".repeat(4 * 1024 * 1024) },
		now: () => time,
		collector: async (s) => {
			signal = s;
			await new Promise((resolve, reject) =>
				s.addEventListener("abort", () => reject(s.reason), { once: true }),
			);
		},
	});
	const receiver = net.createConnection(context.path);
	receiver.pause();
	await new Promise((r) => receiver.on("connect", r));
	await delay(20);
	time += 300001;
	const waiter = net.createConnection(context.path);
	await until(() => signal);
	waiter.destroy();
	await until(() => signal.aborted);
	receiver.destroy();
});
