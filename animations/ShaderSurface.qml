import QtQuick

Item {
    id: root

    property Item sourceItem: null
    property bool open: false
    property int duration: 750
    property int easingType: Easing.OutCubic
    property url openShader: ""
    property url closeShader: ""
    property real randomSeed: Math.random()
    property real progress: 0
    property real targetProgress: 0
    property bool initialized: false
    property bool snappingProgress: false

    property string phase: "close"
    readonly property real shaderProgress: phase === "open" ? progress : 1.0 - progress
    readonly property bool running: progressAnimation.running
    readonly property bool active: running || (progress > 0.001 && progress < 0.999)
    readonly property bool shouldShow: open || active || progress > 0.001

    function syncOpenState() {
        targetProgress = open ? 1 : 0;
        phase = open ? "open" : "close";

        if (initialized) {
            progress = targetProgress;
            settleTimer.restart();
        }
    }

    function snapToTargetProgress() {
        snappingProgress = true;
        progressAnimation.stop();
        progress = targetProgress;
        snappingProgress = false;
    }

    Component.onCompleted: {
        syncOpenState();
        progress = targetProgress;
        initialized = true;
    }

    onOpenChanged: syncOpenState()

    Behavior on progress {
        enabled: !root.snappingProgress

        NumberAnimation {
            id: progressAnimation
            duration: root.duration
            easing.type: root.easingType
        }
    }

    Timer {
        id: settleTimer

        interval: Math.max(1, root.duration + 100)
        repeat: false
        onTriggered: root.snapToTargetProgress()
    }

    ShaderEffectSource {
        id: shaderSource

        anchors.fill: parent
        visible: false
        live: root.active
        hideSource: root.active
        recursive: true
        sourceItem: root.sourceItem
    }

    ShaderEffect {
        anchors.fill: parent
        visible: root.sourceItem !== null && root.active && root.shouldShow

        property var source: shaderSource
        property real progress: root.shaderProgress
        property real randomSeed: root.randomSeed
        property vector2d sourceSize: Qt.vector2d(Math.max(1, root.width), Math.max(1, root.height))

        fragmentShader: root.phase === "open" ? root.openShader : root.closeShader
    }
}
