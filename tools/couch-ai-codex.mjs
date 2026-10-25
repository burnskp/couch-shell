#!/usr/bin/env node
import { spawn } from "node:child_process";
import { createHash, randomBytes, randomUUID } from "node:crypto";
import {
	chmod,
	mkdir,
	open,
	readFile,
	rename,
	writeFile,
} from "node:fs/promises";
import { createServer } from "node:http";
import { arch, homedir, platform, release } from "node:os";
import { dirname, join } from "node:path";
import { pathToFileURL } from "node:url";

const DATA_DIR = join(homedir(), ".local", "share", "couch-shell");
const AUTH_FILE =
	process.env.COUCH_SHELL_AUTH_FILE || join(DATA_DIR, "auth.json");
const AI_STATE_FILE =
	process.env.COUCH_SHELL_AI_STATE_FILE || join(DATA_DIR, "ai-state.json");
const AI_MODELS_FILE =
	process.env.COUCH_SHELL_AI_MODELS_FILE || join(DATA_DIR, "ai-models.json");
const AI_STATE_VERSION = 1;
const AI_MODELS_VERSION = 1;
const AUTH_PROVIDER = "openai-codex";
const CALLBACK_HOST =
	process.env.COUCH_SHELL_OAUTH_CALLBACK_HOST || "127.0.0.1";
const CALLBACK_PORT = Number(
	process.env.COUCH_SHELL_OAUTH_CALLBACK_PORT || "1455",
);
const CLIENT_ID = "app_EMoamEEZ73f0CkXaXp7hrann";
const AUTHORIZE_URL = "https://auth.openai.com/oauth/authorize";
const TOKEN_URL = "https://auth.openai.com/oauth/token";
const REDIRECT_URI = `http://localhost:${CALLBACK_PORT}/auth/callback`;
const SCOPE = "openid profile email offline_access";
const JWT_CLAIM_PATH = "https://api.openai.com/auth";
const CODEX_BASE_URL =
	process.env.COUCH_SHELL_CODEX_BASE_URL || "https://chatgpt.com/backend-api";
const ORIGINATOR = process.env.COUCH_SHELL_CODEX_ORIGINATOR || "pi";
const CLAUDE_CREDENTIALS_FILE =
	process.env.COUCH_SHELL_CLAUDE_CREDENTIALS_FILE ||
	join(
		process.env.CLAUDE_CONFIG_DIR || join(homedir(), ".claude"),
		".credentials.json",
	);
const CLAUDE_USAGE_URL =
	process.env.COUCH_SHELL_CLAUDE_USAGE_URL ||
	"https://api.anthropic.com/api/oauth/usage";
const CLAUDE_SIGN_IN_MESSAGE = "Sign in to Claude Code to track Claude usage.";
const CLAUDE_EXPIRED_MESSAGE =
	"Claude Code sign-in expired. Open Claude Code to refresh it.";
const CODEX_RELEASE_URL =
	"https://api.github.com/repos/openai/codex/releases/latest";
const DEFAULT_MODEL = "gpt-5.5";
const DEFAULT_REASONING = "medium";
const DEFAULT_TEXT_VERBOSITY = "low";
const DEBUG = /^(1|true|yes|on)$/i.test(process.env.COUCH_SHELL_DEBUG || "");
const MAX_RETRIES = 3;
const BASE_DELAY_MS = 1000;
const TOKEN_REFRESH_SKEW_MS = 60_000;
const RETRYABLE_STATUSES = new Set([429, 500, 502, 503, 504]);
const COMPLETION_EVENT_TYPES = new Set([
	"response.completed",
	"response.done",
	"response.incomplete",
]);
const WEB_SEARCH_EVENT_TYPES = new Set([
	"response.web_search_call.in_progress",
	"response.web_search_call.searching",
	"response.web_search_call.completed",
]);

function jsonOut(value) {
	process.stdout.write(`${JSON.stringify(value)}\n`);
}

function fail(message, extra = {}) {
	jsonOut({ type: "error", message, ...extra });
	process.exitCode = 1;
}

function debugOut(message, extra = {}) {
	if (!DEBUG) return;
	jsonOut({ type: "debug", message, ...extra });
}

function base64Url(buffer) {
	return Buffer.from(buffer)
		.toString("base64")
		.replace(/=/g, "")
		.replace(/\+/g, "-")
		.replace(/\//g, "_");
}

function decodeJwtPayload(token) {
	const parts = String(token || "").split(".");
	if (parts.length !== 3) return null;
	try {
		const payload = parts[1].replace(/-/g, "+").replace(/_/g, "/");
		return JSON.parse(Buffer.from(payload, "base64").toString("utf8"));
	} catch {
		return null;
	}
}

function accountIdFromAccess(access) {
	const payload = decodeJwtPayload(access);
	const accountId = payload?.[JWT_CLAIM_PATH]?.chatgpt_account_id;
	if (typeof accountId !== "string" || accountId.length === 0) {
		throw new Error("Failed to extract ChatGPT account id from token");
	}
	return accountId;
}

async function readAuthFile() {
	try {
		const raw = await readFile(AUTH_FILE, "utf8");
		const parsed = JSON.parse(raw);
		return parsed && typeof parsed === "object" && !Array.isArray(parsed)
			? parsed
			: {};
	} catch (error) {
		if (error?.code === "ENOENT") return null;
		throw error;
	}
}

async function writeJsonFile(path, data) {
	await mkdir(dirname(path), { recursive: true, mode: 0o700 });
	const tmp = `${path}.${process.pid}.tmp`;
	await writeFile(tmp, `${JSON.stringify(data, null, 2)}\n`, { mode: 0o600 });
	await chmod(tmp, 0o600);
	await rename(tmp, path);
	await chmod(path, 0o600);
}

async function writeAuthFile(data) {
	await writeJsonFile(AUTH_FILE, data);
}

function normalizeCredentials(entry) {
	if (!entry || typeof entry !== "object") return null;
	if (entry.type && entry.type !== "oauth") return null;
	if (
		typeof entry.access !== "string" ||
		typeof entry.refresh !== "string" ||
		typeof entry.expires !== "number"
	)
		return null;
	return entry;
}

// flock locks the shared open-file description. The parent retains the descriptor
// after flock exits; closing it (including process death) releases the lock.
export async function withAuthLock(transaction) {
	await mkdir(dirname(AUTH_FILE), { recursive: true, mode: 0o700 });
	const lock = await open(`${AUTH_FILE}.lock`, "a", 0o600);
	try {
		await lock.chmod(0o600);
		await new Promise((resolve, reject) => {
			const child = spawn("flock", ["--exclusive", "--timeout", "5", "3"], {
				stdio: ["ignore", "ignore", "pipe", lock.fd],
			});
			child.on("error", reject);
			child.on("exit", (code) =>
				code === 0
					? resolve()
					: reject(new Error("Authentication lock acquisition failed")),
			);
		});
		const existing = await readAuthFile();
		const auth = existing || {};
		if (
			typeof auth._couchShellAuthGeneration !== "string" ||
			!auth._couchShellAuthGeneration
		) {
			auth._couchShellAuthGeneration = randomUUID();
			if (existing) await writeAuthFile(auth);
		}
		return await transaction(auth);
	} finally {
		await lock.close();
	}
}

async function credentialSnapshot() {
	return withAuthLock((auth) => ({
		credentials: normalizeCredentials(auth[AUTH_PROVIDER]),
		generation: auth._couchShellAuthGeneration,
	}));
}

async function getStoredCredentials() {
	return (await credentialSnapshot()).credentials;
}

export async function storeCredentials(credentials, expectedGeneration) {
	return withAuthLock(async (auth) => {
		if (
			expectedGeneration !== undefined &&
			auth._couchShellAuthGeneration !== expectedGeneration
		)
			throw new Error("Authentication session changed; sign in again");
		auth._couchShellAuthGeneration = randomUUID();
		auth[AUTH_PROVIDER] = { type: "oauth", ...credentials };
		await writeAuthFile(auth);
	});
}

export async function deleteCredentials() {
	return withAuthLock(async (auth) => {
		delete auth[AUTH_PROVIDER];
		auth._couchShellAuthGeneration = randomUUID();
		await writeAuthFile(auth);
	});
}

function publicStatusForCredentials(credentials) {
	if (!credentials) {
		return {
			type: "status",
			configured: false,
			provider: AUTH_PROVIDER,
			authFile: AUTH_FILE,
		};
	}
	const expiresInMs = Math.max(0, credentials.expires - Date.now());
	return {
		type: "status",
		configured: true,
		provider: AUTH_PROVIDER,
		authFile: AUTH_FILE,
		accountId:
			typeof credentials.accountId === "string"
				? credentials.accountId
				: undefined,
		expired: expiresInMs <= 0,
		expiresAt: credentials.expires,
		expiresInMs,
	};
}

async function exchangeToken(params) {
	const response = await fetch(TOKEN_URL, {
		method: "POST",
		headers: { "Content-Type": "application/x-www-form-urlencoded" },
		body: new URLSearchParams(params),
	});
	if (!response.ok) {
		const text = await response.text().catch(() => "");
		throw new Error(
			`OpenAI token request failed (${response.status}): ${text}`,
		);
	}
	const json = await response.json();
	if (
		!json.access_token ||
		!json.refresh_token ||
		typeof json.expires_in !== "number"
	) {
		throw new Error("OpenAI token response missing expected fields");
	}
	const credentials = {
		access: json.access_token,
		refresh: json.refresh_token,
		expires: Date.now() + json.expires_in * 1000,
	};
	return { ...credentials, accountId: accountIdFromAccess(credentials.access) };
}

async function refreshCredentials(credentials) {
	return exchangeToken({
		grant_type: "refresh_token",
		refresh_token: credentials.refresh,
		client_id: CLIENT_ID,
	});
}

export async function ensureFreshCredentials(
	force = false,
	exchange = refreshCredentials,
) {
	const { credentials, generation } = await credentialSnapshot();
	if (!credentials)
		throw new Error(`Not signed in. Run: ${process.argv[1]} login`);
	if (!force && Date.now() < credentials.expires - TOKEN_REFRESH_SKEW_MS)
		return credentials;
	const refreshed = await exchange(credentials);
	return withAuthLock(async (auth) => {
		if (
			auth._couchShellAuthGeneration !== generation ||
			auth[AUTH_PROVIDER]?.refresh !== credentials.refresh
		)
			throw new Error("Authentication session changed during refresh");
		auth[AUTH_PROVIDER] = { type: "oauth", ...refreshed };
		await writeAuthFile(auth);
		return auth[AUTH_PROVIDER];
	});
}

async function generatePkce() {
	const verifier = base64Url(randomBytes(32));
	const challenge = base64Url(createHash("sha256").update(verifier).digest());
	return { verifier, challenge };
}

function authUrlForFlow(verifierChallenge, state) {
	const url = new URL(AUTHORIZE_URL);
	url.searchParams.set("response_type", "code");
	url.searchParams.set("client_id", CLIENT_ID);
	url.searchParams.set("redirect_uri", REDIRECT_URI);
	url.searchParams.set("scope", SCOPE);
	url.searchParams.set("code_challenge", verifierChallenge);
	url.searchParams.set("code_challenge_method", "S256");
	url.searchParams.set("state", state);
	url.searchParams.set("id_token_add_organizations", "true");
	url.searchParams.set("codex_cli_simplified_flow", "true");
	url.searchParams.set("originator", ORIGINATOR);
	return url.toString();
}

function oauthHtml(title, body) {
	return `<!doctype html><html><head><meta charset="utf-8"><title>${title}</title></head><body style="font-family:sans-serif;max-width:42rem;margin:4rem auto;line-height:1.5"><h1>${title}</h1><p>${body}</p></body></html>`;
}

export function waitForCallback(
	expectedState,
	{
		port = CALLBACK_PORT,
		host = CALLBACK_HOST,
		timeoutMs = 5 * 60 * 1000,
		onListening = () => {},
		serverFactory = createServer,
	} = {},
) {
	return new Promise((resolve, reject) => {
		let settled = false;
		let timer;
		const settle = (error, value) => {
			if (settled) return;
			settled = true;
			clearTimeout(timer);
			server.close(() => (error ? reject(error) : resolve(value)));
			server.closeAllConnections();
		};
		const server = serverFactory((req, res) => {
			const reply = (status, message) => {
				res.writeHead(status, {
					"Content-Type": "text/html; charset=utf-8",
					Connection: "close",
				});
				res.end(oauthHtml("OpenAI authentication", message));
			};
			let url;
			try {
				url = new URL(req.url || "", "http://localhost");
			} catch {
				reply(400, "Invalid callback.");
				return;
			}
			if (url.pathname !== "/auth/callback") {
				reply(404, "Callback route not found.");
				return;
			}
			if (url.searchParams.get("state") !== expectedState) {
				reply(400, "State mismatch.");
				return;
			}
			if (url.searchParams.has("error")) {
				reply(400, "Authorization was denied by the provider.");
				settle(new Error("OAuth provider rejected authorization"));
				return;
			}
			const code = url.searchParams.get("code");
			if (!code?.trim()) {
				reply(400, "Missing authorization code.");
				return;
			}
			reply(200, "Authentication completed. You can close this window.");
			settle(null, { code });
		});
		server.on("error", (error) => settle(error));
		timer = setTimeout(
			() => settle(new Error("OAuth login timed out")),
			timeoutMs,
		);
		try {
			server.listen(port, host, () => {
				try {
					onListening(server.address());
				} catch (error) {
					settle(error);
				}
			});
		} catch (error) {
			settle(error);
		}
	});
}

async function readStdin() {
	const chunks = [];
	for await (const chunk of process.stdin) chunks.push(chunk);
	return Buffer.concat(chunks).toString("utf8");
}

async function readStdinLine() {
	let buffer = "";
	for await (const chunk of process.stdin) {
		buffer += chunk.toString("utf8");
		const index = buffer.indexOf("\n");
		if (index !== -1) return buffer.slice(0, index);
	}
	return buffer;
}

async function loginCommand() {
	const { verifier, challenge } = await generatePkce();
	const state = randomBytes(16).toString("hex");
	const url = authUrlForFlow(challenge, state);

	const generation = await withAuthLock(async (auth) => {
		auth._couchShellAuthGeneration = randomUUID();
		await writeAuthFile(auth);
		return auth._couchShellAuthGeneration;
	});
	const callback = await waitForCallback(state, {
		onListening: () =>
			jsonOut({
				type: "auth_url",
				url,
				callback: REDIRECT_URI,
				authFile: AUTH_FILE,
			}),
	});
	if (!callback?.code) {
		throw new Error(
			`OAuth callback failed or callback server unavailable on ${CALLBACK_HOST}:${CALLBACK_PORT}`,
		);
	}
	jsonOut({
		type: "login_progress",
		message: "Authorization approved. Exchanging token…",
	});
	const credentials = await exchangeToken({
		grant_type: "authorization_code",
		client_id: CLIENT_ID,
		code: callback.code,
		code_verifier: verifier,
		redirect_uri: REDIRECT_URI,
	});
	await storeCredentials(credentials, generation);
	jsonOut({
		type: "login_complete",
		...publicStatusForCredentials({ type: "oauth", ...credentials }),
	});
}

function codexUrl() {
	const normalized = CODEX_BASE_URL.replace(/\/+$/, "");
	if (normalized.endsWith("/codex/responses")) return normalized;
	if (normalized.endsWith("/codex")) return `${normalized}/responses`;
	return `${normalized}/codex/responses`;
}

function codexModelsUrl() {
	const configured = process.env.COUCH_SHELL_CODEX_MODELS_URL || "";
	if (configured.length > 0) return configured;

	const normalized = CODEX_BASE_URL.replace(/\/+$/, "");
	if (normalized.endsWith("/codex/models")) return normalized;
	if (normalized.endsWith("/codex/responses"))
		return normalized.replace(/\/responses$/, "/models");
	if (normalized.endsWith("/codex")) return `${normalized}/models`;
	return `${normalized}/codex/models`;
}

function withClientVersion(urlString, clientVersion) {
	const url = new URL(urlString);
	url.searchParams.set("client_version", clientVersion);
	return url.toString();
}

export async function discoverCodexClientVersion({
	fetchImpl = fetch,
	timeoutMs = 5000,
} = {}) {
	const controller = new AbortController();
	const timeout = setTimeout(() => controller.abort(), timeoutMs);
	try {
		const response = await fetchImpl(CODEX_RELEASE_URL, {
			headers: {
				accept: "application/vnd.github+json",
				"User-Agent": "couch-shell",
			},
			signal: controller.signal,
		});
		if (!response.ok) throw new Error(`HTTP ${response.status}`);
		const release = await response.json();
		const version =
			typeof release?.tag_name === "string"
				? /^rust-v((?:0|[1-9]\d*)\.(?:0|[1-9]\d*)\.(?:0|[1-9]\d*))$/.exec(
						release.tag_name,
					)
				: null;
		if (!version || release.draft !== false || release.prerelease !== false)
			throw new Error("Invalid stable Codex release metadata");
		return version[1];
	} catch (error) {
		throw new Error(
			`Codex release discovery failed: ${controller.signal.aborted ? "request timed out" : error.message}`,
		);
	} finally {
		clearTimeout(timeout);
	}
}

function clampReasoning(model, effort) {
	const id = String(model || "")
		.split("/")
		.pop();
	const minimalUnsupported =
		id.startsWith("gpt-5.2") ||
		id.startsWith("gpt-5.3") ||
		id.startsWith("gpt-5.4") ||
		id.startsWith("gpt-5.5");
	if (minimalUnsupported && effort === "minimal") return "low";
	if (id === "gpt-5.1" && effort === "xhigh") return "high";
	if (id === "gpt-5.1-codex-mini")
		return effort === "high" || effort === "xhigh" ? "high" : "medium";
	return effort;
}

function messageContent(message) {
	if (!message) return "";
	if (typeof message.content === "string") return message.content;
	if (Array.isArray(message.content)) {
		return message.content
			.map((part) =>
				typeof part === "string" ? part : part?.text || part?.content || "",
			)
			.filter(Boolean)
			.join("\n");
	}
	return String(message.content || "");
}

function responsesInput(messages) {
	const input = [];
	for (const message of messages || []) {
		const text = messageContent(message);
		if (!text.trim()) continue;
		if (message.role === "assistant") {
			input.push({
				type: "message",
				role: "assistant",
				content: [{ type: "output_text", text, annotations: [] }],
				status: "completed",
				id: `msg_${input.length}`,
			});
		} else if (message.role === "user") {
			input.push({ role: "user", content: [{ type: "input_text", text }] });
		}
	}
	return input;
}

function buildChatBody(request) {
	const model = request.model || DEFAULT_MODEL;
	const reasoningEffort =
		request.reasoning || request.reasoningEffort || DEFAULT_REASONING;
	const body = {
		model,
		store: false,
		stream: request.stream !== false,
		instructions: request.instructions || request.systemPrompt || undefined,
		input: responsesInput(request.messages || []),
		text: { verbosity: request.textVerbosity || DEFAULT_TEXT_VERBOSITY },
		prompt_cache_key: request.sessionId || undefined,
		tool_choice: "auto",
		parallel_tool_calls: true,
	};
	if (reasoningEffort !== "none") {
		body.include = ["reasoning.encrypted_content"];
		body.reasoning = {
			effort: clampReasoning(model, reasoningEffort),
			summary: request.reasoningSummary ?? "auto",
		};
	}
	if (request.webSearchMode === "live") {
		body.tools = [{ type: "web_search", external_web_access: true }];
	}
	if (request.temperature !== undefined) body.temperature = request.temperature;
	return body;
}

function isRetryable(status, text) {
	return (
		RETRYABLE_STATUSES.has(status) ||
		/rate.?limit|overloaded|service.?unavailable|upstream.?connect|connection.?refused/i.test(
			text,
		)
	);
}

function sleep(ms) {
	return new Promise((resolve) => setTimeout(resolve, ms));
}

async function postCodex(body, credentials, sessionId) {
	debugOut("posting Codex request", {
		model: body.model,
		inputItems: Array.isArray(body.input) ? body.input.length : 0,
		tools: Array.isArray(body.tools) ? body.tools.map((tool) => tool.type) : [],
		reasoning: body.reasoning,
		webSearch:
			Array.isArray(body.tools) &&
			body.tools.some((tool) => tool.type === "web_search"),
	});
	const headers = {
		Authorization: `Bearer ${credentials.access}`,
		"chatgpt-account-id":
			credentials.accountId || accountIdFromAccess(credentials.access),
		originator: ORIGINATOR,
		"User-Agent": `couch-shell (${platform()} ${release()}; ${arch()})`,
		"OpenAI-Beta": "responses=experimental",
		accept: "text/event-stream",
		"content-type": "application/json",
	};
	if (sessionId) {
		headers.session_id = sessionId;
		headers["x-client-request-id"] = sessionId;
	}
	const json = JSON.stringify(body);
	let lastError;
	for (let attempt = 0; attempt <= MAX_RETRIES; attempt++) {
		try {
			debugOut("Codex fetch attempt", {
				attempt: attempt + 1,
				maxAttempts: MAX_RETRIES + 1,
			});
			const response = await fetch(codexUrl(), {
				method: "POST",
				headers,
				body: json,
			});
			debugOut("Codex response status", {
				status: response.status,
				ok: response.ok,
			});
			if (response.ok) return response;
			const text = await response.text().catch(() => "");
			if (attempt < MAX_RETRIES && isRetryable(response.status, text)) {
				await sleep(BASE_DELAY_MS * 2 ** attempt);
				continue;
			}
			throw new Error(`Codex request failed (${response.status}): ${text}`);
		} catch (error) {
			lastError = error;
			if (
				attempt < MAX_RETRIES &&
				!String(error?.message || error).includes("usage limit")
			) {
				await sleep(BASE_DELAY_MS * 2 ** attempt);
				continue;
			}
			throw error;
		}
	}
	throw lastError || new Error("Codex request failed");
}

function normalizeReasoningOptions(value) {
	if (!Array.isArray(value)) return [];
	const options = [];
	const seen = new Set();
	for (const item of value) {
		const effort =
			typeof item === "string"
				? item
				: item?.effort ||
					item?.reasoningEffort ||
					item?.reasoning_effort ||
					item?.value;
		if (typeof effort !== "string" || effort.length === 0 || seen.has(effort))
			continue;
		seen.add(effort);
		options.push(effort);
	}
	return options;
}

function normalizeModelEntry(model, index = 0) {
	const source = typeof model === "string" ? { model } : model;
	if (!source || typeof source !== "object" || Array.isArray(source))
		return null;

	const id =
		source.model ||
		source.slug ||
		source.id ||
		source.name ||
		source.display_name ||
		source.displayName;
	if (typeof id !== "string" || id.trim().length === 0) return null;
	const visibility =
		typeof source.visibility === "string"
			? source.visibility.toLowerCase()
			: "";
	if (visibility === "hide" || visibility === "hidden") return null;

	const modelId = id.trim();
	return {
		id: `${modelId}-codex-oauth`,
		model: modelId,
		label: source.label || source.displayName || source.display_name || modelId,
		displayName:
			source.displayName || source.display_name || source.label || modelId,
		description:
			typeof source.description === "string" ? source.description : "",
		defaultReasoningEffort:
			source.defaultReasoningEffort ||
			source.default_reasoning_level ||
			source.default_reasoning_effort ||
			"",
		supportedReasoningEfforts: normalizeReasoningOptions(
			source.supportedReasoningEfforts || source.supported_reasoning_levels,
		),
		supportsFiles:
			Boolean(source.supportsFiles) ||
			(Array.isArray(source.input_modalities) &&
				source.input_modalities.includes("image")) ||
			(Array.isArray(source.inputModalities) &&
				source.inputModalities.includes("image")),
		supportsTools: source.supportsTools !== false,
		isDefault: Boolean(source.isDefault || source.is_default),
		priority: typeof source.priority === "number" ? source.priority : index,
	};
}

function normalizeModels(models) {
	const entries = [];
	const seen = new Set();
	for (const item of models || []) {
		const entry = normalizeModelEntry(item, entries.length);
		if (!entry || seen.has(entry.model)) continue;
		seen.add(entry.model);
		entries.push(entry);
	}
	entries.sort((a, b) => a.priority - b.priority);
	return entries;
}

function emptyModelsCache() {
	return {
		version: AI_MODELS_VERSION,
		clientVersion: "",
		updatedAt: 0,
		etag: "",
		models: [],
	};
}

function normalizeModelsCache(value) {
	if (!value || typeof value !== "object" || Array.isArray(value)) {
		throw new Error("AI model cache must be a JSON object");
	}

	const models = normalizeModels(value.models);
	return {
		version: AI_MODELS_VERSION,
		clientVersion:
			typeof value.clientVersion === "string" ? value.clientVersion : "",
		updatedAt: typeof value.updatedAt === "number" ? value.updatedAt : 0,
		etag: typeof value.etag === "string" ? value.etag : "",
		models,
	};
}

function modelsFromResponse(json) {
	if (Array.isArray(json)) return normalizeModels(json);
	if (!json || typeof json !== "object") return [];
	return normalizeModels(
		json.models || json.data || json.available_models || [],
	);
}

async function readModelsCacheFile() {
	try {
		const raw = await readFile(AI_MODELS_FILE, "utf8");
		return normalizeModelsCache(JSON.parse(raw));
	} catch (error) {
		if (error?.code === "ENOENT") return emptyModelsCache();
		throw error;
	}
}

async function writeModelsCache(cache, options = {}) {
	const normalized = normalizeModelsCache({
		...cache,
		updatedAt: options.touchUpdatedAt ? Date.now() : cache.updatedAt,
	});
	await writeJsonFile(AI_MODELS_FILE, normalized);
	return normalized;
}

async function fetchModels(credentials, cache, clientVersion) {
	const headers = {
		Authorization: `Bearer ${credentials.access}`,
		"chatgpt-account-id":
			credentials.accountId || accountIdFromAccess(credentials.access),
		"OpenAI-Beta": "responses=experimental",
		originator: ORIGINATOR,
		version: clientVersion,
		"User-Agent": `couch-shell (${platform()} ${release()}; ${arch()})`,
		accept: "application/json",
	};
	const canRevalidate =
		cache?.etag &&
		cache.models?.length > 0 &&
		cache.clientVersion === clientVersion;
	if (canRevalidate) headers["If-None-Match"] = cache.etag;

	const controller = new AbortController();
	const timeout = setTimeout(() => controller.abort(), 8000);
	try {
		const response = await fetch(
			withClientVersion(codexModelsUrl(), clientVersion),
			{
				method: "GET",
				headers,
				signal: controller.signal,
			},
		);
		if (response.status === 304 && canRevalidate) {
			return {
				models: cache.models,
				etag: cache.etag,
				notModified: true,
			};
		}
		if (!response.ok) {
			const text = await response.text().catch(() => "");
			throw new Error(
				`Codex models request failed (${response.status}): ${text}`,
			);
		}
		const json = await response.json();
		const models = modelsFromResponse(json);
		if (models.length === 0)
			throw new Error("Codex models response did not include models");
		return {
			models,
			etag:
				response.headers.get("etag") ||
				response.headers.get("x-models-etag") ||
				"",
			notModified: false,
		};
	} catch (error) {
		throw new Error(
			`Codex model catalog refresh failed: ${controller.signal.aborted ? "request timed out" : error.message}`,
		);
	} finally {
		clearTimeout(timeout);
	}
}

async function* parseSse(response) {
	const reader = response.body?.getReader();
	if (!reader) return;
	const decoder = new TextDecoder();
	let buffer = "";
	while (true) {
		const { done, value } = await reader.read();
		if (done) break;
		buffer += decoder.decode(value, { stream: true });
		let idx = buffer.indexOf("\n\n");
		while (idx !== -1) {
			const chunk = buffer.slice(0, idx);
			buffer = buffer.slice(idx + 2);
			const data = chunk
				.split("\n")
				.filter((line) => line.startsWith("data:"))
				.map((line) => line.slice(5).trim())
				.join("\n")
				.trim();
			if (data && data !== "[DONE]") {
				try {
					yield JSON.parse(data);
				} catch {}
			}
			idx = buffer.indexOf("\n\n");
		}
	}
}

function debugPayloadForEvent(event, state) {
	const type = event?.type || "unknown";
	const payload = { eventType: type };
	if (event?.response?.id) payload.responseId = event.response.id;
	if (event?.response?.status) payload.status = event.response.status;
	if (event?.item?.type) payload.itemType = event.item.type;
	if (event?.delta || event?.text)
		payload.chars = String(event.delta || event.text || "").length;
	if (type === "response.output_text.delta" || type === "response.text.delta")
		payload.accumulatedChars = state.text.length;
	return payload;
}

function textFromReasoningPart(part) {
	if (typeof part === "string") return part;
	if (typeof part?.text === "string") return part.text;
	if (typeof part?.summary_text === "string") return part.summary_text;
	return "";
}

function reasoningTextFromItem(item) {
	if (!item || item.type !== "reasoning") return "";
	if (typeof item.text === "string") return item.text;
	if (typeof item.summary_text === "string") return item.summary_text;

	const parts = [];
	for (const key of ["summary", "content"]) {
		if (!Array.isArray(item[key])) continue;
		for (const part of item[key]) {
			const text = textFromReasoningPart(part);
			if (text) parts.push(text);
		}
	}
	return parts.join("\n");
}

function usageFromResponse(response) {
	const usage = response?.usage;
	if (!usage) return undefined;
	const input = usage.input_tokens ?? usage.input ?? 0;
	const output = usage.output_tokens ?? usage.output ?? 0;
	return { input, output, total: usage.total_tokens ?? input + output };
}

function emitCodexEvent(event, state) {
	const type = event?.type;
	if (!type) return;
	debugOut("Codex stream event", debugPayloadForEvent(event, state));
	if (type === "error")
		throw new Error(
			`Codex error: ${event.message || event.code || JSON.stringify(event)}`,
		);
	if (type === "response.failed")
		throw new Error(event.response?.error?.message || "Codex response failed");
	if (type === "response.created")
		jsonOut({ type: "start", responseId: event.response?.id });
	if (type === "response.output_text.delta" || type === "response.text.delta") {
		const delta = event.delta || event.text || "";
		if (delta) {
			state.text += delta;
			jsonOut({ type: "text_delta", delta });
		}
	}
	if (
		type === "response.reasoning_summary_text.delta" ||
		type === "response.reasoning_text.delta"
	) {
		const delta = event.delta || event.text || "";
		if (delta) {
			state.reasoning += delta;
			jsonOut({ type: "reasoning_delta", delta });
		}
	}
	if (
		type === "response.output_item.done" &&
		event.item?.type === "reasoning"
	) {
		const reasoning = reasoningTextFromItem(event.item);
		if (reasoning && state.reasoning.length === 0) {
			state.reasoning = reasoning;
			jsonOut({ type: "reasoning_delta", delta: reasoning });
		}
	}
	if (type === "response.output_item.done" && event.item?.type === "message") {
		const content = event.item.content || [];
		for (const part of content) {
			if (
				part.type === "output_text" &&
				typeof part.text === "string" &&
				state.text.length === 0
			) {
				state.text += part.text;
				jsonOut({ type: "text_delta", delta: part.text });
			}
			if (Array.isArray(part.annotations) && part.annotations.length > 0) {
				jsonOut({ type: "annotations", annotations: part.annotations });
			}
		}
	}
	if (WEB_SEARCH_EVENT_TYPES.has(type)) {
		jsonOut({
			type: "web_search",
			status: type.split(".").pop(),
			item: event.item || event,
		});
	}
	if (COMPLETION_EVENT_TYPES.has(type)) {
		state.done = true;
		const response = event.response || {};
		jsonOut({
			type: "done",
			responseId: response.id,
			status: response.status,
			usage: usageFromResponse(response),
			text: state.text,
		});
	}
}

async function chatCommand() {
	const raw = await readStdinLine();
	const request = raw.trim() ? JSON.parse(raw) : {};
	debugOut("received chat request", {
		sessionId: request.sessionId,
		model: request.model || DEFAULT_MODEL,
		messages: Array.isArray(request.messages) ? request.messages.length : 0,
		webSearchMode: request.webSearchMode || "disabled",
	});
	const credentials = await ensureFreshCredentials();
	const body = buildChatBody(request);
	const response = await postCodex(
		body,
		credentials,
		request.sessionId || randomUUID(),
	);
	const state = { text: "", reasoning: "", done: false };
	for await (const event of parseSse(response)) emitCodexEvent(event, state);
	if (!state.done) jsonOut({ type: "done", text: state.text });
}

async function refreshCommand() {
	const refreshed = await ensureFreshCredentials(true);
	jsonOut({
		type: "refresh_complete",
		...publicStatusForCredentials({ type: "oauth", ...refreshed }),
	});
}

function emptyAiState() {
	return {
		version: AI_STATE_VERSION,
		updatedAt: 0,
		activeSessionId: "",
		selectedEngineId: "",
		settings: {},
		sessions: [],
	};
}

function normalizeAiState(value, options = {}) {
	if (!value || typeof value !== "object" || Array.isArray(value)) {
		throw new Error("AI state must be a JSON object");
	}
	const state = { ...value };
	state.version = AI_STATE_VERSION;
	if (options.touchUpdatedAt || typeof state.updatedAt !== "number")
		state.updatedAt = options.touchUpdatedAt ? Date.now() : 0;
	if (!Array.isArray(state.sessions)) state.sessions = [];
	if (typeof state.activeSessionId !== "string") state.activeSessionId = "";
	if (typeof state.selectedEngineId !== "string") state.selectedEngineId = "";
	if (
		!state.settings ||
		typeof state.settings !== "object" ||
		Array.isArray(state.settings)
	)
		state.settings = {};
	return state;
}

async function readAiStateFile() {
	try {
		const raw = await readFile(AI_STATE_FILE, "utf8");
		return normalizeAiState(JSON.parse(raw));
	} catch (error) {
		if (error?.code === "ENOENT") return emptyAiState();
		throw error;
	}
}

async function stateLoadCommand() {
	jsonOut({
		type: "state",
		state: await readAiStateFile(),
		path: AI_STATE_FILE,
	});
}

async function stateSaveCommand() {
	const raw = await readStdinLine();
	const state = raw.trim() ? JSON.parse(raw) : {};
	const normalized = normalizeAiState(state, { touchUpdatedAt: true });
	await writeJsonFile(AI_STATE_FILE, normalized);
	jsonOut({
		type: "state_saved",
		path: AI_STATE_FILE,
		updatedAt: normalized.updatedAt,
	});
}

async function modelsLoadCommand() {
	const cache = await readModelsCacheFile();
	jsonOut({
		type: "models",
		source: cache.updatedAt > 0 ? "cache" : "none",
		path: AI_MODELS_FILE,
		updatedAt: cache.updatedAt,
		models: cache.models,
	});
}

async function modelsRefreshCommand() {
	const cache = await readModelsCacheFile();
	const credentials = await ensureFreshCredentials();
	const clientVersion = await discoverCodexClientVersion();
	const fetched = await fetchModels(credentials, cache, clientVersion);
	const normalized = await writeModelsCache(
		{
			version: AI_MODELS_VERSION,
			clientVersion,
			updatedAt: cache.updatedAt,
			etag: fetched.etag,
			models: fetched.models,
		},
		{ touchUpdatedAt: true },
	);
	jsonOut({
		type: "models",
		source: fetched.notModified ? "cache" : "remote",
		path: AI_MODELS_FILE,
		updatedAt: normalized.updatedAt,
		models: normalized.models,
	});
}

async function payloadCommand() {
	const raw = await readStdin();
	const request = raw.trim() ? JSON.parse(raw) : {};
	jsonOut({ type: "payload", body: buildChatBody(request) });
}

async function logoutCommand() {
	await deleteCredentials();
	jsonOut({ type: "logout_complete", authFile: AUTH_FILE });
}

// Keep the private ChatGPT backend contract behind this provider adapter.
export function normalizeSubscriptionUsage(body, now = Date.now()) {
	const limits = body?.rate_limit;
	const windows = [];
	for (const key of ["primary_window", "secondary_window"]) {
		const value = limits?.[key];
		if (value == null) continue;
		if (
			typeof value.used_percent !== "number" ||
			!Number.isFinite(value.used_percent) ||
			value.used_percent < 0
		)
			throw new Error("Invalid usage percentage");
		const durationSeconds =
			Number.isFinite(value.limit_window_seconds) &&
			value.limit_window_seconds > 0
				? value.limit_window_seconds
				: null;
		const resetsAt =
			Number.isFinite(value.reset_at) && value.reset_at > 0
				? value.reset_at * 1000
				: Number.isFinite(value.reset_after_seconds) &&
						value.reset_after_seconds >= 0
					? now + value.reset_after_seconds * 1000
					: null;
		windows.push({
			id: key,
			remainingPercent: Math.max(0, 100 - value.used_percent),
			durationSeconds,
			resetsAt,
		});
	}
	if (!windows.length) throw new Error("No subscription quota available");
	return {
		id: AUTH_PROVIDER,
		name: "ChatGPT",
		plan: typeof body.plan_type === "string" ? body.plan_type : "",
		updatedAt: now,
		windows,
	};
}

export function subscriptionUsageUrl(base = CODEX_BASE_URL) {
	return `${base.replace(/\/+$/, "").replace(/\/codex(?:\/(?:responses|models))?$/, "")}/wham/usage`;
}

async function fetchUsageJson(
	url,
	headers,
	normalize,
	{ fetchImpl = fetch, timeoutMs = 8000 } = {},
) {
	const controller = new AbortController();
	const timeout = setTimeout(() => controller.abort(), timeoutMs);
	try {
		const response = await fetchImpl(url, {
			method: "GET",
			headers: { ...headers, accept: "application/json" },
			signal: controller.signal,
		});
		if (!response.ok)
			return {
				error: `Usage request failed (HTTP ${response.status})`,
				unauthorized: response.status === 401,
			};
		return { provider: normalize(await response.json()) };
	} catch {
		return {
			error: controller.signal.aborted
				? "Usage request timed out"
				: "Subscription usage unavailable",
		};
	} finally {
		clearTimeout(timeout);
	}
}

export async function fetchSubscriptionUsage(
	credentials,
	{ now = Date.now(), ...options } = {},
) {
	return fetchUsageJson(
		subscriptionUsageUrl(),
		{
			Authorization: `Bearer ${credentials.access}`,
			"chatgpt-account-id":
				credentials.accountId || accountIdFromAccess(credentials.access),
		},
		(body) => normalizeSubscriptionUsage(body, now),
		options,
	);
}

async function usageCommand() {
	try {
		let result = await fetchSubscriptionUsage(await ensureFreshCredentials());
		if (result.unauthorized)
			result = await fetchSubscriptionUsage(await ensureFreshCredentials(true));
		if (result.error) fail(result.error);
		else jsonOut({ type: "usage", provider: result.provider });
	} catch {
		// Credential and provider failures may contain token-bearing response bodies.
		fail(
			"Unable to authenticate subscription usage. Sign in to Couch AI again.",
		);
	}
}

const CLAUDE_WINDOWS = [
	["five_hour", 18000, null],
	["seven_day", 604800, null],
	["seven_day_opus", 604800, "Opus week"],
	["seven_day_sonnet", 604800, "Sonnet week"],
];

// Claude Code owns these credentials; read them but never refresh or rewrite them.
export async function readClaudeCredentials(
	now = Date.now(),
	file = CLAUDE_CREDENTIALS_FILE,
) {
	let oauth;
	try {
		oauth = JSON.parse(await readFile(file, "utf8"))?.claudeAiOauth;
	} catch {
		throw new Error(CLAUDE_SIGN_IN_MESSAGE);
	}
	if (typeof oauth?.accessToken !== "string" || !oauth.accessToken)
		throw new Error(CLAUDE_SIGN_IN_MESSAGE);
	if (Number.isFinite(oauth.expiresAt) && oauth.expiresAt <= now)
		throw new Error(CLAUDE_EXPIRED_MESSAGE);
	return {
		access: oauth.accessToken,
		plan:
			typeof oauth.subscriptionType === "string" ? oauth.subscriptionType : "",
	};
}

export function normalizeClaudeUsage(body, plan = "", now = Date.now()) {
	const windows = [];
	for (const [key, durationSeconds, label] of CLAUDE_WINDOWS) {
		const value = body?.[key];
		if (value == null) continue;
		if (
			typeof value.utilization !== "number" ||
			!Number.isFinite(value.utilization) ||
			value.utilization < 0
		)
			throw new Error("Invalid usage percentage");
		const parsedReset =
			typeof value.resets_at === "string" ? Date.parse(value.resets_at) : NaN;
		const window = {
			id: key,
			remainingPercent: Math.max(0, 100 - value.utilization),
			durationSeconds,
			resetsAt: parsedReset > 0 ? parsedReset : null,
		};
		if (label) window.label = label;
		windows.push(window);
	}
	if (!windows.length) throw new Error("No subscription quota available");
	return { id: "claude", name: "Claude", plan, updatedAt: now, windows };
}

export async function fetchClaudeUsage(
	credentials,
	{ now = Date.now(), ...options } = {},
) {
	return fetchUsageJson(
		CLAUDE_USAGE_URL,
		{
			Authorization: `Bearer ${credentials.access}`,
			"anthropic-beta": "oauth-2025-04-20",
		},
		(body) => normalizeClaudeUsage(body, credentials.plan, now),
		options,
	);
}

async function claudeUsageCommand() {
	let credentials;
	try {
		credentials = await readClaudeCredentials();
	} catch (error) {
		fail(error.message);
		return;
	}
	const result = await fetchClaudeUsage(credentials);
	if (result.unauthorized) fail(CLAUDE_EXPIRED_MESSAGE);
	else if (result.error) fail(result.error);
	else jsonOut({ type: "usage", provider: result.provider });
}

async function main() {
	const [command] = process.argv.slice(2);
	try {
		switch (command) {
			case "usage":
				await usageCommand();
				break;
			case "claude-usage":
				await claudeUsageCommand();
				break;
			case "status":
				jsonOut(publicStatusForCredentials(await getStoredCredentials()));
				break;
			case "logout":
				await logoutCommand();
				break;
			case "refresh":
				await refreshCommand();
				break;
			case "login":
				await loginCommand();
				break;
			case "chat":
				await chatCommand();
				break;
			case "payload":
				await payloadCommand();
				break;
			case "state-load":
				await stateLoadCommand();
				break;
			case "state-save":
				await stateSaveCommand();
				break;
			case "models-load":
				await modelsLoadCommand();
				break;
			case "models-refresh":
				await modelsRefreshCommand();
				break;
			case "auth-path":
				jsonOut({ type: "auth_path", path: AUTH_FILE });
				break;
			default:
				fail(`Unknown command: ${command || "<none>"}`);
		}
	} catch (error) {
		fail(error instanceof Error ? error.message : String(error));
	}
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href)
	main();
