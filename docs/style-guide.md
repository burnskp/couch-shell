# Couch Shell Style Guide

This document captures the visual and structural patterns that make `couch-shell` feel cohesive.

It is written to guide both humans and AI assistants making UI changes. Use it as the default design contract unless a local feature or existing module clearly establishes a stronger pattern.

For the concrete shared QML primitives and current segmented style baseline, see `docs/shared-ui.md`.

For bar widgets, hover popups, and popup helper rows, see `docs/components.md`.

## Purpose

Use this guide to keep new and updated UI work:

- visually consistent with the rest of the shell
- structurally predictable
- compact and information-dense without looking busy
- aligned with the existing QML component and theme system

## Core Principles

### Build from the theme

Prefer values from `theme/Theme.qml` over ad hoc numbers and colors.

Key tokens:

- colors: `Theme.Theme.text`, `subtext0`, `subtext1`, `surface0`, `surface1`, `barBackground`, `barSurface`, `barActiveSurface`, `barAccent`, `teal`, `blue`, `peach`, `red`, `mauve`
- typography: `proseFontFamily`, `monoFontFamily`, `codeFontFamily`, `fontFamily`, `fontSize`, `fontWeight`
- spacing/sizing: `modulePadding`, `moduleGap`, `sectionGap`, `listGap`, `moduleHeight`, `moduleLeadingWidth`, `indicatorThickness`, `windowMaxWidth`

### Prefer square geometry

The current shell language is square and crisp.

- default to `radius: 0`
- do not introduce rounded cards or pills unless the feature already uses them intentionally
- keep bars, cards, windows, and chips aligned to this square treatment

### Use clear hierarchy, not decoration

The shell should feel purposeful, not ornamental.

- use card structure and spacing to create hierarchy
- use accent color only when it communicates state
- avoid decorative color dots, ornaments, and gratuitous gradients
- make the most important information the easiest thing to scan

### Text-first, bars-second

Bars should support meaning, not replace it.

- primary information should still be readable as text
- bars should visualize state, comparison, or progress
- avoid putting critical text inside bars unless contrast is guaranteed and the text truly belongs there
- if text-on-bar becomes fragile, move labels outside the bar

### Stable layouts beat clever layouts

Prefer layouts that stay predictable across changing data.

- keep section order stable
- keep cards stable even when values change
- hide rows that are unavailable or redundant when they add noise
- do not let a popup become a raw dump of service fields

## Naming and File Organization

Use concept-based names, not old implementation names.

Good:

- `AudioHover.qml`
- `BatteryHover.qml`
- `ClockHover.qml`

Avoid:

- names tied to an outdated implementation detail like `SoundHover.qml` or `CalendarHover.qml` when the popup represents a broader concept

Rules:

- widget file names should match the concept they represent
- popup file names should match the widget concept plus `Hover`
- when a preset or internal constant still uses an older term, keep the docs clear about the preferred concept name rather than teaching both as equal choices
- rename old files when the UI concept changes enough that the old name becomes misleading

Current example:

- the clock popup component is `ClockHover.qml`
- `HoverPopupPresets.calendar` is the current internal preset name for that popup path
- in prose, prefer calling the feature the clock popup unless the code itself is being renamed

## Generic Shell Guidance

### Colors

Use color semantically.

- normal/healthy: `teal`
- informational/secondary metric: `blue`
- warm/warning: `peach`
- critical/error: `red`
- primary shell accent/selection: `mauve` or `barAccent`

Use `text` for primary readable text, `subtext0`/`subtext1` for supporting text.

Foreground rule:

- use `Theme.Theme.text` on light neutral surfaces such as `barBackground`, `barSurface`, `surface0`, and `surface1`
- use `Theme.Theme.crust` or `Theme.Theme.barBackground` when the background is dark, accent-colored, or otherwise high-contrast
- status bar widget icons/labels inside colored leading segments are the reference example for this pattern
- if a surface changes from neutral to accent/active state, the foreground should usually switch to the light/base-side color as well

Do not encode meaning only through saturation shifts when a threshold color is clearer.

### Typography

Typography should stay restrained.

- card headers: `fontSize`, bold
- secondary summaries: `fontSize` or `fontSize - 1`, bold or medium depending on importance
- supporting labels/body: `fontSize - 1` or `fontSize - 2`

Avoid oversized text unless the module is explicitly a hero surface.

### Spacing

Use tight, deliberate spacing.

- inside cards: usually `anchors.margins: 6`
- card internal spacing: usually `4` or `6`
- popup section spacing: usually `6`
- compact row spacing: `1` to `4`

If a surface starts to feel airy or detached, reduce spacing before adding more decoration.

## Widgets

Widgets are small status chips, not miniature dashboards.

Use `components/WidgetChip.qml` and the preset system unless there is a strong reason not to.

Implementation guidance for those building blocks lives in [`components.md`](components.md).

Widget rules:

- the widget should expose the single most useful live signal
- the popup should add context, not restate the widget text
- the widget should stay compact and fast to scan from the bar
- keep widget value widths predictable using `FontMetrics` when needed

Examples:

- CPU widget shows the CPU value; popup explains per-cluster load
- Battery widget shows time/full state; popup adds percent, state, and rate
- Clock widget shows time; popup adds date and month context

## Hover Popups

Hover popups are where most of the shell’s current visual language is defined.

Use `components/HoverPopupFrame.qml` as the base.

Implementation details and preferred helper rows live in [`components.md`](components.md).

### Preferred popup structure

Hover popups are flat: rows sit directly in `HoverPopupFrame` with no inner card boxes. `TemperatureHover.qml` is the reference.

Typical pattern:

1. primary metric rows
1. a `HoverPopupDivider`
1. secondary rows, or a compact list such as top processes

Build rows with `Components.HoverPopupMeterRow`, which gives every popup the same columns:

- icon (`popupIcon`, `fontSize + 6`)
- label (`popupLabel`)
- metric bar (`popupFill` on `popupTrack`), or free space when the row has no bar
- right-aligned value (`popupValue`)
- an optional `detail` line at `fontSize - 1` for device names, sizes, reset times, and similar supporting text

Keep all popup text in `popupLabel`/`popupValue`; do not dim secondary text to grey.

Set `contentSpacing: Theme.Theme.listGap + 2` on the frame. Use dividers between groups rather than borders, boxes, or headers.

Bars use `popupFill` by default. Switch the fill to `peach` or `red` only to signal a warning state, such as low battery or an exhausted quota. Keep the default `HoverPopupMetricBar` height across popups.

### Popup width

Prefer keeping hover popups in the same width class unless content clearly needs more room.

Current effective standard:

- widget popup width: about `292`
- popup min width: about `275`

Deviate only for content that genuinely needs it.

### Information selection rules

Good popup content:

- adds missing context
- groups related metrics together
- hides unavailable or redundant fields
- privileges the live question the user actually has

Bad popup content:

- repeats the widget headline in a larger surface
- exposes raw service fields without grouping
- gives equal weight to primary and secondary information
- leaves empty-state sections fully expanded without purpose

### Empty and unavailable states

Prefer hiding unavailable rows instead of rendering them as first-class content.

Good options:

- hide unavailable rows entirely
- replace a whole idle section with one compact row like `Fans  Idle`
- hide empty sections when they add nothing, such as an empty active-stream list

Avoid rendering lots of `Unavailable` text unless the absence itself is important.

## Popup-Specific Guidance by Pattern

### Metric popups

Examples: CPU, RAM, Battery, Temperature, Wi-Fi, Audio

Rules:

- lead with the primary metric rows
- put secondary/supporting rows after a divider
- make bars visualize meaningful normalized or stateful values
- if values have different safe limits, normalize them per source instead of comparing raw values directly

Examples learned from this repo:

- temperature bars should be normalized against per-sensor critical thresholds, not against raw temperature across unrelated devices
- battery status should hide rows that duplicate the widget’s time label
- Wi-Fi should not restate SSID/state that the widget already shows

### Calendar/clock popups

Clock popups should complement the time widget.

Use:

- a `Today` row with the weekday and the full date as detail
- a `Calendar` row with the month, followed by the month grid

Do not overload the clock popup with unrelated system data like time zones or extra clock readouts unless specifically required.

### Popup lists

For lists such as active audio streams or top processes:

- put the list after a divider
- use `HoverPopupMeterRow` with `showBar: false` and a `detail` subtitle, or `HoverPopupProcessRow` for processes
- spacing should stay tight
- if the list is empty, hide it and its divider, or show one compact empty row

## Windows and Large Surfaces

Windows, panes, and panels should feel like enlarged versions of the same system, not a different design language.

Representative files:

- `modules/panes/LeftPane.qml`
- `modules/notifications/ToastItem.qml`
- `modules/bar/TopBar.qml`

Rules:

- use square surfaces and sharp edges
- use `barBackground`, `barSurface`, and accent borders rather than soft layered glassmorphism
- use internal sections/cards inside the larger surface instead of one undifferentiated panel
- active tabs should use clear accent fills; inactive tabs should stay on surface colors
- overlays and notifications can use accent borders, but keep the interior restrained

For panes:

- prefer a neutral base surface with one accent border or active marker
- section blocks inside panes should reuse the same header + body pattern as popup cards
- use only subtle outer shadows on the pane frame itself; keep inner sections flat

For toasts:

- accent belongs on the edge or lifetime/progress treatment, not everywhere
- body copy should remain readable and subdued
- keep shadows outside the toast card and preserve flush screen-edge alignment where the toast anchors to an edge

## Window Chips and Bar Lists

Window chips are compact control surfaces, not decorative tabs.

Representative file:

- `modules/bar/widgets/WindowList.qml`

Rules:

- keep a two-segment structure: leading icon block + value/title block
- active state should use accent on the leading block and active surface on the title block
- inactive state should remain muted but readable
- do not add extra outlines or radius unless the whole bar language changes
- elide long titles instead of growing unpredictably

## Launchbars and Action Docks

`couch-shell` does not currently have one single launchbar module, but launchbar-like surfaces and action docks should follow the same rules.

Representative file:

- `modules/bar/popups/SystemMenu.qml`

Guidance:

- keep launchers and docks as grouped square actions
- use clear hover and pressed states
- keep iconography bold and centered
- use dividers only when they clarify grouping
- prefer one strong accent cue per interaction state instead of multiple competing effects

If creating a future launcher or launchbar:

- build it as a grouped surface with sectioned content
- keep search/results hierarchy text-first
- do not default to rounded modern-app-store styling unless intentionally changing the shell’s language

## AI Implementation Checklist

When adding or updating any UI piece, ask:

1. What is the single most important piece of information?
1. What information is already shown by the widget, and should therefore not be repeated in the popup?
1. For a pane or menu, should this be one card, two cards, or a card plus a compact list? For a hover popup, which rows lead and where do the dividers go?
1. Are bars showing meaningful normalized state, or just raw numbers that mislead?
1. Can unavailable or redundant rows be hidden?
1. Is the width aligned with the rest of the popups unless content clearly needs more?
1. Are colors semantic and restrained?
1. Does the filename still match the concept after the redesign?

## Do and Don’t

Do:

- reuse `WidgetChip`, `ModuleChip`, and `HoverPopupFrame`
- check [`components.md`](components.md) before creating a new chip or popup wrapper
- use theme tokens
- switch foreground text/icon color when the background becomes accent-colored or dark
- build square cards with clean internal hierarchy
- keep layouts stable and compact
- normalize values when raw comparisons are misleading
- hide redundant or unavailable information

Don’t:

- create a new visual language for one widget
- duplicate the widget’s main message inside the popup
- overload popups with every service field available
- rely on decorative accents instead of hierarchy
- leave dark foreground text on dark or saturated accent backgrounds
- mix rounded and square treatments casually
- keep outdated file names after a concept changes

## Current Popup Reference Pattern

The current preferred popup language is best represented by:

- `modules/bar/popups/CpuHover.qml`
- `modules/bar/popups/RamHover.qml`
- `modules/bar/popups/WifiHover.qml`
- `modules/bar/popups/BatteryHover.qml`
- `modules/bar/popups/TemperatureHover.qml`
- `modules/bar/popups/AudioHover.qml`
- `modules/bar/popups/ClockHover.qml`

When in doubt, align new work with those files first.
