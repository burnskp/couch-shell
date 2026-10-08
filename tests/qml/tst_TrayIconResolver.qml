import QtQuick
import QtTest
import "../../services/TrayIconResolverLogic.js" as TrayIconResolverLogic

TestCase {
    name: "TrayIconResolver"
    readonly property string defaultIconSource: "image://icon/application-default-icon"

    function test_normalized_source_handles_direct_and_path_sources() {
        compare(TrayIconResolverLogic.normalizedSource(""), "");
        compare(TrayIconResolverLogic.normalizedSource("/tmp/icon.png"), "file:///tmp/icon.png");
        compare(TrayIconResolverLogic.normalizedSource("file:///tmp/icon.png"), "file:///tmp/icon.png");
        compare(TrayIconResolverLogic.normalizedSource("image://icon/app"), "image://icon/app");
        compare(TrayIconResolverLogic.normalizedSource("qrc:/icons/app.svg"), "qrc:/icons/app.svg");
        compare(TrayIconResolverLogic.normalizedSource("icon.png?path=/tmp/icons/"), "file:///tmp/icons/icon.png");
    }

    function test_source_candidates_include_fallback_last() {
        const candidates = TrayIconResolverLogic.sourceCandidates("/tmp/icon.png", "", defaultIconSource);

        compare(candidates[0], "file:///tmp/icon.png");
        compare(candidates[candidates.length - 1], defaultIconSource);
    }

    function test_source_candidates_skip_unresolved_plain_theme_names() {
        const candidates = TrayIconResolverLogic.sourceCandidates("missing-theme-icon", "", defaultIconSource);

        compare(candidates.length, 1);
        compare(candidates[0], defaultIconSource);
    }

    function test_source_candidates_prefer_resolved_theme_icon() {
        const candidates = TrayIconResolverLogic.sourceCandidates("theme-icon", "image://icon/theme-icon", defaultIconSource);

        compare(candidates.length, 2);
        compare(candidates[0], "image://icon/theme-icon");
        compare(candidates[1], defaultIconSource);
    }

    function test_notification_icon_candidates_include_generic_fallback_last_for_empty_input() {
        const candidates = TrayIconResolverLogic.notificationIconCandidates([], [], defaultIconSource);

        compare(candidates.length, 1);
        compare(candidates[0], defaultIconSource);
    }

    function test_notification_icon_candidates_merge_in_expected_order() {
        const candidates = TrayIconResolverLogic.notificationIconCandidates([
            "app-a",
            defaultIconSource
        ], [
            "desktop-a",
            defaultIconSource
        ], defaultIconSource);

        compare(candidates.length, 3);
        compare(candidates[0], "app-a");
        compare(candidates[1], "desktop-a");
        compare(candidates[2], defaultIconSource);
    }
}
