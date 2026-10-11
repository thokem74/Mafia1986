extends Control

const SCREENS := ["Menu", "NewGame", "SettingsScreen", "Game", "Location", "StatusScreen", "SaveScreen", "PoliceScreen", "SafeScreen", "EndingScreen", "CreditsScreen", "DebugScreen"]
var route: String = "Menu"
var return_route: String = "Menu"
var saving: bool = false
var confirmation: Callable
var setting_up: bool = false
@onready var music_player: AudioStreamPlayer = %MusicPlayer
@onready var sound_player: AudioStreamPlayer = %SoundPlayer

func _ready() -> void:
	get_tree().auto_accept_quit = false
	get_tree().quit_on_go_back = false
	GameState.changed.connect(_campaign_changed)
	Settings.changed.connect(_settings_changed)
	get_viewport().size_changed.connect(_safe_area)
	%New.pressed.connect(func(): _show("NewGame"))
	%Continue.pressed.connect(func(): _load("autosave"))
	%Load.pressed.connect(func(): _saves(false))
	%Settings.pressed.connect(_open_settings)
	%Credits.pressed.connect(func(): _show("CreditsScreen"))
	%Quit.pressed.connect(_quit)
	%Back.pressed.connect(_back)
	%MenuButton.pressed.connect(func(): _show("Menu"))
	%Start.pressed.connect(func(): _confirm(tr("CONFIRM_NEW"), _new_game))
	%Apply.pressed.connect(_apply_settings)
	%StatusButton.pressed.connect(func(): _show("StatusScreen"); _status())
	%SaveButton.pressed.connect(func(): _saves(true))
	%LoadButton.pressed.connect(func(): _saves(false))
	%Leave.pressed.connect(func(): GameState.leave(); _game())
	%DPad.direction_pressed.connect(_direction)
	%SafeDPad.direction_pressed.connect(_safe_direction)
	%SafeDPad.repeat_enabled = false
	%Enter.pressed.connect(_enter)
	%Wait.pressed.connect(func(): _confirm(tr("CONFIRM_WAIT"), GameState.advance_month))
	%MoveMode.pressed.connect(func(): _mode("move"))
	%AttackMode.pressed.connect(func(): _mode("attack"))
	%Skip.pressed.connect(func(): _combat_action("skip"))
	%GiveUp.pressed.connect(func(): _confirm(tr("CONFIRM_FLEE"), _give_up))
	%SafeCancel.pressed.connect(func(): GameState.campaign.safe = {}; GameState.commit(); _game())
	%LocationPanel.action_requested.connect(_location_action)
	%Search.pressed.connect(func(): _police("search"))
	%Bribe.pressed.connect(func(): _police("bribe"))
	%Escape.pressed.connect(func(): _police("escape"))
	%Court.pressed.connect(func(): _police("court"))
	%ConfirmYes.pressed.connect(_confirmed)
	%ConfirmNo.pressed.connect(_cancel_confirmation)
	%AiTimer.timeout.connect(_ai_turn)
	%MusicPlayer.finished.connect(func(): %MusicPlayer.play())
	for index in range(4):
		get_node("%%Slot%d" % index).pressed.connect(_slot.bind(index))
	for pair: Array in [[%DebugMoney, "money"], [%DebugRank, "rank"], [%DebugGear, "gear"], [%DebugPolice, "police"], [%DebugMayor, "mayor"], [%DebugTransport, "transport"]]:
		pair[0].pressed.connect(_debug.bind(pair[1]))
	%Sex.add_item(tr("MALE"))
	%Sex.add_item(tr("FEMALE"))
	%Language.add_item("Deutsch")
	%Language.add_item("English")
	%MusicVolume.value_changed.connect(_music_preview)
	%SoundVolume.value_changed.connect(_sound_preview)
	_settings_changed()
	_safe_area()
	_show("Menu")
	# Headless verification has no audio device; skip playback to avoid exit leaks.
	if DisplayServer.get_name() != "headless":
		%MusicPlayer.play()

func _show(screen: String) -> void:
	if route != screen:
		%DPad.stop()
		%SafeDPad.stop()
	%AiTimer.stop()
	route = screen
	for identifier: String in SCREENS:
		get_node("%" + identifier).visible = identifier == screen
	%Back.visible = screen != "Menu"
	%MenuButton.visible = screen != "Menu"
	%Continue.disabled = not SaveManager.exists("autosave")
	%Quit.visible = OS.get_name() != "Android"
	if screen == "Menu":
		%CityBoard.get_parent().render_target_update_mode = SubViewport.UPDATE_DISABLED
		%CombatBoard.get_parent().render_target_update_mode = SubViewport.UPDATE_DISABLED

func _game() -> void:
	var campaign: Campaign = GameState.campaign
	if campaign == null:
		_show("Menu")
		return
	if not campaign.objectives.ending.is_empty():
		_show("EndingScreen")
		%EndingTitle.text = tr(campaign.objectives.ending)
		%EndingText.text = tr(campaign.objectives.ending + "_TEXT")
		%EndingSummary.text = _summary()
	elif not campaign.police.encounter.is_empty():
		_show("PoliceScreen")
		var encounter := campaign.police.encounter
		%PoliceTitle.text = tr(encounter)
		%PoliceHelp.text = tr("COURT_HELP" if encounter == "COURT" else encounter)
		%Lawyer.visible = encounter == "COURT" and campaign.rank > 4
		%Search.visible = encounter == "SEARCH"
		%Bribe.visible = encounter not in ["SEARCH", "COURT"]
		%Bribe.text = "%s · $%d" % [tr("ACT_PROTECTION"), 500 + 500 * campaign.rank]
		%Escape.visible = %Bribe.visible
		%Court.visible = encounter != "SEARCH"
	elif not campaign.safe.is_empty():
		_show("SafeScreen")
		%SafeTitle.text = tr("SAFE_TURNS") % campaign.safe["attempts"]
		var digits: Array = []
		for index in 3:
			digits.append(("[%d]" if index == campaign.safe["selected"] else " %d ") % campaign.safe["wheels"][index])
		%Wheels.text = " ".join(digits)
		%SafeFeedback.text = tr(campaign.safe["feedback"])
	elif not campaign.combat.is_empty():
		_show("Game")
		%CityImage.hide()
		%CombatImage.show()
		%CityBoard.get_parent().render_target_update_mode = SubViewport.UPDATE_DISABLED
		%CombatBoard.get_parent().render_target_update_mode = SubViewport.UPDATE_ONCE
		%CombatBoard.refresh(campaign)
		var unit := CombatRules.active(campaign)
		var player_turn: bool = unit["side"] == 0
		%BoardTitle.text = tr("TURN") % [campaign.combat["round"], _translated(str(unit["name"]))]
		%ActiveInfo.text = "%s\n%s %d · %s\n%s" % [tr("YOUR_TURN" if player_turn else "ENEMY_TURN"), tr("ENERGY"), unit["energy"], tr(Catalog.weapon(int(unit["weapon"]))["name_key"]), tr("ATTACK" if campaign.combat["mode"] == "attack" else "MOVE")]
		%Modes.show()
		%Enter.hide()
		%Wait.hide()
		%Skip.show()
		%GiveUp.show()
		%MoveMode.disabled = not player_turn
		%AttackMode.disabled = not player_turn
		%Skip.disabled = not player_turn
		%DPad.repeat_enabled = false
		for child in %DPad.get_children():
			if child is Button:
				child.disabled = not player_turn
		%Event.text = _message({"key": campaign.combat["log"], "values": campaign.combat["log_values"]})
		if not player_turn and not %ConfirmOverlay.visible:
			%AiTimer.start()
	elif not campaign.location.is_empty():
		_show("Location")
		%LocationPanel.refresh(campaign)
		%LocationHud.text = _summary()
		%LocationEvent.text = _last_message()
	else:
		_show("Game")
		%CityImage.show()
		%CombatImage.hide()
		%CombatBoard.get_parent().render_target_update_mode = SubViewport.UPDATE_DISABLED
		%CityBoard.refresh(campaign)
		%CityBoard.get_parent().render_target_update_mode = SubViewport.UPDATE_ONCE
		%BoardTitle.text = tr("CITY")
		%Modes.hide()
		%Enter.show()
		%Wait.show()
		%Skip.hide()
		%GiveUp.hide()
		%DPad.repeat_enabled = true
		var waiting := campaign.police.prison_months > 0 or not campaign.job.is_empty()
		for pair: Array in [["Up", Vector2i.UP], ["Left", Vector2i.LEFT], ["Down", Vector2i.DOWN], ["Right", Vector2i.RIGHT]]:
			%DPad.get_node(pair[0]).disabled = waiting or not CityRules.walkable(campaign.position + pair[1])
		var nearby := CityRules.nearby(campaign)
		%Enter.disabled = nearby.is_empty() or waiting
		%Enter.text = tr("ENTER") if nearby.is_empty() else "%s · %s" % [tr("ENTER"), tr(nearby[0]["name_key"])]
		%ActiveInfo.text = tr("MAP_HELP") if Settings.hints else ""
		if waiting:
			%ActiveInfo.text = tr("PRISON_WAIT") % campaign.police.prison_months if campaign.police.prison_months > 0 else tr("JOB_PROGRESS") % campaign.job["months"]
		%Event.text = _last_message()
	%Hud.text = "%s · $%d   |   %s %d   |   %s %d/%d   |   %02d/%d" % [campaign.gang_name, campaign.economy.money, tr("STEPS"), campaign.steps, tr("POINTS"), campaign.points, campaign.goal, campaign.month % 12 + 1, 1925 + campaign.month / 12]
	if Settings.hints and not %ConfirmOverlay.visible:
		if not campaign.combat.is_empty():
			_hint("combat", "COMBAT_HELP")
		elif not campaign.location.is_empty() and route == "Location":
			_hint("location", "LOCATION_HELP")
		elif route == "Game":
			_hint("city", "MAP_HELP")


func _new_game() -> void:
	GameState.new_game(%LeaderName.text, %GangName.text, %LongGame.button_pressed, %Sex.selected)
	_game()

func _enter() -> void:
	var nearby := CityRules.nearby(GameState.campaign)
	if not nearby.is_empty():
		GameState.enter(nearby[0]["id"])

func _direction(direction: Vector2i) -> void:
	if %ConfirmOverlay.visible:
		return
	if GameState.campaign.combat.is_empty():
		GameState.move(direction)
	else:
		_combat_action(GameState.campaign.combat["mode"], direction)

func _mode(mode: String) -> void:
	if not GameState.campaign.combat.is_empty():
		GameState.campaign.combat["mode"] = mode
		GameState.commit()

func _combat_action(mode: String, direction := Vector2i.ZERO) -> void:
	if GameState.campaign.combat.is_empty() or CombatRules.active(GameState.campaign)["side"] != 0:
		return
	if CombatRules.act(GameState.campaign, mode, direction):
		_sound("shot" if mode == "attack" else "click")
		GameState.commit()

func _ai_turn() -> void:
	if route != "Game" or %ConfirmOverlay.visible or GameState.campaign.combat.is_empty():
		return
	if CombatRules.active(GameState.campaign)["side"] == 1:
		var decision := CombatAi.decide(GameState.campaign)
		CombatRules.act(GameState.campaign, decision["mode"], decision["direction"])
		GameState.commit()

func _give_up() -> void:
	CombatRules.finish(GameState.campaign, false)
	GameState.commit()

func _safe_direction(direction: Vector2i) -> void:
	CrimeRules.safe_move(GameState.campaign, direction)
	if not GameState.campaign.safe.is_empty():
		_sound("safe" if GameState.campaign.safe["feedback"] == "SAFE_CLICK" else "dull")
	GameState.commit()

func _location_action(action: String, amount: int, member: int, item: int) -> void:
	var explanation := tr("HELP_" + action.to_upper())
	_confirm(tr("CONFIRM") + "\n\n" + explanation, func():
		LocationRules.perform(GameState.campaign, action, amount, member, item)
		GameState.campaign.location = ""
		GameState.commit())

func _police(action: String) -> void:
	PoliceRules.respond(GameState.campaign, action, int(%Lawyer.value))
	GameState.commit()

func _campaign_changed() -> void:
	if route in ["Game", "Location", "PoliceScreen", "SafeScreen", "EndingScreen"]:
		_game()
	elif route == "StatusScreen":
		_status()

func _summary() -> String:
	var c: Campaign = GameState.campaign
	return "%s · %s\n%s: $%d\n%s: %s\n%s: %d/%d\n%s: %d (%d)\n%s: %d\n%s: %d\n%s: %s" % [c.gang_name, tr("RANK_%d" % c.rank), tr("MONEY"), c.economy.money, tr("CAR"), tr(Catalog.car(c.economy.car)["name_key"]), tr("CARGO"), c.economy.cargo, Catalog.car(c.economy.car)["capacity"], tr("DEBT"), c.economy.debt, c.economy.debt_months, tr("RENT"), c.economy.rent_months, tr("PROTECTED"), c.police.bribe_months, tr("PAPERS"), tr("YES" if c.police.forged_id else "NO")]

func _status() -> void:
	var c: Campaign = GameState.campaign
	var text := _summary() + "\n\n" + tr("GOAL_HELP") % c.goal
	text += "\n%s: %d/%d\n%s: %s\n%s: %s\n" % [tr("POINTS"), c.points, c.goal, tr("MAYOR"), tr("DONE" if c.objectives.mayor_completed else "PENDING"), tr("TRANSPORT"), tr("DONE" if c.objectives.transporter_completed else "PENDING")]
	for person in c.gang:
		text += "\n%s · %s %d/%d · %s\n%s %d · %s %d · %s %d\n" % [person.gangster_name, tr("ENERGY"), person.energy, person.max_energy(), tr(Catalog.weapon(person.weapon)["name_key"]), tr("STRENGTH"), person.strength, tr("INTELLIGENCE"), person.intelligence, tr("BRUTALITY"), person.brutality]
	text += "\n" + tr("LOG") + "\n"
	for message: Dictionary in c.messages:
		text += _message(message) + "\n"
	%StatusText.text = text

func _translated(value: String) -> String:
	return tr(value)

func _message(message: Dictionary) -> String:
	var values: Array = message.get("values", []).duplicate()
	for index in values.size():
		if values[index] is String:
			values[index] = _translated(values[index])
	var text := tr(message["key"])
	return text if values.is_empty() else text % values

func _last_message() -> String:
	return "" if GameState.campaign.messages.is_empty() else _message(GameState.campaign.messages.back())

func _saves(save_mode: bool) -> void:
	return_route = "StatusScreen" if route == "StatusScreen" else "Menu"
	saving = save_mode
	_show("SaveScreen")
	%SaveTitle.text = tr("SAVE_GAME" if saving else "LOAD_GAME")
	%SaveMessage.text = ""
	for index in 4:
		var slot: String = SaveManager.SLOTS[index]
		var button: Button = get_node("%%Slot%d" % index)
		button.text = tr("AUTOSAVE") if index == 0 else tr("SLOT") % index
		button.text += " · " + (tr("CONTINUE") if SaveManager.exists(slot) else tr("EMPTY_SLOT"))
		button.disabled = (saving and index == 0) or (not saving and not SaveManager.exists(slot))

func _slot(index: int) -> void:
	var slot: String = SaveManager.SLOTS[index]
	if saving:
		var perform := func():
			%SaveMessage.text = tr("SAVE_OK" if SaveManager.save_campaign(GameState.campaign, slot) else "SAVE_FAILED")
		if SaveManager.exists(slot):
			_confirm(tr("CONFIRM_SAVE"), perform)
		else:
			perform.call()
	else:
		_confirm(tr("CONFIRM_LOAD"), _load.bind(slot))

func _load(slot: String) -> void:
	if GameState.load_slot(slot):
		_game()
	else:
		if route != "SaveScreen":
			_saves(false)
		%SaveMessage.text = tr(SaveManager.last_error)

func _open_settings() -> void:
	return_route = "Menu" if route == "Menu" else "Game"
	_show("SettingsScreen")
	setting_up = true
	%Language.select(0 if Settings.language == "de" else 1)
	%MusicVolume.value = Settings.music_volume
	%SoundVolume.value = Settings.sound_volume
	%Hints.button_pressed = Settings.hints
	setting_up = false

func _apply_settings() -> void:
	Settings.language = "de" if %Language.selected == 0 else "en"
	Settings.music_volume = %MusicVolume.value
	Settings.sound_volume = %SoundVolume.value
	Settings.hints = %Hints.button_pressed
	Settings.save()
	_back()

func _settings_changed() -> void:
	%MusicPlayer.volume_db = linear_to_db(maxf(0.0001, Settings.music_volume))
	%MusicPlayer.stream_paused = Settings.music_volume <= 0
	%SoundPlayer.volume_db = linear_to_db(maxf(0.0001, Settings.sound_volume))
	%Sex.set_item_text(0, tr("MALE"))
	%Sex.set_item_text(1, tr("FEMALE"))
	if route == "Game":
		_game()

func _music_preview(volume: float) -> void:
	if not setting_up:
		%MusicPlayer.volume_db = linear_to_db(maxf(0.0001, volume))
		%MusicPlayer.stream_paused = volume <= 0

func _sound_preview(volume: float) -> void:
	if not setting_up:
		%SoundPlayer.volume_db = linear_to_db(maxf(0.0001, volume))
		%SoundPlayer.play()

func _sound(identifier: String) -> void:
	if Settings.sound_volume > 0 and DisplayServer.get_name() != "headless":
		%SoundPlayer.stream = load("res://assets/audio/%s.wav" % identifier)
		%SoundPlayer.play()

func _confirm(text: String, action: Callable) -> void:
	%DPad.stop()
	%AiTimer.stop()
	confirmation = action
	%ConfirmNo.show()
	%ConfirmYes.text = tr("YES")
	%ConfirmText.text = text
	%ConfirmOverlay.show()
	%ConfirmNo.grab_focus()

func _confirmed() -> void:
	var action := confirmation
	confirmation = Callable()
	%ConfirmOverlay.hide()
	if action.is_valid():
		action.call()

func _cancel_confirmation() -> void:
	# A tutorial has only Continue; Back dismisses and remembers it as well.
	if not %ConfirmNo.visible:
		_confirmed()
		return
	confirmation = Callable()
	%ConfirmOverlay.hide()
	if route == "Game":
		_game()

func _back() -> void:
	if %ConfirmOverlay.visible:
		_cancel_confirmation()
		return
	match route:
		"Game", "PoliceScreen", "SafeScreen", "EndingScreen": _show("Menu")
		"Location": GameState.leave(); _game()
		"StatusScreen", "DebugScreen": _game()
		"SaveScreen", "SettingsScreen":
			if return_route == "Game": _game()
			else: _show(return_route)
		_: _show("Menu")

func _safe_area() -> void:
	if OS.get_name() != "Android":
		return
	var safe := DisplayServer.get_display_safe_area()
	var screen := DisplayServer.screen_get_size()
	if screen.x <= 0 or safe.size.x <= 0:
		return
	var scale_factor := get_viewport_rect().size / Vector2(screen)
	$Safe.add_theme_constant_override("margin_left", 16 + int(safe.position.x * scale_factor.x))
	$Safe.add_theme_constant_override("margin_right", 16 + int((screen.x - safe.end.x) * scale_factor.x))
	$Safe.add_theme_constant_override("margin_top", 12 + int(safe.position.y * scale_factor.y))
	$Safe.add_theme_constant_override("margin_bottom", 12 + int((screen.y - safe.end.y) * scale_factor.y))

func _quit() -> void:
	if GameState.campaign != null:
		SaveManager.save_campaign(GameState.campaign)
	get_tree().quit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_back()
	elif what == NOTIFICATION_WM_CLOSE_REQUEST:
		_quit()

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo:
		return
	if %ConfirmOverlay.visible:
		if event.keycode == KEY_ESCAPE:
			_cancel_confirmation()
		return
	if event.keycode == KEY_F9 and OS.is_debug_build() and GameState.campaign != null:
		_show("DebugScreen")
	elif event.keycode == KEY_ESCAPE:
		_back()
	elif route == "Game":
		match event.keycode:
			KEY_UP, KEY_W: _direction(Vector2i.UP)
			KEY_DOWN, KEY_S: _direction(Vector2i.DOWN)
			KEY_LEFT, KEY_A: _direction(Vector2i.LEFT)
			KEY_RIGHT, KEY_D: _direction(Vector2i.RIGHT)
			KEY_ENTER:
				if GameState.campaign.combat.is_empty(): _enter()
				else: _mode("attack")
			KEY_SPACE:
				if not GameState.campaign.combat.is_empty(): _combat_action("skip")
	elif route == "SafeScreen":
		match event.keycode:
			KEY_UP: _safe_direction(Vector2i.UP)
			KEY_DOWN: _safe_direction(Vector2i.DOWN)
			KEY_LEFT: _safe_direction(Vector2i.LEFT)
			KEY_RIGHT: _safe_direction(Vector2i.RIGHT)

func _debug(action: String) -> void:
	if not OS.is_debug_build():
		return
	var c: Campaign = GameState.campaign
	match action:
		"money": c.economy.money += 10000
		"rank": c.rank = 5; c.points = 50
		"gear":
			while c.gang.size() < 8:
				var member := Gangster.new()
				member.gangster_name = "Test %d" % c.gang.size()
				c.gang.append(member)
			for person in c.gang:
				person.strength = 99; person.intelligence = 99; person.brutality = 99; person.weapon = 7; person.energy = 99
		"police": c.police.encounter = "SEARCH"
		"mayor": c.objectives.tips |= 16; CrimeRules.mission(c, "mayor")
		"transport": c.objectives.tips |= 4; CrimeRules.mission(c, "transport")
	GameState.commit()
	_game()

func _exit_tree() -> void:
	if is_instance_valid(music_player):
		music_player.stop()
	if is_instance_valid(sound_player):
		sound_player.stop()

func _hint(identifier: String, key: String) -> void:
	if identifier in GameState.campaign.tutorials:
		return
	_confirm(tr(key), func():
		GameState.campaign.tutorials.append(identifier)
		GameState.commit())
	%ConfirmYes.text = tr("CONTINUE")
	%ConfirmNo.hide()
