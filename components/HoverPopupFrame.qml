import QtQuick
import QtQuick.Layouts
import "../theme" as Theme
import "../ui" as Ui

Item {
    id: root

    default property alias contentData: contentColumn.data
    property int minPopupWidth: 0
    property int contentSpacing: 8
    property bool shadowEnabled: Theme.Theme.outerShadowEnabled

    implicitWidth: Math.max(minPopupWidth, contentColumn.implicitWidth + (Theme.Theme.modulePadding * 2))
    implicitHeight: contentColumn.implicitHeight + (Theme.Theme.modulePadding * 2)

    Ui.ShellOuterShadow {
        anchors.fill: frame
        shadowEnabled: root.shadowEnabled
    }

    Rectangle {
        id: frame

        anchors.fill: parent
        color: Theme.Theme.popupBackground
        border.width: 1
        border.color: Theme.Theme.popupBorder
        radius: 0
    }

    ColumnLayout {
        id: contentColumn

        anchors.fill: frame
        anchors.margins: Theme.Theme.modulePadding
        spacing: root.contentSpacing
    }
}
