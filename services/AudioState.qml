pragma Singleton

import Quickshell.Services.Pipewire
import QtQml
import QtQuick
import "." as Services

Item {
    id: root

    readonly property var defaultOutput: Services.BarManager.visible && Pipewire.ready ? Pipewire.defaultAudioSink : null
    readonly property var defaultInput: Services.BarManager.visible && Pipewire.ready ? Pipewire.defaultAudioSource : null
    readonly property bool available: defaultOutput !== null && defaultOutput.audio !== null
    readonly property bool inputAvailable: defaultInput !== null && defaultInput.audio !== null

    property real currentVolume: 0
    property bool currentMuted: true
    property bool currentHeadphonesActive: false
    property real currentInputVolume: 0
    property bool currentInputMuted: true

    readonly property bool muted: available && currentMuted
    readonly property real volume: available ? currentVolume : 0
    readonly property int volumePercent: Math.round(volume * 100)
    readonly property bool headphonesActive: available && currentHeadphonesActive
    readonly property bool inputMuted: inputAvailable && currentInputMuted
    readonly property real inputVolume: inputAvailable ? currentInputVolume : 0
    readonly property int inputVolumePercent: Math.round(inputVolume * 100)
    readonly property string outputName: nodeDisplayName(defaultOutput)
    readonly property string inputName: nodeDisplayName(defaultInput)
    readonly property var activeStreamNodes: {
        const seen = {};
        const streamNodes = [];

        for (const linkGroup of outputLinkTracker.linkGroups || []) {
            const node = linkGroup && linkGroup.source ? linkGroup.source : null;
            if (!node || !node.isStream || !node.audio || seen[node.id])
                continue;

            seen[node.id] = true;
            streamNodes.push(node);
        }

        return streamNodes;
    }
    readonly property var activeStreams: activeStreamNodes.map(node => ({
                "id": node.id,
                "title": streamTitle(node),
                "subtitle": streamSubtitle(node)
            }))
    readonly property var trackedObjects: {
        const objects = [];

        if (defaultOutput)
            objects.push(defaultOutput);

        if (defaultInput && defaultInput !== defaultOutput)
            objects.push(defaultInput);

        for (const node of activeStreamNodes)
            objects.push(node);

        return objects;
    }

    readonly property string iconGlyph: {
        if (!available || muted)
            return "";

        return headphonesActive ? "" : "";
    }
    readonly property string label: !available ? "--" : muted ? "MUTE" : volumePercent + "%"

    function syncState() {
        if (!available) {
            currentVolume = 0;
            currentMuted = true;
            currentHeadphonesActive = false;
        } else {
            const audio = defaultOutput.audio;
            const nextVolume = audio.volume;
            currentVolume = (nextVolume === undefined || isNaN(nextVolume)) ? 0 : nextVolume;
            currentMuted = !!audio.muted;
            currentHeadphonesActive = isHeadphones(defaultOutput);
        }

        if (!inputAvailable) {
            currentInputVolume = 0;
            currentInputMuted = true;
            return;
        }

        const inputAudio = defaultInput.audio;
        const nextInputVolume = inputAudio.volume;
        currentInputVolume = (nextInputVolume === undefined || isNaN(nextInputVolume)) ? 0 : nextInputVolume;
        currentInputMuted = !!inputAudio.muted;
    }

    function toggleMute() {
        if (available)
            defaultOutput.audio.muted = !defaultOutput.audio.muted;
    }

    function toggleInputMute() {
        if (inputAvailable)
            defaultInput.audio.muted = !defaultInput.audio.muted;
    }

    function setVolume(nextVolume) {
        if (available)
            defaultOutput.audio.volume = Math.max(0, Math.min(1, nextVolume));
    }

    function setInputVolume(nextVolume) {
        if (inputAvailable)
            defaultInput.audio.volume = Math.max(0, Math.min(1, nextVolume));
    }

    function nodeDisplayName(node) {
        if (!node)
            return "Unavailable";

        return node.nickname || node.description || node.name || "Unavailable";
    }

    function nodeProperties(node) {
        if (!node || !node.ready)
            return null;

        return node.properties;
    }

    function isHeadphones(node) {
        const properties = nodeProperties(node);
        if (!properties)
            return false;

        const candidates = [
            properties["device.form_factor"],
            properties["device.icon_name"],
            properties["device.product.name"],
            properties["device.nick"],
            properties["node.nick"],
            properties["node.description"],
            properties["device.description"],
        ].filter(value => value !== undefined && value !== null).map(value => value.toString().toLowerCase());

        for (const candidate of candidates) {
            if (candidate.indexOf("headphone") !== -1 || candidate.indexOf("headset") !== -1 || candidate.indexOf("earbud") !== -1 || candidate.indexOf("handsfree") !== -1 || candidate.indexOf("hands-free") !== -1)
                return true;
        }

        return false;
    }

    function streamTitle(node) {
        const properties = nodeProperties(node);
        if (properties) {
            const applicationName = properties["application.name"] || "";
            const mediaName = properties["media.name"] || "";

            if (properties["media.title"])
                return properties["media.title"];

            if (applicationName.length > 0)
                return applicationName;

            if (mediaName.length > 0 && mediaName !== "Playback" && mediaName !== "Record")
                return mediaName;
        }

        return nodeDisplayName(node);
    }

    function streamSubtitle(node) {
        const properties = nodeProperties(node);
        if (!properties)
            return "";

        if (properties["media.artist"])
            return properties["media.artist"];

        const applicationName = properties["application.name"] || "";
        const displayName = nodeDisplayName(node);
        if (applicationName.length > 0 && applicationName !== displayName)
            return applicationName;

        return "";
    }

    onDefaultOutputChanged: syncState()
    onDefaultInputChanged: syncState()
    onAvailableChanged: syncState()
    onInputAvailableChanged: syncState()

    PwNodeLinkTracker {
        id: outputLinkTracker
        node: Services.BarManager.visible ? Pipewire.defaultAudioSink : null
    }

    PwObjectTracker {
        objects: Services.BarManager.visible ? root.trackedObjects : []
    }

    Connections {
        target: root.defaultOutput ? root.defaultOutput.audio : null

        function onVolumeChanged() {
            root.syncState();
        }

        function onMutedChanged() {
            root.syncState();
        }
    }

    Connections {
        target: root.defaultInput ? root.defaultInput.audio : null

        function onVolumeChanged() {
            root.syncState();
        }

        function onMutedChanged() {
            root.syncState();
        }
    }

    Connections {
        target: Services.BarManager

        function onVisibleChanged() {
            root.syncState();
        }
    }

    Component.onCompleted: syncState()
}
