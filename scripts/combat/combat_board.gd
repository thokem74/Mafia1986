extends Node2D

const UNIT_SCENE := preload("res://scenes/combat/unit.tscn")

func refresh(campaign: Campaign) -> void:
	for child in $Units.get_children():
		child.free()
	for index in campaign.combat["units"].size():
		var data: Dictionary = campaign.combat["units"][index]
		if data["energy"] <= 0:
			continue
		var unit := UNIT_SCENE.instantiate()
		$Units.add_child(unit)
		unit.position = Vector2(CombatRules.position(data)) * 10
		if data["side"] == 1:
			unit.get_node("Sprite").texture = preload("res://assets/sprites/enemy.png")
		unit.get_node("Active").visible = index == campaign.combat["active"]
		unit.get_node("Energy").text = str(data["energy"])
	for child in $Highlights.get_children():
		child.free()
	var active := CombatRules.active(campaign)
	var cell := CombatRules.position(active)
	for direction: Vector2i in CombatRules.DIRECTIONS:
		var count := int(Catalog.weapon(int(active["weapon"]))["range"]) if campaign.combat["mode"] == "attack" else 1
		for step in count:
			var marker := preload("res://scenes/combat/highlight.tscn").instantiate()
			var destination := cell + direction * (step + 1)
			if destination.x < 1 or destination.y < 1 or destination.x > 37 or destination.y > 17:
				marker.free()
				break
			if campaign.combat["mode"] == "move" and CombatRules.blocked(destination, campaign.combat["units"], int(campaign.combat["active"])):
				marker.free()
				break
			$Highlights.add_child(marker)
			marker.position = Vector2(destination) * 10
