import QtQuick
import QtTest
import "../../lib/CalculatorLogic.js" as CalculatorLogic

TestCase {
    name: "CalculatorLogic"

    function test_parentheses_powers_and_decimals() {
        const state = CalculatorLogic.evaluateDocument("2 * (3^3)\n1.5 + 2.25\n1+(5*20)");

        compare(state.lines[0].displayResult, "54");
        compare(state.lines[1].displayResult, "3.75");
        compare(state.lines[2].displayResult, "101");
        compare(state.currentTotalDisplay, "101");
    }

    function test_continuation_lines_and_negatives() {
        const state = CalculatorLogic.evaluateDocument("2+2\n-4\n- 4\n- -4");

        compare(state.lines[0].displayResult, "4");
        compare(state.lines[1].displayResult, "-4");
        compare(state.lines[1].negative, true);
        compare(state.lines[2].displayResult, "-8");
        compare(state.lines[2].negative, true);
        compare(state.lines[3].displayResult, "-4");
        compare(state.lines[3].negative, true);
        compare(state.currentTotalDisplay, "-4");
    }

    function test_spaced_continuation_uses_implied_previous_total() {
        const state = CalculatorLogic.evaluateDocument("2+2\n- 2+2\n- 2-2\n+ 2*3");

        compare(state.lines[0].displayResult, "4");
        compare(state.lines[1].displayResult, "4");
        compare(state.lines[2].displayResult, "0");
        compare(state.lines[3].displayResult, "6");
        compare(state.currentTotalDisplay, "6");
    }

    function test_signed_lines_without_space_are_standalone_expressions() {
        const state = CalculatorLogic.evaluateDocument("2+2\n-4+4\n-4-4\n+6");

        compare(state.lines[0].displayResult, "4");
        compare(state.lines[1].displayResult, "0");
        compare(state.lines[2].displayResult, "-8");
        compare(state.lines[2].negative, true);
        compare(state.lines[3].displayResult, "6");
        compare(state.currentTotalDisplay, "6");
    }

    function test_first_line_special_cases_and_blank_lines() {
        const state = CalculatorLogic.evaluateDocument("+2\n\n-2\n*3\n\n4+4\n+ 2\n2*3\n\n1*2");

        compare(state.lines[0].displayResult, "2");
        compare(state.lines[1].kind, "blank");
        compare(state.lines[2].displayResult, "-2");
        compare(state.lines[2].negative, true);
        compare(state.lines[3].kind, "error");
        compare(state.lines[4].kind, "blank");
        compare(state.lines[5].displayResult, "8");
        compare(state.lines[6].displayResult, "10");
        compare(state.lines[7].displayResult, "6");
        compare(state.lines[8].kind, "blank");
        compare(state.lines[9].displayResult, "2");
        compare(state.currentTotalDisplay, "2");
    }

    function test_invalid_first_line_multiply_and_error_recovery() {
        const state = CalculatorLogic.evaluateDocument("*3\n4+4\n(\n+ 2");

        compare(state.lines[0].kind, "error");
        compare(state.lines[0].displayResult, "ERR");
        compare(state.lines[1].displayResult, "8");
        compare(state.lines[2].kind, "error");
        compare(state.lines[3].displayResult, "10");
        compare(state.currentTotalDisplay, "10");
    }

    function test_unfinished_last_line_does_not_show_error_immediately() {
        const state = CalculatorLogic.evaluateDocument("2+2\n1+(");

        compare(state.lines[0].displayResult, "4");
        compare(state.lines[1].kind, "pending");
        compare(state.lines[1].displayResult, "");
        compare(state.currentTotalDisplay, "4");
    }

    function test_committed_invalid_line_shows_error_after_enter() {
        const state = CalculatorLogic.evaluateDocument("2+2\n1+(\n");

        compare(state.lines[0].displayResult, "4");
        compare(state.lines[1].kind, "error");
        compare(state.lines[1].displayResult, "ERR");
        compare(state.currentTotalDisplay, "4");
    }

    function test_broken_operator_still_shows_immediate_error() {
        const state = CalculatorLogic.evaluateDocument("2+2\n*3");

        compare(state.lines[0].displayResult, "4");
        compare(state.lines[1].kind, "error");
        compare(state.lines[1].displayResult, "ERR");
        compare(state.currentTotalDisplay, "4");
    }

    function test_first_line_negative_value_without_previous_total() {
        const state = CalculatorLogic.evaluateDocument("-2");

        compare(state.lines[0].displayResult, "-2");
        compare(state.lines[0].negative, true);
        compare(state.currentTotalDisplay, "-2");
    }

    function test_unary_minus_precedence() {
        const state = CalculatorLogic.evaluateDocument("-2^2\n(-2)^2");

        compare(state.lines[0].displayResult, "-4");
        compare(state.lines[0].negative, true);
        compare(state.lines[1].displayResult, "4");
    }
}
