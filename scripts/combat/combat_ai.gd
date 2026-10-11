class_name CombatAi
extends RefCounted

static func decide(campaign: Campaign) -> Dictionary:
	var combat := campaign.combat
	var index: int = combat["active"]
	var unit := CombatRules.active(campaign)
	for direction: Vector2i in CombatRules.DIRECTIONS:
		var victim := CombatRules.target(combat, index, direction)
		if victim >= 0 and combat["units"][victim]["side"] != unit["side"]:
			return {"mode": "attack", "direction": direction}
	# Breadth-first search toward a clear firing line. No per-frame pathfinding.
	var origin := CombatRules.position(unit)
	var queue: Array[Vector2i] = [origin]
	var first_step: Dictionary = {origin: Vector2i.ZERO}
	var cursor := 0
	while cursor < queue.size():
		var cell := queue[cursor]
		cursor += 1
		if cell != origin:
			for direction: Vector2i in CombatRules.DIRECTIONS:
				var victim := CombatRules.target(combat, index, direction, cell)
				if victim >= 0 and combat["units"][victim]["side"] != unit["side"]:
					return {"mode": "move", "direction": first_step[cell]}
		for direction: Vector2i in CombatRules.DIRECTIONS:
			var destination := cell + direction
			if first_step.has(destination) or CombatRules.blocked(destination, combat["units"], index):
				continue
			first_step[destination] = direction if cell == origin else first_step[cell]
			queue.append(destination)
	return {"mode": "skip", "direction": Vector2i.ZERO}
