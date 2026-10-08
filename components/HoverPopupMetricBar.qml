import QtQuick
import QtQuick.Layouts
import "../theme" as Theme

Rectangle {
    id: root

    default property alias overlayData: overlayContent.data
    property real value: 0
    property color fillColor: Theme.Theme.popupFill
    property color trackColor: Theme.Theme.popupTrack
    property real fillOpacity: 0.9
    property int barHeight: (Theme.Theme.indicatorThickness + 5) * 2

    Layout.fillWidth: true
    implicitHeight: root.barHeight
    radius: 0
    color: root.trackColor

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: parent.width * Math.max(0, Math.min(1, root.value))
        radius: 0
        color: root.fillColor
        opacity: root.fillOpacity
    }

    Item {
        id: overlayContent

        anchors.fill: parent
    }
}
