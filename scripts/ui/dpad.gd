extends GridContainer

signal direction_pressed(direction: Vector2i)

var held := Vector2i.ZERO
var repeat_enabled: bool = true
@onready var repeat_timer: Timer = $Repeat

func _ready() -> void:
	for pair: Array in [["Up", Vector2i.UP], ["Left", Vector2i.LEFT], ["Down", Vector2i.DOWN], ["Right", Vector2i.RIGHT]]:
		var button: Button = get_node(pair[0])
		button.button_down.connect(_press.bind(pair[1]))
		button.button_up.connect(_release)
	repeat_timer.timeout.connect(_repeat)

func _press(direction: Vector2i) -> void:
	held = direction
	direction_pressed.emit(direction)
	if repeat_enabled:
		repeat_timer.wait_time = 0.35
		repeat_timer.start()

func _release() -> void:
	held = Vector2i.ZERO
	repeat_timer.stop()

func _repeat() -> void:
	if held != Vector2i.ZERO and repeat_enabled:
		direction_pressed.emit(held)
		repeat_timer.wait_time = 0.12

func stop() -> void:
	_release()

func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_PAUSED or (what == NOTIFICATION_VISIBILITY_CHANGED and not is_visible_in_tree()):
		_release()
