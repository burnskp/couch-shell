# Picker

The picker is a reusable shell overlay backed by `services/PickerService.qml` and rendered by `modules/picker/PickerOverlay.qml`.

It supports four common views:

1. input only
1. input with list underneath
1. input with list on the left and preview on the right
1. input with list on top and preview underneath

The picker overlay is already mounted per screen in `shell.qml`, so other services and widgets only need to call `PickerService.open(...)` with a config object.

## Service

Import the service from QML:

```qml
import "../services" as Services
```

Available constants:

- `Services.PickerService.modeInputOnly`
- `Services.PickerService.modeList`
- `Services.PickerService.modePreview`
- `Services.PickerService.presentationCentered`
- `Services.PickerService.presentationAnchored`
- `Services.PickerService.previewKindNone`
- `Services.PickerService.previewKindDetails`
- `Services.PickerService.previewKindText`
- `Services.PickerService.previewKindImage`

Primary API:

```qml
Services.PickerService.open(screen, config, mode, anchorX, anchorY, anchorWidth, anchorHeight)
Services.PickerService.close()
Services.PickerService.moveSelection(delta)
```

Arguments:

- `screen`: target screen object for the picker window
- `config`: picker config object
- `mode`: one of the three mode constants
- `anchorX`, `anchorY`, `anchorWidth`, `anchorHeight`: only needed for anchored presentation

The service also exposes runtime state:

- `visible`
- `openScreen`
- `currentConfig`
- `query`
- `selectedIndex`
- `currentItems`
- `currentSelection`

## Minimal Example

```qml
import QtQuick
import "../services" as Services
import "../theme" as Theme

Rectangle {
    id: launcher

    width: 120
    height: 32
    color: Theme.Theme.barSurface
    required property var targetScreen

    property var pickerConfig: ({
        id: "my-picker",
        title: "Launcher",
        presentation: Services.PickerService.presentationCentered,
        centeredTopEdgeFraction: 0.10,
        styleVariant: "utility",
        accentColor: Theme.Theme.mauve,
        surfaces: {
            frame: Theme.Theme.mantle,
            input: Theme.Theme.barBackground,
            list: Theme.Theme.mantle,
            preview: Theme.Theme.mantle,
            rowIdle: Theme.Theme.crust
        },
        selectedRowColor: Theme.Theme.surface0,
        previewLayout: "sidebarRightPreviewWide",
        placeholder: "Search installed applications",
        widthInputOnly: 620,
        widthList: 620,
        widthPreview: 620,
        heightInputOnly: 72,
        heightList: 360,
        heightPreview: 440,
        items: [
            {
                title: "Firefox",
                subtitle: "Web browser",
                meta: "firefox.desktop",
                search: "firefox browser web internet",
                previewKind: Services.PickerService.previewKindText,
                previewTitle: "Firefox.desktop",
                previewBody: "Name: Firefox\nExec: firefox"
            }
        ]
    })

    MouseArea {
        anchors.fill: parent
        onClicked: Services.PickerService.open(launcher.targetScreen, launcher.pickerConfig, Services.PickerService.modePreview, 0, 0, 0, 0)
    }
}
```

If you are opening from an existing bar or popup element and want anchored presentation, pass real anchor geometry instead of zeros.

## Config Shape

Supported config fields:

- `id`: stable identifier for the picker instance
- `title`: optional semantic label for your own use
- `presentation`: `centered` or `anchored`
- `centeredTopEdgeFraction`: top edge position for centered mode, as a fraction of screen height
- `styleVariant`: currently used for internal visual treatment; `utility` is the safest choice
- `accentColor`: accent used for borders, selection accents, and badges
- `surfaces`: object with `frame`, `input`, `list`, `preview`, `rowIdle`
- `selectedRowColor`: background color for the active row
- `previewLayout`: layout variant for preview-capable modes
- `showPreviewTitle`: set `false` to suppress preview header title
- `placeholder`: input placeholder text
- `widthInputOnly`, `widthList`, `widthPreview`
- `heightInputOnly`, `heightList`, `heightPreview`
- `items`: array of result items

## Item Shape

Supported item fields:

- `title`
- `subtitle`
- `meta`
- `search`
- `previewKind`
- `previewTitle`
- `previewBody`
- `previewAccent`

Filtering is built in. The picker matches against:

- `title`
- `subtitle`
- `meta`
- `search`
- `previewTitle`
- `previewBody`

## Layout Options

Current `previewLayout` values used by the overlay:

- `sideBalanced`
- `sideWidePreview`
- `sidePreviewLeft`
- `sidebarRightPreview`
- `sidebarRightPreviewWide`
- `stackedBottom`
- `stackedTop`
- `stackedBalanced`

Recommended mappings:

- input only: `modeInputOnly`
- input + list: `modeList`
- input + side preview: `modePreview` with `sidebarRightPreviewWide`
- input + bottom preview: `modePreview` with `stackedBottom`

## Keyboard Behavior

Built-in controls:

- `Esc`: close picker
- `Up` / `Down`: move selection when list is shown
- `PgUp` / `PgDn`: scroll text preview when preview is shown
- `Enter` / `Return`: close picker

## Notes

- The current picker is display-oriented. It does not yet expose a formal accept callback or selection handler.
- For now, treat it as reusable presentation and search state. If another service needs result execution, that should be added to `PickerService` as an explicit callback or signal rather than hardcoding behavior into the overlay.
- Only one input surface is instantiated at a time to avoid Wayland text-input surface warnings on reopen.
