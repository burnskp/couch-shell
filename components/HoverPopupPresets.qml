pragma Singleton

import QtQml
import "../animations" as Animations
import "../theme" as Theme

QtObject {
    readonly property string defaultPreset: "default"
    readonly property string audio: "audio"
    readonly property string battery: "battery"
    readonly property string calendar: "calendar"
    readonly property string cpu: "cpu"
    readonly property string ram: "ram"
    readonly property string wifi: "wifi"

    function normalizePreset(name) {
        const value = (name || "").toString().trim().toLowerCase();

        switch (value) {
        case audio:
            return audio;
        case battery:
            return battery;
        case calendar:
            return calendar;
        case cpu:
            return cpu;
        case ram:
            return ram;
        case wifi:
            return wifi;
        case defaultPreset:
        case "":
        default:
            return defaultPreset;
        }
    }

    function preset(name) {
        const normalizedName = normalizePreset(name);
        const preset = {
            offsetY: Theme.Theme.listGap + 4,
            collapsedWidth: Theme.Theme.moduleLeadingWidth * 2,
            duration: -1,
            openDuration: Animations.AnimationPresets.smokeDurationMs,
            closeDuration: Animations.AnimationPresets.smokeDurationMs,
            openAnimation: Animations.AnimationRegistry.smoke,
            closeAnimation: Animations.AnimationRegistry.smoke,
            key: ""
        };

        switch (normalizedName) {
        case cpu:
            preset.key = cpu;
            break;
        case ram:
            preset.key = ram;
            break;
        case audio:
        case battery:
        case calendar:
        case wifi:
        case defaultPreset:
        default:
            break;
        }

        return preset;
    }
}
