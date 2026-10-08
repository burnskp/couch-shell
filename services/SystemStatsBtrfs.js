function popupEnabled(enabled, entries) {
	return enabled || entries.length > 0;
}

function refreshResult(previous, output, code) {
	try {
		const next = JSON.parse(output);
		if (code !== 0 || next.version !== 1 || !Array.isArray(next.filesystems))
			throw new Error("Unavailable");
		return next;
	} catch (error) {
		return {
			version: 1,
			status: "unavailable",
			stale: !!(previous && previous.filesystems.length),
			collectedAt: previous ? previous.collectedAt : null,
			filesystems: previous ? previous.filesystems : [],
		};
	}
}

function statusText(report) {
	if (!report) return "Waiting for collector";
	if (report.stale) return "Stale · refresh unavailable";
	if (report.status === "unavailable") return "Collector unavailable";
	if (report.status === "partial") return "Some volume details unavailable";
	return report.filesystems.length ? "" : "No mounted Btrfs volumes";
}

function accountingText(status) {
	return (
		{
			disabled: "Quota accounting disabled",
			scanning: "Quota accounting scanning",
			inconsistent: "Quota accounting inconsistent",
			simple: "Simple quotas · shared usage unavailable",
			unavailable: "Quota accounting unavailable",
		}[status] || ""
	);
}

function volumeCards(report, formatBytes) {
	if (!report) return [];
	const filesystems = report.filesystems;
	function baseName(volume) {
		return volume.label || volume.device.split("/").pop() || volume.uuid;
	}
	return filesystems.map((volume) => {
		const base = baseName(volume);
		const name =
			filesystems.filter((v) => baseName(v) === base).length > 1
				? base + " · " + volume.uuid
				: base;
		const subvolumes = volume.subvolumes || [];
		const snapshots = {};
		let unassociated = 0;
		for (const subvolume of subvolumes) {
			if (!subvolume.parentUuid) continue;
			const source = subvolumes.find((s) => s.uuid === subvolume.parentUuid);
			if (source) snapshots[source.uuid] = (snapshots[source.uuid] || 0) + 1;
			else unassociated++;
		}
		const rows = subvolumes
			.filter((s) => !s.parentUuid || s.mounted === true)
			.sort((a, b) => (a.path < b.path ? -1 : a.path > b.path ? 1 : 0))
			.map((s) => ({
				name: s.path,
				referenced:
					volume.accounting === "valid" && Number.isFinite(s.referencedBytes)
						? formatBytes(s.referencedBytes)
						: "—",
				exclusive:
					volume.accounting === "valid" && Number.isFinite(s.exclusiveBytes)
						? formatBytes(s.exclusiveBytes)
						: "—",
			}));
		const snapshotRows = Object.keys(snapshots).map((uuid) => ({
			name: subvolumes.find((s) => s.uuid === uuid).path,
			value: String(snapshots[uuid]),
		}));
		if (unassociated)
			snapshotRows.push({ name: "Unassociated", value: String(unassociated) });
		return {
			name: name,
			capacity:
				Number.isFinite(volume.totalBytes) &&
				Number.isFinite(volume.availableBytes)
					? formatBytes(volume.availableBytes) +
						" / " +
						formatBytes(volume.totalBytes)
					: "Unavailable",
			explanation:
				volume.status !== "ok"
					? "Volume details unavailable"
					: accountingText(volume.accounting),
			rows: rows,
			snapshots: snapshotRows,
		};
	});
}
