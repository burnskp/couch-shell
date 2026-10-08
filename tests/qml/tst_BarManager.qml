import QtQuick
import QtTest

TestCase {
    id: root

    name: "BarManager"
    property var manager: null

    SignalSpy {
        id: visibleSpy
        target: root.manager
        signalName: "visibleChanged"
    }

    function initTestCase() {
        const component = Qt.createComponent(Qt.resolvedUrl("../../services/internal/BarVisibilityState.qml"));
        compare(component.status, Component.Ready, component.errorString());

        root.manager = component.createObject(root);
        verify(root.manager !== null);
        compare(root.manager.visible, true);
    }

    function init() {
        root.manager.show();
        visibleSpy.clear();
    }

    function cleanup() {
        root.manager.show();
    }

    function cleanupTestCase() {
        if (root.manager)
            root.manager.destroy();
        root.manager = null;
    }

    function test_show_and_hide_are_idempotent() {
        root.manager.show();
        compare(root.manager.visible, true);
        compare(visibleSpy.count, 0);

        root.manager.hide();
        compare(root.manager.visible, false);
        compare(visibleSpy.count, 1);

        root.manager.hide();
        compare(root.manager.visible, false);
        compare(visibleSpy.count, 1);

        root.manager.show();
        compare(root.manager.visible, true);
        compare(visibleSpy.count, 2);
    }

    function test_repeated_toggle() {
        for (let iteration = 0; iteration < 6; iteration += 1) {
            root.manager.toggle();
            compare(root.manager.visible, iteration % 2 === 1);
        }

        compare(root.manager.visible, true);
        compare(visibleSpy.count, 6);
    }
}
