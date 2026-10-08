import QtQml
import QtQuick
import "../../../services" as Services
import "./AiStateLogic.js" as AiStateLogic

Item {
    id: root

    property bool sessionsPopoverOpen: false
    property bool settingsPopoverOpen: false
    property string sessionQuery: ""
    property string inputText: ""
    property real transcriptScrollProgress: 1.0
    property int inputFocusRequest: 0
    property int transcriptRestoreRequest: 0
    property int activeTranscriptCount: 0
    property bool transcriptRestorePending: false
    property var pendingStreamUpdates: ({})
    property string reasoningEffort: Services.AiChatService.defaultReasoning
    property string textVerbosity: "low"
    property string webSearchMode: "disabled"
    property bool showReasoning: false
    readonly property var reasoningEffortOptions: reasoningOptionsForModel(root.activeEngine ? root.activeEngine.model : Services.AiChatService.defaultModel)
    property var engines: buildCodexEngines()
    property var sessions: []
    property string selectedEngineId: engines.length > 0 ? engines[0].id : ""
    property string activeSessionId: ""
    property bool persistenceHydrating: false
    property bool persistenceLoaded: false
    readonly property var activeSession: sessionById(root.activeSessionId)
    readonly property var activeEngine: engineById(root.activeSession ? root.activeSession.engineId : root.selectedEngineId)

    function cloneObject(source, overrides) {
        const next = {};

        for (const key in source)
            next[key] = source[key];

        for (const overrideKey in overrides)
            next[overrideKey] = overrides[overrideKey];

        return next;
    }

    function safeString(value, fallback) {
        return typeof value === "string" ? value : fallback;
    }

    function safeNumber(value, fallback) {
        return typeof value === "number" && isFinite(value) ? value : fallback;
    }

    function normalizeMessage(message) {
        if (!message || typeof message !== "object" || Array.isArray(message))
            return null;
        if (typeof message.id !== "string" || message.id.length === 0)
            return null;
        if (message.role !== "user" && message.role !== "assistant")
            return null;

        return {
            id: message.id,
            role: message.role,
            label: root.safeString(message.label, message.role === "user" ? "You" : Services.AiChatService.defaultModel),
            timestamp: root.safeString(message.timestamp, ""),
            createdAt: root.safeNumber(message.createdAt, 0),
            content: root.safeString(message.content, ""),
            reasoning: root.safeString(message.reasoning, ""),
            responseId: root.safeString(message.responseId, ""),
            usage: message.usage && typeof message.usage === "object" && !Array.isArray(message.usage) ? message.usage : null,
            webSearchStatus: root.safeString(message.webSearchStatus, ""),
            pending: false,
            error: Boolean(message.error)
        };
    }

    function normalizeSession(session) {
        if (!session || typeof session !== "object" || Array.isArray(session))
            return null;
        if (typeof session.id !== "string" || session.id.length === 0)
            return null;

        const messages = [];
        if (Array.isArray(session.messages)) {
            for (const message of session.messages) {
                const normalizedMessage = root.normalizeMessage(message);
                if (normalizedMessage)
                    messages.push(normalizedMessage);
            }
        }

        return {
            id: session.id,
            title: root.safeString(session.title, "New Chat"),
            group: root.safeString(session.group, "Today"),
            createdAt: root.safeNumber(session.createdAt, 0),
            updatedAt: root.safeNumber(session.updatedAt, 0),
            updatedLabel: root.safeString(session.updatedLabel, ""),
            pinned: Boolean(session.pinned),
            titleGenerated: Boolean(session.titleGenerated),
            engineId: root.engineById(session.engineId) ? session.engineId : root.selectedEngineId,
            notes: root.safeString(session.notes, ""),
            draft: root.safeString(session.draft, ""),
            files: Array.isArray(session.files) ? session.files : [],
            messages: messages
        };
    }

    function persistableSessions() {
        const persistedSessions = [];
        for (const session of root.sessions) {
            const messages = [];
            for (const message of session.messages || []) {
                if (message.pending)
                    continue;
                messages.push(root.cloneObject(message, {pending: false}));
            }
            persistedSessions.push(root.cloneObject(session, {messages: messages}));
        }
        return persistedSessions;
    }

    function persistenceSnapshot() {
        return {
            version: 1,
            updatedAt: Date.now(),
            activeSessionId: root.activeSessionId,
            selectedEngineId: root.selectedEngineId,
            settings: {
                reasoningEffort: root.reasoningEffort,
                textVerbosity: root.textVerbosity,
                webSearchMode: root.webSearchMode,
                showReasoning: root.showReasoning
            },
            sessions: root.persistableSessions()
        };
    }

    function hydrateFromPersistedState(state) {
        if (!state || typeof state !== "object" || Array.isArray(state)) {
            root.persistenceLoaded = true;
            return;
        }

        root.persistenceHydrating = true;

        const settings = state.settings && typeof state.settings === "object" && !Array.isArray(state.settings) ? state.settings : {};
        const loadedSelectedEngineId = root.engineById(state.selectedEngineId) ? state.selectedEngineId : root.selectedEngineId;
        const loadedSessions = [];
        if (Array.isArray(state.sessions)) {
            for (const session of state.sessions) {
                const normalizedSession = root.normalizeSession(session);
                if (normalizedSession)
                    loadedSessions.push(normalizedSession);
            }
        }

        root.selectedEngineId = loadedSelectedEngineId;
        const loadedEngine = root.engineById(loadedSelectedEngineId);
        root.reasoningEffort = root.normalizeReasoningEffortForModel(loadedEngine ? loadedEngine.model : Services.AiChatService.defaultModel, root.safeString(settings.reasoningEffort, root.reasoningEffort));
        root.textVerbosity = root.safeString(settings.textVerbosity, root.textVerbosity);
        root.webSearchMode = settings.webSearchMode === "live" ? "live" : "disabled";
        root.showReasoning = Boolean(settings.showReasoning);
        root.sessions = loadedSessions;

        if (root.sessionById(state.activeSessionId))
            root.activeSessionId = state.activeSessionId;
        else
            root.activeSessionId = root.sessions.length > 0 ? root.sessions[0].id : "";

        root.inputText = root.activeSession ? root.activeSession.draft || "" : "";
        root.persistenceHydrating = false;
        root.persistenceLoaded = true;
        root.requestTranscriptRestore();
    }

    function saveStateNow() {
        if (root.persistenceHydrating || !root.persistenceLoaded)
            return;

        saveStateTimer.stop();
        Services.AiChatService.saveState(root.persistenceSnapshot());
    }

    function scheduleSave(delayMs) {
        if (root.persistenceHydrating || !root.persistenceLoaded)
            return;

        saveStateTimer.interval = delayMs || 500;
        saveStateTimer.restart();
    }

    function buildCodexEngines() {
        const items = [];

        for (const modelEntry of Services.AiChatService.codexModels) {
            const model = typeof modelEntry === "string" ? modelEntry : root.safeString(modelEntry.model || modelEntry.slug || modelEntry.id, "");
            if (model.length === 0)
                continue;

            items.push({
                id: root.safeString(modelEntry.id, model + "-codex-oauth"),
                model: model,
                label: typeof modelEntry === "string" ? model : root.safeString(modelEntry.label || modelEntry.displayName, model),
                description: typeof modelEntry === "string" ? "" : root.safeString(modelEntry.description, ""),
                defaultReasoningEffort: typeof modelEntry === "string" ? "" : root.safeString(modelEntry.defaultReasoningEffort, ""),
                supportedReasoningEfforts: typeof modelEntry === "string" || !Array.isArray(modelEntry.supportedReasoningEfforts) ? [] : modelEntry.supportedReasoningEfforts,
                supportsFiles: typeof modelEntry === "string" ? false : Boolean(modelEntry.supportsFiles),
                supportsTools: typeof modelEntry === "string" ? true : modelEntry.supportsTools !== false
            });
        }

        return items;
    }

    function closePopovers() {
        root.sessionsPopoverOpen = false;
        root.settingsPopoverOpen = false;
    }

    function recordTranscriptScroll(viewportHeight, contentHeight, contentY) {
        const maxY = Math.max(0, contentHeight - viewportHeight);
        if (maxY <= 0) {
            root.transcriptScrollProgress = 1.0;
            return;
        }

        root.transcriptScrollProgress = Math.max(0, Math.min(1, contentY / maxY));
    }

    function restoreTranscriptScroll(flickable) {
        if (!flickable)
            return;

        Qt.callLater(function() {
            const maxY = Math.max(0, flickable.contentHeight - flickable.height);
            flickable.contentY = maxY * root.transcriptScrollProgress;
        });
    }

    function requestTranscriptRestore() {
        if (root.activeTranscriptCount > 0) {
            root.transcriptRestoreRequest += 1;
            root.transcriptRestorePending = false;
            return;
        }

        root.transcriptRestorePending = true;
    }

    function scrollTranscriptToBottom() {
        root.transcriptScrollProgress = 1.0;
        root.requestTranscriptRestore();
    }

    function transcriptSurfaceActivated() {
        root.activeTranscriptCount += 1;
        root.flushPendingStreamUpdates();

        if (root.transcriptRestorePending)
            root.requestTranscriptRestore();
    }

    function transcriptSurfaceDeactivated() {
        root.activeTranscriptCount = Math.max(0, root.activeTranscriptCount - 1);
    }

    function requestInputFocus() {
        root.inputFocusRequest += 1;
    }

    function sessionById(sessionId) {
        for (const session of root.sessions) {
            if (session.id === sessionId)
                return session;
        }

        return null;
    }

    function engineById(engineId) {
        for (const engine of root.engines) {
            if (engine.id === engineId)
                return engine;
        }

        return root.engines.length > 0 ? root.engines[0] : null;
    }

    function engineByModel(model) {
        for (const engine of root.engines) {
            if (engine.model === model)
                return engine;
        }

        return null;
    }

    function reasoningOptionsForModel(model) {
        const engine = root.engineByModel(model);
        if (engine && Array.isArray(engine.supportedReasoningEfforts) && engine.supportedReasoningEfforts.length > 0)
            return engine.supportedReasoningEfforts;

        const id = String(model || "").split("/").pop();
        if (id === "gpt-5.1-codex-mini")
            return ["none", "medium", "high"];
        if (id === "gpt-5.1")
            return ["none", "low", "medium", "high"];

        return ["none", "low", "medium", "high", "xhigh"];
    }

    function normalizeReasoningEffortForModel(model, effort) {
        const options = root.reasoningOptionsForModel(model);
        if (options.indexOf(effort) >= 0)
            return effort;
        if (options.indexOf(Services.AiChatService.defaultReasoning) >= 0)
            return Services.AiChatService.defaultReasoning;
        return options.length > 0 ? options[0] : "none";
    }

    function replaceSession(sessionId, overrides) {
        const nextSessions = [];

        for (const session of root.sessions) {
            if (session.id === sessionId)
                nextSessions.push(root.cloneObject(session, overrides));
            else
                nextSessions.push(session);
        }

        root.sessions = nextSessions;
    }

    function replaceMessage(sessionId, messageId, overrides) {
        const session = root.sessionById(sessionId);
        if (!session)
            return;

        const nextMessages = [];
        for (const message of session.messages) {
            if (message.id === messageId)
                nextMessages.push(root.cloneObject(message, overrides));
            else
                nextMessages.push(message);
        }

        root.replaceSession(sessionId, {
            messages: nextMessages,
            updatedAt: Date.now(),
            updatedLabel: "Now"
        });
    }

    function backendMessages(messages) {
        const converted = [];
        for (const message of messages) {
            if (message.pending || message.error)
                continue;
            if (message.role !== "user" && message.role !== "assistant")
                continue;
            if (!message.content || message.content.length === 0)
                continue;
            converted.push({
                role: message.role,
                content: message.content
            });
        }
        return converted;
    }

    function updateDraft(text) {
        root.inputText = text;

        if (root.activeSession) {
            root.replaceSession(root.activeSession.id, {draft: text});
            root.scheduleSave(900);
        }
    }

    function toggleSessionsPopover() {
        const nextState = !root.sessionsPopoverOpen;
        root.closePopovers();
        root.sessionsPopoverOpen = nextState;
    }

    function toggleSettingsPopover() {
        const nextState = !root.settingsPopoverOpen;
        root.closePopovers();
        root.settingsPopoverOpen = nextState;
    }

    function selectEngine(engineId) {
        const engine = root.engineById(engineId);
        root.selectedEngineId = engineId;
        root.reasoningEffort = root.normalizeReasoningEffortForModel(engine ? engine.model : Services.AiChatService.defaultModel, root.reasoningEffort);

        if (root.activeSession)
            root.replaceSession(root.activeSession.id, {engineId: engineId});

        root.scheduleSave();
        root.requestInputFocus();
    }

    function selectReasoningEffort(effort) {
        root.reasoningEffort = root.normalizeReasoningEffortForModel(root.activeEngine ? root.activeEngine.model : Services.AiChatService.defaultModel, effort);
        root.scheduleSave();
        root.requestInputFocus();
    }

    function selectSession(sessionId) {
        const session = root.sessionById(sessionId);
        if (!session)
            return;

        root.activeSessionId = sessionId;
        root.inputText = session.draft || "";
        root.sessionsPopoverOpen = false;
        root.scrollTranscriptToBottom();
        root.scheduleSave();
        root.requestInputFocus();
    }

    function createNewChat() {
        const now = Date.now();
        const nextSession = {
            id: "session-" + now,
            title: "New Chat",
            group: "Today",
            createdAt: now,
            updatedAt: now,
            updatedLabel: "Now",
            pinned: false,
            titleGenerated: false,
            engineId: root.activeEngine ? root.activeEngine.id : root.selectedEngineId,
            notes: "",
            draft: "",
            files: [],
            messages: []
        };

        root.sessions = [nextSession].concat(root.sessions);
        root.activeSessionId = nextSession.id;
        root.inputText = "";
        root.closePopovers();
        root.scrollTranscriptToBottom();
        root.requestInputFocus();
        root.saveStateNow();
        return nextSession;
    }

    function cleanGeneratedTitle(text) {
        let title = String(text || "").trim();
        title = title.replace(/^[\s"'“”‘’`]+|[\s"'“”‘’`.]+$/g, "");
        title = title.split("\n")[0].trim();
        if (title.length > 64)
            title = title.slice(0, 61).trim() + "…";
        return title.length > 0 ? title : "New Chat";
    }

    function requestSessionTitle(sessionId) {
        const session = root.sessionById(sessionId);
        if (!session || session.titleGenerated)
            return;

        let firstUser = "";
        let firstAssistant = "";
        for (const message of session.messages || []) {
            if (message.role === "user" && firstUser.length === 0)
                firstUser = message.content || "";
            else if (message.role === "assistant" && firstAssistant.length === 0 && !message.pending && !message.error)
                firstAssistant = message.content || "";
        }

        if (firstUser.trim().length === 0)
            return;

        const engine = root.engineById(session.engineId);
        if (!engine)
            return;

        Services.AiChatService.generateTitle(sessionId, {
            sessionId: sessionId + "-title",
            model: engine.model,
            reasoning: "none",
            textVerbosity: "low",
            webSearchMode: "disabled",
            instructions: "Generate a short chat session title. Return only the title, no quotes, no punctuation-only suffix, no explanation. Keep it under 6 words.",
            messages: [{
                role: "user",
                content: "User message:\n" + firstUser.slice(0, 1200) + (firstAssistant.trim().length > 0 ? "\n\nAssistant response:\n" + firstAssistant.slice(0, 1200) : "")
            }]
        });
    }

    function sendMessage() {
        if (Services.AiChatService.chatBusy || Services.AiChatService.authenticatedWorkBlocked || !Services.AiChatService.configured)
            return;

        const trimmedText = root.inputText.trim();
        if (trimmedText.length === 0)
            return;

        if (!root.activeEngine && root.engines.length === 0) {
            Services.AiChatService.lastError = "No AI models available. Refresh models after signing in.";
            root.requestInputFocus();
            return;
        }

        const session = root.activeSession || root.createNewChat();
        if (!session)
            return;

        const engine = root.engineById(session.engineId);
        if (!engine) {
            Services.AiChatService.lastError = "No AI models available. Refresh models after signing in.";
            root.requestInputFocus();
            return;
        }

        const now = Date.now();
        const userMessage = {
            id: "user-" + now,
            role: "user",
            label: "You",
            timestamp: "Now",
            createdAt: now,
            content: trimmedText
        };
        const assistantMessage = {
            id: "assistant-" + (now + 1),
            role: "assistant",
            label: engine.model,
            timestamp: "Now",
            createdAt: now + 1,
            content: "",
            pending: true
        };
        const nextMessages = session.messages.concat([userMessage, assistantMessage]);
        const nextTitle = session.title === "New Chat" ? trimmedText.slice(0, 36) : session.title;
        const sessionId = session.id;
        const model = engine.model;

        root.replaceSession(sessionId, {
            title: nextTitle,
            titleGenerated: Boolean(session.titleGenerated),
            updatedAt: now,
            updatedLabel: "Now",
            messages: nextMessages,
            draft: ""
        });
        root.inputText = "";
        root.scrollTranscriptToBottom();
        root.requestInputFocus();
        root.saveStateNow();

        Services.AiChatService.sendChat(sessionId, assistantMessage.id, {
            sessionId: sessionId,
            model: model,
            reasoning: root.reasoningEffort,
            textVerbosity: root.textVerbosity,
            webSearchMode: root.webSearchMode,
            instructions: "You are Couch AI, a concise assistant running inside couch-shell.",
            messages: root.backendMessages(nextMessages)
        });
    }

    function filteredSessionsForGroup(groupName) {
        const matches = [];
        const query = root.sessionQuery.trim().toLowerCase();

        for (const session of root.sessions) {
            if (session.group !== groupName)
                continue;

            if (query.length > 0 && session.title.toLowerCase().indexOf(query) === -1)
                continue;

            matches.push(session);
        }

        return matches;
    }

    function updateMessage(sessionId, messageId, callback, options) {
        const session = root.sessionById(sessionId);
        if (!session)
            return false;

        for (const message of session.messages) {
            if (message.id === messageId) {
                root.replaceMessage(sessionId, messageId, callback(message));
                if (!options || options.scroll !== false)
                    root.scrollTranscriptToBottom();
                return true;
            }
        }

        return false;
    }

    function streamUpdateKey(sessionId, messageId) {
        return sessionId + "\u001f" + messageId;
    }

    function queueStreamDelta(sessionId, messageId, field, delta) {
        const text = delta || "";
        if (text.length === 0)
            return;

        const key = root.streamUpdateKey(sessionId, messageId);
        const updates = root.pendingStreamUpdates;
        const pending = updates[key] || {
            sessionId: sessionId,
            messageId: messageId,
            content: "",
            reasoning: ""
        };

        pending[field] = (pending[field] || "") + text;
        updates[key] = pending;
        root.pendingStreamUpdates = updates;
        streamFlushTimer.interval = root.activeTranscriptCount > 0 ? 50 : 1000;
        streamFlushTimer.restart();
    }

    function flushPendingStreamUpdatesFor(sessionId, messageId) {
        const key = root.streamUpdateKey(sessionId, messageId);
        const pending = root.pendingStreamUpdates[key];
        if (!pending)
            return false;

        delete root.pendingStreamUpdates[key];
        root.pendingStreamUpdates = root.pendingStreamUpdates;

        const changed = root.updateMessage(sessionId, messageId, function(message) {
            return AiStateLogic.streamUpdateOverrides(message, pending);
        }, {scroll: false});

        if (changed)
            root.scrollTranscriptToBottom();

        return changed;
    }

    function flushPendingStreamUpdates() {
        streamFlushTimer.stop();
        const keys = Object.keys(root.pendingStreamUpdates);
        for (const key of keys) {
            const pending = root.pendingStreamUpdates[key];
            if (pending)
                root.flushPendingStreamUpdatesFor(pending.sessionId, pending.messageId);
        }
    }

    function messageById(sessionId, messageId) {
        const session = root.sessionById(sessionId);
        if (!session)
            return null;

        for (const message of session.messages || []) {
            if (message.id === messageId)
                return message;
        }

        return null;
    }

    function couchAiVisible() {
        return AiStateLogic.transcriptIsVisible(root.activeTranscriptCount);
    }

    function notificationPreview(text) {
        return AiStateLogic.notificationPreview(text);
    }

    function notifyCompletionIfHidden(sessionId, messageId) {
        if (root.couchAiVisible())
            return;

        const message = root.messageById(sessionId, messageId);
        if (!message || message.error)
            return;

        const session = root.sessionById(sessionId);
        Services.NotificationManager.recordNotification({
            remoteId: "couch-ai-complete-" + messageId,
            title: "Couch AI replied",
            body: root.notificationPreview(message.content || (session ? session.title : "")),
            appName: "Couch AI",
            appIcon: "",
            desktopEntry: "",
            image: "",
            urgency: Services.NotificationManager.urgencyNormal,
            timeoutMs: Services.NotificationManager.defaultTimeoutMs,
            timestampMs: Date.now(),
            read: false,
            skipToast: false
        });
    }

    function handleChatEvent(sessionId, messageId, event) {
        if (!event)
            return;

        if (event.type === "text_delta") {
            root.queueStreamDelta(sessionId, messageId, "content", event.delta || "");
            return;
        }

        if (event.type === "reasoning_delta") {
            root.queueStreamDelta(sessionId, messageId, "reasoning", event.delta || "");
            return;
        }

        if (event.type === "web_search") {
            root.updateMessage(sessionId, messageId, function() {
                return {
                    webSearchStatus: event.status || "active"
                };
            });
            return;
        }

        if (event.type === "done") {
            root.flushPendingStreamUpdatesFor(sessionId, messageId);
            root.replaceMessage(sessionId, messageId, {
                pending: false,
                responseId: event.responseId || "",
                usage: event.usage || null,
                webSearchStatus: ""
            });
            root.scrollTranscriptToBottom();
            root.notifyCompletionIfHidden(sessionId, messageId);
            root.requestSessionTitle(sessionId);
            root.saveStateNow();
            return;
        }

        if (event.type === "error") {
            root.flushPendingStreamUpdatesFor(sessionId, messageId);
            root.replaceMessage(sessionId, messageId, {
                pending: false,
                error: true,
                webSearchStatus: "",
                content: event.message || "Codex request failed."
            });
            root.scrollTranscriptToBottom();
            root.saveStateNow();
        }
    }

    function handleTitleEvent(sessionId, event) {
        if (!event || event.type !== "done")
            return;

        const session = root.sessionById(sessionId);
        if (!session || session.titleGenerated)
            return;

        const title = root.cleanGeneratedTitle(event.text || "");
        root.replaceSession(sessionId, {
            title: title,
            titleGenerated: true
        });
        root.saveStateNow();
    }

    Timer {
        id: saveStateTimer
        interval: 500
        repeat: false
        onTriggered: root.saveStateNow()
    }

    Timer {
        id: streamFlushTimer
        interval: 50
        repeat: false
        onTriggered: root.flushPendingStreamUpdates()
    }

    Connections {
        target: Services.AiChatService

        function onChatEvent(sessionId, messageId, event) {
            root.handleChatEvent(sessionId, messageId, event);
        }

        function onTitleEvent(sessionId, event) {
            root.handleTitleEvent(sessionId, event);
        }

        function onStateLoaded(state, event) {
            root.hydrateFromPersistedState(state);
        }

        function onStatePersistenceError(message) {
            root.persistenceLoaded = true;
        }
    }

    onActiveEngineChanged: {
        root.reasoningEffort = root.normalizeReasoningEffortForModel(root.activeEngine ? root.activeEngine.model : Services.AiChatService.defaultModel, root.reasoningEffort);
    }

    onEnginesChanged: {
        if (root.engines.length === 0)
            return;

        if (!root.engineById(root.selectedEngineId))
            root.selectedEngineId = root.engines[0].id;

        if (root.activeSession && !root.engineById(root.activeSession.engineId))
            root.replaceSession(root.activeSession.id, {engineId: root.selectedEngineId});
    }

    onTextVerbosityChanged: root.scheduleSave()
    onWebSearchModeChanged: root.scheduleSave()
    onShowReasoningChanged: root.scheduleSave()

    Component.onCompleted: {
        Services.AiChatService.loadModels();
        root.inputText = root.activeSession ? root.activeSession.draft || "" : "";
        root.reasoningEffort = root.normalizeReasoningEffortForModel(root.activeEngine ? root.activeEngine.model : Services.AiChatService.defaultModel, root.reasoningEffort);
        Services.AiChatService.loadState();
    }
}
