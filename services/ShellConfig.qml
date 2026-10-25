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
    readonly property string aiUsageRefreshIntervalToken: "__AI_USAGE_REFRESH_INTERVAL__"
    readonly property int aiUsageRefreshInterval: Number(aiUsageRefreshIntervalToken) > 0 ? Number(aiUsageRefreshIntervalToken) : 300
    readonly property string barHeightToken: "__BAR_HEIGHT__"
    readonly property int barHeight: Number(barHeightToken) > 0 ? Number(barHeightToken) : 20
    readonly property string barTemperatureEnableToken: "__BAR_TEMPERATURE_ENABLE__"
    readonly property bool barTemperatureEnabled: barTemperatureEnableToken === "true"
    readonly property string barTemperatureTextPath: "__BAR_TEMPERATURE_TEXT_PATH__"
    readonly property string barTemperaturePopupPathsToken: '__BAR_TEMPERATURE_POPUP_PATHS__'
    readonly property var barTemperaturePopupPaths: parseObjectToken(barTemperaturePopupPathsToken)
    readonly property string barTemperatureFanPathsToken: '__BAR_TEMPERATURE_FAN_PATHS__'
    readonly property var barTemperatureFanPaths: parseObjectToken(barTemperatureFanPathsToken)
}
