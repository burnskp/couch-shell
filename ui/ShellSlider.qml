import QtQuick
import QtQuick.Layouts
import "../theme" as Theme

Item {
    id: root

    property var style: ({})
    property real value: 0
    property bool active: true
    signal moved(real value)

    implicitWidth: 220
    implicitHeight: 14

    function normalizedValue() {
        return Math.max(0, Math.min(1, root.value));
    }

    function setFromMouse(mouseX) {
        const nextValue = Math.max(0, Math.min(1, mouseX / Math.max(1, track.width)));
        root.moved(nextValue);
    }

    Rectangle {
        id: track

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        implicitHeight: 8
        color: root.style.metricTrackColor || Theme.Theme.barBackground
        border.width: 1
        border.color: root.style.borderColor || Theme.Theme.surfaceBorder
        radius: 0
        opacity: root.enabled ? 1 : 0.55

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: Math.round(parent.width * root.normalizedValue())
            color: root.active ? (root.style.accentColor || Theme.Theme.barAccent) : (root.style.mutedTextColor || Theme.Theme.barMuted || Theme.Theme.subtext0)
            opacity: root.active ? 0.92 : 0.65
            radius: 0
        }

        Rectangle {
            width: 10
            height: parent.height + 4
            y: -2
            x: Math.round((parent.width - width) * root.normalizedValue())
            color: root.active ? (root.style.textOnAccentColor || Theme.Theme.buttonTextOnAccent) : (root.style.surfaceColor || Theme.Theme.surface0)
            border.width: 1
            border.color: root.active ? (root.style.focusBorder || Theme.Theme.focusBorder) : (root.style.borderColor || Theme.Theme.surfaceBorder)
            radius: 0
        }

        MouseArea {
            anchors.fill: parent
            enabled: root.enabled
            hoverEnabled: root.enabled
            cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
            onPressed: mouse => root.setFromMouse(mouse.x)
            onPositionChanged: mouse => {
                if (pressed)
                    root.setFromMouse(mouse.x);
            }
        }
    }
}
