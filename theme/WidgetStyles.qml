pragma Singleton

import QtQml
import QtQuick
import "." as ThemeModule

QtObject {
    readonly property string metric: "metric"
    readonly property string toggle: "toggle"
    readonly property string status: "status"
    readonly property string clock: "clock"
    readonly property string accent: "accent"

    readonly property string toneNormal: "normal"
    readonly property string toneAccent: "accent"
    readonly property string toneCaution: "caution"
    readonly property string toneWarning: "warning"
    readonly property string toneMuted: "muted"

    function normalizeAppearancePreset(name) {
        const value = (name || "").toString().trim().toLowerCase();

        switch (value) {
        case toggle:
            return toggle;
        case status:
            return status;
        case clock:
            return clock;
        case accent:
            return accent;
        case metric:
        default:
            return metric;
        }
    }

    function normalizeTone(name) {
        const value = (name || "").toString().trim().toLowerCase();

        switch (value) {
        case toneAccent:
            return toneAccent;
        case toneCaution:
            return toneCaution;
        case toneWarning:
            return toneWarning;
        case toneMuted:
            return toneMuted;
        case toneNormal:
        default:
            return toneNormal;
        }
    }

    function tonePreset(name) {
        const normalizedTone = normalizeTone(name);

        switch (normalizedTone) {
        case toneAccent:
            return {
                leadingBackground: ThemeModule.Theme.barAccent,
                activeLeadingBackground: ThemeModule.Theme.barAccent,
                hoverLeadingBackground: ThemeModule.Theme.barAccent,
                leadingTextColor: ThemeModule.Theme.barBackground,
                activeLeadingTextColor: ThemeModule.Theme.barBackground,
                valueBackground: ThemeModule.Theme.barSurface,
                activeValueBackground: ThemeModule.Theme.barActiveSurface,
                hoverValueBackground: ThemeModule.Theme.barSurface
            };
        case toneCaution:
            return {
                leadingBackground: ThemeModule.Theme.peach,
                activeLeadingBackground: ThemeModule.Theme.peach,
                hoverLeadingBackground: ThemeModule.Theme.peach,
                leadingTextColor: ThemeModule.Theme.barBackground,
                activeLeadingTextColor: ThemeModule.Theme.barBackground,
                valueBackground: ThemeModule.Theme.barSurface,
                activeValueBackground: ThemeModule.Theme.barActiveSurface,
                hoverValueBackground: ThemeModule.Theme.barSurface
            };
        case toneWarning:
            return {
                leadingBackground: ThemeModule.Theme.red,
                activeLeadingBackground: ThemeModule.Theme.red,
                hoverLeadingBackground: ThemeModule.Theme.red,
                leadingTextColor: ThemeModule.Theme.barBackground,
                activeLeadingTextColor: ThemeModule.Theme.barBackground,
                valueBackground: ThemeModule.Theme.barSurface,
                activeValueBackground: ThemeModule.Theme.barActiveSurface,
                hoverValueBackground: ThemeModule.Theme.barSurface
            };
        case toneMuted:
            return {
                leadingBackground: ThemeModule.Theme.barMuted,
                activeLeadingBackground: ThemeModule.Theme.barMuted,
                hoverLeadingBackground: ThemeModule.Theme.barMuted,
                leadingTextColor: ThemeModule.Theme.barBackground,
                activeLeadingTextColor: ThemeModule.Theme.barBackground,
                valueBackground: ThemeModule.Theme.barSurface,
                activeValueBackground: ThemeModule.Theme.barActiveSurface,
                hoverValueBackground: ThemeModule.Theme.barSurface
            };
        case toneNormal:
        default:
            return {
                leadingBackground: ThemeModule.Theme.barMuted,
                activeLeadingBackground: ThemeModule.Theme.barAccent,
                hoverLeadingBackground: ThemeModule.Theme.barAccent,
                leadingTextColor: ThemeModule.Theme.barBackground,
                activeLeadingTextColor: ThemeModule.Theme.barBackground,
                valueBackground: ThemeModule.Theme.barSurface,
                activeValueBackground: ThemeModule.Theme.barActiveSurface,
                hoverValueBackground: ThemeModule.Theme.barSurface
            };
        }
    }

    function chipPreset(name, toneName) {
        const normalizedName = normalizeAppearancePreset(name);
        const palette = tonePreset(toneName);
        const preset = {
            leadingBackground: palette.leadingBackground,
            activeLeadingBackground: palette.activeLeadingBackground,
            hoverLeadingBackground: palette.hoverLeadingBackground,
            leadingTextColor: palette.leadingTextColor,
            activeLeadingTextColor: palette.activeLeadingTextColor,
            valueBackground: palette.valueBackground,
            activeValueBackground: palette.activeValueBackground,
            hoverValueBackground: palette.hoverValueBackground,
            paddingY: 0,
            leadingWidth: ThemeModule.Theme.moduleLeadingWidth,
            leadingHorizontalCenterOffset: 0,
            leadingVerticalCenterOffset: 0
        };

        switch (normalizedName) {
        case toggle:
            preset.hoverValueBackground = ThemeModule.Theme.barActiveSurface;
            break;
        case status:
            preset.leadingBackground = ThemeModule.Theme.barSurface;
            preset.activeLeadingBackground = ThemeModule.Theme.barActiveSurface;
            preset.hoverLeadingBackground = ThemeModule.Theme.barActiveSurface;
            preset.leadingTextColor = ThemeModule.Theme.text;
            preset.activeLeadingTextColor = ThemeModule.Theme.text;
            break;
        case clock:
            preset.leadingHorizontalCenterOffset = 1;
            break;
        case accent:
            preset.leadingBackground = ThemeModule.Theme.barAccent;
            preset.activeLeadingBackground = ThemeModule.Theme.barAccent;
            preset.hoverLeadingBackground = ThemeModule.Theme.barAccent;
            preset.leadingTextColor = ThemeModule.Theme.barBackground;
            preset.activeLeadingTextColor = ThemeModule.Theme.barBackground;
            break;
        case metric:
        default:
            break;
        }

        return preset;
    }

}
