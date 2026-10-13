# Mafia1986

A single-player, offline Godot 4.7 Android remake of **Igelsoft's Mafia (1986)**,
set in 1920s Chicago. This is an in-development playable campaign; see
[STATUS.md](STATUS.md) for implementation and validation limits, and
[BUILD.md](BUILD.md) for the specification.

## Play

Open `project.godot` with Godot 4.7 and run the main scene. German is the default;
Settings offers English, inline hints and independent music/effect volumes.

- Touch the four direction buttons to move; hold for repeated city movement.
- Stand beside a marked building and press **Enter**. Choose an action, person,
  item and amount, then press **Execute** to act immediately. Each visit costs five monthly steps.
- **Wait** advances a month, recovering health and resolving jobs, rent and debts.
- In combat choose **Move** or **Attack**, then a direction. Each gangster gets
  one action. Shots travel cardinally, stop at walls and pass through allies.
- **Status** shows your gang, equipment, finances and objectives. The menu offers
  autosave continuation and three manual save slots. Back leaves a screen or
  returns to the menu; active encounters remain saved.
- Desktop: arrow keys move, Enter enters, Escape goes back. F9 opens development
  helpers in debug builds only.

Earn money through jobs and alcohol trading, train and equip your people, rent a
hideout and recruit. Pub tips unlock advanced activities and both final missions.
Victory requires the selected points target plus defeating the mayor and robbing
the money transporter. A points target alone does not finish the campaign.

## Build Android

Install matching Godot 4.7 export templates, Android SDK/build tools and Java, then
set the SDK/Java paths in Godot's editor settings. The `Android` preset exports
ARM64, landscape, package `org.thokem.mafia1986`, without Internet permission.

```sh
mkdir -p builds
godot --headless --path . --export-debug Android builds/mafia1986-debug.apk
adb install -r builds/mafia1986-debug.apk
adb shell am start -n org.thokem.mafia1986/com.godot.game.GodotAppLauncher
```

The debug APK is for testing. Release signing is not configured. Generated builds
are ignored by Git and excluded from Godot imports. Reference disk assets are not
included; pixel graphics and synthesized audio were created for this project.

## Verify and learn

```sh
XDG_DATA_HOME=/tmp/mafia1986-validation godot --headless --path . --editor --import --quit
XDG_DATA_HOME=/tmp/mafia1986-tests godot --headless --path . --script tests/run_tests.gd
XDG_DATA_HOME=/tmp/mafia1986-progression godot --headless --path . --script tests/progression_runner.gd
XDG_DATA_HOME=/tmp/mafia1986-visual godot --path . --script tests/visual_runner.gd
```

The visual runner captures German and English menus, city, shop, combat and
settings at 16:9, 18:9, 19.5:9 and 20:9 under `builds/screens/`. Rendering needs a
graphical environment. The deterministic suite checks rules, scene flows,
localization, saves and targeted endgame fights; see STATUS for ordinary
progression and device coverage.

Read [docs/architecture.md](docs/architecture.md) for the code structure,
[docs/original_game_research.md](docs/original_game_research.md) for sources, and
[docs/gameplay_differences.md](docs/gameplay_differences.md) for adaptations.
`tools/generate_assets.py` regenerates original assets using Pillow.

For targeted device combat checks, preserve your campaign in a manual slot, open
F9 in a debug build, equip the test gang and start a mission. At 2340×1080 with
inline hints enabled, `python3 tools/android_combat_smoke.py` drives actual touch
buttons until the fight ends. It reads only this game's autosave and never edits
combat state; coordinates are specific to the tested Samsung layout.
