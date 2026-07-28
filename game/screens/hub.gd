extends BaseScreen
## Hub — dvorište farme po Claude Design mockupu: slojevita brda, kuća + silos,
## ograda, drvo, bara, bale sena, cveće; 6 životinja + 4 kapije mini-igara.

const ANIMAL_FRACS := {
	"cow": Vector2(0.235, 0.63),
	"horse": Vector2(0.385, 0.51),
	"pig": Vector2(0.525, 0.64),
	"goat": Vector2(0.625, 0.48),
	"chicken": Vector2(0.72, 0.67),
	"duck": Vector2(0.875, 0.58),
}

var animal_nodes: Array[AnimalSprite] = []

func _ready() -> void:
	var s := UI.vs(self)
	Scenery.background(self)
	_build_scenery(s)

	for animal in Animals.LIST:
		var frac: Vector2 = ANIMAL_FRACS[animal.id]
		var a := AnimalSprite.new(animal, 1.1)
		a.position = frac * s
		a.tapped.connect(_on_animal_tapped)
		add_child(a)
		animal_nodes.append(a)

	_build_gates(s)
	_build_parent_button(s)
	_build_worlds_button()
	_start_life_timers()

## Malo dugme gore levo — nazad na izbor sveta.
func _build_worlds_button() -> void:
	var btn := TapButton.new(Vector2(100, 100), 62, Color(1, 1, 1, 0.85))
	UI.poly(btn, PackedVector2Array([Vector2(14, -26), Vector2(-22, 0), Vector2(14, 26)]), Color(0.45, 0.40, 0.36))
	btn.tapped.connect(func() -> void: go("worlds"))
	add_child(btn)

func _build_scenery(s: Vector2) -> void:
	Scenery.sun(self, Vector2(s.x - 190, 150))
	Scenery.cloud(self, Vector2(s.x * 0.15, 130), 1.1)
	Scenery.cloud(self, Vector2(s.x * 0.52, 100), 0.8)
	Scenery.cloud(self, Vector2(s.x * 0.33, 215), 0.6)
	Scenery.cloud(self, Vector2(s.x * 0.78, 175), 0.9)

	Scenery.farmhouse(self, Vector2(s.x * 0.135, s.y * 0.40))
	Scenery.silo(self, Vector2(s.x * 0.245, s.y * 0.40))
	var pw := Scenery.svg(self, "path", Vector2(s.x * 0.148, s.y * 0.70), 0.6, -32)
	pw.scale.y = 0.75  # razvuci ka dnu kao na mockupu
	Scenery.fence(self, Vector2(s.x * 0.40, s.y * 0.47), 6)
	Scenery.tree(self, Vector2(s.x * 0.93, s.y * 0.42))
	Scenery.pond(self, Vector2(s.x * 0.60, s.y * 0.86))
	Scenery.hay_bales(self, Vector2(s.x * 0.80, s.y * 0.73))

	# žbunje po brdima
	Scenery.bush(self, Vector2(s.x * 0.34, s.y * 0.475))
	Scenery.bush(self, Vector2(s.x * 0.70, s.y * 0.465), 1.3)
	Scenery.bush(self, Vector2(s.x * 0.055, s.y * 0.60), 1.9, -26)  # ispred kuće

	# cveće po travi — fiksna mesta koja zaobilaze baru
	var flower_spots := [
		Vector2(0.08, 0.86), Vector2(0.20, 0.93), Vector2(0.33, 0.82),
		Vector2(0.44, 0.91), Vector2(0.73, 0.92), Vector2(0.86, 0.84), Vector2(0.95, 0.93),
	]
	var flower_colors := [Pal.FLOWER_PINK, Pal.FLOWER_CREAM, Pal.FLOWER_PINK]
	for i in flower_spots.size():
		var p: Vector2 = flower_spots[i] * s + Vector2(randf_range(-25, 25), randf_range(-15, 15))
		Scenery.flower(self, p, flower_colors[i % 3])

## Igre koje se otključavaju kupovinom ("Unlock all games").
const LOCKED_GAMES := ["bath", "hideseek"]

func _build_gates(s: Vector2) -> void:
	var gates := [
		{"screen": "feed", "icon": "apple"},
		{"screen": "shadows", "icon": "shadow"},
		{"screen": "bath", "icon": "bubbles"},
		{"screen": "hideseek", "icon": "hay"},
	]
	# kapije zbijene ka sredini kao na mockupu
	for i in gates.size():
		var g: Dictionary = gates[i]
		var pos := Vector2(s.x * (0.305 + 0.13 * i), 195)
		var btn := TapButton.new(pos, 105, Pal.BUTTON_WHITE)
		_draw_gate_icon(btn, g.icon)
		var target: String = g.screen
		var locked: bool = target in LOCKED_GAMES and not Save.unlocked
		if locked:
			# katančić u uglu kapije
			Scenery.svg(btn, "icon-lock", Vector2(58, 58), 0.55, 5)
			btn.tapped.connect(func() -> void: go("gate"))  # ka roditeljima na otključavanje
		else:
			btn.tapped.connect(func() -> void: go(target))
		add_child(btn)
		btn.start_pulse()

func _draw_gate_icon(parent: Node, icon: String) -> void:
	Scenery.svg(parent, "icon-%s" % icon, Vector2.ZERO, 0.66, 0)

func _build_parent_button(s: Vector2) -> void:
	# diskretno, malo — namerno NIJE privlačno detetu (☰ kao na mockupu)
	var btn := TapButton.new(Vector2(s.x - 80, s.y - 80), 48, Color(0.99, 0.98, 0.96, 0.55))
	for y in [-12, 0, 12]:
		UI.poly(btn, UI.rect_points(34, 6), Color(0.55, 0.5, 0.45), Vector2(0, y))
	btn.tapped.connect(func() -> void: go("gate"))
	add_child(btn)

var idle_timer: Timer

## "Život" na farmi: povremeno se neka životinja sama javi; leptiri preleću.
func _start_life_timers() -> void:
	idle_timer = Timer.new()
	idle_timer.wait_time = 4.5
	idle_timer.timeout.connect(_random_idle)
	add_child(idle_timer)
	idle_timer.start()

	var fly_timer := Timer.new()
	fly_timer.wait_time = 5.5
	fly_timer.timeout.connect(_spawn_butterfly)
	add_child(fly_timer)
	fly_timer.start()
	# na startu sva tri leptira, razmaknuto
	for i in 3:
		var color: Color = Butterfly.COLORS[i]
		get_tree().create_timer(1.0 + i * 1.8).timeout.connect(func() -> void: _spawn_butterfly(color))

## Kad dete tapne životinju: odloži automatsko glasanje da se zvuci ne preklapaju.
func _on_animal_tapped(_animal: Dictionary) -> void:
	idle_timer.start()

func _random_idle() -> void:
	if animal_nodes.is_empty():
		return
	var a: AnimalSprite = animal_nodes[randi() % animal_nodes.size()]
	# ako nešto već svira (dete tapkalo), samo poskoči — bez glasa preko glasa
	if Audio.is_busy() or randf() >= 0.45:
		UI.bounce(a, a.base_scale)
	else:
		a.react()

func _spawn_butterfly(color := Color.TRANSPARENT) -> void:
	if color == Color.TRANSPARENT:
		color = Butterfly.COLORS[randi() % Butterfly.COLORS.size()]
	var s := UI.vs(self)
	var y := randf_range(150, 450)
	var from_left := randf() < 0.5
	var b := Butterfly.new(
		Vector2(-60 if from_left else s.x + 60, y),
		Vector2(s.x + 60 if from_left else -60, y + randf_range(-100, 100)),
		color
	)
	add_child(b)
