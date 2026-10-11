extends Node

signal changed
var campaign: Campaign

func new_game(leader_name: String, gang_name: String, long_game: bool, sex: int = 0, seed_value: int = 0) -> void:
	campaign = Campaign.new()
	if seed_value == 0:
		campaign.rng.randomize()
	else:
		campaign.rng.seed = seed_value
	campaign.gang_name = gang_name.strip_edges().left(20) if not gang_name.strip_edges().is_empty() else "South Side"
	campaign.years = 50 if long_game else 25
	campaign.goal = campaign.years * 4
	var leader := Gangster.new()
	leader.gangster_name = leader_name.strip_edges().left(20) if not leader_name.strip_edges().is_empty() else "Charlie"
	leader.sex = sex
	leader.strength = 10 + campaign.rng.randi_range(0, 8) * 5
	leader.intelligence = 10 + campaign.rng.randi_range(0, 8) * 5
	leader.brutality = 10 + campaign.rng.randi_range(0, 8) * 5
	campaign.gang.append(leader)
	campaign.economy.money = 5000 + campaign.rng.randi_range(0, 4) * 500
	campaign.note("WELCOME")
	commit()

func commit() -> void:
	if campaign == null:
		return
	if campaign.objectives.won(campaign.points, campaign.goal):
		campaign.objectives.ending = "VICTORY"
	if not SaveManager.save_campaign(campaign):
		campaign.note("SAVE_FAILED")
	changed.emit()

func load_slot(slot: String) -> bool:
	var loaded: Campaign = SaveManager.load_campaign(slot)
	if loaded == null:
		return false
	campaign = loaded
	if SaveManager.recovered_backup:
		campaign.note("SAVE_RECOVERED")
	changed.emit()
	return true

func move(direction: Vector2i) -> void:
	if not can_act() or not campaign.location.is_empty():
		return
	if campaign.steps == 0:
		advance_month()
		commit()
		return
	var destination := campaign.position + direction
	if not CityRules.walkable(destination):
		return
	campaign.position = destination
	campaign.steps -= 1
	campaign.police.street_steps += 1
	# Fixed C64 1.20 BASIC 2041 checks each remaining-step multiple of 20, 20% chance.
	if campaign.rank >= 4 and campaign.steps % 20 == 0 and campaign.rng.randi_range(0, 4) == 0:
		campaign.police.encounter = "SEARCH"
		campaign.note("POLICE_STOP")
	commit()

func enter(identifier: String) -> void:
	if not can_act():
		return
	for item in CityRules.nearby(campaign):
		if item["id"] == identifier:
			if campaign.steps == 0:
				advance_month()
				commit()
				return
			campaign.location = identifier
			campaign.steps = maxi(0, campaign.steps - 5)
			commit()
			return

func leave() -> void:
	if not can_act():
		return
	campaign.location = ""
	commit()

func can_act() -> bool:
	return campaign != null and campaign.combat.is_empty() and campaign.safe.is_empty() and campaign.police.encounter.is_empty() and campaign.objectives.ending.is_empty() and campaign.police.prison_months == 0 and campaign.job.is_empty()

func advance_month() -> void:
	if campaign == null or not campaign.combat.is_empty() or not campaign.safe.is_empty() or not campaign.police.encounter.is_empty() or not campaign.objectives.ending.is_empty():
		return
	campaign.location = ""
	campaign.month += 1
	campaign.last_training = -1
	campaign.last_crime = ""
	campaign.promote()
	for person in campaign.gang:
		person.recover()
	var police := campaign.police
	police.bribe_months = maxi(0, police.bribe_months - 1)
	if police.forged_id and campaign.rng.randi_range(0, 7) == 0:
		police.forged_id = false
		campaign.note("ID_EXPIRED")
	if police.counterfeit and campaign.rng.randi_range(0, 7) == 0:
		police.counterfeit = false
		campaign.note("FAKE_EXPIRED")
	EconomyRules.monthly(campaign)
	campaign.steps = int(Catalog.car(campaign.economy.car)["movement"])
	if campaign.month > campaign.years * 12:
		campaign.objectives.ending = "TIME_UP"
	elif police.prison_months > 0:
		police.prison_months -= 1
		campaign.steps = 0
		campaign.note("PRISON_WAIT", [police.prison_months])
	elif not campaign.job.is_empty() and campaign.combat.is_empty():
		JobRules.resolve_month(campaign)
	commit()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED and campaign != null:
		SaveManager.save_campaign(campaign)
