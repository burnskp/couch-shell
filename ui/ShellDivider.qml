import QtQuick
import QtQuick.Layouts
import "../theme" as Theme

Rectangle {
    id: root

    property var style: ({})

    Layout.fillWidth: true
    implicitHeight: 1
    color: root.style.dividerColor || Theme.Theme.surface1
}
