pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../theme" as Theme
import "../../../ui" as Ui
import "../../../services" as Services

Ui.ShellSurface {
    id: root

    required property var paneState
    property var shellStyle: Ui.ShellStyle.segmented
    property bool modelDropdownOpen: false
    property bool reasoningDropdownOpen: false

    style: root.shellStyle
    tone: "normal"
    padding: Theme.Theme.modulePadding
    implicitHeight: contentColumn.implicitHeight + (padding * 2)

    function authSummary() {
        if (Services.AiChatService.logoutBusy)
            return "Removing credentials…";
        if (Services.AiChatService.loginBusy)
            return Services.AiChatService.loginMessage.length > 0 ? Services.AiChatService.loginMessage : "Opening ChatGPT OAuth…";
        if (!Services.AiChatService.configured)
            return "Not signed in";
        if (Services.AiChatService.expired)
            return "Token expired; refreshes on next request";
        return "Signed in";
    }

    function setReasoningEffort(effort) {
        root.paneState.selectReasoningEffort(effort);
    }

    function padDatePart(value) {
        return String(value).padStart(2, "0");
    }

    function formatModelCacheTime(timestamp) {
        const date = new Date(timestamp);
        const month = root.padDatePart(date.getMonth() + 1);
        const day = root.padDatePart(date.getDate());
        const year = root.padDatePart(date.getFullYear() % 100);
        const hours = root.padDatePart(date.getHours());
        const minutes = root.padDatePart(date.getMinutes());
        return month + "/" + day + "/" + year + " " + hours + ":" + minutes;
    }

    function modelsSummary() {
        if (Services.AiChatService.modelsRefreshBusy)
            return "Refreshing models…";
        if (Services.AiChatService.modelsLoadBusy)
            return "Loading models…";
        if (Services.AiChatService.modelsUpdatedAt > 0)
            return "Cached (" + root.formatModelCacheTime(Services.AiChatService.modelsUpdatedAt) + ")";
        return "No cached models";
    }

    Flickable {
        parent: root.contentItem
        anchors.fill: parent
        clip: true
        contentWidth: width
        contentHeight: contentColumn.implicitHeight
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: contentColumn

            width: parent.width
            spacing: Theme.Theme.listGap + 4

            Ui.ShellText {
                text: "AI Chat Settings"
                role: "heading"
                style: root.shellStyle
            }

            Ui.ShellSurface {
                id: authSection

                Layout.fillWidth: true
                style: root.shellStyle
                tone: "subtle"
                padding: Theme.Theme.moduleValuePadding + 3
                implicitHeight: authColumn.implicitHeight + (padding * 2)

                ColumnLayout {
                    id: authColumn

                    parent: authSection.contentItem
                    anchors.fill: parent
                    spacing: Theme.Theme.listGap

                    Ui.ShellText {
                        Layout.fillWidth: true
                        text: "Account"
                        role: "label"
                        style: root.shellStyle
                    }

                    Ui.ShellText {
                        Layout.fillWidth: true
                        text: root.authSummary()
                        role: Services.AiChatService.configured ? "accent" : "muted"
                        style: root.shellStyle
                        wrapMode: Text.Wrap
                    }

                    Ui.ShellText {
                        Layout.fillWidth: true
                        visible: Services.AiChatService.authUrl.length > 0 && Services.AiChatService.loginBusy
                        text: "If the browser did not open, select and copy this URL:"
                        role: "muted"
                        style: root.shellStyle
                        wrapMode: Text.Wrap
                    }

                    Ui.ShellTextArea {
                        Layout.fillWidth: true
                        visible: Services.AiChatService.authUrl.length > 0 && Services.AiChatService.loginBusy
                        style: root.shellStyle
                        minimumHeight: 76
                        text: Services.AiChatService.authUrl
                        editor.readOnly: true
                        editor.wrapMode: TextEdit.WrapAnywhere
                        editor.selectByMouse: true
                        editor.selectByKeyboard: true
                        editor.persistentSelection: true
                    }

                    Ui.ShellText {
                        Layout.fillWidth: true
                        visible: Services.AiChatService.lastError.length > 0
                        text: Services.AiChatService.lastError
                        role: "danger"
                        style: root.shellStyle
                        wrapMode: Text.Wrap
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.Theme.listGap

                        Ui.ShellButton {
                            Layout.fillWidth: true
                            style: root.shellStyle
                            variant: "accent"
                            text: Services.AiChatService.configured && !Services.AiChatService.authenticatedWorkBlocked ? "Refresh status" : "Login"
                            enabled: !Services.AiChatService.loginBusy && !Services.AiChatService.logoutBusy && !Services.AiChatService.statusBusy
                            onClicked: Services.AiChatService.configured && !Services.AiChatService.authenticatedWorkBlocked ? Services.AiChatService.refreshStatus() : Services.AiChatService.login()
                        }

                        Ui.ShellButton {
                            Layout.fillWidth: true
                            visible: Services.AiChatService.configured
                            style: root.shellStyle
                            variant: "danger"
                            text: Services.AiChatService.logoutBusy ? "Logging out…" : "Logout"
                            enabled: !Services.AiChatService.logoutBusy
                            onClicked: Services.AiChatService.logout()
                        }
                    }
                }
            }

            Ui.ShellSurface {
                id: modelSection

                Layout.fillWidth: true
                style: root.shellStyle
                tone: "subtle"
                padding: Theme.Theme.moduleValuePadding + 3
                implicitHeight: modelColumn.implicitHeight + (padding * 2)

                ColumnLayout {
                    id: modelColumn

                    parent: modelSection.contentItem
                    anchors.fill: parent
                    spacing: Theme.Theme.listGap

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.Theme.listGap

                        Ui.ShellText {
                            Layout.fillWidth: true
                            text: "Model"
                            role: "label"
                            style: root.shellStyle
                        }

                        Ui.ShellText {
                            Layout.fillWidth: true
                            horizontalAlignment: Text.AlignRight
                            text: root.modelsSummary()
                            role: "muted"
                            style: root.shellStyle
                            elide: Text.ElideRight
                        }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.Theme.listGap

                        Ui.ShellButton {
                            Layout.fillWidth: true
                            style: root.shellStyle
                            variant: root.modelDropdownOpen ? "accent" : "default"
                            text: (root.paneState.activeEngine ? root.paneState.activeEngine.model : "No models loaded") + " ▾"
                            onClicked: {
                                root.reasoningDropdownOpen = false;
                                root.modelDropdownOpen = !root.modelDropdownOpen;
                            }
                        }

                        Ui.ShellButton {
                            Layout.preferredWidth: 92
                            style: root.shellStyle
                            variant: Services.AiChatService.modelsRefreshBusy ? "accent" : "ghost"
                            text: "Refresh"
                            enabled: Services.AiChatService.configured && !Services.AiChatService.authenticatedWorkBlocked && !Services.AiChatService.modelsRefreshBusy
                            onClicked: {
                                root.modelDropdownOpen = false;
                                root.reasoningDropdownOpen = false;
                                Services.AiChatService.refreshModels();
                            }
                        }
                    }

                    Ui.ShellSurface {
                        id: modelDropdownMenu

                        Layout.fillWidth: true
                        visible: root.modelDropdownOpen
                        style: root.shellStyle
                        tone: "normal"
                        padding: Theme.Theme.listGap
                        emphasize: true
                        implicitHeight: modelDropdownColumn.implicitHeight + (padding * 2)

                        ColumnLayout {
                            id: modelDropdownColumn

                            parent: modelDropdownMenu.contentItem
                            anchors.fill: parent
                            spacing: Theme.Theme.listGap

                            Repeater {
                                model: root.paneState.engines

                                delegate: Ui.ShellButton {
                                    required property var modelData

                                    Layout.fillWidth: true
                                    style: root.shellStyle
                                    variant: root.paneState.activeEngine && root.paneState.activeEngine.id === modelData.id ? "accent" : "ghost"
                                    text: modelData.model
                                    onClicked: {
                                        root.paneState.selectEngine(modelData.id);
                                        root.modelDropdownOpen = false;
                                    }
                                }
                            }
                        }
                    }

                    Ui.ShellText {
                        Layout.fillWidth: true
                        text: "Reasoning"
                        role: "label"
                        style: root.shellStyle
                    }

                    Ui.ShellButton {
                        Layout.fillWidth: true
                        style: root.shellStyle
                        variant: root.reasoningDropdownOpen ? "accent" : "default"
                        text: root.paneState.reasoningEffort + " ▾"
                        onClicked: {
                            root.modelDropdownOpen = false;
                            root.reasoningDropdownOpen = !root.reasoningDropdownOpen;
                        }
                    }

                    Ui.ShellSurface {
                        id: reasoningDropdownMenu

                        Layout.fillWidth: true
                        visible: root.reasoningDropdownOpen
                        style: root.shellStyle
                        tone: "normal"
                        padding: Theme.Theme.listGap
                        emphasize: true
                        implicitHeight: reasoningDropdownColumn.implicitHeight + (padding * 2)

                        ColumnLayout {
                            id: reasoningDropdownColumn

                            parent: reasoningDropdownMenu.contentItem
                            anchors.fill: parent
                            spacing: Theme.Theme.listGap

                            Repeater {
                                model: root.paneState.reasoningEffortOptions

                                delegate: Ui.ShellButton {
                                    required property string modelData

                                    Layout.fillWidth: true
                                    style: root.shellStyle
                                    variant: root.paneState.reasoningEffort === modelData ? "accent" : "ghost"
                                    text: modelData
                                    onClicked: {
                                        root.setReasoningEffort(modelData);
                                        root.reasoningDropdownOpen = false;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
