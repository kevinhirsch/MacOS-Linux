#!/usr/bin/env bash
# =============================================================================
#  Tahoe Liquid Glass — Ubuntu / KDE Plasma   install.sh
# =============================================================================
#  ONE script, works on BOTH targets (auto-detected via lib/plasma-tools.sh):
#    • Plasma 5.27  (Ubuntu 24.04, alongside GNOME) → Phase A: static + frost
#    • Plasma 6     (Kubuntu 26 dual-boot)          → Phase A + Phase B: refraction
#  Idempotent and reversible. Does NOT touch your GNOME session — it only writes
#  Plasma config, which GNOME ignores. Log into "Plasma (X11)" to see it.
#
#  Layers applied:
#    03-theme    Kvantum widget theme + Aurorae traffic-lights + color-schemes
#    04-configs  global menu, floating dock, SF Pro, wallpaper, auto light/dark
#    frost       stock KWin Blur behind translucent surfaces (Phase A; both OSes)
#    glass       (Plasma 6 only) builds + enables the KWin 6 refraction effect (Phase B)
#
#  Usage:
#    ./install.sh                 full install (Phase A; +Phase B automatically on Plasma 6)
#    ./install.sh --theme-only    03-theme only
#    ./install.sh --configs-only  04-configs only
#    ./install.sh --no-base       skip cloning/installing the MacTahoe-kde base
#    ./install.sh --no-frost      skip enabling stock KWin blur (Phase-A frost)
#    ./install.sh --glass-deps    (Plasma 6) apt-install the KWin-effect build deps first
#    ./install.sh --no-glass      skip the Phase-B refraction effect build
#    ./install.sh --uninstall     restore backed-up Plasma config + disable frost/glass
#    ./install.sh --dry-run       print steps, change nothing
# =============================================================================
set -euo pipefail

HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=lib/plasma-tools.sh
source "$HERE/lib/plasma-tools.sh"

STATE="${XDG_STATE_HOME:-$HOME/.local/state}/tahoe-liquid-glass"
BACKUP="$STATE/backup"
CFG="${XDG_CONFIG_HOME:-$HOME/.config}"

DRYRUN=0; DO_BASE=1; DO_THEME=1; DO_CONFIGS=1; DO_FROST=1; DO_GLASS=1; GLASS_DEPS=0; UNINSTALL=0

c() { printf '\033[%sm' "$1"; }
log()  { printf "$(c '1;36')==>$(c 0) %s\n" "$*"; }
step() { printf "$(c '1;35') · $(c 0)%s\n" "$*"; }
warn() { printf "$(c '1;33')!! $(c 0)%s\n" "$*" >&2; }
die()  { printf "$(c '1;31')xx $(c 0)%s\n" "$*" >&2; exit 1; }
run()  { if (( DRYRUN )); then printf '   [dry] %s\n' "$*"; else "$@"; fi; }

usage() { sed -n '2,34p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//'; exit 0; }

while (( $# )); do
  case "$1" in
    --dry-run)      DRYRUN=1 ;;
    --no-base)      DO_BASE=0 ;;
    --no-frost)     DO_FROST=0 ;;
    --no-glass)     DO_GLASS=0 ;;
    --glass-deps)   GLASS_DEPS=1 ;;
    --theme-only)   DO_BASE=0; DO_CONFIGS=0; DO_FROST=0; DO_GLASS=0 ;;
    --configs-only) DO_BASE=0; DO_THEME=0 ;;
    --uninstall)    UNINSTALL=1 ;;
    -h|--help)      usage ;;
    *) die "unknown flag: $1  (try --help)" ;;
  esac
  shift
done

# --- Plasma config files this package writes to (for backup / restore) -------
TOUCHED=(kdeglobals kwinrc kwinrulesrc plasmarc breezerc
         kglobalshortcutsrc plasma-org.kde.plasma.desktop-appletsrc
         Kvantum/kvantum.kvconfig)

backup_once() {
  [[ -f "$BACKUP/.stamp" ]] && { step "config backup already exists ($BACKUP)"; return; }
  run mkdir -p "$BACKUP"
  local f
  for f in "${TOUCHED[@]}"; do
    if [[ -f "$CFG/$f" ]]; then
      run mkdir -p "$BACKUP/$(dirname "$f")"
      run cp -a "$CFG/$f" "$BACKUP/$f"
    fi
  done
  (( DRYRUN )) || : > "$BACKUP/.stamp"
  step "backed up existing Plasma config → $BACKUP"
}

preflight() {
  [[ -n "${KWRITECONFIG:-}" ]] || die "kwriteconfig (5 or 6) not found — is kde-plasma-desktop installed?"
  command -v plasma-apply-lookandfeel >/dev/null || die "plasma-apply-lookandfeel not found."
  log "Plasma generation detected: $PLASMA_GEN   (kwriteconfig: ${KWRITECONFIG##*/})"
  local cur="${XDG_CURRENT_DESKTOP:-}"
  if [[ "$cur" != *KDE* && "$cur" != *PLASMA* ]]; then
    warn "You're not in a Plasma session (\$XDG_CURRENT_DESKTOP=$cur)."
    warn "That's fine — config is written now and takes effect when you log into 'Plasma (X11)'."
  fi
}

phase_base() {
  log "Base — installing vinceliuice/MacTahoe-kde (light + dark, all scales)"
  run bash "$HERE/03-theme/install-base.sh"
}

phase_theme() {
  log "Theme — Kvantum overrides · Aurorae traffic-lights · color-schemes"
  run bash "$HERE/03-theme/apply-kvantum-overrides.sh"
  run bash "$HERE/03-theme/aurorae/apply-aurorae.sh"
  run bash "$HERE/03-theme/color-schemes/install-colors.sh"
}

phase_configs() {
  log "Configs — look&feel · global menu · dock · fonts · wallpaper · auto light/dark · a11y"
  local s
  for s in 00-apply-lookandfeel 10-global-menu 20-dock-panel 30-fonts \
           40-wallpaper 50-auto-light-dark 60-a11y; do
    local p="$HERE/04-configs/$s.sh"
    [[ -f "$p" ]] || { warn "missing $s.sh (skipping)"; continue; }
    step "$s"
    run bash "$p"
  done
}

phase_frost() {
  # Phase-A glass: stock KWin Blur behind translucent surfaces. Kvantum already
  # marks its surfaces translucent + blur-region (see 03-theme kvconfig overrides);
  # here we just make sure the compositor's Blur effect is on.
  log "Frost — enabling stock KWin Blur (real frosted glass behind windows/menus)"
  run "$KWRITECONFIG" --file kwinrc --group Plugins --key blurEnabled true
  run "$KWRITECONFIG" --file kwinrc --group Plugins --key contrastEnabled true
  # Reload KWin if it's live (no-op / harmless outside a Plasma session).
  if [[ -n "${QDBUS:-}" ]]; then
    run "$QDBUS" org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
  fi
}

phase_glass() {
  # Phase B — the refraction lens. Needs Plasma 6 / KWin 6 (Kubuntu 26). On Plasma
  # 5.27 there is no viable effect API, so we skip and leave stock-blur frost active.
  local ED="$HERE/02-glass-effect"
  if [[ "$PLASMA_GEN" != "6" ]]; then
    log "Glass — Phase B (refraction) needs Plasma 6 / KWin 6; you're on Plasma $PLASMA_GEN"
    step "skipping the KWin effect build; stock-blur frost (Phase A) stays active"
    step "on your Kubuntu 26 dual-boot this SAME command builds + enables it automatically"
    return 0
  fi
  log "Glass — Phase B — building the KWin 6 Liquid Glass effect (refraction)"
  if ! command -v cmake >/dev/null 2>&1 || { [[ ! -d /usr/include/kwin ]] && ! pkg-config --exists kwin 2>/dev/null; }; then
    if (( GLASS_DEPS )); then
      step "installing KWin 6 build dependencies (apt)"
      run sudo apt-get install -y git cmake g++ extra-cmake-modules qt6-tools-dev kwin-dev \
        libkf6configwidgets-dev gettext libkf6kcmutils-dev libkdecorations3-dev libepoxy-dev \
        || { warn "dependency install failed; leaving stock-blur frost active"; return 0; }
    else
      warn "KWin 6 build tools/headers not found."
      warn "Re-run with --glass-deps to apt-install them (see 02-glass-effect/README.md §3)."
      warn "Stock-blur frost stays active meanwhile."
      return 0
    fi
  fi
  if (( DRYRUN )); then
    step "[dry] cmake build + sudo make install in $ED"
  else
    ( set -e; rm -rf "$ED/build"; mkdir "$ED/build"; cd "$ED/build"
      cmake .. -DCMAKE_INSTALL_PREFIX=/usr; make -j"$(nproc)"; sudo make install ) \
      || { warn "glass effect build failed (see 02-glass-effect/README.md); stock-blur frost stays active"; return 0; }
  fi
  step "enabling 'Tahoe Liquid Glass' effect; disabling stock blur (they conflict)"
  run "$KWRITECONFIG" --file kwinrc --group Plugins --key tahoe_liquid_glassEnabled true
  run "$KWRITECONFIG" --file kwinrc --group Plugins --key blurEnabled false
  [[ -n "${QDBUS:-}" ]] && run "$QDBUS" org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
  step "Phase B active: refraction glass on panels / menus / docks."
}

do_install() {
  preflight
  backup_once
  (( DO_BASE ))    && phase_base
  (( DO_THEME ))   && phase_theme
  (( DO_CONFIGS )) && phase_configs
  (( DO_FROST ))   && phase_frost
  (( DO_GLASS ))   && phase_glass
  log "Done. Log out and pick the 'Plasma (X11)' session (Plasma $PLASMA_GEN) to see it."
  step "Parity loop next: dock → toolbar → Settings window (render · compare · tune)."
}

do_uninstall() {
  log "Uninstall — restoring backed-up Plasma config"
  [[ -d "$BACKUP" ]] || die "no backup found at $BACKUP (nothing to restore)."
  local f
  for f in "${TOUCHED[@]}"; do
    if [[ -f "$BACKUP/$f" ]]; then
      run mkdir -p "$CFG/$(dirname "$f")"
      run cp -a "$BACKUP/$f" "$CFG/$f"
      step "restored $f"
    fi
  done
  # turn our effects back off explicitly in case they weren't in the backup
  run "$KWRITECONFIG" --file kwinrc --group Plugins --key blurEnabled false
  run "$KWRITECONFIG" --file kwinrc --group Plugins --key tahoe_liquid_glassEnabled false
  [[ -n "${QDBUS:-}" ]] && run "$QDBUS" org.kde.KWin /KWin reconfigure >/dev/null 2>&1 || true
  warn "Installed theme dirs (~/.local/share/{color-schemes,aurorae,Kvantum,plasma}) were left in place."
  warn "Remove them by hand if you want a full teardown; they're inert unless selected."
  log "Restore complete. Your Plasma config is back to the pre-install snapshot."
}

if (( UNINSTALL )); then do_uninstall; else do_install; fi
