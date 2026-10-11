class_name CrimeRules
extends RefCounted

static func bank_loot(campaign: Campaign, bonus: int = 0) -> void:
	var loot := 4000 + campaign.rng.randi_range(0, 174) * 16 + bonus
	if campaign.objectives.tips & 2 != 0:
		loot += 7500
		campaign.objectives.tips &= ~2
	campaign.economy.money += loot
	campaign.add_points(4)
	campaign.note("LOOT", [loot])

static func bank(campaign: Campaign, safe: bool) -> void:
	var leader := campaign.gang[0]
	if campaign.rank < (2 if safe else 1):
		campaign.note("NEED_RANK", [2 if safe else 1])
		return
	if campaign.last_crime == campaign.location:
		CombatRules.start(campaign, "police", 5, 5, 30)
		return
	if safe:
		if leader.intelligence < 40 or leader.strength < 25 or leader.brutality < 25:
			campaign.note("SAFE_REQUIREMENTS")
			return
		campaign.safe = {"code": [], "wheels": [], "attempts": 13 + leader.intelligence / 16, "selected": 0, "feedback": "SAFE_HELP"}
		for wheel in 3:
			campaign.safe["code"].append(campaign.rng.randi_range(0, 9))
			campaign.safe["wheels"].append(campaign.rng.randi_range(0, 9))
	else:
		if campaign.gang.size() < 2:
			campaign.note("NEED_GANG", [2])
			return
		if campaign.rng.randi_range(0, 2) == 0:
			CombatRules.start(campaign, "bank", 3, 6, 30)
		else:
			bank_loot(campaign)
	campaign.last_crime = campaign.location

static func safe_move(campaign: Campaign, direction: Vector2i) -> void:
	var safe := campaign.safe
	if safe.is_empty():
		return
	if direction.x != 0:
		safe["selected"] = clampi(int(safe["selected"]) + direction.x, 0, 2)
	else:
		var selected: int = safe["selected"]
		safe["wheels"][selected] = (int(safe["wheels"][selected]) - direction.y + 10) % 10
		safe["attempts"] -= 1
		var audible := campaign.rng.randi_range(0, campaign.gang[0].intelligence - 1) >= 4
		safe["feedback"] = "SAFE_CLICK" if audible and safe["wheels"][selected] == safe["code"][selected] else "SAFE_DULL"
		if safe["wheels"] == safe["code"] and audible:
			campaign.safe = {}
			bank_loot(campaign)
		elif safe["attempts"] <= 0:
			campaign.safe = {}
			campaign.note("SAFE_ALARM")
			CombatRules.start(campaign, "police", 5, 5, 30)

static func pickpocket(campaign: Campaign, member_index: int) -> void:
	var person := campaign.gang[member_index]
	var loot := campaign.rng.randi_range(0, 16) / 2 - campaign.rng.randi_range(0, 3)
	if campaign.rng.randi_range(0, person.intelligence - 1) < 10:
		loot = 0
	if loot <= 0:
		campaign.police.encounter = "WANTED"
		campaign.note("PICK_CAUGHT")
		return
	var amounts := [0, 0, 0, 0, 50, 250, 500, 800, 0]
	campaign.economy.money += amounts[clampi(loot, 0, 8)]
	campaign.add_points(1)
	campaign.note("LOOT", [amounts[clampi(loot, 0, 8)]])

static func steal_car(campaign: Campaign, member_index: int) -> void:
	var person := campaign.gang[member_index]
	if campaign.rng.randi_range(0, 99) < person.strength / 4 + (person.intelligence / 4) * 3:
		campaign.economy.car = campaign.rng.randi_range(1, 5)
		campaign.economy.cargo = mini(campaign.economy.cargo, int(Catalog.car(campaign.economy.car)["capacity"]))
		campaign.note("CAR_STOLEN")
	else:
		CombatRules.start(campaign, "theft", 1, 5, 30)

static func store(campaign: Campaign, method: String) -> void:
	if campaign.rank < 2:
		campaign.note("NEED_RANK", [2])
		return
	if campaign.last_crime == campaign.location:
		CombatRules.start(campaign, "police", 5, 5, 30)
		return
	var leader := campaign.gang[0]
	if (method == "rob" and (leader.brutality < 30 or leader.weapon == 0)) or (method == "fraud" and leader.intelligence < 30):
		campaign.note("STORE_REQUIREMENTS")
		return
	campaign.last_crime = campaign.location
	if method == "burgle":
		CombatRules.start(campaign, "store", 3, 7, 30)
	else:
		var loot := campaign.rng.randi_range(800, 999) + (600 if method == "deceive" else 0)
		campaign.economy.money += loot
		campaign.add_points(1)
		campaign.note("LOOT", [loot])

static func tip(campaign: Campaign) -> void:
	if campaign.rank < 4:
		campaign.note("NEED_RANK", [4])
		return
	if campaign.rng.randi_range(0, 2) == 0:
		campaign.note("NO_TIP")
		return
	var price := campaign.rng.randi_range(0, 3) * 500 + 1000
	if not campaign.economy.pay(price):
		campaign.note("NO_MONEY")
		return
	var choice := campaign.rng.randi_range(0, 4)
	if campaign.objectives.tips & (1 << choice) != 0:
		choice = 0
	if choice == 3 and not campaign.economy.pay(5000):
		campaign.note("NO_MONEY")
		return
	campaign.objectives.tips |= 1 << choice
	campaign.note("TIP_%d" % choice, [price])

static func mission(campaign: Campaign, kind: String) -> void:
	var mask := 16 if kind == "mayor" else (4 if kind == "transport" else 1)
	if campaign.objectives.tips & mask == 0:
		campaign.note("NEED_TIP")
		return
	if kind != "mayor" and campaign.gang.size() < 3:
		campaign.note("NEED_GANG", [3])
		return
	campaign.objectives.tips &= ~mask
	if kind == "mayor":
		CombatRules.start(campaign, "mayor_guards", 5, 7, 20)
	elif kind == "transport":
		CombatRules.start(campaign, "transport", 10, 7, 50)
	else:
		CombatRules.start(campaign, "train", 3, 7, 30)
