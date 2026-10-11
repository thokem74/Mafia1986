extends Node

const FORMAT_VERSION := 1
const SLOTS := ["autosave", "slot1", "slot2", "slot3"]
var last_error: String = ""
var recovered_backup: bool = false

func exists(slot: String) -> bool:
	return slot in SLOTS and (FileAccess.file_exists(_path(slot)) or FileAccess.file_exists(_path(slot) + ".bak"))

func save_campaign(campaign: Campaign, slot: String = "autosave") -> bool:
	if slot not in SLOTS:
		return false
	var payload := {"format_version": FORMAT_VERSION, "campaign": campaign.to_dict()}
	if not validate(payload):
		last_error = "SAVE_INVALID"
		return false
	var path := _path(slot)
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null:
		last_error = "SAVE_FAILED"
		return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		last_error = "SAVE_FAILED"
		return false
	# Copy only a validated previous save, so a corrupt primary never replaces a good backup.
	if FileAccess.file_exists(path) and validate(_read(path)):
		if DirAccess.copy_absolute(path, path + ".bak") != OK:
			last_error = "SAVE_FAILED"
			return false
	if DirAccess.rename_absolute(path + ".tmp", path) != OK:
		last_error = "SAVE_FAILED"
		return false
	last_error = ""
	return true

func load_campaign(slot: String = "autosave") -> Campaign:
	recovered_backup = false
	if slot not in SLOTS:
		last_error = "SAVE_INVALID"
		return null
	var payload := _read(_path(slot))
	if not validate(payload):
		payload = _read(_path(slot) + ".bak")
		recovered_backup = true
	if not validate(payload):
		last_error = "SAVE_INVALID"
		return null
	last_error = ""
	return Campaign.from_dict(payload["campaign"])

func _path(slot: String) -> String:
	return "user://%s.json" % slot

func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var parser := JSON.new()
	if parser.parse(FileAccess.get_file_as_string(path)) != OK:
		return {}
	var parsed: Variant = _normalize_numbers(parser.data)
	return parsed if parsed is Dictionary else {}

func validate(payload: Dictionary) -> bool:
	if payload.get("format_version", 0) != FORMAT_VERSION:
		return false
	var data: Variant = payload.get("campaign")
	if not data is Dictionary:
		return false
	var template := Campaign.new().to_dict()
	if not _same_shape(data, template):
		return false
	if not data["rng_state"].is_valid_int():
		return false
	if data["gang"].size() < 1 or data["gang"].size() > 10:
		return false
	for member: Variant in data["gang"]:
		if not member is Dictionary or not _same_shape(member, Gangster.new().to_dict()):
			return false
		for field: String in ["strength", "intelligence", "brutality"]:
			if not _integer_between(member[field], 1, 99):
				return false
		if not _integer_between(member["energy"], 0, 99) or not _integer_between(member["weapon"], 0, 8):
			return false
	var money: Dictionary = data["economy"]
	for field: String in ["money", "cargo", "debt", "debt_months", "rent_months", "investment"]:
		if not _integer_between(money[field], 0, 1000000000):
			return false
	if not _integer_between(money["car"], 0, 5) or money["cargo"] > Catalog.car(int(money["car"]))["capacity"]:
		return false
	if not _integer_between(data["rank"], 0, 10) or not _integer_between(data["points"], 0, 210):
		return false
	if int(data["years"]) not in [25, 50] or data["goal"] != data["years"] * 4:
		return false
	if not _integer_between(data["month"], 0, 601) or not _integer_between(data["steps"], 0, 65):
		return false
	if data["position"].size() != 2 or not _integer_between(data["position"][0], 0, 31) or not _integer_between(data["position"][1], 0, 23):
		return false
	if not CityRules.walkable(Vector2i(int(data["position"][0]), int(data["position"][1]))):
		return false
	if data["location"] != "" and Catalog.location(data["location"]).is_empty():
		return false
	for field: String in ["bribe_months", "prison_months", "street_steps"]:
		if not _integer_between(data["police"][field], 0, 1000000):
			return false
	if data["police"]["encounter"] not in ["", "SEARCH", "CONTRABAND", "WANTED", "COUNTERFEIT", "COURT"]:
		return false
	if not _integer_between(data["objectives"]["tips"], 0, 31) or data["objectives"]["ending"] not in ["", "VICTORY", "TIME_UP"]:
		return false
	if not data["job"].is_empty() and not _same_shape(data["job"], {"id": "", "months": 0, "wage": 0, "points": 0}):
		return false
	if not data["job"].is_empty():
		if data["job"]["id"] not in ["burial", "cards", "eviction", "street"] or not _integer_between(data["job"]["months"], 1, 3) or not _integer_between(data["job"]["wage"], 0, 3000) or not _integer_between(data["job"]["points"], 0, 6):
			return false
	if not data["safe"].is_empty():
		if not _same_shape(data["safe"], {"code": [], "wheels": [], "attempts": 0, "selected": 0, "feedback": ""}):
			return false
		if data["safe"]["code"].size() != 3 or data["safe"]["wheels"].size() != 3 or not _integer_between(data["safe"]["selected"], 0, 2):
			return false
		if not _integer_between(data["safe"]["attempts"], 1, 30):
			return false
		for digit: Variant in data["safe"]["code"] + data["safe"]["wheels"]:
			if not _integer_between(digit, 0, 9):
				return false
	if not data["combat"].is_empty():
		if not CombatRules.valid_save(data["combat"]):
			return false
		var member_indices: Array = []
		for unit: Dictionary in data["combat"]["units"]:
			if unit["side"] == 0:
				if not _integer_between(unit["member"], 0, data["gang"].size() - 1) or unit["member"] in member_indices:
					return false
				member_indices.append(unit["member"])
			elif unit["member"] != -1:
				return false
		if member_indices.size() != data["gang"].size() or data["combat"]["units"][int(data["combat"]["active"])]["energy"] <= 0:
			return false
	for message: Variant in data["messages"]:
		if not message is Dictionary or not _same_shape(message, {"key": "", "values": []}):
			return false
	for hint: Variant in data["tutorials"]:
		if not hint is String:
			return false
	return true

func _integer_between(value: Variant, low: int, high: int) -> bool:
	return (value is int or value is float) and is_finite(float(value)) and float(value) == floor(float(value)) and value >= low and value <= high

func _same_shape(value: Dictionary, template: Dictionary) -> bool:
	if value.size() != template.size():
		return false
	for key: String in template:
		if not value.has(key):
			return false
		var expected: Variant = template[key]
		var actual: Variant = value[key]
		if expected is Dictionary:
			if not actual is Dictionary:
				return false
			if not expected.is_empty() and not _same_shape(actual, expected):
				return false
		elif expected is int:
			if not _integer_between(actual, -1000000000, 1000000000):
				return false
		elif typeof(actual) != typeof(expected):
			return false
	return true

# JSON represents numbers as floats. Campaign values are integers; normalize
# only whole numbers so fractional or non-finite malformed values stay invalid.
func _normalize_numbers(value: Variant) -> Variant:
	if value is float and is_finite(value) and value == floor(value) and absf(value) <= 1000000000:
		return int(value)
	if value is Dictionary:
		for key: Variant in value:
			value[key] = _normalize_numbers(value[key])
	elif value is Array:
		for index in value.size():
			value[index] = _normalize_numbers(value[index])
	return value
