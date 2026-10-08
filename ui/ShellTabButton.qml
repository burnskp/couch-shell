import QtQuick

ShellButton {
    id: root

    variant: root.checked ? "accent" : "default"
    checkable: false
}
