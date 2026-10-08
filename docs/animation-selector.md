# Animation Selector

`animations/AnimationSelector.qml` is the shared wrapper for shell open and close effects.

Use it when a surface should:

- animate in and out with one of the shared presets
- stay mounted while the close animation is still running
- expose a simple `open` boolean instead of hand-wiring per-animation components

The selector swaps between separate open and close animation items and forwards a shared set of properties to whichever preset is active.

## Import

```qml
import "../../animations" as Animations
```

Adjust the relative path for the file you are editing.

## Minimal Pattern

```qml
Animations.AnimationSelector {
    id: panelAnimation

    anchors.fill: parent
    open: root.panelOpen
    openPreset: Animations.AnimationRegistry.slideIn
    closePreset: Animations.AnimationRegistry.smoke
    openDuration: Animations.AnimationPresets.slideInEnterDurationMs
    closeDuration: Animations.AnimationPresets.smokeDurationMs

    Rectangle {
        anchors.fill: parent
        color: Theme.Theme.barBackground
    }
}
```

For windows and overlays, bind the outer visibility to `shouldShow`, not just `open`, so the close animation can finish before the window disappears.

Example:

```qml
visible: panelAnimation.shouldShow
```

## Common Properties

### State

- `open`: target state for the animation
- `running`: `true` while the current animation is active
- `shouldShow`: `true` while open or while closing animation still needs to render
- `phase`: `"open"` or `"close"`
- `progress`: preset-reported progress value for the active animation

### Presets

- `preset`: fallback preset used for both directions if `openPreset` and `closePreset` are not set
- `openPreset`: preset for opening
- `closePreset`: preset for closing

The selector normalizes preset names through `AnimationRegistry`.

Current shared presets:

- `Animations.AnimationRegistry.smoke`
- `Animations.AnimationRegistry.slideIn`
- `Animations.AnimationRegistry.hoverReveal`

### Timing

- `duration`: shared duration fallback
- `openDuration`: open-specific override
- `closeDuration`: close-specific override
- `easingType`: easing passed through to the active preset

If a direction-specific duration is not set, the selector falls back to `duration`, then to the default duration for that preset.

### Preset-Specific Inputs

- `collapsedWidth`: used by `hoverReveal`
- `startX`: used by `slideIn`
- `endX`: used by `slideIn`

These values are forwarded only when the active preset supports them.

## Related Exports

### `Animations.AnimationRegistry`

Use registry constants instead of ad hoc preset strings when possible.

Available shared presets:

- `Animations.AnimationRegistry.smoke`
- `Animations.AnimationRegistry.slideIn`
- `Animations.AnimationRegistry.hoverReveal`

The registry also normalizes common string variants, but callers should still prefer the shared constants so new code matches existing usage.

### `Animations.AnimationPresets`

Use these shared timing defaults when a caller needs explicit durations:

- `Animations.AnimationPresets.hoverRevealDurationMs`
- `Animations.AnimationPresets.smokeDurationMs`
- `Animations.AnimationPresets.slideInEnterDurationMs`
- `Animations.AnimationPresets.easeOutCubic`

Typical pattern:

```qml
openPreset: Animations.AnimationRegistry.slideIn
closePreset: Animations.AnimationRegistry.smoke
openDuration: Animations.AnimationPresets.slideInEnterDurationMs
closeDuration: Animations.AnimationPresets.smokeDurationMs
```

Prefer these shared constants before introducing one-off timing values for common shell motion.

## Preset Notes

### Smoke

Use `smoke` when the surface should dissolve in and out without directional motion.

Typical use:

- picker open and close
- pane close
- toast close
- notification panel close

### Slide In

Use `slideIn` when the open animation should read as entering from one side.

Typical inputs:

```qml
openPreset: Animations.AnimationRegistry.slideIn
startX: width + Theme.Theme.sectionGap
```

or from the left:

```qml
startX: -(width + Theme.Theme.sectionGap)
```

`slideIn` is commonly paired with `smoke` on close.

### Hover Reveal

Use `hoverReveal` for popup surfaces that should expand from a compact width into full content.

Typical inputs:

```qml
openPreset: Animations.AnimationRegistry.hoverReveal
collapsedWidth: Theme.Theme.moduleLeadingWidth * 2
```

## Sizing Rules

`AnimationSelector` does not provide useful implicit width on its own.

That is intentional: many animated children use `anchors.fill: parent`, and deriving implicit width from those children creates binding loops.

When using the selector:

- set `width` explicitly, or
- use `anchors.fill: parent`, or
- place it in a layout that gives it a concrete width

Do not rely on `AnimationSelector.implicitWidth` for layout decisions.

`implicitHeight` still comes from the selector's content, which is useful for popup-style surfaces that have a fixed width but content-driven height.

## Internal Content vs External Source

The selector's child items become the animation source automatically through its default property:

```qml
Animations.AnimationSelector {
    Rectangle { }
}
```

This is the normal pattern and the one used across the shell.

The actual preset items receive that content as their `sourceItem`, so callers usually do not need to think about the underlying animation implementation.

## Recommended Patterns

- use `open` as the single source of truth for whether the surface should be expanded
- bind window or overlay visibility to `shouldShow`
- use `slideIn` for directional entry and `smoke` for exit when motion should only happen on open
- use `smoke` for both directions when the surface should feel more ambient than positional
- give the selector a concrete width

## Reference Usages

- `modules/panes/LeftPane.qml`
- `modules/panes/RightPane.qml`
- `modules/notifications/NotificationHistoryPanel.qml`
- `modules/notifications/ToastItem.qml`
- `modules/bar/BarHoverPopupHost.qml`
- `modules/picker/PickerOverlay.qml`
