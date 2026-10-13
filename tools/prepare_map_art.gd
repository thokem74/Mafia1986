extends SceneTree

const MARKERS := ["pub", "arms", "cars", "store", "bank", "police", "hideout", "forgery", "casino", "loan", "subway", "station", "mayor", "transport"]


func _initialize() -> void:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://assets/maps/prompts.json"))
	for asset: Dictionary in manifest["assets"]:
		var image := Image.load_from_file(asset["source"])
		if image.is_empty():
			push_error("Missing generated source: " + str(asset["source"]))
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


func _save_sprite(image: Image, identifier: String, dimensions: Vector2i) -> void:
	# Trim transparent generation padding, then preserve the object's proportions.
	var sprite := image.get_region(image.get_used_rect())
	var factor := minf(float(dimensions.x) / sprite.get_width(), float(dimensions.y) / sprite.get_height())
	sprite.resize(maxi(1, roundi(sprite.get_width() * factor)), maxi(1, roundi(sprite.get_height() * factor)), Image.INTERPOLATE_NEAREST)
	var canvas := Image.create(dimensions.x, dimensions.y, false, Image.FORMAT_RGBA8)
	canvas.blit_rect(sprite, Rect2i(Vector2i.ZERO, sprite.get_size()), (dimensions - sprite.get_size()) / 2)
	canvas.save_png("res://assets/maps/%s.png" % identifier)
