#!/usr/bin/env bash
# lib/plasma-tools.sh
# Resolve the KDE/Plasma CLI tools for whichever Plasma generation is installed
# (Plasma 6 -> *6 binaries; Plasma 5.27 -> *5 binaries) so the SAME package runs
# on both. Ubuntu 24.04 ships Plasma 5.27; a later move to Plasma 6 needs no edits.
#
# Source this file; it exports KWRITECONFIG KREADCONFIG KPACKAGETOOL QDBUS PLASMA_GEN.

_tlg_resolve() {
  local c
  for c in "$@"; do
    if command -v "$c" >/dev/null 2>&1; then command -v "$c"; return 0; fi
  done
  return 1
}

export KWRITECONFIG="$(_tlg_resolve kwriteconfig6 kwriteconfig5 || true)"
export KREADCONFIG="$(_tlg_resolve kreadconfig6 kreadconfig5 || true)"
export KPACKAGETOOL="$(_tlg_resolve kpackagetool6 kpackagetool5 || true)"
export QDBUS="$(_tlg_resolve qdbus6 qdbus-qt6 qdbus || true)"

case "${KWRITECONFIG:-}" in
  *6) export PLASMA_GEN=6 ;;
  *)  export PLASMA_GEN=5 ;;
esac
