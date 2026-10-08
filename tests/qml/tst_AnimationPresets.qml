import QtQuick
import QtTest
import "../../animations" as Animations

TestCase {
    name: "AnimationPresets"

    function test_registry_normalizes_aliases_and_defaults() {
        compare(Animations.AnimationRegistry.normalizePreset("smoke"), Animations.AnimationRegistry.smoke);
        compare(Animations.AnimationRegistry.normalizePreset("slide-in"), Animations.AnimationRegistry.slideIn);
        compare(Animations.AnimationRegistry.normalizePreset("hover-reveal"), Animations.AnimationRegistry.hoverReveal);
        compare(Animations.AnimationRegistry.normalizePreset("fade"), Animations.AnimationRegistry.smoke);
        compare(Animations.AnimationRegistry.normalizePreset("unknown"), Animations.AnimationRegistry.smoke);
    }

}
