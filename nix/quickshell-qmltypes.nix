# Quickshell's QML module tree with tooling-only qmltypes fixes applied.
#
# Since Qt 6.12, qmltyperegistrar emits one-line opaque stubs such as
#   Component { isTypeOpaque: true; name: "UntypedObjectModel"; accessSemantics: "value" }
# into each module's qmltypes for foreign types it cannot see. qmllint then
# resolves those names to the empty stub instead of the real type declared in
# another Quickshell module (PopupAnchor, UntypedObjectModel, ...), producing
# false positives like `Could not find property "item"` on `PopupWindow.anchor`.
#
# This derivation copies the upstream module tree (~500K; a real copy rather
# than symlinks, because qmllint follows a symlinked qmldir back to the original
# directory and would load the unpatched qmltypes) and rewrites only the
# qmltypes files, dropping one-line opaque stubs whose name is declared as a
# real component elsewhere in the tree. qmldir and .qml files are unchanged,
# and the runtime (which never reads qmltypes) behaves exactly as upstream.
{
  gawk,
  quickshell,
  qt6,
  runCommand,
}:
let
  qmlPrefix = qt6.qtbase.qtQmlPrefix;
in
runCommand "quickshell-qmltypes-${quickshell.version}"
  {
    nativeBuildInputs = [ gawk ];
  }
  ''
    src=${quickshell}/${qmlPrefix}
    dest=$out/${qmlPrefix}
    mkdir -p "$dest"
    cp -rL "$src/." "$dest/"
    chmod -R u+w "$dest"

    mapfile -t typesFiles < <(find "$dest" -name '*.qmltypes')

    # Names of real (non-opaque) components declared anywhere in the tree.
    realNames="$TMPDIR/real-names"
    awk '
      /^        isTypeOpaque: true$/ { opaque = 1; next }
      /^    Component \{$/ { opaque = 0; next }
      /^        name: "/ {
        if (!opaque) { split($0, parts, "\""); print parts[2] }
      }
    ' "''${typesFiles[@]}" | sort -u > "$realNames"

    for file in "''${typesFiles[@]}"; do
      awk -v namesFile="$realNames" '
        BEGIN { while ((getline name < namesFile) > 0) real[name] = 1 }
        /^    Component \{ isTypeOpaque: true; name: "[^"]+"; accessSemantics: "value" \}$/ {
          split($0, parts, "\"")
          if (parts[2] in real) next
        }
        { print }
      ' "$file" > "$file.tmp"
      rm "$file"
      mv "$file.tmp" "$file"
    done
  ''
