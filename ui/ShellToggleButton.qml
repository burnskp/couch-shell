import QtQuick

ShellButton {
    id: root

    property string onText: "Enabled"
    property string offText: "Disabled"

    checkable: true
    text: root.checked ? root.onText : root.offText
    variant: root.checked ? "accent" : "default"
}
