class_name ObjectiveState
extends RefCounted

var tips: int = 0
var mayor_completed: bool = false
var transporter_completed: bool = false
var ending: String = ""

func won(points: int, goal: int) -> bool:
	return points >= goal and mayor_completed and transporter_completed

func to_dict() -> Dictionary:
	return {"tips": tips, "mayor_completed": mayor_completed,
		"transporter_completed": transporter_completed, "ending": ending}

static func from_dict(value: Dictionary) -> ObjectiveState:
	var result := ObjectiveState.new()
	for field: String in value:
		result.set(field, value[field])
	return result
