pragma Singleton

import Quickshell
import QtQml
import "TrayIconResolverLogic.js" as TrayIconResolverLogic

QtObject {
    id: root

    readonly property string defaultThemeIconName: "dialog-information-symbolic"
    readonly property string defaultThemeIconFallbackName: "application-default-icon"
    readonly property string defaultIconSource: Quickshell.iconPath(root.defaultThemeIconName, root.defaultThemeIconFallbackName)
    function isNonEmptyString(value) {
        return TrayIconResolverLogic.isNonEmptyString(value);
    }

    function normalizedSource(icon) {
        return TrayIconResolverLogic.normalizedSource(icon);
    }

    function resolvedThemeIcon(icon, fallback) {
        if (!isNonEmptyString(icon))
            return "";

        return Quickshell.iconPath(icon, fallback || root.defaultThemeIconFallbackName);
    }

    function themeIconSource(icon) {
        return isNonEmptyString(icon) && Quickshell.hasThemeIcon(icon) ? root.resolvedThemeIcon(icon) : "";
    }

    function sourceCandidates(icon) {
        return TrayIconResolverLogic.sourceCandidates(icon, root.themeIconSource(icon), root.defaultIconSource);
    }

    function source(icon) {
        const candidates = root.sourceCandidates(icon);
        return candidates.length > 0 ? candidates[0] : "";
    }

    function desktopEntryIcon(desktopEntryId, appName) {
        let entry = null;

        if (isNonEmptyString(desktopEntryId)) {
            entry = DesktopEntries.byId(desktopEntryId);

            if (!entry && !desktopEntryId.endsWith(".desktop"))
                entry = DesktopEntries.byId(`${desktopEntryId}.desktop`);
        }

        if (!entry && isNonEmptyString(appName))
            entry = DesktopEntries.heuristicLookup(appName);

        return entry && isNonEmptyString(entry.icon) ? entry.icon : "";
    }

    function notificationIconCandidates(appIcon, desktopEntryId, appName) {
        const desktopIcon = root.desktopEntryIcon(desktopEntryId, appName);
        return TrayIconResolverLogic.notificationIconCandidates(
            root.sourceCandidates(appIcon),
            root.sourceCandidates(desktopIcon),
            root.defaultIconSource
        );
    }

}
