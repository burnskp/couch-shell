import QtQuick
import QtTest
import "../../modules/panes/ai/AiStateLogic.js" as AiStateLogic

TestCase {
    name: "AiStateLogic"

    function test_transcript_visibility_follows_active_count() {
        compare(AiStateLogic.transcriptIsVisible(0), false);
        compare(AiStateLogic.transcriptIsVisible(-1), false);
        compare(AiStateLogic.transcriptIsVisible(1), true);
        compare(AiStateLogic.transcriptIsVisible(2), true);
    }

    function test_notification_preview_compacts_and_truncates_text() {
        compare(AiStateLogic.notificationPreview("  hello\n\tworld  "), "hello world");
        compare(AiStateLogic.notificationPreview(""), "The response has finished writing.");

        const longText = "x".repeat(200);
        const preview = AiStateLogic.notificationPreview(longText);
        compare(preview.length, 178);
        compare(preview.slice(-1), "…");
    }

    function test_stream_update_overrides_append_pending_content_and_reasoning() {
        const overrides = AiStateLogic.streamUpdateOverrides({
            content: "Hel",
            reasoning: "Bec"
        }, {
            content: "lo",
            reasoning: "ause"
        });

        compare(overrides.content, "Hello");
        compare(overrides.reasoning, "Because");
        compare(overrides.pending, true);
    }
}
