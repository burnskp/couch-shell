import QtQuick
import QtTest
import "../../services/WindowIconOverridesLogic.js" as WindowIconOverridesLogic

TestCase {
    name: "WindowIconOverridesLogic"

    readonly property var rules: [{
            initialClass: "ghostty",
            glyph: ""
        }, {
            initialClass: "mpv",
            glyph: ""
        }, {
            initialClass: "android-studio",
            glyph: ""
        }, {
            initialClass: "geeqie",
            glyph: ""
        }, {
            initialClass: "electron",
            initialTitleContains: "legcord",
            glyph: ""
        }]

    function test_glyph_for_matches_initial_class() {
        compare(WindowIconOverridesLogic.glyphFor({
            initialClass: "ghostty"
        }, rules), "");
    }

    function test_glyph_for_falls_back_to_runtime_identifiers() {
        compare(WindowIconOverridesLogic.glyphFor({
            class: "mpv"
        }, rules), "");
        compare(WindowIconOverridesLogic.glyphFor({
            wayland: {
                appId: "android-studio"
            }
        }, rules), "");
        compare(WindowIconOverridesLogic.glyphFor({
            lastIpcObject: {
                wm_class: "geeqie"
            }
        }, rules), "");
    }

    function test_glyph_for_checks_title_condition_across_available_titles() {
        compare(WindowIconOverridesLogic.glyphFor({
            class: "electron",
            title: "Legcord"
        }, rules), "");
        compare(WindowIconOverridesLogic.glyphFor({
            class: "electron",
            title: "Electron"
        }, rules), "");
    }
}
