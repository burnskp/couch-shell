import QtQuick
import QtTest
import "../../services/SystemStatsDisk.js" as Disk
import "../../services/SystemStatsFormatting.js" as Formatting
import "../../services/NotificationLogic.js" as Notifications

TestCase {
    name: "SystemStatsDisk"

    function test_severity_data() {
        const gib = 1073741824;
        return [
            {tag: "warning boundary", bytes: 50 * gib, warning: 50, critical: 10, expected: 0},
            {tag: "below warning", bytes: 50 * gib - 1, warning: 50, critical: 10, expected: 1},
            {tag: "critical boundary", bytes: 10 * gib, warning: 50, critical: 10, expected: 1},
            {tag: "below critical", bytes: 10 * gib - 1, warning: 50, critical: 10, expected: 2},
            {tag: "zero", bytes: 0, warning: 50, critical: 10, expected: 2},
            {tag: "custom warning boundary", bytes: 8 * gib, warning: 8, critical: 2, expected: 0},
            {tag: "custom warning", bytes: 8 * gib - 1, warning: 8, critical: 2, expected: 1},
            {tag: "custom critical boundary", bytes: 2 * gib, warning: 8, critical: 2, expected: 1},
            {tag: "custom critical", bytes: 2 * gib - 1, warning: 8, critical: 2, expected: 2},
            {tag: "unavailable", bytes: null, warning: 50, critical: 10, expected: -1}
        ];
    }

    function test_severity(data) {
        compare(Disk.severity(data.bytes === null ? null : {availableBytes: data.bytes}, data.warning, data.critical), data.expected);
    }

    function test_alert_episodes() {
        let level = 0;
        // Initial warning, duplicates/failure, escalation, partial recovery,
        // full recovery, then a direct critical drop without a warning toast.
        const readings = [1, 1, -1, 1, 2, 2, 1, -1, 2, 0, -1, 2, 1, 2, 0, 1];
        const alerts = [];
        for (let index = 0; index < readings.length; index++) {
            const next = Disk.alertTransition(level, readings[index]);
            level = next.level;
            if (next.notify)
                alerts.push(index);
        }
        compare(alerts, [0, 4, 11, 15]);
    }

    function test_persistent_notification_payloads() {
        const options = {low: "low", normal: "normal", critical: "critical", defaultTimeoutMs: 5000, notificationUrgency: {Low: 0, Normal: 1, Critical: 2}};
        const ids = [];
        for (const level of [1, 2]) {
            const payload = Disk.alertPayload(level, "/test path", "0 B", options.normal, options.critical);
            compare(payload.title, level === 2 ? "Critical disk space" : "Low disk space");
            compare(payload.appName, "Couch Shell");
            compare(payload.body, "/test path · 0 B remaining");
            compare(payload.urgency, level === 2 ? "critical" : "normal");
            compare(payload.timeoutMs, 0);
            compare(Notifications.normalizeNotificationPayload(payload, options).timeoutMs, 0);
            compare(Disk.alertPayload(level, "/test path", "1 GiB", options.normal, options.critical).remoteId, payload.remoteId);
            ids.push(payload.remoteId);
        }
        verify(ids[0] !== ids[1]);
    }

    function test_parse_data() {
        return [
            { tag: "normal", output: "Avail Size\n 128849018880 536870912000\n", code: 0, available: 128849018880, total: 536870912000 },
            { tag: "zero available", output: "Avail Size\n0 100\n", code: 0, available: 0, total: 100 },
            { tag: "large", output: "Avail Size\n10995116277760 21990232555520\n", code: 0, available: 10995116277760, total: 21990232555520 },
            { tag: "failed", output: "Avail Size\n10 100\n", code: 1 },
            { tag: "timeout", output: "", code: 124 },
            { tag: "missing", output: "", code: 1 },
            { tag: "incomplete", output: "Avail Size\n", code: 0 },
            { tag: "malformed", output: "Avail Size\n12x 100\n", code: 0 },
            { tag: "negative", output: "Avail Size\n-1 100\n", code: 0 },
            { tag: "zero total", output: "Avail Size\n0 0\n", code: 0 }
        ];
    }

    function test_parse(data) {
        const result = Disk.parseResult(data.output, data.code);
        if (data.available === undefined) {
            compare(result, null);
            compare(Disk.availableLabel(result, Formatting.formatBytes), "Unk");
        } else {
            compare(result.availableBytes, data.available);
            compare(result.totalBytes, data.total);
        }
    }

    function test_selection_order_duplicates_and_labels() {
        const entries = [{name: "Second 'disk'", path: "/b"}, {name: "First", path: "/a"}, {name: "Again", path: "/b"}, {name: "Missing", path: "/missing"}];
        compare(Disk.queryPaths("/text only", entries), ["/text only", "/b", "/a", "/missing"]);
        const results = {"/text only": {availableBytes: 1024, totalBytes: 2048}, "/a": {availableBytes: 0, totalBytes: 100}, "/b": {availableBytes: 128849018880, totalBytes: 536870912000}};
        compare(Disk.availableLabel(results["/text only"], Formatting.formatBytes), "1.0 KiB");
        const rows = Disk.popupRows(entries, results, Formatting.formatBytes);
        compare(rows.map(row => row.name), ["Second 'disk'", "First", "Again", "Missing"]);
        compare(rows[0].value, "120 GiB / 500 GiB");
        compare(rows[1].value, "0 B / 100 B");
        compare(rows[2].value, rows[0].value);
        compare(rows[3].value, "Unavailable");
        compare(Disk.popupRows([], results, Formatting.formatBytes), []);
        compare(Disk.queryPaths("/a", []), ["/a"]);
        compare(Disk.queryPaths("/a", entries), ["/a", "/b", "/missing"]);
    }

    function test_paths_are_arguments() {
        const path = "/spaces and 'single' \"double\" $(touch nope)";
        const command = Disk.queryCommand(path);
        compare(command[command.length - 1], path);
        compare(command[command.length - 2], "--");
        compare(command[0], "timeout");
        verify(command.indexOf("LC_ALL=C") >= 0);
    }
}
