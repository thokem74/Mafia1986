class_name JobRules
extends RefCounted

static func offer(campaign: Campaign) -> void:
	if campaign.rank > 3:
		campaign.note("JOBS_LOW_RANK")
		return
	if campaign.rng.randi_range(0, 4) == 0:
		campaign.note("NO_JOB")
		return
	var item: Dictionary = Catalog.all()["jobs"][campaign.rng.randi_range(0, 3)].duplicate()
	item["wage"] += campaign.rng.randi_range(0, 2) * 500
	campaign.job = item
	campaign.steps = 0
	campaign.location = ""
	campaign.note("JOB_ACCEPTED", ["JOB_" + str(item["id"]).to_upper(), item["months"], item["wage"]])

static func resolve_month(campaign: Campaign) -> void:
	var identifier: String = campaign.job["id"]
	if identifier == "street":
		CombatRules.start(campaign, "job", 1, 0, 20)
	elif identifier in ["burial", "eviction"] and campaign.rng.randi_range(0, 1) == 0:
		CombatRules.start(campaign, "job", 1, 5, 30)
	elif identifier == "cards" and campaign.rng.randi_range(0, 5) <= 1:
		CombatRules.start(campaign, "job", 1, 2, 10)
	else:
		complete_month(campaign)
	campaign.steps = 0

static func complete_month(campaign: Campaign) -> void:
	campaign.job["months"] -= 1
	if campaign.job["months"] <= 0:
		campaign.economy.money += int(campaign.job["wage"])
		campaign.add_points(int(campaign.job["points"]))
		campaign.note("JOB_PAID", [campaign.job["wage"]])
		campaign.job = {}
	else:
		campaign.note("JOB_PROGRESS", [campaign.job["months"]])
