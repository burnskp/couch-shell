# Quickshell project structure and testing notes

This file is background context and repo history, not the primary implementation contract.

For current reuse and implementation guidance, start with:

- `docs/style-guide.md`
- `docs/components.md`
- `docs/shared-ui.md`
- the relevant subsystem guide in `docs/`

## Sources checked

### Official Quickshell docs

- Installation and setup: <https://quickshell.org/docs/master/guide/install-setup>
- Distribution and configuration paths: <https://quickshell.org/docs/master/guide/distribution>
- Quickshell 0.2 changelog for `.qmlls.ini` and root-relative imports: <https://raw.githubusercontent.com/quickshell-mirror/quickshell/master/changelog/v0.2.0.md>
- Official examples: <https://github.com/quickshell-mirror/quickshell-examples>

### Community shells inspected

- Caelestia Shell: <https://github.com/caelestia-dots/shell>
- Noctalia Shell: <https://github.com/noctalia-dev/noctalia-shell>
- DankMaterialShell: <https://github.com/AvengeMedia/DankMaterialShell>
- Illogical Impulse quickshell config: <https://github.com/end-4/dots-hyprland>

### Qt testing docs

- Qt Quick Test overview: <https://doc.qt.io/qt-6/qtquicktest-index.html>
- QML lint warnings and errors: <https://doc.qt.io/qt-6/qmllint-warnings-and-errors.html>

## Practical conclusions

### 1. Keep `shell.qml` as the entrypoint

That is consistent across the official examples and most public shells.

### 2. Package installs should behave like named Quickshell configs

The official Quickshell distribution docs recommend:

- dotfiles: `$XDG_CONFIG_HOME/quickshell/<name>`
- packaged installs: `$XDG_CONFIG_DIRS/quickshell/<name>`

This repo installs the config to `.../etc/xdg/quickshell/couch-shell` inside the Nix package and wraps `qs -c couch-shell`.

### 3. The smallest sustainable directory split is:

- `components/` reusable view pieces
- `modules/` shell features or windows/panels
- `lib/` pure JS helpers
- `tests/qml/` Qt Quick Test files
- `nix/` package/module helpers

That matches the growth pattern seen in public shells without over-abstracting too early.

### 4. Root-relative imports are useful, but optional

Quickshell 0.2 introduced `import qs.path.to.module` and generated `.qmlls.ini` support for QMLLS.

That is attractive for large shells, but it relies on a generated system-dependent VFS config. For a small repo that needs deterministic sandbox linting, explicit path imports are easier to validate headlessly.

### 5. Headless automated testing should focus on pure logic

Qt Quick Test can run QML tests offscreen. The Qt docs explicitly note that tests normally open a window, and recommend `-platform offscreen` to avoid that.

That means the safest CI/sandbox split is:

#### Good automated targets

- pure JS helpers
- state reducers / formatting helpers
- non-Wayland component behavior that can run offscreen
- strict `qmllint`

#### Manual-only targets

- `PanelWindow` anchoring and exclusive zone behavior
- compositor-specific Hyprland interactions
- multi-monitor behavior on a live Wayland session
- anything that depends on focused outputs, layer shell, or real compositor IPC state

### 6. Strict qmllint is a good baseline gate

Qt's `qmllint` supports `-W 0`, which fails after zero warnings. Some diagnostics default to `info`, so promoting them to `warning` helps make the check truly strict.

This repo promotes at least:

- `unused-imports`
- `multiline-strings`

## Recommended workflow for this repo

- `direnv allow` to enter the nix-direnv shell
- `./scripts/lint` while iterating
- `./scripts/test` before handoff
- `nix run .#couch-shell` for live manual validation in Hyprland
