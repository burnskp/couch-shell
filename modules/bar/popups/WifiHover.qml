pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../components" as Components
import "../../../services" as Services
import "../../../theme" as Theme

Components.HoverPopupFrame {
    id: root

    minPopupWidth: 275

    readonly property string connectionSummary: Services.NetworkState.bandLabel + " / " + Services.NetworkState.speedLabel + " / " + Services.NetworkState.strengthLabel
    readonly property string txRateLabel: Services.NetworkState.connected ? Services.NetworkState.formatRate(Services.NetworkState.txRateBytesPerSecond) : "--"
    readonly property string rxRateLabel: Services.NetworkState.connected ? Services.NetworkState.formatRate(Services.NetworkState.rxRateBytesPerSecond) : "--"
    readonly property string interfaceLabel: Services.NetworkState.interfaceName.length > 0 ? Services.NetworkState.interfaceName : "--"

    function graphPeakValue() {
        const samples = Services.NetworkState.rxRateHistory.concat(Services.NetworkState.txRateHistory);
        let peak = 0;

        for (let index = 0; index < samples.length; index += 1)
            peak = Math.max(peak, samples[index]);

        peak = Math.max(peak, Services.NetworkState.rxRateBytesPerSecond, Services.NetworkState.txRateBytesPerSecond);
        return Math.max(peak, 1);
    }

    function drawSeries(ctx, samples, width, height, peak, strokeColor) {
        if (!samples || samples.length === 0)
            return;

        const step = samples.length > 1 ? width / (samples.length - 1) : 0;
        ctx.beginPath();

        for (let index = 0; index < samples.length; index += 1) {
            const x = step * index;
            const y = height - (Math.max(samples[index], 0) / peak) * height;

            if (index === 0)
                ctx.moveTo(x, y);
            else
                ctx.lineTo(x, y);
        }

        ctx.lineWidth = 1.5;
        ctx.strokeStyle = strokeColor;
        ctx.stroke();
    }

    Components.HoverPopupCard {
        extraHeight: 2
        contentSpacing: 5

        RowLayout {
            Layout.fillWidth: true
            spacing: 6

            Text {
                Layout.fillWidth: true
                text: "Connection"
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize
                font.weight: Font.Bold
                color: Theme.Theme.text
            }

            Text {
                text: root.interfaceLabel
                Layout.preferredWidth: 88
                Layout.maximumWidth: 88
                elide: Text.ElideLeft
                horizontalAlignment: Text.AlignRight
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize - 1
                font.weight: Font.Bold
                color: Theme.Theme.subtext0
            }
        }

        Text {
            Layout.fillWidth: true
            text: root.connectionSummary
            elide: Text.ElideRight
            font.family: Theme.Theme.fontFamily
            font.pixelSize: Theme.Theme.fontSize - 2
            font.weight: Font.Bold
            color: Theme.Theme.subtext1
        }
    }

    Components.HoverPopupCard {
        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Text {
                Layout.fillWidth: true
                text: "Traffic Monitor"
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize
                font.weight: Font.Bold
                color: Theme.Theme.text
            }

            Text {
                text: "Up"
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize - 1
                font.weight: Font.Bold
                color: Theme.Theme.popupIcon
            }

            Text {
                text: root.txRateLabel
                Layout.minimumWidth: 54
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize - 1
                font.weight: Font.Bold
                color: Theme.Theme.text
                horizontalAlignment: Text.AlignRight
            }
        }

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Item {
                Layout.fillWidth: true
            }

            Text {
                text: "Down"
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize - 1
                font.weight: Font.Bold
                color: Theme.Theme.lavender
            }

            Text {
                text: root.rxRateLabel
                Layout.minimumWidth: 54
                font.family: Theme.Theme.fontFamily
                font.pixelSize: Theme.Theme.fontSize - 1
                font.weight: Font.Bold
                color: Theme.Theme.text
                horizontalAlignment: Text.AlignRight
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: 66
            radius: 0
            color: Theme.Theme.popupTrack

            Repeater {
                model: 3

                delegate: Rectangle {
                    required property int index

                    width: parent.width
                    height: 1
                    x: 0
                    y: ((index + 1) * parent.height) / 4
                    color: Theme.Theme.surface0
                    opacity: 0.55
                }
            }

            Canvas {
                id: trafficCanvas

                anchors.fill: parent

                onPaint: {
                    const ctx = getContext("2d");
                    ctx.reset();

                    const peak = root.graphPeakValue();
                    root.drawSeries(ctx, Services.NetworkState.rxRateHistory, width, height, peak, Theme.Theme.lavender);
                    root.drawSeries(ctx, Services.NetworkState.txRateHistory, width, height, peak, Theme.Theme.popupFill);
                }

                Connections {
                    target: Services.NetworkState

                    function onRxRateHistoryChanged() {
                        trafficCanvas.requestPaint();
                    }

                    function onTxRateHistoryChanged() {
                        trafficCanvas.requestPaint();
                    }
                }
            }

        }
    }

    Components.HoverPopupCard {
        Components.HoverPopupKeyValueRow {
            label: "Tx Total"
            value: Services.NetworkState.connected ? Services.NetworkState.formatBytes(Services.NetworkState.sessionTxBytes) : "--"
        }

        Components.HoverPopupKeyValueRow {
            label: "Rx Total"
            value: Services.NetworkState.connected ? Services.NetworkState.formatBytes(Services.NetworkState.sessionRxBytes) : "--"
        }
    }
}
