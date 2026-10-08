import QtQuick
import QtTest
import "../../services/NotificationLogic.js" as NotificationLogic

TestCase {
    name: "NotificationManager"
    readonly property var urgencyOptions: ({
        low: "low",
        normal: "normal",
        critical: "critical",
        defaultTimeoutMs: 5000,
        historyOpen: false,
        notificationUrgency: {
            Low: 0,
            Normal: 1,
            Critical: 2
        }
    })

    function test_normalize_notification_payload_applies_expected_fallbacks() {
        const payload = NotificationLogic.normalizeNotificationPayload({
            summary: "Summary",
            desktopEntry: "org.example.App",
            timeoutMs: 1234,
            timestampMs: -10,
            skipToast: 1
        }, {
            low: urgencyOptions.low,
            normal: urgencyOptions.normal,
            critical: urgencyOptions.critical,
            defaultTimeoutMs: urgencyOptions.defaultTimeoutMs,
            historyOpen: true,
            notificationUrgency: urgencyOptions.notificationUrgency
        });

        compare(payload.title, "Summary");
        compare(payload.appName, "org.example.App");
        compare(payload.timeoutMs, 1234);
        compare(payload.timestampMs, 0);
        compare(payload.read, true);
        compare(payload.skipToast, true);
    }

    function test_normalize_notification_payload_defaults_title() {
        const payload = NotificationLogic.normalizeNotificationPayload({}, urgencyOptions);

        compare(payload.title, "Notification");
        compare(payload.body, "");
        compare(payload.appName, "");
        compare(payload.read, false);
    }

    function test_normalize_urgency_accepts_enums_and_strings() {
        compare(NotificationLogic.normalizeUrgency(urgencyOptions.notificationUrgency.Low, urgencyOptions), "low");
        compare(NotificationLogic.normalizeUrgency(urgencyOptions.notificationUrgency.Normal, urgencyOptions), "normal");
        compare(NotificationLogic.normalizeUrgency(urgencyOptions.notificationUrgency.Critical, urgencyOptions), "critical");
        compare(NotificationLogic.normalizeUrgency("low", urgencyOptions), "low");
        compare(NotificationLogic.normalizeUrgency("critical", urgencyOptions), "critical");
        compare(NotificationLogic.normalizeUrgency("unknown", urgencyOptions), "normal");
    }

    function test_resolve_timeout_ms_defaults_and_handles_critical() {
        compare(NotificationLogic.resolveTimeoutMs(2500, "normal", urgencyOptions), 2500);
        compare(NotificationLogic.resolveTimeoutMs(undefined, "normal", urgencyOptions), urgencyOptions.defaultTimeoutMs);
        compare(NotificationLogic.resolveTimeoutMs(-5, "normal", urgencyOptions), 0);
        compare(NotificationLogic.resolveTimeoutMs(2500, "critical", urgencyOptions), 0);
    }

    function test_notification_timeout_from_server_preserves_ms_and_defaults() {
        compare(NotificationLogic.notificationTimeoutFromServer(2500, urgencyOptions.defaultTimeoutMs), 2500);
        compare(NotificationLogic.notificationTimeoutFromServer(0, urgencyOptions.defaultTimeoutMs), 0);
        compare(NotificationLogic.notificationTimeoutFromServer(-1, urgencyOptions.defaultTimeoutMs), urgencyOptions.defaultTimeoutMs);
    }

    function test_recompute_counts_tracks_unread_and_status_entries() {
        const counts = NotificationLogic.recomputeCounts([
            {read: false, urgency: "low"},
            {read: false, urgency: "normal"},
            {read: true, urgency: "critical"}
        ], urgencyOptions.low);

        compare(counts.unreadCount, 2);
        compare(counts.statusNotificationCount, 2);
    }
}
