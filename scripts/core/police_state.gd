class_name PoliceState
extends RefCounted

var bribe_months: int = 0
var forged_id: bool = false
var counterfeit: bool = false
var prison_months: int = 0
var street_steps: int = 0
var encounter: String = ""

func to_dict() -> Dictionary:
	return {"bribe_months": bribe_months, "forged_id": forged_id,
		"counterfeit": counterfeit, "prison_months": prison_months,
		"street_steps": street_steps, "encounter": encounter}

static func from_dict(value: Dictionary) -> PoliceState:
	var result := PoliceState.new()
	for field: String in value:
		result.set(field, value[field])
	return result
