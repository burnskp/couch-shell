import QtQuick
import QtQuick.Layouts
import "../theme" as Theme

Rectangle {
    id: root

    property var style: ({})
    property string title: ""
    property string iconText: ""
    property color iconColor: root.style.textColor || Theme.Theme.text
    property bool checked: false
    property bool hovered: switchMouseArea.containsMouse
    property bool showBorder: true
    property bool showTopBorder: true
    property bool showRightBorder: true
    property bool showBottomBorder: true
    property bool showLeftBorder: true
    readonly property color resolvedBorderColor: root.style.borderColor || Theme.Theme.surfaceBorder
    signal clicked()

    color: root.hovered ? (root.style.buttonHoverBackground || Theme.Theme.buttonBackgroundHover) : (root.style.surfaceColor || Theme.Theme.surface0)
    radius: 0
    border.width: 0
    implicitHeight: contentRow.implicitHeight + 8
    opacity: root.enabled ? 1 : 0.55

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.right: parent.right
        height: root.showBorder && root.showTopBorder ? 1 : 0
        color: root.resolvedBorderColor
        visible: height > 0
        radius: 0
    }

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: root.showBorder && root.showRightBorder ? 1 : 0
        color: root.resolvedBorderColor
        visible: width > 0
        radius: 0
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: root.showBorder && root.showBottomBorder ? 1 : 0
        color: root.resolvedBorderColor
        visible: height > 0
        radius: 0
    }

    Rectangle {
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.bottom: parent.bottom
        width: root.showBorder && root.showLeftBorder ? 1 : 0
        color: root.resolvedBorderColor
        visible: width > 0
        radius: 0
    }

    RowLayout {
        id: contentRow

        anchors.fill: parent
        anchors.margins: 4
        spacing: root.style.controlSpacing || 8

        ShellText {
            Layout.alignment: Qt.AlignVCenter
            role: "label"
            style: Object.assign({}, root.style, { textColor: root.iconColor, mutedTextColor: root.iconColor })
            text: root.iconText
            visible: root.iconText.length > 0
        }

        ShellText {
            Layout.fillWidth: true
            role: "label"
            style: root.style
            text: root.title
        }

        Rectangle {
            Layout.alignment: Qt.AlignVCenter
            implicitWidth: 34
            implicitHeight: 16
            color: root.checked ? (root.style.accentBackground || Theme.Theme.buttonAccentBackground) : (root.style.buttonHoverBackground || Theme.Theme.buttonBackgroundHover)
            border.width: 0
            radius: 0

            Rectangle {
                width: 12
                height: parent.height - 4
                y: 2
                x: root.checked ? parent.width - width - 2 : 2
                color: root.checked ? (root.style.textOnAccentColor || Theme.Theme.buttonTextOnAccent) : (root.style.textColor || Theme.Theme.text)
                radius: 0

                Behavior on x {
                    NumberAnimation {
                        duration: 120
                    }
                }
            }
        }
    }

    MouseArea {
        id: switchMouseArea

        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: root.enabled
        cursorShape: root.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: root.clicked()
    }
}
