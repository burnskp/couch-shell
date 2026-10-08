import QtQuick
import QtQuick.Layouts
import "../theme" as Theme

Item {
    id: root

    default property alias contentData: contentColumn.data
    property var style: ({})
    property int minPopupWidth: 0
    property int contentSpacing: root.style.sectionSpacing || 8
    property bool shadowEnabled: Theme.Theme.outerShadowEnabled

    implicitWidth: Math.max(root.minPopupWidth, contentColumn.implicitWidth + ((root.style.windowPadding || Theme.Theme.modulePadding) * 2))
    implicitHeight: contentColumn.implicitHeight + ((root.style.windowPadding || Theme.Theme.modulePadding) * 2) + 2

    ShellOuterShadow {
        anchors.fill: frame
        shadowEnabled: root.shadowEnabled
    }

    Rectangle {
        id: frame

        anchors.fill: parent
        color: root.style.popupBackground || Theme.Theme.popupBackground
        border.width: 1
        border.color: root.style.borderColor || Theme.Theme.popupBorder
        radius: 0
    }

    Rectangle {
        anchors.top: frame.top
        anchors.left: frame.left
        anchors.right: frame.right
        height: 2
        color: root.style.popupTopBarColor || frame.color
        opacity: 0.9
    }

    ColumnLayout {
        id: contentColumn

        anchors.fill: frame
        anchors.margins: root.style.windowPadding || Theme.Theme.modulePadding
        anchors.topMargin: (root.style.windowPadding || Theme.Theme.modulePadding) + 2
        spacing: root.contentSpacing
    }
}
