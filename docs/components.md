# Components

This document explains the internal reusable building blocks in `components/`.

Use these components before creating a new bar chip, hover popup shell, or popup row primitive.

These are internal repo conventions, not public API guarantees.

Use [`style-guide.md`](style-guide.md) alongside this file for shell-wide naming, visual language, and popup content rules.

## Purpose

The `components/` layer exists to:

- keep bar widgets on one composition pattern
- keep hover popups on one layout and animation pattern
- avoid repeating chip and popup wiring in each widget
- give AI and contributors a clear first stop before introducing new wrappers

Import the module with:

```qml
import "../../components" as Components
```

Adjust the relative path for the file you are editing.

## Start Here

For new bar work:

- start with `Components.WidgetChip`
- use `popupContent` for hover popup content
- use `Components.HoverPopupFrame` inside the popup component
- use `Components.HoverPopupPresets` unless the popup needs a deliberate override

Drop to `Components.ModuleChip` only when `WidgetChip` is too opinionated for the widget you need.

## Core Chips

### `Components.ModuleChip`

Low-level bar chip base with:

- optional leading segment
- optional value segment
- hover and click state
- hover popup metadata consumed by `modules/bar/BarHoverPopupHost.qml`

Use it when:

- the widget still fits the shell's two-segment chip model
- `WidgetChip` is close, but you need direct control over chip colors or value content structure

Important properties:

- `leadingText`
- `clickable`
- `hoverable`
- `active`
- `hoverPopup`
- `hoverPopupWidth`
- `hoverPopupOffsetY`
- `hoverPopupCollapsedWidth`
- `hoverPopupOpenAnimationStyle`
- `hoverPopupCloseAnimationStyle`
- `hoverPopupKey`

Signal:

- `clicked(button)`

Minimal pattern:

```qml
Components.ModuleChip {
    leadingText: "CPU"
    clickable: true
    hoverable: true
    hoverPopup: cpuPopup

    Text {
        text: "34%"
    }

    onClicked: button => {
        if (button === Qt.LeftButton)
            doSomething()
    }
}
```

### `Components.WidgetChip`

Preferred entry point for new bar widgets.

`WidgetChip` wraps `ModuleChip` and applies:

- shell widget style presets
- icon segment defaults
- popup preset defaults
- standard `valueText` rendering
- optional `valueContent` loader for custom value layout

Use it when:

- building a normal bar widget
- the widget has a single primary signal and optional hover popup
- the shell's existing bar language should apply unchanged

Important properties:

- `appearancePreset`
- `tone`
- `popupPreset`
- `iconGlyph`
- `popupContent`
- `valueText`
- `valueContent`
- `interactive`
- `popupKey`
- `popupWidth`
- `preferredValueWidth`
- `maximumValueWidth`

Minimal pattern:

```qml
Components.WidgetChip {
    iconGlyph: "󰍛"
    valueText: Services.NetworkState.accessPointLabel
    popupPreset: Components.HoverPopupPresets.wifi
    popupContent: wifiPopup
}
```

Prefer `valueText` unless the widget really needs custom content. Use `valueContent` only when a plain text value is not enough.

## Popup Shell

### `Components.HoverPopupFrame`

Default base for widget hover popups.

Use it for:

- widget popups in `modules/bar/popups/`
- small hover information popups
- popup cards that should match the shell's current bar popup language

Important properties:

- `minPopupWidth`
- `contentSpacing`
- default `contentData`

Minimal pattern:

```qml
Components.HoverPopupFrame {
    minPopupWidth: 275

    Rectangle {
        Layout.fillWidth: true
        implicitHeight: 48
        color: Theme.Theme.surface0
    }
}
```

This component gives you the outer popup shell.

### `Components.HoverPopupCard`

Shared inner card shell for bar hover popups.

Use it for:

- the square inner cards inside `modules/bar/popups/`
- popup sections that need the standard surface, border, and inner padding

Important properties:

- default `contentData`
- `contentSpacing`
- `contentMargin`
- `extraHeight` when a popup needs a small height adjustment without reintroducing a custom shell

## Popup Presets

### `Components.HoverPopupPresets`

Shared popup behavior defaults for widget popups.

Available preset names today:

- `defaultPreset`
- `audio`
- `battery`
- `calendar` for the current clock popup preset name
- `cpu`
- `ram`
- `wifi`

The clock popup component is named `ClockHover.qml`, but its current preset name is still `calendar`. Treat `ClockHover` as the user-facing concept name in new prose and filenames unless the code path is intentionally renamed.

Use it when:

- a widget popup should follow standard open and close animation choices
- a widget needs a popup key that other code can react to

The most important caller is `WidgetChip`, which reads the preset and forwards:

- `offsetY`
- `collapsedWidth`
- `duration`
- `openDuration`
- `closeDuration`
- `openAnimation`
- `closeAnimation`
- `key`

Typical usage:

```qml
Components.WidgetChip {
    popupPreset: Components.HoverPopupPresets.cpu
}
```

Use a custom override only when the popup genuinely needs behavior outside the current preset set.

## Popup Rows

### `Components.HoverPopupKeyValueRow`

Preferred label/value row for popup cards.

Use this for bar hover popups in `modules/bar/popups/`.

If the surface is a pane, menu, settings card, or other general shell popup outside the bar hover-popup path, use `Ui.ShellKeyValueRow` from [`shared-ui.md`](shared-ui.md) instead.

Use it for:

- short metric summaries
- battery, network, and system information rows
- compact popup metadata

Important properties:

- `label`
- `value`
- `labelColumnWidth`
- `labelElide` (defaults to `Text.ElideNone`; use `Text.ElideMiddle` for bounded discovered names)
- `centerValueWhenLabelEmpty`
- `valueWrap`

### `Components.HoverPopupProcessRow`

Preferred row for top-process style popup lists.

Use this for bar hover popups, not for general pane or menu lists.

Use it when showing:

- PID
- process/command text
- a trailing metric such as CPU percent or RSS

Important properties:

- `pid`
- `command`
- `metricText`

### `Components.HoverPopupMetricBar`

Preferred metric bar for bar hover popups.

Use it for:

- popup metric fills in `modules/bar/popups/`
- popup bars that need optional overlay content such as a trailing percent label

Important properties:

- `value` from `0` to `1`
- `fillColor`
- `trackColor`
- `fillOpacity`
- `barHeight`
- default `overlayData`

### `Components.HoverPopupDivider`

Preferred thin divider for popup sections.

Use it instead of ad hoc `Rectangle { implicitHeight: 1 }` separators in hover popups.

## Specialized Helpers

### `Components.NotificationAppIcon`

Use this for notification app icons instead of rebuilding icon fallback logic.

It already integrates with `Services.TrayIconResolver.notificationIconCandidates(...)` and the shell's fallback treatment.

### `Components.DigitalClock`

Ready-made clock widget built on `WidgetChip`.

Treat this as a real reference implementation for a simple widget with popup content.

## When To Use `components/` vs `ui/`

Use `components/` when:

- building bar widgets
- building hover popups tied to bar widgets
- wiring popup animation behavior through widget-level presets

Use `ui/` when:

- building panes
- building menus and settings surfaces
- building general shell controls such as buttons, sections, text fields, and section frames

See [`shared-ui.md`](shared-ui.md) for the `ui/` layer.

## Rules Of Thumb

- prefer `WidgetChip` over `ModuleChip`
- prefer `HoverPopupFrame` over a new popup shell wrapper
- prefer popup helper rows over local one-off clones in bar hover popups
- if the popup belongs to a pane, menu, or settings surface instead of the bar, prefer the `ui/` equivalents from [`shared-ui.md`](shared-ui.md)
- extend presets only when at least 2 real widgets want the same popup behavior
- if a widget cannot fit the chip model, stop and confirm that it really belongs in the bar before creating a new primitive

## Reference Usages

- `components/DigitalClock.qml`
- `modules/bar/widgets/CpuWidget.qml`
- `modules/bar/widgets/RamWidget.qml`
- `modules/bar/widgets/AudioWidget.qml`
- `modules/bar/widgets/BatteryWidget.qml`
- `modules/bar/widgets/TemperatureWidget.qml`
- `modules/bar/widgets/WifiWidget.qml`
- `modules/bar/popups/CpuHover.qml`
- `modules/bar/popups/RamHover.qml`
- `modules/bar/popups/WifiHover.qml`
- `modules/bar/popups/BatteryHover.qml`
