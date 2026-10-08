import QtQuick
import QtTest
import "../../services/NetworkLogic.js" as NetworkLogic

TestCase {
    name: "NetworkLogic"

    function test_wifi_status_uses_radio_flags_when_disconnected() {
        const enabled = NetworkLogic.deriveWifiStatus({
            wifiEnabled: true,
            wifiHardwareEnabled: true,
            hasWifiDevice: true,
            deviceConnected: false,
            hasActiveNetwork: false
        });

        verify(enabled.available);
        verify(enabled.wifiEnabled);
        verify(!enabled.reconnecting);
        verify(!enabled.connected);

        const disabled = NetworkLogic.deriveWifiStatus({
            wifiEnabled: false,
            wifiHardwareEnabled: true,
            hasWifiDevice: true,
            deviceConnected: false,
            hasActiveNetwork: false
        });

        verify(disabled.available);
        verify(!disabled.wifiEnabled);
        verify(!disabled.reconnecting);
        verify(!disabled.connected);
    }

    function test_wifi_status_treats_connected_device_as_enabled() {
        const connected = NetworkLogic.deriveWifiStatus({
            wifiEnabled: false,
            wifiHardwareEnabled: true,
            hasWifiDevice: true,
            deviceConnected: true,
            hasActiveNetwork: true
        });

        verify(connected.available);
        verify(connected.wifiEnabled);
        verify(!connected.reconnecting);
        verify(connected.connected);
    }
}
