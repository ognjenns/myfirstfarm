extends "res://screens/feed_game.gd"
## Nahrani džunglu — isti engine kao farma, džungla svet:
## banana→majmun, kikiriki→slon, lišće→žirafa, batak→lav,
## semenke→papagaj, lubenica→nilski konj.

func _setup_scene(_s: Vector2) -> void:
	home_target = "jungle"
	Scenery.background(self, "background-jungle")
	add_ambient(0, "mosquito")

func _world_list() -> Array:
	return Animals.JUNGLE
