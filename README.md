# Pill overlay
<img width="2548" height="1432" alt="Ingame overlay" src="https://github.com/user-attachments/assets/e1c0dc0d-d743-47ad-8afd-89ee5d6c9a98" />

A clean FPS/CPU/GPU pill shown at the top of the screen while a game is
running. Inspired by Devyn Johnston, I wanted a clean game overlay without the extra fuzz MangoHud brings in.

It uses [MangoHud](https://github.com/flightlessmango/MangoHud) as a
headless background data source (it's the only thing that can see a game's
real FPS, via its Vulkan/OpenGL render hook) and renders the actual pill
itself in Quickshell, which gives full control over padding, spacing and
colors that MangoHud's own renderer doesn't expose.

## Requirements

Install MangoHud itself (the plugin drives it, but doesn't install it):

```
sudo pacman -S mangohud lib32-mangohud
```

## Installing

```
omarchy plugin add https://github.com/Grappabh/omarchy-pill-overlay --enable
```

That one command clones it, enables it, and (interactively) asks which bar
section to place the widget in — defaulting to the right side. Running
non-interactively (e.g. scripted, or with `--yes`)? It'll skip that prompt
and enable without a bar placement; just run this afterward:

```
omarchy plugin enable io.github.grappabh.pill-overlay --section right
```

(That second form also works standalone if you ever disable and re-enable
the plugin later — no need to re-add it from git again.)

Everything else is automatic the first time it loads:

- It adds `MANGOHUD=1` to your Hyprland config so every Vulkan/OpenGL/Proton
  game picks up MangoHud, without you having to find and edit the right
  file yourself (Omarchy installs use either a Lua config or the classic
  `hyprland.conf` format — it detects and handles either one). This only
  ever *adds* a line, never touches anything else, and automatically
  verifies the change didn't break your Hyprland config — rolling itself
  back with a desktop notification if it ever did, rather than leaving
  things broken.
- It adds the settings MangoHud needs to `~/.config/MangoHud/MangoHud.conf`
  (stats computation + invisible background logging). If you already use
  MangoHud with your own visible overlay and have conflicting settings
  there, it won't silently overwrite them — you'll get a desktop
  notification telling you exactly what to change instead.

If you ever want to do either step by hand instead, see
[Manual setup](#manual-setup) below.

## Customizing

A small pill-shaped icon appears in your bar whenever a game is actively
running (i.e. whenever the overlay pill itself would be showing) — click it
to open a settings popup:

<img width="465" height="795" alt="Widget" src="https://github.com/user-attachments/assets/497ab652-ef1f-4a65-bd8d-15c8020d96ac" />
- **Position** — a mini monitor with 6 clickable dots (top/bottom ×
  left/center/right) for where the pill sits on screen.
- **Font size** / **Opacity** — sliders.
- **Follow Omarchy theme** — a switch that, when on, uses your current
  theme's accent/popup colors instead of the custom ones below (and hides
  those controls while it's on).
- **Label color** / **Background** — pick which one you're editing with the
  two pill buttons, then use the saturation/value box, hue slider, or the
  editable hex field underneath to set it.
- **°C / °F** — a switch for which unit temperatures are shown in.
- **Show/hide shortcut** — a pill showing the current keyboard shortcut for
  toggling the overlay on/off while a game is running (default
  **Super+Ctrl+G**). Click it, then press the key combination you want
  (needs at least one modifier — Ctrl/Shift/Alt/Super); it updates live, no
  restart needed. Escape cancels without changing anything.

You can also hand-edit `~/.config/omarchy/pill-overlay-settings.json` directly
(auto-created with defaults on first load). It's deliberately *not* inside this plugin's own folder:
Omarchy's plugin hot-reload watches that whole folder for source changes, so
a settings file living there would trigger a full plugin reload on every single change in the settings.

```json
{
  "fontSize": 16,
  "labelColor": "#6C9BD9",
  "backgroundColor": "#101518",
  "backgroundOpacity": 0.85,
  "position": "top-center",
  "followTheme": false,
  "fahrenheit": false,
  "overlayVisible": true,
  "shortcut": "SUPER CTRL, G"
}
```

`shortcut` uses Hyprland's own bind syntax (space-separated modifiers, comma,
then the key) — easiest to change via the popup's recorder pill rather than
by hand.

`position` is one of `top-left`, `top-center`, `top-right`, `bottom-left`,
`bottom-center`, `bottom-right`.

## Manual setup

The plugin sets this up automatically on first load (see [Installing](#installing)
above). If that ever fails on an unusual setup, here's the equivalent by hand:

Add this line to your `~/.config/hypr/hyprland.lua`, in the personal
overrides section near the bottom:

```lua
hl.env("MANGOHUD", "1")
```

(If you're on a non-Omarchy or non-Lua Hyprland config, the equivalent is
`env = MANGOHUD,1` in your `hyprland.conf`.) Reload Hyprland (`hyprctl
reload`) after adding it.

## How it works

- MangoHud runs invisibly (`alpha=0`) and continuously logs fps/cpu/gpu
  stats to a CSV in `~/.cache/mangohud/`.
- A small script tails whichever CSV file is newest, so the plugin always
  follows the currently-running game without needing to know its name.
- The Quickshell panel shows only when that data is flowing *and* the
  monitor it's on currently displays a fullscreen window — so it won't
  follow you to other workspaces, and on multi-monitor setups it only
  appears on the screen that actually has the game.
- The bar item's settings popup (and the show/hide shortcut) both work
  while a game is fullscreen, the same way bluetooth/network's popups do —
  they're real layer-shell surfaces, not something tied to the bar's own
  visibility.
- The show/hide shortcut is applied two ways: live immediately (so a
  freshly recorded one works without restarting anything), and persisted to
  `~/.config/hypr/pill-overlay-shortcut.conf` (sourced once from
  `hyprland.conf`) so it survives an actual Hyprland restart too.

## Known limitations

- Some games/emulators recreate their renderer periodically (loading
  screens, resolution changes), which can make the pill briefly flicker off
  and self-recover within a second or two. This is the game's behavior, not
  something the plugin controls.

## Credits

Bundles [Open Sans](https://www.opensans.com) (SIL Open Font License 1.1).

## License

MIT — see [LICENSE](LICENSE).
