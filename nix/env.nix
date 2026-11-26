{
  pkgs,
}:
let
  markdownGuard = pkgs.callPackage ./markdown-guard.nix { };
  # Quickshell QML modules with Qt 6.12 opaque qmltypes stubs removed so qmllint
  # resolves the real types; see quickshell-qmltypes.nix.
  quickshellQmltypes = pkgs.callPackage ./quickshell-qmltypes.nix { };
  qmlPackages = [
    markdownGuard
    pkgs.qt6.qtdeclarative
    quickshellQmltypes
  ];

  qtPluginPackages = [
    pkgs.qt6.qtbase
    pkgs.qt6.qtdeclarative
    pkgs.qt6.qtsvg
    pkgs.quickshell
  ];

  qmlImportPath = pkgs.lib.makeSearchPathOutput "" pkgs.qt6.qtbase.qtQmlPrefix qmlPackages;
  qtPluginPath = pkgs.lib.makeSearchPathOutput "" pkgs.qt6.qtbase.qtPluginPrefix qtPluginPackages;
  fontconfigFile = pkgs.makeFontsConf {
    fontDirectories = [ pkgs.noto-fonts ];
  };
in
{
  inherit fontconfigFile qmlImportPath qtPluginPath;

  devPackages = with pkgs; [
    markdownGuard
    util-linux
    treefmt
    bash
    coreutils
    biome
    deadnix
    git
    just
    markdownlint-cli2
    mdformat
    nix
    nixfmt
    nodejs
    noto-fonts
    pkgs.quickshell
    pre-commit
    prek
    qt6.qtdeclarative
    qt6.qtsvg
    shellcheck
    statix
    wl-clipboard
  ];
}
