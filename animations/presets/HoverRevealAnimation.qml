import QtQuick
import ".." as Animations

Item {
    id: root

    default property alias contentData: contentContainer.data
    property Item sourceItem: contentContainer
    property bool open: false
    property int duration: Animations.AnimationPresets.hoverRevealDurationMs
    property int easingType: Animations.AnimationPresets.easeOutCubic
    property real collapsedWidth: width
    readonly property bool usingInternalSource: sourceItem === contentContainer

    readonly property real clampedCollapsedWidth: Math.max(1, Math.min(width, collapsedWidth))
    readonly property real targetProgress: open ? 1 : 0
    readonly property bool running: progressAnimation.running
    readonly property bool shouldShow: open || running || animatedProgress > 0.001
    readonly property string phase: open ? "open" : "close"
    readonly property real progress: animatedProgress

    property real animatedProgress: targetProgress

    implicitWidth: sourceItem ? sourceItem.implicitWidth : contentContainer.implicitWidth
    implicitHeight: sourceItem ? sourceItem.implicitHeight : contentContainer.implicitHeight
    anchors.fill: parent

    Behavior on animatedProgress {
        NumberAnimation {
            id: progressAnimation
            duration: root.duration
            easing.type: root.easingType
        }
    }

    Item {
        id: revealMask

        anchors.top: parent.top
        x: Math.round((root.width - width) / 2)
        width: Math.round(root.clampedCollapsedWidth + ((root.width - root.clampedCollapsedWidth) * root.animatedProgress))
        height: Math.round(root.height * root.animatedProgress)
        clip: true

        Item {
            id: contentContainer

            visible: root.usingInternalSource
            x: -revealMask.x
            y: Math.round(-18 * (1 - root.animatedProgress))
            width: root.width
            height: root.height
        }

        ShaderEffectSource {
            visible: !root.usingInternalSource && root.shouldShow
            live: !root.usingInternalSource && root.shouldShow
            hideSource: !root.usingInternalSource && root.shouldShow
            recursive: true
            sourceItem: root.usingInternalSource ? null : root.sourceItem
            x: -revealMask.x
            y: Math.round(-18 * (1 - root.animatedProgress))
            width: root.width
            height: root.height
        }
    }
}
