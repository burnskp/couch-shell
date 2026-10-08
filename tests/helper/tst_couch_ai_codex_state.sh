#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." && pwd)"
helper="$repo_root/tools/couch-ai-codex.mjs"
tmpdir="$(mktemp -d)"
trap 'rm -rf "$tmpdir"' EXIT
state_file="$tmpdir/nested/ai-state.json"
models_file="$tmpdir/nested/ai-models.json"
auth_file="$tmpdir/nested/auth.json"
save_output="$tmpdir/state-save.out"
bad_output_file="$tmpdir/bad-state.out"

load_empty="$(COUCH_SHELL_AI_STATE_FILE="$state_file" node "$helper" state-load)"
node -e '
const event = JSON.parse(process.argv[1]);
if (event.type !== "state") throw new Error("expected state event");
if (event.state.version !== 1) throw new Error("expected version 1");
if (!Array.isArray(event.state.sessions) || event.state.sessions.length !== 0) throw new Error("expected empty sessions");
' "$load_empty"

printf '%s\n' '{"activeSessionId":"s1","selectedEngineId":"m1","settings":{"showReasoning":true},"sessions":[{"id":"s1","messages":[{"id":"u1","role":"user","content":"hello"}]}]}' \
  | COUCH_SHELL_AI_STATE_FILE="$state_file" node "$helper" state-save >"$save_output"

saved="$(cat "$save_output")"
node -e '
const event = JSON.parse(process.argv[1]);
if (event.type !== "state_saved") throw new Error("expected state_saved event");
if (typeof event.updatedAt !== "number" || event.updatedAt <= 0) throw new Error("expected updatedAt");
' "$saved"

if [[ "$(stat -c %a "$(dirname "$state_file")")" != "700" ]]; then
  echo "state directory mode is not 700" >&2
  exit 1
fi

if [[ "$(stat -c %a "$state_file")" != "600" ]]; then
  echo "state file mode is not 600" >&2
  exit 1
fi

loaded="$(COUCH_SHELL_AI_STATE_FILE="$state_file" node "$helper" state-load)"
node -e '
const event = JSON.parse(process.argv[1]);
if (event.state.activeSessionId !== "s1") throw new Error("activeSessionId did not round trip");
if (event.state.settings.showReasoning !== true) throw new Error("settings did not round trip");
if (event.state.sessions[0].messages[0].content !== "hello") throw new Error("message content did not round trip");
' "$loaded"

COUCH_SHELL_AI_STATE_FILE="$state_file" node -e '
const { spawn } = require("node:child_process");
const helper = process.argv[1];
const child = spawn(process.execPath, [helper, "state-save"], { env: process.env });
let output = "";
const timer = setTimeout(() => {
  child.kill();
  console.error("state-save did not respond after a single line without stdin EOF");
  process.exit(1);
}, 1500);
child.stdout.on("data", chunk => {
  output += chunk;
  const lineEnd = output.indexOf("\n");
  if (lineEnd === -1) return;
  clearTimeout(timer);
  const event = JSON.parse(output.slice(0, lineEnd));
  if (event.type !== "state_saved") throw new Error("expected state_saved event");
  child.kill();
});
child.on("error", error => {
  clearTimeout(timer);
  throw error;
});
child.stdin.write(JSON.stringify({ activeSessionId: "line-write", sessions: [] }) + "\n");
' "$helper"

printf '{not json' >"$state_file"
if COUCH_SHELL_AI_STATE_FILE="$state_file" node "$helper" state-load >"$bad_output_file"; then
  echo "malformed state load unexpectedly succeeded" >&2
  exit 1
fi
bad_output="$(cat "$bad_output_file")"
node -e '
const event = JSON.parse(process.argv[1]);
if (event.type !== "error") throw new Error("expected error for malformed JSON");
' "$bad_output"

load_models="$(COUCH_SHELL_AI_MODELS_FILE="$models_file" node "$helper" models-load)"
node -e '
const event = JSON.parse(process.argv[1]);
if (event.type !== "models") throw new Error("expected models event");
if (event.source !== "none") throw new Error("expected no-cache source");
if (!Array.isArray(event.models) || event.models.length !== 0) throw new Error("expected empty models");
' "$load_models"

node - "$helper" "$models_file" "$auth_file" <<'NODE'
const { mkdirSync, writeFileSync, statSync } = require("node:fs");
const { dirname } = require("node:path");
const { createServer } = require("node:http");
const { spawn } = require("node:child_process");

const helper = process.argv[2];
const modelsFile = process.argv[3];
const authFile = process.argv[4];

mkdirSync(dirname(authFile), { recursive: true, mode: 0o700 });
writeFileSync(authFile, JSON.stringify({
  "openai-codex": {
    type: "oauth",
    access: "fake-access-token",
    refresh: "fake-refresh-token",
    expires: Date.now() + 600000,
    accountId: "acct_test"
  }
}));

const server = createServer((req, res) => {
  const url = new URL(req.url, "http://127.0.0.1");
  if (url.pathname !== "/codex/models") {
    res.writeHead(404);
    res.end("not found");
    return;
  }
  if (url.searchParams.get("client_version") !== "0.159.2") {
    res.writeHead(400);
    res.end("missing client_version");
    return;
  }
  if (req.headers.version !== "0.159.2") {
    res.writeHead(400);
    res.end("missing version header");
    return;
  }
  if (req.headers["openai-beta"] !== "responses=experimental") {
    res.writeHead(400);
    res.end("missing beta header");
    return;
  }
  if (req.headers.authorization !== "Bearer fake-access-token") {
    res.writeHead(401);
    res.end("missing auth");
    return;
  }
  if (req.headers["chatgpt-account-id"] !== "acct_test") {
    res.writeHead(400);
    res.end("missing account id");
    return;
  }
  res.writeHead(200, {
    "content-type": "application/json",
    etag: "models-etag-1"
  });
  res.end(JSON.stringify({
    models: [{
      slug: "gpt-test-remote",
      display_name: "GPT Test Remote",
      description: "Remote model",
      priority: 0,
      visibility: "list",
      supported_reasoning_levels: [{ effort: "low" }, { effort: "high" }],
      input_modalities: ["text", "image"]
    }, {
      slug: "gpt-test-hidden",
      display_name: "GPT Test Hidden",
      priority: 1,
      visibility: "hide",
      supported_reasoning_levels: [{ effort: "medium" }],
      input_modalities: ["text"]
    }]
  }));
});

server.listen(0, "127.0.0.1", () => {
  const { port } = server.address();
  const child = spawn(process.execPath, ["--import", require("node:path").join(dirname(helper), "../tests/helper/model-fetch-fixture.mjs"), helper, "models-refresh"], {
    env: {
      ...process.env,
      COUCH_SHELL_AI_MODELS_FILE: modelsFile,
      COUCH_SHELL_AUTH_FILE: authFile,
      COUCH_SHELL_CODEX_BASE_URL: `http://127.0.0.1:${port}`
    }
  });
  let stdout = "";
  let stderr = "";
  child.stdout.on("data", chunk => stdout += chunk);
  child.stderr.on("data", chunk => stderr += chunk);
  child.on("close", code => {
    server.close();
    if (code !== 0) {
      console.error(stderr || stdout);
      process.exit(code || 1);
    }
    const event = JSON.parse(stdout.trim());
    if (event.type !== "models") throw new Error("expected models event");
    if (event.source !== "remote") throw new Error("expected remote source");
    if (event.models.length !== 1) throw new Error("expected one remote model");
    const model = event.models[0];
    if (model.model !== "gpt-test-remote") throw new Error("remote model did not normalize");
    if (model.label !== "GPT Test Remote") throw new Error("display name did not normalize");
    if (!model.supportsFiles) throw new Error("image modality did not normalize");
    if (model.supportedReasoningEfforts.join(",") !== "low,high") throw new Error("reasoning options did not normalize");
    if ((statSync(modelsFile).mode & 0o777) !== 0o600) throw new Error("models cache is not private");
  });
});
NODE
