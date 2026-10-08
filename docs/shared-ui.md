# Shared UI Guide

This document explains how to use the shared QML UI primitives in `ui/`.

Use this guide when building or refactoring panes, menus, popups, and form-like shell surfaces.

For bar widgets and hover popups, check [`components.md`](components.md) first. That layer is the preferred reuse path for chips, widget popups, and popup helper rows.

Use [`style-guide.md`](style-guide.md) alongside this file for shell-wide visual language, naming, and content selection rules.

## Purpose

The shared UI layer exists to:

- keep the shell on one visual language
- remove repeated inline `Rectangle` + `Text` + `MouseArea` styling
- centralize the segmented pane/menu treatment chosen for the shell
- make future UI changes smaller and safer

The current baseline style lives in `Ui.ShellStyle.segmented`.

## Imports

Import the shared module with:

```qml
import "../../ui" as Ui
```

Adjust the relative path for the file you are editing.

## `ui/` vs `components/`

Use `ui/` when:

- building panes
- building menus and settings surfaces
- building shared shell controls such as buttons, sections, text, dividers, and inputs

Use `components/` when:

- building bar widgets
- building hover popups attached to bar widgets
- reusing chip and popup helper building blocks

Preferred split:

- `ui/` for pane and menu primitives
- `components/` for bar chip and hover popup primitives

If a feature starts in the bar, start with [`components.md`](components.md). If it starts as a pane, menu, or form-like surface, start here.

## Core Style Objects

### `Ui.ShellStyle`

Use this singleton as the style source for shared controls.

Available styles today:

- `Ui.ShellStyle.segmented`
- `Ui.ShellStyle.segmentedTabs`

Typical usage:

```qml
readonly property var shellStyle: Ui.ShellStyle.segmented
readonly property var tabStyle: Ui.ShellStyle.segmentedTabs
```

Use `segmented` for panes, cards, buttons, and surfaces.

Use `segmentedTabs` for tab rows where the active tab should read more strongly than a normal button.

## Shared Primitives

### `Ui.ShellSurface`

Base square surface for reusable shell containers.

Use it for:

- cards
- framed utility areas
- input shells
- compact grouped surfaces

Important properties:

- `style`
- `tone`: `normal`, `subtle`, `input`, `accent`
- `padding`
- `emphasize`

Example:

```qml
Ui.ShellSurface {
    style: shellStyle
    tone: "input"
    padding: Theme.Theme.modulePadding
}
```

### `Ui.ShellPaneFrame`

Use for the outer frame of left/right panes.

This replaces hand-built pane `Rectangle` wrappers.

Example:

```qml
Ui.ShellPaneFrame {
    width: root.paneWidth
    height: root.paneHeight
    style: shellStyle
}
```

### `Ui.ShellSection`

Use for standard inner cards with an optional header row.

Good for:

- grouped settings
- placeholder cards
- popup sections
- task sections

Important properties:

- `title`
- `summary`
- `style`

Example:

```qml
Ui.ShellSection {
    style: shellStyle
    title: "Tasks"

    Ui.ShellText {
        Layout.fillWidth: true
        role: "muted"
        style: shellStyle
        wrapMode: Text.Wrap
        text: "Placeholder tasks content goes here."
    }
}
```

### `Ui.ShellPopupFrame`

Use for popup chrome when building new shared popup surfaces.

For existing hover popups, continue using `components/HoverPopupFrame.qml` unless you are intentionally migrating that code path.

If the popup is attached to a bar widget hover state, that is the `components/` path, not the `ui/` path.

### `Ui.ShellOuterShadow`

Use for subtle outer elevation around floating shell boxes such as panes, popup frames, and toasts.

Apply it to the outermost frame only. Do not add it to inner cards, rows, buttons, or repeated list content.

When a surface is inside a tightly sized `PanelWindow`, `PopupWindow`, or animation wrapper, reserve `Theme.Theme.outerShadowEffectivePadding` around the frame so the shadow is not clipped. For edge-flush surfaces, reserve padding only away from the screen edge and offset the frame so its visible edge remains flush.

### `Ui.ShellDivider`

Use for separators between tab rows and pane content.

### `Ui.ShellText`

Use this instead of raw `Text` when the content should follow shell typography roles.

Roles currently used:

- `title`
- `heading`
- `body`
- `label`
- `value`
- `muted`
- `accent`
- `danger`

Example:

```qml
Ui.ShellText {
    role: "heading"
    style: shellStyle
    text: "Couch AI"
}
```

## Interactive Controls

### `Ui.ShellButton`

Base rectangular action button.

Variants:

- `default`
- `accent`
- `ghost`
- `danger`

Use `contentLeftPadding` only when a fixed-width button group needs icon/text alignment across rows. Leave it at the default `-1` for centered button content.

Example:

```qml
Ui.ShellButton {
    style: shellStyle
    variant: "accent"
    text: "Apply"
    onClicked: doSomething()
}
```

### `Ui.ShellTabButton`

Use for segmented tab rows.

Pair it with `Ui.ShellStyle.segmentedTabs`.

Example:

```qml
Ui.ShellTabButton {
    text: "Tasks"
    style: tabStyle
    checked: currentTab === "tasks"
    onClicked: currentTab = "tasks"
}
```

### `Ui.ShellToggleButton`

Use for compact on/off actions where the whole button flips state.

### `Ui.ShellSwitch`

Use for settings-like boolean rows where the label and control live together.

## Inputs

### `Ui.ShellTextField`

Use for single-line input.

### `Ui.ShellTextArea`

Use for multiline editable areas.

This is the shared shell text-area treatment. If a surface needs custom surrounding layout, keep the surrounding layout custom and use shared styling where it still fits.

The calculator in `LeftPane.qml` is the reference example for this rule: the layout is custom, but the surrounding shell surfaces and typography use the shared system.

## Data Display

### `Ui.ShellKeyValueRow`

Use for label/value rows inside cards and popups.

Use this for panes, menus, settings surfaces, and general shell popup cards.

If the row is inside a bar hover popup in `modules/bar/popups/`, use `Components.HoverPopupKeyValueRow` from [`components.md`](components.md) instead.

### `Ui.ShellMetricBar`

Use for usage/progress/health bars.

### `Ui.ShellEmptyState`

Use when a whole section has no content and should still render intentionally.

## When To Use Shared UI vs Custom Layout

Use shared primitives when:

- the surface is a pane card, popup card, action button, tab, divider, input, or standard text block
- you are replacing repeated inline shell styling
- the interaction is ordinary and the shared control already fits

Keep custom layout when:

- the behavior is domain-specific enough that a generic control would become awkward
- the layout is tightly coupled to data presentation, like the calculator editor + result gutter
- forcing the custom surface into a shared abstraction would make it harder to read or maintain

Preferred pattern:

- shared outer shell
- custom inner layout only where truly needed

## Current Real Examples

Use these files as references:

- `modules/panes/LeftPane.qml`
- `modules/panes/RightPane.qml`
- `modules/bar/popups/SystemMenu.qml`

These show how to:

- bind `shellStyle` and `tabStyle`
- build panes with `Ui.ShellPaneFrame`
- use `Ui.ShellSection` for grouped content
- use shared tab/button/text primitives without over-abstracting specialized content

## Rules Of Thumb

- prefer `Ui.ShellText` over raw `Text` for normal shell copy
- prefer `Ui.ShellSection` over one-off card `Rectangle`s
- prefer `Ui.ShellButton` and `Ui.ShellTabButton` over inline clickables
- prefer `Ui.ShellKeyValueRow` for pane/menu/settings cards, not bar hover popups
- use `Ui.ShellStyle.segmented` as the default shared style unless a new style is intentionally introduced
- do not build a new generic primitive unless at least 2 real surfaces want the same structure
- if a layout is unique, keep the layout local and only share the styling pieces

## Adding New Shared Controls

When introducing a new shared control:

1. confirm the pattern already appears in at least two places or is clearly foundational
1. keep the API small and shell-specific
1. source visual decisions from `Theme.qml` and `Ui.ShellStyle`
1. register the component in `ui/qmldir`
1. migrate one real call site to prove the abstraction is worth keeping

Avoid building broad generic controls that do not match current shell usage.

## Markdown text

Use `Ui.ShellMarkdownText` for untrusted Markdown. It keeps native Qt Markdown
formatting and selection, and separates fenced code into plain-text blocks with
literal copying. User-activated links are restricted to HTTP and HTTPS.

Each prose `TextEdit` stays empty until `MarkdownResourceGuard.install(textDocument)`
succeeds. The `CouchShell.Markdown` C++ module installs a guarded `QTextDocument`
using Qt's public [setTextDocument API](https://doc.qt.io/qt-6/qquicktextdocument.html#setTextDocument).
The document returns a valid transparent one-pixel image for every image resource
and a valid empty result for other resource types, without invoking Qt's default
loader or resource-provider fallback. This covers all URL schemes, including
local files, relative paths, data URLs, and Qt resources.

Image-to-link rewriting remains a presentation feature. It is not a sanitizer or
the security boundary: Qt and the JavaScript parser can interpret the same input
differently. Do not render untrusted prose in a separate unguarded `TextEdit`, and
do not populate a document before installing the guard. Installation failure
leaves prose empty.

`nix/markdown-guard.nix` builds the module and QML type metadata separately. The
package and development environment include its QML import path; the lint,
test, and smoke wrappers use that environment. Native renderer tests include
observable loopback HTTP positive controls, parser bypasses, local resource
placeholders, formatting, and selection. A Quickshell integration test streams
content through the real component and checks literal code copying.
