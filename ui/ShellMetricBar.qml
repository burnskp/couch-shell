import QtQuick
import QtQuick.Layouts
import "../theme" as Theme

Item {
    id: root

    property var style: ({})
    property real value: 0.5
    property color fillColor: root.style.metricFillColor || (root.style.accentColor || Theme.Theme.teal)
    property color trackColor: root.style.metricTrackColor || Theme.Theme.barBackground
    property string label: ""
    property string valueText: ""
    property int barHeight: root.style.metricBarHeight || ((Theme.Theme.indicatorThickness + 5) * 2)

    implicitWidth: 220
    implicitHeight: metricColumn.implicitHeight

    ColumnLayout {
        id: metricColumn

        anchors.fill: parent
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            visible: root.label.length > 0 || root.valueText.length > 0

            ShellText {
                Layout.fillWidth: true
                role: "label"
                style: root.style
                text: root.label
            }

            ShellText {
                role: "value"
                style: root.style
                text: root.valueText
                visible: text.length > 0
            }
        }

        Rectangle {
            Layout.fillWidth: true
            implicitHeight: root.barHeight
            color: root.trackColor
            radius: 0

            Rectangle {
                anchors.left: parent.left
                anchors.top: parent.top
                anchors.bottom: parent.bottom
                width: parent.width * Math.max(0, Math.min(1, root.value))
                color: root.fillColor
                opacity: 0.92
                radius: 0
            }
        }
    }
}
