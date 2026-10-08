pragma Singleton

import Quickshell.Services.UPower
import QtQml

QtObject {
    id: root

    readonly property var powerProfiles: PowerProfiles
    readonly property bool available: powerProfiles !== null && powerProfiles !== undefined
    readonly property int profile: available ? powerProfiles.profile : PowerProfile.Balanced
    readonly property string iconGlyph: {
        switch (profile) {
        case PowerProfile.PowerSaver:
            return "";
        case PowerProfile.Performance:
            return "";
        case PowerProfile.Balanced:
        default:
            return "";
        }
    }

    function cycleProfile() {
        if (!available)
            return;

        switch (powerProfiles.profile) {
        case PowerProfile.Performance:
            powerProfiles.profile = PowerProfile.PowerSaver;
            break;
        case PowerProfile.Balanced:
            powerProfiles.profile = PowerProfile.Performance;
            break;
        case PowerProfile.PowerSaver:
        default:
            powerProfiles.profile = PowerProfile.Balanced;
            break;
        }
    }
}
