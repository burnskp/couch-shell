pragma Singleton

import Quickshell.Io
import Quickshell.Networking
import QtQml
import QtQuick
import "." as Services
import "./NetworkLogic.js" as NetworkLogic

Item {
    id: root

    property bool available: false
    property bool wifiEnabled: false
    property bool reconnecting: false
    property bool connected: false
    property string interfaceName: ""
    property string connectionName: ""
    property string ssid: ""
    property int signalPercent: 0
    property string band: ""
    property string linkSpeed: ""
    property bool isOpenNetwork: false
    property real sessionRxBytes: 0
    property real sessionTxBytes: 0
    property int rxRateBytesPerSecond: 0
    property int txRateBytesPerSecond: 0
    property real lastRxBytes: 0
    property real lastTxBytes: 0
    property real baselineRxBytes: 0
    property real baselineTxBytes: 0
    property double lastSampleTimestamp: 0
    property string activeConnectionKey: ""
    property string telemetryConnectionKey: ""
    property int rateHistoryLength: 24
    property var rxRateHistory: []
    property var txRateHistory: []

    readonly property string accessPointLabel: {
        if (!available)
            return "Unavailable";
        if (!wifiEnabled)
            return "Disabled";
        if (reconnecting)
            return "Reconnecting";
        if (!connected)
            return "Disconnected";
        if (ssid.length > 0)
            return ssid;
        if (connectionName.length > 0)
            return connectionName;
        return "Hidden network";
    }
    readonly property string iconGlyph: NetworkLogic.iconGlyph(available, wifiEnabled, connected, signalPercent)
    readonly property string bandLabel: connected && band.length > 0 ? band : "--"
    readonly property string speedLabel: connected && linkSpeed.length > 0 ? linkSpeed : "--"
    readonly property string strengthLabel: connected ? signalPercent + "%" : "--"
    readonly property string currentConnectionKey: NetworkLogic.connectionKey(connected, interfaceName, ssid, connectionName)

    function toggleWifi() {
        Networking.wifiEnabled = !wifiEnabled;
    }

    function findWifiDevice() {
        const devices = Networking.devices.values || [];

        for (const candidate of devices) {
            if (candidate && candidate.type === DeviceType.Wifi)
                return candidate;
        }

        return null;
    }

    function findActiveNetwork(wifiDevice) {
        if (!wifiDevice)
            return null;

        const networks = wifiDevice.networks.values || [];

        for (const candidate of networks) {
            if (candidate && candidate.connected)
                return candidate;
        }

        return null;
    }

    function syncNetworkingState() {
        const wifiDevice = findWifiDevice();
        const activeNetwork = findActiveNetwork(wifiDevice);

        const derivedStatus = NetworkLogic.deriveWifiStatus({
            wifiEnabled: Networking.wifiEnabled,
            wifiHardwareEnabled: Networking.wifiHardwareEnabled,
            hasWifiDevice: wifiDevice !== null,
            deviceConnected: wifiDevice !== null && wifiDevice.connected,
            hasActiveNetwork: activeNetwork !== null
        });

        available = derivedStatus.available;
        wifiEnabled = derivedStatus.wifiEnabled;
        reconnecting = derivedStatus.reconnecting;
        connected = derivedStatus.connected;
        interfaceName = wifiDevice ? wifiDevice.name : "";
        connectionName = activeNetwork ? activeNetwork.name : "";
        ssid = connectionName;
        signalPercent = activeNetwork ? Math.round(Math.max(0, Math.min(activeNetwork.signalStrength, 1)) * 100) : 0;
        isOpenNetwork = activeNetwork ? activeNetwork.security === WifiSecurityType.Open : false;

        if (wifiDevice)
            wifiDevice.scannerEnabled = Services.BarManager.visible;

        if (!connected) {
            band = "";
            linkSpeed = "";
            resetTraffic();
        }
    }

    function telemetryScript() {
        return ['device="$1"', 'link_speed=""', 'frequency=""', '', 'details=$(nmcli -m multiline -f CAPABILITIES.SPEED device show "$device" 2>/dev/null || true)', 'while IFS= read -r line; do', '  case "$line" in', '    CAPABILITIES.SPEED:*) link_speed=${line#CAPABILITIES.SPEED:} ;;', '  esac', 'done <<EOF', '$details', 'EOF', '', 'scan=$(nmcli -m multiline -f IN-USE,FREQ dev wifi list ifname "$device" --rescan no 2>/dev/null || true)', 'active_entry=no', 'while IFS= read -r line; do', '  case "$line" in', '    IN-USE:*)', '      in_use=${line#IN-USE:}', '      case "$in_use" in', '        *"*"*) active_entry=yes ;;', '        *) active_entry=no ;;', '      esac', '      ;;', '    FREQ:*)', '      if [ "$active_entry" = yes ] && [ -z "$frequency" ]; then', '        frequency=${line#FREQ:}', '      fi', '      ;;', '  esac', 'done <<EOF', '$scan', 'EOF', '', 'rx_bytes=$(cat "/sys/class/net/$device/statistics/rx_bytes" 2>/dev/null || printf 0)', 'tx_bytes=$(cat "/sys/class/net/$device/statistics/tx_bytes" 2>/dev/null || printf 0)', 'printf "linkSpeed=%s\n" "$link_speed"', 'printf "frequency=%s\n" "$frequency"', 'printf "rxBytes=%s\n" "$rx_bytes"', 'printf "txBytes=%s\n" "$tx_bytes"'].join("\n");
    }

    function parseTelemetry(output, connectionKeyValue) {
        const telemetry = NetworkLogic.parseTelemetry(output);

        if (!NetworkLogic.shouldApplyTelemetry(connected, currentConnectionKey, connectionKeyValue))
            return;

        linkSpeed = telemetry.linkSpeed;
        band = telemetry.band;

        updateTraffic(telemetry.rawRxBytes, telemetry.rawTxBytes, connectionKeyValue);
    }

    function updateTraffic(rawRxBytes, rawTxBytes, nextConnectionKey) {
        const nextState = NetworkLogic.updateTraffic({
            activeConnectionKey,
            baselineRxBytes,
            baselineTxBytes,
            lastRxBytes,
            lastTxBytes,
            lastSampleTimestamp,
            sessionRxBytes,
            sessionTxBytes,
            rxRateBytesPerSecond,
            txRateBytesPerSecond
        }, rawRxBytes, rawTxBytes, nextConnectionKey, Date.now());
        activeConnectionKey = nextState.activeConnectionKey;
        baselineRxBytes = nextState.baselineRxBytes;
        baselineTxBytes = nextState.baselineTxBytes;
        lastRxBytes = nextState.lastRxBytes;
        lastTxBytes = nextState.lastTxBytes;
        lastSampleTimestamp = nextState.lastSampleTimestamp;
        sessionRxBytes = nextState.sessionRxBytes;
        sessionTxBytes = nextState.sessionTxBytes;
        rxRateBytesPerSecond = nextState.rxRateBytesPerSecond;
        txRateBytesPerSecond = nextState.txRateBytesPerSecond;
        rxRateHistory = NetworkLogic.appendRateHistory(rxRateHistory, rxRateBytesPerSecond, rateHistoryLength);
        txRateHistory = NetworkLogic.appendRateHistory(txRateHistory, txRateBytesPerSecond, rateHistoryLength);
    }

    function resetTraffic() {
        const nextState = NetworkLogic.resetTraffic();
        activeConnectionKey = nextState.activeConnectionKey;
        baselineRxBytes = nextState.baselineRxBytes;
        baselineTxBytes = nextState.baselineTxBytes;
        lastRxBytes = nextState.lastRxBytes;
        lastTxBytes = nextState.lastTxBytes;
        lastSampleTimestamp = nextState.lastSampleTimestamp;
        sessionRxBytes = nextState.sessionRxBytes;
        sessionTxBytes = nextState.sessionTxBytes;
        rxRateBytesPerSecond = nextState.rxRateBytesPerSecond;
        txRateBytesPerSecond = nextState.txRateBytesPerSecond;
        rxRateHistory = [];
        txRateHistory = [];
    }

    function formatRate(bytesPerSecond) {
        return NetworkLogic.formatRate(bytesPerSecond);
    }

    function formatBytes(bytes) {
        return NetworkLogic.formatBytes(bytes);
    }

    function refreshTelemetry() {
        if (!Services.BarManager.visible)
            return;

        root.syncNetworkingState();

        if (root.connected && root.interfaceName.length > 0 && !telemetryProcess.running)
            telemetryProcess.running = true;
    }

    function syncBarLifecycle() {
        if (Services.BarManager.visible) {
            root.refreshTelemetry();
            return;
        }

        const wifiDevice = root.findWifiDevice();
        if (wifiDevice)
            wifiDevice.scannerEnabled = false;
        if (telemetryProcess.running)
            telemetryProcess.running = false;

        root.band = "";
        root.linkSpeed = "";
        root.resetTraffic();
    }

    Process {
        id: telemetryProcess
        command: ["sh", "-lc", root.telemetryScript(), "sh", root.interfaceName]

        onRunningChanged: {
            if (running)
                root.telemetryConnectionKey = root.currentConnectionKey;
        }

        stdout: StdioCollector {
            onStreamFinished: root.parseTelemetry(this.text, root.telemetryConnectionKey)
        }
    }

    Connections {
        target: Networking
        enabled: Services.BarManager.visible

        function onWifiEnabledChanged() {
            root.syncNetworkingState();
        }

        function onWifiHardwareEnabledChanged() {
            root.syncNetworkingState();
        }
    }

    Connections {
        target: Networking.devices
        enabled: Services.BarManager.visible

        function onObjectInsertedPost() {
            root.syncNetworkingState();
        }

        function onObjectRemovedPost() {
            root.syncNetworkingState();
        }
    }

    Timer {
        interval: 1500
        running: Services.BarManager.visible
        repeat: true
        onTriggered: root.refreshTelemetry()
    }

    Connections {
        target: Services.BarManager

        function onVisibleChanged() {
            root.syncBarLifecycle();
        }
    }

    Component.onCompleted: root.syncBarLifecycle()
}
