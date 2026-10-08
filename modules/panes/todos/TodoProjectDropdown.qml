pragma ComponentBehavior: Bound

TodoDropdown {
    id: root

    required property var paneState

    signal projectSelected()

    model: root.paneState.projectScopes()
    value: root.paneState.newTaskProject
    loading: root.paneState.loadingProjects
    enabled: !root.paneState.mutationBusy
    noticeText: !root.loading && root.model.length === 0 ? "No active projects found" : ""
    onSelected: value => {
        root.paneState.newTaskProject = value;
        root.projectSelected();
    }
}
