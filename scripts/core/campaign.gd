class_name Campaign
extends RefCounted

var gang_name: String = "South Side"
var economy := EconomyState.new()
var police := PoliceState.new()
var objectives := ObjectiveState.new()
var gang: Array[Gangster] = []
var position := Vector2i(3, 3)
var month: int = 0
var years: int = 25
var goal: int = 100
var points: int = 0
var rank: int = 0
var steps: int = 25
var location: String = ""
var job: Dictionary = {}
var combat: Dictionary = {}
var safe: Dictionary = {}
var last_training: int = -1
var last_crime: String = ""
var tutorials: Array[String] = []
var rng := RandomNumberGenerator.new()
var messages: Array[Dictionary] = []

func note(key: String, values: Array = []) -> void:
	messages.append({"key": key, "values": values})
	if messages.size() > 30:
		messages.pop_front()

func add_points(amount: int) -> void:
	points = clampi(points + amount, 0, goal + 10)

func promote() -> void:
	var new_rank := mini(10, (points + 5) / (goal / 10))
	if new_rank > rank:
		rank = new_rank
		note("PROMOTED", ["RANK_%d" % rank])

func to_dict() -> Dictionary:
	var members: Array = []
	for member in gang:
		members.append(member.to_dict())
	# RNG state must be a string: JSON floats cannot preserve all 64 bits.
	return {"gang_name": gang_name, "economy": economy.to_dict(), "police": police.to_dict(),
		"objectives": objectives.to_dict(), "gang": members, "position": [position.x, position.y],
		"month": month, "years": years, "goal": goal, "points": points, "rank": rank,
		"steps": steps, "location": location, "job": job, "combat": combat, "safe": safe,
		"last_training": last_training, "last_crime": last_crime, "tutorials": tutorials,
		"rng_state": str(rng.state), "messages": messages}.duplicate(true)

static func from_dict(value: Dictionary) -> Campaign:
	var result := Campaign.new()
	result.gang_name = value["gang_name"]
	result.economy = EconomyState.from_dict(value["economy"])
	result.police = PoliceState.from_dict(value["police"])
	result.objectives = ObjectiveState.from_dict(value["objectives"])
	for member: Dictionary in value["gang"]:
		result.gang.append(Gangster.from_dict(member))
	result.position = Vector2i(int(value["position"][0]), int(value["position"][1]))
	for field: String in ["month", "years", "goal", "points", "rank", "steps",
		"location", "job", "combat", "safe", "last_training", "last_crime"]:
		result.set(field, value[field])
	result.tutorials.assign(value.get("tutorials", []))
	result.messages.assign(value.get("messages", []))
	result.rng.state = int(value["rng_state"])
	return result
