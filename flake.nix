{
  description = "couch-shell: a Quickshell-based shell for Hyprland";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    git-hooks = {
      url = "github:cachix/git-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      git-hooks,
      treefmt-nix,
      ...
    }:
    let
      inherit (nixpkgs) lib;
      defaults = {
        wallpaper = "assets/coding-deck.png";
        fonts = {
          proseFamily = "Inter";
          monoFamily = "CommitMono Nerd Font";
          codeFamily = "CommitMono Nerd Font";
          notificationToastFamily = "CommitMono Nerd Font";
          size = 12;
          aiPaneSize = 12;
          tasksPaneSize = 12;
          notificationToastSize = 12;
          packages = [ ];
        };
        theme = {
          flavor = "latte";
        };
        bar = {
          height = 20;
          aiUsage = {
            defaultProvider = "chatgpt";
            hoverProviders = "all";
            refreshInterval = 300;
          };
          disk = {
            btrfs = {
              enable = false;
              pollInterval = 300;
            };
            warningThresholdGiB = 50;
            criticalThresholdGiB = 10;
            textPath = "/persist";
            popupPaths = [
              {
                name = "Persist";
                path = "/persist";
              }
              {
                name = "Ephemeral";
                path = "/";
              }
            ];
          };
          temperature = {
            enable = true;
            textPath = "/sys/class/hwmon/hwmon9/temp1_input";
            popupPaths = {
              cpu = "/sys/class/hwmon/hwmon9/temp1_input";
              gpu = "/sys/class/hwmon/hwmon7/temp2_input";
              ram = "/sys/class/hwmon/hwmon6/temp1_input";
              wifi = "/sys/class/hwmon/hwmon11/temp1_input";
              nvme0 = "/sys/class/hwmon/hwmon0/temp1_input";
              nvme1 = "/sys/class/hwmon/hwmon1/temp1_input";
            };
            fanPaths = {
              fan1 = "/sys/class/hwmon/hwmon7/fan1_input";
              fan2 = "/sys/class/hwmon/hwmon7/fan2_input";
            };
          };
        };
      };
      systems = [
        "x86_64-linux"
      ];
      forAllSystems = f: lib.genAttrs systems (system: f system (import nixpkgs { inherit system; }));
      mkCouchShellPackage =
        pkgs:
        {
          bar ? defaults.bar,
          fonts ? defaults.fonts,
          theme ? defaults.theme,
        }:
        pkgs.callPackage ./nix/package.nix {
          inherit (defaults) wallpaper;
          fonts = lib.recursiveUpdate defaults.fonts fonts;
          bar =
            let
              temperatureOverrides = lib.attrByPath [ "temperature" ] { } bar;
              mergedTemperature =
                (lib.recursiveUpdate defaults.bar.temperature (
                  builtins.removeAttrs temperatureOverrides [
                    "popupPaths"
                    "fanPaths"
                  ]
                ))
                // lib.optionalAttrs (temperatureOverrides ? popupPaths) {
                  inherit (temperatureOverrides) popupPaths;
                }
                // lib.optionalAttrs (temperatureOverrides ? fanPaths) {
                  inherit (temperatureOverrides) fanPaths;
                };
            in
            (lib.recursiveUpdate defaults.bar (builtins.removeAttrs bar [ "temperature" ]))
            // {
              temperature = mergedTemperature;
            };
          theme = lib.recursiveUpdate defaults.theme theme;
        };
      checkSource = lib.fileset.toSource {
        root = ./.;
        fileset = lib.fileset.unions [
          ./animations
          ./components
          ./lib
          ./modules
          ./nix
          ./scripts
          ./services
          ./tests
          ./theme
          ./tools
          ./ui
          ./README.md
          ./assets
          ./shell.qml
          ./smoke.qml
        ];
      };
      treefmtEval =
        pkgs:
        treefmt-nix.lib.evalModule pkgs {
          projectRootFile = "flake.nix";
          programs = {
            biome.enable = true;
            deadnix.enable = true;
            mdformat.enable = true;
            nixfmt.enable = true;
            statix.enable = true;
          };
        };
      gitHooks =
        system:
        git-hooks.lib.${system}.run {
          src = ./.;
          hooks = {
            check-merge-conflicts.enable = true;
            check-yaml.enable = true;
            end-of-file-fixer.enable = true;
            flake-checker.enable = true;
            treefmt = {
              enable = true;
              entry = "nix fmt";
              pass_filenames = false;
            };
            trim-trailing-whitespace.enable = true;
            markdownlint = {
              enable = true;
              settings.configuration = {
                MD013 = false;
                MD026 = false;
                MD033 = false;
                MD034 = false;
              };
            };
            couch-shell-lint = {
              enable = true;
              name = "couch-shell-lint";
              entry = "bash ./scripts/lint";
              pass_filenames = false;
            };
            couch-shell-test = {
              enable = true;
              name = "couch-shell-test";
              entry = "bash ./scripts/test";
              pass_filenames = false;
              stages = [ "pre-push" ];
            };
          };
        };
    in
    {
      formatter = forAllSystems (_: pkgs: (treefmtEval pkgs).config.build.wrapper);

      lib = {
        inherit defaults;
        mkCouchShellPackage =
          {
            pkgs,
            bar ? defaults.bar,
            fonts ? defaults.fonts,
            theme ? defaults.theme,
          }:
          mkCouchShellPackage pkgs {
            inherit bar fonts theme;
          };
      };

      packages = forAllSystems (
        _: pkgs: rec {
          couch-shell = mkCouchShellPackage pkgs { };

          default = couch-shell;
        }
      );

      apps = forAllSystems (
        system: _pkgs: rec {
          couch-shell = {
            type = "app";
            program = "${self.packages.${system}.couch-shell}/bin/couch-shell";
            meta.description = "Run couch-shell";
          };

          default = couch-shell;
        }
      );

      devShells = forAllSystems (
        system: pkgs:
        let
          devEnv = import ./nix/env.nix {
            inherit pkgs;
          };
          preCommitCheck = gitHooks system;
        in
        {
          default = pkgs.mkShell {
            packages = devEnv.devPackages;

            FONTCONFIG_FILE = devEnv.fontconfigFile;
            QML_IMPORT_PATH = devEnv.qmlImportPath;
            QT_PLUGIN_PATH = devEnv.qtPluginPath;

            shellHook = ''
              export COUCH_SHELL_PINNED_DEV_ENV=1
            ''
            + preCommitCheck.shellHook;
          };
        }
      );

      checks = forAllSystems (
        system: pkgs:
        let
          devEnv = import ./nix/env.nix {
            inherit pkgs;
          };
          mkCheck =
            name: command:
            pkgs.runCommand name
              {
                nativeBuildInputs = devEnv.devPackages;
                FONTCONFIG_FILE = devEnv.fontconfigFile;
                QML_IMPORT_PATH = devEnv.qmlImportPath;
                QT_PLUGIN_PATH = devEnv.qtPluginPath;
              }
              ''
                cp -r ${checkSource} source
                chmod -R u+w source
                cd source
                # Quickshell and fontconfig need writable paths in the build sandbox.
                export XDG_RUNTIME_DIR="$TMPDIR/couch-shell-runtime"
                export XDG_CACHE_HOME="$TMPDIR/couch-shell-cache"
                mkdir -p "$XDG_RUNTIME_DIR" "$XDG_CACHE_HOME"
                chmod 700 "$XDG_RUNTIME_DIR"
                ${command}
                touch "$out"
              '';
        in
        {
          disk-config =
            let
              evaluate =
                disk:
                (lib.evalModules {
                  specialArgs = { inherit pkgs; };
                  modules = [
                    (import ./nix/home-manager.nix self)
                    ({ lib, ... }: {
                      options = {
                        home.packages = lib.mkOption { type = lib.types.listOf lib.types.package; };
                        systemd.user.services = lib.mkOption { type = lib.types.attrs; };
                        assertions = lib.mkOption { type = lib.types.listOf lib.types.attrs; };
                      };
                      config.programs.couch-shell = {
                        enable = true;
                        package = pkgs.hello;
                        bar.disk = disk;
                      };
                    })
                  ];
                }).config;
              defaultConfig = evaluate { };
              custom = {
                warningThresholdGiB = 20;
                criticalThresholdGiB = 5;
              };
              valid = config: lib.all (entry: entry.assertion) config.assertions;
              packageValid =
                disk: (builtins.tryEval (mkCouchShellPackage pkgs { bar.disk = disk; }).drvPath).success;
              invalid = [
                {
                  warningThresholdGiB = 10;
                  criticalThresholdGiB = 10;
                }
                {
                  warningThresholdGiB = 10;
                  criticalThresholdGiB = 11;
                }
                { warningThresholdGiB = 0; }
                { criticalThresholdGiB = -1; }
                { warningThresholdGiB = 1.5; }
              ];
            in
            assert defaultConfig.programs.couch-shell.bar.disk.warningThresholdGiB == 50;
            assert defaultConfig.programs.couch-shell.bar.disk.criticalThresholdGiB == 10;
            assert valid defaultConfig && valid (evaluate custom);
            assert
              !(valid (evaluate {
                warningThresholdGiB = 10;
                criticalThresholdGiB = 10;
              }));
            assert packageValid { } && packageValid custom;
            assert lib.all (disk: !(packageValid disk)) invalid;
            assert lib.all (
              disk:
              !(builtins.tryEval (builtins.deepSeq (evaluate disk).programs.couch-shell.bar.disk true)).success
            ) (lib.drop 2 invalid);
            pkgs.runCommand "couch-shell-disk-config" { } ''touch "$out"'';
          package = self.packages.${system}.couch-shell;
          lint = mkCheck "couch-shell-lint" "${pkgs.bash}/bin/bash ./scripts/lint";
          test = mkCheck "couch-shell-test" "${pkgs.bash}/bin/bash ./scripts/test";
          formatting = (treefmtEval pkgs).config.build.check self;
          default = self.packages.${system}.couch-shell;
        }
        // import ./nix/btrfs-checks.nix { inherit pkgs lib; }
      );

      nixosModules.default = import ./nix/nixos.nix;

      homeManagerModules = {
        default = import ./nix/home-manager.nix self;
        couch-shell = import ./nix/home-manager.nix self;
      };

    };
}
