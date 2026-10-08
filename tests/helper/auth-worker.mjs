import {
	ensureFreshCredentials,
	storeCredentials,
	withAuthLock,
} from "../../tools/couch-ai-codex.mjs";

const [command, value] = process.argv.slice(2);
const credentials = (refresh) => ({
	access: "fake-access",
	refresh,
	expires: 0,
});
try {
	if (command === "refresh") {
		await ensureFreshCredentials(true, async () => {
			process.send({ ready: true });
			await new Promise((resolve) => process.once("message", resolve));
			return credentials("refreshed");
		});
	} else if (command === "login") {
		await storeCredentials(credentials(value));
	} else if (command === "hold") {
		await withAuthLock(async () => {
			process.send({ ready: true });
			await new Promise((resolve) => process.once("message", resolve));
		});
	}
} catch (error) {
	process.send?.({ error: error.message });
	process.exitCode = 1;
} finally {
	process.disconnect?.();
}
