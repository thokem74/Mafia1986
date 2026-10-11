# Architecture

`scenes/main/main.tscn` contains the menus, settings, status, save slots, dialogs,
location view, police/court view, safe puzzle and ending. Controls are visible in
the editor. `scripts/ui/main.gd` connects their signals and selects the current
screen; it does not create a UI tree. Location actions instantiate the reusable
`scenes/ui/action_row.tscn`. Units and map markers also use authored scenes.

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

City and combat art render at 320×240 and 400×200 inside SubViewports. The main
Control scene scales independently, preserving readable text and touch targets.
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
