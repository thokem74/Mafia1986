class_name CityRules
extends RefCounted

const SIZE := Vector2i(32, 24)
const DIRECTIONS := [Vector2i.UP, Vector2i.LEFT, Vector2i.DOWN, Vector2i.RIGHT]

static func walkable(cell: Vector2i) -> bool:
	if cell.x < 1 or cell.x >= SIZE.x - 1 or cell.y < 1 or cell.y >= SIZE.y - 1:
		return false
	return cell.y in [3, 9, 15, 21] or cell.x in [3, 7, 11, 15, 19, 23, 27]

static func nearby(campaign: Campaign) -> Array[Dictionary]:
	var found: Array[Dictionary] = []
	for item: Dictionary in Catalog.locations():
		var cell := Vector2i(item["x"], item["y"])
		if absi(cell.x - campaign.position.x) + absi(cell.y - campaign.position.y) <= 1 and visible(item, campaign):
			found.append(item)
	return found

static func visible(item: Dictionary, campaign: Campaign) -> bool:
	if item["kind"] == "mayor":
		return campaign.objectives.tips & 16 != 0 and not campaign.objectives.mayor_completed
	if item["kind"] == "transport":
		return campaign.objectives.tips & 4 != 0 and not campaign.objectives.transporter_completed
	return true
