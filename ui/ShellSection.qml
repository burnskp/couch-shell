import QtQuick
import QtQuick.Layouts

ShellSurface {
    id: root

    default property alias contentData: contentColumn.data
    property string title: ""
    property string summary: ""
    property int contentSpacing: root.style.sectionSpacing || 6
    implicitWidth: contentColumn.implicitWidth + (root.padding * 2)
    implicitHeight: contentColumn.implicitHeight + (root.padding * 2)

    ColumnLayout {
        id: contentColumn

        parent: root.contentItem
        anchors.fill: parent
        spacing: root.contentSpacing

        RowLayout {
            Layout.fillWidth: true
            visible: root.title.length > 0 || root.summary.length > 0
            spacing: root.style.controlSpacing || 6

            ShellText {
                Layout.fillWidth: true
                role: "heading"
                style: root.style
                text: root.title
                visible: text.length > 0
                elide: Text.ElideRight
            }

            ShellText {
                role: "muted"
                style: root.style
                text: root.summary
                visible: text.length > 0
                horizontalAlignment: Text.AlignRight
                elide: Text.ElideRight
            }
        }
    }
}
