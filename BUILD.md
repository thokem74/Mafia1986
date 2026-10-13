You are working inside the root of the existing Godot project:

https://github.com/thokem74/Mafia1986

Your task is to build a complete single-player Android remake of the 1986 C64 game **Mafia by Igelsoft** using Godot.

This is NOT the different 1986 Mafia game by Sascha Laffrenzen.

The target game is the Igelsoft Mafia game set in 1920s Chicago, with a city map, cars, weapons, pubs, shops, gangs, police, jobs, crime, turn-based tactical combat, the mayor endgame objective, and the money transporter endgame objective.

Do not stop after creating a prototype or project skeleton. Work iteratively toward a genuinely playable game.

---

# 1. READ PROJECT INSTRUCTIONS FIRST

Before changing anything:

1. Read `AGENTS.md`.
2. Read `README.md`.
3. Inspect `project.godot`.
4. Inspect `export_presets.cfg`.
5. Inspect the entire existing project tree before making architectural decisions.

The rules in `AGENTS.md` are mandatory.

In particular:

* Follow the official Godot GDScript style guide.
* Prefer clear, explicit, easy-to-learn code.
* Use typed GDScript where it improves readability.
* Use descriptive names.
* Keep classes and methods focused.
* Comment non-obvious gameplay rules and design decisions.
* Visible game objects should be created in `.tscn` scenes whenever practical.
* Do not generate visible UI trees entirely from scripts when they can reasonably exist as scenes.
* Scripts should primarily implement state, behavior, and interactions.
* Optimize appropriately for Android.
* Avoid unnecessary `_process()` work and unnecessary allocations.

The project currently targets Godot 4.7 and uses the mobile renderer.

Do not downgrade the project to an older Godot version.

---

# 2. TARGET PLATFORM

Primary target:

* Android smartphones
* landscape orientation only
* touch-first controls
* responsive across different Android screen sizes and aspect ratios
* designed to remain usable on smaller phones
* arm64 Android export

Desktop keyboard/mouse controls may also exist for easier development and testing, but Android touch controls are the primary interface.

Do not design the interface around keyboard input and then merely overlay virtual keys.

Design it properly for touch.

---

# 3. GAME IDENTITY

The goal is to recreate the **look, atmosphere, rules, pacing, systems, and gameplay identity** of Igelsoft's C64 Mafia while making it pleasant to play on a modern Android touchscreen.

The visual target is:

**C64 look enhanced for modern phones**

That means:

* unmistakable 1980s C64 pixel-art aesthetic
* low-resolution visual language
* limited retro palette
* chunky pixel graphics
* tile/character-inspired city map
* period-appropriate 1920s Chicago atmosphere
* retro illustrated location screens where appropriate
* minimal smooth vector/mobile-app aesthetic
* no glossy generic modern mobile-game appearance

However:

* text must remain readable on modern phones
* touch targets must be comfortably sized
* menus may use more screen space than the original
* information hierarchy may be improved
* status information can be clearer
* combat feedback can be clearer
* transitions may be quicker
* important information should not require memorizing keyboard shortcuts

Do not replace the game with a modern redesign.

The player should immediately recognize that this is a remake of an old 8-bit computer game.

---

# 4. LANGUAGE

Implement localization from the beginning.

Required languages:

* German
* English

German should be the default language.

Use Godot's localization system rather than hardcoding translated strings throughout scripts.

Keep translatable text outside gameplay logic wherever practical.

The Settings screen must allow switching between German and English.

Do not duplicate game logic per language.

---

# 5. SINGLE-PLAYER ONLY

This remake is single-player only.

Do NOT implement:

* hot-seat multiplayer
* network multiplayer
* multiple human players
* multiplayer lobby systems
* multiplayer save structure

The human player controls one gang.

Other criminals, hostile gangs, police, guards, mission opponents, and combat enemies are controlled by AI.

Where the original game's rules contain systems designed around multiple human players, reinterpret them appropriately for a single-player campaign while preserving the original game's intent.

Research how the original game behaves before inventing replacements.

---

# 6. PRIMARY REFERENCE SOURCES

Use the following sources heavily.

## Original C64 game information

https://www.c64-wiki.com/wiki/Mafia

https://www.retro-gamer.de/mafia-1986-bandenkrieg-auf-dem-c64/

Search for additional reliable sources about:

* Mafia by Igelsoft
* C64 Mafia Igelsoft
* Mafia 1986 Igelsoft
* walkthroughs
* screenshots
* manuals
* gameplay videos
* maps
* weapon statistics
* car statistics
* mission conditions
* ranking system
* danger/fame/points system
* jobs
* police system
* arrests
* prison
* bribery
* gang recruitment
* combat rules
* endgame conditions

When information is uncertain, search the web rather than guessing.

---

# 7. VERY IMPORTANT REFERENCE IMPLEMENTATION

Study this repository carefully:

https://github.com/drunkeneye/MAFIA.A8

This is an Atari 8-bit port of the original Igelsoft C64 game and is extremely useful as a behavioral and architectural reference.

Read its:

* `README.md`
* `Manual.txt`
* `Anleitung.txt`
* `src/main.pas`
* `src/player.pas`
* `src/map.pas`
* `src/fight.pas`
* `src/fight_ai.pas`
* `src/fight_utils.pas`
* `src/helpers_game.pas`
* `src/locations.pas`
* `src/setup_game.pas`
* relevant variable/constant files
* all files under `src/locations/`
* map generation/data files
* localization data
* game data/constants
* any comments documenting differences from the original game

Important location implementations include:

* arms dealer
* bank
* car dealer
* central station
* forgery
* gambling
* hideout
* loan shark
* mayor
* money transporter
* police
* pub
* store
* subway

The Atari implementation contains useful:

* game-state logic
* maps
* location logic
* combat logic
* combat AI
* progression rules
* gangster data
* weapons
* vehicles
* economy
* localization
* endgame conditions

However:

**Do NOT blindly copy Atari behavior when comments or research show that it differs from the C64 original.**

Treat it as an implementation reference, not absolute truth.

---

# 8. SOURCE PRIORITY

When determining original gameplay behavior, use this priority:

1. verified behavior from the later fixed C64 releases
2. original C64 documentation/manuals/screenshots/gameplay
3. reliable C64 historical documentation
4. `drunkeneye/MAFIA.A8`
5. other reliable historical sources
6. a documented best-effort approximation

Prefer the later fixed C64 behavior over known buggy early releases.

Do not intentionally reproduce crashes, broken logic, corrupt states, or obvious bugs from early versions.

If you find uncertainty about an important mechanic, add a short entry to a developer reference file such as:

`docs/original_game_research.md`

Record:

* mechanic
* sources checked
* observed behavior
* uncertainty
* implementation decision

Do not silently invent major game rules.

---

# 9. LEGAL / ASSET RULE

Use reference repositories and historical screenshots to understand the game's design.

Do NOT automatically copy third-party copyrighted graphics, music, fonts, or sound files into this project unless the license clearly permits reuse.

If license status is unclear:

* recreate equivalent original assets
* create new pixel art inspired by the technical limitations and atmosphere
* do not pixel-for-pixel trace protected artwork

The remake should reproduce the feel and layout of the original without requiring unauthorized reuse of proprietary assets.

---

# 10. IMAGE GENERATION

If an appropriate image-generation skill/tool is available, you may use it when creating original visual assets.

Use generated imagery only where it genuinely helps, especially for:

* location illustrations
* title artwork
* splash artwork
* store/pub/bank/police/location panels
* mission illustrations
* app icon concepts

Generated images must then be adapted to the game's visual style.

They should look like original retro game art, not modern AI artwork.

Target characteristics:

* low resolution
* deliberate pixel structure
* restricted palette
* strong silhouettes
* minimal gradients
* 1980s home-computer feel
* 1920s Chicago subject matter

Do NOT rely on generated full-resolution illustrations directly inside gameplay.

Pixel art should remain crisp and intentionally low resolution.

For map tiles, UI icons, characters, cars, weapons, and combat pieces, prefer purpose-built pixel assets.

---

# 11. GAME PREMISE

The game takes place in Chicago during Prohibition around 1920.

The player begins as an insignificant criminal recently released from prison.

The goal is to rise through the criminal underworld by:

* earning money
* committing crimes
* taking jobs
* buying equipment
* acquiring vehicles
* smuggling alcohol
* recruiting gangsters
* improving gang capability
* surviving police attention
* bribing authorities
* building reputation/fame/danger points
* completing increasingly serious crimes
* eventually confronting the mayor objective
* eventually completing the money transporter objective

The endgame must preserve the original structure as closely as research allows.

Do not turn this into a generic mission-based action game.

---

# 12. CORE GAME STRUCTURE

Design the game around several major modes.

At minimum:

## Title / Main Menu

Must include:

* New Game
* Continue
* Load Game
* Settings
* Credits
* Quit where appropriate

On Android, Continue should load the latest autosave.

---

## City Map

This is one of the game's core screens.

The player moves through a stylized top-down Chicago city.

Requirements:

* retro tile/grid visual style
* streets
* blocks/buildings
* recognizable interactive locations
* player marker
* vehicle-aware movement
* movement rules based on original behavior
* clear indication of accessible directions
* location entry
* police encounters where appropriate
* random encounters/events where appropriate
* touch-friendly controls

Do not turn the city map into free analogue movement if the original design is tile/grid based.

Preserve the deliberate grid-based movement.

---

# 13. TOUCH CONTROLS — CITY MAP

Landscape mobile layout should roughly consist of:

* game/map area as the main focus
* large virtual directional pad
* context-sensitive action button
* status button
* optional end-turn / wait button when relevant
* compact HUD

Use minimum comfortable touch sizes.

Do not require precise tiny taps.

Support:

* tap
* hold where useful
* optional swipe navigation only if it improves usability

The virtual directional controls must be responsive.

Avoid hidden gestures for critical actions.

---

# 14. LOCATIONS

Implement the major original locations.

At minimum research and reproduce:

* Pub
* Arms Dealer
* Car Dealer
* Bank
* Store
* Police Station
* Loan Shark
* Hideout / Apartment
* Forgery
* Gambling
* Subway
* Central Station
* Mayor-related location
* Money Transporter objective

Each location should be implemented as a reusable Godot scene or reusable UI framework.

Do not create one enormous monolithic script containing every location.

Use shared reusable menu/location components where appropriate, with specialized scripts/resources for unique mechanics.

---

# 15. CARS

Research the original vehicle system.

Reproduce as accurately as practical:

* car types
* prices
* movement advantages
* carrying capacity
* usefulness for smuggling
* ownership
* theft where applicable
* buying/selling where applicable
* restrictions and consequences

Keep vehicle data separate from UI logic.

Prefer resources or data tables such as:

`CarData`

with fields such as:

* id
* localized name key
* price
* capacity
* movement value
* relevant risk modifiers

Use actual researched values where available.

---

# 16. WEAPONS

Research and implement the original weapons.

Weapon data should be data-driven.

Possible fields include:

* id
* localized name
* purchase price
* damage
* range
* accuracy
* ammo rules if applicable
* combat restrictions

Do not invent an elaborate modern weapon system if the original doesn't have one.

Reproduce the original tactical differences.

---

# 17. PLAYER AND GANGSTER MODEL

Separate player campaign state from individual gangsters.

The player/gang state may include:

* money
* bank/loan information
* current location
* current vehicle
* inventory
* alcohol/smuggling cargo
* criminal rank
* reputation/fame/danger points
* wanted/police state
* bribery state
* objectives completed
* properties/hideout
* gang membership
* current jobs
* game time/date/turn state

Individual gangsters should hold relevant researched attributes such as:

* name
* sex if part of original mechanics
* health/energy
* strength
* brutality
* weapon
* status
* injuries
* gang role if applicable

Do not place all state in one giant global dictionary.

Use typed classes/resources where useful.

---

# 18. GANG RECRUITMENT

Research:

* how gangsters are recruited
* costs
* prerequisites
* gang size
* rank restrictions
* stats
* naming
* dismissal/death/injury rules

Implement a readable gang-management screen.

On mobile, show each gangster as a clear touch-friendly row/card with:

* name
* health
* weapon
* important attributes

Keep the presentation retro, but readability is more important than perfectly duplicating C64 character-cell limitations.

---

# 19. JOBS AND CRIMES

Research and implement the original crime/job systems.

Examples may include:

* small jobs
* robberies
* safe cracking
* theft
* bank crime
* alcohol smuggling
* contract crimes
* store-related crimes
* pickpocketing
* other original criminal activities

For each activity preserve:

* prerequisites
* probabilities
* rewards
* penalties
* score/fame effects
* police risk
* equipment requirements

Do not normalize every crime into the same generic "success percentage" system unless the original actually behaves that way.

---

# 20. ALCOHOL SMUGGLING

Prohibition-era alcohol smuggling is important to the theme and economy.

Research and reproduce:

* acquisition
* price
* transport capacity
* vehicle interaction
* destination
* reward
* police risk
* profit structure

Present cargo clearly in the HUD/status screen.

---

# 21. POLICE SYSTEM

The police system should preserve the original risk/reward character.

Research:

* police checks
* roadblocks
* arrests
* searches
* illegal weapons
* contraband
* wanted level
* forged papers
* bribery
* court/jail outcomes
* escape possibilities

The system should be harsh where the original is harsh, but the player should receive enough information to understand what happened.

Avoid unfair-feeling invisible rules where modern UI can explain them.

For example, a post-event message may explain:

* why police stopped the player
* what illegal item caused arrest
* what modifier affected the outcome

Do not reveal hidden random numbers unless in a debug mode.

---

# 22. BRIBERY

Research the original bribery mechanics.

Implement them faithfully.

Bribery should influence the correct systems and not simply become a generic permanent "reduce police chance" upgrade unless that is actually how the original works.

Keep bribery state in campaign data and make it visible to the player where appropriate.

---

# 23. FORGERY

Implement forged documents / forged money as supported by original research.

The Atari port contains useful comments about places where its implementation intentionally differs from the original.

Pay particular attention to these comments.

If the C64 behavior is known, prefer it.

---

# 24. LOAN SHARK / DEBT

Research and reproduce:

* borrowing
* limits
* repayment
* interest
* deadlines
* consequences
* intimidation / combat / punishment if applicable

Make debt state easy to inspect.

Do not soften consequences merely because they are harsh unless the original behavior is genuinely broken.

---

# 25. GAMBLING

Implement original gambling mechanics where practical.

Keep the interface fast.

Do not add modern gambling monetization mechanics.

This is strictly an in-game fictional currency system.

No real-money gambling.

---

# 26. RANK / FAME / POINTS

Research the original ranking system carefully.

Implement:

* score/fame/danger points
* rank progression
* prerequisites
* unlocks
* role in victory conditions

Make current rank and progress visible from the status screen.

Do not fabricate arbitrary RPG XP levels.

Use the original system where it can be determined.

---

# 27. ENDGAME

The endgame must preserve the original game's important requirements.

Research exact conditions.

The Atari manual states that merely gaining points is not enough.

The player must ultimately satisfy the required criminal status and complete the major endgame actions involving:

* the mayor
* the money transporter / gold transport

Use the best verified C64 behavior.

Do not allow victory simply by accumulating enough money.

Implement:

* clear endgame progression
* required prerequisites
* final objectives
* victory screen
* final score/status summary

---

# 28. COMBAT

Combat is a major feature.

It must remain turn-based tactical combat.

Do NOT convert it into:

* real-time shooter combat
* action combat
* twin-stick shooting
* auto-battler combat

The basic structure should remain faithful:

* two sides
* multiple gangsters
* each gangster acts in turn
* character may move or attack according to original rules
* directional shooting
* weapon ranges matter
* gangster statistics matter
* health/energy matters
* AI controls enemies
* winner determined by original-style combat outcome

Study:

* `fight.pas`
* `fight_ai.pas`
* `fight_utils.pas`
* related combat variable files

in `drunkeneye/MAFIA.A8`.

---

# 29. TOUCH CONTROLS — COMBAT

Combat controls should be significantly clearer than old keyboard controls.

Recommended touch model:

Large D-pad:

* up
* down
* left
* right

Action mode:

* Move
* Attack
* Skip

When Attack is selected:

* show valid attack directions/range
* player taps direction to shoot

When Move is selected:

* highlight valid movement cells if appropriate

Also provide:

* active gangster indicator
* health
* weapon
* ammunition if applicable
* turn indicator
* enemy indicators

Keep the combat board visually retro.

Do not obscure the arena with huge mobile UI panels.

---

# 30. COMBAT AI

Enemy AI is required.

Use the Atari `fight_ai.pas` implementation as a strong reference.

AI does not need to be modern chess-engine sophistication.

It should reproduce the original game's tactical feel.

Priorities may include:

* choosing viable targets
* moving into range
* avoiding useless movement
* using weapon range intelligently
* pursuing enemies
* shooting when a reasonable shot exists

Keep AI deterministic enough to debug.

Separate AI decision logic from animation/UI.

---

# 31. SAVE SYSTEM

Unlike the original C64 limitations, the Android remake must have robust saving.

Implement:

## Autosave

Autosave after meaningful state changes such as:

* entering/leaving important locations
* completing a job
* combat
* purchases
* arrests
* major missions
* end of turn/month as appropriate

Also save when Android sends the application to the background if practical.

## Manual saves

Provide several manual save slots.

Save files should include a format version.

Design saves so future migrations are possible.

Never serialize raw scene instances as the primary save format.

Serialize campaign data.

Provide:

* Continue
* Load Game
* Save Game

where appropriate.

Prevent accidental save corruption using safe write practices.

---

# 32. QUALITY-OF-LIFE IMPROVEMENTS

Preserve original rules, but modernize UX.

Required QoL improvements include:

* touch-friendly menus
* clear selection highlighting
* autosave
* manual save/load
* fast transitions
* readable HUD
* readable status screens
* contextual help
* immediate button actions without confirmation dialogs
* combat range/movement feedback
* clear police/arrest explanations
* clear objective tracking
* inline hints for new players

Do not radically rebalance the game initially.

---

# 33. ORIGINAL RULES POLICY

Target:

**faithful fixed C64 rules + modern quality-of-life improvements**

Do not deliberately recreate known bugs.

Do not rebalance costs/rewards/probabilities merely because they seem old-fashioned.

First reproduce the original intended rules.

If a mechanic seems frustrating:

1. verify the original behavior
2. improve UI/feedback first
3. only alter the actual rule if necessary
4. document the change

If a gameplay balance change is made, record it in:

`docs/gameplay_differences.md`

Explain:

* original behavior
* remake behavior
* reason for change

---

# 34. OPENING GAME PACING

The early game may be slow.

Do NOT immediately increase rewards or give the player extra starting money.

Instead improve the experience through:

* fast UI
* clear objectives
* minimal loading
* inline hints
* understandable location choices
* clear progression indicators

Only consider balance changes after the faithful version is playable.

---

# 35. UI ARCHITECTURE

Create reusable scene components.

Likely examples:

* `MainMenu`
* `SettingsScreen`
* `CityMap`
* `GameHud`
* `TouchDPad`
* `ContextActionBar`
* `LocationScreen`
* `RetroDialog`
* `StatusScreen`
* `GangScreen`
* `InventoryScreen`
* `CombatScene`
* `CombatHud`
* `SaveLoadScreen`

Do not create every location UI entirely through script.

Use scenes.

Use theme resources for consistent fonts, margins, panels, focus indicators, buttons, and retro colors.

---

# 36. PROJECT ARCHITECTURE

Favor understandable organization such as:

```text
res://
  scenes/
    main/
    map/
    combat/
    locations/
    ui/
  scripts/
    core/
    map/
    combat/
    locations/
    ai/
  data/
    weapons/
    cars/
    gangsters/
    locations/
    jobs/
  assets/
    fonts/
    sprites/
    tiles/
    illustrations/
    audio/
  localization/
  docs/
```

This is an example, not a mandatory exact structure.

Choose a clean structure after inspecting the existing repository.

---

# 37. AUTOLOADS

Use autoloads only when they represent truly global responsibilities.

Reasonable examples:

* GameState
* SaveManager
* SettingsManager
* AudioManager

Do not turn every system into an autoload.

Avoid a massive `GameManager.gd` containing the entire game.

---

# 38. GAME STATE

Use a central campaign model, but break data into logical components.

Game state must survive scene changes.

Separate:

* campaign data
* UI state
* runtime scene state

Do not store important persistent game state only inside scene nodes.

---

# 39. DATA-DRIVEN DESIGN

Use Resources or structured data for things such as:

* cars
* weapons
* jobs
* ranks
* gangsters
* location definitions
* encounter types
* economy constants

Keep game balance values out of giant switch statements where practical.

The goal is to make the original mechanics easy to inspect and adjust.

---

# 40. PIXEL ART RENDERING

Configure Godot for crisp pixel art.

Avoid blurry texture filtering.

Use:

* nearest filtering where appropriate
* integer or carefully controlled scaling where appropriate
* a low-resolution internal game canvas if this provides the best result
* aspect-safe scaling for landscape phones

Test several common ratios:

* 16:9
* 18:9
* 19.5:9
* 20:9

UI must remain usable without stretching pixel art unnaturally.

---

# 41. SAFE AREAS

Account for:

* rounded phone corners
* notches
* camera cutouts
* gesture navigation regions

Do not place essential buttons against unsafe edges.

---

# 42. AUDIO

Research the original sound/music style.

Create or use legally reusable audio that evokes:

* C64 / Atari-era chip sound
* 1920s crime atmosphere
* simple short effects
* restrained retro music

Provide independent settings for:

* music volume
* sound volume

Allow muting.

Do not require internet access for audio.

---

# 43. SETTINGS

Settings should include at least:

* language
* music volume
* sound volume
* vibration/haptics if implemented
* inline hints on/off
* optional touch-control sizing if useful

Persist settings separately from savegames.

---

# 44. TUTORIAL

Provide lightweight, non-blocking inline help.

It should teach:

* city movement
* entering locations
* earning initial money
* buying equipment
* status screen
* cars
* police risk
* gang recruitment when unlocked
* tactical combat when first encountered

Do not interrupt experienced players constantly.

Inline hints should be disableable in Settings and require no dismissal.

---

# 45. DEVELOPMENT / DEBUG TOOLS

Create development helpers that make testing easier.

Useful debug features may include:

* jump to location
* set money
* set rank
* add weapon
* add vehicle
* create gangsters
* trigger police event
* start test combat
* trigger mayor objective
* trigger transporter objective

Debug tools must not appear in normal release gameplay.

Use them to avoid manually grinding through the campaign during development.

---

# 46. TESTING

Test gameplay logic independently where practical.

At minimum create tests or deterministic validation for:

* save/load round-trip
* rank progression
* economic transactions
* weapon data
* car data
* gang recruitment
* combat damage/range logic
* combat AI basic decisions
* victory-condition logic
* localization resource availability

Use deterministic RNG seeds for tests where randomness is involved.

---

# 47. GODOT HEADLESS VALIDATION

Regularly run Godot headless validation where possible.

Examples:

* project imports without fatal errors
* scenes load
* scripts parse
* tests run

Fix warnings/errors caused by your changes.

Do not leave the repository in a state where Godot opens with broken script references.

---

# 48. ANDROID VALIDATION

The existing repository already has an Android export preset.

Preserve and improve it as needed.

Validate:

* landscape orientation
* touch controls
* safe area
* pixel scaling
* Android back button behavior
* save paths
* app suspend/resume
* performance
* no reliance on desktop-only APIs

Do not require internet permission unless the actual shipped game needs internet.

The final game should be playable completely offline.

---

# 49. PERFORMANCE

This is a lightweight 2D game.

It should perform smoothly on modest Android hardware.

Avoid:

* unnecessary full-screen shaders
* huge uncompressed textures
* excessive node creation every frame
* constant allocation in `_process()`
* polling when signals/events are sufficient

---

# 50. BUILD ORDER

Work in coherent vertical slices.

Recommended order:

## Phase 1 — Research and architecture

* inspect repository
* read all reference material
* research the original C64 version
* document key rules
* establish folder structure
* establish localization
* establish global campaign model
* establish pixel rendering strategy

## Phase 2 — Core shell

* boot scene
* main menu
* settings
* localization
* save manager
* base retro theme
* responsive landscape UI

## Phase 3 — City map

* reconstruct map
* player movement
* touch controls
* location detection
* HUD
* status
* basic map transitions

## Phase 4 — First playable economy loop

Implement enough locations to allow:

* earning money
* buying something
* moving around the city
* saving/loading
* progressing

## Phase 5 — Cars and smuggling

* vehicles
* vehicle movement effects
* cargo
* alcohol
* smuggling
* relevant police risk

## Phase 6 — Gang system

* recruitment
* gangster stats
* gang-management screen
* equipment

## Phase 7 — Combat

* combat arena
* turn system
* movement
* shooting
* weapons
* health
* enemy AI
* combat results

## Phase 8 — Crime/police systems

* robberies
* arrests
* police searches
* forgery
* bribery
* court/jail
* debt
* loan shark

## Phase 9 — Progression

* ranks
* points
* unlocks
* advanced jobs
* escalating criminal activities

## Phase 10 — Endgame

* mayor objective
* money transporter objective
* victory logic
* ending screen

## Phase 11 — Polish

* tutorial
* audio
* improved pixel assets
* location illustrations
* animation
* accessibility/readability
* save robustness
* Android testing
* performance

Do not attempt to build every subsystem simultaneously.

But do not stop merely because one phase is complete.

Continue to the next logical phase as long as the repository remains stable.

---

# 51. ACCEPTANCE CRITERIA

The game is not considered complete merely because the city map opens.

A meaningful completed implementation should allow a fresh player to:

1. launch the Android game
2. choose German or English
3. start a new game
4. learn basic controls
5. move around Chicago
6. enter locations
7. perform initial jobs/crimes
8. earn and spend money
9. buy or obtain equipment
10. acquire/use a vehicle
11. interact with the police system
12. participate in smuggling/criminal activities
13. recruit a gang
14. manage gangster equipment/health
15. enter tactical combat
16. fight AI opponents
17. progress through ranks
18. save and resume the game
19. unlock late-game content
20. complete the mayor objective
21. complete the money-transporter objective
22. satisfy the original-style victory conditions
23. reach a proper ending screen

---

# 52. DO NOT DO THESE THINGS

Do not:

* implement the Sascha Laffrenzen Mafia game
* convert the game into an action shooter
* convert tactical combat to real-time
* make it multiplayer
* add gacha
* add ads
* add microtransactions
* add online accounts
* add backend services
* add unnecessary networking
* add a generic joystick overlay without redesigning the UI
* create major visual elements entirely by script when a scene is more appropriate
* put the whole game into one script
* hardcode all English/German strings in gameplay code
* blindly copy unlicensed third-party assets
* intentionally reproduce known C64 bugs
* arbitrarily rebalance the game before reproducing the original behavior
* stop after producing empty architecture or TODO stubs

---

# 53. WHEN INFORMATION IS MISSING

If you do not know how an original mechanic works:

1. search the internet
2. inspect C64 references
3. inspect the Atari implementation
4. compare several sources where possible
5. implement the most defensible behavior
6. document uncertainty

Do not block progress waiting for user clarification unless the decision fundamentally changes the requested game.

The user's preferences are already defined:

* game: Mafia by Igelsoft
* original platform reference: C64
* target: Android
* engine: Godot 4.7
* single-player only
* German + English
* German default
* landscape orientation
* C64 look enhanced for modern phones
* faithful fixed original rules
* modern QoL
* touch-first controls

Use these decisions and continue.

---

# 54. KEEP DOCUMENTATION UPDATED

Maintain:

`README.md`

with:

* game description
* development status
* controls
* desktop testing
* Android testing/build instructions
* known limitations

Also maintain:

`docs/original_game_research.md`

for researched original behavior.

And:

`docs/gameplay_differences.md`

for intentional differences between the remake and verified C64 behavior.

If useful also add:

`docs/architecture.md`

to explain major systems in simple terms.

---

# 55. CODE QUALITY

This project is also intended to be understandable by someone learning Godot and GDScript.

Therefore:

* favor readability over clever abstractions
* keep functions reasonably small
* use descriptive typed variables
* explain important formulas
* explain unusual original-game behavior
* avoid unnecessary design patterns
* avoid premature abstraction
* avoid giant state machines where smaller components are clearer
* avoid magic numbers
* place researched game constants in meaningful data structures

Code should be easy to inspect from the Godot editor.

---

# 56. WORKING STYLE

At the beginning of each work session:

1. inspect current repository state
2. read TODO/research documentation
3. identify the next incomplete vertical slice
4. implement it
5. validate scripts/scenes
6. run tests
7. update documentation
8. continue with the next useful slice

When modifying existing code, understand it before replacing it.

Prefer incremental commits/logical changes over wholesale rewrites.

---

# 57. FIRST TASK

Start now.

Your first actions should be:

1. Read `AGENTS.md`.
2. Inspect the complete local repository.
3. Inspect the reference repository `https://github.com/drunkeneye/MAFIA.A8`.
4. Research the Igelsoft C64 version from the supplied sources and additional reliable sources.
5. Create `docs/original_game_research.md`.
6. Record the major game systems, locations, progression, combat model, and victory conditions.
7. Determine an appropriate Godot architecture.
8. Establish the base project structure.
9. Configure landscape/mobile/pixel-art settings.
10. Implement localization architecture.
11. Implement the main menu/settings shell.
12. Implement the campaign data/save foundation.
13. Begin the city-map vertical slice.

Do not ask the user to choose things already specified above.

When details are uncertain, research them and make a documented best-effort decision.

Continue implementing the game.
