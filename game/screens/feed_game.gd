extends BaseScreen
## Mini-igra: Nahrani životinju — dizajn po Claude Design mockupu.
## Životinje u redu gore, ispod svake ČINIJA (meta), hrana leži na koritu dole.
## Dete prevlači hranu u pravu činiju. Progresija: 2 → 3 → 4 životinje.

var round_num := 0
var animals_on_screen: Array[AnimalSprite] = []
var plates := {}  # animal_id -> Sprite2D (činija)
var foods_left := 0
var _round_nodes: Array[Node] = []

func _ready() -> void:
	var s := UI.vs(self)
	_setup_scene(s)
	add_home_button()

	# korito preko donjeg dela (raspon 0.19–0.81 širine kao na mockupu)
	var trough := Scenery.svg(self, "trough", Vector2(s.x * 0.5, s.y * 0.79), (s.x * 0.616) / 600.0, 10)
	trough.z_index = 10

	_start_round()

## Svet — džungla varijanta prejaše ovo dvoje.
func _setup_scene(_s: Vector2) -> void:
	Scenery.background(self, "background-feed")
	add_ambient()

func _world_list() -> Array:
	return Animals.LIST

func _animal_count() -> int:
	return clampi(2 + round_num / 3, 2, 4)

func _start_round() -> void:
	for n in _round_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_round_nodes.clear()
	animals_on_screen.clear()
	plates.clear()

	var s := UI.vs(self)
	var chosen := Animals.random_set(_animal_count(), _world_list())
	foods_left = chosen.size()
	var n := chosen.size()

	# životinje u redu gore + činija ispod svake
	var head_scale := (s.x * 0.092) / 230.0
	var plate_scale := (s.x * 0.075) / 256.0
	for i in n:
		var x := s.x * (i + 1) / (n + 1)
		var a := AnimalSprite.new(chosen[i], head_scale)
		a.position = Vector2(x, s.y * 0.28)
		add_child(a)
		animals_on_screen.append(a)
		_round_nodes.append(a)

		var plate := Scenery.svg(self, "feeding-plate", Vector2(x, s.y * 0.50), plate_scale, 5)
		plates[chosen[i].id] = plate
		_round_nodes.append(plate)

	# hrana na obodu korita — kompaktna grupa centrirana na sredini
	var foods := chosen.map(func(c): return c.food)
	foods.shuffle()
	var spacing := s.x * 0.13
	for i in n:
		var fx := s.x * 0.5 + (i - (n - 1) / 2.0) * spacing
		var f := FoodItem.new(foods[i], Vector2(fx, s.y * 0.72), s.x * 0.062)
		f.dropped.connect(_on_food_dropped)
		add_child(f)
		_round_nodes.append(f)

func _plate_hit(food: FoodItem) -> String:
	var s := UI.vs(self)
	for id in plates:
		if food.global_position.distance_to(plates[id].global_position) < s.x * 0.075:
			return id
	return ""

func _on_food_dropped(food: FoodItem) -> void:
	var hit_id := _plate_hit(food)
	if hit_id == "":
		food.go_home()
		return
	var animal_node: AnimalSprite = null
	for a in animals_on_screen:
		if a.animal.id == hit_id:
			animal_node = a
			break
	if animal_node.animal.food == food.kind:
		_feed(animal_node, food)
	else:
		Audio.play("wrong", -6.0)
		animal_node.shake()
		food.go_home()

func _feed(animal_node: AnimalSprite, food: FoodItem) -> void:
	foods_left -= 1
	# hrana upadne u činiju, pa životinja srećno poskoči
	food.eaten_by(plates[animal_node.animal.id].global_position)
	UI.haptic(35)
	Audio.play("pop")
	animal_node.react(true)
	if foods_left == 0:
		round_num += 1
		_victory_dance()
		celebrate(UI.vs(self) / 2)
		get_tree().create_timer(1.8).timeout.connect(_start_round)

## Sve životinje zaplešu kad je runda gotova.
func _victory_dance() -> void:
	for a in animals_on_screen:
		var tw := a.create_tween()
		for i in 3:
			tw.tween_property(a, "rotation", 0.14, 0.12)
			tw.tween_property(a, "rotation", -0.14, 0.12)
		tw.tween_property(a, "rotation", 0.0, 0.1)
