import QtQuick
import QtQuick.Layouts
import "../theme" as Theme

Rectangle {
    id: root

    property var style: ({})
    property string text: ""
    property string iconText: ""
    property color iconColor: root.textColorForState()
    property string variant: "default"
    property bool checkable: false
    property bool checked: false
    property bool hovered: buttonArea.containsMouse
    property bool pressed: buttonArea.pressed
    property int horizontalPadding: root.style.buttonHorizontalPadding || Theme.Theme.modulePadding
    property real contentLeftPadding: -1
    property int verticalPadding: root.style.buttonVerticalPadding || 0
    signal clicked()

    function backgroundForState() {
        if (root.variant === "danger")
            return root.checked || root.pressed ? Qt.alpha(root.style.dangerColor || Theme.Theme.buttonDangerBackground, 0.92) : (root.hovered ? Qt.alpha(root.style.dangerHoverColor || Theme.Theme.peach, 0.88) : Qt.alpha(root.style.dangerBackground || Theme.Theme.buttonDangerBackground, 0.82));

        if (root.variant === "accent")
            return root.checked || root.pressed ? (root.style.accentActiveBackground || Theme.Theme.buttonAccentBackground) : (root.hovered ? (root.style.accentHoverBackground || Theme.Theme.buttonAccentBackground) : (root.style.accentBackground || Theme.Theme.buttonAccentBackground));

        if (root.variant === "ghost")
            return root.checked || root.pressed ? (root.style.buttonHoverBackground || Theme.Theme.buttonBackgroundHover) : (root.hovered ? (root.style.ghostHoverBackground || Theme.Theme.buttonBackgroundHover) : Theme.Theme.transparent);

        return root.checked || root.pressed ? (root.style.buttonActiveBackground || Theme.Theme.buttonBackgroundActive) : (root.hovered ? (root.style.buttonHoverBackground || Theme.Theme.buttonBackgroundHover) : (root.style.buttonBackground || Theme.Theme.buttonBackground));
    }

    function textColorForState() {
        if (root.variant === "accent" || root.variant === "danger")
            return root.style.textOnAccentColor || Theme.Theme.buttonTextOnAccent;

        if (root.checked && root.variant !== "ghost")
            return root.style.buttonActiveTextColor || root.style.textColor || Theme.Theme.text;

        return root.style.textColor || Theme.Theme.text;
    }

    function borderColorForState() {
        if (root.checked && root.variant !== "ghost")
            return root.style.buttonActiveBorderColor || root.style.borderColor || Theme.Theme.surfaceBorder;

        return root.style.borderColor || Theme.Theme.surfaceBorder;
    }

    implicitHeight: root.style.controlHeight || Theme.Theme.controlHeight
    implicitWidth: buttonContent.implicitWidth + (root.horizontalPadding * 2)
    color: root.backgroundForState()
    radius: 0
    border.width: root.style.buttonBorderWidth !== undefined ? root.style.buttonBorderWidth : (root.variant === "ghost" ? 1 : 0)
    border.color: root.borderColorForState()
    opacity: root.enabled ? 1 : 0.55

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.checked ? (root.style.buttonAccentRailWidth !== undefined ? root.style.buttonAccentRailWidth : (root.style.accentRailWidth || 0)) : 0
        color: root.style.accentColor || Theme.Theme.barAccent
        visible: width > 0
        radius: 0
    }

    RowLayout {
        id: buttonContent

        width: implicitWidth
        height: implicitHeight
        x: root.contentLeftPadding >= 0 ? root.contentLeftPadding : Math.round((parent.width - width) / 2)
        y: Math.round((parent.height - height) / 2)
        spacing: root.iconText.length > 0 ? (root.style.iconSpacing || root.style.controlSpacing || 6) : 0

        ShellText {
            Layout.alignment: Qt.AlignVCenter
            role: "label"
            style: Object.assign({}, root.style, { textColor: root.iconColor, mutedTextColor: root.iconColor })
            text: root.iconText
            visible: root.iconText.length > 0
        }

        ShellText {
            id: buttonLabel

            Layout.alignment: Qt.AlignVCenter
            role: "label"
            style: Object.assign({}, root.style, { textColor: root.textColorForState(), mutedTextColor: root.textColorForState() })
            text: root.text
        }
    }

    MouseArea {
        id: buttonArea

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: {
            if (root.checkable)
                root.checked = !root.checked;

            root.clicked();
        }
    }
}
