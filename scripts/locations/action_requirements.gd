class_name ActionRequirements
extends RefCounted

# Read-only form preview. Gameplay rules still validate actions when performed.
var available: bool = true
var lines: PackedStringArray = []


static func evaluate(campaign: Campaign, action: String, quantity: int, member_index: int, item_index: int) -> ActionRequirements:
	var result := ActionRequirements.new()
	var economy := campaign.economy
	var leader := campaign.gang[0]
	var member := campaign.gang[clampi(member_index, 0, campaign.gang.size() - 1)]
	match action:
		"weapon":
			result._stats(member, EconomyRules.weapon_requirements(item_index))
			result._money(campaign, int(Catalog.weapon(item_index)["price"]))
		"car":
			result._money(campaign, int(Catalog.car(item_index)["price"]))
		"train", "camp":
			if action == "camp":
				result._rank(campaign, 5)
			result._add("REQ_TRAINING", [int(campaign.last_training == campaign.month), 1], campaign.last_training != campaign.month)
			result._money(campaign, 2500 + 500 * campaign.rank if action == "camp" else 800 + 200 * campaign.rank)
		"recruit":
			var offer: Dictionary = Catalog.all()["recruits"][clampi(item_index, 0, Catalog.all()["recruits"].size() - 1)]
			result._rank(campaign, 5)
			result._condition("REQ_HIDEOUT", economy.has_hideout)
			result._add("REQ_GANG_SPACE", [campaign.gang.size(), 10], campaign.gang.size() < 10)
			for person: Gangster in campaign.gang:
				if person.gangster_name == offer["name"]:
					result._add("RECRUIT_ALREADY", [], false)
					break
			result._money(campaign, int(offer["price"]))
		"buy_alcohol":
			var capacity := int(Catalog.car(economy.car)["capacity"]) - economy.cargo
			result._add("REQ_CAPACITY", [quantity, capacity], quantity > 0 and quantity <= capacity)
			var price := _preview_rng(campaign).randi_range(5, 14)
			result._add("REQ_BOTTLE_PRICE", [price], true)
			result._money(campaign, price * quantity)
		"sell_alcohol":
			result._add("REQ_CARGO", [quantity, economy.cargo], quantity > 0 and quantity <= economy.cargo)
		"rent":
			result._add("REQ_RENT", [economy.rent_months, quantity, 36], quantity > 0 and economy.rent_months + quantity <= 36)
			result._money(campaign, quantity * 100)
		"protection":
			result._quantity(quantity, 12)
			result._money(campaign, quantity * 1000)
		"id":
			result._condition("REQ_NEW_ID", not campaign.police.forged_id)
			result._money(campaign, 1000 * campaign.gang.size())
		"fake":
			result._condition("REQ_NEW_COUNTERFEIT", not campaign.police.counterfeit)
			result._quantity(quantity, 5000)
			result._money(campaign, quantity)
		"borrow":
			result._quantity(quantity, 5000)
			result._no_debt(campaign)
			result._condition("REQ_NO_BUSINESS", not economy.owns_business)
		"repay":
			result._add("REQ_DEBT", [economy.debt], economy.debt > 0 and quantity > 0)
			result._money(campaign, mini(quantity, economy.debt))
		"business":
			result._no_debt(campaign)
			if economy.owns_business:
				result._add("REQ_SELL_BUSINESS", [], true)
			else:
				result._money(campaign, 5000 + _preview_rng(campaign).randi_range(0, 10) * 100)
		"invest":
			result._condition("REQ_BUSINESS", economy.owns_business)
			result._add("REQ_INVESTMENT", [economy.investment, quantity, 5000], quantity > 0 and economy.investment + quantity <= 5000)
			result._money(campaign, quantity)
		"withdraw":
			result._condition("REQ_BUSINESS", economy.owns_business)
			result._add("REQ_WITHDRAW", [mini(quantity, economy.investment), economy.investment], quantity > 0 and economy.investment > 0)
		"collect":
			result._condition("REQ_BUSINESS", economy.owns_business)
			result._add("REQ_INVESTED", [economy.investment], economy.investment > 0)
		"ride":
			result._money(campaign, 50)
		"gamble1", "gamble2", "gamble3":
			result._quantity(quantity, 10000)
			result._money(campaign, quantity)
		"job":
			result._add("REQ_JOB_RANK", [campaign.rank], campaign.rank <= 3)
		"tip":
			result._rank(campaign, 4)
			# Preview the same price rolls without consuming campaign randomness.
			# The availability roll remains a possible outcome, not a prerequisite.
			var random := _preview_rng(campaign)
			random.randi_range(0, 2)
			var price := random.randi_range(0, 3) * 500 + 1000
			var choice := random.randi_range(0, 4)
			if campaign.objectives.tips & (1 << choice) != 0:
				choice = 0
			if choice == 3:
				price += 5000
			result._money(campaign, price)
		"dismiss":
			result._condition("REQ_NOT_LEADER", member_index > 0)
		"rob_bank", "safe":
			result._rank(campaign, 2 if action == "safe" else 1)
			if campaign.last_crime == campaign.location:
				result._add("REQ_REPEAT_CRIME", [], true)
			elif action == "safe":
				result._stats(leader, {"strength": 25, "intelligence": 40, "brutality": 25})
			else:
				result._gang(campaign, 2)
		"rob", "deceive", "burgle", "fraud":
			result._rank(campaign, 2)
			if campaign.last_crime == campaign.location:
				result._add("REQ_REPEAT_CRIME", [], true)
			elif action == "rob":
				result._stats(leader, {"brutality": 30})
				result._condition("REQ_WEAPON", leader.weapon != 0)
			elif action == "fraud":
				result._stats(leader, {"intelligence": 30})
		"train_rob", "transport", "mayor":
			var mask := 16 if action == "mayor" else (4 if action == "transport" else 1)
			result._condition("REQ_TIP", campaign.objectives.tips & mask != 0)
			if action != "mayor":
				result._gang(campaign, 3)
		"bribe":
			result._money(campaign, 500 + 500 * campaign.rank)
		"court":
			if campaign.rank > 4 and quantity > 0:
				result._quantity(quantity, 10000)
				result._money(campaign, quantity)
	return result


static func _preview_rng(campaign: Campaign) -> RandomNumberGenerator:
	var random := RandomNumberGenerator.new()
	random.seed = campaign.rng.seed
	random.state = campaign.rng.state
	return random


func _add(key: String, values: Array, met: bool) -> void:
	var text := tr(key)
	lines.append(text if values.is_empty() else text % values)
	available = available and met


func _money(campaign: Campaign, price: int) -> void:
	_add("REQ_MONEY", [price, campaign.economy.money], campaign.economy.money >= price)


func _rank(campaign: Campaign, minimum: int) -> void:
	_add("REQ_RANK", [campaign.rank, minimum], campaign.rank >= minimum)


func _gang(campaign: Campaign, minimum: int) -> void:
	_add("REQ_GANG", [campaign.gang.size(), minimum], campaign.gang.size() >= minimum)


func _quantity(quantity: int, maximum: int) -> void:
	_add("REQ_QUANTITY", [quantity, maximum], quantity > 0 and quantity <= maximum)


func _condition(key: String, met: bool) -> void:
	_add(key, [tr("YES" if met else "NO")], met)


func _no_debt(campaign: Campaign) -> void:
	_add("REQ_NO_DEBT", [campaign.economy.debt], campaign.economy.debt == 0)


func _stats(person: Gangster, requirements: Dictionary) -> void:
	var details: PackedStringArray = []
	for stat: String in requirements:
		var minimum := int(requirements[stat])
		if minimum == 0:
			continue
		var current := int(person.get(stat))
		details.append("%s %d/%d" % [tr(stat.to_upper()), current, minimum])
		available = available and current >= minimum
	if not details.is_empty():
		_add("WEAPON_STATS", [" · ".join(details)], true)
