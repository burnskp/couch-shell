{
  stdenv,
  cmake,
  qt6,
}:
stdenv.mkDerivation {
  pname = "couch-shell-markdown-guard";
  version = "0.1.0";
  src = ../native/markdown-guard;
  nativeBuildInputs = [ cmake ];
  buildInputs = [
    qt6.qtbase
    qt6.qtdeclarative
  ];
  dontWrapQtApps = true;
}
