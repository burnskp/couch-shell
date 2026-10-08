import QtQuick
import QtTest
import "../../services/BatteryLogic.js" as BatteryLogic

TestCase {
    name: "BatteryLogic"

    function test_duration_string_formats_hours_and_minutes() {
        compare(BatteryLogic.durationString(0), "");
        compare(BatteryLogic.durationString(90 * 60), "1:30");
    }

    function test_battery_icon_covers_plugged_and_discharging_states() {
        compare(BatteryLogic.batteryIcon(100, false, true), "󱟢");
        compare(BatteryLogic.batteryIcon(80, true, false), "󰂊");
        compare(BatteryLogic.batteryIcon(12, false, false), "󰁺");
        compare(BatteryLogic.batteryIcon(42, false, true), "󱟢");
    }

    function test_battery_label_prefers_time_and_full_state() {
        compare(BatteryLogic.batteryLabel(90 * 60, false, false), "1:30");
        compare(BatteryLogic.batteryLabel(45 * 60, true, true), "0:45");
        compare(BatteryLogic.batteryLabel(0, false, false), "--:--");
        compare(BatteryLogic.batteryLabel(0, false, true), "FULL");
    }

    function test_low_battery_alert_level_requires_ready_discharging_and_threshold() {
        compare(BatteryLogic.lowBatteryAlertLevel(false, true, 4), 0);
        compare(BatteryLogic.lowBatteryAlertLevel(true, false, 4), 0);
        compare(BatteryLogic.lowBatteryAlertLevel(true, true, 11), 0);
        compare(BatteryLogic.lowBatteryAlertLevel(true, true, 10), 1);
        compare(BatteryLogic.lowBatteryAlertLevel(true, true, 5), 2);
    }

    function test_low_battery_alert_only_records_escalations() {
        verify(BatteryLogic.shouldRecordLowBatteryAlert(0, 1));
        verify(BatteryLogic.shouldRecordLowBatteryAlert(1, 2));
        verify(!BatteryLogic.shouldRecordLowBatteryAlert(1, 1));
        verify(!BatteryLogic.shouldRecordLowBatteryAlert(2, 1));
        verify(!BatteryLogic.shouldRecordLowBatteryAlert(0, 0));
    }

    function test_low_battery_alert_payload_uses_expected_notification_fields() {
        const lowPayload = BatteryLogic.lowBatteryAlertPayload(1, 9, "0:42", "normal", "critical", 5000);
        compare(lowPayload.remoteId, "couch-shell-battery-low");
        compare(lowPayload.title, "Low battery");
        compare(lowPayload.body, "9% remaining · 0:42 left");
        compare(lowPayload.appName, "Couch Shell");
        compare(lowPayload.urgency, "normal");
        compare(lowPayload.timeoutMs, 5000);

        const criticalPayload = BatteryLogic.lowBatteryAlertPayload(2, 5, "--:--", "normal", "critical", 5000);
        compare(criticalPayload.remoteId, "couch-shell-battery-critical");
        compare(criticalPayload.title, "Critical battery");
        compare(criticalPayload.body, "5% remaining");
        compare(criticalPayload.urgency, "critical");
        compare(criticalPayload.timeoutMs, 0);
    }
}
