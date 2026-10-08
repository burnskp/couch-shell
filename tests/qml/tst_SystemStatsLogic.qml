import QtQuick
import QtTest
import "../../services/SystemStatsFormatting.js" as SystemStatsFormatting
import "../../services/SystemStatsLogic.js" as SystemStatsLogic
import "../../services/SystemStatsSensors.js" as SystemStatsSensors

TestCase {
    name: "SystemStatsLogic"

    function test_format_helpers() {
        compare(SystemStatsFormatting.formatBytes(0), "0 B");
        compare(SystemStatsFormatting.formatBytes(1024), "1.0 KiB");
        compare(SystemStatsFormatting.formatBytes(10 * 1024), "10 KiB");
        compare(SystemStatsFormatting.formatTemperature(NaN), "Unk");
        compare(SystemStatsFormatting.formatTemperature(42.34), "42 °C");
        compare(SystemStatsFormatting.formatRpm(-1), "Unavailable");
        compare(SystemStatsFormatting.formatRpm(1540), "1540");
    }

    function test_temperature_sensor_entries_use_known_order_and_labels() {
        const entries = SystemStatsSensors.temperatureSensorEntries({
            cpu: "/sys/class/hwmon/hwmon9/temp1_input",
            nvme1: "/sys/class/hwmon/hwmon1/temp1_input",
            wifi: "/sys/class/hwmon/hwmon11/temp1_input",
            gpu: "/sys/class/hwmon/hwmon7/temp2_input",
            ram: "/sys/class/hwmon/hwmon6/temp1_input",
            nvme0: "/sys/class/hwmon/hwmon0/temp1_input",
            chipset: "/sys/class/hwmon/hwmon2/temp1_input"
        });

        compare(entries.length, 7);
        compare(entries[0].key, "cpu");
        compare(entries[0].label, "CPU");
        compare(entries[0].criticalPath, "/sys/class/hwmon/hwmon9/temp1_crit");
        compare(entries[1].key, "gpu");
        compare(entries[1].label, "GPU");
        compare(entries[2].key, "ram");
        compare(entries[2].label, "RAM");
        compare(entries[3].key, "wifi");
        compare(entries[3].label, "WiFi");
        compare(entries[4].key, "nvme0");
        compare(entries[4].label, "NVMe 0");
        compare(entries[5].key, "nvme1");
        compare(entries[5].label, "NVMe 1");
        compare(entries[6].key, "chipset");
        compare(entries[6].label, "Chipset");
    }

    function test_parse_sensor_status_keeps_popup_rows_and_marks_missing_values_unavailable() {
        const popupEntries = SystemStatsSensors.temperatureSensorEntries({
            cpu: "/sys/class/hwmon/hwmon9/temp1_input",
            gpu: "/sys/class/hwmon/hwmon7/temp2_input",
            ram: "/sys/class/hwmon/hwmon6/temp1_input",
            wifi: "/sys/class/hwmon/hwmon11/temp1_input"
        });
        const fanEntries = SystemStatsSensors.fanSensorEntries({
            fan2: "/sys/class/hwmon/hwmon7/fan2_input",
            fan1: "/sys/class/hwmon/hwmon7/fan1_input"
        });
        const parsed = SystemStatsSensors.parseSensorStatus(["primaryTempRaw=70000", "popupTemp:cpu=70000", "popupTempCrit:cpu=105000", "popupTemp:gpu=61000", "popupTemp:ram=47000", "popupTempCrit:ram=95000", "popupFan:fan1=3200"].join("\n"), popupEntries, fanEntries);

        compare(parsed.primaryTemperatureC, 70);
        compare(parsed.temperatureRows.length, 4);
        compare(parsed.temperatureRows[0].label, "CPU");
        compare(parsed.temperatureRows[0].temperatureC, 70);
        compare(parsed.temperatureRows[0].criticalC, 105);
        compare(parsed.temperatureRows[0].usagePercent, 67);
        compare(parsed.temperatureRows[1].label, "GPU");
        compare(parsed.temperatureRows[1].temperatureC, 61);
        verify(isNaN(parsed.temperatureRows[1].criticalC));
        compare(parsed.temperatureRows[1].temperatureLabel, "61 °C");
        compare(parsed.temperatureRows[1].usagePercent, -1);
        compare(parsed.temperatureRows[2].label, "RAM");
        compare(parsed.temperatureRows[2].temperatureC, 47);
        compare(parsed.temperatureRows[2].criticalC, 95);
        compare(parsed.temperatureRows[2].usagePercent, 49);
        compare(parsed.temperatureRows[3].label, "WiFi");
        verify(isNaN(parsed.temperatureRows[3].temperatureC));
        compare(parsed.temperatureRows[3].temperatureLabel, "Unk");
        compare(parsed.temperatureRows[3].usagePercent, -1);
        compare(parsed.fanRows.length, 2);
        compare(parsed.fanRows[0].label, "Fan 1");
        compare(parsed.fanRows[0].rpm, 3200);
        compare(parsed.fanRows[0].rpmLabel, "3200");
        compare(parsed.fanRows[1].label, "Fan 2");
        compare(parsed.fanRows[1].rpm, -1);
        compare(parsed.fanRows[1].rpmLabel, "Unavailable");
    }

    function test_fan_sensor_entries_use_known_order_and_labels() {
        const entries = SystemStatsSensors.fanSensorEntries({
            pump: "/sys/class/hwmon/hwmon3/fan1_input",
            fan2: "/sys/class/hwmon/hwmon7/fan2_input",
            fan1: "/sys/class/hwmon/hwmon7/fan1_input"
        });

        compare(entries.length, 3);
        compare(entries[0].key, "fan1");
        compare(entries[0].label, "Fan 1");
        compare(entries[1].key, "fan2");
        compare(entries[1].label, "Fan 2");
        compare(entries[2].key, "pump");
        compare(entries[2].label, "Pump");
    }

    function test_update_cpu_usage_calculates_delta_percent() {
        const first = SystemStatsLogic.updateCpuUsage(100, 60, 0, 0, 0);
        compare(first.cpuUsagePercent, 0);

        const second = SystemStatsLogic.updateCpuUsage(200, 90, first.cpuUsagePercent, first.lastCpuTotalTicks, first.lastCpuIdleTicks);
        compare(second.cpuUsagePercent, 70);
        compare(second.lastCpuTotalTicks, 200);
        compare(second.lastCpuIdleTicks, 90);
    }

    function test_update_cpu_usage_resets_invalid_input() {
        const reset = SystemStatsLogic.updateCpuUsage(-1, 0, 88, 123, 45);

        compare(reset.cpuUsagePercent, 0);
        compare(reset.lastCpuTotalTicks, 0);
        compare(reset.lastCpuIdleTicks, 0);
    }

    function test_parse_aggregate_status_updates_stats() {
        const parsed = SystemStatsLogic.parseAggregateStatus(["memTotalKb=8192", "memAvailableKb=2048", "swapTotalKb=4096", "swapFreeKb=1024", "cpuTotalTicks=100", "cpuIdleTicks=25", "cpu0TotalTicks=50", "cpu0IdleTicks=10", "cpu1TotalTicks=50", "cpu1IdleTicks=15", "cpu0MaxFreqKhz=5300000", "cpu1MaxFreqKhz=4600000"].join("\n"), 0, 0, 0, [], [], []);

        compare(parsed.memoryTotalBytes, 8192 * 1024);
        compare(parsed.memoryUsedBytes, 6144 * 1024);
        compare(parsed.memoryPercent, 75);
        compare(parsed.swapTotalBytes, 4096 * 1024);
        compare(parsed.swapUsedBytes, 3072 * 1024);
        compare(parsed.swapPercent, 75);
        compare(parsed.cpuUsagePercent, 0);
        compare(parsed.cpuCores.length, 2);
        compare(parsed.cpuCores[0].index, 0);
        compare(parsed.cpuCores[1].index, 1);
    }

    function test_parse_aggregate_status_handles_systems_without_swap() {
        const parsed = SystemStatsLogic.parseAggregateStatus(["memTotalKb=8192", "memAvailableKb=2048", "swapTotalKb=0", "swapFreeKb=0", "cpuTotalTicks=100", "cpuIdleTicks=25"].join("\n"), 0, 0, 0, [], [], []);

        compare(parsed.swapTotalBytes, 0);
        compare(parsed.swapUsedBytes, 0);
        compare(parsed.swapPercent, 0);
    }

    function test_parse_aggregate_status_updates_per_core_usage_and_labels() {
        const first = SystemStatsLogic.parseAggregateStatus(["memTotalKb=8192", "memAvailableKb=2048", "swapTotalKb=0", "swapFreeKb=0", "cpuTotalTicks=100", "cpuIdleTicks=50", "cpu0TotalTicks=40", "cpu0IdleTicks=10", "cpu1TotalTicks=30", "cpu1IdleTicks=20", "cpu2TotalTicks=20", "cpu2IdleTicks=15", "cpu0MaxFreqKhz=5300000", "cpu1MaxFreqKhz=4600000", "cpu2MaxFreqKhz=2500000"].join("\n"), 0, 0, 0, [], [], []);

        const second = SystemStatsLogic.parseAggregateStatus(["memTotalKb=8192", "memAvailableKb=2048", "swapTotalKb=0", "swapFreeKb=0", "cpuTotalTicks=200", "cpuIdleTicks=80", "cpu0TotalTicks=90", "cpu0IdleTicks=20", "cpu1TotalTicks=70", "cpu1IdleTicks=30", "cpu2TotalTicks=40", "cpu2IdleTicks=25", "cpu0MaxFreqKhz=5300000", "cpu1MaxFreqKhz=4600000", "cpu2MaxFreqKhz=2500000"].join("\n"), first.cpuUsagePercent, first.lastCpuTotalTicks, first.lastCpuIdleTicks, first.cpuCores.map(core => core.usagePercent), first.lastCpuCoreTotalTicks, first.lastCpuCoreIdleTicks);

        compare(second.cpuCores.length, 3);
        compare(second.cpuCores[0].coreType, "performance");
        compare(second.cpuCores[0].index, 0);
        compare(second.cpuCores[0].usagePercent, 80);
        compare(second.cpuCores[1].coreType, "efficient");
        compare(second.cpuCores[1].index, 1);
        compare(second.cpuCores[1].usagePercent, 75);
        compare(second.cpuCores[2].coreType, "lowPowerEfficient");
        compare(second.cpuCores[2].index, 2);
        compare(second.cpuCores[2].usagePercent, 50);
    }

    function test_parse_top_processes_snapshot_sorts_cpu_and_memory() {
        const parsed = SystemStatsLogic.parseTopProcessesSnapshot(["100 12.5 2048 firefox --profile default", "200 55.2 1024 /etc/profiles/per-user/llama/bin/Hyprland", "300 3.0 8192 qmlscene --platform offscreen", "400 1.0 4096 ps", "500 2.0 512 sh"].join("\n"));

        compare(parsed.topCpuProcesses.length, 3);
        compare(parsed.topCpuProcesses[0].pid, 200);
        compare(parsed.topCpuProcesses[0].command, "Hyprland");
        compare(parsed.topCpuProcesses[1].pid, 100);
        compare(parsed.topCpuProcesses[1].command, "firefox");
        compare(parsed.topMemoryProcesses[0].pid, 300);
        compare(parsed.topMemoryProcesses[0].command, "qmlscene");
        compare(parsed.topMemoryProcesses[1].pid, 100);
    }
}
