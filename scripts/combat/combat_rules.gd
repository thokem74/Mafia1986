class_name CombatRules
extends RefCounted

const SIZE := Vector2i(40, 20)
const DIRECTIONS := [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
const WALLS := [Vector2i(18, 3), Vector2i(20, 15), Vector2i(18, 9)]

static func start(campaign: Campaign, reason: String, enemies: int, weapon: int, energy: int) -> void:
	var units: Array = []
	for index in campaign.gang.size():
		var member := campaign.gang[index]
		units.append({"name": member.gangster_name, "side": 0, "member": index,
			"x": 4 + (index % 2) * 3, "y": 1 + (index / 2) * 4, "energy": member.energy,
			"weapon": member.weapon, "strength": member.strength, "brutality": member.brutality})
	for index in enemies:
		units.append({"name": "ENEMY_" + reason.to_upper(), "side": 1, "member": -1,
			"x": 32 + (index % 2) * 3, "y": 1 + (index / 2) * 3, "energy": energy,
			"weapon": weapon, "strength": 30, "brutality": 30})
	campaign.combat = {"reason": reason, "units": units, "active": 0, "round": 1, "mode": "move", "log": "COMBAT_START", "log_values": []}
	if units[0]["energy"] <= 0:
		_next(campaign)
	campaign.note("COMBAT_START")

static func active(campaign: Campaign) -> Dictionary:
	return campaign.combat["units"][int(campaign.combat["active"])]

static func position(unit: Dictionary) -> Vector2i:
	return Vector2i(int(unit["x"]), int(unit["y"]))

static func blocked(cell: Vector2i, units: Array, ignored: int) -> bool:
	if cell.x < 1 or cell.y < 1 or cell.x + 1 >= SIZE.x - 1 or cell.y + 1 >= SIZE.y - 1:
		return true
	for wall: Vector2i in WALLS:
		if absi(cell.x - wall.x) < 2 and absi(cell.y - wall.y) < 2:
			return true
	for index in units.size():
		if index == ignored or units[index]["energy"] <= 0:
			continue
		var other := position(units[index])
		if absi(cell.x - other.x) < 2 and absi(cell.y - other.y) < 2:
			return true
	return false

static func target(combat: Dictionary, index: int, direction: Vector2i, origin := Vector2i(-1, -1)) -> int:
	var units: Array = combat["units"]
	var shooter: Dictionary = units[index]
	var cell := position(shooter) if origin.x < 0 else origin
	if direction == Vector2i.RIGHT:
		cell += Vector2i(1, 1)
	elif direction in [Vector2i.LEFT, Vector2i.DOWN]:
		cell += Vector2i(0, 1)
	for distance in int(Catalog.weapon(int(shooter["weapon"]))["range"]):
		cell += direction
		if cell.x <= 0 or cell.x >= SIZE.x - 1 or cell.y <= 0 or cell.y >= SIZE.y - 1:
			return -1
		for wall: Vector2i in WALLS:
			if Rect2i(wall, Vector2i(2, 2)).has_point(cell):
				return -1
		for candidate in units.size():
			if candidate != index and units[candidate]["side"] != shooter["side"] and units[candidate]["energy"] > 0 and Rect2i(position(units[candidate]), Vector2i(2, 2)).has_point(cell):
				return candidate
	return -1

static func act(campaign: Campaign, mode: String, direction := Vector2i.ZERO) -> bool:
	if campaign.combat.is_empty():
		return false
	var combat := campaign.combat
	var unit := active(campaign)
	if mode == "move":
		var destination := position(unit) + direction
		if direction not in DIRECTIONS or blocked(destination, combat["units"], int(combat["active"])):
			return false
		unit["x"] = destination.x
		unit["y"] = destination.y
		combat["log"] = "COMBAT_MOVE"
		combat["log_values"] = [unit["name"]]
	elif mode == "attack":
		if direction not in DIRECTIONS:
			return false
		var victim_index := target(combat, int(combat["active"]), direction)
		var item := Catalog.weapon(int(unit["weapon"]))
		# C64 BASIC miss rule documented in the reference: either random check zero misses.
		var missed := campaign.rng.randi_range(0, int(item["precision"]) - 1) == 0 or campaign.rng.randi_range(0, int(unit["strength"]) / 10) == 0
		combat["log"] = "COMBAT_MISS"
		combat["log_values"] = [unit["name"]]
		if victim_index >= 0 and not missed:
			var victim: Dictionary = combat["units"][victim_index]
			var damage := int(campaign.rng.randf() * int(item["damage"]) + int(unit["brutality"]) / 10.0) + 1
			victim["energy"] = maxi(0, int(victim["energy"]) - damage)
			combat["log"] = "COMBAT_HIT"
			combat["log_values"] = [unit["name"], victim["name"], damage, victim["energy"]]
	elif mode != "skip":
		return false
	else:
		combat["log"] = "COMBAT_SKIP"
		combat["log_values"] = [unit["name"]]
	if _winner(combat) != -1:
		finish(campaign, _winner(combat) == 0)
	else:
		_next(campaign)
	return true

static func _winner(combat: Dictionary) -> int:
	var alive := [false, false]
	for unit: Dictionary in combat["units"]:
		if unit["energy"] > 0:
			alive[int(unit["side"])] = true
	if not alive[0]:
		return 1
	if not alive[1]:
		return 0
	return -1

static func _next(campaign: Campaign) -> void:
	var combat := campaign.combat
	var count: int = combat["units"].size()
	for step in count:
		combat["active"] = (int(combat["active"]) + 1) % count
		if combat["active"] == 0:
			combat["round"] += 1
		if active(campaign)["energy"] > 0:
			break

static func finish(campaign: Campaign, won: bool) -> void:
	var reason: String = campaign.combat["reason"]
	for unit: Dictionary in campaign.combat["units"]:
		if unit["side"] == 0:
			campaign.gang[int(unit["member"])].energy = maxi(5, int(unit["energy"]))
	campaign.combat = {}
	campaign.note("COMBAT_WON" if won else "COMBAT_LOST")
	if reason == "job":
		if won:
			JobRules.complete_month(campaign)
		else:
			campaign.job = {}
			campaign.add_points(-2)
		campaign.steps = 0
	elif reason == "debt":
		if won:
			campaign.economy.debt_months = campaign.rng.randi_range(3, 5)
		else:
			campaign.economy.money = 0
			campaign.economy.debt = 0
			campaign.economy.debt_months = 0
	elif not won:
		campaign.police.encounter = "COURT"
	elif reason == "mayor_guards":
		start(campaign, "mayor", 1, 1, 30)
	elif reason == "mayor":
		campaign.objectives.mayor_completed = true
		campaign.economy.money += 7000
		campaign.police.forged_id = true
		campaign.location = ""
		campaign.note("MAYOR_DONE")
	elif reason == "transport":
		campaign.objectives.transporter_completed = true
		CrimeRules.bank_loot(campaign, 10000)
		campaign.location = ""
		campaign.note("TRANSPORT_DONE")
	elif reason in ["bank", "train"]:
		CrimeRules.bank_loot(campaign, 5000 if reason == "train" else 0)
	elif reason == "store":
		campaign.economy.money += campaign.rng.randi_range(800, 999)
		campaign.add_points(1)
	elif reason == "collect":
		campaign.economy.money += campaign.rng.randi_range(500, 1499)
		campaign.add_points(2)
	else:
		campaign.add_points(1)

static func valid_save(combat: Dictionary) -> bool:
	for key: String in ["reason", "units", "active", "round", "mode", "log", "log_values"]:
		if not combat.has(key):
			return false
	if not combat["reason"] is String or not combat["log"] is String or not combat["log_values"] is Array:
		return false
	if combat["reason"] not in ["job", "debt", "mayor_guards", "mayor", "transport", "bank", "train", "store", "collect", "police", "theft"] or combat["mode"] not in ["move", "attack"]:
		return false
	if not combat["units"] is Array or combat["units"].size() < 2 or combat["units"].size() > 20:
		return false
	if not (combat["active"] is int or combat["active"] is float) or int(combat["active"]) != combat["active"] or combat["active"] < 0 or combat["active"] >= combat["units"].size():
		return false
	if not (combat["round"] is int or combat["round"] is float) or not is_finite(float(combat["round"])) or float(combat["round"]) != floor(float(combat["round"])) or combat["round"] < 1:
		return false
	for unit: Variant in combat["units"]:
		if not unit is Dictionary or not unit.get("name") is String:
			return false
		for field: String in ["x", "y", "energy", "weapon", "strength", "brutality", "side", "member"]:
			if not (unit.get(field) is float or unit.get(field) is int) or not is_finite(float(unit[field])) or float(unit[field]) != floor(float(unit[field])):
				return false
		if int(unit["side"]) not in [0, 1] or unit["weapon"] < 0 or unit["weapon"] > 8 or unit["energy"] < 0 or unit["energy"] > 99:
			return false
		if unit["x"] < 1 or unit["x"] > 37 or unit["y"] < 1 or unit["y"] > 17:
			return false
		if unit["strength"] < 1 or unit["strength"] > 99 or unit["brutality"] < 1 or unit["brutality"] > 99:
			return false
	return true
