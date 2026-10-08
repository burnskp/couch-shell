# Repository Instructions

## Internal Reuse Docs

- Before creating new UI primitives, popup wrappers, or parallel controller state, check the docs in `docs/` first.
- Prefer documented reusable pieces over introducing new wrappers or duplicate state.
- Use `docs/style-guide.md` for the shell-wide visual language, naming rules, popup content guidance, and the AI implementation checklist.
- Use `docs/components.md` for bar widgets, hover popups, and popup helper rows.
- Use `docs/bar.md` for global bar visibility, bar content lifecycle, and bar-only background work.
- Use `docs/shared-ui.md` for pane, menu, form, and general shell UI primitives in `ui/`.
- Use `docs/panes.md` for `PaneManager` and pane control flow.
- Use `docs/notifications.md` for `NotificationManager` and notification UI flow.
- Use `docs/picker.md` for picker usage.
- Use `docs/animation-selector.md` for shared animation usage.

## Doc Selection

- For bar widgets or bar hover popups, start with `docs/components.md`, then check `docs/style-guide.md` for naming and content rules.
- For bar visibility or power-aware bar service lifecycle, start with `docs/bar.md`.
- For panes, menus, forms, or general shell surfaces in `ui/`, start with `docs/shared-ui.md`, then check `docs/style-guide.md` for visual language.
- For shared controller state, use the subsystem doc first: `docs/panes.md`, `docs/notifications.md`, or `docs/picker.md`.
- For shared motion, use `docs/animation-selector.md`.
- Treat `docs/research.md` as background context and repo history, not as the primary implementation contract.

## Linting

- Use `bash ./scripts/lint` from the repository root.
- Do not invoke `qmllint` directly for normal validation.
- `scripts/lint` resolves the repo root, loads the QML environment through `bash ./scripts/with-qml-env`, and passes the correct import paths to `qmllint`.

## Tests

- Use `bash ./scripts/test` from the repository root.
- Do not invoke `qmltestrunner` directly for normal validation.
- `scripts/test` runs `bash ./scripts/lint` first, then runs `qmltestrunner` with the repo's wrapper environment and the offscreen settings required for this project, and finally runs `bash ./scripts/smoke`.

## Smoke Test

- Use `bash ./scripts/smoke` from the repository root when you need to verify that Quickshell can load the real service and widget import graph offscreen.
- `scripts/smoke` runs `qs` against `smoke.qml` with the repo's QML environment and offscreen platform settings.

## Build

- Use `bash ./scripts/build` from the repository root to validate that the Nix package still builds.
- `scripts/build` wraps `nix build .#couch-shell`.

## Wrapper Scripts

- Prefer the script wrappers in `scripts/` over calling underlying tools directly when validating QML.
- For normal validation after code changes, prefer `bash ./scripts/test` and `bash ./scripts/build`.
- If you need the configured QML environment for another command, run it through `bash ./scripts/with-qml-env <command>`.
