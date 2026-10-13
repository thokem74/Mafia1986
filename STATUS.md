# Building status

Last updated: 2026-10-13
Current phase: 11 — polish and acceptance validation.
Overall build status: **In progress**. A playable campaign, ending and ARM64 debug APK are implemented. This is not yet a fully validated faithful release.

## Development phases

| BUILD.md phase | Status | Evidence / remaining work |
| --- | --- | --- |
| 1 Research and architecture | Implemented | Atari manuals/source/data reviewed; fixed C64 1.20 BASIC and roster inspected. Research, differences and architecture documented; exact map and remaining balance comparisons open. |
| 2 Core shell | Implemented | Scene-authored menus/settings, German/English, typed state, Resources, versioned saves, backups. Desktop suite and Android shell checks pass. |
| 3 City map | Implemented | Connected grid, nearby entrances, steps/months, vehicle allowance, hold movement. All entrances reachable; Android hold tested. |
| 4 First playable economy loop | Implemented | Four jobs, rent, transactions, training, location actions. Automated rules checks pass. |
| 5 Cars and smuggling | Implemented | Six travel modes, cargo limits, purchase/sale/stealing. Normal trading funds a campaign; fixed C64 vehicle tables restored. |
| 6 Gang system | Implemented | Thirty C64 recruits, ten-person maximum, equipment, dismissal and monthly health. Recruitment rules and campaign progression tested. |
| 7 Combat | Implemented | Authored board/units, cardinal range, variable damage, turns, obstacles, AI pathfinding, save/resume. Automated fights and Android touch/save tests pass. |
| 8 Crime/police systems | Implemented | Safe puzzle, bank/store/train crimes, checkpoints, bribery, court, prison, forgery, loans and collectors. Deterministic checks pass. |
| 9 Progression | Implemented | Monthly ranks, tips, advanced activities, business/investments. Long campaign reaches final prerequisites without injected state. |
| 10 Endgame | Implemented | Two-stage mayor fight, ten-guard transporter, both completion flags, points prerequisite, victory/time-up ending. Targeted and normal-rules progression checks pass. |
| 11 Polish | In progress | Original pixel graphics/audio/icon, touch controls, safe areas, inline hints, localization, documentation and debug restrictions implemented. Device soak/performance and manual campaign acceptance remain open. |

## Completed features and research corrections

- Shared location components cover pubs, stations, arms/car dealers, shops, banks, hideout, forgery, casino, loan business, subway, police, mayor and transporter.
- Low-resolution gameplay rendering is separate from responsive readable UI; nearest filtering, landscape and large touch targets.
- Offline synthesized music/effects with separate volume settings; no Internet permission or monetization.
- `user://` autosave plus three manual slots, temporary write/replacement, validated backup recovery, independent settings, exact RNG and active-encounter persistence.
- Fixed C64 data takes precedence over Atari: original weapon identities/prices, accuracy/damage, prerequisites, car tables, thirty recruits, ten-person cap, health, starting money/stats, five-step visits, ally-transparent shots and 20% police checks at remaining-step multiples of 20.
- Fixed defects found in validation: JSON integer/RNG precision, aliased save snapshots, backup recovery, combat text overflow, hold repeat cancellation, Android default Back exit, tutorial Back loop and headless audio shutdown leaks.

## Validation results

- Godot **4.7.2**, Mobile rendering retained. Headless import, script parsing, main boot and all authored scenes pass. Headless main boot exits cleanly.
- **2,495 deterministic assertions pass**: definition consistency, every translation entry, reachable locations, transactions, recruitment, rank/deadline/victory rules, combat/AI, encounter saves, corrupt backup recovery, invalid versions/data and scene flows.
- `tests/progression_runner.gd`: fresh long campaign, seed 2026, normal movement/entry/transactions and combat rules only. **Victory in month 341**, 1,281 location actions, ten members, 210/200 points, both mayor and transporter completed. No injected money, stats, ranks, tips or objective flags. Automated player uses the combat AI; this is not a human playthrough and does not establish balance across seeds.
- 424 full-screen-map redesign German/English layout captures cover all screens, every location kind, equipment/recruit forms, six crowded battle settings, both action modes and hints on/off at **16:9, 18:9, 19.5:9 and 20:9**, in `builds/screens/maps/`. Eight contact sheets and representative full-size screenshots inspected; automated bounds checks report zero layout failures.
- ARM64 **debug APK export succeeds**, signs/verifies with debug key. Package `org.thokem.mafia1986`; QA scripts/docs/build artifacts excluded from export. Output: `builds/mafia1986-debug.apk`.
- Samsung **SM-A176B**, 2340×1080 landscape, Mali-G68 Vulkan Mobile: installed/launched, new campaign, German/English switching, readable notch-safe layout, autosave continuation and suspend/resume verified.
- Held city touch advanced three tiles and persisted three moves. Held combat touch consumed exactly one action: actor 0 moved x4→x5, active actor became 1. Both stages of the mayor fight completed using real touch actions and explicit debug helpers: 117 actions in 54 seconds. The ten-guard transporter also completed: 109 touch actions in 64 seconds. Game-specific log showed no script/runtime errors during that sample.
- Android combat memory sample: 354,638 KiB PSS (about 346 MiB), then 361,129 KiB (about 353 MiB) after both encounters. This is a short observation, not a sustained memory-leak or thermal test.
- Android Back keeps the app running and navigates its screens; confirmation and tutorial pop-ups have been removed; immediate actions and inline hints have desktop regression checks. Active fight background/process-restart recovery checked separately from normal campaign progression. Android victory layout verified by loading the completed desktop progression save into manual slot 2; this was not a full phone campaign. The original phone test campaign was preserved in slot 3 and restored after testing.

## Immediate-action UI update (2026-10-13)

- Removed all action confirmations and first-time tutorial pop-ups. Start, Wait, Execute, Give Up, save overwrite and load perform immediately; inline city/location/combat help follows Settings hints.
- Existing save format and legacy tutorial history remain compatible. Save/load results and error messages remain visible.
- Godot editor import and 858 assertions pass. Forty German/English captures with hints enabled at the four supported aspect ratios inspected; ARM64 debug APK exported and installed.
- Samsung touch checks verified one-tap Start, movement, Wait, Execute (job acceptance), Back and Continue. Original device saves/settings backed up before testing and restored afterward.

## Noir pixel-art and Android UI redesign (2026-10-13)

- Built-in ImageGen created 19 full-screen backgrounds: 14 location kinds plus menu, city, combat, safe and ending. Utility screens share the hideout scene. Exact prompts are in `assets/backgrounds/prompts.json`; originals are preserved in Codex's generated-images directory.
- Rounded midnight-blue cards, amber primary actions, readable bundled Adwaita Sans, larger D-pad targets, clear selected states, styled sliders/toggles, and scrollable forms replace the old flat UI and location thumbnails. All visible composition remains in Godot scenes.
- Backgrounds preserve aspect ratio while covering the screen, ignore touch input, and load only when the displayed setting changes. Live city/combat boards, immediate actions and save compatibility remain intact.
- Godot import and 885 assertions pass. The complete visual run produces 232 captures with zero fixed-control overflows. ARM64 debug APK exports and installs on the Samsung.
- Android checks verify readable notch-safe menu/forms/city/location/settings, one-tap and held movement, immediate location entry/Execute, English selection/Apply, single-action combat holds, mode selection, one-tap surrender and Android Back. Original phone saves/settings are backed up before verification and restored afterward.

## Full-screen playable map update (2026-10-13)

- Built-in ImageGen produced top-down city terrain, matching rooftop surroundings, six combat environments, red/blue gangsters, cover and a location-icon atlas. Final pixel assets and exact prompts are in `assets/maps/`; original generated images remain in Codex's generated-images directory. A saved layout reference fixes city roads to the existing grid.
- Removed inset board frames and SubViewports. Full-screen terrain sits below live, scene-authored game objects and UI. The entire grid fits without distortion into the clear area left of the controls; hints appear inline in the event strip. Generated cover sprites match all three existing collision positions.
- Combat reasons select street/shop/bank/train/warehouse/mayor artwork. Gameplay, immediate actions, legacy tutorial history and save format remain unchanged; `project.godot` was not modified by this update.
- Godot import and **920 assertions pass**. **424 German/English screenshots** cover all screens plus six crowded battle settings, both action modes, hints on/off and four supported aspect ratios. Automated bounds/grid-overlap checks report zero failures; eight map contact sheets and representative full-size images were inspected.
- Android debug APK exports, signs and installs on the Samsung SM-A176B. Real touches verified one-tap Start, one-cell street movement, a hold adding three cells, immediate Wait, Android Back, a 20-fighter battle, a combat hold consuming exactly one action, Attack selection, enemy AI advancement with hints shown and immediate surrender. Game-specific logs showed no script/rendering errors during these checks.
- Five original device save/settings files were backed up to `/tmp/mafia1986-map-device-backup`, restored, and byte-verified after reopening the menu. Combat checks used an isolated fixture rather than the user's campaign.

## Street-map readability update (2026-10-13)

- The street player now has a visible 26-pixel-tall red character, a pale-cyan ring and dark backing, with no player label. The scene crops unused transparent sprite padding; combat artwork and presentation are unchanged.
- Reusable scene-authored badges pair the existing icons with short German/English names. Entrance connectors retain catalog coordinates, and cyan destination highlighting matches the Enter button. Badge/text sizes stay constant across map scaling; nearby labels shift within their roof block when needed to clear the character.
- City terrain is dimmed to 55% and surrounding rooftops to 30%, preserving visible roads while prioritizing characters and locations. The whole grid remains visible, with annotation space reserved above it.
- **2,495 deterministic checks pass**, including every walkable cell, all entrance highlights, icon identities, text fit, constant character size, and late-game visibility. **488 city screenshots** cover all 20 entrances, boundaries, label avoidance, both hint states, both languages and all four aspect ratios, with zero layout failures. Eight contact sheets and representative full-size images were inspected.
- Android verification also exposed two platform Back requests from a single press, 14 ms apart. The first acts immediately; only a duplicate within 50 ms is ignored. Button actions remain immediate. Regression checks cover location → map → menu navigation.
- Final ARM64 debug APK exported, signed and installed on the Samsung. Touch checks verified two single-cell moves, correct pub highlighting/entry, a hold advancing five cells, and native Back returning location → map → menu without skipping screens. The 26-pixel character and translated location badges were inspected on-device.
- The five original phone save/settings files were backed up to `/tmp/mafia1986-city-readability-device-backup`, restored and byte-verified after reopening the final menu. Existing artwork, campaign format and `project.godot` were preserved.

## Known limitations and blockers

- No build blocker. Release signing is not configured; this APK is a debug/testing build.
- Faithful C64 parity is unfinished: district geometry, shop/hotel variants, offer randomness, rank weighting/options and several encounter/economy details remain provisional. `docs/gameplay_differences.md` records these instead of claiming exact original pacing.
- The 25/50-year and 100/200-point setup is a provisional single-player adaptation. Fixed C64 original offers an ending year and point multiplier.
- Full human campaign playthrough, device coverage beyond this Samsung, landscape-cutout variation, sustained FPS/memory/thermal profiling and a long suspend/resume soak are not yet validated.

## Next concrete task

Compare remaining map/rank/location variants against fixed C64 1.20/1.31 gameplay, then complete a human campaign and sustained Android performance/lifecycle acceptance run. Keep implemented features separate from these open validation tasks.

## All 23 acceptance criteria

Checked means implemented with the evidence noted; it does **not** certify full Android release acceptance. Unchecked items retain required manual/device validation.

- [x] 1 Launch the Android game — Samsung install/launch.
- [x] 2 Choose German or English — translations, settings and phone persistence.
- [x] 3 Start a new game — desktop and Samsung.
- [x] 4 Learn basic controls — contextual city/location/combat hints; desktop Back regression and phone display.
- [x] 5 Move around Chicago — grid/reachability tests and held Android touch.
- [x] 6 Enter locations — scene-flow checks and normal-rules progression.
- [x] 7 Perform initial jobs/crimes — deterministic job/crime checks.
- [x] 8 Earn and spend money — transaction checks and ordinary-rule campaign.
- [x] 9 Buy or obtain equipment — researched prerequisites, transactions and progression.
- [x] 10 Acquire/use a vehicle — transactions, cargo/steps and progression.
- [x] 11 Interact with police — deterministic checks and progression encounters.
- [x] 12 Smuggle alcohol and commit crimes — cargo/trade/crime checks and progression.
- [x] 13 Recruit a gang — prerequisites/duplicates/cap and ten-person progression.
- [x] 14 Manage equipment/health — weapon, training and monthly-health rules.
- [x] 15 Enter tactical combat — desktop and Android targeted mayor encounter.
- [x] 16 Fight AI opponents — deterministic fights and complete rules-driven campaign.
- [x] 17 Progress through ranks — thresholds/retention and ordinary-rule progression.
- [x] 18 Save and resume — round-trips, corruption recovery, Android suspend/process restart.
- [x] 19 Unlock late-game content — purchased tips and normal progression.
- [x] 20 Complete mayor objective — normal-rules desktop progression plus both Android fight stages using targeted debug setup.
- [x] 21 Complete transporter objective — normal-rules desktop progression plus ten-guard Android fight using targeted debug setup.
- [x] 22 Satisfy victory conditions — prerequisite tests and normal-rules progression; both final fights separately passed on Android.
- [x] 23 Reach ending screen — desktop scene assertion and Android victory screen loaded from the completed normal-rules campaign.
