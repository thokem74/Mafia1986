extends Node

signal changed

var language: String = "de"
var music_volume: float = 0.35
var sound_volume: float = 0.65
var hints: bool = true

func _ready() -> void:
	var config := ConfigFile.new()
	if config.load("user://settings.cfg") == OK:
		language = config.get_value("settings", "language", "de")
		music_volume = float(config.get_value("settings", "music", 0.35))
		sound_volume = float(config.get_value("settings", "sound", 0.65))
		hints = bool(config.get_value("settings", "hints", true))
	apply()

func apply() -> void:
	if language not in ["de", "en"]:
		language = "de"
	TranslationServer.set_locale(language)
	changed.emit()

func save() -> void:
	var config := ConfigFile.new()
	config.set_value("settings", "language", language)
	config.set_value("settings", "music", music_volume)
	config.set_value("settings", "sound", sound_volume)
	config.set_value("settings", "hints", hints)
	config.save("user://settings.cfg")
	apply()
