extends BaseScreen
## Hub — dvorište farme po Claude Design mockupu: slojevita brda, kuća + silos,
## ograda, drvo, bara, bale sena, cveće; 6 životinja + 4 kapije mini-igara.

## Životinje celim telom (kupljeni paketi): x, y STOPALA, visina kao deo
## visine ekrana, i da li gleda udesno (crteži gledaju ulevo). Raspored je
## po dubini: veće napred, manje pozadi, niko ne stoji ispred kapija.
const ANIMAL_FRACS := {
	"cow":     [0.19, 0.90, 0.45, true],
	"horse":   [0.42, 0.82, 0.48, false],
	"pig":     [0.60, 0.94, 0.30, true],
	"goat":    [0.75, 0.84, 0.36, false],
	"chicken": [0.87, 0.94, 0.28, false],
	"duck":    [0.955, 0.86, 0.25, false],
}

var animal_nodes: Array = []
var _fan: Sprite2D
var _open_gates: Array[TapButton] = []
var _hint_turn := 0

func _ready() -> void:
	var s := UI.vs(self)
	_build_background(s)
	_build_scenery(s)

	# Na uskom ekranu (iPad 4:3) visina je ista, a širina manja — životinje
	# merene po visini ispadnu ogromne, pa se smanje srazmerno odnosu strana.
	var shrink: float = clampf((s.x / s.y) / 2.14, 0.62, 1.0)
	for animal in Animals.LIST:
		var d: Array = ANIMAL_FRACS[animal.id]
		var a := FarmBody.new(animal, s.y * float(d[2]) * shrink, bool(d[3]))
		a.position = Vector2(s.x * float(d[0]), s.y * float(d[1]))
		# Dublje = manji z: ko stoji niže na ekranu, bliži je i ide ispred.
		a.z_index = int(float(d[1]) * 10.0)
		a.tapped.connect(_on_animal_tapped)
		add_child(a)
		animal_nodes.append(a)
	set_process(true)

	_build_gates(s)
	_build_parent_button(s)
	_build_worlds_button()
	_start_life_timers()
	add_hint(6.0)

## Malo dugme gore levo — nazad na izbor sveta.
func _build_worlds_button() -> void:
	var btn := TapButton.new(Vector2(100, 100), 62, Color(1, 1, 1, 0.85))
	UI.poly(btn, PackedVector2Array([Vector2(14, -26), Vector2(-22, 0), Vector2(14, 26)]), Color(0.45, 0.40, 0.36))
	btn.tapped.connect(func() -> void: go("worlds"))
	add_child(btn)

## Pozadina iz kupljenog paketa (Mega farm kit): gotova pozadina sa nebom,
## brdima, njivama i putem, uklopljena po visini i centrirana.
func _build_background(s: Vector2) -> void:
	var bg := Sprite2D.new()
	bg.texture = load("res://art/farm/bg-road.png")
	var bt := bg.texture.get_size()
	var sc: float = maxf(s.y / bt.y, s.x / bt.x)
	bg.scale = Vector2(sc, sc)
	bg.position = s / 2.0
	bg.z_index = -60
	add_child(bg)
	Scenery.cloud(self, Vector2(s.x * 0.15, 130), 1.1)
	Scenery.cloud(self, Vector2(s.x * 0.78, 110), 0.9)


func _prop(art: String, frac_w: float, cx: float, base_y: float, z: int) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/farm/%s.png" % art)
	var tex := sp.texture.get_size()
	var s := UI.vs(self)
	sp.scale = Vector2.ONE * ((s.x * frac_w) / tex.x)
	sp.offset = Vector2(0, -tex.y / 2.0)
	sp.position = Vector2(s.x * cx, s.y * base_y)
	sp.z_index = z
	add_child(sp)
	return sp


## Rekviziti iz paketa, od najdaljeg ka najbližem. Sve što je "na tlu" ima
## oslonac na dnu crteža. Traka za životinje je između ograde (pozadi) i
## cveća uz donju ivicu (napred).
func _build_scenery(s: Vector2) -> void:
	# Daleko: drveće po brdima, štala sa silosom i vetrenjačom desno, kokošinjac levo.
	_prop("tree-4", 0.15, 0.03, 0.60, -40)
	_prop("tree-3", 0.11, 0.33, 0.56, -42)
	_prop("tree-1", 0.14, 0.56, 0.58, -41)
	_prop("tree-2", 0.10, 0.99, 0.60, -40)
	_prop("coop", 0.19, 0.13, 0.66, -36)
	_prop("silo", 0.065, 0.735, 0.62, -37)
	_prop("barn", 0.20, 0.84, 0.63, -36)
	_prop("windmill", 0.055, 0.945, 0.60, -38)
	_fan = _prop("windmill-fan", 0.075, 0.945, 0.60, -37)
	# Krila se vrte oko svog centra: crtež je kvadrat sa osovinom u sredini.
	_fan.offset = Vector2.ZERO
	var fan_h: float = _fan.texture.get_size().y * _fan.scale.y
	var mill_h: float = load("res://art/farm/windmill.png").get_size().y * ((s.x * 0.055) / 206.0)
	_fan.position = Vector2(s.x * 0.945, s.y * 0.60 - mill_h + fan_h * 0.32)
	_prop("track", 0.16, 0.80, 0.70, -39)
	# Srednji plan: njive i bilje uz ogradu.
	_prop("haypile", 0.16, 0.30, 0.69, -34)
	_prop("sunflowers", 0.10, 0.47, 0.70, -33)
	_prop("corn-group", 0.15, 0.64, 0.71, -33)
	_prop("carrots", 0.09, 0.22, 0.73, -32)
	_prop("lettuce-patch", 0.10, 0.40, 0.735, -32)
	_prop("orange-tree", 0.07, 0.905, 0.72, -33)
	_prop("scarecrow", 0.08, 0.53, 0.73, -31)
	# Ograda iza životinja, preko cele širine, sa otvorenom kapijom u sredini.
	for i in 7:
		var x: float = 0.02 + 0.137 * i
		if i == 3:
			_prop("gate-open", 0.07, x + 0.05, 0.775, -30)
			continue
		_prop("fence", 0.14, x + 0.07, 0.775, -30)
	# Prednji plan: žbunje i cveće uz donju ivicu, ispred životinja.
	_prop("bush-1", 0.13, 0.06, 1.01, 12)
	_prop("bush-3", 0.09, 0.50, 1.01, 12)
	_prop("bush-2", 0.12, 0.93, 1.02, 12)
	for tx in [0.10, 0.33, 0.57, 0.74, 0.90]:
		_prop("tuft", 0.05, tx, 1.005, 11)


func _process(delta: float) -> void:
	if _fan:
		_fan.rotation += delta * 0.6

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
		UI.circle(btn, Vector2.ZERO, 105 + 11, Pal.OUTLINE, -2)
		UI.circle(btn, Vector2.ZERO, 105 + 4, Color("#E9DCC4"), -1)
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
		if not locked:
			_open_gates.append(btn)


## PRVI pokazivač na hubu je uvek KAPIJA — dete pre svega treba da nađe put
## do igre, i to važi pri svakom dolasku na hub, ne samo prvi put.
## Tek od drugog pokazivača, i tek kad se vrati iz neke igre, pokazuje se i
## na životinje — tada već zna gde su igre, pa je red da otkrije da i krava
## reaguje na dodir.
## U listi meta su SAMO otključane kapije — na katanac se ne pokazuje nikad.
func hint_spot() -> Dictionary:
	_hint_turn += 1
	var main: Node = get_tree().get_first_node_in_group("main")
	if main.played_game and _hint_turn % 2 == 0 and not animal_nodes.is_empty():
		return {"at": animal_nodes[randi() % animal_nodes.size()].position, "size": 1.9}
	if _open_gates.is_empty():
		return {}
	return {"at": _open_gates[randi() % _open_gates.size()].position, "size": 2.0}

## Ikone kapija od kupljenih crteža (04.09.2026): jabuka, senka krave,
## prase sa mehurićima, kokoška iza plasta sena.
func _draw_gate_icon(parent: Node, icon: String) -> void:
	match icon:
		"apple":
			_png(parent, "res://art/food/apple.png", 150.0, Vector2(0, 4))
		"shadow":
			_png(parent, "res://art/farm/cow-sil.png", 140.0, Vector2(0, 8))
		"bubbles":
			# kada iz kupatila, prase u njoj, pena
			_png(parent, "res://art/bath/tub.png", 160.0, Vector2(0, 30))
			var pig := FarmBody.portrait("pig", 84.0)
			pig.position = Vector2(-4, -8)
			parent.add_child(pig)
			_png(parent, "res://art/bath/tub-front.png", 160.0, Vector2(0, 30))
			_png(parent, "res://art/bath/foam-1.png", 60.0, Vector2(-40, -2))
			_png(parent, "res://art/bath/foam-2.png", 50.0, Vector2(44, -6))
		"hay":
			var hen := FarmBody.portrait("chicken", 90.0)
			hen.position = Vector2(30, -34)
			parent.add_child(hen)
			_png(parent, "res://art/farm/haypile.png", 160.0, Vector2(0, 30))

func _png(parent: Node, path: String, width: float, pos: Vector2) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = load(path)
	sp.scale = Vector2.ONE * (width / sp.texture.get_size().x)
	sp.position = pos
	parent.add_child(sp)
	return sp

func _build_parent_button(s: Vector2) -> void:
	# diskretno, malo — namerno NIJE privlačno detetu (☰ kao na mockupu)
	var btn := TapButton.new(Vector2(s.x - 80, s.y - 80), 48, Color(0.99, 0.98, 0.96, 0.55))
	for y in [-12, 0, 12]:
		UI.poly(btn, UI.rect_points(34, 6), Color(0.55, 0.5, 0.45), Vector2(0, y))
	btn.tapped.connect(func() -> void: go("gate"))
	btn.z_index = 100   # iznad žbunja i rekvizita uz ivicu
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
	for i in 2:
		var color: String = FarmButterfly.COLORS[i]
		get_tree().create_timer(1.0 + i * 1.8).timeout.connect(func() -> void: _spawn_butterfly(color))

## Kad dete tapne životinju: odloži automatsko glasanje da se zvuci ne preklapaju.
func _on_animal_tapped(_animal: Dictionary) -> void:
	idle_timer.start()

func _random_idle() -> void:
	if animal_nodes.is_empty():
		return
	var a: FarmBody = animal_nodes[randi() % animal_nodes.size()]
	# ako nešto već svira (dete tapkalo), samo tačka bez glasa
	if Audio.is_busy() or randf() >= 0.45:
		a.play_react()
	else:
		a.react()

func _spawn_butterfly(color := "") -> void:
	# Najviše dva leptira odjednom — četiri su odvlačila pažnju sa životinja.
	var alive := 0
	for c in get_children():
		if c is FarmButterfly:
			alive += 1
	if alive >= 2:
		return
	if color == "":
		color = FarmButterfly.COLORS[randi() % FarmButterfly.COLORS.size()]
	var s := UI.vs(self)
	var y := randf_range(150, 450)
	var from_left := randf() < 0.5
	var b := FarmButterfly.new(
		Vector2(-60 if from_left else s.x + 60, y),
		Vector2(s.x + 60 if from_left else -60, y + randf_range(-100, 100)),
		color
	)
	add_child(b)
