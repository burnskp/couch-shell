import QtQuick
import "../theme" as Theme

Text {
    id: root

    property string role: "body"
    property var style: ({})

    readonly property color resolvedColor: {
        switch (root.role) {
        case "muted":
            return root.style.subtleTextColor || root.style.mutedTextColor || Theme.Theme.overlay1;
        case "label":
            return root.style.mutedTextColor || Theme.Theme.subtext0;
        case "accent":
            return root.style.accentColor || Theme.Theme.barAccent;
        case "danger":
            return root.style.dangerColor || Theme.Theme.red;
        case "value":
        case "title":
        case "heading":
        case "body":
        default:
            return root.style.textColor || Theme.Theme.text;
        }
    }

    readonly property int baseFontSize: root.style.fontSize || Theme.Theme.fontSize
    readonly property int resolvedPixelSize: {
        switch (root.role) {
        case "title":
            return root.baseFontSize + 1;
        case "heading":
        case "value":
        case "body":
            return root.baseFontSize;
        case "muted":
        case "label":
        default:
            return root.baseFontSize - 1;
        }
    }

    readonly property int resolvedWeight: {
        switch (root.role) {
        case "title":
        case "heading":
        case "value":
        case "accent":
        case "danger":
            return Font.Bold;
        case "muted":
        case "label":
        case "body":
        default:
            return Theme.Theme.fontWeight;
        }
    }

    color: root.resolvedColor
    font.family: Theme.Theme.fontFamily
    font.pixelSize: root.resolvedPixelSize
    font.weight: root.resolvedWeight
    textFormat: Text.PlainText
}
