function iconGlyph(available, wifiEnabled, connected, signalPercent) {
	if (!available || !wifiEnabled) return "󰤮";
	if (!connected) return "󰤯";
	if (signalPercent >= 80) return "󰤨";
	if (signalPercent >= 55) return "󰤥";
	if (signalPercent >= 30) return "󰤢";
	return "󰤟";
}

function connectionKey(connected, interfaceName, ssid, connectionName) {
	if (!connected) return "";

	return [interfaceName || "", ssid || "", connectionName || ""].join("|");
}

function deriveWifiStatus(state) {
	const available = !!state.hasWifiDevice;
	const wifiEnabled =
		(!!state.wifiEnabled && !!state.wifiHardwareEnabled) ||
		!!state.deviceConnected ||
		!!state.hasActiveNetwork;
	const reconnecting =
		wifiEnabled && !!state.deviceConnected && !state.hasActiveNetwork;
	const connected = wifiEnabled && !!state.hasActiveNetwork;

	return {
		available: available,
		wifiEnabled: wifiEnabled,
		reconnecting: reconnecting,
		connected: connected,
	};
}

function parseKeyValueOutput(output) {
	const data = {};
	const lines = (output || "").split(/\n/);

	for (let index = 0; index < lines.length; index += 1) {
		const line = lines[index];
		const separatorIndex = line.indexOf("=");
		if (separatorIndex === -1) continue;
		data[line.slice(0, separatorIndex)] = line.slice(separatorIndex + 1).trim();
	}

	return data;
}

function parseTelemetry(output) {
	const data = parseKeyValueOutput(output);
	const rawFrequency = parseInt(data.frequency || "", 10);
	let band = "";

	if (Number.isFinite(rawFrequency) && rawFrequency > 0)
		band = rawFrequency >= 5000 ? "5 GHz" : "2.4 GHz";

	return {
		linkSpeed: data.linkSpeed || "",
		band: band,
		rawRxBytes: Math.max(parseFloat(data.rxBytes || "0"), 0),
		rawTxBytes: Math.max(parseFloat(data.txBytes || "0"), 0),
	};
}

function shouldApplyTelemetry(
	connected,
	currentConnectionKey,
	connectionKeyValue,
) {
	return (
		connected &&
		currentConnectionKey.length > 0 &&
		currentConnectionKey === connectionKeyValue
	);
}

function resetTraffic() {
	return {
		activeConnectionKey: "",
		baselineRxBytes: 0,
		baselineTxBytes: 0,
		lastRxBytes: 0,
		lastTxBytes: 0,
		lastSampleTimestamp: 0,
		sessionRxBytes: 0,
		sessionTxBytes: 0,
		rxRateBytesPerSecond: 0,
		txRateBytesPerSecond: 0,
	};
}

function updateTraffic(
	currentState,
	rawRxBytes,
	rawTxBytes,
	nextConnectionKey,
	now,
) {
	if (!nextConnectionKey || nextConnectionKey.length === 0)
		return resetTraffic();

	const sameConnection = currentState.activeConnectionKey === nextConnectionKey;
	if (!sameConnection) {
		return {
			activeConnectionKey: nextConnectionKey,
			baselineRxBytes: rawRxBytes,
			baselineTxBytes: rawTxBytes,
			lastRxBytes: rawRxBytes,
			lastTxBytes: rawTxBytes,
			lastSampleTimestamp: now,
			sessionRxBytes: 0,
			sessionTxBytes: 0,
			rxRateBytesPerSecond: 0,
			txRateBytesPerSecond: 0,
		};
	}

	const deltaMs = now - currentState.lastSampleTimestamp;
	const rxDelta = Math.max(rawRxBytes - currentState.lastRxBytes, 0);
	const txDelta = Math.max(rawTxBytes - currentState.lastTxBytes, 0);
	const sessionRxBytes = Math.max(rawRxBytes - currentState.baselineRxBytes, 0);
	const sessionTxBytes = Math.max(rawTxBytes - currentState.baselineTxBytes, 0);

	return {
		activeConnectionKey: nextConnectionKey,
		baselineRxBytes: currentState.baselineRxBytes,
		baselineTxBytes: currentState.baselineTxBytes,
		lastRxBytes: rawRxBytes,
		lastTxBytes: rawTxBytes,
		lastSampleTimestamp: now,
		sessionRxBytes: sessionRxBytes,
		sessionTxBytes: sessionTxBytes,
		rxRateBytesPerSecond:
			deltaMs > 0
				? Math.round((rxDelta * 1000) / deltaMs)
				: currentState.rxRateBytesPerSecond,
		txRateBytesPerSecond:
			deltaMs > 0
				? Math.round((txDelta * 1000) / deltaMs)
				: currentState.txRateBytesPerSecond,
	};
}

function appendRateHistory(history, nextValue, maxLength) {
	const nextHistory = Array.isArray(history) ? history.slice() : [];
	nextHistory.push(Math.max(nextValue || 0, 0));

	if (maxLength > 0 && nextHistory.length > maxLength)
		nextHistory.splice(0, nextHistory.length - maxLength);

	return nextHistory;
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

function formatRate(bytesPerSecond) {
	return `${formatBytes(bytesPerSecond)}/s`;
}
