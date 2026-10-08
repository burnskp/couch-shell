pragma Singleton

import QtQuick

QtObject {
    readonly property string hoverReveal: "hoverReveal"
    readonly property string slideIn: "slideIn"
    readonly property string smoke: "smoke"

    function normalizePreset(preset) {
        const value = (preset || "").toString().trim().toLowerCase();

        switch (value) {
        case hoverReveal.toLowerCase():
        case "hover-reveal":
        case "hover_reveal":
            return hoverReveal;
        case slideIn.toLowerCase():
        case "slide-in":
        case "slide_in":
            return slideIn;
        case smoke:
            return smoke;
        default:
            return smoke;
        }
    }
}
