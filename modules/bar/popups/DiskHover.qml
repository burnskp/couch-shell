pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Window
import QtQuick.Controls
import QtQuick.Layouts
import "../../../components" as Components
import "../../../services" as Services
import "../../../theme" as Theme

Components.HoverPopupFrame {
    id: root
    readonly property bool btrfs: Services.ShellConfig.barDiskBtrfsEnabled
    minPopupWidth: 320

    ScrollView {
        Layout.fillWidth: true
        Layout.preferredHeight: Math.min(cards.implicitHeight, Math.max(80, root.Screen.height - Services.ShellConfig.barHeight - 64))
        contentWidth: availableWidth
        clip: true
        ScrollBar.horizontal.policy: ScrollBar.AlwaysOff

        ColumnLayout {
            id: cards
            width: parent.width
            spacing: Theme.Theme.listGap + 2

            Components.HoverPopupMeterRow {
                label: root.btrfs ? "Btrfs volumes" : "Disks"
                valueText: "Free / Total"
                showBar: false
            }
            Text {
                Layout.fillWidth: true
                visible: root.btrfs && text !== ""
                text: Services.SystemStatsState.btrfsStatus
                textFormat: Text.PlainText
                wrapMode: Text.Wrap
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize - 1
                font.weight: Font.Bold
                color: Theme.Theme.popupLabel
            }
            Repeater {
                model: root.btrfs ? Services.SystemStatsState.btrfsCards : Services.SystemStatsState.diskRows
                delegate: Components.HoverPopupMeterRow {
                    required property var modelData
                    labelElide: Text.ElideMiddle
                    label: modelData.name
                    valueText: root.btrfs ? modelData.capacity : modelData.value
                    showBar: false
                }
            }

            Repeater {
                model: root.btrfs ? Services.SystemStatsState.btrfsCards : []
                delegate: ColumnLayout {
                    id: volumeCard
                    required property var modelData
                    Layout.fillWidth: true
                    spacing: Theme.Theme.listGap
                    Components.HoverPopupDivider {}
                    Components.HoverPopupMeterRow {
                        label: "Subvolumes · " + volumeCard.modelData.name
                        labelElide: Text.ElideMiddle
                        showBar: false
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: volumeCard.modelData.explanation
                        wrapMode: Text.Wrap
                        font.family: Theme.Theme.fontFamily
                        font.pixelSize: Theme.Theme.fontSize - 1
                        font.weight: Font.Bold
                        color: Theme.Theme.popupLabel
                    }
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 3
                        columnSpacing: 12
                        rowSpacing: 4
                        Text { Layout.fillWidth: true; Layout.minimumWidth: 0; text: "" }
                        Text {
                            Layout.alignment: Qt.AlignRight
                            text: "Referenced"
                            font.family: Theme.Theme.fontFamily
                            font.pixelSize: Theme.Theme.fontSize - 1
                            font.weight: Font.Bold
                            horizontalAlignment: Text.AlignRight
                            color: Theme.Theme.popupLabel
                        }
                        Text {
                            Layout.alignment: Qt.AlignRight
                            text: "Exclusive"
                            font.family: Theme.Theme.fontFamily
                            font.pixelSize: Theme.Theme.fontSize - 1
                            font.weight: Font.Bold
                            horizontalAlignment: Text.AlignRight
                            color: Theme.Theme.popupLabel
                        }
                        Repeater {
                            model: volumeCard.modelData.rows.length * 3
                            delegate: Text {
                                required property int index
                                readonly property var row: volumeCard.modelData.rows[Math.floor(index / 3)]
                                Layout.fillWidth: index % 3 === 0
                                Layout.alignment: index % 3 === 0 ? Qt.AlignLeft : Qt.AlignRight
                                Layout.minimumWidth: index % 3 === 0 ? 0 : implicitWidth
                                Layout.preferredWidth: index % 3 === 0 ? 0 : implicitWidth
                                horizontalAlignment: index % 3 === 0 ? Text.AlignLeft : Text.AlignRight
                                text: index % 3 === 0 ? row.name : index % 3 === 1 ? row.referenced : row.exclusive
                                textFormat: Text.PlainText
                                elide: index % 3 === 0 ? Text.ElideMiddle : Text.ElideNone
                                font.family: Theme.Theme.fontFamily
                                font.pixelSize: index % 3 === 0 ? Theme.Theme.fontSize - 1 : Theme.Theme.fontSize
                                font.weight: Font.Bold
                                color: Theme.Theme.popupValue
                            }
                        }
                    }
                    Components.HoverPopupDivider { visible: volumeCard.modelData.snapshots.length > 0 }
                    Components.HoverPopupMeterRow {
                        visible: volumeCard.modelData.snapshots.length > 0
                        label: "Snapshots"
                        showBar: false
                    }
                    Repeater {
                        model: volumeCard.modelData.snapshots
                        delegate: Components.HoverPopupKeyValueRow {
                            required property var modelData
                            labelColumnWidth: 100
                            labelElide: Text.ElideMiddle
                            label: modelData.name
                            value: modelData.value
                        }
                    }
                }
            }
        }
    }
}
