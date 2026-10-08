import QtQuick
import QtTest
import "../../modules/bar/widgets/WindowListLogic.js" as WindowListLogic

TestCase {
    name: "WindowListLogic"

    function test_title_block_width_respects_window_max_width() {
        const width = WindowListLogic.titleBlockWidth(600, 10, 44, 20, 260);

        compare(width, 240);
    }

    function test_chip_width_caps_at_window_max_width() {
        const width = WindowListLogic.chipWidth(600, 10, 20, 44, 260);

        compare(width, 260);
    }

    function test_chip_width_keeps_minimum_width() {
        const width = WindowListLogic.chipWidth(0, 10, 20, 44, 260);

        compare(width, 44);
    }

    function test_available_title_block_width_splits_remaining_space() {
        const width = WindowListLogic.availableTitleBlockWidth(300, 3, 8, 20, 44, 260);

        compare(width, 74);
    }

    function test_constrained_chip_width_truncates_to_available_share() {
        const width = WindowListLogic.constrainedChipWidth(600, 10, 20, 44, 260, 300, 3, 8);

        compare(width, 94);
    }

    function test_constrained_chip_width_does_not_expand_to_fill_available_space() {
        const width = WindowListLogic.constrainedChipWidth(20, 10, 20, 44, 260, 900, 1, 8);

        compare(width, 60);
    }
}
