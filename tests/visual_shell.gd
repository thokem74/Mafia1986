extends "res://scripts/ui/main.gd"


func _notification(what: int) -> void:
	# A desktop window-close event must not silently truncate the capture matrix.
	if what != NOTIFICATION_WM_CLOSE_REQUEST:
		super._notification(what)
