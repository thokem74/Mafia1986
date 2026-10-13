extends Node2D

var highlighted: bool = false


func refresh(item: Dictionary, campaign: Campaign, destination: String) -> void:
	visible = CityRules.visible(item, campaign)
	highlighted = str(item["id"]) == destination
	$Annotation/Name/Text.text = tr("MAP_LOC_" + str(item["kind"]).to_upper())
	$Annotation/Selected.visible = highlighted
	$Annotation/Connector.default_color = Color(0.65, 0.95, 1.0) if highlighted else Color(0.95, 0.76, 0.43)


func fit_annotations(map_scale: float, character_rect: Rect2) -> void:
	# Positions stay in map cells; the badge and text keep their screen-pixel size.
	$Annotation.scale = Vector2.ONE / map_scale
	var label_width := minf(82.0, 40.0 * map_scale - 2.0)
	$Annotation/Name.offset_left = -label_width / 2.0
	$Annotation/Name.offset_right = label_width / 2.0
	$Annotation/Name.offset_top = -58.0
	$Annotation/Name.offset_bottom = -38.0
	var default_label := Rect2($Annotation.global_position + Vector2(-label_width / 2.0, -58.0), Vector2(label_width, 20.0))
	var beside_player := default_label.intersects(character_rect)
	# A player on a vertical street can pass beside a rooftop label. Put that
	# label below a raised badge while keeping both inside the same roof block.
	$Annotation/Badge.position.y = -40.0 if beside_player else -30.0
	$Annotation/Icon.position.y = -28.0 if beside_player else -18.0
	$Annotation/Selected.position.y = -10.0 if beside_player else 0.0
	$Annotation/Connector.points = PackedVector2Array([Vector2.ZERO, Vector2(0, -16 if beside_player else -6)])
	if beside_player:
		$Annotation/Name.offset_top = -14.0
		$Annotation/Name.offset_bottom = 6.0


func annotation_rect() -> Rect2:
	var label: Control = $Annotation/Name
	var badge: Control = $Annotation/Badge
	return label.get_global_rect().merge(badge.get_global_rect())
