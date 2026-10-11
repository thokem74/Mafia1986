class_name EconomyState
extends RefCounted

var money: int = 0
var car: int = 0
var cargo: int = 0
var debt: int = 0
var debt_months: int = 0
var rent_months: int = 0
var has_hideout: bool = false
var owns_business: bool = false
var investment: int = 0

func pay(amount: int) -> bool:
	if amount < 0 or money < amount:
		return false
	money -= amount
	return true

func to_dict() -> Dictionary:
	return {"money": money, "car": car, "cargo": cargo, "debt": debt,
		"debt_months": debt_months, "rent_months": rent_months, "has_hideout": has_hideout,
		"owns_business": owns_business, "investment": investment}

static func from_dict(value: Dictionary) -> EconomyState:
	var result := EconomyState.new()
	for field: String in value:
		result.set(field, value[field])
	return result
