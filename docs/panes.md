# Panes

This document explains the internal pane control flow built around `services/PaneManager.qml`.

Use this guide before adding new pane toggles, pane tabs, or alternate pane state.

## Purpose

`PaneManager` is the shared controller for left and right pane state.

Use it to:

- decide which pane is open
- decide which screen owns each pane
- select the active tab for each side
- expose pane actions through Quickshell IPC commands

Do not create a second pane state singleton or local pane open state when the feature belongs to the existing left or right pane.

## Import

```qml
import "../services" as Services
```

## Constants

Left pane tabs:

- `Services.PaneManager.leftTabCouchAi`

Right pane tabs:

- `Services.PaneManager.rightTabTasks`

Use these constants instead of ad hoc tab strings.

## Shared State

Left side:

- `leftOpen`
- `leftScreen`
- `leftTab`

Right side:

- `rightOpen`
- `rightScreen`
- `rightTab`

The main pane windows bind their visibility from this shared state rather than storing local open flags.

## Primary Operations

Visibility helpers:

- `isLeftVisibleOnScreen(screen)`
- `isRightVisibleOnScreen(screen)`

Open and close helpers:

- `openLeft(screen, tab)`
- `openRight(screen, tab)`
- `closeLeft()`
- `closeRight()`

Toggle helpers:

- `toggleLeft(screen)`
- `toggleRight(screen)`
- `toggleLeftTab(screen, tab)`
- `toggleRightTab(screen, tab)`

Screen helpers:

- `firstScreen()`
- `focusedScreen()`

Normalization helpers:

- `normalizeLeftTab(tab)`
- `normalizeRightTab(tab)`

Most callers should use `toggleLeftTab(...)` or `toggleRightTab(...)` rather than open and close functions directly.

## Typical Patterns

### Open a pane on the current focused screen

```qml
Services.PaneManager.toggleLeftTab(
    Services.PaneManager.focusedScreen(),
    Services.PaneManager.leftTabCouchAi
)
```

### Drive pane window visibility

```qml
readonly property bool isTargetScreen: Services.PaneManager.leftScreen === root.screen

Component.onCompleted: {
    paneAnimation.open = Services.PaneManager.leftOpen && isTargetScreen
}
```

### Drive tab buttons

```qml
Ui.ShellTabButton {
    checked: Services.PaneManager.rightTab === Services.PaneManager.rightTabTasks
    onClicked: Services.PaneManager.toggleRightTab(root.screen, Services.PaneManager.rightTabTasks)
}
```

## How Tab Toggling Works

`toggleLeftTab(screen, tab)` and `toggleRightTab(screen, tab)` do 2 things:

- if the target pane is already visible on that screen and already on that tab, they close it
- otherwise, they open the pane on that screen and switch to the requested tab

That means tab buttons and menu actions can usually share the same toggle call.

## Screen Ownership

Panes are screen-specific.

- `leftScreen` and `rightScreen` track which screen owns each visible pane
- `isLeftVisibleOnScreen(screen)` and `isRightVisibleOnScreen(screen)` are the preferred checks for cross-screen UI such as the bar system menu

Do not infer pane visibility with only `leftOpen` or `rightOpen` when the caller is screen-aware.

## IPC Commands

`PaneManager` exposes Quickshell IPC commands for external keybinds.

Current commands on the `panes` target:

- `toggleCouchAi`
- `toggleTasks`
- `openNewTask`

Example calls:

```sh
couch-shell ipc call panes toggleCouchAi
couch-shell ipc call panes toggleTasks
couch-shell ipc call panes openNewTask
```

If you add another pane-level external action through `PaneManager`, keep the IPC command in the singleton so pane behavior stays centralized.

## When To Extend `PaneManager`

Extend `PaneManager` when:

- adding a new left or right pane target
- adding a new system-menu action that opens a pane
- adding another IPC command for the existing pane system
- changing screen targeting rules for pane behavior

Do not extend it when:

- the feature is a picker or popup rather than a pane
- the feature is a self-contained local panel with no shared shell state

## Reference Usages

- `modules/panes/LeftPane.qml`
- `modules/panes/RightPane.qml`
- `modules/bar/popups/SystemMenu.qml`
- `README.md` keymap section
