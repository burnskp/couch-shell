import QtQuick
import QtTest
import "../../services/AiUsageLogic.js" as Logic

TestCase {
    name: "AiUsageLogic"

    function provider(windows, status) {
        return { windows: windows, status: status || "ready" };
    }
    function quota(remaining, reset) {
        return { remainingPercent: remaining, resetsAt: reset };
    }
    function test_lowest_and_fractional_remaining() {
        compare(Logic.summary(provider([quota(80, null), quota(22, null)]), 0).text, "22%");
        compare(Logic.summary(provider([quota(0.1, null)]), 0).text, "1%");
        compare(Logic.summary(provider([quota(100, null)]), 0).text, "100%");
    }
    function test_exhausted_uses_last_blocking_reset() {
        const value = Logic.summary(provider([quota(0, 3600000), quota(0, 7200000), quota(40, 9000000)]), 0);
        compare(value.text, "2:00");
        verify(value.exhausted);
        compare(Logic.summary(provider([quota(0, null), quota(0, 7200000)]), 0).text, "0%");
    }
    function test_countdown_data() {
        return [
            { tag: "sub-minute", reset: 1, expected: "0:01" },
            { tag: "minute", reset: 60000, expected: "0:01" },
            { tag: "round-up", reset: 60001, expected: "0:02" },
            { tag: "hour", reset: 3600000, expected: "1:00" },
            { tag: "weekly", reset: 604800000, expected: "168:00" },
            { tag: "expired", reset: 900, expected: "0:00", now: 1000 },
            { tag: "missing", reset: null, expected: "Unknown" }
        ];
    }
    function test_countdown(data) { compare(Logic.countdown(data.reset, data.now || 0), data.expected); }
    function test_stale_or_missing_is_not_current() {
        compare(Logic.summary(provider([]), 0).text, "Unk");
        compare(Logic.summary(provider([quota(50, 1000)], "error"), 0).text, "Unk");
        compare(Logic.summary(provider([quota(0, 1000)]), 1000).text, "Unk");
        compare(Logic.summary(provider([quota(80, 1000)]), 1001).text, "Unk");
    }
    function test_next_tick_and_duration_labels() {
        compare(Logic.nextTick([quota(0, 61001)], 0), 1001);
        compare(Logic.nextTick([quota(0, 60000)], 0), 60000);
        compare(Logic.nextTick([quota(0, null)], 0), 60000);
        compare(Logic.windowLabel({ durationSeconds: 18000 }), "5 hours");
        compare(Logic.windowLabel({ durationSeconds: 604800 }), "1 week");
        compare(Logic.windowLabel({ id: "primary_window" }), "Primary limit");
        compare(Logic.windowLabel({ durationSeconds: 604800, label: "Opus week" }), "Opus week");
    }
}
