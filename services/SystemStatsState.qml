pragma Singleton
pragma ComponentBehavior: Bound

import Quickshell.Io
import QtQml
import QtQuick
import "." as Services
import "./SystemStatsFormatting.js" as SystemStatsFormatting
import "./SystemStatsLogic.js" as SystemStatsLogic
import "./SystemStatsSensors.js" as SystemStatsSensors
import "./SystemStatsDisk.js" as SystemStatsDisk
import "./SystemStatsBtrfs.js" as SystemStatsBtrfs

Item {
    id: root

    property real memoryTotalBytes: 0
    property real memoryUsedBytes: 0
    property int memoryPercent: 0
    property real swapTotalBytes: 0
    property real swapUsedBytes: 0
    property int swapPercent: 0
    property int cpuUsagePercent: 0
    property real primaryTemperatureC: NaN
    property var temperatureRows: []
    property var fanRows: []
    property var topCpuProcesses: []
    property var topMemoryProcesses: []
    property var cpuCores: []
    property real lastCpuIdleTicks: 0
    property real lastCpuTotalTicks: 0
    property var lastCpuCoreTotalTicks: []
    property var lastCpuCoreIdleTicks: []
    property bool topCpuProcessesEnabled: false
    property bool topMemoryProcessesEnabled: false

    readonly property bool topProcessesActive: Services.BarManager.visible && (topCpuProcessesEnabled || topMemoryProcessesEnabled)
    readonly property bool temperatureEnabled: Services.ShellConfig.barTemperatureEnabled
    readonly property string primaryTemperaturePath: Services.ShellConfig.barTemperatureTextPath
    readonly property var temperaturePopupEntries: SystemStatsSensors.temperatureSensorEntries(Services.ShellConfig.barTemperaturePopupPaths)
    readonly property var fanPopupEntries: SystemStatsSensors.fanSensorEntries(Services.ShellConfig.barTemperatureFanPaths)
    readonly property real memoryAvailableBytes: Math.max(memoryTotalBytes - memoryUsedBytes, 0)
    readonly property string memoryAvailableLabel: formatGib(memoryAvailableBytes)
    readonly property string cpuUsageLabel: cpuUsagePercent + "%"
    readonly property string primaryTemperatureLabel: formatTemperature(primaryTemperatureC)

    property int diskAlertLevel: 0
    readonly property int diskSeverity: SystemStatsDisk.severity(diskResults[Services.ShellConfig.barDiskTextPath], Services.ShellConfig.barDiskWarningThresholdGiB, Services.ShellConfig.barDiskCriticalThresholdGiB)

    function recordDiskResult(path, result) {
        const results = Object.assign(Object.create(null), root.diskResults);
        results[path] = result;
        root.diskResults = results;
        if (path !== Services.ShellConfig.barDiskTextPath)
            return;
        const transition = SystemStatsDisk.alertTransition(root.diskAlertLevel, root.diskSeverity);
        root.diskAlertLevel = transition.level;
        if (transition.notify)
            Services.NotificationManager.recordNotification(SystemStatsDisk.alertPayload(root.diskSeverity, path, root.diskAvailableLabel, Services.NotificationManager.urgencyNormal, Services.NotificationManager.urgencyCritical));
    }

    property var diskResults: Object.create(null)
    readonly property var diskPaths: SystemStatsDisk.queryPaths(Services.ShellConfig.barDiskTextPath, Services.ShellConfig.barDiskBtrfsEnabled ? [] : Services.ShellConfig.barDiskPopupPaths)
    readonly property string diskAvailableLabel: SystemStatsDisk.availableLabel(diskResults[Services.ShellConfig.barDiskTextPath], SystemStatsFormatting.formatBytes)
    readonly property var diskRows: SystemStatsDisk.popupRows(Services.ShellConfig.barDiskPopupPaths, diskResults, SystemStatsFormatting.formatBytes)
    readonly property bool diskPollingActive: diskTimer.running
    readonly property var diskQueryPathsRunning: {
        const paths = [];
        for (let index = 0; index < diskQueries.count; index++) {
            const query = diskQueries.objectAt(index) as Process;
            if (query.running)
                paths.push(root.diskPaths[index]);
        }
        return paths;
    }

    property var btrfsReport: null
    readonly property bool btrfsPollingActive: Services.BarManager.visible && Services.ShellConfig.barDiskBtrfsEnabled
    readonly property bool btrfsQueryRunning: btrfsProcess.running
    readonly property string btrfsStatus: SystemStatsBtrfs.statusText(btrfsReport)
    readonly property var btrfsCards: SystemStatsBtrfs.volumeCards(btrfsReport, SystemStatsFormatting.formatBytes)

    function refreshBtrfs() {
        if (Services.BarManager.visible && Services.ShellConfig.barDiskBtrfsEnabled && !btrfsProcess.running)
            btrfsProcess.running = true;
    }

    Process {
        id: btrfsProcess
        command: [Services.ShellConfig.btrfsClient]
        stdout: StdioCollector { id: btrfsOutput }
        stderr: StdioCollector {}
        // qmllint disable signal-handler-parameters
        onExited: (exitCode, exitStatus) => {
            if (root.btrfsPollingActive)
                root.btrfsReport = SystemStatsBtrfs.refreshResult(root.btrfsReport, btrfsOutput.text, exitStatus === 0 ? exitCode : -1);
        }
        // qmllint enable signal-handler-parameters
    }

    Timer {
        interval: Math.min(2147483647, Services.ShellConfig.barDiskBtrfsPollInterval * 1000)
        running: root.btrfsPollingActive
        repeat: true
        onTriggered: root.refreshBtrfs()
    }

    function refreshDisks() {
        for (let index = 0; index < diskQueries.count; index++) {
            const query = diskQueries.objectAt(index) as Process;
            if ((Services.BarManager.visible || root.diskPaths[index] === Services.ShellConfig.barDiskTextPath) && !query.running)
                query.running = true;
        }
    }

    Instantiator {
        id: diskQueries
        model: root.diskPaths
        delegate: Process {
            id: diskQuery
            required property string modelData
            command: SystemStatsDisk.queryCommand(modelData)
            stdout: StdioCollector { id: diskOutput }
            stderr: StdioCollector {}
            // Quickshell's QML type metadata omits QProcess::ExitStatus.
            // qmllint disable signal-handler-parameters
            onExited: (exitCode, exitStatus) => {
                if (!Services.BarManager.visible && modelData !== Services.ShellConfig.barDiskTextPath)
                    return;
                root.recordDiskResult(modelData, SystemStatsDisk.parseResult(diskOutput.text, exitStatus === 0 ? exitCode : -1));
            }
            // qmllint enable signal-handler-parameters
        }
    }

    Timer {
        id: diskTimer
        interval: 15000
        running: true
        repeat: true
        onTriggered: root.refreshDisks()
    }

    function sensorCommandScript() {
        return [
            'read_value() {',
            '  if [ -n "$1" ] && [ -r "$1" ]; then',
            '    tr -d "\\n" < "$1" 2>/dev/null || true',
            '  fi',
            '}',
            '',
            'printf "primaryTempRaw=%s\\n" "$(read_value "$1")"',
            'shift',
            'while [ "$#" -gt 0 ] && [ "$1" != "--fans" ]; do',
            '  label=$1',
            '  path=$2',
            '  crit_path=$3',
            '  printf "popupTemp:%s=%s\\n" "$label" "$(read_value "$path")"',
            '  printf "popupTempCrit:%s=%s\\n" "$label" "$(read_value "$crit_path")"',
            '  shift 3',
            'done',
            'if [ "$#" -gt 0 ] && [ "$1" = "--fans" ]; then',
            '  shift',
            'fi',
            'while [ "$#" -ge 2 ]; do',
            '  label=$1',
            '  path=$2',
            '  printf "popupFan:%s=%s\\n" "$label" "$(read_value "$path")"',
            '  shift 2',
            'done'
        ].join("\n");
    }

    function sensorCommand() {
        const command = ["sh", "-lc", root.sensorCommandScript(), "sh", root.primaryTemperaturePath];

        for (const entry of root.temperaturePopupEntries) {
            command.push(entry.key);
            command.push(entry.path);
            command.push(entry.criticalPath || "");
        }

        command.push("--fans");

        for (const entry of root.fanPopupEntries) {
            command.push(entry.key);
            command.push(entry.path);
        }

        return command;
    }

    function aggregateCommandScript() {
        return [
            'mem_total_kb=0',
            'mem_available_kb=0',
            'swap_total_kb=0',
            'swap_free_kb=0',
            'while IFS=" " read -r key value _; do',
            '  case "$key" in',
            '    MemTotal:) mem_total_kb=$value ;;',
            '    MemAvailable:) mem_available_kb=$value ;;',
            '    SwapTotal:) swap_total_kb=$value ;;',
            '    SwapFree:) swap_free_kb=$value ;;',
            '  esac',
            'done < /proc/meminfo',
            '',
            'printf "memTotalKb=%s\\n" "$mem_total_kb"',
            'printf "memAvailableKb=%s\\n" "$mem_available_kb"',
            'printf "swapTotalKb=%s\\n" "$swap_total_kb"',
            'printf "swapFreeKb=%s\\n" "$swap_free_kb"',
            '',
            'set -- $(sed -n "s/^cpu  //p" /proc/stat | head -n 1)',
            'cpu_user=$1',
            'cpu_nice=$2',
            'cpu_system=$3',
            'cpu_idle=$4',
            'cpu_iowait=${5:-0}',
            'cpu_irq=${6:-0}',
            'cpu_softirq=${7:-0}',
            'cpu_steal=${8:-0}',
            'cpu_total=$((cpu_user + cpu_nice + cpu_system + cpu_idle + cpu_iowait + cpu_irq + cpu_softirq + cpu_steal))',
            'cpu_idle_total=$((cpu_idle + cpu_iowait))',
            'printf "cpuTotalTicks=%s\\n" "$cpu_total"',
            'printf "cpuIdleTicks=%s\\n" "$cpu_idle_total"',
            '',
            'while IFS=" " read -r cpu_label cpu_user cpu_nice cpu_system cpu_idle cpu_iowait cpu_irq cpu_softirq cpu_steal _; do',
            '  case "$cpu_label" in',
            '    cpu[0-9]*)',
            '      cpu_index=${cpu_label#cpu}',
            '      cpu_total=$((cpu_user + cpu_nice + cpu_system + cpu_idle + ${cpu_iowait:-0} + ${cpu_irq:-0} + ${cpu_softirq:-0} + ${cpu_steal:-0}))',
            '      cpu_idle_total=$((cpu_idle + ${cpu_iowait:-0}))',
            '      printf "cpu%sTotalTicks=%s\\n" "$cpu_index" "$cpu_total"',
            '      printf "cpu%sIdleTicks=%s\\n" "$cpu_index" "$cpu_idle_total"',
            '      ;;',
            '  esac',
            'done < /proc/stat',
            '',
            'for cpu_path in /sys/devices/system/cpu/cpu[0-9]*; do',
            '  cpu_name=${cpu_path##*/}',
            '  cpu_index=${cpu_name#cpu}',
            '  freq_path="$cpu_path/cpufreq/cpuinfo_max_freq"',
            '  if [ -r "$freq_path" ]; then',
            '    printf "cpu%sMaxFreqKhz=%s\\n" "$cpu_index" "$(tr -d "\\n" < "$freq_path")"',
            '  fi',
            'done'
        ].join("\n");
    }

    function topProcessesCommandScript() {
        return [
            'if command -v ps >/dev/null 2>&1; then',
            '  ps ww -eo pid=,%cpu=,rss=,args= 2>/dev/null || true',
            'fi'
        ].join("\n");
    }

    function parseAggregateStatus(output) {
        const parsed = SystemStatsLogic.parseAggregateStatus(output, cpuUsagePercent, lastCpuTotalTicks, lastCpuIdleTicks, cpuCores.map((core) => core.usagePercent), lastCpuCoreTotalTicks, lastCpuCoreIdleTicks);
        memoryTotalBytes = parsed.memoryTotalBytes;
        memoryUsedBytes = parsed.memoryUsedBytes;
        memoryPercent = parsed.memoryPercent;
        swapTotalBytes = parsed.swapTotalBytes;
        swapUsedBytes = parsed.swapUsedBytes;
        swapPercent = parsed.swapPercent;
        cpuUsagePercent = parsed.cpuUsagePercent;
        cpuCores = parsed.cpuCores;
        lastCpuTotalTicks = parsed.lastCpuTotalTicks;
        lastCpuIdleTicks = parsed.lastCpuIdleTicks;
        lastCpuCoreTotalTicks = parsed.lastCpuCoreTotalTicks;
        lastCpuCoreIdleTicks = parsed.lastCpuCoreIdleTicks;
    }

    function parseSensorStatus(output) {
        const parsed = SystemStatsSensors.parseSensorStatus(output, temperaturePopupEntries, fanPopupEntries);
        primaryTemperatureC = parsed.primaryTemperatureC;
        temperatureRows = parsed.temperatureRows;
        fanRows = parsed.fanRows;
    }

    function parseTopProcesses(output) {
        const parsed = SystemStatsLogic.parseTopProcessesForState(output, topCpuProcessesEnabled, topMemoryProcessesEnabled);
        topCpuProcesses = parsed.topCpuProcesses;
        topMemoryProcesses = parsed.topMemoryProcesses;
    }

    function refreshAggregate() {
        if (Services.BarManager.visible && !aggregateProcess.running)
            aggregateProcess.running = true;
    }

    function refreshSensors() {
        if (Services.BarManager.visible && root.temperatureEnabled && !sensorProcess.running)
            sensorProcess.running = true;
    }

    function refreshTopProcesses() {
        if (!topProcessesActive || topProcessesProcess.running)
            return;

        topProcessesProcess.running = true;
    }

    function updateTopProcessesPolling() {
        if (topProcessesActive) {
            topProcessesTimer.restart();
            refreshTopProcesses();
            return;
        }

        topProcessesTimer.stop();
        topProcessesTimeoutTimer.stop();
        if (topProcessesProcess.running)
            topProcessesProcess.running = false;
        topCpuProcesses = [];
        topMemoryProcesses = [];
    }

    function syncBarLifecycle() {
        if (Services.BarManager.visible) {
            root.refreshBtrfs();
            root.refreshDisks();
            root.refreshAggregate();
            root.refreshSensors();
            root.updateTopProcessesPolling();
            return;
        }

        for (let index = 0; index < diskQueries.count; index++) {
            const query = diskQueries.objectAt(index) as Process;
            if (root.diskPaths[index] !== Services.ShellConfig.barDiskTextPath && query.running)
                query.running = false;
        }
        const results = Object.create(null);
        results[Services.ShellConfig.barDiskTextPath] = root.diskResults[Services.ShellConfig.barDiskTextPath];
        root.diskResults = results;
        root.refreshDisks();
        if (btrfsProcess.running)
            btrfsProcess.running = false;

        if (aggregateProcess.running)
            aggregateProcess.running = false;
        if (sensorProcess.running)
            sensorProcess.running = false;

        root.topCpuProcessesEnabled = false;
        root.topMemoryProcessesEnabled = false;
        root.updateTopProcessesPolling();
    }

    function setTopCpuProcessesEnabled(enabled) {
        if (topCpuProcessesEnabled === enabled)
            return;

        topCpuProcessesEnabled = enabled;
        updateTopProcessesPolling();
    }

    function setTopMemoryProcessesEnabled(enabled) {
        if (topMemoryProcessesEnabled === enabled)
            return;

        topMemoryProcessesEnabled = enabled;
        updateTopProcessesPolling();
    }

    function formatTemperature(value) {
        return SystemStatsFormatting.formatTemperature(value);
    }

    function formatBytes(bytes) {
        return SystemStatsFormatting.formatBytes(bytes);
    }

    function formatRpm(value) {
        return SystemStatsFormatting.formatRpm(value);
    }

    function formatGib(bytes) {
        return SystemStatsFormatting.formatGib(bytes);
    }

    function formatProcessCpuPercent(value) {
        return SystemStatsFormatting.formatProcessCpuPercent(value);
    }

    Process {
        id: aggregateProcess
        command: ["sh", "-lc", root.aggregateCommandScript()]

        stdout: StdioCollector {
            onStreamFinished: root.parseAggregateStatus(this.text)
        }
    }

    Timer {
        interval: 5000
        running: Services.BarManager.visible
        repeat: true
        onTriggered: root.refreshAggregate()
    }

    Process {
        id: sensorProcess
        command: root.sensorCommand()

        stdout: StdioCollector {
            onStreamFinished: root.parseSensorStatus(this.text)
        }
    }

    Timer {
        interval: 15000
        running: Services.BarManager.visible && root.temperatureEnabled
        repeat: true
        onTriggered: root.refreshSensors()
    }

    Process {
        id: topProcessesProcess
        command: ["sh", "-lc", root.topProcessesCommandScript()]

        stdout: StdioCollector {
            onStreamFinished: root.parseTopProcesses(this.text)
        }

        onRunningChanged: {
            if (running)
                topProcessesTimeoutTimer.restart();
            else
                topProcessesTimeoutTimer.stop();
        }
    }

    Timer {
        id: topProcessesTimer
        interval: 5000
        running: false
        repeat: true
        onTriggered: root.refreshTopProcesses()
    }

    Timer {
        id: topProcessesTimeoutTimer
        interval: 4000
        repeat: false
        onTriggered: {
            if (topProcessesProcess.running)
                topProcessesProcess.running = false;
        }
    }

    Connections {
        target: Services.BarManager

        function onVisibleChanged() {
            root.syncBarLifecycle();
        }
    }

    Component.onCompleted: root.syncBarLifecycle()
}
