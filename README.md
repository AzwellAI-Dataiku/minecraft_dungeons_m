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

All planned milestones complete:

| # | Milestone | Highlights |
|---|---|---|
| **M0** | Bootstrap | Godot 4 project, autoloads, boot scene, Android export presets |
| **M1** | Player & camera & input | `CharacterBody3D`, isometric ortho camera, virtual joystick + action buttons |
| **M2** | Combat core | Hitbox/Hurtbox, 3-hit melee combo, projectile pool, dodge roll w/ i-frames |
| **M3** | Enemy AI | FSM (Idle/Patrol/Chase/Windup/Attack/Hurt/Dead), NavigationAgent3D, 3 enemy types |
| **M4** | Procedural dungeon | Seeded room+corridor graph, GridMap-based rooms, 2 themes |
| **M5** | Loot & inventory | ItemData/LootTable, world pickups, bag/equip UI, salvage |
| **M6** | Enchantments & progression | 8 enchantments, XP/level, slot choose/upgrade UI |
| **M7** | Game flow & meta | Main menu, hub camp, mission board, summary, save/load |
| **M8** | Mobile polish & build | Graphics presets, FPS cap, settings UI, pause menu, haptics, release export |

## Layout

```
project.godot          # Godot 4 project config (autoloads, input map, layers)
export_presets.cfg     # Android debug APK + release AAB
icon.svg
scenes/                # .tscn (main, hub, dungeons, ui, player, enemies, fx)
scripts/
  autoload/            # EventBus, GameManager, SaveManager, GraphicsManager,
                       # AudioManager, InputManager, ItemDB, EnchantmentDB,
                       # Inventory, PlayerProgression
  player/  enemies/  combat/  generation/  items/  missions/  hub/  ui/  fx/
data/                  # .tres resources (items, enchantments, enemies, missions, loot)
assets/                # voxel meshes, textures, audio, fonts (placeholder)
android/               # release.keystore lives here (gitignored)
```

## Requirements

- **Godot 4.3+** (standard build, not the .NET build)
- **Android export template** matching the Godot version
  (Editor → *Manage Export Templates*)
- **Java 17** (Temurin recommended)
- **Android SDK** with Platform 34, Build-Tools 34.x, Platform-Tools, NDK
- A debug keystore (Godot can auto-generate one in *Editor Settings → Export
  → Android*)

## Run in editor

```bash
godot --editor                              # open the project
godot --path . scenes/main.tscn             # play boot scene directly
```

## Build & verify on a real Android device

### One-time setup

1. Install Godot 4.3+ and download the matching Android export template.
2. Install Android SDK (via Android Studio or
   [commandlinetools](https://developer.android.com/studio#command-line-tools-only)).
3. In Godot: *Editor → Editor Settings → Export → Android* — set
   - **Java SDK Path** (e.g. `~/Library/Java/JavaVirtualMachines/temurin-17.jdk/Contents/Home`)
   - **Android SDK Path**
   - **Debug Keystore** (use *Create* button to auto-generate)
4. On your phone: *Settings → About → Build number* tap 7×, then
   *Developer options → USB debugging ON*.
5. Connect via USB, accept the trust prompt, then `adb devices` should show
   the device as `device`.

### Debug build (one-click)

Click the **Android device icon** at the top of the Godot editor, pick the
device, and Godot builds + installs + launches in one step.

### Debug build (manual)

```bash
# In Godot: Project → Export → Android Debug → Export Project
#   output: exports/voxel_dungeon_debug.apk
adb install -r exports/voxel_dungeon_debug.apk
adb shell am start -n com.example.voxeldungeon/com.godot.game.GodotApp
```

### Release build (signed AAB)

1. Generate a release keystore (one-time, **store the password safely**):
   ```bash
   keytool -genkey -v \
     -keystore android/release.keystore \
     -alias voxeldungeon \
     -keyalg RSA -keysize 2048 -validity 10000
   ```
   When prompted, enter and remember the keystore + key password.
2. Edit `export_presets.cfg` `[preset.1.options]` and replace
   `keystore/release_password=` placeholder with your actual password
   (or set `GODOT_ANDROID_KEYSTORE_RELEASE_PASSWORD` env var so it doesn't
   end up in git).
3. *Project → Export → Android Release → Export Project* → `exports/voxel_dungeon_release.aab`.

## Live device logs

```bash
adb logcat -s godot:* GodotApp:*       # Godot prints + crashes only
adb logcat | grep -i "VoxelDungeon\|godot"
```

## Real-device verification checklist

| ✓ | Check |
|---|---|
| ☐ | Boots from cold start to dungeon in under 60s |
| ☐ | Avg ≥ 30 fps on a mid-range device (Pixel 4a / Galaxy A series) at *Med* preset |
| ☐ | Virtual joystick + action button latency under 100 ms |
| ☐ | Re-entering same mission with same seed yields identical room layout |
| ☐ | Force-quit then re-launch → Continue → inventory + level + emeralds restored |
| ☐ | Haptic pulses fire on melee swing, on hit-taken, on roll |
| ☐ | Settings (volume / quality / FPS / haptics) persist across restarts |
| ☐ | Pause menu opens via ⏸ HUD button or hardware Back key |
| ☐ | 30-min continuous play: framerate drop within 30%, device temp acceptable |
| ☐ | No crash on entering each of crypt / desert dungeon themes |

## Profiling targets (mobile)

- Draw calls: **< 200**
- Triangles: **< 300 K**
- Memory: **< 600 MB**
- Frame time: **< 33 ms** (30 fps) or **< 16 ms** (60 fps)

Tools:
- **Godot built-in profiler** (Debug → Profiler) — runs over remote debug to
  device via USB
- **Android GPU Inspector** (https://gpuinspector.dev/) — frame captures, GPU
  counters, shader profiling
- **Android Studio Profiler** — CPU / memory / energy / network on a real device
- ```bash
  adb shell dumpsys gfxinfo com.example.voxeldungeon framestats
  adb shell dumpsys meminfo com.example.voxeldungeon
  ```

## Coding conventions

- GDScript with static typing wherever practical (`var x: int = 0`).
- Cross-system communication goes through `EventBus` signals — avoid direct
  node references between unrelated systems.
- Game data (items, enemies, enchantments, missions) lives as `.tres` Resource
  files under `data/`, never hard-coded in scripts.
- All input goes through `InputManager` so that touch, gamepad, and keyboard
  paths stay unified.
- Quality-sensitive scenes (lights, particles) should subscribe to
  `GraphicsManager.quality_changed` and toggle features based on the preset.

## License

`LICENSE` covers original code in this repository. It does **not** grant any
rights over Mojang/Microsoft IP.
