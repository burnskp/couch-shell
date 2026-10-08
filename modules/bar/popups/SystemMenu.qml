pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../services" as Services
import "../../../theme" as Theme
import "../../../ui" as Ui

Ui.ShellPaneFrame {
    id: root

    signal requestClose()
    required property var barScreen
    readonly property var shellStyle: Object.assign({}, Ui.ShellStyle.flatPopup, {
        windowPadding: 11,
        sectionPadding: 6,
        sectionSpacing: 6,
        controlSpacing: 6,
        buttonActiveBackground: Theme.Theme.mantle,
        buttonBorderWidth: 1,
        iconSpacing: 5
    })
    readonly property var blockStyle: Object.assign({}, root.shellStyle, {
        borderColor: Theme.Theme.popupBorder,
        strongBorderColor: Theme.Theme.popupBorder
    })
    readonly property var actionButtonStyle: Object.assign({}, root.shellStyle, {
        buttonBorderWidth: 0
    })
    readonly property var dangerButtonStyle: Object.assign({}, root.shellStyle, {
        textColor: Theme.Theme.red,
        mutedTextColor: Theme.Theme.red,
        buttonBorderWidth: 0
    })
    readonly property var workspaceButtonStyle: Object.assign({}, root.shellStyle, {
        buttonActiveBackground: Theme.Theme.popupBackground,
        buttonActiveTextColor: Theme.Theme.mauve,
        buttonActiveBorderColor: Theme.Theme.mauve,
        buttonBorderWidth: 0,
        buttonAccentRailWidth: 0
    })
    readonly property bool leftVisible: Services.PaneManager.isLeftVisibleOnScreen(root.barScreen)
    readonly property bool rightVisible: Services.PaneManager.isRightVisibleOnScreen(root.barScreen)
    readonly property real sessionActionColumnWidth: sessionActionsGrid.width > 0 ? (sessionActionsGrid.width - sessionActionsGrid.columnSpacing) / sessionActionsGrid.columns : 0
    readonly property real paneActionColumnWidth: paneActionsGrid.width > 0 ? (paneActionsGrid.width - paneActionsGrid.columnSpacing) / paneActionsGrid.columns : sessionActionColumnWidth
    readonly property real actionIconSpacing: root.shellStyle.iconSpacing || root.shellStyle.controlSpacing || 6
    readonly property real leftActionContentLeft: Math.max(0, (sessionActionColumnWidth - (rebootIconMetrics.width + actionIconSpacing + rebootLabelMetrics.width)) / 2)
    readonly property real rightActionContentLeft: Math.max(0, (sessionActionColumnWidth - (powerOffIconMetrics.width + actionIconSpacing + powerOffLabelMetrics.width)) / 2)

    style: root.shellStyle
    implicitWidth: Math.max(320, menuColumn.implicitWidth + (root.padding * 2))
    implicitHeight: menuColumn.implicitHeight + (root.padding * 2)
    showRightBorder: false
    showAccentRail: false

    function closeAfter(action) {
        action();
        root.requestClose();
    }

    function leftPaneChecked(tab) {
        return root.leftVisible && Services.PaneManager.leftTab === tab;
    }

    function rightPaneChecked(tab) {
        return root.rightVisible && Services.PaneManager.rightTab === tab;
    }

    TextMetrics {
        id: rebootIconMetrics

        font.family: Theme.Theme.fontFamily
        font.pixelSize: Theme.Theme.fontSize - 1
        font.weight: Theme.Theme.fontWeight
        text: "󰜉"
    }

    TextMetrics {
        id: rebootLabelMetrics

        font.family: Theme.Theme.fontFamily
        font.pixelSize: Theme.Theme.fontSize - 1
        font.weight: Theme.Theme.fontWeight
        text: "Reboot"
    }

    TextMetrics {
        id: powerOffIconMetrics

        font.family: Theme.Theme.fontFamily
        font.pixelSize: Theme.Theme.fontSize - 1
        font.weight: Theme.Theme.fontWeight
        text: "󰐥"
    }

    TextMetrics {
        id: powerOffLabelMetrics

        font.family: Theme.Theme.fontFamily
        font.pixelSize: Theme.Theme.fontSize - 1
        font.weight: Theme.Theme.fontWeight
        text: "Power off"
    }

    ColumnLayout {
        id: menuColumn

        parent: root.contentItem
        anchors.fill: parent
        spacing: 9

        Ui.ShellSection {
            Layout.fillWidth: true
            style: root.blockStyle
            showBorder: false
            padding: 0
            contentSpacing: 0

            Ui.ShellSwitch {
                Layout.fillWidth: true
                style: root.shellStyle
                showBottomBorder: false
                iconText: "󰒲"
                iconColor: Theme.Theme.subtext1
                title: "Idle"
                enabled: !Services.SessionActions.busy
                checked: Services.IdleInhibitorState.enabled
                onClicked: Services.IdleInhibitorState.toggle()
            }

            Ui.ShellSwitch {
                Layout.fillWidth: true
                style: root.shellStyle
                showBottomBorder: false
                iconText: "󰍹"
                iconColor: checked ? Theme.Theme.mauve : Theme.Theme.subtext1
                title: "Screen saver"
                enabled: Services.ScreenSaverState.available && !Services.ScreenSaverState.busy
                checked: Services.ScreenSaverState.available && Services.ScreenSaverState.active
                onClicked: Services.ScreenSaverState.toggle()
            }

            Ui.ShellSwitch {
                Layout.fillWidth: true
                style: root.shellStyle
                showBottomBorder: false
                iconText: "󰤨"
                iconColor: checked ? Theme.Theme.mauve : Theme.Theme.subtext1
                title: "Wi-Fi"
                enabled: Services.NetworkState.available
                checked: Services.NetworkState.available && Services.NetworkState.wifiEnabled
                onClicked: Services.NetworkState.toggleWifi()
            }

            Ui.ShellSwitch {
                Layout.fillWidth: true
                style: root.shellStyle
                iconText: "󰂯"
                iconColor: Theme.Theme.subtext1
                title: "Bluetooth"
                enabled: Services.BluetoothState.available && !Services.BluetoothState.busy
                checked: Services.BluetoothState.available && Services.BluetoothState.enabled
                onClicked: Services.BluetoothState.toggle()
            }
        }

        Ui.ShellSection {
            Layout.fillWidth: true
            style: root.blockStyle
            showBorder: false
            padding: 0
            contentSpacing: root.shellStyle.controlSpacing

            Ui.ShellSurface {
                id: speakersControl

                Layout.fillWidth: true
                style: root.shellStyle
                tone: "normal"
                padding: 6
                implicitHeight: speakersColumn.implicitHeight + (speakersControl.padding * 2)

                ColumnLayout {
                    id: speakersColumn

                    anchors.fill: parent
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: root.shellStyle.controlSpacing

                        Ui.ShellText {
                            role: "label"
                            style: Object.assign({}, root.shellStyle, { textColor: Theme.Theme.subtext1, mutedTextColor: Theme.Theme.subtext1 })
                            text: "󰕾"
                        }

                        Ui.ShellText {
                            Layout.fillWidth: true
                            role: "label"
                            style: root.shellStyle
                            text: "Speakers"
                        }

                        Ui.ShellButton {
                            style: root.shellStyle
                            variant: Services.AudioState.muted ? "default" : "accent"
                            text: "Mute"
                            enabled: Services.AudioState.available
                            onClicked: Services.AudioState.toggleMute()
                        }
                    }

                    Ui.ShellSlider {
                        Layout.fillWidth: true
                        style: root.shellStyle
                        enabled: Services.AudioState.available
                        active: !Services.AudioState.muted
                        value: Services.AudioState.volume
                        onMoved: value => Services.AudioState.setVolume(value)
                    }
                }
            }

            Ui.ShellSurface {
                id: microphoneControl

                Layout.fillWidth: true
                style: root.shellStyle
                tone: "normal"
                padding: 6
                implicitHeight: microphoneColumn.implicitHeight + (microphoneControl.padding * 2)

                ColumnLayout {
                    id: microphoneColumn

                    anchors.fill: parent
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: root.shellStyle.controlSpacing

                        Ui.ShellText {
                            role: "label"
                            style: Object.assign({}, root.shellStyle, { textColor: Theme.Theme.subtext1, mutedTextColor: Theme.Theme.subtext1 })
                            text: "󰍬"
                        }

                        Ui.ShellText {
                            Layout.fillWidth: true
                            role: "label"
                            style: root.shellStyle
                            text: "Microphone"
                        }

                        Ui.ShellButton {
                            style: root.shellStyle
                            variant: Services.AudioState.inputMuted ? "default" : "accent"
                            text: "Mute"
                            enabled: Services.AudioState.inputAvailable
                            onClicked: Services.AudioState.toggleInputMute()
                        }
                    }

                    Ui.ShellSlider {
                        Layout.fillWidth: true
                        style: root.shellStyle
                        enabled: Services.AudioState.inputAvailable
                        active: !Services.AudioState.inputMuted
                        value: Services.AudioState.inputVolume
                        onMoved: value => Services.AudioState.setInputVolume(value)
                    }
                }
            }
        }

        Ui.ShellSection {
            Layout.fillWidth: true
            style: root.blockStyle
            contentSpacing: root.shellStyle.controlSpacing

            GridLayout {
                id: sessionActionsGrid

                Layout.fillWidth: true
                columns: 2
                rowSpacing: root.shellStyle.controlSpacing
                columnSpacing: root.shellStyle.controlSpacing

                Ui.ShellButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: root.sessionActionColumnWidth
                    contentLeftPadding: root.leftActionContentLeft
                    style: root.actionButtonStyle
                    iconText: "󰌾"
                    text: "Lock"
                    enabled: !Services.SessionActions.busy
                    onClicked: root.closeAfter(Services.SessionActions.lock)
                }

                Ui.ShellButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: root.sessionActionColumnWidth
                    contentLeftPadding: root.rightActionContentLeft
                    style: root.actionButtonStyle
                    iconText: "󰍃"
                    text: "Log out"
                    enabled: !Services.SessionActions.busy
                    onClicked: root.closeAfter(Services.SessionActions.logout)
                }

                Ui.ShellButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: root.sessionActionColumnWidth
                    contentLeftPadding: root.leftActionContentLeft
                    style: root.actionButtonStyle
                    iconText: "󰑐"
                    text: "Reload"
                    enabled: !Services.SessionActions.busy
                    onClicked: root.closeAfter(Services.SessionActions.reloadHyprland)
                }

                Ui.ShellButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: root.sessionActionColumnWidth
                    contentLeftPadding: root.rightActionContentLeft
                    style: root.actionButtonStyle
                    iconText: "󰒲"
                    text: "Suspend"
                    enabled: !Services.SessionActions.busy
                    onClicked: root.closeAfter(Services.SessionActions.suspend)
                }

                Ui.ShellButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: root.sessionActionColumnWidth
                    contentLeftPadding: root.leftActionContentLeft
                    style: root.dangerButtonStyle
                    iconText: "󰜉"
                    iconColor: Theme.Theme.red
                    text: "Reboot"
                    enabled: !Services.SessionActions.busy
                    onClicked: root.closeAfter(Services.SessionActions.reboot)
                }

                Ui.ShellButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: root.sessionActionColumnWidth
                    contentLeftPadding: root.rightActionContentLeft
                    style: root.dangerButtonStyle
                    iconText: "󰐥"
                    iconColor: Theme.Theme.red
                    text: "Power off"
                    enabled: !Services.SessionActions.busy
                    onClicked: root.closeAfter(Services.SessionActions.powerOff)
                }
            }
        }

        Ui.ShellSection {
            Layout.fillWidth: true
            style: root.blockStyle
            contentSpacing: root.shellStyle.controlSpacing

            GridLayout {
                id: paneActionsGrid

                Layout.fillWidth: true
                columns: 2
                rowSpacing: root.shellStyle.controlSpacing
                columnSpacing: root.shellStyle.controlSpacing

                Ui.ShellButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: root.paneActionColumnWidth
                    contentLeftPadding: root.leftActionContentLeft
                    style: root.workspaceButtonStyle
                    checked: root.leftPaneChecked(Services.PaneManager.leftTabCouchAi)
                    iconText: "󰚩"
                    text: "AI Chat"
                    onClicked: root.closeAfter(function() {
                        Services.PaneManager.toggleLeftTab(root.barScreen, Services.PaneManager.leftTabCouchAi);
                    })
                }

                Ui.ShellButton {
                    Layout.fillWidth: true
                    Layout.preferredWidth: root.paneActionColumnWidth
                    contentLeftPadding: root.rightActionContentLeft
                    style: root.workspaceButtonStyle
                    checked: root.rightPaneChecked(Services.PaneManager.rightTabTasks)
                    iconText: "󰄬"
                    text: "Tasks"
                    onClicked: root.closeAfter(function() {
                        Services.PaneManager.toggleRightTab(root.barScreen, Services.PaneManager.rightTabTasks);
                    })
                }
            }
        }
    }
}
