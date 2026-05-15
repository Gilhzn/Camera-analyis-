# Iron Frontline

An original real-time strategy game built in **Godot 4.3+**, designed for
mobile (Android) with touch controls and a 2D top-down view. It reproduces the
*gameplay feel* of classic 90s base-building RTS games (harvest → build →
tech-up → fight) with entirely **original names, art and code** — no
third-party game assets, trademarks, lore or music are used. Visuals are simple
geometric shapes drawn at runtime.

> Scope: a playable **skirmish vertical slice** — you vs. a basic AI on one
> procedurally generated map. Win by destroying the enemy Construction Yard.

## Requirements

- [Godot Engine 4.3 or newer](https://godotengine.org/download) (standard build).
- For Android: the matching **Android Build Template** + Android SDK/JDK
  configured in Godot's *Editor → Manage Export Templates* and
  *Editor → Editor Settings → Export → Android*.

## Run on desktop (development)

1. Open Godot, **Import** this folder (it contains `project.godot`).
2. Press **F5** (the main scene is `scenes/Main.tscn`).
3. Mouse emulates touch: left-drag = pan, mouse-wheel = zoom, click = tap.

## Build the Android APK

1. Open the project in Godot and let it import once.
2. *Project → Export…* — an **Android** preset is included
   (`export_presets.cfg`).
3. Install the Android Build Template (*Project → Install Android Build
   Template…*) and set the SDK/JDK paths in Editor Settings if prompted.
4. *Export Project* → produces `build/iron-frontline.apk`.
5. Install on a device: `adb install -r build/iron-frontline.apk`.

(The orientation is locked to landscape.)

## How to play

- **Pan**: drag one finger.  **Zoom**: pinch with two fingers (wheel on desktop).
- **Select**: tap a friendly unit.  **Select Army**: HUD button selects all
  combat units.
- **Move / Attack**: with units selected, tap ground to move, tap an enemy to
  attack.  **Stop**: HUD button.
- **Build a structure**: tap it in the right-side menu, then tap a valid spot
  near your base (green = ok, red = blocked). **Cancel Build** aborts placement.
- **Train units**: tap a unit in the menu; it builds at its production
  structure and gathers at the rally point.
- **Economy**: build a Power Plant, then an Ore Refinery (it arrives with a
  free Harvester). Harvesters auto-mine the gold ore fields and refill credits.
- **Tech path**: Construction Yard → Power Plant → Refinery → Barracks /
  War Factory → Gun Turret. The build menu disables what you can't make yet.
- **Win**: destroy the enemy Construction Yard. **Lose**: yours is destroyed.

## Project layout

Only `scenes/Main.tscn` is a scene file; everything else is built in code for
robustness.

| Path | Role |
|------|------|
| `scripts/main.gd` | Boots the whole match (world, camera, HUD, AI, bases). |
| `scripts/core/` | `game_state` (autoload), `grid`, `pathfinder`, `database` (autoload). |
| `scripts/units/` | `unit`, `harvester`, `unit_data`. |
| `scripts/buildings/` | `building`, `building_data`. |
| `scripts/systems/` | `production` (autoload), `combat`, `fog_of_war`. |
| `scripts/ai/enemy_ai.gd` | Basic skirmish opponent. |
| `scripts/input/input_controller.gd` | Touch pan/zoom, select, command, placement. |
| `scripts/ui/hud.gd` | Resource bar, build menu, minimap, win/lose. |
| `scripts/world/map.gd` | Procedural terrain, rock, ore fields. |

Units and buildings are **data-driven** (`scripts/core/database.gd`), so new
types/maps can be added without touching the engine code.

## Known limitations (vertical slice)

Single map, one basic-difficulty AI, two combat units + harvester, ~6 building
types, no campaign / story / multiplayer / sound. These are intentional scope
boundaries; the architecture is built to extend.
