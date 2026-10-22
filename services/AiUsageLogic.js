function percentage(value) {
	return Math.ceil(Math.max(0, Math.min(100, value))) + "%";
}

function countdown(resetsAt, now) {
	if (!(resetsAt > 0)) return "Unknown";
	const minutes = Math.ceil(Math.max(0, resetsAt - now) / 60000);
	return Math.floor(minutes / 60) + ":" + String(minutes % 60).padStart(2, "0");
}

function resetDuration(resetsAt, now) {
	if (!(resetsAt > 0)) return "Unknown";
	const minutes = Math.ceil(Math.max(0, resetsAt - now) / 60000);
	return (
		Math.floor(minutes / 1440) +
		"d " +
		(Math.floor(minutes / 60) % 24) +
		"h " +
		(minutes % 60) +
		"m"
	);
}

function windowLabel(window) {
	const seconds = window.durationSeconds;
	if (!(seconds > 0))
		return window.id === "primary_window" ? "Primary limit" : "Secondary limit";
	if (seconds % 604800 === 0)
		return seconds / 604800 + " week" + (seconds === 604800 ? "" : "s");
	if (seconds % 86400 === 0)
		return seconds / 86400 + " day" + (seconds === 86400 ? "" : "s");
	if (seconds % 3600 === 0)
		return seconds / 3600 + " hour" + (seconds === 3600 ? "" : "s");
	return Math.ceil(seconds / 60) + " minutes";
}

function expired(provider, now) {
	return provider.windows.some(
		(window) => window.resetsAt > 0 && window.resetsAt <= now,
	);
}

function summary(provider, now) {
	const windows = provider.windows;
	if (provider.status !== "ready" || !windows.length || expired(provider, now))
		return { text: "Unk", exhausted: false };
	const remaining = Math.min.apply(
		null,
		windows.map((window) => window.remainingPercent),
	);
	if (remaining > 0) return { text: percentage(remaining), exhausted: false };
	const exhausted = windows.filter((window) => window.remainingPercent === 0);
	const resetKnown = exhausted.every((window) => window.resetsAt > 0);
	const resetsAt = Math.max.apply(
		null,
		exhausted.map((window) => window.resetsAt || 0),
	);
	return {
		text: resetKnown ? countdown(resetsAt, now) : "0%",
		exhausted: true,
	};
}

// Wake only when a displayed minute changes, including the reset itself.
function nextTick(windows, now) {
	return windows.reduce((delay, window) => {
		const remaining = window.resetsAt - now;
		return remaining > 0 ? Math.min(delay, remaining % 60000 || 60000) : delay;
	}, 60000);
}
