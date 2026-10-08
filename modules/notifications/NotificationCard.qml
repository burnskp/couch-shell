pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../components" as Components
import "../../services" as Services
import "../../theme" as Theme
import "../../ui" as Ui

Rectangle {
    id: root

    required property string title
    required property string body
    required property string appName
    required property string appIcon
    required property string desktopEntry
    required property string image
    required property string urgency

    property string appLabel: root.appName
    property string trailingText: ""
    property string footerTrailingText: ""
    property bool highlighted: false
    property bool showRightBorder: true
    property int accentWidth: 10
    property int horizontalPadding: 12
    property int leadingPadding: 28
    property int verticalPadding: 8
    property int appIconSize: 16
    property int imagePreviewSize: 56
    property int imageMaxHeight: 132
    property string fontFamily: Theme.Theme.fontFamily
    property int fontSize: Theme.Theme.fontSize
    property int bodyMaximumLineCount: root.imagePlacement === "side" && root.hasImage ? 3 : 4
    property string imagePlacement: "side"
    property real bottomBarProgress: 1
    readonly property var shellStyle: Object.assign({}, Ui.ShellStyle.segmented, { fontSize: root.fontSize })
    readonly property bool hasImage: root.image.length > 0 && activeImageSource.length > 0
    readonly property string activeImageSource: root.image.length > 0 ? Services.TrayIconResolver.normalizedSource(root.image) || root.image : ""
    readonly property color accentColor: {
        switch (root.urgency) {
        case "low":
            return Theme.Theme.teal;
        case "critical":
            return Theme.Theme.red;
        case "normal":
        default:
            return Theme.Theme.mauve;
        }
    }

    implicitHeight: contentItem.implicitHeight + (root.verticalPadding * 2)
    color: Theme.Theme.barBackground
    radius: 0
    border.width: 0

    Rectangle {
        anchors.fill: parent
        color: root.highlighted ? Theme.Theme.barActiveSurface : Theme.Theme.barSurface
        opacity: 0.42
        radius: 0
    }

    Rectangle {
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        width: root.accentWidth
        color: root.accentColor
        radius: 0
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 2
        color: Theme.Theme.barActiveSurface
        radius: 0

        Rectangle {
            anchors.left: parent.left
            anchors.top: parent.top
            anchors.bottom: parent.bottom
            width: parent.width * Math.max(0, Math.min(1, root.bottomBarProgress))
            color: root.accentColor
            radius: 0
        }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        height: 1
        color: root.accentColor
        radius: 0
    }

    Rectangle {
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        width: root.showRightBorder ? 1 : 0
        color: root.accentColor
        visible: width > 0
        radius: 0
    }

    Item {
        id: contentItem

        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.leftMargin: root.leadingPadding
        anchors.rightMargin: root.horizontalPadding
        anchors.topMargin: root.verticalPadding
        implicitHeight: root.imagePlacement === "below" ? stackedContent.implicitHeight : sideContent.implicitHeight

        ColumnLayout {
            id: stackedContent

            visible: root.imagePlacement === "below"
            width: parent.width
            spacing: 2

            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.Theme.listGap

                Components.NotificationAppIcon {
                    Layout.alignment: Qt.AlignVCenter
                    Layout.preferredWidth: root.appIconSize
                    Layout.preferredHeight: root.appIconSize
                    appIcon: root.appIcon
                    desktopEntry: root.desktopEntry
                    appName: root.appName
                    size: root.appIconSize
                }

                Ui.ShellText {
                    Layout.fillWidth: true
                    visible: root.appLabel.length > 0
                    font.family: root.fontFamily
                    role: "label"
                    style: Object.assign({}, root.shellStyle, { mutedTextColor: Theme.Theme.subtext1 })
                    text: root.appLabel
                    elide: Text.ElideRight
                    font.weight: Font.Bold
                    font.pixelSize: root.fontSize - 2
                }

                Text {
                    visible: root.trailingText.length > 0
                    text: root.trailingText
                    font.family: root.fontFamily
                    font.pixelSize: root.fontSize - 2
                    font.weight: Theme.Theme.fontWeight
                    color: Theme.Theme.subtext0
                }
            }

            Ui.ShellText {
                Layout.fillWidth: true
                role: "heading"
                font.family: root.fontFamily
                style: root.shellStyle
                text: root.title
                elide: Text.ElideRight
            }

            Ui.ShellText {
                Layout.fillWidth: true
                visible: root.body.length > 0
                font.family: root.fontFamily
                role: "muted"
                style: root.shellStyle
                text: root.body
                wrapMode: Text.Wrap
                maximumLineCount: root.bodyMaximumLineCount
                elide: Text.ElideRight
            }

            Image {
                Layout.fillWidth: true
                Layout.maximumHeight: root.imageMaxHeight
                Layout.preferredHeight: visible && implicitWidth > 0 ? Math.min(root.imageMaxHeight, (width / implicitWidth) * implicitHeight) : 0
                source: root.activeImageSource
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
                visible: root.hasImage
            }

            Ui.ShellText {
                Layout.fillWidth: true
                visible: root.footerTrailingText.length > 0
                horizontalAlignment: Text.AlignRight
                role: "label"
                font.family: root.fontFamily
                style: Object.assign({}, root.shellStyle, { mutedTextColor: Theme.Theme.subtext1 })
                text: root.footerTrailingText
                font.weight: Font.Bold
                font.pixelSize: root.fontSize - 2
            }
        }

        RowLayout {
            id: sideContent

            visible: root.imagePlacement === "side"
            width: parent.width
            spacing: 8

            Image {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: root.imagePreviewSize
                Layout.preferredHeight: root.imagePreviewSize
                source: root.activeImageSource
                fillMode: Image.PreserveAspectFit
                asynchronous: true
                cache: false
                visible: root.hasImage
            }

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 2

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 6

                    Components.NotificationAppIcon {
                        Layout.alignment: Qt.AlignVCenter
                        Layout.preferredWidth: root.appIconSize
                        Layout.preferredHeight: root.appIconSize
                        appIcon: root.appIcon
                        desktopEntry: root.desktopEntry
                        appName: root.appName
                        size: root.appIconSize
                    }

                    Ui.ShellText {
                        Layout.fillWidth: true
                        visible: root.appLabel.length > 0
                        font.family: root.fontFamily
                        role: "label"
                        style: Object.assign({}, root.shellStyle, { mutedTextColor: Theme.Theme.subtext1 })
                        text: root.appLabel
                        elide: Text.ElideRight
                        font.weight: Font.Bold
                        font.pixelSize: root.fontSize - 2
                    }

                    Text {
                        visible: root.trailingText.length > 0
                        text: root.trailingText
                        font.family: root.fontFamily
                        font.pixelSize: root.fontSize - 2
                        font.weight: Theme.Theme.fontWeight
                        color: Theme.Theme.subtext0
                    }
                }

                Ui.ShellText {
                    Layout.fillWidth: true
                    role: "heading"
                    font.family: root.fontFamily
                    style: root.shellStyle
                    text: root.title
                    elide: Text.ElideRight
                }

                Ui.ShellText {
                    Layout.fillWidth: true
                    visible: root.body.length > 0
                    font.family: root.fontFamily
                    role: "muted"
                    style: root.shellStyle
                    text: root.body
                    wrapMode: Text.Wrap
                    maximumLineCount: root.bodyMaximumLineCount
                    elide: Text.ElideRight
                }

                Ui.ShellText {
                    Layout.fillWidth: true
                    visible: root.footerTrailingText.length > 0
                    horizontalAlignment: Text.AlignRight
                    role: "label"
                    font.family: root.fontFamily
                    style: Object.assign({}, root.shellStyle, { mutedTextColor: Theme.Theme.subtext1 })
                    text: root.footerTrailingText
                    font.weight: Font.Bold
                    font.pixelSize: root.fontSize - 2
                }
            }
        }
    }
}
