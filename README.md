# Workspace OSD

A giant, theme-aware number that flashes in the center of the screen whenever
the active Hyprland workspace changes — for [Omarchy](https://omarchy.org/)
(Quickshell) on Arch Linux.

It replaces the usual tiny OSD with a large number, and is fully configurable
from a settings panel: on-screen time, fade, size, opacity, **shape**
(rectangle / rounded / circle) and **border**.

## Preview

<!-- Add a preview.png at the repository root to have it picked up by the
     Omarchy marketplace. A screenshot of the OSD on the desktop is ideal. -->

## Features

- Large centered workspace number on every workspace change.
- Theme-aware: uses the active Omarchy theme (`Color.accent` for the number,
  `Color.background` for the card, `popups.border` for the outline). Switches
  live with the theme.
- Selectable shape: `rectangle`, `rounded`, `circle`.
- Optional border. When the border is off, only the number is drawn (fully
  transparent background).
- Adjustable duration, fade-in, reopen delay, glyph size and opacity.
- Preferences live in a dedicated TOML file (hot-reloaded) and a built-in
  settings panel.

## Requirements

- Omarchy (uses `omarchy-shell` / Quickshell and the `qs.Commons` / `qs.Ui`
  singletons).
- Hyprland.
- No external dependencies.

## Install

```bash
omarchy plugin add https://github.com/iesta/omarchy-workspace-osd --enable
```

Then restart the shell so the panel mounts:

```bash
omarchy restart shell
```

## Usage

The OSD shows automatically. To open its settings:

```bash
omarchy-shell shell call iesta.workspace-osd openSettings '{}'
```

or from the Omarchy menu: **Workspace OSD → Settings**.

Close the settings panel:

```bash
omarchy-shell shell call iesta.workspace-osd closeSettings '{}'
```

## Configuration

Preferences are stored in:

`~/.config/omarchy/workspace-osd.toml`

created automatically on first run. It is read live (edits apply without a
restart).

```toml
# shape: rectangle | rounded | circle
[workspace-osd]
duration = 750        # ms the number stays on screen
fade = 60             # fade-in duration, ms
reopen = 0            # delay before re-opening on rapid workspace changes, ms
size-multiplier = 8   # glyph size = base font size x N
opacity = 0.82        # card background opacity (only when border = true)
shape = "rounded"     # rectangle | rounded | circle
border = false        # false => no outline, transparent background
```

| Key | Type | Default | Meaning |
|---|---|---|---|
| `duration` | int (ms) | `750` | On-screen time |
| `fade` | int (ms) | `60` | Fade-in duration |
| `reopen` | int (ms) | `0` | Reopen delay |
| `size-multiplier` | number | `7` | Glyph size multiplier |
| `opacity` | number (0–1) | `0.82` | Card opacity (bordered only) |
| `shape` | enum | `rounded` | `rectangle`, `rounded`, `circle` |
| `border` | bool | `false` | Draw outline + card |

## Remove

```bash
omarchy plugin remove iesta.workspace-osd
```

Your config file at `~/.config/omarchy/workspace-osd.toml` is left in place;
delete it manually if you no longer need it.

## Files

| File | Purpose |
|---|---|
| `manifest.json` | Plugin manifest (kind `panel`, `keepLoaded`) |
| `WorkspaceOsd.qml` | OSD overlay, preference loading/persistence, IPC |
| `WorkspaceOsdSettings.qml` | Settings modal |
| `Config.js` | TOML parse/serialize + defaults |

## License

MIT — see [LICENSE](LICENSE).
