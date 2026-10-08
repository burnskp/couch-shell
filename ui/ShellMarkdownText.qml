pragma ComponentBehavior: Bound

import QtQuick
import CouchShell.Markdown
import QtQuick.Layouts
import Quickshell.Io
import "../theme" as Theme
import "ShellMarkdownTextLogic.js" as MarkdownLogic

ColumnLayout {
    id: root

    property string text: ""
    property string role: "body"
    property var style: ({})
    property string proseFontFamily: Theme.Theme.proseFontFamily
    property string codeFontFamily: Theme.Theme.codeFontFamily
    property color codeBackground: root.style.inputBackground || Theme.Theme.inputBackground
    property color codeBorder: root.style.borderColor || Theme.Theme.surfaceBorder
    property int codePadding: Theme.Theme.modulePadding
    property int fontSize: root.style.fontSize || Theme.Theme.fontSize
    property bool showCodeCopyButton: true

    spacing: Theme.Theme.listGap + 2

    function proseColor() {
        switch (root.role) {
        case "muted":
            return root.style.subtleTextColor || root.style.mutedTextColor || Theme.Theme.overlay1;
        case "label":
            return root.style.mutedTextColor || Theme.Theme.subtext0;
        case "accent":
            return root.style.accentColor || Theme.Theme.barAccent;
        case "danger":
            return root.style.dangerColor || Theme.Theme.red;
        default:
            return root.style.textColor || Theme.Theme.text;
        }
    }

    function prosePixelSize() {
        switch (root.role) {
        case "title":
            return root.fontSize + 1;
        case "muted":
        case "label":
            return root.fontSize - 1;
        default:
            return root.fontSize;
        }
    }

    function proseWeight() {
        switch (root.role) {
        case "title":
        case "heading":
        case "value":
        case "accent":
        case "danger":
            return Font.Bold;
        default:
            return Theme.Theme.fontWeight;
        }
    }

    function isExternalLink(link) {
        return MarkdownLogic.isExternalLink(link);
    }

    function openExternalLink(link) {
        const target = String(link || "").trim();
        if (!root.isExternalLink(target))
            return false;

        return Qt.openUrlExternally(target);
    }

    function parseBlocks(markdown) {
        return MarkdownLogic.parseBlocks(markdown);
    }

    Repeater {
        model: root.parseBlocks(root.text)

        delegate: ColumnLayout {
            id: blockDelegate

            required property var modelData
            readonly property string blockType: modelData && modelData.type ? modelData.type : "text"
            readonly property string blockText: modelData && modelData.text ? modelData.text : ""
            readonly property string renderedText: MarkdownLogic.renderImagesAsLinks(blockText)
            readonly property string blockLanguage: modelData && modelData.language ? modelData.language : ""
            readonly property bool isCodeBlock: blockType === "code"
            readonly property bool isTextBlock: blockType === "text"
            readonly property bool hasLanguage: blockLanguage.length > 0
            property bool copied: false

            function copyCode() {
                if (!blockDelegate.isCodeBlock || blockDelegate.blockText.length === 0)
                    return;

                codeCopyProcess.exec(["sh", "-c", "printf %s \"$1\" | wl-copy", "sh", blockDelegate.blockText]);
            }

            Layout.fillWidth: true
            spacing: 0

            TextEdit {
                id: prose
                objectName: "markdownProseBlock"
                property bool resourceGuardInstalled: false
                Component.onCompleted: resourceGuardInstalled = MarkdownResourceGuard.install(textDocument)
                Layout.fillWidth: true
                Layout.preferredWidth: blockDelegate.width
                visible: blockDelegate.isTextBlock
                text: prose.resourceGuardInstalled ? blockDelegate.renderedText : ""
                readOnly: true
                selectByMouse: true
                selectByKeyboard: true
                wrapMode: TextEdit.Wrap
                color: root.proseColor()
                font.family: root.proseFontFamily
                font.pixelSize: root.prosePixelSize()
                font.weight: root.proseWeight()
                textFormat: TextEdit.MarkdownText
                selectionColor: root.style.inputSelection || Theme.Theme.inputSelection
                selectedTextColor: root.proseColor()
                onLinkActivated: function(link) {
                    root.openExternalLink(link);
                }
            }

            Rectangle {
                objectName: "markdownCodeBlock"
                Layout.fillWidth: true
                visible: blockDelegate.isCodeBlock
                implicitHeight: codeColumn.implicitHeight + (root.codePadding * 2)
                color: root.codeBackground
                radius: 0
                border.width: 1
                border.color: root.codeBorder

                ColumnLayout {
                    id: codeColumn

                    anchors.fill: parent
                    anchors.margins: root.codePadding
                    spacing: Theme.Theme.listGap

                    RowLayout {
                        Layout.fillWidth: true
                        visible: blockDelegate.hasLanguage || root.showCodeCopyButton
                        spacing: Theme.Theme.listGap

                        ShellText {
                            Layout.fillWidth: true
                            visible: blockDelegate.hasLanguage
                            text: blockDelegate.blockLanguage
                            role: "label"
                            style: root.style
                            font.family: root.codeFontFamily
                        }

                        Item {
                            Layout.fillWidth: true
                            visible: !blockDelegate.hasLanguage
                        }

                        ShellButton {
                            visible: root.showCodeCopyButton
                            enabled: blockDelegate.blockText.length > 0
                            style: root.style
                            variant: blockDelegate.copied ? "accent" : "ghost"
                            text: blockDelegate.copied ? "Copied" : "Copy"
                            horizontalPadding: Theme.Theme.moduleValuePadding + 4
                            onClicked: blockDelegate.copyCode()
                        }
                    }

                    TextEdit {
                        Layout.fillWidth: true
                        Layout.preferredWidth: codeColumn.width
                        text: blockDelegate.blockText
                        readOnly: true
                        selectByMouse: true
                        selectByKeyboard: true
                        wrapMode: TextEdit.WrapAnywhere
                        color: root.style.textColor || Theme.Theme.text
                        font.family: root.codeFontFamily
                        font.pixelSize: root.fontSize
                        font.weight: Theme.Theme.fontWeight
                        textFormat: TextEdit.PlainText
                        selectionColor: root.style.inputSelection || Theme.Theme.inputSelection
                        selectedTextColor: root.style.textColor || Theme.Theme.text
                    }
                }

                Process {
                    id: codeCopyProcess

                    // Quickshell metadata omits QProcess::ExitStatus.
                    // qmllint disable signal-handler-parameters
                    onExited: function(exitCode) {
                        if (exitCode !== 0)
                            return;

                        blockDelegate.copied = true;
                        copiedResetTimer.restart();
                    }
                    // qmllint enable signal-handler-parameters
                }

                Timer {
                    id: copiedResetTimer

                    interval: 1400
                    onTriggered: blockDelegate.copied = false
                }
            }
        }
    }
}
