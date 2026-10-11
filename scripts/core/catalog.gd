class_name Catalog
extends RefCounted

static var definitions: Dictionary = {}

static func all() -> Dictionary:
	if definitions.is_empty():
		var resource := load("res://data/game_definitions.tres") as GameDefinitions
		definitions = resource.tables
	return definitions

static func weapon(index: int) -> Dictionary:
	return all()["weapons"][index]

static func car(index: int) -> Dictionary:
	return all()["cars"][index]

static func locations() -> Array:
	return all()["locations"]

static func location(identifier: String) -> Dictionary:
	for item: Dictionary in locations():
		if item["id"] == identifier:
			return item
	return {}
