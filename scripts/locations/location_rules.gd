class_name LocationRules
extends RefCounted

static func actions(kind: String) -> Array:
	match kind:
		"pub": return ["job", "sell_alcohol", "recruit", "tip"]
		"station": return ["job", "buy_alcohol", "recruit", "tip", "pickpocket", "train_rob"]
		"arms": return ["weapon", "train", "camp"]
		"cars": return ["car", "steal"]
		"hideout": return ["rent", "dismiss", "rival"]
		"bank": return ["rob_bank", "safe"]
		"store": return ["rob", "deceive", "burgle", "fraud"]
		"police": return ["protection", "surrender"]
		"forgery": return ["id", "fake"]
		"casino": return ["gamble1", "gamble2", "gamble3"]
		"loan": return ["borrow", "repay", "business", "invest", "withdraw", "collect"]
		"subway": return ["pickpocket", "ride"]
		"mayor": return ["mayor"]
		"transport": return ["transport"]
	return []

static func perform(campaign: Campaign, action: String, amount: int, member: int, item: int) -> void:
	member = clampi(member, 0, campaign.gang.size() - 1)
	match action:
		"job": JobRules.offer(campaign)
		"weapon": EconomyRules.buy_weapon(campaign, member, clampi(item, 1, 8))
		"train", "camp": EconomyRules.train(campaign, member, action == "camp")
		"car": EconomyRules.buy_car(campaign, clampi(item, 1, 5))
		"steal": CrimeRules.steal_car(campaign, member)
		"buy_alcohol", "sell_alcohol": EconomyRules.smuggle(campaign, action == "buy_alcohol", amount)
		"recruit": EconomyRules.recruit(campaign, clampi(item, 0, Catalog.all()["recruits"].size() - 1))
		"rent": EconomyRules.rent(campaign, amount)
		"dismiss":
			if member > 0:
				campaign.gang.remove_at(member)
				campaign.note("DISMISSED")
		"rival": CombatRules.start(campaign, "store", 3, 3, 30)
		"rob_bank", "safe": CrimeRules.bank(campaign, action == "safe")
		"rob", "deceive", "burgle", "fraud": CrimeRules.store(campaign, action)
		"pickpocket": CrimeRules.pickpocket(campaign, member)
		"tip": CrimeRules.tip(campaign)
		"train_rob": CrimeRules.mission(campaign, "train")
		"mayor", "transport": CrimeRules.mission(campaign, action)
		"protection": PoliceRules.protection(campaign, amount)
		"surrender": campaign.police.encounter = "COURT"
		"id", "fake": PoliceRules.forge(campaign, action == "fake", amount)
		"ride":
			if campaign.economy.pay(50):
				var stops := [Vector2i(21, 9), Vector2i(25, 15)]
				campaign.position = stops[1] if campaign.position == stops[0] else stops[0]
				campaign.location = ""
				campaign.note("SUBWAY_RIDE")
			else:
				campaign.note("NO_MONEY")
		"gamble1", "gamble2", "gamble3":
			if amount < 1 or amount > 10000 or not campaign.economy.pay(amount):
				campaign.note("NO_MONEY")
				return
			var game := int(action.right(1))
			if campaign.rng.randi_range(0, game) == 0:
				var payout := int(amount * (0.5 + game))
				campaign.economy.money += payout
				campaign.note("GAMBLE_WIN", [payout])
			else:
				campaign.note("GAMBLE_LOSE")
		"borrow":
			if amount < 1 or amount > 5000 or campaign.economy.debt > 0 or campaign.economy.owns_business:
				campaign.note("LOAN_REFUSED")
				return
			campaign.economy.money += amount
			campaign.economy.debt = amount + amount / 16
			campaign.economy.debt_months = campaign.rng.randi_range(6, 9)
			campaign.note("BORROWED", [campaign.economy.debt, campaign.economy.debt_months])
		"repay":
			amount = mini(amount, campaign.economy.debt)
			if amount > 0 and campaign.economy.pay(amount):
				campaign.economy.debt -= amount
				campaign.note("REPAID", [amount])
			else:
				campaign.note("NO_MONEY")
		"business":
			if campaign.economy.debt > 0:
				campaign.note("LOAN_REFUSED")
			elif campaign.economy.owns_business:
				campaign.economy.money += 4500 + campaign.rng.randi_range(0, 10) * 100
				campaign.economy.owns_business = false
				campaign.economy.investment = 0
			elif campaign.economy.pay(5000 + campaign.rng.randi_range(0, 10) * 100):
				campaign.economy.owns_business = true
				campaign.note("BUSINESS_BOUGHT")
			else:
				campaign.note("NO_MONEY")
		"invest":
			if campaign.economy.owns_business and amount > 0 and campaign.economy.investment + amount <= 5000 and campaign.economy.pay(amount):
				campaign.economy.investment += amount
			else:
				campaign.note("INVEST_REFUSED")
		"withdraw":
			amount = mini(amount, campaign.economy.investment)
			if campaign.economy.owns_business and amount > 0:
				campaign.economy.investment -= amount
				campaign.economy.money += amount
		"collect":
			if campaign.economy.owns_business and campaign.economy.investment > 0:
				CombatRules.start(campaign, "collect", 1, 6, 35)
			else:
				campaign.note("INVEST_REFUSED")
