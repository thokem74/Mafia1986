class_name PoliceRules
extends RefCounted

static func search(campaign: Campaign) -> void:
	var police := campaign.police
	police.encounter = ""
	if campaign.rng.randi_range(0, 1) == 0:
		if police.counterfeit:
			police.encounter = "COUNTERFEIT"
		elif campaign.economy.cargo > 0:
			campaign.economy.cargo = 0
			police.encounter = "CONTRABAND"
		elif not police.forged_id:
			police.encounter = "WANTED"
	if police.encounter.is_empty():
		campaign.note("POLICE_CLEAR")
	elif police.bribe_months > 0 and campaign.rng.randi_range(0, 1) == 1:
		police.encounter = ""
		campaign.note("POLICE_PROTECTED")

static func respond(campaign: Campaign, action: String, lawyer_payment: int = 0) -> void:
	if campaign.police.encounter == "SEARCH":
		search(campaign)
		return
	if campaign.police.encounter == "COURT":
		court(campaign, lawyer_payment)
		return
	if action == "bribe":
		var price := 500 + 500 * campaign.rank
		if campaign.economy.pay(price) and campaign.rng.randi_range(0, 4) != 0:
			campaign.police.encounter = ""
			campaign.note("BRIBE_ACCEPTED")
			return
	elif action == "escape":
		if campaign.rng.randi_range(0, 79) <= Catalog.car(campaign.economy.car)["movement"]:
			campaign.police.encounter = ""
			campaign.add_points(2)
			campaign.note("ESCAPED")
			return
		campaign.add_points(-4)
	campaign.police.encounter = "COURT"
	campaign.note("COURT_HELP")

static func court(campaign: Campaign, lawyer_payment: int = 0) -> void:
	var sentence := 1 + campaign.rank / 2
	if campaign.rank > 4 and lawyer_payment > 0 and lawyer_payment <= 10000 and campaign.economy.pay(lawyer_payment):
		sentence = maxi(0, sentence - campaign.rng.randi_range(0, lawyer_payment / 1024))
	campaign.police.prison_months = sentence
	campaign.police.encounter = ""
	campaign.objectives.tips = 0
	campaign.job = {}
	campaign.location = ""
	campaign.position = Vector2i(25, 3)
	campaign.steps = 0
	campaign.add_points(2 if sentence == 0 else -3)
	campaign.note("SENTENCED", [sentence])

static func protection(campaign: Campaign, months: int) -> void:
	if months < 1 or months > 12:
		return
	if not campaign.economy.pay(months * 1000):
		campaign.note("NO_MONEY")
		return
	campaign.police.bribe_months += months
	campaign.add_points(2)
	campaign.note("PROTECTION", [months])

static func forge(campaign: Campaign, money: bool, quantity: int) -> void:
	if money:
		if campaign.police.counterfeit or quantity < 1 or quantity > 5000:
			campaign.note("FORGE_ALREADY")
			return
		if not campaign.economy.pay(quantity):
			campaign.note("NO_MONEY")
			return
		campaign.economy.money += quantity * 2 + campaign.rng.randi_range(0, 255) * 3
		campaign.police.counterfeit = true
	else:
		if campaign.police.forged_id:
			campaign.note("FORGE_ALREADY")
			return
		if not campaign.economy.pay(1000 * campaign.gang.size()):
			campaign.note("NO_MONEY")
			return
		campaign.police.forged_id = true
	campaign.add_points(1)
	campaign.note("FORGED")
