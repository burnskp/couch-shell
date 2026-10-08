import QtQuick
import "." as Animations

Item {
    id: root

    default property alias contentData: contentContainer.data
    property Item sourceItem: contentContainer
    property bool open: false

    // The selector creates separate open/close animation items, so one duration
    // value is enough. These aliases keep compatibility with existing callers.
    property int duration: Animations.AnimationPresets.slideInEnterDurationMs
    property alias enterDuration: root.duration
    property alias exitDuration: root.duration
    property int easingType: Animations.AnimationPresets.easeOutCubic

    // Opening animates from startX to endX. Closing reverses the same path.
    // Positive values move right, negative values move left.
    // By default, start just beyond the item's own width so it reads as off-screen
    // for both narrow toasts and wider panes.
    property real startX: Number.NaN
    property real startMargin: 24
    property real endX: 0

    property bool animatedOpen: false
    readonly property bool usingInternalSource: sourceItem === contentContainer
    readonly property real baseWidth: root.width > 0 ? root.width : root.implicitWidth
    readonly property real effectiveStartX: isNaN(root.startX) ? root.baseWidth + root.startMargin : root.startX

    readonly property bool running: opacityAnimation.running || xAnimation.running
    readonly property bool shouldShow: root.open || root.running
    readonly property string phase: root.open ? "open" : "close"
    readonly property real progress: opacity

    implicitWidth: sourceItem ? sourceItem.implicitWidth : contentContainer.implicitWidth
    implicitHeight: sourceItem ? sourceItem.implicitHeight : contentContainer.implicitHeight

    opacity: root.animatedOpen ? 1 : 0
    x: root.animatedOpen ? root.endX : root.effectiveStartX

    Behavior on opacity {
        NumberAnimation {
            id: opacityAnimation
            duration: root.duration
            easing.type: root.easingType
        }
    }

    Behavior on x {
        NumberAnimation {
            id: xAnimation
            duration: root.duration
            easing.type: root.easingType
        }
    }

    onOpenChanged: root.animatedOpen = root.open
    Component.onCompleted: root.animatedOpen = root.open

    Item {
        id: contentContainer

        visible: root.usingInternalSource
        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
        width: root.width > 0 ? root.width : implicitWidth
        height: root.height > 0 ? root.height : implicitHeight
    }

    ShaderEffectSource {
        anchors.fill: parent
        visible: !root.usingInternalSource && root.shouldShow
        live: !root.usingInternalSource && root.shouldShow
        hideSource: !root.usingInternalSource && root.shouldShow
        recursive: true
        sourceItem: root.usingInternalSource ? null : root.sourceItem
    }
}
