import QtQuick
import QtQuick.Effects
import "../theme" as Theme

RectangularShadow {
    id: root

    property bool shadowEnabled: Theme.Theme.outerShadowEnabled

    color: Theme.Theme.outerShadowColor
    opacity: Theme.Theme.outerShadowOpacity
    blur: Theme.Theme.outerShadowBlur
    spread: Theme.Theme.outerShadowSpread
    radius: 0
    offset: Qt.vector2d(Theme.Theme.outerShadowHorizontalOffset, Theme.Theme.outerShadowVerticalOffset)
    cached: true
    visible: root.shadowEnabled && root.opacity > 0
}
