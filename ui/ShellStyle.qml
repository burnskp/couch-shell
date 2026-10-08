pragma Singleton

import QtQml
import "../theme" as Theme

QtObject {
    readonly property var segmented: ({
        textColor: Theme.Theme.text,
        mutedTextColor: Theme.Theme.subtext0,
        subtleTextColor: Theme.Theme.overlay1,
        accentColor: Theme.Theme.accent,
        dangerColor: Theme.Theme.red,
        surfaceColor: Theme.Theme.base,
        subtleSurfaceColor: Theme.Theme.mantle,
        accentSurfaceColor: Theme.Theme.crust,
        borderColor: Theme.Theme.surface0,
        strongBorderColor: Theme.Theme.surface1,
        dividerColor: Theme.Theme.surface0,
        inputBackground: Theme.Theme.inputBackground,
        inputBackgroundActive: Theme.Theme.inputBackgroundActive,
        inputSelection: Theme.Theme.inputSelection,
        focusBorder: Theme.Theme.focusBorder,
        buttonBackground: Theme.Theme.buttonBackground,
        buttonHoverBackground: Theme.Theme.buttonBackgroundHover,
        buttonActiveBackground: Theme.Theme.buttonBackgroundActive,
        accentBackground: Theme.Theme.buttonAccentBackground,
        accentHoverBackground: Theme.Theme.buttonAccentBackground,
        accentActiveBackground: Theme.Theme.buttonAccentBackground,
        dangerBackground: Theme.Theme.buttonDangerBackground,
        textOnAccentColor: Theme.Theme.buttonTextOnAccent,
        sectionPadding: 8,
        sectionSpacing: 8,
        controlSpacing: Theme.Theme.controlSpacing,
        controlHeight: Theme.Theme.controlHeight,
        buttonHorizontalPadding: Theme.Theme.modulePadding,
        buttonVerticalPadding: 0,
        metricTrackColor: Theme.Theme.track,
        metricFillColor: Theme.Theme.fill,
        windowPadding: Theme.Theme.modulePadding,
        overlayColor: Theme.Theme.mantle,
        overlayOpacity: 0.26,
        accentRailWidth: 2,
        buttonAccentRailWidth: 0,
        inputFocusRailWidth: 0,
        popupBackground: Theme.Theme.popupBackground,
        popupTopBarColor: Theme.Theme.popupBackground,
        summary: "Catppuccin Latte surfaces with Mauve accents and square geometry."
    })

    readonly property var flatPopup: Object.assign({}, segmented, {
        surfaceColor: Theme.Theme.popupBackground,
        subtleSurfaceColor: Theme.Theme.popupBackground,
        accentSurfaceColor: Theme.Theme.popupBackground,
        borderColor: Theme.Theme.surface0,
        strongBorderColor: Theme.Theme.surface1,
        dividerColor: Theme.Theme.surface0,
        buttonBackground: Theme.Theme.popupBackground,
        buttonHoverBackground: Theme.Theme.crust,
        buttonActiveBackground: Theme.Theme.crust,
        metricTrackColor: Theme.Theme.surface0,
        metricFillColor: Theme.Theme.mauve,
        overlayOpacity: 0
    })

    readonly property var segmentedTabs: Object.assign({}, segmented, {
        buttonBackground: Theme.Theme.base,
        buttonHoverBackground: Theme.Theme.crust,
        buttonActiveBackground: Theme.Theme.barAccent,
        textOnAccentColor: Theme.Theme.buttonTextOnAccent,
        buttonHorizontalPadding: Theme.Theme.modulePadding + 2
    })
}
