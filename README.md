# couch-shell

A small [Quickshell](https://quickshell.org/) shell for Hyprland, packaged for Nix and exportable as a Home Manager module.

## What is in this repo

- `shell.qml` entrypoint, matching the standard Quickshell pattern from the official examples
- `theme/` for shared color, spacing, and typography tokens plus semantic widget style presets
- `animations/` for shared motion presets, shader wrappers, and reusable transition assets
- `assets/` for the shipped wallpaper and related visual assets
- `services/` for Quickshell singletons and pure JS service logic
- `components/` for reusable UI primitives such as `ModuleChip` and `WidgetChip`
- `modules/bar/widgets/` for bar-specific widgets
- `modules/bar/BarHoverPopupHost.qml` for the bar-local hover popup controller that keeps `TopBar.qml` focused on composition
- `modules/bar/popups/` for lightweight popup surfaces
- `lib/` for pure JS helpers that are easy to unit test
- `tests/qml/` for headless Qt Quick tests
- `nix/` for packaging plus the Home Manager module
- `flake.nix` and `nix/env.nix` for the development shell, nix-direnv integration, formatting, and git hooks

## Research summary

I did a quick survey of the official docs and a few larger public shells:

- Official Quickshell docs recommend named configs under `$XDG_CONFIG_HOME/quickshell/<name>` for dotfiles and `$XDG_CONFIG_DIRS/quickshell/<name>` for packaged installs.
- The official examples keep `shell.qml` as the entrypoint and place related QML files next to it.
- Larger community shells such as Caelestia, Noctalia, DankMaterialShell, and Illogical Impulse commonly grow into `components/`, `modules/`, `services/`, and `assets/` directories.
- Quickshell 0.2 added root-relative imports and `.qmlls.ini` support for QMLLS, but those generated VFS files are system-dependent. For a sandbox-friendly project with strict headless linting, this repo sticks to explicit path imports.
- For automated testing, the practical baseline is Qt Quick Test via `qmltestrunner`, run with `-platform offscreen`. Wayland-specific behavior like `PanelWindow` placement and Hyprland integration should still be treated as manual validation.

A longer note with links is in [`docs/research.md`](docs/research.md).

## Internal Docs

These docs are internal reuse guides for contributors and AI working in this repo.

- [`docs/style-guide.md`](docs/style-guide.md) for the shell-wide visual language, naming rules, popup content guidance, and the AI implementation checklist
- [`docs/shared-ui.md`](docs/shared-ui.md) for pane, menu, form, and shared shell primitives in `ui/`
- [`docs/components.md`](docs/components.md) for bar chips, hover popup shells, and popup helper rows in `components/`
- [`docs/bar.md`](docs/bar.md) for global bar visibility, content unloading, and power-aware bar services
- [`docs/panes.md`](docs/panes.md) for `PaneManager` and pane control flow
- [`docs/notifications.md`](docs/notifications.md) for `NotificationManager` and notification UI flow
- [`docs/picker.md`](docs/picker.md) for the picker service and overlay
- [`docs/animation-selector.md`](docs/animation-selector.md) for shared animation usage

Use the docs in this order:

- visual language, naming, popup information selection: [`docs/style-guide.md`](docs/style-guide.md)
- bar widgets and bar hover popups: [`docs/components.md`](docs/components.md)
- global bar visibility and bar-only service lifecycle: [`docs/bar.md`](docs/bar.md)
- panes, menus, forms, and general shell controls: [`docs/shared-ui.md`](docs/shared-ui.md)
- shared controller state and overlays: the relevant subsystem guide in `docs/`
- background repo research and external references: [`docs/research.md`](docs/research.md)

## Current shell surface

The migrated shell currently includes:

- fixed `1..5` workspace indicators
- active-workspace window chips
- CPU usage, RAM, and CPU temperature modules
- battery and audio modules
- system tray icons and a system glyph in the status cluster
- a status-cluster system popup with an idle inhibitor toggle

The shipped media defaults are:

- desktop wallpaper reference: `assets/coding-deck.png`

Animation presets are shared through the top-level `animations/` module. The current presets are `HoverRevealAnimation`, `SmokeAnimation`, and `SlideIn`. Surfaces can either instantiate a preset directly or use `Animations.AnimationSelector` with `preset`, or with separate `openPreset` / `closePreset` values when the enter and exit effects should differ. Window- and popup-level animated surfaces should keep their outer `visible` binding tied to the animation wrapper's lifecycle state (for example `shouldShow`) so close transitions can finish before the surface is torn down.

The Home Manager runtime configuration surface is intentionally small:

- `fonts.proseFamily`
- `fonts.monoFamily`
- `fonts.codeFamily`
- `fonts.notificationToastFamily`
- `fonts.size`
- `fonts.aiPaneSize`
- `fonts.tasksPaneSize`
- `fonts.notificationToastSize`
- `fonts.packages`
- `theme.flavor`
- `bar.disk.textPath`
- `bar.disk.warningThresholdGiB` (default `50`)
- `bar.disk.criticalThresholdGiB` (default `10`)
- `bar.disk.popupPaths`
- `bar.disk.btrfs.enable` (default `false`)
- `bar.disk.btrfs.pollInterval` (default `300` seconds)
- `bar.height`
- `bar.temperature.enable`
- `bar.temperature.textPath`
- `bar.temperature.popupPaths`
- `bar.temperature.fanPaths`

Bar ordering, spacing, and most theme defaults are kept in code rather than exposed as user options.

### Theme

The shell palette is centrally managed in `theme/Theme.qml` and can be switched between Catppuccin flavors through Home Manager:

```nix
programs.couch-shell.theme.flavor = "mocha";
```

Supported values are `latte`, `frappe`, `macchiato`, and `mocha`. The default is `latte`.

### Bar

The top bar height is configurable through Home Manager:

```nix
programs.couch-shell.bar.height = 24;
```

The default is `20` pixels, but the rendered bar grows when needed to keep larger configured fonts from clipping glyph icons. Bar modules use the same height so widget chips stay aligned with the effective bar size.

### Fonts

Font families are configured through the Home Manager module and substituted into the packaged QML config at build time.

- `fonts.proseFamily` is used by task notes, AI chat inputs, and markdown prose.
- `fonts.monoFamily` is the shell's monospace/default font family.
- `fonts.codeFamily` is used by markdown fenced code blocks.
- `fonts.notificationToastFamily` is used by notification toasts.
- `fonts.size` is the base shell font size in pixels.
- `fonts.aiPaneSize` is the AI pane font size in pixels.
- `fonts.tasksPaneSize` is the tasks pane font size in pixels.
- `fonts.notificationToastSize` is the notification toast font size in pixels.
- `fonts.packages` adds font packages to the wrapper's fontconfig file so the selected families are visible when launching the packaged shell.

Defaults:

```nix
programs.couch-shell.fonts = {
  proseFamily = "Inter";
  monoFamily = "CommitMono Nerd Font";
  codeFamily = "CommitMono Nerd Font";
  notificationToastFamily = "CommitMono Nerd Font";
  size = 12;
  aiPaneSize = 12;
  tasksPaneSize = 12;
  notificationToastSize = 12;
  packages = [ ];
};
```

Example:

```nix
programs.couch-shell.fonts = {
  proseFamily = "Inter";
  monoFamily = "CommitMono Nerd Font";
  codeFamily = "JetBrainsMono Nerd Font";
  notificationToastFamily = "Inter";
  size = 12;
  aiPaneSize = 15;
  tasksPaneSize = 13;
  notificationToastSize = 16;
  packages = [
    pkgs.inter
    pkgs.nerd-fonts.jetbrains-mono
  ];
};
```

Install or list any font packages needed by the configured family names. If a family is not available through fontconfig, Qt will fall back according to the system font configuration.

### Disk space

The disk widget shows available space for `textPath`. Its hover popup lists free and total space for the containing filesystem of each named path, preserving names and ordering. These defaults also apply when running unpackaged QML:

```nix
programs.couch-shell.bar.disk = {
  warningThresholdGiB = 50;
  criticalThresholdGiB = 10;
  textPath = "/persist";
  popupPaths = [
    { name = "Persist"; path = "/persist"; }
    { name = "Ephemeral"; path = "/"; }
  ];
};
```

`textPath` is independent of `popupPaths`. Custom lists replace the defaults; `popupPaths = [ ];` disables the hover popup. Package users can pass the same `bar.disk` settings to `lib.mkCouchShellPackage`. Names and paths may contain spaces or quotes. Missing or unreadable paths show `Unk` in the widget and `Unavailable` in the popup, without falling back to another filesystem.

Disk data is shared across monitors and refreshed every 15 seconds, with one bounded query per distinct path. The widget path keeps polling while the bar is hidden; popup-only queries stop and are cancelled, then refresh immediately when shown. See [`docs/bar.md`](docs/bar.md).

Disk warnings apply only to `bar.disk.textPath`: below `warningThresholdGiB` (default 50) the chip turns peach, and below `criticalThresholdGiB` (default 10) it turns red. Thresholds are positive integers in GiB, with critical lower than warning; comparisons use unrounded available bytes. Failed readings show `Unk` with normal tone and send no alerts.

“Low disk space” and “Critical disk space” notifications identify the path and remaining space and stay until dismissed. Each severity alerts once per session-local low-space episode; a direct critical drop sends only the critical alert. A successful reading at or above the warning threshold rearms both alerts. Partial recovery, failures, and dismissal do not rearm them, and recovery does not dismiss existing toasts. Notifications respect the existing do-not-disturb behavior.

For automatic Btrfs discovery, import the NixOS module at the system level:

```nix
imports = [ couch-shell.nixosModules.default ];
```

Then enable the hover in the integrated Home Manager user's configuration:

```nix
programs.couch-shell.bar.disk.btrfs = {
  enable = true;
  pollInterval = 300; # seconds; five minutes by default
};
```

The NixOS module automatically installs one shared, socket-activated root collector for enabled users. Log in again after activation to pick up the `couch-shell-btrfs` group. This hover replaces `popupPaths`, including an empty list, and shows mounted volumes, subvolume referenced/exclusive usage when accounting is valid, and snapshot counts. The chip still uses `textPath` at its existing 15-second interval. Hiding the bar stops Btrfs requests; the system service has no periodic timer.

Standalone Home Manager and direct package consumers must provision the root collector separately; enabling a user option cannot install a system service. See [`docs/bar.md`](docs/bar.md#automatic-btrfs-hover) for system provisioning, accounting states, access permissions, and diagnostics. Leaving Btrfs disabled preserves the manual hover.

### Temperature sensors

Temperature sensor paths must be full sysfs paths, such as `/sys/class/hwmon/hwmon7/temp1_input` for temperatures and `/sys/class/hwmon/hwmon7/fan1_input` for fan speed sensors. When set, `popupPaths` and `fanPaths` replace the default sensor sets; use `{ }` to show no popup temperatures or fans.

Example:

```nix
programs.couch-shell.bar.temperature = {
  textPath = "/sys/class/hwmon/hwmon7/temp1_input";
  popupPaths = {
    gpu = "/sys/class/hwmon/hwmon7/temp2_input";
    ram = "/sys/class/hwmon/hwmon6/temp1_input";
    wifi = "/sys/class/hwmon/hwmon11/temp1_input";
    nvme0 = "/sys/class/hwmon/hwmon0/temp1_input";
    nvme1 = "/sys/class/hwmon/hwmon1/temp1_input";
  };
  fanPaths = {
    fan1 = "/sys/class/hwmon/hwmon7/fan1_input";
    fan2 = "/sys/class/hwmon/hwmon7/fan2_input";
  };
};
```

## Keymap

The bar and side panes expose Quickshell IPC commands that you can map from Hyprland. Bar visibility is global across monitors and resets to visible whenever the shell starts:

- `couch-shell ipc call bar show` shows every bar
- `couch-shell ipc call bar hide` hides every bar
- `couch-shell ipc call bar toggle` toggles every bar

The current pane actions are:

- `couch-shell ipc call panes toggleCouchAi` toggles the left pane on `Couch AI`
- `couch-shell ipc call panes toggleTasks` toggles the right pane on `Tasks`
- `couch-shell ipc call panes openNewTask` opens a centered new-task window

Add matching Hyprland binds so those shortcuts execute the IPC commands.

### Home Manager example

For NixOS with Home Manager, this can look like:

```nix
{
  wayland.windowManager.hyprland = {
    enable = true;

    settings = {
      bind = [
        "$mod, B, exec, couch-shell ipc call bar toggle"
        "$mod SHIFT, A, exec, couch-shell ipc call panes toggleCouchAi"
        "$mod SHIFT, T, exec, couch-shell ipc call panes toggleTasks"
        "$mod SHIFT, Return, exec, couch-shell ipc call panes openNewTask"
      ];
    };
  };
}
```

If you do not use `$mod`, replace it with the modifier string you use in Hyprland, such as `SUPER`.

## AI chat local state

Couch AI stores OpenAI/Codex OAuth credentials, local chat history, and the cached model catalog separately under the user data directory:

- credentials: `~/.local/share/couch-shell/auth.json`
- chat state: `~/.local/share/couch-shell/ai-state.json`
- model cache: `~/.local/share/couch-shell/ai-models.json`

These files are written through the `couch-ai-codex` helper with a private data directory (`0700`), private JSON files (`0600`), and atomic temp-file renames. `COUCH_SHELL_AUTH_FILE`, `COUCH_SHELL_AI_STATE_FILE`, and `COUCH_SHELL_AI_MODELS_FILE` can override the default paths.

Every model refresh first discovers the latest stable Codex version from GitHub, then requests the model catalog using that version. Refresh requires network access to both GitHub and the model service; if either request fails, the existing model list and cache are preserved and an error is shown. Loading cached models remains offline. The cache records the successful client version so that a version change forces a fresh catalog request.

`COUCH_SHELL_CODEX_CLIENT_VERSION` is no longer used. A `client_version` query parameter in `COUCH_SHELL_CODEX_MODELS_URL` is replaced by the discovered version. Refresh does not fall back to a bundled, installed, or previously cached client version.

Chat state includes sessions, messages, drafts, selected model/settings, active session, and persisted reasoning text. It does not include OAuth tokens; those remain only in `auth.json`. Logging out removes credentials but intentionally keeps local chat history. Chat history is currently retained until the local state file is removed or a future clear-history UI is added.

See [authentication guarantees](docs/authentication.md) for credential concurrency, logout, and OAuth callback handling.

## Development

### nix-direnv

```bash
direnv allow
```

That loads the flake-backed development shell through nix-direnv automatically.

### Available commands

```bash
./scripts/lint
./scripts/test
nix flake check
nix run .#couch-shell
```

## Linting

`./scripts/lint` runs `qmllint` in strict mode:

- `-W 0` makes warnings fail immediately
- `unused-imports` and `multiline-strings` are promoted from info to warning
- `-E` reads imports directly from the current flake's `QML_IMPORT_PATH`, without a separate login shell
- `scripts/with-qml-env` refreshes `QML_IMPORT_PATH` and `QT_PLUGIN_PATH` on each run so stale shell variables do not break module resolution

## Testing

Run `bash ./scripts/test` locally to run the same lint, helper tests, Qt Quick tests, markdown guard tests, and smoke checks as CI. The script enters the pinned Nix environment once and uses temporary runtime and cache directories with desktop display and Qt theme settings cleared. Temporary directories are removed when the suite exits.

The other CI jobs run `bash ./scripts/build` and `nix build --no-link --print-build-logs .#checks.x86_64-linux.formatting`.

Automated tests are intentionally limited to headless-safe checks:

- `qmllint` for static analysis
- `qmltestrunner` with `-platform offscreen` for pure QML/JS logic tests

Manual tests are still required for:

- actual `PanelWindow` placement on Wayland
- Hyprland monitor/workspace behavior
- compositor integration details

## Running the shell

From the repo:

```bash
nix run .#couch-shell
```

After installation:

```bash
couch-shell
```

## Home Manager

### Standalone Home Manager flake

Add the flake input and import the module:

```nix
{
  inputs.couch-shell.url = "github:burnskp/couch-shell";

  outputs = { self, nixpkgs, home-manager, couch-shell, ... }: {
    homeConfigurations.me = home-manager.lib.homeManagerConfiguration {
      pkgs = import nixpkgs { system = "x86_64-linux"; };
      modules = [
        couch-shell.homeManagerModules.default
        {
          programs.couch-shell = {
            enable = true;
            systemd.enable = true;
            fonts = {
              proseFamily = "Inter";
              monoFamily = "CommitMono Nerd Font";
              codeFamily = "JetBrainsMono Nerd Font";
              notificationToastFamily = "Inter";
            };
            bar.temperature = {
              textPath = "/sys/class/hwmon/hwmon10/temp1_input";
              fanPaths = {
                fan1 = "/sys/class/hwmon/hwmon10/fan1_input";
                fan2 = "/sys/class/hwmon/hwmon10/fan2_input";
              };
            };
          };
        }
      ];
    };
  };
}
```

### Home Manager inside a NixOS flake

If you use Home Manager through `nixosConfigurations`, add the same flake input and include the module in one of your Home Manager user modules:

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs";

    couch-shell.url = "github:burnskp/couch-shell";
    couch-shell.inputs.nixpkgs.follows = "nixpkgs";
  };

  outputs = inputs@{ nixpkgs, home-manager, couch-shell, ... }: {
    nixosConfigurations.my-host = nixpkgs.lib.nixosSystem {
      system = "x86_64-linux";
      modules = [
        home-manager.nixosModules.home-manager
        {
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;

          home-manager.users.me = {
            imports = [ couch-shell.homeManagerModules.default ];

            programs.couch-shell = {
              enable = true;
              systemd.enable = true;
              fonts = {
                proseFamily = "Inter";
                monoFamily = "CommitMono Nerd Font";
                codeFamily = "JetBrainsMono Nerd Font";
                notificationToastFamily = "Inter";
              };
              bar.temperature = {
                textPath = "/sys/class/hwmon/hwmon10/temp1_input";
                fanPaths = {
                  fan1 = "/sys/class/hwmon/hwmon10/fan1_input";
                  fan2 = "/sys/class/hwmon/hwmon10/fan2_input";
                };
              };
            };
          };
        }
      ];
    };
  };
}
```

## Validation notes

The documented workflows should be validated with:

- `./scripts/lint`
- `./scripts/test`
- `nix flake check`
- `nix run .#couch-shell -- --help`
- `$(nix build .#couch-shell --no-link --print-out-paths)/bin/couch-shell --help`

Manual Wayland validation is still required for actual panel placement and compositor integration.

## Pre-commit hooks

Hooks are defined in `flake.nix` through `git-hooks.nix` and installed by the development shell.

- pre-commit: format + Nix hygiene + shell lint + QML lint
- pre-push: full `./scripts/test`
