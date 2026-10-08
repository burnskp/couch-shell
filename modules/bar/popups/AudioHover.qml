pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../components" as Components
import "../../../services" as Services
import "../../../theme" as Theme

Components.HoverPopupFrame {
    id: root

    readonly property bool hasActiveStreams: Services.AudioState.activeStreams.length > 0
    minPopupWidth: 275

    Components.HoverPopupCard {
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: "Output"
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize
                font.weight: Font.Bold
                color: Theme.Theme.text
            }

            Text {
                text: Services.AudioState.muted ? "Muted" : Services.AudioState.volumePercent + "%"
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize
                font.weight: Font.Bold
                color: Theme.Theme.text
            }
        }

        Text {
            Layout.fillWidth: true
            text: Services.AudioState.outputName
            elide: Text.ElideRight
            font.family: Theme.Theme.fontFamily
            font.pixelSize: Theme.Theme.fontSize - 1
            font.weight: Font.Bold
            color: Theme.Theme.subtext0
        }

        Components.HoverPopupMetricBar {
            value: Services.AudioState.muted ? 0 : Services.AudioState.volumePercent / 100
            fillColor: Theme.Theme.popupFill
        }
    }

    Components.HoverPopupCard {
        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: "Input"
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize
                font.weight: Font.Bold
                color: Theme.Theme.text
            }

            Text {
                text: Services.AudioState.inputMuted ? "Muted" : Services.AudioState.inputVolumePercent + "%"
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize
                font.weight: Font.Bold
                color: Theme.Theme.text
            }
        }

        Text {
            Layout.fillWidth: true
            text: Services.AudioState.inputName
            elide: Text.ElideRight
            font.family: Theme.Theme.fontFamily
            font.pixelSize: Theme.Theme.fontSize - 1
            font.weight: Font.Bold
            color: Theme.Theme.subtext0
        }

        Components.HoverPopupMetricBar {
            value: Services.AudioState.inputMuted ? 0 : Services.AudioState.inputVolumePercent / 100
            fillColor: Theme.Theme.popupFill
        }
    }

    Components.HoverPopupCard {
        visible: root.hasActiveStreams

        Text {
            Layout.fillWidth: true
            text: "Active Audio"
            font.family: Theme.Theme.fontFamily
            font.pixelSize: Theme.Theme.fontSize
            font.weight: Font.Bold
            color: Theme.Theme.text
        }

        Repeater {
            model: Services.AudioState.activeStreams

            delegate: ColumnLayout {
                id: streamRow

                required property var modelData

                Layout.fillWidth: true
                spacing: 1

                Text {
                    Layout.fillWidth: true
                    text: streamRow.modelData.title
                    elide: Text.ElideRight
                    font.family: Theme.Theme.fontFamily
                    font.pixelSize: Theme.Theme.fontSize - 1
                    font.weight: Font.Bold
                    color: Theme.Theme.text
                }

                Text {
                    visible: streamRow.modelData.subtitle.length > 0
                    Layout.fillWidth: true
                    text: streamRow.modelData.subtitle
                    elide: Text.ElideRight
                    font.family: Theme.Theme.fontFamily
                    font.pixelSize: Theme.Theme.fontSize - 2
                    font.weight: Font.Medium
                    color: Theme.Theme.subtext0
                }
            }
        }
    }
}
