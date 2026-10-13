extends SceneTree

var failures: int = 0
var checks: int = 0
var state: Node
var saves: Node

func _initialize() -> void:
	call_deferred("_run")

func check(condition: bool, description: String) -> void:
	checks += 1
	if not condition:
		failures += 1
		push_error(description)

func fresh(seed_value: int = 100) -> Campaign:
	state.new_game("Tester", "Test gang", false, 0, seed_value)
	return state.campaign

func _run() -> void:
	state = root.get_node("GameState")
	saves = root.get_node("SaveManager")
	_test_data()
	_test_campaign()
	_test_economy()
	_test_crime()
	_test_combat()
	_test_saves()
	await _test_scenes()
	print("RESULT: %d checks, %d failures" % [checks, failures])
	quit(0 if failures == 0 else 1)

func _test_data() -> void:
	check(Catalog.all() == saves._normalize_numbers(JSON.parse_string(FileAccess.get_file_as_string("res://data/game.json"))), "Resource and source definitions match")
	check(Catalog.all()["weapons"].size() == 9, "Nine weapons")
	check(Catalog.all()["cars"].size() == 6, "Six movement modes")
	for item: Dictionary in Catalog.all()["weapons"]:
		check(item["range"] > 0 and item["precision"] > 0 and item["damage"] > 0, "Weapon values positive")
	for item: Dictionary in Catalog.all()["cars"]:
		check(item["capacity"] >= 50 and item["movement"] >= 25, "Vehicle values valid")
	for locale: String in ["de", "en"]:
		TranslationServer.set_locale(locale)
		var csv := FileAccess.open("res://localization/strings.csv", FileAccess.READ)
		csv.get_csv_line()
		while not csv.eof_reached():
			var row := csv.get_csv_line()
			if row.size() == 1 and row[0].is_empty(): continue
			check(row.size() == 3 and not row[1].is_empty() and not row[2].is_empty() and TranslationServer.translate(row[0]) != row[0], "Complete translation " + locale + " " + row[0])
		for key: String in ["NEW_GAME", "SAVE_INVALID", "SAFE_HELP", "VICTORY", "RANK_10"]:
			check(TranslationServer.translate(key) != key, "Translation: " + locale + " " + key)
		for item: Dictionary in Catalog.locations():
			check(TranslationServer.translate(item["name_key"]) != item["name_key"], "Location translation")
		for kind: String in ["pub", "station", "arms", "cars", "store", "bank", "hideout", "loan", "police", "forgery", "subway", "casino", "mayor", "transport"]:
			for action: String in LocationRules.actions(kind):
				check(TranslationServer.translate("ACT_" + action.to_upper()) != "ACT_" + action.to_upper(), "Action localized")
	TranslationServer.set_locale("de")
	# Every location entrance must be reachable from the starting street network.
	var reached := {Vector2i(3, 3): true}
	var queue: Array[Vector2i] = [Vector2i(3, 3)]
	var cursor := 0
	while cursor < queue.size():
		var cell := queue[cursor]
		cursor += 1
		for direction: Vector2i in CityRules.DIRECTIONS:
			var next := cell + direction
			if CityRules.walkable(next) and not reached.has(next):
				reached[next] = true
				queue.append(next)
	for location: Dictionary in Catalog.locations():
		var accessible := false
		for direction: Vector2i in CityRules.DIRECTIONS:
			accessible = accessible or reached.has(Vector2i(location["x"], location["y"]) + direction)
		check(accessible, "Reachable entrance: " + location["id"])

func _test_campaign() -> void:
	var c := fresh()
	check(c.gang.size() == 1 and c.gang[0].energy == 5 and c.gang[0].weapon == 0, "Starting gang")
	check(c.economy.money >= 5000 and c.economy.money <= 7000, "Starting cash range")
	var original := c.to_dict()
	var same := fresh()
	check(original == same.to_dict(), "Seeded new game repeatable")
	state.move(Vector2i.LEFT)
	check(same.position == Vector2i(2, 3) and same.steps == 24, "Grid movement costs step")
	state.move(Vector2i.UP)
	check(same.position == Vector2i(2, 3) and same.steps == 24, "Blocked movement costs nothing")
	c = fresh()
	c.points = 45
	check(c.rank == 0, "Rank waits for month")
	state.advance_month()
	check(c.rank == 5, "Promotion threshold")
	c.add_points(-40)
	state.advance_month()
	check(c.rank == 5, "Rank retained after points loss")
	c.economy.car = 3
	state.advance_month()
	check(c.steps == 40, "Car refreshes next month's allowance")
	c.points = 100
	check(not c.objectives.won(c.points, c.goal), "Points alone cannot win")
	c.objectives.mayor_completed = true
	check(not c.objectives.won(c.points, c.goal), "One mission cannot win")
	c.objectives.transporter_completed = true
	state.commit()
	check(c.objectives.ending == "VICTORY", "All victory prerequisites")
	c = fresh()
	c.month = 300
	state.advance_month()
	check(c.objectives.ending == "TIME_UP", "Campaign deadline")

func _test_economy() -> void:
	var c := fresh()
	var initial := c.economy.money
	check(not c.economy.pay(-100) and c.economy.money == initial, "Negative transaction rejected")
	check(not c.economy.pay(initial + 1) and c.economy.money == initial, "Insufficient money does not mutate")
	EconomyRules.buy_weapon(c, 0, 7)
	check(c.gang[0].weapon == 0 and c.economy.money == initial, "Weapon requirements enforced")
	c.gang[0].strength = 99
	c.gang[0].intelligence = 99
	c.gang[0].brutality = 99
	c.economy.money = 20000
	EconomyRules.buy_weapon(c, 0, 7)
	check(c.gang[0].weapon == 7 and c.economy.money == 12000, "Buy weapon")
	EconomyRules.buy_car(c, 3)
	check(c.economy.car == 3 and c.economy.money == 7000, "Buy car")
	EconomyRules.smuggle(c, true, 201)
	check(c.economy.cargo == 0, "Cargo capacity enforced")
	EconomyRules.smuggle(c, true, 100)
	check(c.economy.cargo == 100, "Buy smuggling cargo")
	for attempt in 20:
		EconomyRules.smuggle(c, false, 100)
		if c.economy.cargo == 0: break
	check(c.economy.cargo == 0, "Sell cargo")
	c.economy.money = 30000
	c.rank = 5
	EconomyRules.recruit(c, 0)
	check(c.gang.size() == 1, "Hideout prerequisite")
	EconomyRules.rent(c, 12)
	EconomyRules.recruit(c, 0)
	check(c.gang.size() == 2 and c.gang[1].energy == 5, "Recruit with rent and rank")
	EconomyRules.recruit(c, 0)
	check(c.gang.size() == 2, "Duplicate recruit rejected")
	c.gang[0].strength = 30
	EconomyRules.train(c, 0, false)
	var energy := c.economy.money
	EconomyRules.train(c, 0, false)
	check(c.gang[0].strength == 35 and c.economy.money == energy, "Monthly training limit")
	LocationRules.perform(c, "borrow", 5000, 0, 0)
	check(c.economy.debt == 5312 and c.economy.debt_months >= 6, "Debt interest and deadline")
	LocationRules.perform(c, "repay", 5312, 0, 0)
	check(c.economy.debt == 0, "Debt repayment")
	PoliceRules.protection(c, 2)
	check(c.police.bribe_months == 2, "Temporary commissioner bribe")
	state.advance_month()
	check(c.police.bribe_months == 1, "Protection expires monthly")

func _test_crime() -> void:
	var c := fresh(777)
	c.rank = 5
	c.gang[0].strength = 40
	c.gang[0].intelligence = 40
	c.gang[0].brutality = 40
	c.location = "bank"
	CrimeRules.bank(c, true)
	check(c.safe.size() > 0 and c.safe["code"].size() == 3, "Solo safe minigame")
	c.safe["attempts"] = 1
	c.safe["code"] = [9, 9, 9]
	c.safe["wheels"] = [0, 0, 0]
	CrimeRules.safe_move(c, Vector2i.UP)
	check(c.safe.is_empty() and not c.combat.is_empty(), "Safe failure triggers police fight")
	c = fresh()
	c.objectives.tips = 4
	CrimeRules.mission(c, "transport")
	check(c.combat.is_empty() and c.objectives.tips == 4, "Transport requires three gangsters")
	c.police.encounter = "COURT"
	c.rank = 5
	c.objectives.tips = 31
	PoliceRules.court(c)
	check(c.police.prison_months == 3 and c.objectives.tips == 0 and c.steps == 0, "Court sentence and cancellation")
	c.economy.debt = 1000
	c.economy.debt_months = 0
	EconomyRules.monthly(c)
	check(c.combat["reason"] == "debt", "Overdue debt collectors")

func _test_combat() -> void:
	var c := fresh()
	c.gang[0].weapon = 5
	c.gang[0].strength = 99
	c.gang[0].brutality = 99
	CombatRules.start(c, "police", 1, 0, 20)
	var units: Array = c.combat["units"]
	units[0]["x"] = 4
	units[0]["y"] = 4
	units[1]["x"] = 9
	units[1]["y"] = 4
	check(CombatRules.target(c.combat, 0, Vector2i.RIGHT) == 1, "Cardinal target in range")
	units.append(units[0].duplicate())
	units[2]["x"] = 7
	check(CombatRules.target(c.combat, 0, Vector2i.RIGHT) == 1, "C64 shots pass through allies")
	units.pop_back()
	units[1]["x"] = 25
	check(CombatRules.target(c.combat, 0, Vector2i.RIGHT) == -1, "Range enforced")
	units[1]["x"] = 9
	var choice := CombatAi.decide(c)
	check(choice["mode"] == "attack" and choice["direction"] == Vector2i.RIGHT, "AI chooses clear shot")
	check(not CombatRules.act(c, "move", Vector2i(-4, 0)), "Invalid direction rejected")
	check(CombatRules.act(c, "move", Vector2i.DOWN) and c.combat["active"] == 1, "Move consumes one action")
	CombatRules.finish(c, false)
	check(c.gang[0].energy >= 5 and c.police.encounter == "COURT", "Combat loss recovery and court")
	c = fresh(777)
	c.economy.money = 100000
	c.rank = 5
	c.economy.has_hideout = true
	for index in 7: EconomyRules.recruit(c, index)
	for person in c.gang:
		person.strength = 99
		person.brutality = 99
		person.intelligence = 99
		person.energy = 99
		person.weapon = 7
	c.objectives.tips = 16
	var points_before := c.points
	CrimeRules.mission(c, "mayor")
	_auto_fight(c)
	check(c.objectives.mayor_completed and c.points == points_before, "Mayor two fights, no invented score bonus")
	for person in c.gang: person.energy = 99
	c.objectives.tips = 4
	CrimeRules.mission(c, "transport")
	_auto_fight(c)
	check(c.objectives.transporter_completed, "Ten-guard transporter combat can be won")

func _auto_fight(c: Campaign) -> void:
	for turn in 4000:
		if c.combat.is_empty(): return
		var action := CombatAi.decide(c)
		CombatRules.act(c, action["mode"], action["direction"])
	check(false, "Combat failed to terminate")

func _test_saves() -> void:
	var c := fresh()
	check(saves.save_campaign(c, "slot1"), "Write save")
	var expected := c.to_dict()
	var loaded: Campaign = saves.load_campaign("slot1")
	check(loaded != null and loaded.to_dict() == expected, "Save round-trip")
	check(c.rng.randi() == loaded.rng.randi(), "RNG preserved")
	CombatRules.start(c, "job", 1, 0, 20)
	c.job = {"id": "street", "months": 1, "wage": 1500, "points": 3}
	check(saves.save_campaign(c, "slot2"), "Active encounter saved")
	loaded = saves.load_campaign("slot2")
	check(loaded.combat == c.combat and loaded.job == c.job, "Combat and job state round-trip")
	var malformed := {"format_version": 1, "campaign": c.to_dict()}
	malformed["campaign"]["combat"]["units"][0]["member"] = 50
	check(not saves.validate(malformed), "Combat member reference rejected")
	malformed = {"format_version": 1, "campaign": c.to_dict()}
	malformed["campaign"]["combat"]["units"][0]["x"] = 1.5
	check(not saves.validate(malformed), "Fractional combat position rejected")
	malformed = {"format_version": 1, "campaign": c.to_dict()}
	malformed["campaign"]["job"]["id"] = "unknown"
	check(not saves.validate(malformed), "Unknown job rejected")
	c.economy.money += 100
	check(saves.save_campaign(c, "slot1"), "Backup created")
	var file := FileAccess.open("user://slot1.json", FileAccess.WRITE)
	file.store_string("{broken")
	file.close()
	loaded = saves.load_campaign("slot1")
	check(loaded != null and saves.recovered_backup and loaded.to_dict() == expected, "Corrupt primary recovers last good backup")
	var invalid := {"format_version": 999, "campaign": expected}
	check(not saves.validate(invalid), "Unsupported save version rejected")
	invalid = {"format_version": 1, "campaign": expected.duplicate(true)}
	invalid["campaign"]["gang"][0]["weapon"] = 100
	check(not saves.validate(invalid), "Out-of-range data rejected")
	check(not saves.save_campaign(c, "../bad"), "Invalid slot rejected")

func _test_scenes() -> void:
	for path: String in ["res://scenes/main/main.tscn", "res://scenes/map/city_board.tscn", "res://scenes/combat/combat_board.tscn", "res://scenes/locations/location_panel.tscn"]:
		check(load(path) is PackedScene, "Scene loads: " + path)
	var shell: Variant = load("res://scenes/main/main.tscn").instantiate()
	root.add_child(shell)
	await process_frame
	check(shell.route == "Menu", "Main menu boots")
	check(not quit_on_go_back, "Android Back handled by the game")
	check(shell.get_node("%Background").mouse_filter == Control.MOUSE_FILTER_IGNORE, "Full-screen background does not consume touches")
	check(shell.get_node("%Background").stretch_mode == TextureRect.STRETCH_KEEP_ASPECT_COVERED, "Artwork covers the whole screen without distortion")
	check(shell.theme.has_stylebox("normal", "PrimaryButton"), "Modern theme distinguishes primary actions")
	root.get_node("Settings").hints = true
	shell.get_node("%New").pressed.emit()
	shell.get_node("%Start").pressed.emit()
	await process_frame
	check(shell.route == "Game" and state.campaign != null, "Start opens campaign in one press")
	check(not shell.has_node("ConfirmOverlay"), "No confirmation or tutorial overlay")
	check(not shell.get_node("%ActiveInfo").text.is_empty(), "City hints remain inline")
	var starting_steps: int = state.campaign.steps
	shell.get_node("%DPad/Right").button_down.emit()
	shell.get_node("%DPad/Right").button_up.emit()
	check(state.campaign.steps == starting_steps - 1, "Hints do not block movement")
	shell.get_node("%Wait").pressed.emit()
	check(state.campaign.month == 1, "Wait advances month in one press")
	shell.get_node("%Back").pressed.emit()
	check(shell.route == "Menu", "Back navigates immediately with hints enabled")
	shell._game()
	state.campaign.position = Vector2i(5, 3)
	shell.get_node("%Enter").pressed.emit()
	await process_frame
	check(shell.route == "Location", "Scene-based location opens")
	check(shell.get_node("%LocationPanel/LocationHint").visible, "Location hints are inline")
	var recruit_button: Button = shell.get_node("%LocationPanel/ActionScroll/Actions").get_child(2)
	recruit_button.pressed.emit()
	check(recruit_button.button_pressed and not shell.get_node("%LocationPanel/ActionScroll/Actions").get_child(0).button_pressed, "Location action selection has a single highlight")
	check(shell.get_node("%LocationPanel/Parameters/Item").item_count == 30, "Recruit offers shown")
	state.campaign.rank = 5
	state.campaign.economy.has_hideout = true
	var cash_before: int = state.campaign.economy.money
	shell.get_node("%LocationPanel/Parameters/Execute").pressed.emit()
	check(state.campaign.gang.size() == 2 and state.campaign.economy.money < cash_before and state.campaign.location.is_empty(), "Execute recruits immediately with selected parameters")
	shell._saves(true)
	shell.get_node("%Slot1").pressed.emit()
	state.campaign.gang_name = "Immediate overwrite"
	state.campaign.tutorials.append("city")
	shell.get_node("%Slot1").pressed.emit()
	check(saves.load_campaign("slot1").gang_name == "Immediate overwrite", "Occupied save overwrites in one press")
	check(shell.get_node("%SaveMessage").text == TranslationServer.translate("SAVE_OK"), "Save success remains visible")
	state.campaign.gang_name = "Unsaved change"
	shell._saves(false)
	shell.get_node("%Slot1").pressed.emit()
	check(state.campaign.gang_name == "Immediate overwrite" and shell.route == "Game", "Load replaces campaign in one press")
	check("city" in state.campaign.tutorials, "Legacy tutorial field survives save and load")
	# Invalid campaign data exercises the existing save-error message without changing files.
	shell._saves(true)
	state.campaign.gang[0].weapon = 100
	shell.get_node("%Slot1").pressed.emit()
	check(shell.get_node("%SaveMessage").text == TranslationServer.translate("SAVE_FAILED"), "Save failure remains visible")
	state.campaign.gang[0].weapon = 0
	shell._load("missing")
	check(shell.route == "SaveScreen" and shell.get_node("%SaveMessage").text == TranslationServer.translate("SAVE_INVALID"), "Load failure remains visible")
	shell._open_settings()
	shell.get_node("%Language").select(1)
	shell._apply_settings()
	check(root.get_node("Settings").language == "en", "English settings switch")
	CombatRules.start(state.campaign, "job", 1, 0, 20)
	shell._game()
	await process_frame
	check(shell.get_node("%CombatBoard").visible and not shell.get_node("%CityBoard").visible, "Full-screen combat objects displayed")
	check(shell.get_node("%CombatHint").visible, "Combat hints are inline")
	shell.get_node("%AttackMode").pressed.emit()
	check(shell.get_node("%AttackMode").button_pressed and not shell.get_node("%MoveMode").button_pressed, "Combat mode selection is highlighted")
	state.campaign.combat["active"] = state.campaign.combat["units"].size() - 1
	shell._game()
	check(not shell.get_node("%AiTimer").is_stopped(), "Hints do not pause enemy turns")
	var round_before: int = state.campaign.combat["round"]
	shell._ai_turn()
	check(state.campaign.combat["round"] > round_before, "Enemy turn executes with hints enabled")
	shell.get_node("%GiveUp").pressed.emit()
	check(state.campaign.combat.is_empty() and state.campaign.messages.back()["key"] == "COMBAT_LOST", "Give Up resolves defeat in one press")
	root.get_node("Settings").hints = false
	CombatRules.start(state.campaign, "job", 1, 0, 20)
	shell._game()
	check(not shell.get_node("%CombatHint").visible, "Combat hint follows setting")
	state.campaign.combat = {}
	state.campaign.location = "arms"
	shell._game()
	check(not shell.get_node("%LocationPanel/LocationHint").visible, "Location hint follows setting")
	state.campaign.location = ""
	shell._game()
	check(shell.get_node("%ActiveInfo").text.is_empty(), "City hint follows setting")
	var presentation: Variant = shell.get_node("%MapWorld")
	check(presentation.mouse_filter == Control.MOUSE_FILTER_IGNORE, "Map scenery leaves touch input to controls")
	check(not shell.get_node("%Background").visible and presentation.visible, "Gameplay uses top-down scenery")
	var terrains := {"job": "street", "debt": "street", "collect": "street", "police": "street", "theft": "street", "store": "shop", "bank": "bank", "train": "train", "transport": "warehouse", "mayor": "mayor", "mayor_guards": "mayor"}
	for reason: String in terrains:
		CombatRules.start(state.campaign, reason, 10, 5, 30)
		shell._game()
		check(presentation.current_art == terrains[reason] and presentation.get_node("Terrain").texture != null, "Combat terrain: " + reason)
	for obstacle: Sprite2D in shell.get_node("%CombatBoard/Cover").get_children():
		check(Vector2i(obstacle.position / 10) in CombatRules.WALLS, "Cover matches collision at " + str(obstacle.position))
		check(obstacle.texture.get_size() == Vector2(20, 20), "Cover matches two-cell footprint")
	for combat: bool in [false, true]:
		presentation.combat_visible = combat
		for width: int in [1152, 1296, 1404, 1440]:
			var clear_area := Rect2(24, 130, width - 348, 410)
			presentation.fit_to(clear_area)
			check(clear_area.grow(1).encloses(presentation.map_rect), "Whole grid fits clear area: %s/%d" % [combat, width])
			var expected_ratio := 2.0 if combat else 4.0 / 3.0
			check(is_equal_approx(presentation.map_rect.size.x / presentation.map_rect.size.y, expected_ratio), "Map scaling preserves aspect ratio")
	state.campaign.combat = {}
	for location: Dictionary in Catalog.locations():
		state.campaign.location = location["id"]
		shell._game()
		check(shell.get_node("%Background").current_art == location["kind"] and shell.get_node("%Background").texture != null, "Location backdrop loads: " + str(location["kind"]))
	state.campaign.location = ""
	state.campaign.objectives.ending = "VICTORY"
	shell._game()
	check(shell.route == "EndingScreen", "Completed campaign shows ending scene")
	shell.get_node("%MusicPlayer").stop()
	shell.get_node("%SoundPlayer").stop()
	await create_timer(0.1).timeout
	shell.queue_free()
	await process_frame
