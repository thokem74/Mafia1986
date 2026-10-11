extends Node2D

func refresh(campaign: Campaign) -> void:
	$Player.position = Vector2(campaign.position) * 10 + Vector2(5, 5)
	for marker: Sprite2D in $Locations.get_children():
		var item := Catalog.location(str(marker.name))
		marker.visible = CityRules.visible(item, campaign)
