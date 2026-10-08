pragma Singleton

import Quickshell as QS
import Quickshell.Hyprland
import QtQml
import "." as Services
import "./HyprlandLogic.js" as HyprlandLogic

QtObject {
    id: root

    property int iconRevision: 0

    property var desktopEntriesConnections: Connections {
        target: QS.DesktopEntries.applications
        enabled: Services.BarManager.visible

        function onValuesChanged() {
            root.iconRevision++;
        }
    }

    function switchWorkspace(id) {
        Hyprland.dispatch("workspace " + id);
    }

    function focusWindow(address) {
        if (!address || !address.length)
            return;

        Hyprland.dispatch("focuswindow address:0x" + address.replace(/^0x/, ""));
    }

    function workspaceOccupied(workspace) {
        return !!(workspace && workspace.toplevels && workspace.toplevels.values.length > 0);
    }

    function normalizedString(value) {
        return value === undefined || value === null ? "" : String(value).trim();
    }

    function pushUnique(values, value) {
        const stringValue = normalizedString(value);
        if (!stringValue.length || values.indexOf(stringValue) !== -1)
            return;

        values.push(stringValue);
    }

    function lookupVariants(id) {
        const raw = id ? String(id).trim() : "";
        if (!raw.length)
            return [];

        const lower = raw.toLowerCase();
        const reverseDomainTail = raw.indexOf(".") !== -1 ? raw.split(".").slice(-1)[0] : "";
        const variants = [];

        pushUnique(variants, raw);
        pushUnique(variants, lower);
        pushUnique(variants, raw.replace(/_/g, "-"));
        pushUnique(variants, lower.replace(/_/g, "-"));
        pushUnique(variants, raw.replace(/-/g, "_"));
        pushUnique(variants, lower.replace(/-/g, "_"));
        pushUnique(variants, reverseDomainTail);
        pushUnique(variants, reverseDomainTail.toLowerCase());
        pushUnique(variants, reverseDomainTail.replace(/_/g, "-"));
        pushUnique(variants, reverseDomainTail.toLowerCase().replace(/_/g, "-"));
        pushUnique(variants, reverseDomainTail.replace(/-/g, "_"));
        pushUnique(variants, reverseDomainTail.toLowerCase().replace(/-/g, "_"));

        return variants;
    }

    function lookupIdsFor(toplevel) {
        const ids = [];

        if (!toplevel)
            return ids;

        pushUnique(ids, toplevel.wayland && toplevel.wayland.appId ? toplevel.wayland.appId : "");
        pushUnique(ids, toplevel.class);
        pushUnique(ids, toplevel.initialClass);
        pushUnique(ids, toplevel.appId);
        pushUnique(ids, toplevel.lastIpcObject && toplevel.lastIpcObject.class ? toplevel.lastIpcObject.class : "");
        pushUnique(ids, toplevel.lastIpcObject && toplevel.lastIpcObject.initialClass ? toplevel.lastIpcObject.initialClass : "");
        pushUnique(ids, toplevel.lastIpcObject && toplevel.lastIpcObject.appId ? toplevel.lastIpcObject.appId : "");
        pushUnique(ids, toplevel.lastIpcObject && toplevel.lastIpcObject.wm_class ? toplevel.lastIpcObject.wm_class : "");

        return ids;
    }

    function overrideGlyphFor(toplevel) {
        return Services.WindowIconOverrides.glyphFor(toplevel);
    }

    function pathStem(value) {
        const raw = normalizedString(value);
        if (!raw.length)
            return "";

        const token = raw.split(/\s+/)[0];
        const slashIndex = Math.max(token.lastIndexOf("/"), token.lastIndexOf("\\"));
        const baseName = slashIndex === -1 ? token : token.slice(slashIndex + 1);
        const dotIndex = baseName.lastIndexOf(".");
        return dotIndex > 0 ? baseName.slice(0, dotIndex) : baseName;
    }

    function variantMapFor(id) {
        const map = ({ });

        for (const variant of lookupVariants(id))
            map[String(variant).toLowerCase()] = true;

        return map;
    }

    function hasVariantMatch(variantMap, candidate) {
        for (const variant of lookupVariants(candidate)) {
            if (variantMap[String(variant).toLowerCase()])
                return true;
        }

        return false;
    }

    function entryLookupValues(entry) {
        const command = entry.command && entry.command.length ? entry.command[0] : "";
        return [entry.id, entry.name, entry.startupClass, entry.icon, pathStem(entry.icon), entry.execString, pathStem(entry.execString), command, pathStem(command)];
    }

    function scannedDesktopEntryFor(id) {
        const variants = variantMapFor(id);

        for (const entry of QS.DesktopEntries.applications.values) {
            if (!entry || !entry.icon || !entry.icon.length)
                continue;

            for (const value of entryLookupValues(entry)) {
                if (hasVariantMatch(variants, value))
                    return entry;
            }
        }

        return null;
    }

    function desktopEntryFor(id) {
        const variants = lookupVariants(id);

        for (const variant of variants) {
            const heuristicEntry = QS.DesktopEntries.heuristicLookup(variant);
            if (heuristicEntry && heuristicEntry.icon && heuristicEntry.icon.length)
                return heuristicEntry;
        }

        for (const variant of variants) {
            const exactEntry = QS.DesktopEntries.byId(variant);
            if (exactEntry && exactEntry.icon && exactEntry.icon.length)
                return exactEntry;
        }

        const scannedEntry = scannedDesktopEntryFor(id);
        if (scannedEntry)
            return scannedEntry;

        return null;
    }

    function iconNameFor(toplevel) {
        root.iconRevision;

        const lookupIds = lookupIdsFor(toplevel);
        for (const lookupId of lookupIds) {
            const desktopEntry = desktopEntryFor(lookupId);
            if (desktopEntry)
                return desktopEntry.icon;
        }

        return lookupIds.length ? lookupIds[0] : "application-x-executable";
    }

    function titleFor(toplevel) {
        return HyprlandLogic.titleFor(toplevel);
    }
}
