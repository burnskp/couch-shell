# Authentication guarantees

`tools/couch-ai-codex.mjs` owns credential access. Helper commands and JSON events
remain the interface used by `services/AiChatService.qml`. Tokens are never stored
in chat history or emitted in status events.

## Credential transactions

All credential reads and updates use an exclusive OS `flock` on `auth.json.lock`
beside the authentication file, with a five-second acquisition timeout. The
helper opens a private descriptor and passes it to `flock` through an argument
array. The descriptor remains open in the helper for the transaction; closing it
or terminating the helper releases the lock. The lock file must not be removed
or replaced while helpers are running.

Existing authentication files acquire a private `_couchShellAuthGeneration`
identifier automatically under the lock. Login and logout replace that generation;
refresh retains it. Login reserves a generation before waiting for the browser,
and checks it again before storing credentials, so logout also invalidates a
pending login. Unrelated authentication entries survive updates. Files use private
`0600` permissions and atomic renames, in a directory created with `0700` permissions.

Refresh snapshots both the generation and refresh token under the lock, releases
the lock for the network exchange, then reacquires it to commit. The commit fails
if either value changed. Thus a refresh completing after logout cannot recreate
credentials, and an old refresh cannot overwrite a newer login or another refresh.
Logout writes a new generation even when no credentials remain. The tombstone and
unrelated entries remain in the file; the provider's credentials are removed.

## Shell logout

Logout immediately blocks new authenticated work, cancels chat, title, model
refresh, subscription usage, login, and status helpers, and advances the service's event generation.
Late output and stderr from older helpers are ignored. Active chat/title requests
receive a cancellation event so they do not remain pending.

Account state is cleared only after the helper confirms removal. A removal failure
is reported and authenticated work remains blocked until another login succeeds;
logout can be retried. Local chat history is preserved. The settings UI allows
logout while a status check or login is running.

## OAuth callback lifecycle

The loopback listener starts before the helper emits `auth_url`. Missing or
incorrect state receives HTTP 400 without ending login. Missing or blank codes
also receive HTTP 400 while leaving the listener available. Only matching state
with a nonempty code succeeds. A provider error with matching state terminates
login; an error with incorrect state does not.

The callback wait expires after five minutes. Success, provider failure, listener
failure, and timeout clean up the listener and its connections. Test dependencies
can inject the exchange and callback timeout/listener without using real tokens
or authenticating against a provider.

Run `bash ./scripts/test` for regressions covering cross-process credential races,
legacy migration, concurrent writes, lock timeout and termination, callback
validation and cleanup, and shell cancellation/removal failure behavior. Run
`bash ./scripts/build` to verify packaged helper and native QML imports.
