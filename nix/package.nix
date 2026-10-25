{
  lib,
  callPackage,
  util-linux,
  stdenvNoCC,
  makeWrapper,
  coreutils,
  makeFontsConf,
  nodejs,
  noto-fonts,
  quickshell,
  wl-clipboard,
  qt6,
  couchTasksCommand ? "ct",
  wallpaper ? "assets/coding-deck.png",
  fonts ? {
    proseFamily = "Inter";
    monoFamily = "CommitMono Nerd Font";
    codeFamily = "CommitMono Nerd Font";
    notificationToastFamily = "CommitMono Nerd Font";
    size = 12;
    aiPaneSize = 12;
    tasksPaneSize = 12;
    notificationToastSize = 12;
    packages = [ ];
  },
  theme ? {
    flavor = "latte";
  },
  bar ? {
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
  },
}:
let
  markdownGuard = callPackage ./markdown-guard.nix { };
  normalizedFonts = {
    proseFamily = lib.attrByPath [ "proseFamily" ] "Inter" fonts;
    monoFamily = lib.attrByPath [ "monoFamily" ] "CommitMono Nerd Font" fonts;
    codeFamily = lib.attrByPath [ "codeFamily" ] "CommitMono Nerd Font" fonts;
    notificationToastFamily = lib.attrByPath [ "notificationToastFamily" ] (lib.attrByPath [
      "monoFamily"
    ] "CommitMono Nerd Font" fonts) fonts;
    size = lib.attrByPath [ "size" ] 12 fonts;
    aiPaneSize = lib.attrByPath [ "aiPaneSize" ] (lib.attrByPath [ "size" ] 12 fonts) fonts;
    tasksPaneSize = lib.attrByPath [ "tasksPaneSize" ] (lib.attrByPath [ "size" ] 12 fonts) fonts;
    notificationToastSize = lib.attrByPath [ "notificationToastSize" ] (lib.attrByPath [
      "size"
    ] 12 fonts) fonts;
    packages = lib.attrByPath [ "packages" ] [ ] fonts;
  };
  normalizedTheme = {
    flavor = lib.attrByPath [ "flavor" ] "latte" theme;
  };
  catppuccinFlavors = [
    "latte"
    "frappe"
    "macchiato"
    "mocha"
  ];
  fontconfigFile = makeFontsConf {
    fontDirectories = [ noto-fonts ] ++ normalizedFonts.packages;
  };
  escapeQmlString = value: lib.replaceStrings [ "\\" "\"" ] [ "\\\\" "\\\"" ] value;
  fontSize = normalizedFonts.size;
  barHeight = lib.attrByPath [ "height" ] 20 bar;
  aiUsageProviders = [
    "chatgpt"
    "claude"
  ];
  aiUsageDefaultProvider = lib.attrByPath [ "aiUsage" "defaultProvider" ] "chatgpt" bar;
  aiUsageHoverProviderModes = [
    "all"
    "current"
  ];
  aiUsageHoverProviders = lib.attrByPath [ "aiUsage" "hoverProviders" ] "all" bar;
  aiUsageRefreshInterval = lib.attrByPath [ "aiUsage" "refreshInterval" ] 300 bar;
  btrfsInterval = lib.attrByPath [ "disk" "btrfs" "pollInterval" ] 300 bar;
  warningThresholdGiB = lib.attrByPath [ "disk" "warningThresholdGiB" ] 50 bar;
  criticalThresholdGiB = lib.attrByPath [ "disk" "criticalThresholdGiB" ] 10 bar;
  diskJson = builtins.toJSON {
    inherit warningThresholdGiB criticalThresholdGiB;
    btrfs = {
      enable = lib.attrByPath [ "disk" "btrfs" "enable" ] false bar;
      pollInterval = btrfsInterval;
    };
    textPath = lib.attrByPath [ "disk" "textPath" ] "/persist" bar;
    popupPaths =
      lib.attrByPath
        [ "disk" "popupPaths" ]
        [
          {
            name = "Persist";
            path = "/persist";
          }
          {
            name = "Ephemeral";
            path = "/";
          }
        ]
        bar;
  };
  temperatureTextPath = if bar.temperature.textPath == null then "" else bar.temperature.textPath;
  temperaturePopupPathsJson = builtins.toJSON bar.temperature.popupPaths;
  temperatureFanPathsJson = builtins.toJSON bar.temperature.fanPaths;
  qmlPackages = [
    markdownGuard
    qt6.qtdeclarative
    qt6.qtsvg
    quickshell
  ];
  qtPluginPackages = [
    qt6.qtbase
    qt6.qtdeclarative
    qt6.qtsvg
    quickshell
  ];
  qmlImportPath = lib.makeSearchPathOutput "" qt6.qtbase.qtQmlPrefix qmlPackages;
  qtPluginPath = lib.makeSearchPathOutput "" qt6.qtbase.qtPluginPrefix qtPluginPackages;
in
assert lib.assertMsg (lib.elem normalizedTheme.flavor catppuccinFlavors)
  "couch-shell: theme.flavor must be one of ${lib.concatStringsSep ", " catppuccinFlavors}";
assert lib.assertMsg (lib.elem aiUsageDefaultProvider aiUsageProviders)
  "couch-shell: bar.aiUsage.defaultProvider must be one of ${lib.concatStringsSep ", " aiUsageProviders}";
assert lib.assertMsg (lib.elem aiUsageHoverProviders aiUsageHoverProviderModes)
  "couch-shell: bar.aiUsage.hoverProviders must be one of ${lib.concatStringsSep ", " aiUsageHoverProviderModes}";
assert lib.assertMsg (
  builtins.isInt aiUsageRefreshInterval && aiUsageRefreshInterval > 0
) "couch-shell: bar.aiUsage.refreshInterval must be a positive integer";
assert lib.assertMsg (
  builtins.isInt btrfsInterval && btrfsInterval > 0
) "couch-shell: bar.disk.btrfs.pollInterval must be a positive integer";
assert lib.assertMsg
  (
    builtins.isInt warningThresholdGiB
    && warningThresholdGiB > 0
    && builtins.isInt criticalThresholdGiB
    && criticalThresholdGiB > 0
    && criticalThresholdGiB < warningThresholdGiB
  )
  "couch-shell: bar.disk thresholds must be positive integers with criticalThresholdGiB lower than warningThresholdGiB";
stdenvNoCC.mkDerivation {
  pname = "couch-shell";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./..;
    fileset = lib.fileset.unions [
      ./../animations
      ./../components
      ./../assets
      ./../lib
      ./../modules
      ./../services
      ./../theme
      ./../tools
      ./../ui
      ./../README.md
      ./../shell.qml
    ];
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    install -Dm644 "$src/shell.qml" "$out/etc/xdg/quickshell/couch-shell/shell.qml"
    install -Dm755 "$src/tools/couch-ai-codex.mjs" "$out/libexec/couch-shell/couch-ai-codex.mjs"

    install -Dm644 "$src/tools/btrfs/client.mjs" "$out/libexec/couch-shell/btrfs-client.mjs"
    makeWrapper ${nodejs}/bin/node "$out/bin/couch-shell-btrfs-client" \
      --add-flags "$out/libexec/couch-shell/btrfs-client.mjs"

    makeWrapper ${nodejs}/bin/node "$out/bin/couch-ai-codex" \
      --add-flags "$out/libexec/couch-shell/couch-ai-codex.mjs" \
      --prefix PATH : ${lib.makeBinPath [ util-linux ]}

    install -Dm644 /dev/stdin "$out/share/applications/io.github.burnskp.couchshell.desktop" <<'EOF'
    [Desktop Entry]
    Version=1.5
    Type=Application
    Name=couch-shell
    NoDisplay=true
    Exec=couch-shell
    EOF

    for path in animations assets components lib modules services theme ui; do
      if [ -e "$src/$path" ]; then
        cp -r "$src/$path" "$out/etc/xdg/quickshell/couch-shell/"
      fi
    done

    substituteInPlace "$out/etc/xdg/quickshell/couch-shell/services/ShellConfig.qml" \
      --replace-fail '__DESKTOP_WALLPAPER__' '${escapeQmlString wallpaper}' \
      --replace-fail '__AI_CODEX_HELPER__' "$out/bin/couch-ai-codex" \
      --replace-fail '__COUCH_TASKS_COMMAND__' '${escapeQmlString couchTasksCommand}' \
      --replace-fail '__CATPPUCCIN_FLAVOR__' '${escapeQmlString normalizedTheme.flavor}' \
      --replace-fail '__FONT_PROSE_FAMILY__' '${escapeQmlString normalizedFonts.proseFamily}' \
      --replace-fail '__FONT_MONO_FAMILY__' '${escapeQmlString normalizedFonts.monoFamily}' \
      --replace-fail '__FONT_CODE_FAMILY__' '${escapeQmlString normalizedFonts.codeFamily}' \
      --replace-fail '__NOTIFICATION_TOAST_FONT_FAMILY__' '${escapeQmlString normalizedFonts.notificationToastFamily}' \
      --replace-fail '__FONT_SIZE__' '${toString fontSize}' \
      --replace-fail '__AI_PANE_FONT_SIZE__' '${toString normalizedFonts.aiPaneSize}' \
      --replace-fail '__TASKS_PANE_FONT_SIZE__' '${toString normalizedFonts.tasksPaneSize}' \
      --replace-fail '__NOTIFICATION_TOAST_FONT_SIZE__' '${toString normalizedFonts.notificationToastSize}' \
      --replace-fail '__BTRFS_CLIENT__' "$out/bin/couch-shell-btrfs-client" \
      --replace-fail '__BAR_DISK_JSON__' ${lib.escapeShellArg (escapeQmlString diskJson)} \
      --replace-fail '__BAR_HEIGHT__' '${toString barHeight}' \
      --replace-fail '__AI_USAGE_DEFAULT_PROVIDER__' '${aiUsageDefaultProvider}' \
      --replace-fail '__AI_USAGE_HOVER_PROVIDERS__' '${aiUsageHoverProviders}' \
      --replace-fail '__AI_USAGE_REFRESH_INTERVAL__' '${toString aiUsageRefreshInterval}' \
      --replace-fail '__BAR_TEMPERATURE_ENABLE__' '${
        if bar.temperature.enable then "true" else "false"
      }' \
      --replace-fail '__BAR_TEMPERATURE_TEXT_PATH__' '${escapeQmlString temperatureTextPath}' \
      --replace-fail '__BAR_TEMPERATURE_POPUP_PATHS__' '${escapeQmlString temperaturePopupPathsJson}' \
      --replace-fail '__BAR_TEMPERATURE_FAN_PATHS__' '${escapeQmlString temperatureFanPathsJson}'

    makeWrapper ${lib.getExe quickshell} "$out/bin/couch-shell" \
      --set FONTCONFIG_FILE "${fontconfigFile}" \
      --set QML_IMPORT_PATH "${qmlImportPath}" \
      --set QT_PLUGIN_PATH "${qtPluginPath}" \
      --set COUCH_SHELL_CODEX_HELPER "$out/bin/couch-ai-codex" \
      --prefix PATH : ${
        lib.makeBinPath [
          wl-clipboard
          coreutils
        ]
      } \
      --prefix XDG_CONFIG_DIRS : "$out/etc/xdg" \
      --prefix XDG_DATA_DIRS : "$out/share" \
      --add-flags "-c couch-shell"

    runHook postInstall
  '';

  doInstallCheck = true;
  installCheckPhase = ''
    runHook preInstallCheck

    grep -F "$out/etc/xdg" "$out/bin/couch-shell" >/dev/null
    grep -F "$out/share" "$out/bin/couch-shell" >/dev/null
    grep -F "$out/bin/couch-ai-codex" "$out/bin/couch-shell" >/dev/null
    "$out/bin/couch-ai-codex" auth-path >/dev/null
    ! grep -F '$out/etc/xdg' "$out/bin/couch-shell" >/dev/null
    ! grep -F '$out/share' "$out/bin/couch-shell" >/dev/null

    runHook postInstallCheck
  '';

  meta = {
    description = "A small Quickshell-based Hyprland shell";
    homepage = "https://github.com/burnskp/couch-shell";
    license = lib.licenses.mit;
    mainProgram = "couch-shell";
    platforms = lib.platforms.linux;
  };
}
