import QtQuick
import "." as Animations

Item {
    id: root

    default property alias contentData: contentContainer.data
    property Item sourceItem: contentContainer
    property bool open: false
    property int duration: 750
    property int easingType: Easing.OutCubic
    property url openShader: ""
    property url closeShader: ""
    property real randomSeed: Math.random()

    readonly property alias running: shader.running
    readonly property alias shouldShow: shader.shouldShow
    readonly property alias phase: shader.phase
    readonly property alias progress: shader.progress

    function syncShaderOpen() {
        shader.open = root.open;
    }

    implicitWidth: sourceItem ? sourceItem.implicitWidth : contentContainer.implicitWidth
    implicitHeight: sourceItem ? sourceItem.implicitHeight : contentContainer.implicitHeight

    Item {
        id: contentContainer

        implicitWidth: childrenRect.width
        implicitHeight: childrenRect.height
        width: root.width > 0 ? root.width : implicitWidth
        height: root.height > 0 ? root.height : implicitHeight
    }

    Animations.ShaderSurface {
        id: shader

        anchors.fill: parent
        sourceItem: root.sourceItem
        open: false
        duration: root.duration
        easingType: root.easingType
        openShader: root.openShader
        closeShader: root.closeShader
        randomSeed: root.randomSeed
    }

    onOpenChanged: syncShaderOpen()
    Component.onCompleted: syncShaderOpen()
}
