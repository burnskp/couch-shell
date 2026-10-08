import QtQuick
import QtQuick.Layouts
import "../theme" as Theme

Rectangle {
    id: root

    default property alias contentData: contentColumn.data
    property int contentMargin: 6
    property int extraHeight: 0
    property alias contentSpacing: contentColumn.spacing

    Layout.fillWidth: true
    implicitHeight: contentColumn.implicitHeight + (contentMargin * 2) + extraHeight
    radius: 0
    color: Theme.Theme.popupBackground
    border.width: 1
    border.color: Theme.Theme.popupBorder

    ColumnLayout {
        id: contentColumn

        anchors.fill: parent
        anchors.margins: root.contentMargin
        spacing: 4
    }
}
