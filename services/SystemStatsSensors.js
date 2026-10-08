function formatTemperature(value) {
	return Number.isFinite(value) ? `${Math.round(value)} °C` : "Unk";
}

function formatRpm(value) {
	return Number.isFinite(value) && value >= 0 ? `${value}` : "Unavailable";
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

function parseTemperatureValue(rawValue) {
	const value = parseFloat(rawValue || "");
	if (!Number.isFinite(value)) return NaN;
	return value / 1000;
}

function parseFanValue(rawValue) {
	const value = parseInt(rawValue || "", 10);
	return Number.isFinite(value) && value >= 0 ? value : -1;
}

function temperatureSensorRank(sensorKey) {
	switch ((sensorKey || "").toString().trim().toLowerCase()) {
		case "cpu":
			return 0;
		case "gpu":
			return 1;
		case "ram":
			return 2;
		case "wifi":
			return 3;
		case "nvme0":
			return 4;
		case "nvme1":
			return 5;
		default:
			return 100;
	}
}

function temperatureCriticalPath(sensorPath) {
	const normalized = (sensorPath || "").toString().trim();
	if (normalized.length === 0) return "";
	if (/_input$/.test(normalized)) return normalized.replace(/_input$/, "_crit");
	return "";
}

function capitalizeWord(word) {
	if (!word || word.length === 0) return "";
	return word.charAt(0).toUpperCase() + word.slice(1);
}

function titleCaseWords(value) {
	const normalized = (value || "").toString().trim().toLowerCase();
	const words = normalized
		.replace(/[_-]+/g, " ")
		.split(/\s+/)
		.filter((word) => word.length > 0)
		.map(capitalizeWord);

	return words.length > 0 ? words.join(" ") : "Unknown";
}

function temperatureSensorLabel(sensorKey) {
	const normalized = (sensorKey || "").toString().trim().toLowerCase();

	switch (normalized) {
		case "cpu":
			return "CPU";
		case "gpu":
			return "GPU";
		case "ram":
			return "RAM";
		case "wifi":
			return "WiFi";
		case "nvme0":
			return "NVMe 0";
		case "nvme1":
			return "NVMe 1";
		default:
			return titleCaseWords(normalized);
	}
}

function fanSensorRank(sensorKey) {
	switch ((sensorKey || "").toString().trim().toLowerCase()) {
		case "fan1":
			return 0;
		case "fan2":
			return 1;
		default:
			return 100;
	}
}

function fanSensorLabel(sensorKey) {
	const normalized = (sensorKey || "").toString().trim().toLowerCase();
	const match = normalized.match(/^fan(\d+)$/);
	if (match) return `Fan ${match[1]}`;
	return titleCaseWords(normalized);
}

function temperatureSensorEntries(sensorPaths) {
	if (
		!sensorPaths ||
		typeof sensorPaths !== "object" ||
		Array.isArray(sensorPaths)
	)
		return [];

	return Object.keys(sensorPaths)
		.map((key) => ({
			key: key,
			label: temperatureSensorLabel(key),
			path: (sensorPaths[key] || "").toString(),
			criticalPath: temperatureCriticalPath(sensorPaths[key]),
		}))
		.filter((entry) => entry.path.length > 0)
		.sort((left, right) => {
			const rankDelta =
				temperatureSensorRank(left.key) - temperatureSensorRank(right.key);
			if (rankDelta !== 0) return rankDelta;

			return left.label.localeCompare(right.label);
		});
}

function fanSensorEntries(sensorPaths) {
	if (
		!sensorPaths ||
		typeof sensorPaths !== "object" ||
		Array.isArray(sensorPaths)
	)
		return [];

	return Object.keys(sensorPaths)
		.map((key) => ({
			key: key,
			label: fanSensorLabel(key),
			path: (sensorPaths[key] || "").toString(),
		}))
		.filter((entry) => entry.path.length > 0)
		.sort((left, right) => {
			const rankDelta = fanSensorRank(left.key) - fanSensorRank(right.key);
			if (rankDelta !== 0) return rankDelta;

			return left.label.localeCompare(right.label);
		});
}

function parseSensorStatus(output, popupEntries, fanEntries) {
	const data = parseKeyValueOutput(output);
	const temperatureEntries = Array.isArray(popupEntries) ? popupEntries : [];
	const popupFanEntries = Array.isArray(fanEntries) ? fanEntries : [];
	const primaryTemperatureC = parseTemperatureValue(data.primaryTempRaw);

	return {
		primaryTemperatureC: primaryTemperatureC,
		temperatureRows: temperatureEntries.map((entry) => {
			const temperatureC = parseTemperatureValue(
				data[`popupTemp:${entry.key}`],
			);
			const criticalC = parseTemperatureValue(
				data[`popupTempCrit:${entry.key}`],
			);
			return {
				key: entry.key,
				label: entry.label || temperatureSensorLabel(entry.key),
				temperatureC: temperatureC,
				criticalC: criticalC,
				temperatureLabel: formatTemperature(temperatureC),
				usagePercent:
					Number.isFinite(temperatureC) &&
					Number.isFinite(criticalC) &&
					criticalC > 0
						? Math.round((temperatureC / criticalC) * 100)
						: -1,
			};
		}),
		fanRows: popupFanEntries.map((entry) => {
			const rpm = parseFanValue(data[`popupFan:${entry.key}`]);
			return {
				key: entry.key,
				label: entry.label || fanSensorLabel(entry.key),
				rpm: rpm,
				rpmLabel: formatRpm(rpm),
			};
		}),
	};
}
