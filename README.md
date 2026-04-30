# Voxel Dungeon Crawler (Personal Learning Project)

An Android-targeted, isometric voxel action-RPG built in **Godot 4** as a
personal-learning clone of the *Minecraft Dungeons* gameplay loop.

> **Legal notice — read first.**
> "Minecraft" and "Minecraft Dungeons" are trademarks of Mojang AB / Microsoft.
> This repository is **private learning material only**. It must not be
> distributed, uploaded to any app store, or made public. **No original
> assets** (textures, models, sounds, fonts, logos) from Mojang/Microsoft are
> included. All in-game names, identifiers, and assets used here are
> placeholders that should be replaced with original work before any external
> sharing.

## Status

Milestone **M0 — Bootstrap** ✅

Implemented:
- Godot 4 project skeleton (Forward Mobile renderer)
- Five autoload singletons: `EventBus`, `GameManager`, `SaveManager`,
  `AudioManager`, `InputManager`
- Boot scene (`scenes/main.tscn`) with Play / Quit
- Android export presets (debug APK + release AAB, arm64-v8a, min SDK 28)
- `.gitignore`, project icon, directory layout

Next milestone: **M1 — Player, camera, and input** (see
[`/root/.claude/plans/dapper-finding-crystal.md`](../../.claude/plans/dapper-finding-crystal.md)
for the full roadmap).

## Layout

```
project.godot          # Godot 4 project config
export_presets.cfg     # Android debug + release presets
icon.svg
scenes/                # .tscn scenes (main, ui, player, enemies, dungeons, hub, fx)
scripts/               # GDScript source
  autoload/            # Global singletons (EventBus, GameManager, ...)
data/                  # .tres resources (items, enchantments, enemies, missions, loot)
assets/                # voxel meshes, textures, audio, fonts, shaders
tests/                 # GUT or scene-based tests
addons/                # Optional plugins
```

## Requirements

- **Godot 4.3+** (standard build, not the .NET build unless you plan to add C#)
- **Android export template** matching your Godot version
  (Editor → *Manage Export Templates*)
- For building APK/AAB:
  - Java 17 (Temurin recommended)
  - Android SDK + NDK (Platform 34, Build-Tools 34.x)
  - A debug keystore (Godot can auto-generate one in *Editor Settings → Export
    → Android*)

## Run in editor

```bash
godot --editor          # open the project
# or directly play the boot scene
godot --path . scenes/main.tscn
```

You should see a "Boot OK" status with the Godot version and platform.

## Build for Android (debug)

1. Connect a device with USB debugging enabled.
2. *Project → Export → Android Debug → Export Project*
   (output: `exports/voxel_dungeon_debug.apk`).
3. Install:
   ```bash
   adb install -r exports/voxel_dungeon_debug.apk
   ```
4. Or use the editor's *one-click deploy* button while a device is connected.

## Coding conventions

- GDScript with static typing wherever practical (`var x: int = 0`).
- Cross-system communication goes through `EventBus` signals — avoid direct
  node references between unrelated systems.
- Game data (items, enemies, enchantments, missions) lives as `.tres` Resource
  files under `data/`, never hard-coded in scripts.
- All input goes through `InputManager` so that touch, gamepad, and keyboard
  paths stay unified.

## License

`LICENSE` covers original code in this repository. It does **not** grant any
rights over Mojang/Microsoft IP.
