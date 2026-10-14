extends VBoxContainer

signal action_requested(action: String, amount: int, member: int, item: int)
const ACTION_SCENE := preload("res://scenes/ui/action_row.tscn")
var current_action: String = ""
var campaign: Campaign
@onready var actions: VBoxContainer = $ActionScroll/Actions
@onready var member: OptionButton = $Parameters/Member
@onready var item: OptionButton = $Parameters/Item
@onready var amount: SpinBox = $Parameters/Quantity/Amount

func _ready() -> void:
	$Parameters/Quantity/Minus.pressed.connect(func(): amount.value = maxi(1, int(amount.value) - int(amount.step)))
	$Parameters/Quantity/Plus.pressed.connect(func(): amount.value += amount.step)
	$Parameters/Execute.pressed.connect(func(): action_requested.emit(current_action, int(amount.value), member.selected, item.get_selected_id()))
	item.item_selected.connect(func(_index: int): _update_details())
	member.item_selected.connect(func(_index: int): _update_details())

func refresh(value: Campaign) -> void:
	campaign = value
	$LocationHint.visible = Settings.hints
	var location := Catalog.location(campaign.location)
	$Title.text = tr(location["name_key"])
	var selected_member := member.selected
	member.clear()
	for person in campaign.gang:
		member.add_item("%s · %s %d" % [person.gangster_name, tr("ENERGY"), person.energy])
	member.select(clampi(selected_member, 0, member.item_count - 1))
	for child in actions.get_children():
		child.free()
	var available := LocationRules.actions(location["kind"])
	for action: String in available:
		var button: Button = ACTION_SCENE.instantiate()
		actions.add_child(button)
		button.text = tr("ACT_" + action.to_upper())
		button.set_meta("action", action)
		button.pressed.connect(_select.bind(action))
		button.button_pressed = action == current_action
	if current_action not in available:
		current_action = ""
	$Parameters.visible = not current_action.is_empty()
	if not current_action.is_empty():
		_select(current_action)

func _select(action: String) -> void:
	current_action = action
	for button: Button in actions.get_children():
		button.set_pressed_no_signal(button.get_meta("action") == action)
	$Parameters.show()
	$Parameters/Help.text = tr("HELP_" + action.to_upper())
	member.visible = action in ["weapon", "train", "camp", "pickpocket", "steal", "dismiss"]
	item.visible = action in ["weapon", "car", "recruit"]
	$Parameters/Quantity.visible = action in ["buy_alcohol", "sell_alcohol", "rent", "protection", "fake", "gamble1", "gamble2", "gamble3", "borrow", "repay", "invest", "withdraw"]
	var old_selection := item.selected
	item.clear()
	if action == "weapon":
		for index in range(1, 9):
			item.add_item("%s · $%d" % [tr(Catalog.weapon(index)["name_key"]), Catalog.weapon(index)["price"]], index)
	elif action == "car":
		for index in range(1, 6):
			item.add_item("%s · $%d" % [tr(Catalog.car(index)["name_key"]), Catalog.car(index)["price"]], index)
	elif action == "recruit":
		for offer: Dictionary in Catalog.all()["recruits"]:
			item.add_item("%s · $%d" % [offer["name"], offer["price"]])
	if item.item_count > 0:
		item.select(clampi(old_selection, 0, item.item_count - 1))
	amount.max_value = 36 if action == "rent" else (12 if action == "protection" else (200 if "alcohol" in action else 10000))
	amount.step = 1 if action in ["rent", "protection", "buy_alcohol", "sell_alcohol"] else 100
	amount.value = clampf(amount.value, 1, amount.max_value)
	_update_details()

func _update_details() -> void:
	$Parameters/Details.text = ""
	$Parameters/Requirements.text = ""
	$Parameters/Execute.disabled = false
	if item.item_count == 0:
		return
	var index := item.get_selected_id()
	if current_action == "weapon":
		var data := Catalog.weapon(index)
		$Parameters/Details.text = tr("DETAIL_WEAPON") % [data["price"], data["range"], data["precision"], data["damage"]]
		var person := campaign.gang[member.selected]
		var requirements := EconomyRules.weapon_requirements(index)
		var stat_details: PackedStringArray = []
		var needs_training := false
		for stat: String in requirements:
			var minimum := int(requirements[stat])
			if minimum == 0:
				continue
			var current := int(person.get(stat))
			stat_details.append("%s %d/%d" % [tr(stat.to_upper()), current, minimum])
			needs_training = needs_training or current < minimum
		if not stat_details.is_empty():
			$Parameters/Requirements.text = tr("WEAPON_STATS") % " · ".join(stat_details)
			if needs_training:
				$Parameters/Requirements.text += "\n" + tr("WEAPON_TRAIN_FIRST")
		# The purchase rules charge the full price before crediting a trade-in.
		var needs_money := campaign.economy.money < int(data["price"])
		$Parameters/Execute.disabled = needs_training or needs_money
		if needs_money:
			if not $Parameters/Requirements.text.is_empty():
				$Parameters/Requirements.text += "\n"
			$Parameters/Requirements.text += tr("NO_MONEY")
	elif current_action == "car":
		var data := Catalog.car(index)
		$Parameters/Details.text = tr("DETAIL_CAR") % [data["price"], data["capacity"], data["movement"]]
	elif current_action == "recruit":
		var data: Dictionary = Catalog.all()["recruits"][index]
		$Parameters/Details.text = "%s %d · %s %d · %s %d" % [tr("STRENGTH"), data["strength"], tr("INTELLIGENCE"), data["intelligence"], tr("BRUTALITY"), data["brutality"]]
