# Architecture

`scenes/main/main.tscn` contains the menus, settings, status, save slots, forms,
location view, police/court view, safe puzzle and ending. Controls are visible in
the editor. `scripts/ui/main.gd` connects their signals and selects the current
screen; it does not create a UI tree. Location actions instantiate the reusable
`scenes/ui/action_row.tscn`. Units and map markers also use authored scenes.

The full-screen `Background` TextureRect uses aspect-preserving cover scaling
and ignores touch input. Its small `screen_background.gd` script chooses a
background only when the screen changes: location kind, safe,
police, ending or the shared hideout for utility screens. It does not keep an
array of all decoded backgrounds or update artwork per frame. The source art
and exact built-in ImageGen prompts are under `assets/backgrounds/`.

`assets/android_theme.tres` provides rounded navy panels, amber primary actions,
clear selected/disabled states, slider handles and toggles, plus bundled Adwaita
Sans with its font license. Cards, scroll containers and large D-pad buttons are
scene-authored. Location actions and combat modes show one active selection.
Gameplay actions execute immediately; inline hints require no dismissal.

The three autoloads have separate responsibilities:

- `Settings` loads a separate ConfigFile, applies translations and volume levels.
- `SaveManager` validates and serializes campaigns, temporary writes and backups.
- `GameState` owns the campaign and coordinates moves, monthly turns and autosaves.

`Campaign` holds typed gangster, economy, police and objective objects. Gameplay
rules in `scripts/locations/` mutate those objects, append localized message keys,
and use the campaign's seeded RNG. Combat stores its board, active actor and turn
in the campaign, so saving during a fight preserves the encounter. `CombatAi`
chooses a cardinal shot or uses breadth-first search to reach a firing position.
The UI then calls the same combat action method used by the tests.

`GameDefinitions` is an editor-inspectable Resource in
`data/game_definitions.tres`; `Catalog` provides accessors. `data/game.json` is the
human-readable source mirror. When changing definitions, update both files; JSON
object syntax is also valid for the Resource's `tables` dictionary. Research
citations and unresolved differences belong in the two research documents.

Gameplay uses a full-screen scene-authored `MapWorld` behind the controls, with
live city/combat Node2D scenes rather than inset SubViewports. Its terrain covers
the display; the complete 320×240 city or 400×200 battle grid scales uniformly
into the clear `MapArea` beside the controls. Fitting runs after container layout
changes, not per frame. The city image follows the exact street grid, and only
its non-playable outer border blends into decorative rooftop surroundings.
Combat terrain has no interior obstacles baked in: three authored cover sprites
match the existing two-cell collision positions. Existing campaign reasons select
street, shop, bank, train, warehouse or mayor terrain without adding save fields.
Generated character sprites, location markers and terrain use nearest filtering.
`assets/maps/prompts.json` records the built-in ImageGen prompts and original
source paths; `tools/prepare_map_art.gd` trims transparent padding and downsamples
those originals into small game assets. Scene-authored objects retain logical
cell positions. Street annotations counter-scale to remain readable: a cropped
26-pixel player character sits inside a cyan ring, and reusable location badges
show short translated labels and exact entrance connectors. Labels move below a
raised badge if their normal rooftop position would overlap the player. Terrain
is dimmed separately from annotations, and a top margin reserves label space.
UI controls scale independently, preserving text and touch targets.

Android platform Back requests are coalesced within 50 ms because a single press
can deliver a duplicate request. The first request navigates immediately; on-screen
buttons bypass this duplicate filter.
The scene responds to viewport changes and applies Android safe-area margins.
Only the hold-movement and enemy-action timers run repeated gameplay callbacks.
No server, account, advertising or Internet permission is involved.

Persistence format 1 has one autosave and three manual slots. Integer data is
validated before construction, RNG state is serialized as a string to retain all
64 bits, and save snapshots deep-copy encounter dictionaries. A failed primary
load tries the last validated backup. Saves/settings are under `user://`; tests
use a separate XDG data root to avoid modifying a developer's campaign.

Development helpers are visible only in debug builds (F9). They are for targeted
verification, and must not substitute for ordinary progression testing.
