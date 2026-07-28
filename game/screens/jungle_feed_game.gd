extends "res://screens/feed_game.gd"
## Nahrani džunglu — isti engine kao farma, džungla scena:
## šuplje deblo umesto korita, list umesto tanjira, džungla hrana.

func _setup_scene(_s: Vector2) -> void:
	home_target = "jungle"
	Scenery.background(self, "background-jfeed")
	add_ambient(0, "mosquito")

func _world_list() -> Array:
	return Animals.JUNGLE

func _trough_asset() -> String:
	return "log-trough"

func _trough_span() -> float:
	return 0.46

func _plate_asset() -> String:
	return "leaf-plate"

func _food_y() -> float:
	return 0.655

func _plate_span() -> float:
	return 0.115  # list-tanjir krupniji — jasnija meta za decu
