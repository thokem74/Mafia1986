class_name Gangster
extends RefCounted

var gangster_name: String = "Charlie"
var strength: int = 20
var intelligence: int = 20
var brutality: int = 20
var energy: int = 5
var weapon: int = 0
var sex: int = 0

func max_energy() -> int:
	return mini(99, 2 + strength / 4 + brutality / 4)

func recover() -> void:
	energy = mini(max_energy(), energy + strength / 10 + 1)

func to_dict() -> Dictionary:
	return {"name": gangster_name, "strength": strength, "intelligence": intelligence,
		"brutality": brutality, "energy": energy, "weapon": weapon, "sex": sex}

static func from_dict(value: Dictionary) -> Gangster:
	var person := Gangster.new()
	person.gangster_name = value.get("name", "Charlie")
	person.strength = int(value.get("strength", 20))
	person.intelligence = int(value.get("intelligence", 20))
	person.brutality = int(value.get("brutality", 20))
	person.energy = int(value.get("energy", 5))
	person.weapon = int(value.get("weapon", 0))
	person.sex = int(value.get("sex", 0))
	return person
