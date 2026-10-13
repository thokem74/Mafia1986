extends SceneTree

var shell: Variant
var state: Node
var viewport: SubViewport

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	state = root.get_node("GameState")
	shell = load("res://scenes/main/main.tscn").instantiate()
	viewport = SubViewport.new()
	viewport.size = Vector2i(1152, 648)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	root.get_node("Settings").hints = true
	viewport.add_child(shell)
	state.new_game("Charlie", "South Side", false, 0, 400)
	DirAccess.make_dir_recursive_absolute("res://builds/screens")
	for locale: String in ["de", "en"]:
		root.get_node("Settings").language = locale
		root.get_node("Settings").apply()
		for width in [1152, 1296, 1404, 1440]:
			viewport.size = Vector2i(width, 648)
			await process_frame
			await process_frame
			shell._show("Menu")
			await capture("%s_%d_menu" % [locale, width])
			shell._game()
			await capture("%s_%d_city" % [locale, width])
			state.campaign.location = "arms"
			shell._game()
			shell.get_node("%LocationPanel")._select("weapon")
			await capture("%s_%d_shop" % [locale, width])
			state.campaign.location = ""
			CombatRules.start(state.campaign, "police", 5, 5, 30)
			shell._game()
			await capture("%s_%d_combat" % [locale, width])
			if locale == "de" and width == 1152:
				for path: String in ["Safe", "Safe/Root", "Safe/Root/Header", "Safe/Root/Content", "Safe/Root/Content/Game", "Safe/Root/Content/Game/Body", "Safe/Root/Content/Game/Body/Controls", "Safe/Root/Content/Game/Body/Controls/ActiveInfo"]:
					var node: Control = shell.get_node(path)
					print(path, " rect ", node.get_global_rect(), " min ", node.get_combined_minimum_size())
			state.campaign.combat = {}
			shell._open_settings()
			await capture("%s_%d_settings" % [locale, width])
			shell._game()
	shell.get_node("%MusicPlayer").stop()
	shell.get_node("%SoundPlayer").stop()
	await create_timer(0.1).timeout
	shell.queue_free()
	await process_frame
	print("VISUAL CAPTURES COMPLETE")
	quit()

func capture(identifier: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	viewport.get_texture().get_image().save_png("res://builds/screens/%s.png" % identifier)
