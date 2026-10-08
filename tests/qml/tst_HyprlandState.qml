import QtQuick
import QtTest
import "../../services/HyprlandLogic.js" as HyprlandLogic

TestCase {
    name: "HyprlandState"

    function test_logic_only_exposes_offscreen_title_helper() {
        compare(typeof HyprlandLogic.titleFor, "function");
        compare(typeof HyprlandLogic.iconNameFor, "undefined");
    }

    function test_title_for_prefers_title_then_app_ids() {
        compare(HyprlandLogic.titleFor({
            title: "Terminal",
            wayland: {
                appId: "foot"
            }
        }), "Terminal");
        compare(HyprlandLogic.titleFor({
            title: "",
            wayland: {
                appId: "foot"
            }
        }), "foot");
        compare(HyprlandLogic.titleFor({
            lastIpcObject: {
                class: "Firefox"
            }
        }), "Firefox");
        compare(HyprlandLogic.titleFor(null), "Unknown");
    }
}
