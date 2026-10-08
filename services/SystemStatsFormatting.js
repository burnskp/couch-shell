function formatTemperature(value) {
	return Number.isFinite(value) ? `${Math.round(value)} °C` : "Unk";
}

function formatRpm(value) {
	return Number.isFinite(value) && value >= 0 ? `${value}` : "Unavailable";
}

function formatBytes(bytes) {
	if (!Number.isFinite(bytes) || bytes <= 0) return "0 B";

	const units = ["B", "KiB", "MiB", "GiB", "TiB"];
	let value = bytes;
	let unitIndex = 0;

	while (value >= 1024 && unitIndex < units.length - 1) {
		value /= 1024;
		unitIndex += 1;
	}

	const precision = value >= 10 || unitIndex === 0 ? 0 : 1;
	return `${value.toFixed(precision)} ${units[unitIndex]}`;
}

function formatGib(bytes) {
	if (!Number.isFinite(bytes) || bytes <= 0) return "0.0 GiB";

	return `${(bytes / (1024 * 1024 * 1024)).toFixed(1)} GiB`;
}

function formatProcessCpuPercent(value) {
	if (!Number.isFinite(value) || value < 0) return "0.0%";

	return `${value.toFixed(1)}%`;
}
