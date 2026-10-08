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

function parseTopProcessesSnapshot(output) {
	const lines = (output || "").split(/\n/);
	const processes = [];

	for (let index = 0; index < lines.length; index += 1) {
		const trimmed = lines[index].trim();
		if (!trimmed.length) continue;

		const match = trimmed.match(
			/^(\d+)\s+([0-9]+(?:\.[0-9]+)?)\s+(\d+)\s+(.+)$/,
		);
		if (!match) continue;

		const command = firstCommandToken(match[4]);
		if (command === "ps" || command === "sh") continue;

		processes.push({
			pid: parseInt(match[1], 10),
			cpuPercent: parseFloat(match[2]),
			rssBytes: parseInt(match[3], 10) * 1024,
			command: command,
		});
	}

	const topCpuProcesses = processes
		.slice()
		.sort((left, right) => right.cpuPercent - left.cpuPercent)
		.slice(0, 5)
		.map((process) => ({
			pid: process.pid,
			cpuPercent: process.cpuPercent,
			command: process.command,
		}));
	const topMemoryProcesses = processes
		.slice()
		.sort((left, right) => right.rssBytes - left.rssBytes)
		.slice(0, 5)
		.map((process) => ({
			pid: process.pid,
			rssBytes: process.rssBytes,
			command: process.command,
		}));

	return {
		topCpuProcesses: topCpuProcesses,
		topMemoryProcesses: topMemoryProcesses,
	};
}

function firstCommandToken(commandLine) {
	const trimmed = (commandLine || "").trim();
	if (!trimmed.length) return "";

	const match = trimmed.match(/^\S+/);
	const token = match ? match[0] : trimmed;
	return basename(token);
}

function basename(path) {
	const segments = (path || "").split("/");

	for (let index = segments.length - 1; index >= 0; index -= 1) {
		if (segments[index].length > 0) return segments[index];
	}

	return path || "";
}

function parseTopProcessesForState(
	output,
	topCpuProcessesEnabled,
	topMemoryProcessesEnabled,
) {
	if (!topCpuProcessesEnabled && !topMemoryProcessesEnabled) {
		return {
			topCpuProcesses: [],
			topMemoryProcesses: [],
		};
	}

	return parseTopProcessesSnapshot(output);
}

function parseCpuTickValue(rawValue) {
	const value = parseFloat(rawValue || "");
	return Number.isFinite(value) && value >= 0 ? value : 0;
}

function parseCoreMaxFrequencyValue(rawValue) {
	const value = parseInt(rawValue || "", 10);
	return Number.isFinite(value) && value > 0 ? value : 0;
}

function parseCpuCoreSamples(data) {
	const coreSamples = [];

	for (let index = 0; ; index += 1) {
		const totalKey = `cpu${index}TotalTicks`;
		const idleKey = `cpu${index}IdleTicks`;
		if (!(totalKey in data) && !(idleKey in data)) break;

		coreSamples.push({
			index: index,
			totalTicks: parseCpuTickValue(data[totalKey]),
			idleTicks: parseCpuTickValue(data[idleKey]),
		});
	}

	return coreSamples;
}

function parseCpuCoreMaxFrequencies(data, coreCount) {
	const frequencies = [];

	for (let index = 0; index < coreCount; index += 1) {
		frequencies.push(parseCoreMaxFrequencyValue(data[`cpu${index}MaxFreqKhz`]));
	}

	return frequencies;
}

function classifyCpuCoreTypes(maxFrequencies) {
	const frequencyGroups = [];
	const sortedFrequencies = Array.from(
		new Set(maxFrequencies.filter((value) => value > 0)),
	).sort((left, right) => right - left);

	for (
		let groupIndex = 0;
		groupIndex < sortedFrequencies.length;
		groupIndex += 1
	) {
		const frequency = sortedFrequencies[groupIndex];
		let coreType = "efficient";

		if (sortedFrequencies.length === 1) coreType = "unknown";
		else if (sortedFrequencies.length === 2)
			coreType = groupIndex === 0 ? "performance" : "efficient";
		else if (groupIndex === 0) coreType = "performance";
		else if (groupIndex === sortedFrequencies.length - 1)
			coreType = "lowPowerEfficient";

		frequencyGroups.push({
			frequency: frequency,
			coreType: coreType,
		});
	}

	return maxFrequencies.map((frequency) => {
		const match = frequencyGroups.find(
			(group) => group.frequency === frequency,
		);
		const coreType = match ? match.coreType : "unknown";

		return {
			coreType: coreType,
			maxFrequencyKhz: frequency,
		};
	});
}

function updateCpuCoreUsages(
	coreSamples,
	currentCoreUsages,
	lastCpuCoreTotalTicks,
	lastCpuCoreIdleTicks,
	coreTypes,
) {
	const nextCoreUsages = [];
	const nextLastCpuCoreTotalTicks = [];
	const nextLastCpuCoreIdleTicks = [];

	for (let index = 0; index < coreSamples.length; index += 1) {
		const sample = coreSamples[index];
		const usage = updateCpuUsage(
			sample.totalTicks,
			sample.idleTicks,
			currentCoreUsages[index] || 0,
			lastCpuCoreTotalTicks[index] || 0,
			lastCpuCoreIdleTicks[index] || 0,
		);
		const coreMetadata = coreTypes[index] || {
			coreType: "unknown",
			maxFrequencyKhz: 0,
		};

		nextCoreUsages.push({
			index: index,
			usagePercent: usage.cpuUsagePercent,
			coreType: coreMetadata.coreType,
			maxFrequencyKhz: coreMetadata.maxFrequencyKhz,
		});
		nextLastCpuCoreTotalTicks.push(usage.lastCpuTotalTicks);
		nextLastCpuCoreIdleTicks.push(usage.lastCpuIdleTicks);
	}

	return {
		cpuCores: nextCoreUsages,
		lastCpuCoreTotalTicks: nextLastCpuCoreTotalTicks,
		lastCpuCoreIdleTicks: nextLastCpuCoreIdleTicks,
	};
}

function updateCpuUsage(
	totalTicks,
	idleTicks,
	currentCpuUsagePercent,
	lastCpuTotalTicks,
	lastCpuIdleTicks,
) {
	if (
		!Number.isFinite(totalTicks) ||
		!Number.isFinite(idleTicks) ||
		totalTicks <= 0 ||
		idleTicks < 0
	) {
		return {
			cpuUsagePercent: 0,
			lastCpuTotalTicks: 0,
			lastCpuIdleTicks: 0,
		};
	}

	let cpuUsagePercent = currentCpuUsagePercent;
	if (
		lastCpuTotalTicks > 0 &&
		totalTicks >= lastCpuTotalTicks &&
		idleTicks >= lastCpuIdleTicks
	) {
		const totalDelta = totalTicks - lastCpuTotalTicks;
		const idleDelta = idleTicks - lastCpuIdleTicks;
		if (totalDelta > 0)
			cpuUsagePercent = Math.max(
				0,
				Math.min(
					100,
					Math.round(((totalDelta - idleDelta) / totalDelta) * 100),
				),
			);
	}

	return {
		cpuUsagePercent: cpuUsagePercent,
		lastCpuTotalTicks: totalTicks,
		lastCpuIdleTicks: idleTicks,
	};
}

function parseAggregateStatus(
	output,
	currentCpuUsagePercent,
	lastCpuTotalTicks,
	lastCpuIdleTicks,
	currentCoreUsages,
	lastCpuCoreTotalTicks,
	lastCpuCoreIdleTicks,
) {
	const data = parseKeyValueOutput(output);
	const cpuCoreSamples = parseCpuCoreSamples(data);
	const cpuCoreTypes = classifyCpuCoreTypes(
		parseCpuCoreMaxFrequencies(data, cpuCoreSamples.length),
	);
	const memTotalKb = parseFloat(data.memTotalKb || "0");
	const memAvailableKb = parseFloat(data.memAvailableKb || "0");
	const swapTotalKb = parseFloat(data.swapTotalKb || "0");
	const swapFreeKb = parseFloat(data.swapFreeKb || "0");
	const memoryTotalBytes = Math.max(memTotalKb, 0) * 1024;
	const memoryUsedBytes = Math.max(memTotalKb - memAvailableKb, 0) * 1024;
	const swapTotalBytes = Math.max(swapTotalKb, 0) * 1024;
	const swapUsedBytes = Math.max(swapTotalKb - swapFreeKb, 0) * 1024;
	const cpuUsage = updateCpuUsage(
		parseFloat(data.cpuTotalTicks || "0"),
		parseFloat(data.cpuIdleTicks || "0"),
		currentCpuUsagePercent,
		lastCpuTotalTicks,
		lastCpuIdleTicks,
	);
	const cpuCoreUsage = updateCpuCoreUsages(
		cpuCoreSamples,
		currentCoreUsages,
		lastCpuCoreTotalTicks,
		lastCpuCoreIdleTicks,
		cpuCoreTypes,
	);

	return {
		memoryTotalBytes: memoryTotalBytes,
		memoryUsedBytes: memoryUsedBytes,
		memoryPercent:
			memoryTotalBytes > 0
				? Math.round((memoryUsedBytes / memoryTotalBytes) * 100)
				: 0,
		swapTotalBytes: swapTotalBytes,
		swapUsedBytes: swapUsedBytes,
		swapPercent:
			swapTotalBytes > 0
				? Math.round((swapUsedBytes / swapTotalBytes) * 100)
				: 0,
		cpuUsagePercent: cpuUsage.cpuUsagePercent,
		cpuCores: cpuCoreUsage.cpuCores,
		lastCpuTotalTicks: cpuUsage.lastCpuTotalTicks,
		lastCpuIdleTicks: cpuUsage.lastCpuIdleTicks,
		lastCpuCoreTotalTicks: cpuCoreUsage.lastCpuCoreTotalTicks,
		lastCpuCoreIdleTicks: cpuCoreUsage.lastCpuCoreIdleTicks,
	};
}
