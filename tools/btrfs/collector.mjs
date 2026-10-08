import { execFile } from "node:child_process";
import { readFile } from "node:fs/promises";

// All paths below are substituted by the collector package, never by a client.
const binaries = { findmnt: "@findmnt@", btrfs: "@btrfs@", df: "@df@" };
export function runCommand(file, args, signal, timeout = 5000) {
	return new Promise((resolve, reject) => {
		execFile(
			file,
			args,
			{
				env: { LC_ALL: "C", PATH: "" },
				signal,
				timeout,
				killSignal: "SIGKILL",
				maxBuffer: 8 * 1024 * 1024,
			},
			(error, stdout, stderr) => {
				if (signal?.aborted) return reject(signal.reason);
				resolve({ code: error ? error.code || -1 : 0, stdout, stderr });
			},
		);
	});
}
function checked(result) {
	if (result.code !== 0)
		throw new Error(`Command unavailable: ${result.stderr || result.code}`);
	return result.stdout;
}
export function discover(output) {
	const groups = new Map();
	for (const mount of JSON.parse(output).filesystems) {
		if (!mount.uuid || !mount.target?.startsWith("/")) continue;
		if (!groups.has(mount.uuid)) groups.set(mount.uuid, []);
		const mounts = groups.get(mount.uuid);
		if (!mounts.some((m) => m.target === mount.target)) mounts.push(mount);
	}
	return groups;
}
export function parseSubvolumes(output, topLevel) {
	const rows = JSON.parse(output)["subvolume-list"];
	if (!Array.isArray(rows)) throw new Error("Invalid subvolume report");
	const volumes = new Map();
	for (const row of rows) {
		const id = Number(row.id);
		if (!Number.isSafeInteger(id) || id < 5 || typeof row.path !== "string")
			throw new Error("Invalid subvolume record");
		const uuid = (value) =>
			!value || value === "-" || /^0{8}-0{4}-0{4}-0{4}-0{12}$/.test(value)
				? null
				: value;
		volumes.set(id, {
			id,
			path: row.path.replace(/^<FS_TREE>\//, ""),
			uuid: uuid(row.uuid),
			parentUuid: uuid(row.parent_uuid),
			referencedBytes: null,
			exclusiveBytes: null,
		});
	}
	if (topLevel)
		volumes.set(5, {
			id: 5,
			path: "/",
			uuid: null,
			parentUuid: null,
			referencedBytes: null,
			exclusiveBytes: null,
		});
	else volumes.delete(5);
	return [...volumes.values()].sort((a, b) =>
		a.path < b.path ? -1 : a.path > b.path ? 1 : 0,
	);
}
// FSROOT may name a bind-mounted directory inside a subvolume.
export function markMounted(subvolumes, mounts) {
	for (const volume of subvolumes) volume.mounted = false;
	for (const mount of mounts) {
		if (typeof mount.fsroot !== "string") continue;
		let best = null;
		for (const volume of subvolumes) {
			const path = volume.path === "/" ? "/" : `/${volume.path}`;
			if (
				(mount.fsroot === path ||
					mount.fsroot.startsWith(path === "/" ? "/" : `${path}/`)) &&
				(!best ||
					(volume.path === "/" ? 0 : volume.path.length) >
						(best.path === "/" ? 0 : best.path.length))
			)
				best = volume;
		}
		if (best) best.mounted = true;
	}
	return subvolumes;
}
export function accounting(result, mode, rescan) {
	const message = result.stderr + "\n" + result.stdout;
	if (/quota.*not enabled|quotas.*disabled/i.test(message))
		return { status: "disabled", usage: new Map() };
	if (mode.trim() === "squota") return { status: "simple", usage: new Map() };
	if (result.code !== 0 || !["qgroup", "squota"].includes(mode.trim()))
		return { status: "unavailable", usage: new Map() };
	if (
		/rescan.*running|rescan.*progress/i.test(message) ||
		(rescan.code === 0 &&
			!/no rescan operation in progress/i.test(rescan.stdout) &&
			/running|progress/i.test(rescan.stdout))
	)
		return { status: "scanning", usage: new Map() };
	if (/inconsistent/i.test(message))
		return { status: "inconsistent", usage: new Map() };
	if (rescan.code !== 0) return { status: "unavailable", usage: new Map() };
	const usage = new Map();
	for (const line of result.stdout.split("\n")) {
		const match = line.match(/^\s*0\/(\d+)\s+(\d+)\s+(\d+)(?:\s|$)/);
		if (match)
			usage.set(Number(match[1]), {
				referencedBytes: Number(match[2]),
				exclusiveBytes: Number(match[3]),
			});
	}
	return { status: usage.size ? "valid" : "unavailable", usage };
}
export async function collect(signal, dependencies = {}) {
	const run =
		dependencies.run ||
		((name, args) => runCommand(binaries[name], args, signal));
	const capacity =
		dependencies.capacity ||
		(async (path) => {
			const result = await run("df", [
				"--block-size=1",
				"--output=avail,size",
				"--",
				path,
			]);
			const match = checked(result)
				.trim()
				.split("\n")[1]
				?.match(/^\s*(\d+)\s+(\d+)\s*$/);
			if (!match) throw new Error("Capacity unavailable");
			return { availableBytes: Number(match[1]), totalBytes: Number(match[2]) };
		});
	const quotaMode =
		dependencies.quotaMode ||
		((uuid) =>
			readFile(`/sys/fs/btrfs/${uuid}/qgroups/mode`, "utf8").catch(() => ""));
	const found = await run("findmnt", [
		"--json",
		"--list",
		"--types",
		"btrfs",
		"--output",
		"UUID,LABEL,SOURCE,TARGET,FSROOT",
	]);
	// findmnt uses exit 1 for an empty selection, with no JSON output.
	const groups =
		found.code === 1 && !found.stdout.trim() && !found.stderr.trim()
			? new Map()
			: discover(checked(found));
	const filesystems = [];
	for (const [uuid, mounts] of groups) {
		signal.throwIfAborted();
		const base = {
			uuid,
			label: mounts[0].label || "",
			device: (mounts[0].source || "").replace(/\[.*$/, ""),
			availableBytes: null,
			totalBytes: null,
			subvolumes: [],
			accounting: "unavailable",
			status: "unavailable",
		};
		let best = base;
		for (const mount of mounts) {
			signal.throwIfAborted();
			const volume = { ...base };
			try {
				// Revalidate UUID before querying a mount that might have been replaced.
				const current = await run("findmnt", [
					"--json",
					"--target",
					mount.target,
					"--output",
					"UUID",
				]);
				if (JSON.parse(checked(current)).filesystems[0]?.uuid !== uuid)
					continue;
				Object.assign(volume, await capacity(mount.target));
				volume.status = "partial";
				const subvolumes = await run("btrfs", [
					"--format",
					"json",
					"subvolume",
					"list",
					"-a",
					"-u",
					"-q",
					"--",
					mount.target,
				]);
				volume.subvolumes = markMounted(
					parseSubvolumes(
						checked(subvolumes),
						mounts.some((m) => m.fsroot === "/"),
					),
					mounts,
				);
				const qgroups = await run("btrfs", [
					"qgroup",
					"show",
					"--raw",
					"--",
					mount.target,
				]);
				const rescan = await run("btrfs", [
					"quota",
					"rescan",
					"-s",
					"--",
					mount.target,
				]);
				const state = accounting(qgroups, await quotaMode(uuid), rescan);
				volume.accounting = state.status;
				volume.subvolumes = volume.subvolumes.map((s) => ({
					...s,
					...(state.usage.get(s.id) || {}),
				}));
				volume.status = "ok";
				best = volume;
				break;
			} catch (error) {
				signal.throwIfAborted();
				console.error(`Btrfs collection failed for ${uuid}: ${error.message}`);
				if (volume.totalBytes !== null) best = volume;
			}
		}
		filesystems.push(best);
	}
	return {
		version: 1,
		collectedAt: Date.now(),
		status: filesystems.some((f) => f.status !== "ok") ? "partial" : "ok",
		filesystems,
	};
}
