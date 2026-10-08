// Test-only preload: never allow an unexpected request to reach the network.
import { appendFileSync } from "node:fs";

const nativeFetch = globalThis.fetch;
const fixture = JSON.parse(process.env.TEST_MODEL_FETCH || "{}");
globalThis.fetch = async (url, options = {}) => {
	const parsed = new URL(url);
	const discovery =
		url === "https://api.github.com/repos/openai/codex/releases/latest";
	if (process.env.TEST_MODEL_REQUEST_LOG) {
		appendFileSync(
			process.env.TEST_MODEL_REQUEST_LOG,
			JSON.stringify({
				url,
				discovery,
				version: options.headers?.version,
				etag: options.headers?.["If-None-Match"],
				authenticated: Boolean(options.headers?.Authorization),
			}) + "\n",
		);
	}
	if (discovery) {
		return new Response(
			JSON.stringify(
				fixture.release ?? {
					tag_name: "rust-v0.159.2",
					draft: false,
					prerelease: false,
				},
			),
			{ status: fixture.releaseStatus ?? 200 },
		);
	}
	if (parsed.hostname === "127.0.0.1" && !fixture.catalog) {
		return nativeFetch(url, options);
	}
	if (fixture.catalog && parsed.hostname === "models.test") {
		const {
			status = 200,
			body = { models: [{ slug: "new-model", visibility: "list" }] },
		} = fixture.catalog;
		return new Response(status === 304 ? null : JSON.stringify(body), {
			status,
			headers: { etag: "new-etag" },
		});
	}
	throw new Error("Unexpected test network request");
};
