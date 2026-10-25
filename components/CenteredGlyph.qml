import QtQuick
import "../theme" as Theme

// Icon glyph centered on its ink bounds inside its parent. Icon fonts often draw
// outside their advance box, so anchors.centerIn leaves glyphs visibly off-center.
Text {
    id: root

    property real horizontalCenterOffset: 0
    property real verticalCenterOffset: 0

    // Measure at a large size: small-size tight bounds are hinted to whole pixels,
    // which is up to two physical pixels of error on a 2x display.
    readonly property int measureScale: 8
    readonly property real devicePixelRatio: Screen.devicePixelRatio > 0 ? Screen.devicePixelRatio : 1
    readonly property rect inkRect: Qt.rect(metrics.tightBoundingRect.x / measureScale, metrics.tightBoundingRect.y / measureScale, metrics.tightBoundingRect.width / measureScale, metrics.tightBoundingRect.height / measureScale)

    function snapToDevicePixel(value) {
        return Math.round(value * root.devicePixelRatio) / root.devicePixelRatio;
    }

    x: parent ? snapToDevicePixel((parent.width - inkRect.width) / 2 - inkRect.x + horizontalCenterOffset) : 0
    y: parent ? snapToDevicePixel((parent.height - inkRect.height) / 2 - (baselineOffset + inkRect.y) + verticalCenterOffset) : 0
    font.family: Theme.Theme.fontFamily
    font.pixelSize: Theme.Theme.barIconFontSize
    font.weight: Font.Bold

    TextMetrics {
        id: metrics
        font.family: root.font.family
        font.weight: root.font.weight
        font.pixelSize: root.font.pixelSize * root.measureScale
        text: root.text
    }
}
