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
            spacing: 8

            Components.HoverPopupCard {
                Text {
                    Layout.fillWidth: true
                    text: root.btrfs ? "Btrfs volumes" : "Free / Total"
                    font.family: Theme.Theme.fontFamily
                    font.pixelSize: Theme.Theme.fontSize
                    font.weight: Font.Bold
                    color: Theme.Theme.text
                }
                Components.HoverPopupKeyValueRow {
                    visible: root.btrfs
                    label: ""
                    value: "Free / Total"
                }
                Text {
                    Layout.fillWidth: true
                    visible: root.btrfs && text !== ""
                    text: Services.SystemStatsState.btrfsStatus
                    textFormat: Text.PlainText
                    wrapMode: Text.Wrap
                    font.family: Theme.Theme.fontFamily
                    font.pixelSize: Theme.Theme.fontSize - 1
                    color: Theme.Theme.subtext0
                }
                Repeater {
                    model: root.btrfs ? Services.SystemStatsState.btrfsCards : Services.SystemStatsState.diskRows
                    delegate: Components.HoverPopupKeyValueRow {
                        required property var modelData
                        labelColumnWidth: 100
                        labelElide: root.btrfs ? Text.ElideMiddle : Text.ElideNone
                        label: modelData.name
                        value: root.btrfs ? modelData.capacity : modelData.value
                    }
                }
            }

            Repeater {
                model: root.btrfs ? Services.SystemStatsState.btrfsCards : []
                delegate: Components.HoverPopupCard {
                    id: volumeCard
                    required property var modelData
                    Text {
                        Layout.fillWidth: true
                        text: "Subvolumes · " + volumeCard.modelData.name
                        textFormat: Text.PlainText
                        elide: Text.ElideMiddle
                        font.family: Theme.Theme.fontFamily
                        font.pixelSize: Theme.Theme.fontSize
                        font.weight: Font.Bold
                        color: Theme.Theme.text
                    }
                    Text {
                        Layout.fillWidth: true
                        visible: text !== ""
                        text: volumeCard.modelData.explanation
                        wrapMode: Text.Wrap
                        font.family: Theme.Theme.fontFamily
                        font.pixelSize: Theme.Theme.fontSize - 1
                        color: Theme.Theme.subtext0
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
                            color: Theme.Theme.text
                        }
                        Text {
                            Layout.alignment: Qt.AlignRight
                            text: "Exclusive"
                            font.family: Theme.Theme.fontFamily
                            font.pixelSize: Theme.Theme.fontSize - 1
                            font.weight: Font.Bold
                            horizontalAlignment: Text.AlignRight
                            color: Theme.Theme.text
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
                                color: Theme.Theme.text
                            }
                        }
                    }
                    Components.HoverPopupDivider { visible: volumeCard.modelData.snapshots.length > 0 }
                    Text {
                        visible: volumeCard.modelData.snapshots.length > 0
                        text: "Snapshots"
                        font.family: Theme.Theme.fontFamily
                        font.pixelSize: Theme.Theme.fontSize
                        font.weight: Font.Bold
                        color: Theme.Theme.text
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
