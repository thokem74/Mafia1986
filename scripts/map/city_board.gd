extends Node2D

const CELL_SIZE := 10.0

var annotation_scale: float = 1.0


func refresh(campaign: Campaign) -> void:
	$Player.position = (Vector2(campaign.position) + Vector2(0.5, 0.5)) * CELL_SIZE
	var nearby := CityRules.nearby(campaign)
	var destination := str(nearby[0]["id"]) if not nearby.is_empty() else ""
	for marker: Node2D in $Locations.get_children():
		marker.refresh(Catalog.location(str(marker.name)), campaign, destination)
	fit_annotations(annotation_scale)


func fit_annotations(map_scale: float) -> void:
	annotation_scale = map_scale
	$Player.scale = Vector2.ONE / map_scale
	for marker: Node2D in $Locations.get_children():
		marker.fit_annotations(map_scale, character_rect())


func character_rect() -> Rect2:
	return Rect2($Player.global_position - Vector2(10, 13), Vector2(20, 26))


func player_rect() -> Rect2:
	# The dark outer edge of the radius-18 ring extends to 20 screen pixels.
	return Rect2($Player.global_position - Vector2(20, 20), Vector2(40, 40))
