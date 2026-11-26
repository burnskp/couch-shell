pragma Singleton

import QtQml

QtObject {
    function parseObjectToken(token) {
        try {
            const parsed = JSON.parse(token);
            return parsed && typeof parsed === "object" && !Array.isArray(parsed) ? parsed : ({});
        } catch (error) {
            return {};
        }
    }

    function stringToken(token, fallback) {
        return token.indexOf("__") === 0 ? fallback : token;
    }

    function parseDiskToken(token) {
        try {
            return JSON.parse(token);
        } catch (error) {
            return { warningThresholdGiB: 50, criticalThresholdGiB: 10, textPath: "/persist", popupPaths: [
                { name: "Persist", path: "/persist" },
                { name: "Ephemeral", path: "/" }
            ] };
        }
    }

    // Right-side bar chips in display order. "temperature" is also dropped when bar.temperature.enable is false.
    readonly property var barWidgetIds: ["cpu", "temperature", "ram", "disk", "aiUsage", "wifi", "battery", "audio", "clock"]
    readonly property var barWidgetsDefault: ["cpu", "temperature", "ram", "disk", "wifi", "battery", "audio", "clock"]

    function parseBarWidgetsToken(token) {
        let parsed = barWidgetsDefault;
        try {
            const value = JSON.parse(token);
            if (Array.isArray(value))
                parsed = value;
        } catch (error) {}

        const result = [];
        for (const id of parsed) {
            if (barWidgetIds.indexOf(id) >= 0 && result.indexOf(id) < 0)
                result.push(id);
        }
        return result;
    }

    function barWidgetEnabled(id) {
        return barWidgets.indexOf(id) >= 0;
    }

    readonly property string barWidgetsToken: '__BAR_WIDGETS_JSON__'
    readonly property var barWidgets: parseBarWidgetsToken(barWidgetsToken).filter(id => id !== "temperature" || barTemperatureEnableToken === "true")

    readonly property var barDisk: parseDiskToken("__BAR_DISK_JSON__")
    readonly property real barDiskWarningThresholdGiB: barDisk.warningThresholdGiB ?? 50
    readonly property real barDiskCriticalThresholdGiB: barDisk.criticalThresholdGiB ?? 10
    readonly property string barDiskTextPath: barDisk.textPath
    readonly property var barDiskPopupPaths: barDisk.popupPaths
    readonly property bool barDiskBtrfsEnabled: !!(barDisk.btrfs && barDisk.btrfs.enable)
    readonly property int barDiskBtrfsPollInterval: barDisk.btrfs ? barDisk.btrfs.pollInterval : 300
    readonly property string btrfsClient: stringToken("__BTRFS_CLIENT__", "couch-shell-btrfs-client")

    readonly property string desktopWallpaper: "__DESKTOP_WALLPAPER__"
    readonly property string aiCodexHelper: "__AI_CODEX_HELPER__"
    readonly property string couchTasksCommand: "__COUCH_TASKS_COMMAND__"
    readonly property string catppuccinFlavor: stringToken("__CATPPUCCIN_FLAVOR__", "latte")
    readonly property string proseFontFamily: stringToken("__FONT_PROSE_FAMILY__", "Inter")
    readonly property string monoFontFamily: stringToken("__FONT_MONO_FAMILY__", "CommitMono Nerd Font")
    readonly property string codeFontFamily: stringToken("__FONT_CODE_FAMILY__", monoFontFamily)
    readonly property string notificationToastFontFamily: stringToken("__NOTIFICATION_TOAST_FONT_FAMILY__", monoFontFamily)
    readonly property string fontSizeToken: "__FONT_SIZE__"
    readonly property int fontSize: Number(fontSizeToken) > 0 ? Number(fontSizeToken) : 12
    readonly property string aiPaneFontSizeToken: "__AI_PANE_FONT_SIZE__"
    readonly property int aiPaneFontSize: Number(aiPaneFontSizeToken) > 0 ? Number(aiPaneFontSizeToken) : fontSize
    readonly property string tasksPaneFontSizeToken: "__TASKS_PANE_FONT_SIZE__"
    readonly property int tasksPaneFontSize: Number(tasksPaneFontSizeToken) > 0 ? Number(tasksPaneFontSizeToken) : fontSize
    readonly property string notificationToastFontSizeToken: "__NOTIFICATION_TOAST_FONT_SIZE__"
    readonly property int notificationToastFontSize: Number(notificationToastFontSizeToken) > 0 ? Number(notificationToastFontSizeToken) : fontSize
    readonly property string aiUsageDefaultProvider: stringToken("__AI_USAGE_DEFAULT_PROVIDER__", "chatgpt")
    readonly property string aiUsageHoverProviders: stringToken("__AI_USAGE_HOVER_PROVIDERS__", "all")
    readonly property string aiUsageRefreshIntervalToken: "__AI_USAGE_REFRESH_INTERVAL__"
    readonly property int aiUsageRefreshInterval: Number(aiUsageRefreshIntervalToken) > 0 ? Number(aiUsageRefreshIntervalToken) : 300
    readonly property string notificationHistoryLimitToken: "__NOTIFICATION_HISTORY_LIMIT__"
    readonly property int notificationHistoryLimit: Number(notificationHistoryLimitToken) > 0 ? Number(notificationHistoryLimitToken) : 200
    // CPU hover layout. Anything other than "false" (including an unsubstituted token) keeps the default.
    readonly property string barCpuShowClusterBarsToken: "__BAR_CPU_SHOW_CLUSTER_BARS__"
    readonly property bool barCpuShowClusterBars: barCpuShowClusterBarsToken !== "false"
    readonly property string barCpuShowCoresToken: "__BAR_CPU_SHOW_CORES__"
    readonly property bool barCpuShowCores: barCpuShowCoresToken !== "false"
    // Units in the RAM and temperature widget text. Anything other than "false" keeps the unit.
    readonly property string barRamShowUnitToken: "__BAR_RAM_SHOW_UNIT__"
    readonly property bool barRamShowUnit: barRamShowUnitToken !== "false"
    readonly property string barTemperatureShowUnitToken: "__BAR_TEMPERATURE_SHOW_UNIT__"
    readonly property bool barTemperatureShowUnit: barTemperatureShowUnitToken !== "false"
    readonly property string barHeightToken: "__BAR_HEIGHT__"
    readonly property int barHeight: Number(barHeightToken) > 0 ? Number(barHeightToken) : 20
    readonly property string barTemperatureEnableToken: "__BAR_TEMPERATURE_ENABLE__"
    readonly property bool barTemperatureEnabled: barWidgetEnabled("temperature")
    readonly property string barTemperatureTextPath: "__BAR_TEMPERATURE_TEXT_PATH__"
    readonly property string barTemperaturePopupPathsToken: '__BAR_TEMPERATURE_POPUP_PATHS__'
    readonly property var barTemperaturePopupPaths: parseObjectToken(barTemperaturePopupPathsToken)
    readonly property string barTemperatureFanPathsToken: '__BAR_TEMPERATURE_FAN_PATHS__'
    readonly property var barTemperatureFanPaths: parseObjectToken(barTemperatureFanPathsToken)
}
