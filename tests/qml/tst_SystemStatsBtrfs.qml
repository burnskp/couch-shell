import QtQuick
import QtTest
import "../../services/SystemStatsBtrfs.js" as Btrfs
import "../../services/SystemStatsFormatting.js" as Formatting

TestCase {
    name: "SystemStatsBtrfs"

    function test_mode() {
        verify(Btrfs.popupEnabled(true, []));
        verify(!Btrfs.popupEnabled(false, []));
        verify(Btrfs.popupEnabled(false, [{name: "Root", path: "/"}]));
    }

    function test_status() {
        compare(Btrfs.statusText(null), "Waiting for collector");
        const empty = {version: 1, status: "ok", filesystems: []};
        compare(Btrfs.statusText(empty), "No mounted Btrfs volumes");
        compare(Btrfs.statusText(Btrfs.refreshResult(null, "", 1)), "Collector unavailable");
        const old = {version: 1, status: "ok", collectedAt: 123, filesystems: [{uuid: "a"}]};
        const failed = Btrfs.refreshResult(old, "garbage", 0);
        compare(failed.filesystems, old.filesystems);
        compare(failed.collectedAt, 123);
        compare(Btrfs.statusText(failed), "Stale · refresh unavailable");
        compare(Btrfs.refreshResult(failed, JSON.stringify(empty), 0), empty);
        verify(Btrfs.accountingText("simple").indexOf("Simple quotas") === 0);
    }

    function test_formatting_and_snapshots() {
        const volume = {uuid: "aaa", label: "cryptroot", device: "/dev/mapper/cryptroot", totalBytes: 2048, availableBytes: 1024, status: "ok", accounting: "valid", subvolumes: [
            {id: 257, path: "persist", uuid: "p", parentUuid: null, referencedBytes: 1024, exclusiveBytes: 0},
            {id: 256, path: "home", uuid: "h", parentUuid: null, referencedBytes: null, exclusiveBytes: null},
            {id: 258, path: "snap", uuid: "s", parentUuid: "p"},
            {id: 259, path: "orphan", uuid: "o", parentUuid: "deleted"}
        ]};
        const cards = Btrfs.volumeCards({filesystems: [volume, Object.assign({}, volume, {uuid: "bbb"})]}, Formatting.formatBytes);
        compare(cards[0].name, "cryptroot · aaa");
        compare(cards[0].capacity, "1.0 KiB / 2.0 KiB");
        compare(cards[0].rows.map(row => row.name), ["home", "persist"]);
        compare(cards[0].rows[0].referenced, "—");
        compare(cards[0].rows[1].exclusive, "0 B");
        compare(cards[0].snapshots, [{name: "persist", value: "1"}, {name: "Unassociated", value: "1"}]);
        volume.accounting = "inconsistent";
        compare(Btrfs.volumeCards({filesystems: [volume]}, Formatting.formatBytes)[0].rows[1].referenced, "—");
    }

    function test_mounted_snapshots() {
        const volume = {uuid: "fs", device: "/dev/test", status: "ok", accounting: "valid", subvolumes: [
            {path: "source", uuid: "p", parentUuid: null},
            {path: "rollback", uuid: "r", parentUuid: "p", mounted: true, referencedBytes: 1024, exclusiveBytes: 0},
            {path: "deleted-parent", uuid: "d", parentUuid: "gone", mounted: true},
            {path: "hidden", uuid: "h", parentUuid: "p", mounted: false},
            {path: "legacy", uuid: "l", parentUuid: "p"}
        ]};
        const card = Btrfs.volumeCards({filesystems: [volume]}, Formatting.formatBytes)[0];
        compare(card.rows.map(row => row.name), ["deleted-parent", "rollback", "source"]);
        compare(card.rows[1].referenced, "1.0 KiB");
        compare(card.rows[1].exclusive, "0 B");
        compare(card.snapshots, [{name: "source", value: "3"}, {name: "Unassociated", value: "1"}]);
    }

}
