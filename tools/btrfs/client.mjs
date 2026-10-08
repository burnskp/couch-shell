import net from "node:net";

const socket = net.createConnection("/run/couch-shell/btrfs.sock");
let output = "";
const timer = setTimeout(
	() => socket.destroy(new Error("Collector timeout")),
	55000,
);
socket.setEncoding("utf8");
socket.on("data", (chunk) => {
	output += chunk;
	if (output.length > 16 * 1024 * 1024)
		socket.destroy(new Error("Report too large"));
});
socket.on("end", () => {
	try {
		const report = JSON.parse(output);
		if (report.version !== 1 || !Array.isArray(report.filesystems))
			throw new Error("Invalid report");
		process.stdout.write(`${JSON.stringify(report)}\n`);
	} catch {
		process.exitCode = 1;
	}
});
socket.on("error", () => {
	process.exitCode = 1;
});
socket.on("close", () => clearTimeout(timer));
for (const signal of ["SIGTERM", "SIGINT"])
	process.on(signal, () => {
		socket.destroy();
		process.exitCode = 1;
	});
