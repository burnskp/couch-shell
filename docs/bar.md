# Bar Lifecycle

This document explains the shell-wide bar visibility controller and the power rules for bar-only services.

Use it before adding bar visibility state, recurring work used only by the bar, or a bar-anchored surface.

For widget composition and popup helpers, also use [`components.md`](components.md). For visual language and naming, use [`style-guide.md`](style-guide.md).

## Controller

`services/BarManager.qml` is the only owner of global bar visibility.

Import it through the services module:

```qml
import "../../services" as Services
```

The public interface is:

- `Services.BarManager.visible`
- `Services.BarManager.show()`
- `Services.BarManager.hide()`
- `Services.BarManager.toggle()`

Visibility starts as `true` for every shell process. It is session-local, is not a Home Manager option, and applies to every monitor.

External callers use the `bar` IPC target:

```sh
couch-shell ipc call bar show
couch-shell ipc call bar hide
couch-shell ipc call bar toggle
```

## Window And Content Lifecycle

Each `TopBar` binds both its window visibility and exclusive zone to `BarManager.visible`. Hiding sets the exclusive zone to zero immediately and deactivates the loader that owns `BarContent`.

`BarContent` contains the complete rendered bar tree:

- workspace and window bindings
- system widgets and the clock
- system tray/status controls
- hover popup host and popup loaders

Keeping all of these behind one loader means hidden bars retain no rendered widget or hover-popup tree. Popup-only top-process flags are cleared when the tree is destroyed.

The system menu and notification history remain separate shell windows, but their managers close them when the bar is hidden. Their windows also require `BarManager.visible` as a safety guard.

Idle inhibition is intentionally outside `BarContent` and `TopBar`. `IdleInhibitorWindow` provides the live, non-exclusive Wayland surface required by the idle-inhibit protocol, so a user-selected inhibitor remains active while bars are hidden.

## Power Rules

Recurring work that exists only to populate the bar must follow `BarManager.visible`.

While hidden:

- aggregate CPU and memory polling, popup-only disk polling, temperature polling, and top-process polling stop; running processes are cancelled
- top-process results and enable flags are cleared
- Wi-Fi telemetry stops, its process is cancelled, and device scanning is disabled
- Bluetooth and screen-saver status polling stop and running status processes are cancelled
- PipeWire node/link object tracking used by bar audio displays is detached
- desktop-entry change subscriptions used for bar window icons are disabled

When shown, each status service refreshes immediately before continuing its normal interval. Popup-only process polling stays disabled until a CPU or RAM popup is actually open.

Do not gate event-driven shell safety or non-bar subsystems on bar visibility. In particular, these remain active:

- UPower battery changes and low-battery notifications
- widget filesystem polling and low-disk-space notifications
- notification ingestion and toast handling
- panes and picker actions
- the user-selected idle inhibitor

When adding new work, use this rule: if no shell feature needs the data while `BarContent` is unloaded, stop the work while hidden and refresh immediately on show. If the work protects the session or drives another shell surface, keep it active.

## Reference Files

- `services/BarManager.qml`
- `modules/bar/TopBar.qml`
- `modules/bar/BarContent.qml`
- `modules/bar/IdleInhibitorWindow.qml`
- `services/SystemStatsState.qml`
- `services/NetworkState.qml`
- `services/AudioState.qml`

## Disk Space

`SystemStatsState` shares disk results across monitors. A separate 15-second timer queries each distinct configured path once per cycle, including the independent widget path and ordered popup paths. Each query runs locale-independent GNU `df` with byte units under a 3-second timeout (with a 1-second forced termination grace period). Paths are command arguments, never shell source. The widget path keeps polling while hidden to drive space alerts. Hiding cancels popup-only queries and clears their results; showing refreshes all paths immediately.

Missing or unreadable paths and failed or timed-out queries remain unavailable: the chip shows `Unk`, and popup rows show `Unavailable`. Successful zero available space remains `0 B`. The disk chip sits between RAM and Wi-Fi and uses the standard hover animations and shared popup frame, card, and key/value rows.

Disk warnings apply only to `bar.disk.textPath`: below `warningThresholdGiB` (default 50) the chip turns peach, and below `criticalThresholdGiB` (default 10) it turns red. Thresholds are positive integers in GiB, with critical lower than warning; comparisons use unrounded available bytes. Failed readings show `Unk` with normal tone and send no alerts.

“Low disk space” and “Critical disk space” notifications identify the path and remaining space and stay until dismissed. Each severity alerts once per session-local low-space episode; a direct critical drop sends only the critical alert. A successful reading at or above the warning threshold rearms both alerts. Partial recovery, failures, and dismissal do not rearm them, and recovery does not dismiss existing toasts. Notifications respect the existing do-not-disturb behavior.

### Automatic Btrfs hover

`bar.disk.btrfs.enable = true` replaces the manual hover rows with discovered mounted Btrfs filesystems, even with an empty `popupPaths`. `textPath` and its 15-second free-space query remain independent. Manual popup paths are not queried in this mode.

`SystemStatsState` owns one Btrfs client and timer for all monitors. It requests immediately on show, then every `bar.disk.btrfs.pollInterval` seconds (default 300). Hiding cancels the client and stops the timer. The last report remains available; a failed refresh marks retained data stale. A successful empty report displays “No mounted Btrfs volumes”; a failed connection displays “Collector unavailable”.

Import `couch-shell.nixosModules.default` in the NixOS configuration alongside integrated Home Manager. The module detects enabled shell users with Btrfs enabled and installs one root service and socket. With no enabled consumer, it installs neither. The shortest enabled user's interval controls the shared cache freshness and failure retry interval. There is no system timer: the idle server does no collection. Simultaneous clients share a collection, and disconnecting the last waiting client aborts its commands. Cancellation preserves the cache and does not start failure backoff. Clients reconnecting during cancellation wait for it to finish and a one-second cooldown before sharing a fresh attempt. No attempt starts without waiters. Genuine failures retain the configured retry interval. Both subprocesses and the whole collection have deadlines.

The socket `/run/couch-shell/btrfs.sock` and atomically replaced report `/run/couch-shell/btrfs.json` are accessible only to root and the `couch-shell-btrfs` group. Enabled users join that group automatically and **must log in again** after activation. Group members can see the names and usage of every discovered filesystem and subvolume. Clients connect for one fixed report; they cannot supply paths, commands, or destinations.

The server accepts at most 32 simultaneous connections and rate-limits requests globally to 16 per second with a burst of 32. Each serialized report is limited to 16 MiB, and outstanding responses reserve at most 64 MiB until disconnect. Excess connections or responses are closed immediately; clients can retry once load subsides. Response delivery has an absolute five-second deadline after collection completes. Oversized collections use normal failure handling; oversized saved caches are ignored.

Standalone Home Manager and direct package users must provision the system collector separately. On NixOS, import the same module and configure:

```nix
services.couch-shell-btrfs = {
  enable = true;
  users = [ "alice" ];
  pollInterval = 300;
};
```

Outside NixOS, provision equivalent root-owned systemd units using `nix/btrfs-collector.nix`, one activation socket, a `0750` root/group runtime directory, and `0660` socket permissions. Home Manager alone cannot install this root service.

The report groups mounts by filesystem UUID and joins qgroup usage to actual subvolume IDs. Mount aliases never create extra subvolumes. The top-level subvolume (ID 5) appears only when mounted directly. Snapshot parent UUIDs supply counts by source, including an unassociated count when the source no longer exists. Version-1 subvolume records may include `mounted: true`, derived from the longest directory-boundary match of discovered mount `FSROOT` values, including bind mounts inside subvolumes. Rows show subvolumes with no parent UUID and mounted snapshot-derived subvolumes, including rollback snapshots whose parents have been deleted. Older reports without `mounted` retain the previous filtering. Snapshot usage is not summed. Capacity uses available bytes, as in manual mode.

The service retains its filesystem sandbox, bounds capabilities to `CAP_SYS_ADMIN` and `CAP_DAC_READ_SEARCH`, blocks mount syscalls, and protects kernel tunables, kernel modules, and control groups. Memory is limited to 192 MiB high / 256 MiB maximum with no swap. These restrictions do not narrow group-wide metadata visibility.

The collector only reads metadata. It does not enable quotas, request an accounting rescan, sync the filesystem, or walk directory contents. It uses a private build of the pinned Btrfs tools with upstream's experimental JSON output enabled to preserve subvolume path characters. Referenced/exclusive columns appear only for valid full qgroup accounting. Disabled, scanning, inconsistent, unknown, and simple quota modes retain names and capacity with a compact explanation. Simple quotas do not track shared versus exclusive usage; see the [Btrfs quota documentation](https://btrfs.readthedocs.io/en/latest/btrfs-quota.html).

Diagnostics:

```sh
systemctl status couch-shell-btrfs.socket couch-shell-btrfs.service
journalctl -u couch-shell-btrfs.service
id # verify couch-shell-btrfs membership
couch-shell-btrfs-client
cat /run/couch-shell/btrfs.json
```

An inactive service before the first request is expected. If a failed report is cached, wait for the configured interval before retrying. `bash ./scripts/test` covers parsers, socket behavior, formatting, and offscreen hide/show cancellation. `nix build .#checks.x86_64-linux.btrfs-module .#checks.x86_64-linux.btrfs-vm` checks system integration, permissions, and real Btrfs accounting in a disposable VM.

## AI Subscription Usage

`AiUsageState` owns one shared provider model and the bar-only refresh/countdown timers.
`AiChatService` owns the cancellable helper process and reuses its existing authentication
state. No widget owns polling or credentials. Hiding the bar cancels the helper and
stops timers; showing it refreshes immediately. Requests run every 60 seconds, with a
25-second overall deadline and an eight-second HTTP deadline. Known resets trigger a
refresh; an already-expired server snapshot is retried on the normal interval instead
of causing a tight loop.

`couch-ai-codex usage` reads `GET /wham/usage` under the existing backend base URL,
using the existing credential transaction/refresh implementation. A 401 permits one
forced token refresh and retry. Provider response bodies, credentials, and helper
stderr are never forwarded into usage errors. The endpoint is private; the adapter
isolates its contract from QML. Tests use fake credentials and injected responses.

The normalized provider record has `id`, `name`, `plan`, `updatedAt` (epoch milliseconds),
and `windows`. Each window has `id`, `remainingPercent` (unrounded 0–100),
`durationSeconds` (nullable), and `resetsAt` (nullable epoch milliseconds). QML adds
`status` (`idle`, `loading`, `ready`, or `error`) and `error`. Additional adapters should
publish this model and retain their own authentication behind the service boundary;
`providers` currently contains only `openai-codex`, the selected chip provider.

The chip selects the minimum remaining percentage. Positive fractions round upward.
At zero it counts down to the latest exhausted window's reset, provided every blocking
window has a known reset; otherwise it displays `0%`. Countdown text rounds up to whole
minutes and permits hours over 24 in the chip. The hover's reset row uses days, hours,
and minutes, such as `2d 3h 15m`. A reset never implies a replenished quota: expired,
loading, and failed readings show `Unk`, with previous windows marked stale in the
hover. Account changes and logout discard previous windows. The chip uses
`PaneManager.toggleLeftTab` for its click action and the default hover animation preset.
