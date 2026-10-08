{ pkgs, lib }:
let
  evaluate =
    extra:
    (lib.nixosSystem {
      inherit (pkgs.stdenv.hostPlatform) system;
      modules = [
        ./nixos.nix
        ({ lib, ... }: {
          options.home-manager.users = lib.mkOption {
            # Represents the evaluated users supplied by integrated Home Manager.
            type = lib.types.attrsOf lib.types.anything;
            default = { };
          };
          config.system.stateVersion = "26.05";
        })
        extra
      ];
    }).config;
  consumer = interval: {
    programs.couch-shell = {
      enable = true;
      bar.disk.btrfs = {
        enable = true;
        pollInterval = interval;
      };
    };
  };
  disabled = evaluate { };
  optedOut = evaluate {
    home-manager.users.alice.programs.couch-shell = {
      enable = true;
      bar.disk.btrfs.enable = false;
    };
  };
  shellDisabled = evaluate {
    home-manager.users.alice.programs.couch-shell = {
      enable = false;
      bar.disk.btrfs = {
        enable = true;
        pollInterval = 10;
      };
    };
  };
  single = evaluate { home-manager.users.alice = consumer 300; };
  multiple = evaluate {
    home-manager.users = {
      alice = consumer 300;
      bob = consumer 60;
    };
  };
  restrictions = single.systemd.services.couch-shell-btrfs.serviceConfig;
  standalone = evaluate {
    services.couch-shell-btrfs = {
      enable = true;
      users = [ "alice" ];
    };
  };
in
{
  btrfs-module =
    assert !(disabled.systemd.sockets ? couch-shell-btrfs);
    assert !(disabled.systemd.services ? couch-shell-btrfs);
    assert !(optedOut.systemd.sockets ? couch-shell-btrfs);
    assert !(shellDisabled.systemd.sockets ? couch-shell-btrfs);
    assert single.services.couch-shell-btrfs.enable;
    assert single.services.couch-shell-btrfs.pollInterval == 300;
    assert single.users.groups.couch-shell-btrfs.members == [ "alice" ];
    assert multiple.services.couch-shell-btrfs.pollInterval == 60;
    assert
      multiple.users.groups.couch-shell-btrfs.members == [
        "alice"
        "bob"
      ];
    assert standalone.users.groups.couch-shell-btrfs.members == [ "alice" ];
    assert
      restrictions.CapabilityBoundingSet == [
        "CAP_SYS_ADMIN"
        "CAP_DAC_READ_SEARCH"
      ];
    assert restrictions.SystemCallFilter == [ "~@mount" ];
    assert
      restrictions.ProtectKernelTunables
      && restrictions.ProtectKernelModules
      && restrictions.ProtectControlGroups;
    assert
      restrictions.MemoryHigh == "192M"
      && restrictions.MemoryMax == "256M"
      && restrictions.MemorySwapMax == "0";
    assert restrictions.ProtectSystem == "strict" && restrictions.ProtectHome == "read-only";
    assert restrictions.ReadWritePaths == [ "/run/couch-shell" ];
    pkgs.runCommand "couch-shell-btrfs-module-evaluation" { } ''touch "$out"'';

  btrfs-vm = pkgs.testers.runNixOSTest {
    name = "couch-shell-btrfs";
    nodes.machine = { pkgs, ... }: {
      imports = [ ./nixos.nix ];
      virtualisation.emptyDiskImages = [ 1024 ];
      services.couch-shell-btrfs = {
        enable = true;
        users = [ "alice" ];
        pollInterval = 1;
      };
      # Run a mount probe inside exactly the collector's sandbox.
      systemd.services.couch-shell-btrfs.serviceConfig.ExecStartPost =
        pkgs.writeShellScript "check-mount-denied" ''
          if ${pkgs.util-linux}/bin/mount --bind /run/couch-shell /run/couch-shell; then
            exit 1
          fi
        '';
      users.users.alice = {
        isNormalUser = true;
      };
      users.users.outsider = {
        isNormalUser = true;
      };
      environment.systemPackages = [
        pkgs.btrfs-progs
        (pkgs.callPackage ./btrfs-collector.nix { })
      ];
    };
    testScript = ''
      import json
      import shlex
      machine.start()
      machine.wait_for_unit("couch-shell-btrfs.socket")
      machine.fail("systemctl is-active couch-shell-btrfs.service")
      machine.succeed("mkfs.btrfs -f -L cryptroot /dev/vdb; mkdir -p /mnt/btrfs; mount /dev/vdb /mnt/btrfs")
      machine.succeed("btrfs subvolume create /mnt/btrfs/root; btrfs subvolume create /mnt/btrfs/persist")
      odd_path = 'space "quotes"\\backslash\nnewline'
      machine.succeed("btrfs subvolume create " + shlex.quote("/mnt/btrfs/" + odd_path))
      machine.succeed("mkdir -p /mnt/alias; mount -o subvol=persist /dev/vdb /mnt/alias")
      machine.succeed("dd if=/dev/urandom of=/mnt/btrfs/persist/data bs=1M count=8; sync")
      machine.fail("su outsider -c couch-shell-btrfs-client")
      first = json.loads(machine.succeed("su alice -c couch-shell-btrfs-client"))
      pid = machine.succeed("systemctl show couch-shell-btrfs.service -p MainPID --value").strip()
      status = machine.succeed("cat /proc/" + pid + "/status")
      fields = dict(line.split(":", 1) for line in status.splitlines())
      assert int(fields["CapBnd"].strip(), 16) == (1 << 21) | (1 << 2), status
      assert int(fields["CapEff"].strip(), 16) == (1 << 21) | (1 << 2), status
      assert fields["Seccomp"].strip() == "2", status
      for prop, expected in [("ProtectKernelTunables", "yes"), ("ProtectKernelModules", "yes"), ("ProtectControlGroups", "yes"), ("MemoryHigh", "201326592"), ("MemoryMax", "268435456"), ("MemorySwapMax", "0")]:
          assert machine.succeed("systemctl show couch-shell-btrfs.service -p " + prop + " --value").strip() == expected, prop
      syscalls = machine.succeed("systemctl show couch-shell-btrfs.service -p SystemCallFilter --value").strip()
      assert syscalls.startswith("~") and "mount" in syscalls[1:].split(), syscalls
      machine.wait_for_unit("couch-shell-btrfs.service")
      assert first["status"] == "ok", first
      assert len(first["filesystems"]) == 1, first
      volume = first["filesystems"][0]
      assert volume["label"] == "cryptroot", volume
      assert volume["accounting"] == "disabled", volume
      assert sorted(s["path"] for s in volume["subvolumes"]) == sorted(["/", "persist", "root", odd_path]), volume
      assert next(s for s in volume["subvolumes"] if s["path"] == "persist")["mounted"]
      assert not next(s for s in volume["subvolumes"] if s["path"] == "root")["mounted"]
      assert volume["totalBytes"] > volume["availableBytes"] > 0, volume
      machine.succeed("su alice -c 'cat /run/couch-shell/btrfs.json'")
      machine.fail("su outsider -c 'cat /run/couch-shell/btrfs.json'")
      machine.succeed("test $(stat -c %a /run/couch-shell/btrfs.json) = 640")
      machine.succeed("btrfs quota enable /mnt/btrfs; btrfs quota rescan -W /mnt/btrfs")
      machine.succeed("btrfs subvolume snapshot -r /mnt/btrfs/persist /mnt/btrfs/snapshot; sync")
      machine.sleep(2)
      second = json.loads(machine.succeed("su alice -c couch-shell-btrfs-client"))
      volume = second["filesystems"][0]
      assert volume["accounting"] == "valid", volume
      persist = next(s for s in volume["subvolumes"] if s["path"] == "persist")
      snapshot = next(s for s in volume["subvolumes"] if s["path"] == "snapshot")
      assert persist["referencedBytes"] >= 8 * 1024 * 1024, persist
      assert persist["exclusiveBytes"] < persist["referencedBytes"], persist
      assert snapshot["parentUuid"] == persist["uuid"], volume
      cached = json.loads(machine.succeed("cat /run/couch-shell/btrfs.json"))
      assert cached == second
      machine.sleep(2)
      assert json.loads(machine.succeed("cat /run/couch-shell/btrfs.json")) == cached
      machine.succeed("btrfs subvolume create /mnt/btrfs/temporary; mkdir /mnt/btrfs/temporary/inside; btrfs subvolume snapshot /mnt/btrfs/temporary /mnt/btrfs/rollback; btrfs subvolume delete /mnt/btrfs/temporary")
      machine.succeed("mkdir -p /mnt/inside; mount --bind /mnt/btrfs/rollback/inside /mnt/inside")
      machine.succeed("mkdir -p /mnt/rollback /mnt/bind; mount -o subvol=snapshot /dev/vdb /mnt/rollback; mount --bind /mnt/rollback /mnt/bind")
      machine.sleep(2)
      mounted = json.loads(machine.succeed("su alice -c couch-shell-btrfs-client"))
      assert next(s for s in mounted["filesystems"][0]["subvolumes"] if s["path"] == "snapshot")["mounted"], mounted
      rollback = next(s for s in mounted["filesystems"][0]["subvolumes"] if s["path"] == "rollback")
      assert rollback["mounted"] and rollback["parentUuid"], rollback
      assert not any(s["uuid"] == rollback["parentUuid"] for s in mounted["filesystems"][0]["subvolumes"]), mounted
      machine.succeed("umount /mnt/inside; umount /mnt/bind; umount /mnt/rollback; umount /mnt/alias; umount /mnt/btrfs")
      machine.sleep(2)
      empty = json.loads(machine.succeed("su alice -c couch-shell-btrfs-client"))
      assert empty["status"] == "ok" and empty["filesystems"] == [], empty
    '';
  };
}
