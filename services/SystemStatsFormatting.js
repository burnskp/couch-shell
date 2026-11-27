function formatTemperature(value, showUnit = true) {
	if (!Number.isFinite(value)) return "Unk";

	const rounded = Math.round(value);
	return showUnit ? `${rounded} °C` : `${rounded}`;
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

function formatGib(bytes, showUnit = true) {
	const value =
		!Number.isFinite(bytes) || bytes <= 0
			? "0.0"
			: (bytes / (1024 * 1024 * 1024)).toFixed(1);
	return showUnit ? `${value} GiB` : value;
}

function formatPercent(value, showUnit = true) {
	const rounded = Number.isFinite(value) ? Math.round(value) : 0;
	return showUnit ? `${rounded}%` : `${rounded}`;
}

function formatProcessCpuPercent(value) {
	if (!Number.isFinite(value) || value < 0) return "0.0%";

	return `${value.toFixed(1)}%`;
}
