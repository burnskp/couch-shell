import QtQuick
import QtQuick.Layouts
import "../theme" as Theme

Rectangle {
    id: root

    default property alias contentData: valueRow.data
    property Component hoverPopup: null
    property real hoverPopupWidth: 220
    property real hoverPopupOffsetY: 0
    property int hoverPopupCollapsedWidth: Math.max(width, Theme.Theme.moduleLeadingWidth * 2)
    property int hoverPopupAnimationDuration: -1
    property int hoverPopupOpenAnimationDuration: hoverPopupAnimationDuration
    property int hoverPopupCloseAnimationDuration: hoverPopupAnimationDuration
    property string hoverPopupOpenAnimationStyle: "smoke"
    property string hoverPopupCloseAnimationStyle: "smoke"
    property bool hoverPopupEnabled: hoverPopup !== null
    property string hoverPopupKey: ""
    property string leadingText: ""
    property color leadingBackground: Theme.Theme.barMuted
    property color activeLeadingBackground: Theme.Theme.barAccent
    property color hoverLeadingBackground: activeLeadingBackground
    property color leadingTextColor: Theme.Theme.barBackground
    property color activeLeadingTextColor: Theme.Theme.barBackground
    property color valueBackground: Theme.Theme.barSurface
    property color activeValueBackground: Theme.Theme.barActiveSurface
    property color hoverValueBackground: Theme.Theme.barSurface
    property int paddingY: 0
    property int leadingWidth: Theme.Theme.moduleLeadingWidth
    property real leadingHorizontalCenterOffset: 0
    property real leadingVerticalCenterOffset: 0
    property bool clickable: false
    property bool hoverable: false
    property bool active: false
    property int acceptedButtons: root.clickable ? (Qt.LeftButton | Qt.RightButton | Qt.MiddleButton) : Qt.NoButton
    readonly property bool hovered: mouseArea.containsMouse
    readonly property bool hasLeadingSegment: leadingText.length > 0
    readonly property bool hasValueSegment: valueRow.implicitWidth > 0
    readonly property int valuePadding: Theme.Theme.moduleValuePadding
    readonly property int valueRightPadding: Theme.Theme.moduleValueRightPadding
    signal clicked(int button)

    color: Theme.Theme.transparent
    radius: 0
    implicitHeight: Theme.Theme.moduleHeight
    implicitWidth: (hasLeadingSegment ? leadingBlock.implicitWidth : 0) + (hasValueSegment ? valueBlock.implicitWidth : 0)

    RowLayout {
        anchors.fill: parent
        spacing: 0

        Rectangle {
            id: leadingBlock

            visible: root.hasLeadingSegment
            Layout.preferredWidth: implicitWidth
            Layout.fillHeight: true
            implicitWidth: root.leadingWidth
            implicitHeight: root.implicitHeight
            color: root.active ? root.activeLeadingBackground : root.hovered ? root.hoverLeadingBackground : root.leadingBackground
            radius: 0

            CenteredGlyph {
                horizontalCenterOffset: root.leadingHorizontalCenterOffset
                verticalCenterOffset: root.leadingVerticalCenterOffset
                text: root.leadingText
                color: root.active ? root.activeLeadingTextColor : root.leadingTextColor
            }
        }

        Rectangle {
            id: valueBlock

            visible: root.hasValueSegment
            Layout.preferredWidth: implicitWidth
            Layout.fillHeight: true
            implicitWidth: root.hasValueSegment ? valueRow.implicitWidth + root.valuePadding + root.valueRightPadding : 0
            implicitHeight: root.implicitHeight
            color: root.active ? root.activeValueBackground : root.hovered ? root.hoverValueBackground : root.valueBackground
            radius: 0

            RowLayout {
                id: valueRow
                anchors.fill: parent
                anchors.leftMargin: root.valuePadding
                anchors.rightMargin: root.valueRightPadding
                anchors.topMargin: root.paddingY
                anchors.bottomMargin: root.paddingY
                spacing: Theme.Theme.listGap
            }
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        enabled: root.clickable || root.hoverable
        acceptedButtons: root.acceptedButtons
        hoverEnabled: root.clickable || root.hoverable
        cursorShape: root.clickable ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: mouse => root.clicked(mouse.button)
    }
}
