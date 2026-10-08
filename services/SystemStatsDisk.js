function queryPaths(textPath, popupPaths) {
	return Array.from(
		new Set([textPath].concat(popupPaths.map((entry) => entry.path))),
	);
}

function queryCommand(path) {
	return [
		"timeout",
		"--kill-after=1s",
		"3s",
		"env",
		"LC_ALL=C",
		"sh",
		"-c",
		'test -r "$1" && exec df --block-size=1 --output=avail,size -- "$1"',
		"--",
		path,
	];
}

function parseResult(output, exitCode) {
	if (exitCode !== 0) return null;
	const lines = (output || "").trim().split(/\n/);
	if (lines.length !== 2) return null;
	const match = lines[1].match(/^\s*(\d+)\s+(\d+)\s*$/);
	if (!match) return null;
	const availableBytes = Number(match[1]);
	const totalBytes = Number(match[2]);
	if (
		!Number.isFinite(availableBytes) ||
		!Number.isFinite(totalBytes) ||
		totalBytes <= 0 ||
		availableBytes > totalBytes
	)
		return null;
	return { availableBytes: availableBytes, totalBytes: totalBytes };
}

function availableLabel(result, formatBytes) {
	return result ? formatBytes(result.availableBytes) : "Unk";
}

function popupRows(entries, results, formatBytes) {
	return entries.map((entry) => {
		const result = results[entry.path];
		return {
			name: entry.name,
			path: entry.path,
			value: result
				? formatBytes(result.availableBytes) +
					" / " +
					formatBytes(result.totalBytes)
				: "Unavailable",
		};
	});
}

// -1 distinguishes failed readings from successful recovery.
function severity(result, warningGiB, criticalGiB) {
	if (!result) return -1;
	if (result.availableBytes < criticalGiB * 1073741824) return 2;
	return result.availableBytes < warningGiB * 1073741824 ? 1 : 0;
}

function alertTransition(previousLevel, severity) {
	if (severity < 0) return { level: previousLevel, notify: false };
	if (severity === 0) return { level: 0, notify: false };
	return {
		level: Math.max(previousLevel, severity),
		notify: severity > previousLevel,
	};
}

function alertPayload(level, path, remaining, urgencyNormal, urgencyCritical) {
	return {
		remoteId:
			level === 2 ? "couch-shell-disk-critical" : "couch-shell-disk-low",
		title: level === 2 ? "Critical disk space" : "Low disk space",
		body: path + " · " + remaining + " remaining",
		appName: "Couch Shell",
		urgency: level === 2 ? urgencyCritical : urgencyNormal,
		timeoutMs: 0,
	};
}
