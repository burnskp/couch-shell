import QtQuick
import "../theme" as Theme

Item {
    id: root

    default property alias contentData: frame.contentData
    property alias contentItem: frame.contentItem
    property alias padding: frame.padding
    property alias showBorder: frame.showBorder
    property alias showTopBorder: frame.showTopBorder
    property alias showRightBorder: frame.showRightBorder
    property alias showBottomBorder: frame.showBottomBorder
    property alias showLeftBorder: frame.showLeftBorder
    property alias showAccentRail: frame.showAccentRail
    property alias emphasize: frame.emphasize
    property var style: ({})
    property real overlayOpacity: root.style.overlayOpacity !== undefined ? root.style.overlayOpacity : 0.26
    property bool shadowEnabled: Theme.Theme.outerShadowEnabled

    ShellOuterShadow {
        anchors.fill: frame
        shadowEnabled: root.shadowEnabled
    }

    ShellSurface {
        id: frame

        anchors.fill: parent
        style: root.style
        tone: "subtle"
        padding: root.style.windowPadding || 10
        emphasize: true

        Rectangle {
            anchors.fill: parent
            color: root.style.overlayColor || root.style.subtleSurfaceColor || frame.color
            opacity: root.overlayOpacity
            radius: 0
        }
    }
}
