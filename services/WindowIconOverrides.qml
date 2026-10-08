pragma Singleton

import QtQml
import "./WindowIconOverridesLogic.js" as WindowIconOverridesLogic

QtObject {
    readonly property var rules: [
        {
            initialClass: "foot",
            glyph: ""
        },
        {
            initialClass: "com.mitchellh.ghostty",
            glyph: ""
        },
        {
            initialClass: "kitty",
            glyph: ""
        },
        {
            initialClass: "helium",
            glyph: ""
        },
        {
            initialClass: "geeqie",
            glyph: ""
        },
        {
            initialClass: "evince",
            glyph: "󰈙"
        },
        {
            initialClass: "mpv",
            glyph: ""
        },
        {
            initialClass: "android-studio",
            glyph: ""
        },
        {
            initialClass: "androidstudio",
            glyph: ""
        },
        {
            initialClass: "electron",
            initialTitleContains: "legcord",
            glyph: ""
        }
    ]

    function glyphFor(toplevel) {
        return WindowIconOverridesLogic.glyphFor(toplevel, rules);
    }
}
