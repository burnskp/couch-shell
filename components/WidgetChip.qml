import QtQuick
import QtQuick.Layouts
import "." as Components
import "../theme" as Theme

ModuleChip {
    id: root

    property string appearancePreset: Theme.WidgetStyles.metric
    property string tone: Theme.WidgetStyles.toneNormal
    property string popupPreset: Components.HoverPopupPresets.defaultPreset
    property string iconGlyph: ""
    property Component popupContent: null
    property Component valueContent: null
    property string valueText: ""
    property color valueTextColor: Theme.Theme.text
    property int valueTextWeight: Font.Bold
    property real preferredValueWidth: -1
    property real maximumValueWidth: -1
    property int valueHorizontalAlignment: Text.AlignLeft
    property int valueElideMode: Text.ElideNone
    property bool interactive: false
    property bool extraHoverable: false
    property string popupKey: ""
    property real popupWidth: -1
    property bool popupOffsetYSet: false
    property real popupOffsetY: 0
    property bool popupCollapsedWidthSet: false
    property real popupCollapsedWidth: 0
    property int popupDuration: -1
    property int popupOpenDuration: -1
    property int popupCloseDuration: -1
    property string popupOpenAnimation: ""
    property string popupCloseAnimation: ""
    property int iconWidth: -1
    property bool iconHorizontalOffsetSet: false
    property real iconHorizontalOffset: 0
    property bool iconVerticalOffsetSet: false
    property real iconVerticalOffset: 0

    readonly property var resolvedChipPreset: Theme.WidgetStyles.chipPreset(root.appearancePreset, root.tone)
    readonly property var resolvedPopupPreset: Components.HoverPopupPresets.preset(root.popupPreset)
    readonly property int resolvedPopupOpenDuration: root.popupOpenDuration >= 0 ? root.popupOpenDuration : (root.resolvedPopupPreset.openDuration >= 0 ? root.resolvedPopupPreset.openDuration : root.resolvedPopupPreset.duration)
    readonly property int resolvedPopupCloseDuration: root.popupCloseDuration >= 0 ? root.popupCloseDuration : (root.resolvedPopupPreset.closeDuration >= 0 ? root.resolvedPopupPreset.closeDuration : root.resolvedPopupPreset.duration)

    leadingText: root.iconGlyph
    leadingBackground: root.resolvedChipPreset.leadingBackground
    activeLeadingBackground: root.resolvedChipPreset.activeLeadingBackground
    hoverLeadingBackground: root.resolvedChipPreset.hoverLeadingBackground
    leadingTextColor: root.resolvedChipPreset.leadingTextColor
    activeLeadingTextColor: root.resolvedChipPreset.activeLeadingTextColor
    valueBackground: root.resolvedChipPreset.valueBackground
    activeValueBackground: root.resolvedChipPreset.activeValueBackground
    hoverValueBackground: root.resolvedChipPreset.hoverValueBackground
    paddingY: root.resolvedChipPreset.paddingY
    leadingWidth: root.iconWidth >= 0 ? root.iconWidth : root.resolvedChipPreset.leadingWidth
    leadingHorizontalCenterOffset: root.iconHorizontalOffsetSet ? root.iconHorizontalOffset : root.resolvedChipPreset.leadingHorizontalCenterOffset
    leadingVerticalCenterOffset: root.iconVerticalOffsetSet ? root.iconVerticalOffset : root.resolvedChipPreset.leadingVerticalCenterOffset
    clickable: root.interactive
    hoverable: root.interactive || root.extraHoverable || root.popupContent !== null
    hoverPopup: root.popupContent
    hoverPopupWidth: root.popupWidth >= 0 ? root.popupWidth : 220
    hoverPopupOffsetY: root.popupOffsetYSet ? root.popupOffsetY : root.resolvedPopupPreset.offsetY
    hoverPopupCollapsedWidth: root.popupCollapsedWidthSet ? root.popupCollapsedWidth : Math.max(root.width, root.resolvedPopupPreset.collapsedWidth)
    hoverPopupAnimationDuration: root.popupDuration
    hoverPopupOpenAnimationDuration: root.resolvedPopupOpenDuration
    hoverPopupCloseAnimationDuration: root.resolvedPopupCloseDuration
    hoverPopupOpenAnimationStyle: root.popupOpenAnimation.length > 0 ? root.popupOpenAnimation : root.resolvedPopupPreset.openAnimation
    hoverPopupCloseAnimationStyle: root.popupCloseAnimation.length > 0 ? root.popupCloseAnimation : root.resolvedPopupPreset.closeAnimation
    hoverPopupKey: root.popupKey.length > 0 ? root.popupKey : root.resolvedPopupPreset.key

    Loader {
        active: root.valueContent !== null
        sourceComponent: root.valueContent
    }

    Text {
        visible: root.valueContent === null && root.valueText.length > 0
        readonly property real constrainedWidth: root.preferredValueWidth >= 0 ? root.preferredValueWidth : root.maximumValueWidth >= 0 ? Math.min(implicitWidth, root.maximumValueWidth) : implicitWidth

        Layout.preferredWidth: constrainedWidth
        width: constrainedWidth
        horizontalAlignment: root.valueHorizontalAlignment
        elide: root.valueElideMode
        text: root.valueText
        font.family: Theme.Theme.fontFamily
        font.pixelSize: Theme.Theme.fontSize
        font.weight: root.valueTextWeight
        color: root.valueTextColor
    }
}
