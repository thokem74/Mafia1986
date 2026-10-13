extends TextureRect

const BACKGROUND_DIRECTORY := "res://assets/backgrounds/"

var current_art: String = "menu"


func show_screen(screen: String, campaign: Campaign) -> void:
	var art := "menu"
	match screen:
		"NewGame", "SettingsScreen", "StatusScreen", "SaveScreen", "CreditsScreen", "DebugScreen":
			art = "hideout"
		"Game":
			art = "combat" if campaign != null and not campaign.combat.is_empty() else "city"
		"Location":
			if campaign != null and not campaign.location.is_empty():
				art = str(Catalog.location(campaign.location)["kind"])
		"PoliceScreen":
			art = "police"
		"SafeScreen":
			art = "safe"
		"EndingScreen":
			art = "ending"
	if art == current_art:
		return
	# Load on screen changes, never per frame. The backdrop stays behind all input controls.
	texture = load(BACKGROUND_DIRECTORY + art + ".png") as Texture2D
	current_art = art
