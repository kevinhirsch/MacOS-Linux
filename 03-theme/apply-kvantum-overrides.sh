#!/usr/bin/env bash
# 03-theme/apply-kvantum-overrides.sh
# Merge the Tahoe-Liquid-Glass override keys into the INSTALLED MacTahoe
# kvconfig files, using ${KWRITECONFIG:-kwriteconfig5} (kvconfig is INI, so this is safe and
# preserves every upstream [Widget] section we don't touch).
#
# Run AFTER install-base.sh. Idempotent.
set -euo pipefail
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

KV_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/Kvantum/MacTahoe"
[[ -d "$KV_DIR" ]] || { echo "!! $KV_DIR missing — run install-base.sh first"; exit 1; }

# Parse an override file (INI with '#'/';' comments) and replay every
# 'group/key=value' into the target kvconfig via ${KWRITECONFIG:-kwriteconfig5}.
merge_override() {
  local override="$1" target="$2" group=""
  echo "==> Merging $(basename "$override") -> $target"
  while IFS= read -r line || [[ -n "$line" ]]; do
    line="${line%%$'\r'}"
    case "$line" in
      ''|'#'*|';'*) continue ;;
      '['*']')
        group="${line#[}"; group="${group%]}"
        continue ;;
      *'='*)
        local key="${line%%=*}" val="${line#*=}"
        # trim surrounding whitespace
        key="${key#"${key%%[![:space:]]*}"}"; key="${key%"${key##*[![:space:]]}"}"
        ${KWRITECONFIG:-kwriteconfig5} --file "$target" --group "$group" --key "$key" "$val"
        ;;
    esac
  done < "$override"
}

merge_override "$HERE/kvantum/MacTahoe.kvconfig.override"     "$KV_DIR/MacTahoe.kvconfig"
merge_override "$HERE/kvantum/MacTahoeDark.kvconfig.override" "$KV_DIR/MacTahoeDark.kvconfig"

# Point Kvantum at the theme (kvantummanager also does this; we do it headless).
KVANTUM_RC="${XDG_CONFIG_HOME:-$HOME/.config}/Kvantum/kvantum.kvconfig"
${KWRITECONFIG:-kwriteconfig5} --file "$KVANTUM_RC" --group General --key theme "MacTahoe"

# Make Qt use Kvantum as the platform style so all of this takes effect.
${KWRITECONFIG:-kwriteconfig5} --file kdeglobals --group KDE --key widgetStyle "kvantum"

echo "==> Kvantum overrides applied. Theme=MacTahoe (light=MacTahoe / dark=MacTahoeDark)."
echo "    The auto light/dark switcher (04-configs) flips the Kvantum theme key"
echo "    between MacTahoe and MacTahoeDark alongside the color scheme."
