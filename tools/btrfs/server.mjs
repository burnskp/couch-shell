import { open, rename, unlink, writeFile } from "node:fs/promises";
import net from "node:net";
import { pathToFileURL } from "node:url";
import { collect } from "./collector.mjs";

const MAX_REPORT_BYTES = 16 * 1024 * 1024;
function serialize(report, limit) {
	const buffer = Buffer.from(`${JSON.stringify(report)}\n`);
	if (buffer.length > limit) throw new Error("Report exceeds size limit");
	return buffer;
}
export async function loadCache(path, limit = MAX_REPORT_BYTES) {
	let file;
	try {
		file = await open(path, "r");
		if ((await file.stat()).size > limit) return null;
		const buffer = Buffer.alloc(limit + 1);
		let length = 0;
		while (length < buffer.length) {
			const { bytesRead } = await file.read(
				buffer,
				length,
				buffer.length - length,
			);
			if (!bytesRead) break;
			length += bytesRead;
		}
		if (length > limit) return null;
		const saved = JSON.parse(buffer.subarray(0, length).toString());
		return saved.version === 1 && Array.isArray(saved.filesystems)
			? saved
			: null;
	} catch {
		return null;
	} finally {
		await file?.close();
	}
}
export async function publish(path, report) {
	const temporary = `${path}.${process.pid}.tmp`;
	try {
		await writeFile(
			temporary,
			Buffer.isBuffer(report) ? report : serialize(report, MAX_REPORT_BYTES),
			{
				mode: 0o640,
				flag: "wx",
			},
		);
		await rename(temporary, path);
	} finally {
		await unlink(temporary).catch(() => {});
	}
}
export function createServer({
	interval = 300000,
	cachePath = "/run/couch-shell/btrfs.json",
	collector = collect,
	now = Date.now,
	timeout = 45000,
	initial = null,
	maxConnections = 32,
	maxReportBytes = MAX_REPORT_BYTES,
	maxResponseBytes = 64 * 1024 * 1024,
	requestsPerSecond = 16,
	requestBurst = 32,
	deliveryTimeout = 5000,
	cancelCooldown = 1000,
} = {}) {
	let report = initial;
	let buffer = null;
	try {
		if (report) buffer = serialize(report, maxReportBytes);
	} catch {
		report = null;
	}
	let attemptedAt = report?.attemptedAt ?? report?.collectedAt ?? -Infinity;
	let pending = null;
	let retryAt = 0;
	let retryTimer = null;
	let outstanding = 0;
	let tokens = requestBurst;
	let tokenTime = performance.now();
	const clients = new Set();
	const waiters = new Set();
	const failed = () => ({
		version: 1,
		collectedAt: report?.collectedAt ?? null,
		attemptedAt: now(),
		status: "unavailable",
		stale: !!report?.filesystems?.length,
		filesystems: report?.filesystems || [],
	});
	function deliver(socket, deadline) {
		waiters.delete(socket);
		if (socket.destroyed) return;
		if (
			!buffer ||
			outstanding + buffer.length > maxResponseBytes ||
			deadline <= performance.now()
		) {
			socket.destroy();
			return;
		}
		const size = buffer.length;
		outstanding += size;
		const timer = setTimeout(
			() => socket.destroy(),
			deadline - performance.now(),
		);
		socket.once("close", () => {
			clearTimeout(timer);
			outstanding -= size;
		});
		socket.end(buffer);
	}
	function start() {
		if (pending || !waiters.size) return;
		if (performance.now() < retryAt) {
			if (!retryTimer)
				retryTimer = setTimeout(() => {
					retryTimer = null;
					start();
				}, retryAt - performance.now());
			return;
		}
		if (now() - attemptedAt < interval) {
			for (const socket of waiters)
				deliver(socket, performance.now() + deliveryTimeout);
			return;
		}
		const controller = new AbortController();
		const job = { controller, cancelled: false, collecting: true };
		pending = job;
		const attempt = now();
		const timer = setTimeout(
			() => controller.abort(new Error("Collection timeout")),
			timeout,
		);
		(async () => {
			let next, encoded;
			try {
				next = await collector(controller.signal);
				controller.signal.throwIfAborted();
				next.attemptedAt = attempt;
				next.filesystems = next.filesystems.map((f) => {
					const previous = report?.filesystems.find(
						(old) => old.uuid === f.uuid,
					);
					return f.status !== "ok" && previous
						? { ...previous, stale: true, status: f.status }
						: f;
				});
				next.stale = next.filesystems.some((f) => f.stale);
				encoded = serialize(next, maxReportBytes);
			} catch (error) {
				if (!job.cancelled) {
					console.error(`Btrfs report unavailable: ${error.message}`);
					next = failed();
					try {
						encoded = serialize(next, maxReportBytes);
					} catch {
						next = { ...next, filesystems: [], stale: false };
						try {
							encoded = serialize(next, maxReportBytes);
						} catch {
							encoded = null;
						}
					}
				}
			}
			clearTimeout(timer);
			job.collecting = false;
			if (job.cancelled) {
				pending = null;
				retryAt = performance.now() + cancelCooldown;
				start();
				return;
			}
			const deadline = performance.now() + deliveryTimeout;
			job.deadline = deadline;
			// Include cache publication in the absolute delivery deadline.
			for (const socket of waiters) {
				const timer = setTimeout(() => socket.destroy(), deliveryTimeout);
				socket.once("close", () => clearTimeout(timer));
			}
			try {
				if (encoded) await publish(cachePath, encoded);
			} catch {
				next = {
					...next,
					status: "unavailable",
					stale: !!next.filesystems.length,
				};
				try {
					encoded = serialize(next, maxReportBytes);
				} catch {
					encoded = null;
				}
			}
			report = next;
			buffer = encoded;
			attemptedAt = attempt;
			pending = null;
			for (const socket of waiters) deliver(socket, deadline);
		})();
	}
	const server = net.createServer((socket) => {
		socket.on("error", () => {});
		const time = performance.now();
		tokens = Math.min(
			requestBurst,
			tokens + ((time - tokenTime) * requestsPerSecond) / 1000,
		);
		tokenTime = time;
		if (clients.size >= maxConnections || tokens < 1) {
			socket.destroy();
			return;
		}
		tokens--;
		clients.add(socket);
		waiters.add(socket);
		socket.on("data", () => socket.destroy()); // No request payload is supported.
		socket.on("close", () => {
			clients.delete(socket);
			waiters.delete(socket);
			if (!waiters.size) {
				clearTimeout(retryTimer);
				retryTimer = null;
				if (pending?.collecting && !pending.controller.signal.aborted) {
					pending.cancelled = true;
					pending.controller.abort(new Error("No waiting clients"));
				}
			}
		});
		if (pending?.deadline) {
			const timer = setTimeout(
				() => socket.destroy(),
				Math.max(0, pending.deadline - performance.now()),
			);
			socket.once("close", () => clearTimeout(timer));
		}
		start();
	});
	server.on("close", () => {
		clearTimeout(retryTimer);
		pending?.controller.abort(new Error("Server closed"));
	});
	return server;
}
if (
	process.argv[1] &&
	import.meta.url === pathToFileURL(process.argv[1]).href
) {
	if (
		process.env.LISTEN_PID !== String(process.pid) ||
		process.env.LISTEN_FDS !== "1"
	)
		throw new Error("Expected exactly one systemd activation socket");
	const cachePath = "/run/couch-shell/btrfs.json";
	createServer({
		interval: Number(process.argv[2]) * 1000,
		cachePath,
		initial: await loadCache(cachePath),
	}).listen({ fd: 3 });
}
