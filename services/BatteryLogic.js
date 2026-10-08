function durationString(seconds) {
	if (!seconds || seconds <= 0) return "";

	const totalMinutes = Math.floor(seconds / 60);
	const hours = Math.floor(totalMinutes / 60);
	const minutes = totalMinutes % 60;
	return `${hours}:${minutes.toString().padStart(2, "0")}`;
}

function chargingBatteryIcon(percent) {
	if (percent >= 95) return "󰂅";
	if (percent >= 85) return "󰂋";
	if (percent >= 75) return "󰂊";
	if (percent >= 65) return "󰢞";
	if (percent >= 55) return "󰂉";
	if (percent >= 45) return "󰢝";
	if (percent >= 35) return "󰂈";
	if (percent >= 25) return "󰂇";
	if (percent >= 15) return "󰂆";
	return "󰢜";
}

function dischargingBatteryIcon(percent) {
	if (percent >= 95) return "󰁹";
	if (percent >= 85) return "󰂂";
	if (percent >= 75) return "󰂁";
	if (percent >= 65) return "󰂀";
	if (percent >= 55) return "󰁿";
	if (percent >= 45) return "󰁾";
	if (percent >= 35) return "󰁽";
	if (percent >= 25) return "󰁼";
	if (percent >= 15) return "󰁻";
	return "󰁺";
}

function batteryIcon(percent, isCharging, isPlugged) {
	if (isPlugged && !isCharging) return "󱟢";

	if (isCharging) return chargingBatteryIcon(percent);

	return dischargingBatteryIcon(percent);
}

function batteryLabel(seconds, isCharging, isPlugged) {
	if (isPlugged && !isCharging) return "FULL";

	const timeText = durationString(seconds);
	return timeText.length > 0 ? timeText : "--:--";
}

function lowBatteryAlertLevel(ready, isDischarging, percent) {
	if (!ready || !isDischarging || percent > 10) return 0;

	return percent <= 5 ? 2 : 1;
}

function shouldRecordLowBatteryAlert(currentLevel, nextLevel) {
	return nextLevel > currentLevel;
}

function lowBatteryAlertPayload(
	alertLevel,
	percent,
	label,
	urgencyNormal,
	urgencyCritical,
	defaultTimeoutMs,
) {
	const hasUsableLabel = label && label.length > 0 && label !== "--:--";

	return {
		remoteId:
			alertLevel === 2
				? "couch-shell-battery-critical"
				: "couch-shell-battery-low",
		title: alertLevel === 2 ? "Critical battery" : "Low battery",
		body:
			percent + "% remaining" + (hasUsableLabel ? " · " + label + " left" : ""),
		appName: "Couch Shell",
		urgency: alertLevel === 2 ? urgencyCritical : urgencyNormal,
		timeoutMs: alertLevel === 2 ? 0 : defaultTimeoutMs,
	};
}
