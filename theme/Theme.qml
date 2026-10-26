pragma Singleton

import QtQml
import QtQuick
import "../services" as Services

QtObject {
    readonly property string flavor: Services.ShellConfig.catppuccinFlavor
    readonly property var palettes: ({
        latte: {
            rosewater: "#dc8a78", flamingo: "#dd7878", pink: "#ea76cb", mauve: "#8839ef",
            red: "#d20f39", maroon: "#e64553", peach: "#fe640b", yellow: "#df8e1d",
            green: "#40a02b", teal: "#179299", sky: "#04a5e5", sapphire: "#209fb5",
            blue: "#1e66f5", lavender: "#7287fd", text: "#4c4f69", subtext1: "#5c5f77",
            subtext0: "#6c6f85", overlay2: "#7c7f93", overlay1: "#8c8fa1", overlay0: "#9ca0b0",
            surface2: "#acb0be", surface1: "#bcc0cc", surface0: "#ccd0da", base: "#eff1f5",
            mantle: "#e6e9ef", crust: "#dce0e8"
        },
        frappe: {
            rosewater: "#f2d5cf", flamingo: "#eebebe", pink: "#f4b8e4", mauve: "#ca9ee6",
            red: "#e78284", maroon: "#ea999c", peach: "#ef9f76", yellow: "#e5c890",
            green: "#a6d189", teal: "#81c8be", sky: "#99d1db", sapphire: "#85c1dc",
            blue: "#8caaee", lavender: "#babbf1", text: "#c6d0f5", subtext1: "#b5bfe2",
            subtext0: "#a5adce", overlay2: "#949cbb", overlay1: "#838ba7", overlay0: "#737994",
            surface2: "#626880", surface1: "#51576d", surface0: "#414559", base: "#303446",
            mantle: "#292c3c", crust: "#232634"
        },
        macchiato: {
            rosewater: "#f4dbd6", flamingo: "#f0c6c6", pink: "#f5bde6", mauve: "#c6a0f6",
            red: "#ed8796", maroon: "#ee99a0", peach: "#f5a97f", yellow: "#eed49f",
            green: "#a6da95", teal: "#8bd5ca", sky: "#91d7e3", sapphire: "#7dc4e4",
            blue: "#8aadf4", lavender: "#b7bdf8", text: "#cad3f5", subtext1: "#b8c0e0",
            subtext0: "#a5adcb", overlay2: "#939ab7", overlay1: "#8087a2", overlay0: "#6e738d",
            surface2: "#5b6078", surface1: "#494d64", surface0: "#363a4f", base: "#24273a",
            mantle: "#1e2030", crust: "#181926"
        },
        mocha: {
            rosewater: "#f5e0dc", flamingo: "#f2cdcd", pink: "#f5c2e7", mauve: "#cba6f7",
            red: "#f38ba8", maroon: "#eba0ac", peach: "#fab387", yellow: "#f9e2af",
            green: "#a6e3a1", teal: "#94e2d5", sky: "#89dceb", sapphire: "#74c7ec",
            blue: "#89b4fa", lavender: "#b4befe", text: "#cdd6f4", subtext1: "#bac2de",
            subtext0: "#a6adc8", overlay2: "#9399b2", overlay1: "#7f849c", overlay0: "#6c7086",
            surface2: "#585b70", surface1: "#45475a", surface0: "#313244", base: "#1e1e2e",
            mantle: "#181825", crust: "#11111b"
        }
    })
    readonly property var palette: palettes[flavor] || palettes.latte

    readonly property color rosewater: palette.rosewater
    readonly property color flamingo: palette.flamingo
    readonly property color pink: palette.pink
    readonly property color mauve: palette.mauve
    readonly property color red: palette.red
    readonly property color maroon: palette.maroon
    readonly property color peach: palette.peach
    readonly property color yellow: palette.yellow
    readonly property color green: palette.green
    readonly property color teal: palette.teal
    readonly property color sky: palette.sky
    readonly property color sapphire: palette.sapphire
    readonly property color blue: palette.blue
    readonly property color lavender: palette.lavender
    readonly property color text: palette.text
    readonly property color subtext1: palette.subtext1
    readonly property color subtext0: palette.subtext0
    readonly property color overlay2: palette.overlay2
    readonly property color overlay1: palette.overlay1
    readonly property color overlay0: palette.overlay0
    readonly property color surface2: palette.surface2
    readonly property color surface1: palette.surface1
    readonly property color surface0: palette.surface0
    readonly property color base: palette.base
    readonly property color mantle: palette.mantle
    readonly property color crust: palette.crust
    readonly property color transparent: "transparent"

    // Shell-wide semantic aliases.
    readonly property color outline: text
    readonly property color accent: mauve
    readonly property color border: surface0
    readonly property color track: surface0
    readonly property color fill: mauve
    readonly property color textOnAccent: base

    // Bar tokens.
    readonly property color barAccent: accent
    readonly property color barMuted: overlay2
    readonly property color barActiveSurface: surface1
    readonly property color barSurface: surface0
    readonly property color barBackground: mantle

    // Component aliases for targeted popup, pane, message, composer, and control styling.
    readonly property color popupBackground: base
    readonly property color popupBorder: surface0
    readonly property color popupSeparator: surface0
    readonly property color popupLabel: text
    readonly property color popupValue: text
    readonly property color popupIdle: overlay1
    readonly property color popupTrack: surface0
    readonly property color popupFill: mauve

    readonly property color assistantBubbleBackground: base
    readonly property color assistantBubbleBorder: surface0
    readonly property color userBubbleBackground: crust
    readonly property color userBubbleBorder: surface0
    readonly property color aiMarkerBackground: mauve
    readonly property color userMarkerBackground: surface1

    readonly property color composerBackground: base

    readonly property color surfaceBorder: border
    readonly property color surfaceBorderStrong: barAccent
    readonly property color focusBorder: barAccent
    readonly property color inputBackground: composerBackground
    readonly property color inputBackgroundActive: composerBackground
    readonly property color inputSelection: crust
    readonly property color buttonBackground: base
    readonly property color buttonBackgroundHover: crust
    readonly property color buttonBackgroundActive: surface1
    readonly property color buttonAccentBackground: barAccent
    readonly property color buttonDangerBackground: red
    readonly property color buttonTextOnAccent: textOnAccent

    // Subtle outer elevation for floating shell boxes. Apply only to outer
    // popup/window/pane frames, not inner cards or rows.
    readonly property bool outerShadowEnabled: true
    readonly property color outerShadowColor: "#000000"
    readonly property real outerShadowOpacity: 0.16
    readonly property real outerShadowBlur: 14
    readonly property real outerShadowSpread: 0
    readonly property real outerShadowHorizontalOffset: 0
    readonly property real outerShadowVerticalOffset: 3
    readonly property int outerShadowPadding: 12
    readonly property int outerShadowEffectivePadding: outerShadowEnabled ? outerShadowPadding : 0

    readonly property string proseFontFamily: Services.ShellConfig.proseFontFamily
    readonly property string monoFontFamily: Services.ShellConfig.monoFontFamily
    readonly property string codeFontFamily: Services.ShellConfig.codeFontFamily
    readonly property string notificationToastFontFamily: Services.ShellConfig.notificationToastFontFamily
    readonly property string fontFamily: monoFontFamily
    readonly property int fontSize: Services.ShellConfig.fontSize
    readonly property int aiPaneFontSize: Services.ShellConfig.aiPaneFontSize
    readonly property int tasksPaneFontSize: Services.ShellConfig.tasksPaneFontSize
    readonly property int notificationToastFontSize: Services.ShellConfig.notificationToastFontSize
    readonly property int fontWeight: 600

    // Bar dimensions derive from fontSize so configurable fonts do not clip glyph icons.
    readonly property int minimumBarIconSize: 12
    readonly property int barIconFontSize: Math.max(minimumBarIconSize, fontSize)
    readonly property int iconSize: barIconFontSize
    readonly property int barIconPadding: 8
    readonly property int minimumBarIconButtonWidth: 20
    readonly property int barIconButtonWidth: Math.max(minimumBarIconButtonWidth, iconSize + barIconPadding)
    readonly property int configuredBarHeight: Services.ShellConfig.barHeight
    readonly property int minimumReadableBarHeight: barIconFontSize + barIconPadding
    readonly property int barHeight: Math.max(configuredBarHeight, minimumReadableBarHeight)
    readonly property int moduleHeight: barHeight
    readonly property int workspaceWidth: Math.max(18, fontSize + 6)
    readonly property int barEdgePadding: 4
    readonly property int modulePadding: 10
    readonly property int moduleValuePadding: Math.max(3, Math.round(fontSize * 0.25))
    readonly property int moduleValueRightPadding: moduleValuePadding + 2
    readonly property int moduleGap: 10
    readonly property int sectionGap: moduleGap
    readonly property int listGap: 4
    readonly property int moduleLeadingWidth: barIconButtonWidth
    readonly property int indicatorThickness: 3
    readonly property int windowChipMinWidth: 44
    readonly property int batteryPopupWidth: 300
    readonly property int windowMaxWidth: 260
    readonly property int controlHeight: moduleHeight
    readonly property int controlPadding: modulePadding
    readonly property int controlSpacing: listGap + 2
}
