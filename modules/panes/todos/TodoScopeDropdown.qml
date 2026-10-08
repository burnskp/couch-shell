pragma ComponentBehavior: Bound

TodoDropdown {
    id: root

    required property var paneState

    model: root.paneState.scopes
    value: root.paneState.scope
    loading: root.paneState.loadingProjects
    noticeText: root.paneState.scopes.length <= 1 ? "No projects found" : ""
    onSelected: value => root.paneState.setScope(value)
}
