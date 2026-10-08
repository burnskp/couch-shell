import QtQuick
import "../theme" as Theme

Rectangle {
    id: root

    default property alias contentData: contentItem.data
    property alias contentItem: contentItem
    property var style: ({})
    property string tone: "normal"
    property int padding: root.style.sectionPadding || 6
    property bool showBorder: true
    property bool showTopBorder: true
    property bool showRightBorder: true
    property bool showBottomBorder: true
    property bool showLeftBorder: true
    property bool showAccentRail: true
    property bool emphasize: false
    readonly property color resolvedBorderColor: root.emphasize ? (root.style.strongBorderColor || Theme.Theme.surfaceBorderStrong) : (root.style.borderColor || Theme.Theme.surfaceBorder)

    color: {
        switch (root.tone) {
        case "subtle":
            return root.style.subtleSurfaceColor || Theme.Theme.barSurface;
        case "input":
            return root.style.inputBackground || Theme.Theme.inputBackground;
        case "accent":
            return root.style.accentSurfaceColor || Theme.Theme.surface0;
        case "normal":
        default:
            return root.style.surfaceColor || Theme.Theme.surface0;
        }
    }
    radius: 0
    border.width: 0

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.showBorder && root.showTopBorder ? 1 : 0
        color: root.resolvedBorderColor
        visible: height > 0
        radius: 0
    }

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: root.showBorder && root.showRightBorder ? 1 : 0
        color: root.resolvedBorderColor
        visible: width > 0
        radius: 0
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.showBorder && root.showBottomBorder ? 1 : 0
        color: root.resolvedBorderColor
        visible: height > 0
        radius: 0
    }

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: root.showBorder && root.showLeftBorder ? 1 : 0
        color: root.resolvedBorderColor
        visible: width > 0
        radius: 0
    }

    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.left: parent.left
        width: root.emphasize && root.showAccentRail ? (root.style.accentRailWidth || 0) : 0
        color: root.style.accentColor || Theme.Theme.barAccent
        visible: width > 0
        radius: 0
    }

    Item {
        id: contentItem

        anchors.fill: parent
        anchors.margins: root.padding
    }
}
