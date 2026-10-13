extends SceneTree

const SCREEN_DIRECTORY := "res://builds/screens/maps"

var shell: Variant
var state: Node
var viewport: SubViewport
var layout_failures: int = 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	state = root.get_node("GameState")
	shell = load("res://scenes/main/main.tscn").instantiate()
	shell.set_script(load("res://tests/visual_shell.gd"))
	# Visual QA does not need a looping audio stream in the mixer.
	shell.get_node("%MusicPlayer").stream = null
	viewport = SubViewport.new()
	viewport.size = Vector2i(1152, 648)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.gui_disable_input = true
	root.add_child(viewport)
	root.get_node("Settings").hints = true
	viewport.add_child(shell)
	shell.set_process_unhandled_key_input(false)
	DirAccess.make_dir_recursive_absolute(SCREEN_DIRECTORY)
	var locales: Array[String] = ["de", "en"]
	var widths: Array[int] = [1152, 1296, 1404, 1440]
	if "--quick" in OS.get_cmdline_user_args():
		locales.assign(["de"])
		widths.assign([1152])
	for locale: String in locales:
		root.get_node("Settings").language = locale
		root.get_node("Settings").apply()
		for width: int in widths:
			viewport.size = Vector2i(width, 648)
			state.new_game("Charlie", "South Side", false, 0, 400)
			await process_frame
			var prefix := "%s_%d_" % [locale, width]
			shell._show("Menu")
			await capture(prefix + "menu")
			shell._show("NewGame")
			await capture(prefix + "new_game")
			shell._game()
			await capture(prefix + "city")
			root.get_node("Settings").hints = false
			shell._game()
			await capture(prefix + "city_no_hints")
			root.get_node("Settings").hints = true
			for location: Dictionary in Catalog.locations():
				state.campaign.location = location["id"]
				shell._game()
				var panel: Variant = shell.get_node("%LocationPanel")
				var available := LocationRules.actions(location["kind"])
				panel._select(str(available[0]))
				await capture(prefix + "location_" + str(location["kind"]))
				# Also cover the longest equipment/recruit selection forms.
				if location["kind"] in ["arms", "pub"]:
					panel._select("weapon" if location["kind"] == "arms" else "recruit")
					await capture(prefix + "parameters_" + str(location["kind"]))
			state.campaign.location = ""
			# Full parties exercise every spawn row and energy-label overlap.
			for member_index: int in range(1, 10):
				var member := Gangster.new()
				member.gangster_name = "Member %d" % member_index
				member.weapon = 5
				state.campaign.gang.append(member)
			for reason: String in ["police", "store", "bank", "train", "transport", "mayor"]:
				CombatRules.start(state.campaign, reason, 10, 5, 30)
				for hints: bool in [true, false]:
					root.get_node("Settings").hints = hints
					for mode: String in ["move", "attack"]:
						state.campaign.combat["mode"] = mode
						shell._game()
						await capture(prefix + "combat_%s_%s_%s" % [reason, mode, "hints" if hints else "no_hints"])
			root.get_node("Settings").hints = true
			state.campaign.combat = {}
			state.campaign.police.encounter = "SEARCH"
			shell._game()
			await capture(prefix + "police")
			state.campaign.police.encounter = "COURT"
			state.campaign.rank = 5
			shell._game()
			await capture(prefix + "court")
			state.campaign.police.encounter = ""
			state.campaign.safe = {"attempts": 6, "selected": 0, "wheels": [0, 0, 0], "feedback": "SAFE_HELP"}
			shell._game()
			await capture(prefix + "safe")
			state.campaign.safe = {}
			shell._show("StatusScreen")
			shell._status()
			await capture(prefix + "status")
			shell._saves(true)
			await capture(prefix + "saves")
			shell._open_settings()
			await capture(prefix + "settings")
			shell._show("CreditsScreen")
			await capture(prefix + "credits")
			shell._show("DebugScreen")
			await capture(prefix + "debug")
			state.campaign.objectives.ending = "VICTORY"
			shell._game()
			await capture(prefix + "ending")
	shell.get_node("%MusicPlayer").stop()
	shell.get_node("%SoundPlayer").stop()
	await create_timer(0.1).timeout
	shell.queue_free()
	viewport.queue_free()
	await process_frame
	shell = null
	viewport = null
	await process_frame
	print("VISUAL CAPTURES COMPLETE: %d layout failures" % layout_failures)
	quit(0 if layout_failures == 0 else 1)


func capture(identifier: String) -> void:
	if identifier.ends_with("_menu"):
		print("CAPTURING ", identifier)
	await process_frame
	await process_frame
	_check_layout(shell, identifier)
	if shell.route == "Game":
		var map_rect: Rect2 = shell.get_node("%MapWorld").map_rect
		var clear_area: Rect2 = shell.get_node("%MapArea").get_global_rect()
		if not clear_area.grow(1).encloses(map_rect):
			layout_failures += 1
			push_error(identifier + ": playable grid leaves clear area")
		for overlay: String in ["ControlCard", "EventCard", "BoardTitle", "Hud", "Back", "MenuButton"]:
			if map_rect.intersects(shell.get_node("%" + overlay).get_global_rect()):
				layout_failures += 1
				push_error(identifier + ": map overlaps " + overlay)
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("%s/%s.png" % [SCREEN_DIRECTORY, identifier])


func _check_layout(node: Node, identifier: String, inside_scroll: bool = false) -> void:
	# Scroll content can intentionally extend beyond the viewport; fixed controls cannot.
	inside_scroll = inside_scroll or node is ScrollContainer
	if node is Control and node.is_visible_in_tree() and not inside_scroll:
		var rect: Rect2 = node.get_global_rect()
		if rect.size.x > 0 and rect.size.y > 0 and (rect.end.x > viewport.size.x + 1 or rect.end.y > viewport.size.y + 1):
			layout_failures += 1
			push_error("%s: %s exceeds viewport: %s" % [identifier, node.name, rect])
	for child: Node in node.get_children():
		# The city/combat SubViewports have their own pixel coordinate systems.
		if not child is SubViewport:
			_check_layout(child, identifier, inside_scroll)
