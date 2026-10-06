# Game overlay

A clean FPS/CPU/GPU pill shown at the top of the screen while a game is
running — centered, dark, minimal, and only visible on the monitor that
actually has the fullscreen game on it.

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

## Enabling

```
omarchy plugin enable game-overlay
omarchy bar put game-overlay --section right
```

The second command is needed because `enable` only registers the plugin —
it doesn't place the bar widget into your actual bar layout. (Put it in
whichever section you like; `right` is just a reasonable default.)

That's it — everything else is automatic the first time it loads:

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

A small **"FPS \<n\>"** item appears in your bar whenever a game is actively
running (i.e. whenever the overlay pill itself would be showing) — click it
to open a settings popup:

- **Position** — a mini monitor with 6 clickable dots (top/bottom ×
  left/center/right) for where the pill sits on screen.
- **Font size** / **Opacity** — sliders.
- **Follow Omarchy theme** — a switch that, when on, uses your current
  theme's accent/popup colors instead of the custom ones below (and greys
  those fields out while it's on).
- **Label color** / **Background** — hex color fields (type a `#rrggbb`
  value directly).
- **°C / °F** — a switch for which unit temperatures are shown in.

You can also hand-edit `~/.config/omarchy/game-overlay-settings.json` directly
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
  "fahrenheit": false
}
```

`position` is one of `top-left`, `top-center`, `top-right`, `bottom-left`,
`bottom-center`, `bottom-right`.

## Manual setup

The plugin sets this up automatically on first load (see [Enabling](#enabling)
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

## Known limitations

- Some games/emulators recreate their renderer periodically (loading
  screens, resolution changes), which can make the pill briefly flicker off
  and self-recover within a second or two. This is the game's behavior, not
  something the plugin controls.
- The bar item (and its settings popup) is only reachable while the bar
  itself is visible, which Omarchy hides during fullscreen games — see above.

## Credits

Bundles [Open Sans](https://www.opensans.com) (SIL Open Font License 1.1).

## License

MIT — see [LICENSE](LICENSE).
