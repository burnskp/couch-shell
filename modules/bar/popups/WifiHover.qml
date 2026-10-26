pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Layouts
import "../../../components" as Components
import "../../../services" as Services
import "../../../theme" as Theme

Components.HoverPopupFrame {
    id: root

    minPopupWidth: 275
    contentSpacing: Theme.Theme.listGap + 2

    readonly property string connectionSummary: root.interfaceLabel + " · " + Services.NetworkState.bandLabel + " / " + Services.NetworkState.speedLabel
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

    Components.HoverPopupMeterRow {
        label: "Signal"
        valueText: Services.NetworkState.strengthLabel
        barValue: Services.NetworkState.connected ? Services.NetworkState.signalPercent / 100 : 0
        detail: root.connectionSummary
    }

    Components.HoverPopupDivider {}

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

    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.Theme.listGap * 4

        Components.HoverPopupMeterRow {
            // Equal preferred widths split the line evenly between Up and Down.
            Layout.preferredWidth: 1
            label: "Up"
            valueText: root.txRateLabel
            showBar: false
        }

        Components.HoverPopupMeterRow {
            Layout.preferredWidth: 1
            label: "Down"
            valueText: root.rxRateLabel
            showBar: false
        }
    }

    Components.HoverPopupDivider {}

    Components.HoverPopupMeterRow {
        label: "Tx Total"
        valueText: Services.NetworkState.connected ? Services.NetworkState.formatBytes(Services.NetworkState.sessionTxBytes) : "--"
        showBar: false
    }

    Components.HoverPopupMeterRow {
        label: "Rx Total"
        valueText: Services.NetworkState.connected ? Services.NetworkState.formatBytes(Services.NetworkState.sessionRxBytes) : "--"
        showBar: false
    }
}
