extends SceneTree

# An ordinary rules-driven campaign: no injected money, stats, ranks or tips.
var state: Node
var c: Campaign
var failed: bool = false
var actions: int = 0

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	state = root.get_node("GameState")
	state.new_game("Charlie", "Progression", true, 0, 2026)
	c = state.campaign
	for trade in 30:
		if c.economy.money >= 7000: break
		visit("station_west", "buy_alcohol", 50)
		for attempt in 8:
			if c.economy.cargo == 0: break
			visit("pub_south", "sell_alcohol", c.economy.cargo)
	visit("cars", "car", 1, 0, 3)
	visit("forgery", "id")
	# Repeated station/pub commerce funds training and the final gang.
	for trade in 400:
		if c.economy.money > 650000: break
		visit("station_west", "buy_alcohol", 200)
		for attempt in 8:
			if c.economy.cargo == 0: break
			visit("pub_south", "sell_alcohol", c.economy.cargo)
		if c.month >= 400 or failed: break
	print("COMMERCE month=", c.month, " money=", c.economy.money, " points=", c.points)
	while c.gang[0].intelligence < 40 or c.gang[0].brutality < 40:
		visit("arms", "train")
		state.advance_month()
		if c.month >= 570 or failed: break
	visit("hideout", "rent", 36)
	for index in Catalog.all()["recruits"].size():
		var offer: Dictionary = Catalog.all()["recruits"][index]
		if offer["intelligence"] >= 40 and offer["brutality"] >= 40 and c.gang.size() < 10:
			visit("pub_south", "recruit", 1, 0, index)
	for member in c.gang.size():
		visit("arms", "weapon", 1, member, 7)
	for member in c.gang.size():
		while c.gang[member].strength < 90 or c.gang[member].brutality < 90:
			visit("arms", "camp", 1, member)
			state.advance_month()
			if c.economy.money < 20000 or c.month >= 550: break
		if c.economy.rent_months < 12: visit("hideout", "rent", 24)
	for month in 12: state.advance_month()
	for attempt in 80:
		if c.objectives.tips & 20 == 20: break
		visit("pub_south", "tip")
		if failed: break
	visit("mayor", "mayor")
	for month in 12: state.advance_month()
	# Tips can expire following arrest; obtain the transporter tip if necessary.
	for attempt in 40:
		if c.objectives.tips & 4 != 0: break
		visit("pub_south", "tip")
	visit("transport", "transport")
	state.commit()
	print("PROGRESSION month=", c.month, " actions=", actions, " gang=", c.gang.size(), " money=", c.economy.money, " points=", c.points, " mayor=", c.objectives.mayor_completed, " transport=", c.objectives.transporter_completed, " ending=", c.objectives.ending)
	quit(0 if c.objectives.ending == "VICTORY" and not failed else 1)

func settle() -> void:
	for iteration in 30000:
		if c.objectives.ending != "": return
		if not c.combat.is_empty():
			var decision := CombatAi.decide(c)
			CombatRules.act(c, decision["mode"], decision.get("direction", Vector2i.ZERO))
		elif not c.police.encounter.is_empty():
			PoliceRules.respond(c, "escape", 10000)
		elif c.police.prison_months > 0 or not c.job.is_empty():
			state.advance_month()
		else: return
	failed = true

func visit(identifier: String, action: String, amount: int = 1, member: int = 0, item: int = 0) -> void:
	if failed or not c.objectives.ending.is_empty(): return
	settle()
	var location := Catalog.location(identifier)
	var destination := Vector2i(int(location["x"]), int(location["y"]) + 1)
	for step in 1000:
		if c.position == destination: break
		var direction := next_step(c.position, destination)
		if direction == Vector2i.ZERO:
			failed = true
			return
		state.move(direction)
		settle()
		if c.objectives.ending != "": return
	state.enter(identifier)
	if c.location != identifier:
		state.enter(identifier)
	if c.location != identifier:
		failed = true
		return
	LocationRules.perform(c, action, amount, member, item)
	c.location = ""
	actions += 1
	settle()
	state.commit()

func next_step(start: Vector2i, goal: Vector2i) -> Vector2i:
	var queue: Array[Vector2i] = [start]
	var previous: Dictionary = {start: start}
	var cursor := 0
	while cursor < queue.size():
		var cell := queue[cursor]
		cursor += 1
		if cell == goal:
			while previous[cell] != start: cell = previous[cell]
			return cell - start
		for direction: Vector2i in CombatRules.DIRECTIONS:
			var neighbor := cell + direction
			if CityRules.walkable(neighbor) and not previous.has(neighbor):
				previous[neighbor] = cell
				queue.append(neighbor)
	return Vector2i.ZERO
