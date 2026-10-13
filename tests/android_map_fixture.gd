extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var state := root.get_node("GameState")
	state.new_game("Charlie", "Map QA", false, 0, 2026)
	var campaign: Campaign = state.campaign
	for index: int in range(1, 10):
		var member := Gangster.new()
		member.gangster_name = "QA %d" % index
		campaign.gang.append(member)
	for member: Gangster in campaign.gang:
		member.strength = 99
		member.brutality = 99
		member.energy = 49
		member.weapon = 5
	CombatRules.start(campaign, "transport", 10, 5, 30)
	var save := {"format_version": 1, "campaign": campaign.to_dict()}
	if not root.get_node("SaveManager").validate(save):
		push_error("Invalid Android map fixture")
		quit(1)
		return
	var file := FileAccess.open("/tmp/mafia1986-map-fixture.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(save))
	file.close()
	quit()
