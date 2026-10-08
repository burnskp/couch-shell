# Reusable Refactor Review

This document captures the current code review findings around reusable shell UI adoption so the work can be split into multiple iterations.

It focuses on three questions:

- what can be updated now to use the newer reusable pieces
- what should be extracted into reusable code, but does not have a shared solution yet
- what should be refactored, but is currently blocked because the shared pieces only partially support the existing behavior

## Summary

Highest-value targets:

1. `modules/picker/PickerOverlay.qml`
1. shared inner structure across `modules/bar/popups/*.qml`

The shared controller layer looks healthy. I did not find a duplicate global pane, notification, or picker state system that should be merged back into the existing services.

## Bucket 1: Can Adopt Existing Reusable Pieces Now

These are good candidates for an early cleanup pass because the reusable pieces already exist and the migration risk is low.

### Wi-Fi Hover Totals Card

File:

- `modules/bar/popups/WifiHover.qml:231-289`

Current duplication:

- totals summary is implemented as a local `GridLayout` with repeated `Text`

Existing reusable piece that fits now:

- `components/HoverPopupKeyValueRow.qml`

Why this should be early:

- it is a direct match for the documented popup summary row helper
- it is a small, low-risk migration

Suggested iteration scope:

- convert the totals section to stacked `Components.HoverPopupKeyValueRow` rows

## Bucket 2: Should Become Reusable, But No Shared Solution Exists Yet

These are the places where the code wants a reusable abstraction, but the repo does not currently provide one.

### Picker Row Delegate Primitive

File:

- `modules/picker/PickerOverlay.qml`

Duplicated areas:

- stacked delegate at `:611-684`
- main row delegate at `:955-1055`

Shared behavior that should be extracted:

- badge block
- title/meta line
- subtitle line
- hover and selected background treatment
- click selection behavior

Why it matters:

- the picker currently carries the same row presentation logic in two places
- any future style change to picker results has to be implemented twice

Potential reusable target:

- a new picker-specific row component, likely under `modules/picker/` first unless a second consumer appears

Suggested iteration scope:

- introduce one local reusable row component for picker results
- wire both list layouts to the same component
- keep broader picker layout logic unchanged

### Menu Action Card / Status Cluster Button Reuse

Files:

- `modules/bar/popups/SystemMenu.qml:20-74`
- `modules/bar/widgets/StatusClusterWidget.qml:113-155`
- `modules/bar/widgets/StatusClusterWidget.qml:157-231`
- `modules/bar/widgets/StatusClusterWidget.qml:308-340`

Observation:

- there are local abstractions here that look reusable if more surfaces adopt the same pattern

Why this is lower priority:

- there is not yet enough duplication across the repo to justify a shared primitive immediately
- this should probably wait until a second or third real use case exists

Suggested iteration scope:

- defer unless upcoming work creates more consumers

## Bucket 3: Should Be Refactored, But Shared Pieces Only Have Partial Support

These are strong refactor targets, but the current reusable pieces do not fully support the way the feature works.

### Hover Popup Inner Cards

Files:

- `modules/bar/popups/AudioHover.qml`
- `modules/bar/popups/BatteryHover.qml`
- `modules/bar/popups/ClockHover.qml`
- `modules/bar/popups/CpuHover.qml`
- `modules/bar/popups/RamHover.qml`
- `modules/bar/popups/TemperatureHover.qml`
- `modules/bar/popups/WifiHover.qml`

What is already shared:

- outer popup shell via `components/HoverPopupFrame.qml`
- summary/process rows via popup row helpers

What is still duplicated:

- inner square card shell
- card padding and border treatment
- repeated title/value row structure

Why this is blocked today:

- `HoverPopupFrame` only solves the outer wrapper
- the docs explicitly note that inner card layout is still local

What likely needs to exist:

- a `HoverPopupCard` or `HoverPopupSection` primitive in `components/`

Suggested iteration scope:

- define the shared popup-card primitive first
- migrate one or two popups as references
- migrate the rest after the pattern feels stable

### Popup Metric Bars

Files with duplication:

- `modules/bar/popups/AudioHover.qml:62-77`
- `modules/bar/popups/AudioHover.qml:128-143`
- `modules/bar/popups/BatteryHover.qml:64-80`
- `modules/bar/popups/CpuHover.qml:112-149`
- `modules/bar/popups/RamHover.qml:80-114`
- `modules/bar/popups/TemperatureHover.qml:111-126`
- `modules/bar/popups/TemperatureHover.qml:176-209`

Related reusable piece:

- `ui/ShellMetricBar.qml`

Why this is blocked today:

- the reusable metric bar exists in `ui/`
- bar hover popups are documented to prefer `components/`
- the current bar does not fully solve the popup-layer reuse path

What likely needs to exist:

- either a popup-safe metric bar in `components/`
- or a documented cross-layer rule saying `ui/ShellMetricBar` is acceptable in bar hover popups

Suggested iteration scope:

- decide which layer should own popup metric bars
- then migrate the repeated bars once that ownership is clear

### Picker Overlay Chrome and Input

File:

- `modules/picker/PickerOverlay.qml`

Related reusable pieces:

- `ui/ShellPopupFrame.qml`
- `ui/ShellTextField.qml`

What the shared pieces help with:

- general popup chrome
- general text input styling

Why this is only a partial fit:

- picker supports centered and anchored presentation
- picker supports multiple preview layouts
- picker input has a custom badge-led structure
- picker layout coordinates results and preview panes in ways the generic popup shell does not cover

Suggested iteration scope:

- avoid a broad migration until the picker-specific reusable boundaries are clearer
- focus first on row delegate reuse, which is the clearest win

### Notification History Panel Surface

File:

- `modules/notifications/NotificationHistoryPanel.qml`

Related reusable piece:

- `ui/ShellPopupFrame.qml`

Why this is only a partial fit:

- notification history is an anchored `PanelWindow`
- it needs clipped scrolling list behavior and notification-specific card treatment
- `ShellPopupFrame` is useful reference chrome, but not a drop-in replacement for the whole panel

Suggested iteration scope:

- reuse smaller shared pieces now
- do not try to replace the full panel shell with `ShellPopupFrame` yet

## Feature Breakdown

## Part 2: Picker

Primary file:

- `modules/picker/PickerOverlay.qml`

This track has one clear local reuse win, but broader migration is blocked because the current shared popup/input primitives only partially fit the picker's layout and behavior.

### Picker: Iteration 1

Goal:

- remove duplicated picker row layout and interaction logic

Scope:

- extract a shared picker row primitive for the main and stacked result delegates
- centralize badge rendering, title/meta row, subtitle row, selected styling, and hover handling
- keep existing picker layout modes unchanged

Files:

- `modules/picker/PickerOverlay.qml`

Expected outcome:

- picker results become easier to restyle consistently
- future row behavior changes only need to be made once

### Picker: Iteration 2

Goal:

- decide what parts of picker chrome should become reusable without forcing it into the wrong shared primitives

Scope:

- evaluate whether the input surface should become a picker-specific reusable component
- evaluate whether preview surfaces should be standardized locally inside the picker module
- avoid forcing full migration to `Ui.ShellPopupFrame` or `Ui.ShellTextField` until the anchored, centered, and multi-preview layout requirements are covered

Files:

- `modules/picker/PickerOverlay.qml`

Expected outcome:

- clearer boundaries between generic shell primitives and picker-specific reusable pieces
- reduced risk of introducing an abstraction that only fits half of the picker's behavior

### Picker: Open Reuse Questions

- whether picker reuse should stay local to `modules/picker/` or eventually expose a more generic shell search/result surface
- whether the badge-led input treatment is picker-specific enough to remain local even if surrounding input chrome gets shared
- whether the preview pane variants are truly multiple layouts of one abstraction or several intentionally different presentations

## Notes

- I did not find evidence of duplicated global controller state for panes, notifications, or picker behavior. The current reuse gaps are mostly visual/component-level, not service-level.
- Some local abstractions should stay local until there is a second real consumer. The review should not be read as a reason to aggressively generalize every repeated block immediately.
