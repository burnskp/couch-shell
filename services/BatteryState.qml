pragma Singleton

import Quickshell.Services.UPower
import QtQml
import "." as Services
import "./BatteryLogic.js" as BatteryLogic

QtObject {
    id: root

    readonly property var device: UPower.displayDevice
    readonly property var powerProfiles: PowerProfiles
    readonly property bool ready: device && device.ready && device.isLaptopBattery
    readonly property real rawPercentage: ready && device.percentage !== undefined ? device.percentage : 0
    readonly property int percentage: ready ? Math.round(rawPercentage <= 1 ? rawPercentage * 100 : rawPercentage) : 0
    readonly property int deviceState: ready && device.state !== undefined && device.state !== null ? device.state : UPowerDeviceState.Unknown
    readonly property string stateText: ready ? UPowerDeviceState.toString(deviceState) : ""
    readonly property bool charging: deviceState === UPowerDeviceState.Charging || deviceState === UPowerDeviceState.PendingCharge
    readonly property bool plugged: charging || deviceState === UPowerDeviceState.FullyCharged
    readonly property bool discharging: ready && deviceState === UPowerDeviceState.Discharging
    readonly property bool lowWarning: discharging && percentage <= 20
    readonly property bool lowCritical: discharging && percentage <= 10
    property int lowBatteryAlertLevel: 0
    readonly property string iconGlyph: BatteryLogic.batteryIcon(percentage, charging, plugged)
    readonly property real remainingSeconds: ready ? charging ? device.timeToFull : device.timeToEmpty : 0
    readonly property string statusSummary: {
        if (!ready)
            return "Unavailable";
        if (plugged && !charging)
            return "Fully charged";
        if (charging)
            return "Charging";
        if (deviceState === UPowerDeviceState.Discharging)
            return "Discharging";
        return stateText.length > 0 ? stateText : "Unknown";
    }
    readonly property real powerWatts: {
        if (!ready)
            return NaN;

        if (device.changeRate !== undefined)
            return Math.abs(device.changeRate);

        if (device.energyRate !== undefined)
            return Math.abs(device.energyRate);

        return NaN;
    }
    readonly property bool healthSupported: ready && device.healthSupported === true
    readonly property real healthPercentage: healthSupported && device.healthPercentage !== undefined ? device.healthPercentage : NaN
    readonly property int degradationReason: powerProfiles && powerProfiles.performanceDegradationReason !== undefined ? powerProfiles.performanceDegradationReason : PerformanceDegradationReason.None
    readonly property bool degradationActive: degradationReason !== PerformanceDegradationReason.None
    readonly property string degradationText: degradationActive ? PerformanceDegradationReason.toString(degradationReason) : ""
    readonly property string healthText: healthSupported && Number.isFinite(healthPercentage) ? Math.round(healthPercentage) + "%" : "Unavailable"
    readonly property string wattsText: Number.isFinite(powerWatts) && powerWatts > 0 ? powerWatts.toFixed(1) + " W" : "Unavailable"
    readonly property string label: {
        if (!ready)
            return "--:--";
        return BatteryLogic.batteryLabel(remainingSeconds, charging, plugged);
    }

    function evaluateLowBatteryAlert() {
        const alertLevel = BatteryLogic.lowBatteryAlertLevel(root.ready, root.discharging, root.percentage);

        if (alertLevel === 0) {
            root.lowBatteryAlertLevel = 0;
            return;
        }

        if (!BatteryLogic.shouldRecordLowBatteryAlert(root.lowBatteryAlertLevel, alertLevel))
            return;

        root.lowBatteryAlertLevel = alertLevel;
        Services.NotificationManager.recordNotification(BatteryLogic.lowBatteryAlertPayload(
            alertLevel,
            root.percentage,
            root.label,
            Services.NotificationManager.urgencyNormal,
            Services.NotificationManager.urgencyCritical,
            Services.NotificationManager.defaultTimeoutMs
        ));
    }

    onPercentageChanged: evaluateLowBatteryAlert()
    onDeviceStateChanged: evaluateLowBatteryAlert()

    Component.onCompleted: evaluateLowBatteryAlert()
}
