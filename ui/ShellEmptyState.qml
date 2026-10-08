import QtQuick
import QtQuick.Layouts

ShellSurface {
    id: root

    property var style: ({})
    property string title: ""
    property string body: ""
    implicitWidth: contentColumn.implicitWidth + (root.padding * 2)
    implicitHeight: contentColumn.implicitHeight + (root.padding * 2)

    ColumnLayout {
        id: contentColumn

        parent: root.contentItem
        anchors.fill: parent
        spacing: 4

        ShellText {
            Layout.fillWidth: true
            role: "heading"
            style: root.style
            text: root.title
        }

        ShellText {
            Layout.fillWidth: true
            role: "muted"
            style: root.style
            text: root.body
            wrapMode: Text.Wrap
        }
    }
}
