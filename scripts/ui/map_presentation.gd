extends Control

const CELL_SIZE := 10.0
const ART_DIRECTORY := "res://assets/maps/"

var combat_visible: bool = false
var current_art: String = ""
var map_rect := Rect2()


static func combat_art(reason: String) -> String:
	match reason:
		"store":
			return "shop"
		"bank":
			return "bank"
		"train":
			return "train"
		"transport":
			return "warehouse"
		"mayor", "mayor_guards":
			return "mayor"
		_:
			return "street"


func refresh(campaign: Campaign) -> void:
	combat_visible = not campaign.combat.is_empty()
	%CityBoard.visible = not combat_visible
	%CombatBoard.visible = combat_visible
	var art := combat_art(str(campaign.combat["reason"])) if combat_visible else "surroundings"
	if art != current_art:
		$Terrain.texture = load(ART_DIRECTORY + art + ".png") as Texture2D
		current_art = art
	$Terrain.modulate = Color.WHITE if combat_visible else Color(0.3, 0.3, 0.3, 1.0)
	if combat_visible:
		%CombatBoard.refresh(campaign)
	else:
		%CityBoard.refresh(campaign)


func fit_to(area: Rect2) -> void:
	if not combat_visible:
		# Leave room above the first rooftop row for constant-size location labels.
		area.position.y += 24.0
		area.size.y -= 24.0
	# Reserve the whole grid before scaling; overlays never conceal a playable cell.
	var dimensions := Vector2(CombatRules.SIZE if combat_visible else CityRules.SIZE) * CELL_SIZE
	var factor := minf(area.size.x / dimensions.x, area.size.y / dimensions.y)
	var board: Node2D = %CombatBoard if combat_visible else %CityBoard
	board.scale = Vector2.ONE * factor
	board.position = (area.position - global_position + (area.size - dimensions * factor) / 2.0).round()
	map_rect = Rect2(global_position + board.position, dimensions * factor)
	if not combat_visible:
		%CityBoard.fit_annotations(factor)
