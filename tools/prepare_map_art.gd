extends SceneTree

const MARKERS := ["pub", "arms", "cars", "store", "bank", "police", "hideout", "forgery", "casino", "loan", "subway", "station", "mayor", "transport"]
const SPRITE_ASSETS := ["player", "enemy", "cover", "locations"]


func _initialize() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/prompts.json"))
	for asset: Dictionary in manifest["assets"]:
		# Background refreshes must not reprocess the existing character or marker sprites.
		if "--terrain-only" in OS.get_cmdline_user_args() and asset["name"] in SPRITE_ASSETS:
			continue
		var image := Image.load_from_file(asset["source"])
		if image.is_empty():
			push_error("Missing generated source: " + str(asset["source"]))
			quit(1)
			return
		if asset["name"] == "city" and asset.has("layout_preparation"):
			image = _fit_city_layout(image, asset["layout_preparation"])
			if image == null:
				quit(1)
				return
		if asset["name"] == "locations":
			for index: int in MARKERS.size():
				var cell_size := image.get_size() / 4
				var cell := image.get_region(Rect2i(Vector2i(index % 4, index / 4) * cell_size, cell_size))
				_save_sprite(cell, "markers/" + MARKERS[index], Vector2i(14, 14))
		elif asset["name"] in ["player", "enemy", "cover"]:
			_save_sprite(image, asset["name"], Vector2i(20, 20))
		else:
			image.resize(int(asset["size"][0]), int(asset["size"][1]), Image.INTERPOLATE_NEAREST)
			image.save_png("res://assets/maps/%s.png" % asset["name"])
	quit()


func _fit_city_layout(source: Image, layout: Dictionary) -> Image:
	# Generation can drift a few pixels. Fit its roof blocks to the actual game cells
	# instead of trusting the generated roads or changing the gameplay coordinates.
	const CELL_PIXELS := 10
	var columns := _city_building_spans(true)
	var rows := _city_building_spans(false)
	var source_columns: Array = layout["source_columns"]
	var source_rows: Array = layout["source_rows"]
	if columns.size() != source_columns.size() or rows.size() != source_rows.size():
		push_error("Generated city roof regions do not match the gameplay layout")
		return null
	var dimensions := CityRules.SIZE * CELL_PIXELS
	var canvas := Image.create(dimensions.x, dimensions.y, false, Image.FORMAT_RGB8)
	canvas.fill(source.get_pixel(0, 0))
	var sample: Array = layout["road_sample"]
	var road_region := Rect2i(int(sample[0]), int(sample[1]), int(sample[2]), int(sample[3]))
	var road := source.get_region(road_region)
	road.resize(CELL_PIXELS, CELL_PIXELS, Image.INTERPOLATE_NEAREST)
	for cell_y: int in CityRules.SIZE.y:
		for cell_x: int in CityRules.SIZE.x:
			var cell := Vector2i(cell_x, cell_y)
			if CityRules.walkable(cell):
				canvas.blit_rect(road, Rect2i(Vector2i.ZERO, road.get_size()), cell * CELL_PIXELS)
	for row_index: int in rows.size():
		for column_index: int in columns.size():
			var source_x: Array = source_columns[column_index]
			var source_y: Array = source_rows[row_index]
			var source_position := Vector2i(int(source_x[0]), int(source_y[0]))
			var source_end := Vector2i(int(source_x[1]), int(source_y[1]))
			var roof := source.get_region(Rect2i(source_position, source_end - source_position))
			var column: Vector2i = columns[column_index]
			var row: Vector2i = rows[row_index]
			var roof_size := Vector2i(column.y - column.x, row.y - row.x) * CELL_PIXELS
			roof.resize(roof_size.x, roof_size.y, Image.INTERPOLATE_NEAREST)
			var roof_position := Vector2i(column.x, row.x) * CELL_PIXELS
			canvas.blit_rect(roof, Rect2i(Vector2i.ZERO, roof.get_size()), roof_position)
	return canvas


func _city_building_spans(horizontal: bool) -> Array[Vector2i]:
	# End-exclusive spans describe the roof blocks between the one-cell streets.
	var spans: Array[Vector2i] = []
	var length: int = CityRules.SIZE.x if horizontal else CityRules.SIZE.y
	var start: int = -1
	for coordinate: int in range(1, length - 1):
		var cell := Vector2i(coordinate, 1) if horizontal else Vector2i(1, coordinate)
		if CityRules.walkable(cell):
			if start >= 0:
				spans.append(Vector2i(start, coordinate))
				start = -1
		elif start < 0:
			start = coordinate
	if start >= 0:
		spans.append(Vector2i(start, length - 1))
	return spans


func _save_sprite(image: Image, identifier: String, dimensions: Vector2i) -> void:
	# Trim transparent generation padding, then preserve the object's proportions.
	var sprite := image.get_region(image.get_used_rect())
	var factor := minf(float(dimensions.x) / sprite.get_width(), float(dimensions.y) / sprite.get_height())
	sprite.resize(maxi(1, roundi(sprite.get_width() * factor)), maxi(1, roundi(sprite.get_height() * factor)), Image.INTERPOLATE_NEAREST)
	var canvas := Image.create(dimensions.x, dimensions.y, false, Image.FORMAT_RGBA8)
	canvas.blit_rect(sprite, Rect2i(Vector2i.ZERO, sprite.get_size()), (dimensions - sprite.get_size()) / 2)
	canvas.save_png("res://assets/maps/%s.png" % identifier)
