extends BaseScreen
## Mini-igra: Nahrani životinju — dizajn po Claude Design mockupu.
## Životinje u redu gore, ispod svake ČINIJA (meta), hrana leži na koritu dole.
## Dete prevlači hranu u pravu činiju. Progresija: 2 → 3 → 4 životinje.

var round_num := 0
var animals_on_screen: Array = []   # AnimalSprite (glave) ili FarmBody (tela)
var plates := {}  # animal_id -> Sprite2D (činija)
var foods_left := 0
var _round_nodes: Array[Node] = []

## Prevlačenje se iz slike ne vidi: prst pokaže JEDNU hranu i činiju u koju
## ide. Igra nema greške, pa nagoveštaj sme da otkrije tačan par.
func hint_spot() -> Dictionary:
	if foods_left <= 0:
		return {}
	for f in get_children():
		if not (f is FoodItem) or f.dragging or f.locked:
			continue
		for a in animals_on_screen:
			if a.animal.food == f.kind and plates.has(a.animal.id):
				return {"from": f.position, "to": plates[a.animal.id].position}
	return {}


func _ready() -> void:
	var s := UI.vs(self)
	_setup_scene(s)
	add_home_button()
	add_hint(6.0)

	# korito preko donjeg dela
	if not _use_bodies():
		var trough := Scenery.svg(self, _trough_asset(), Vector2(s.x * 0.5, s.y * 0.79), (s.x * _trough_span()) / 600.0, 10)
		trough.z_index = 10

	_start_round()

## Svet — džungla varijanta prejaše ove kukice.
func _setup_scene(_s: Vector2) -> void:
	# Farma: dvorište iz kupljenog paketa — pozadina sa putem, štala i
	# drveće daleko, ograda iza životinja, cveće uz ivice. Sredina dole je
	# prazna trava: tu stoji hrana.
	var bg := Sprite2D.new()
	bg.texture = load("res://art/farm/bg-field.png")
	var bt := bg.texture.get_size()
	var sc: float = maxf(_s.y / bt.y, _s.x / bt.x)
	bg.scale = Vector2(sc, sc)
	bg.position = _s / 2.0
	bg.z_index = -60
	add_child(bg)
	_prop("tree-4", 0.15, 0.04, 0.58, -40)
	_prop("tree-1", 0.14, 0.30, 0.56, -41)
	_prop("tree-2", 0.10, 0.97, 0.58, -40)
	_prop("silo", 0.06, 0.66, 0.60, -37)
	_prop("barn", 0.19, 0.76, 0.61, -36)
	_prop("haypile", 0.14, 0.14, 0.64, -34)
	_prop("sunflowers", 0.09, 0.48, 0.66, -33)
	_prop("corn-group", 0.13, 0.90, 0.67, -33)
	_prop("bush-1", 0.11, 0.04, 1.01, 12)
	_prop("bush-2", 0.10, 0.96, 1.02, 12)
	# Oblaci IZA drveća (z -50), ne preko njega; leptiri kao i svuda.
	add_ambient(0)
	Scenery.cloud(self, Vector2(_s.x * 0.15, 120), 1.0, -50)
	Scenery.cloud(self, Vector2(_s.x * 0.72, 90), 0.8, -50)


func _prop(art: String, frac_w: float, cx: float, base_y: float, z: int) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/%s/%s.png" % [_art_dir(), art])
	var tex := sp.texture.get_size()
	var s := UI.vs(self)
	sp.scale = Vector2.ONE * ((s.x * frac_w) / tex.x)
	sp.offset = Vector2(0, -tex.y / 2.0)
	sp.position = Vector2(s.x * cx, s.y * base_y)
	sp.z_index = z
	add_child(sp)
	return sp

func _world_list() -> Array:
	return Animals.LIST

## Folder kupljenih rekvizita (art/<dir>/) — džungla ima svoj.
func _art_dir() -> String:
	return "farm"

## Senka pod nogama: na farmi je tlo nacrtano (put, zemlja), u džungli je ravno.
func _ground_shadows() -> bool:
	return false

## Visina tela po vrsti, u odnosu na "standardnu" visinu runde: veliki su
## veći, ptice manje.
func _body_rel(id: String) -> float:
	return {"horse": 1.08, "cow": 0.82, "goat": 0.78, "pig": 0.60, "chicken": 0.55, "duck": 0.55}.get(id, 0.7)

## Farma koristi životinje celim telom (kupljeni paketi); džungla još glave.
func _use_bodies() -> bool:
	return true

func _trough_asset() -> String:
	return "trough"

func _trough_span() -> float:
	return 0.616

## Gde se spušta hrana: kod tela je to gomila iz paketa ispred njuške.
func _plate_asset() -> String:
	return "haypile"

func _food_y() -> float:
	return 0.90

func _plate_span() -> float:
	return 0.075

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
	var plate_scale := (s.x * _plate_span()) / 256.0
	for i in n:
		var x := s.x * (i + 1) / (n + 1)
		if _use_bodies():
			# Razmaknute do ivica, da se gomile sena između njih ne dodiruju.
			var spread: float = {2: 0.56, 3: 0.36, 4: 0.26}.get(n, 0.26)
			x = s.x * (0.5 + (float(i) - float(n - 1) / 2.0) * spread)
		var a: Node2D
		var plate: Sprite2D
		if _use_bodies():
			# Telo stoji na travi ispred ograde, KRUPNO, gleda ka sredini;
			# ispred nogu je gomila sena iz paketa — tu se spušta hrana.
			# Visina po vrsti: konj i krava najveći, patka i kokoška najmanje.
			var rel: float = _body_rel(chosen[i].id)
			var h: float = s.y * (0.50 if n <= 2 else 0.42) * rel
			# Okrenute jedna prema drugoj: leve gledaju udesno, desne ulevo.
			var faces_right: bool = x < s.x * 0.5
			a = FarmBody.new(chosen[i], h, faces_right)
			a.position = Vector2(x, s.y * 0.80)
			a.z_index = 2
			if _ground_shadows():
				a.add_shadow()
			# Seno UZ NJUŠKU: na istoj liniji tla, odmah ispred prednje ivice
			# tela, na strani u koju životinja gleda; ispred nje po dubini.
			var body_w: float = a.body_size().x
			var dirn: float = 1.0 if faces_right else -1.0
			plate = _prop(_plate_asset(), 0.10 if n <= 3 else 0.085, (x + dirn * (body_w * 0.42 + s.x * 0.012)) / s.x, 0.805, 6)
		else:
			a = AnimalSprite.new(chosen[i], head_scale)
			a.position = Vector2(x, s.y * 0.28)
			plate = Scenery.svg(self, _plate_asset(), Vector2(x, s.y * 0.50), plate_scale, 5)
		add_child(a)
		animals_on_screen.append(a)
		_round_nodes.append(a)

		plates[chosen[i].id] = plate
		_round_nodes.append(plate)

	# hrana na obodu korita — kompaktna grupa centrirana na sredini
	var foods := chosen.map(func(c): return c.food)
	foods.shuffle()
	var spacing := s.x * (0.15 if _use_bodies() else 0.13)
	for i in n:
		var fx := s.x * 0.5 + (i - (n - 1) / 2.0) * spacing
		var f := FoodItem.new(foods[i], Vector2(fx, s.y * _food_y()), s.x * (0.085 if _use_bodies() else 0.062))
		f.dropped.connect(_on_food_dropped)
		add_child(f)
		_round_nodes.append(f)

## NAJBLIŽA gomila u dometu — sa tri-četiri životinje gomile dve susedne
## umeju da budu bliže od dometa, pa "prva u listi" pogađa pogrešnu.
func _plate_hit(food: FoodItem) -> String:
	var s := UI.vs(self)
	var best := ""
	var best_d: float = s.x * maxf(0.09, _plate_span())
	for id in plates:
		var d: float = food.global_position.distance_to(plates[id].global_position + Vector2(0, -s.y * 0.03))
		if d < best_d:
			best_d = d
			best = id
	return best

func _on_food_dropped(food: FoodItem) -> void:
	var hit_id := _plate_hit(food)
	if hit_id == "":
		food.go_home()
		return
	var animal_node: Node2D = null
	for a in animals_on_screen:
		if a.animal.id == hit_id:
			animal_node = a
			break
	if animal_node.animal.food == food.kind:
		_feed(animal_node, food)
	else:
		Audio.play("wrong", -8.0)
		animal_node.shake()
		food.go_home()

func _feed(animal_node: Node2D, food: FoodItem) -> void:
	foods_left -= 1
	# plop u činiju → nom-nom žvakanje → srećan poskok (slojevit feedback)
	food.eaten_by(plates[animal_node.animal.id].global_position)
	UI.haptic(35)
	Audio.play("plop")
	get_tree().create_timer(0.20).timeout.connect(func() -> void: Audio.play("nom"))
	get_tree().create_timer(1.00).timeout.connect(func() -> void: animal_node.react(true))
	if foods_left == 0:
		round_num += 1
		_victory_dance()
		if _use_bodies():
			# Bez konfeta: dečji glas i mali narandžasti sjaj oko svake životinje.
			Audio.play(["yay", "giggle", "kid"][randi() % 3], -2.0)
			for a in animals_on_screen:
				_glow(a.position + Vector2(0, -UI.vs(self).y * 0.14), UI.vs(self).y * 0.18)
		else:
			celebrate(UI.vs(self) / 2)
		get_tree().create_timer(1.8).timeout.connect(_start_round)

## Sve životinje zaplešu kad je runda gotova.
func _glow(pos: Vector2, height: float) -> void:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/fx/charge-1.png")
	sp.scale = Vector2.ONE * (height / sp.texture.get_size().y)
	sp.position = pos
	sp.z_index = 25
	sp.modulate = Color(1.0, 0.62, 0.2, 0.55)   # blaže, upola providno
	add_child(sp)
	var tw := create_tween()
	for i in 10:
		var idx := i + 1
		tw.tween_callback(func() -> void: sp.texture = load("res://art/fx/charge-%d.png" % idx))
		tw.tween_interval(0.05)
	tw.tween_callback(sp.queue_free)


func _victory_dance() -> void:
	for a in animals_on_screen:
		if a is FarmBody:
			# Bez klaćenja: ko ima jedenje žvaće, ostali skoče.
			(a as FarmBody).play_happy()
			continue
		var tw: Tween = a.create_tween()
		for i in 3:
			tw.tween_property(a, "rotation", 0.14, 0.12)
			tw.tween_property(a, "rotation", -0.14, 0.12)
		tw.tween_property(a, "rotation", 0.0, 0.1)
