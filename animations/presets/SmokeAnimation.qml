import QtQuick
import ".." as Animations

Animations.SurfaceAnimation {
    duration: Animations.AnimationPresets.smokeDurationMs
    easingType: Animations.AnimationPresets.easeOutCubic
    openShader: Qt.resolvedUrl("../shaders/smoke/open.qsb")
    closeShader: Qt.resolvedUrl("../shaders/smoke/close.qsb")
}
