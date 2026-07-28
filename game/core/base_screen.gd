class_name BaseScreen
extends Node2D
## Zajedničko za sve ekrane: navigacija + kućica za povratak na hub.

## Gde vodi "kućica" — mini-igre iz džungle postavljaju "jungle".
var home_target := "hub"

func go(screen_name: String) -> void:
	get_tree().get_first_node_in_group("main").goto(screen_name)

func add_home_button() -> void:
	var btn := TapButton.new(Vector2(110, 110), 75, Color(1, 1, 1, 0.9))
	# ikonica kućice
	UI.poly(btn, PackedVector2Array([Vector2(-42, 0), Vector2(0, -38), Vector2(42, 0)]), Color("#e2574c"))  # krov
	UI.poly(btn, UI.rect_points(56, 36), Color("#f5b971"), Vector2(0, 18))  # zid
	UI.poly(btn, UI.rect_points(16, 20), Color("#8d5524"), Vector2(0, 26))  # vrata
	btn.tapped.connect(func() -> void: go(home_target))
	add_child(btn)

## Ambijent za mini-igre: oblaci + letač (leptir na farmi, komarac u džungli).
var ambient_flyer := "butterfly"

func add_ambient(cloud_count := 2, flyer := "butterfly") -> void:
	ambient_flyer = flyer
	var s := UI.vs(self)
	for i in cloud_count:
		Scenery.cloud(self, Vector2(s.x * randf_range(0.1, 0.9), randf_range(80, 230)), randf_range(0.7, 1.0))
	var fly_timer := Timer.new()
	fly_timer.wait_time = 7.0
	fly_timer.timeout.connect(_spawn_ambient_flyer)
	add_child(fly_timer)
	fly_timer.start()
	get_tree().create_timer(2.5).timeout.connect(_spawn_ambient_flyer)

func _spawn_ambient_flyer() -> void:
	var s := UI.vs(self)
	var y := randf_range(120, 380)
	var from_left := randf() < 0.5
	var from := Vector2(-60 if from_left else s.x + 60, y)
	var to := Vector2(s.x + 60 if from_left else -60, y + randf_range(-80, 80))
	if ambient_flyer == "mosquito":
		add_child(Mosquito.new(from, to))
	else:
		add_child(Butterfly.new(from, to, Butterfly.COLORS[randi() % Butterfly.COLORS.size()]))

func celebrate(pos: Vector2) -> void:
	Audio.play("fanfare")
	UI.confetti(self, pos, 90)
	UI.confetti(self, pos + Vector2(-350, 60), 50)
	UI.confetti(self, pos + Vector2(350, 60), 50)
