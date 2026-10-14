class_name EconomyRules
extends RefCounted

static func weapon_requirements(weapon_index: int) -> Dictionary:
	# Keep the shop display and purchase checks tied to the same original rules.
	return {
		"strength": 20 if weapon_index in [2, 3] else 0,
		"intelligence": 40 if weapon_index > 5 else 0,
		"brutality": 40 if weapon_index == 3 or weapon_index > 6 else 0,
	}

static func buy_weapon(campaign: Campaign, member_index: int, weapon_index: int) -> void:
	if member_index < 0 or member_index >= campaign.gang.size() or weapon_index < 1 or weapon_index > 8:
		return
	var member := campaign.gang[member_index]
	var item := Catalog.weapon(weapon_index)
	var requirements := weapon_requirements(weapon_index)
	for stat: String in requirements:
		if int(member.get(stat)) < int(requirements[stat]):
			campaign.note("WEAPON_REQUIREMENTS")
			return
	if not campaign.economy.pay(int(item["price"])):
		campaign.note("NO_MONEY")
		return
	if member.weapon != 0:
		campaign.economy.money += int(float(Catalog.weapon(member.weapon)["price"]) / 1.5)
	campaign.add_points(1 if weapon_index > member.weapon else -1)
	member.weapon = weapon_index
	campaign.note("BOUGHT", [item["name_key"]])

static func train(campaign: Campaign, member_index: int, camp: bool) -> void:
	if campaign.last_training == campaign.month:
		campaign.note("TRAINED_ALREADY")
		return
	if camp and campaign.rank < 5:
		campaign.note("NEED_RANK", [5])
		return
	var price := 2500 + 500 * campaign.rank if camp else 800 + 200 * campaign.rank
	if not campaign.economy.pay(price):
		campaign.note("NO_MONEY")
		return
	var member := campaign.gang[member_index]
	member.strength = mini(99, member.strength + (campaign.rng.randi_range(8, 15) if camp else 5))
	member.intelligence = mini(99, member.intelligence + (campaign.rng.randi_range(8, 15) if camp else 3))
	member.brutality = mini(99, member.brutality + (campaign.rng.randi_range(8, 15) if camp else 2))
	campaign.last_training = campaign.month
	campaign.add_points(1 if camp else 2)
	campaign.note("TRAINED", [member.gangster_name])

static func buy_car(campaign: Campaign, index: int) -> void:
	var item := Catalog.car(index)
	if not campaign.economy.pay(int(item["price"])):
		campaign.note("NO_MONEY")
		return
	if campaign.economy.car != 0:
		campaign.economy.money += 1000 + campaign.rng.randi_range(0, campaign.economy.car - 1) * 512 + campaign.rng.randi_range(0, 255)
	campaign.economy.car = index
	campaign.economy.cargo = mini(campaign.economy.cargo, int(item["capacity"]))
	campaign.note("BOUGHT", [item["name_key"]])

static func smuggle(campaign: Campaign, buy: bool, quantity: int) -> void:
	if quantity < 1:
		return
	if buy:
		var capacity := int(Catalog.car(campaign.economy.car)["capacity"])
		if quantity > capacity - campaign.economy.cargo:
			campaign.note("NO_CAPACITY")
			return
		var price := campaign.rng.randi_range(5, 14)
		if not campaign.economy.pay(price * quantity):
			campaign.note("NO_MONEY")
			return
		campaign.economy.cargo += quantity
		campaign.add_points(2)
		campaign.note("CARGO_BOUGHT", [quantity, price])
	else:
		if quantity > campaign.economy.cargo:
			campaign.note("NO_CARGO")
			return
		if campaign.rng.randi_range(0, 1) == 0:
			campaign.note("NO_BUYER")
			return
		var price := campaign.rng.randi_range(10, 29)
		campaign.economy.cargo -= quantity
		campaign.economy.money += price * quantity
		campaign.note("CARGO_SOLD", [quantity, price])

static func recruit(campaign: Campaign, index: int) -> void:
	if campaign.rank < 5 or not campaign.economy.has_hideout:
		campaign.note("RECRUIT_REQUIREMENTS")
		return
	if campaign.gang.size() >= 10:
		campaign.note("GANG_FULL")
		return
	var offer: Dictionary = Catalog.all()["recruits"][index]
	for member in campaign.gang:
		if member.gangster_name == offer["name"]:
			campaign.note("RECRUIT_ALREADY")
			return
	if not campaign.economy.pay(int(offer["price"])):
		campaign.note("NO_MONEY")
		return
	var person := Gangster.from_dict(offer.merged({"energy": 5}))
	campaign.gang.append(person)
	campaign.note("RECRUITED", [person.gangster_name])

static func rent(campaign: Campaign, months: int) -> void:
	if months < 1 or campaign.economy.rent_months + months > 36:
		return
	if not campaign.economy.pay(100 * months):
		campaign.note("NO_MONEY")
		return
	campaign.economy.has_hideout = true
	campaign.economy.rent_months += months
	campaign.note("RENTED", [months])

static func monthly(campaign: Campaign) -> void:
	var economy := campaign.economy
	if economy.has_hideout:
		if economy.rent_months > 0:
			economy.rent_months -= 1
		else:
			var extra := campaign.rng.randi_range(250, 449)
			if economy.pay(extra):
				campaign.note("RENT_OVERDUE", [extra])
			else:
				economy.has_hideout = false
				campaign.gang.resize(1)
				campaign.note("EVICTED")
	if economy.investment > 0 and campaign.rng.randi_range(0, 2) == 0:
		var income := economy.investment / 64 + campaign.rng.randi_range(0, 255)
		economy.money += income
		campaign.note("BUSINESS_INCOME", [income])
	if economy.debt > 0:
		if economy.debt_months > 0:
			economy.debt_months -= 1
		else:
			CombatRules.start(campaign, "debt", 5, 3, 30)
	if campaign.objectives.tips & 8 != 0:
		campaign.objectives.tips &= ~8
		if campaign.rng.randi_range(0, 4) == 0:
			campaign.note("GUNRUN_LOST")
		else:
			var profit := 5500 + campaign.rng.randi_range(0, 149) * 64
			economy.money += profit
			campaign.note("GUNRUN_PROFIT", [profit])
