import QtQuick
import QtTest
import "../../lib/workspaces.js" as WorkspaceModel

TestCase {
    name: "WorkspaceModel"

    function test_sortWorkspaces_filtersSpecialAndSortsById() {
        const result = WorkspaceModel.sortWorkspaces([
            { "id": 3, "name": "3" },
            { "id": 1, "name": "1 web" },
            { "id": 0, "name": "special:scratchpad" },
            { "id": 2, "name": "2-code" }
        ]);

        compare(result.length, 3);
        compare(result[0].id, 1);
        compare(result[1].id, 2);
        compare(result[2].id, 3);
    }

    function test_displayName_prefersReadableNameSuffix() {
        compare(WorkspaceModel.displayName({ "id": 4, "name": "4:chat" }), "chat");
        compare(WorkspaceModel.displayName({ "id": 5, "name": "5 mail" }), "mail");
        compare(WorkspaceModel.displayName({ "id": 6, "name": "plain-name" }), "plain-name");
    }

    function test_displayName_fallsBackToIdForSpecialAndBlankNames() {
        compare(WorkspaceModel.displayName({ "id": 7, "name": "special:term" }), "7");
        compare(WorkspaceModel.displayName({ "id": 8, "name": "   " }), "8");
        compare(WorkspaceModel.displayName(null), "?");
    }
}
