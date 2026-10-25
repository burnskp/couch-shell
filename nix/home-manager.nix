self:
{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.programs.couch-shell;
  inherit (self.lib) defaults;
  defaultPackage = self.lib.mkCouchShellPackage {
    inherit pkgs;
    fonts = {
      inherit (cfg.fonts)
        proseFamily
        monoFamily
        codeFamily
        notificationToastFamily
        size
        aiPaneSize
        tasksPaneSize
        notificationToastSize
        packages
        ;
    };
    theme = {
      inherit (cfg.theme) flavor;
    };
    bar = {
      inherit (cfg.bar) height disk aiUsage;
      temperature = {
        inherit (cfg.bar.temperature)
          enable
          textPath
          ;
        popupPaths =
          if cfg.bar.temperature.popupPaths == null then
            defaults.bar.temperature.popupPaths
          else
            cfg.bar.temperature.popupPaths;
        fanPaths =
          if cfg.bar.temperature.fanPaths == null then
            defaults.bar.temperature.fanPaths
          else
            cfg.bar.temperature.fanPaths;
      };
    };
  };
in
{
  options.programs.couch-shell = {
    enable = lib.mkEnableOption "the couch-shell quickshell package";

    package = lib.mkOption {
      type = lib.types.package;
      default = defaultPackage;
      description = "The couch-shell package to install.";
    };

    fonts = {
      proseFamily = lib.mkOption {
        type = lib.types.str;
        default = defaults.fonts.proseFamily;
        description = "Font family used for prose text fields and markdown body text.";
      };

      monoFamily = lib.mkOption {
        type = lib.types.str;
        default = defaults.fonts.monoFamily;
        description = "Monospace font family used by the shell and as the default code font.";
      };

      codeFamily = lib.mkOption {
        type = lib.types.str;
        default = defaults.fonts.codeFamily;
        description = "Font family used for markdown code blocks.";
      };

      notificationToastFamily = lib.mkOption {
        type = lib.types.str;
        default = defaults.fonts.notificationToastFamily;
        description = "Font family used for notification toasts.";
      };

      size = lib.mkOption {
        type = lib.types.ints.between 6 48;
        default = defaults.fonts.size;
        description = "Base shell font size in pixels.";
      };

      aiPaneSize = lib.mkOption {
        type = lib.types.ints.between 6 48;
        default = defaults.fonts.aiPaneSize;
        description = "Font size in pixels for the AI pane.";
      };

      tasksPaneSize = lib.mkOption {
        type = lib.types.ints.between 6 48;
        default = defaults.fonts.tasksPaneSize;
        description = "Font size in pixels for the tasks pane.";
      };

      notificationToastSize = lib.mkOption {
        type = lib.types.ints.between 6 48;
        default = defaults.fonts.notificationToastSize;
        description = "Font size in pixels for notification toasts.";
      };

      packages = lib.mkOption {
        type = lib.types.listOf lib.types.package;
        default = defaults.fonts.packages;
        description = "Additional font packages added to the couch-shell fontconfig file.";
        example = lib.literalExpression "[ pkgs.inter pkgs.nerd-fonts.jetbrains-mono ]";
      };
    };

    theme = {
      flavor = lib.mkOption {
        type = lib.types.enum [
          "latte"
          "frappe"
          "macchiato"
          "mocha"
        ];
        default = defaults.theme.flavor;
        description = "Catppuccin flavor used for the shell palette.";
      };
    };

    bar = {
      height = lib.mkOption {
        type = lib.types.ints.positive;
        default = defaults.bar.height;
        description = "Height of the top bar in pixels.";
      };

      aiUsage = {
        defaultProvider = lib.mkOption {
          type = lib.types.enum [
            "chatgpt"
            "claude"
          ];
          default = defaults.bar.aiUsage.defaultProvider;
          description = "AI subscription shown in the bar usage chip when the shell starts. Clicking the chip switches it until the next restart.";
        };

        hoverProviders = lib.mkOption {
          type = lib.types.enum [
            "all"
            "current"
          ];
          default = defaults.bar.aiUsage.hoverProviders;
          description = "Whether the AI usage hover lists every AI subscription or only the one shown in the chip.";
        };

        refreshInterval = lib.mkOption {
          type = lib.types.ints.positive;
          default = defaults.bar.aiUsage.refreshInterval;
          description = "Seconds between visible-bar AI subscription usage requests.";
        };
      };

      disk = {
        warningThresholdGiB = lib.mkOption {
          type = lib.types.ints.positive;
          default = defaults.bar.disk.warningThresholdGiB;
          description = "Warn when the widget filesystem has less than this many GiB available.";
        };
        criticalThresholdGiB = lib.mkOption {
          type = lib.types.ints.positive;
          default = defaults.bar.disk.criticalThresholdGiB;
          description = "Critical available-space threshold in GiB. Must be lower than warningThresholdGiB.";
        };
        btrfs = {
          enable = lib.mkEnableOption "automatic Btrfs discovery in the disk hover";
          pollInterval = lib.mkOption {
            type = lib.types.ints.positive;
            default = 300;
            description = "Seconds between visible-bar Btrfs requests. Requires the system collector.";
          };
        };
        textPath = lib.mkOption {
          type = lib.types.str;
          default = defaults.bar.disk.textPath;
          description = "Path whose containing filesystem supplies available space in the disk widget.";
        };

        popupPaths = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                name = lib.mkOption {
                  type = lib.types.str;
                  description = "Filesystem label in the disk popup.";
                };
                path = lib.mkOption {
                  type = lib.types.str;
                  description = "Path identifying the containing filesystem.";
                };
              };
            }
          );
          default = defaults.bar.disk.popupPaths;
          description = "Ordered named filesystems in the disk popup. Replaces the defaults; an empty list disables the manual popup. Ignored when Btrfs discovery is enabled.";
        };
      };

      temperature = {
        enable = lib.mkOption {
          type = lib.types.bool;
          default = defaults.bar.temperature.enable;
          description = "Whether to show the bar temperature widget.";
        };

        textPath = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = defaults.bar.temperature.textPath;
          description = "Primary temperature sensor for the widget text. Use the full sysfs sensor path, such as `/sys/class/hwmon/hwmon7/temp1_input`.";
        };

        popupPaths = lib.mkOption {
          type = lib.types.nullOr (lib.types.attrsOf (lib.types.nullOr lib.types.str));
          default = null;
          defaultText = lib.literalExpression "self.lib.defaults.bar.temperature.popupPaths";
          description = "Named temperature sensors shown in the widget hover popup. When set, this replaces the default sensor set. Values should be full sysfs sensor paths, such as `/sys/class/hwmon/hwmon7/temp2_input`.";
        };

        fanPaths = lib.mkOption {
          type = lib.types.nullOr (lib.types.attrsOf (lib.types.nullOr lib.types.str));
          default = null;
          defaultText = lib.literalExpression "self.lib.defaults.bar.temperature.fanPaths";
          description = "Named fan sensors shown in the widget hover popup. When set, this replaces the default sensor set. Values should be full sysfs sensor paths, such as `/sys/class/hwmon/hwmon7/fan1_input`.";
        };
      };
    };

    systemd = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
        description = "Whether to autostart couch-shell as a user service.";
      };

      target = lib.mkOption {
        type = lib.types.str;
        default = "graphical-session.target";
        description = "The systemd user target that should start couch-shell.";
      };

      environment = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [ ];
        description = "Extra environment variables passed to the couch-shell service.";
        example = [ "QT_QPA_PLATFORM=wayland" ];
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.bar.disk.criticalThresholdGiB < cfg.bar.disk.warningThresholdGiB;
        message = "couch-shell: bar.disk.criticalThresholdGiB must be lower than warningThresholdGiB";
      }
    ];
    home.packages = [ cfg.package ];

    systemd.user.services.couch-shell = lib.mkIf cfg.systemd.enable {
      Unit = {
        Description = "couch-shell";
        After = [ cfg.systemd.target ];
        PartOf = [ cfg.systemd.target ];
      };

      Service = {
        ExecStart = "${lib.getExe cfg.package}";
        Restart = "on-failure";
        RestartSec = "2s";
        Environment = cfg.systemd.environment;
      };

      Install = {
        WantedBy = [ cfg.systemd.target ];
      };
    };
  };
}
