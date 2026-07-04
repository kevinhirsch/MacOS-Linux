# 04-configs — Tahoe · Plasma 6 config layer

Real `kwriteconfig6` / `plasma-apply-*` commands and drop-in files that wire the desktop into the
macOS Tahoe shape, on top of the `03-theme` layer.

Run order (after `03-theme`):

```bash
./00-apply-lookandfeel.sh     # set the global theme + Kvantum style baseline
./10-global-menu.sh           # top menu bar applet + GTK app menu export
./20-dock-panel.sh            # floating icons-only dock (48px), bottom-center
./30-fonts.sh                 # SF Pro Text UI font + fontconfig + type ramp
./40-wallpaper.sh             # Tahoe-Beach wallpaper (day/dark aware)
./50-auto-light-dark.sh install   # sun-based auto switcher (systemd --user + astral)
./60-a11y.sh status           # reduce-transparency / contrast / motion hooks
```

| File                     | What it does                                                                 |
|--------------------------|------------------------------------------------------------------------------|
| `00-apply-lookandfeel.sh`| `plasma-apply-lookandfeel` to the MacTahoe global theme (dark by default).    |
| `10-global-menu.sh`      | Adds `org.kde.plasma.appmenu` to a top panel; sets `menuBar=Widget` in kwinrc; installs `environment.d` snippet so GTK apps export their menu (`appmenu-gtk-module`, App/File/Edit order preserved by the app). |
| `20-dock-panel.sh`       | Writes a floating, icons-only Plasma panel (Icons-only Task Manager, 48px icons, centered, auto-hide optional) into `plasma-org.kde.plasma.desktop-appletsrc`. |
| `30-fonts.sh`            | `kwriteconfig6 kdeglobals [General]` font keys to SF Pro Text at the macOS type ramp; installs a fontconfig alias so `SF Pro Text` resolves. |
| `40-wallpaper.sh`        | `plasma-apply-wallpaperimage` to the MacTahoe "Tahoe-Beach" wallpaper (ships day + dark variants). |
| `50-auto-light-dark.sh`  | Installs `tahoe-theme-switch` (Python + astral, Phoenix coords) and a `systemd --user` timer that runs `plasma-apply-colorscheme` + `plasma-apply-lookandfeel` at sunrise/sunset. |
| `60-a11y.sh`             | Toggles reduce-transparency (Kvantum + Plasma blur off), increased-contrast scheme, and reduce-motion (KWin animation speed) — each independently. |
| `files/`                 | Static drop-in files referenced by the scripts (environment.d snippet, systemd units, python switcher, dock applet fragment, fontconfig). |

## Notes on correctness (Plasma 6, verified Jul 2026)

- `kwriteconfig6` is the Plasma 6 tool (was `kwriteconfig5`). Group with square brackets in the name
  (like `org.kde.kdecoration2`) is passed verbatim to `--group`.
- Applying live config: `qdbus6 org.kde.KWin /KWin reconfigure` for KWin; for the shell,
  `plasmashell --replace &` or log out/in. The scripts prefer the least-disruptive reload available.
- The global menu needs BOTH the applet (Qt/KDE apps talk DBus menu natively) AND
  `appmenu-gtk-module` + `UBUNTU_MENUPROXY=1` in the environment for GTK apps.
