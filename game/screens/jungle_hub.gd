extends BaseScreen
## Jungle hub — kupljeni paketi (03.09.2026): gotova pozadina džungle,
## krošnja, debla, lijane; šest životinja celim telom; 4 kapije. Majmun visi na lijani ispod kapija i na
## dodir se ljulja gore-dole; papagaj stoji na oborenom deblu.

## Životinje na tlu: x, y STOPALA, visina kao deo visine ekrana, gleda udesno.
## Po dubini: ko stoji niže na ekranu, bliži je i ide ispred.
const ANIMAL_FRACS := {
	"elephant": [0.165, 0.95, 0.41, true],
	"parrot":   [0.385, 0.87, 0.20, true],
	"lion":     [0.545, 0.93, 0.30, false],
	"hippo":    [0.685, 0.965, 0.34, false],
	"giraffe":  [0.90, 0.93, 0.62, false],
}
## Majmun na lijani: x, y RUKU, visina.
const MONKEY := [0.50, 0.36, 0.29]

var animal_nodes: Array = []
var _open_gates: Array[TapButton] = []
var _hint_turn := 0
var idle_timer: Timer

func _ready() -> void:
	var s := UI.vs(self)
	JungleScene.background(self)   # nebo + smeđa traka tla
	_build_frame(s)
	_build_ground(s)

	# Na uskom ekranu (tablet 4:3) životinje su malo manje, da se ne guraju.
	var shrink: float = clampf((s.x / s.y) / 2.14, 0.84, 1.0)
	for animal in Animals.JUNGLE:
		if animal.id == "monkey":
			continue
		var d: Array = ANIMAL_FRACS[animal.id]
		var a := FarmBody.new(animal, s.y * float(d[2]) * shrink, bool(d[3]))
		a.position = Vector2(s.x * float(d[0]), s.y * float(d[1]))
		a.z_index = int(float(d[1]) * 10.0)
		a.add_shadow()
		a.tapped.connect(_on_animal_tapped)
		add_child(a)
		animal_nodes.append(a)

	# lijana od vrha ekrana do majmunovih ruku, majmun visi ispod
	var mpos := Vector2(s.x * MONKEY[0], s.y * MONKEY[1])
	var vine := JungleScene.place(self, "vine-hang-long", Vector2(MONKEY[0], -0.005), 0.42, true, -3, Vector2(0.5, 0.0))
	var vine_h: float = vine.texture.get_size().y * vine.scale.y
	# lijana je kraća od visine ruku: produži je skaliranjem po visini
	vine.scale.y = vine.scale.y * ((mpos.y + s.y * 0.01) / vine_h)
	var monkey := FarmBody.new(Animals.by_id_jungle("monkey"), s.y * MONKEY[2], false, "monkey-vine")
	monkey.position = mpos
	monkey.z_index = 1
	monkey.tapped.connect(_on_animal_tapped)
	add_child(monkey)
	animal_nodes.append(monkey)

	_build_gates(s)
	_build_worlds_button()
	_build_parent_button(s)
	_start_life_timers()
	add_hint(6.0)


## Tlo: oboreno deblo (papagajeva bina) i žbun u uglovima — ništa više.
## Kamenje, cveće, busenje i lišće su izbačeni: bilo je prenatrpano (04.09.).
func _build_ground(s: Vector2) -> void:
	var _unused := s
	# žbunje sa cvećem duž vrha trake tla, IZA životinja, u prazninama
	# između njih (levo od slona ga slon sakrije)
	JungleScene.place(self, "bush-2", Vector2(0.31, 0.885), 0.15, false, -38)
	JungleScene.place(self, "flower-blue", Vector2(0.285, 0.885), 0.10, true, -36)
	JungleScene.place(self, "flower-red", Vector2(0.345, 0.885), 0.10, true, -36)
	JungleScene.place(self, "ground-leaves", Vector2(0.06, 0.89), 0.11, false, -37)
	JungleScene.place(self, "plant-1", Vector2(0.60, 0.885), 0.08, false, -37)
	JungleScene.place(self, "bush-1", Vector2(0.735, 0.885), 0.13, false, -38)
	JungleScene.place(self, "flower-yellow", Vector2(0.775, 0.885), 0.10, true, -36)
	JungleScene.place(self, "tuft-3", Vector2(0.88, 0.89), 0.07, false, -38)
	JungleScene.place(self, "fallen-trunk", Vector2(0.385, 0.895), 0.18, false, -36)
	# ispred: žbun u uglovima
	JungleScene.place(self, "bush-1", Vector2(0.04, 1.03), 0.14, false, 12)
	JungleScene.place(self, "bush-3", Vector2(0.955, 1.03), 0.13, false, 12, Vector2(0.5, 1.0), true)

## Okvir po promo slici paketa (Ognjen, 04.09.2026): levo grupa drveća sa
## granama i lijanama, totem, gusto žbunje sa cvećem i deblo dole; desno
## jedno deblo. Sve stoji na smeđoj traci tla, iza životinja.
func _build_frame(_s: Vector2) -> void:
	JungleScene.place(self, "canopy-1", Vector2(0.50, -0.01), 1.08, false, -45, Vector2(0.5, 0.0))
	# levo: veliko deblo uz ivicu, dva tanja iza njega, duga grana sa lijanama
	# debla su IZA trake tla (z ispod -56): rastu iz zemlje, korenje se ne vidi,
	# pa slon stoji na zemlji, a ne na korenju
	JungleScene.place(self, "trunk-3", Vector2(0.19, 0.95), 0.78, true, -58)
	JungleScene.place(self, "trunk-4", Vector2(0.29, 0.95), 0.62, true, -59, Vector2(0.5, 1.0), true)
	JungleScene.place(self, "trunk-1", Vector2(0.05, 1.02), 1.15, true, -57)
	JungleScene.place(self, "branch-long", Vector2(0.02, 0.34), 0.26, false, -57, Vector2(0.0, 1.0))
	JungleScene.place(self, "vine-hang", Vector2(0.20, 0.13), 0.30, true, -43, Vector2(0.5, 0.0))
	JungleScene.place(self, "vine-hang-long", Vector2(0.27, 0.10), 0.36, true, -43, Vector2(0.5, 0.0))
	JungleScene.place(self, "flower-purple", Vector2(0.235, 0.36), 0.045, false, -42, Vector2(0.5, 0.0))
	# desno: deblo uz ivicu i totem između nilskog konja i žirafe
	JungleScene.place(self, "trunk-2", Vector2(0.96, 1.02), 1.08, true, -57, Vector2(0.5, 1.0), true)
	JungleScene.place(self, "rock-head", Vector2(0.80, 0.90), 0.36, true, -40)


func _build_worlds_button() -> void:
	var btn := TapButton.new(Vector2(100, 100), 62, Color(1, 1, 1, 0.85))
	UI.poly(btn, PackedVector2Array([Vector2(14, -26), Vector2(-22, 0), Vector2(14, 26)]), Color(0.45, 0.40, 0.36))
	btn.tapped.connect(func() -> void: go("worlds"))
	add_child(btn)

func _build_parent_button(s: Vector2) -> void:
	var btn := TapButton.new(Vector2(s.x - 80, s.y - 80), 48, Color(0.99, 0.98, 0.96, 0.55))
	for y in [-12, 0, 12]:
		UI.poly(btn, UI.rect_points(34, 6), Color(0.55, 0.5, 0.45), Vector2(0, y))
	btn.tapped.connect(func() -> void: go("gate"))
	btn.z_index = 100   # iznad žbunja uz ivicu
	add_child(btn)

## Igre koje se otključavaju kupovinom ("Unlock all games").
const LOCKED_GAMES := ["memory", "quiz"]

func _build_gates(s: Vector2) -> void:
	var gates := [
		{"screen": "memory"},
		{"screen": "quiz"},
		{"screen": "vines"},
		{"screen": "sizes"},
	]
	for i in gates.size():
		var g: Dictionary = gates[i]
		var pos := Vector2(s.x * (0.305 + 0.13 * i), 195)
		var btn := TapButton.new(pos, 105, Pal.BUTTON_WHITE)
		UI.circle(btn, Vector2.ZERO, 105 + 11, Pal.OUTLINE, -2)
		UI.circle(btn, Vector2.ZERO, 105 + 4, Color("#E9DCC4"), -1)
		_gate_icon(btn, g.screen)
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


## Ikone kapija od naših crteža (04.09.2026): dve karte, oblačić sa notom,
## majmun na lijani, veliki i mali žbun. Sve u lokalnim merama dugmeta r=105.
const INK := Color("#2B1A0E")

func _gate_icon(btn: Node2D, screen: String) -> void:
	match screen:
		"memory":
			for i in 2:
				var c := Node2D.new()
				c.position = Vector2(-18 + i * 36, 6 - i * 10)
				c.rotation = -0.18 + i * 0.28
				btn.add_child(c)
				UI.poly(c, UI.rounded_rect_points(84, 108, 16), INK)
				UI.poly(c, UI.rounded_rect_points(74, 98, 13), Color("#B97A34") if i == 0 else Color("#F6E9CC"))
				UI.poly(c, UI.rounded_rect_points(58, 82, 10), Color("#D3964C") if i == 0 else Color("#FFF7E4"))
				if i == 0:
					var leaf := Sprite2D.new()
					leaf.texture = load("res://art/jungle/leaf-1.png")
					leaf.scale = Vector2.ONE * (56.0 / leaf.texture.get_size().y)
					leaf.rotation = -0.35
					c.add_child(leaf)
				else:
					var face := FarmBody.portrait("monkey", 60.0)
					c.add_child(face)
		"quiz":
			var b := Node2D.new()
			b.position = Vector2(0, -8)
			btn.add_child(b)
			UI.poly(b, UI.rounded_rect_points(126, 92, 22), INK)
			UI.poly(b, PackedVector2Array([Vector2(-44, 38), Vector2(-14, 38), Vector2(-40, 68)]), INK)
			UI.poly(b, UI.rounded_rect_points(114, 80, 18), Color("#F6E9CC"))
			UI.poly(b, PackedVector2Array([Vector2(-38, 40), Vector2(-20, 40), Vector2(-36, 58)]), Color("#F6E9CC"))
			var note := Sprite2D.new()
			note.texture = load("res://art/svg/note-float-1.svg")
			note.scale = Vector2.ONE * 0.36
			b.add_child(note)
		"vines":
			var vine := Sprite2D.new()
			vine.texture = load("res://art/jungle/vine-hang.png")
			var vh := vine.texture.get_size()
			vine.scale = Vector2(36.0 / vh.x, 92.0 / vh.y)
			vine.position = Vector2(2, -60)
			btn.add_child(vine)
			var m := Sprite2D.new()
			m.texture = load("res://art/jungle/monkey-vine-idle-1.png")
			m.scale = Vector2.ONE * (118.0 / m.texture.get_size().y)
			m.position = Vector2(0, 30)
			btn.add_child(m)
		"sizes":
			var big := Sprite2D.new()
			big.texture = load("res://art/jungle/bush-2.png")
			big.scale = Vector2.ONE * (116.0 / big.texture.get_size().x)
			big.position = Vector2(-22, 28)
			btn.add_child(big)
			var small := Sprite2D.new()
			small.texture = load("res://art/jungle/bush-2.png")
			small.scale = Vector2.ONE * (58.0 / small.texture.get_size().x)
			small.position = Vector2(52, 44)
			btn.add_child(small)
			var e := FarmBody.portrait("elephant", 78.0)
			e.position = Vector2(-24, -34)
			btn.add_child(e)
			var pr := FarmBody.portrait("parrot", 40.0)
			pr.position = Vector2(54, 6)
			btn.add_child(pr)


## PRVI pokazivač na hubu je uvek KAPIJA — dete pre svega treba da nađe put
## do igre, i to važi pri svakom dolasku na hub, ne samo prvi put.
## Tek od drugog pokazivača, i tek kad se vrati iz neke igre, pokazuje se i
## na životinje — tada već zna gde su igre, pa je red da otkrije da i majmun
## reaguje na dodir.
## U listi meta su SAMO otključane kapije — na katanac se ne pokazuje nikad.
func hint_spot() -> Dictionary:
	_hint_turn += 1
	var main: Node = get_tree().get_first_node_in_group("main")
	if main.played_game and _hint_turn % 2 == 0 and not animal_nodes.is_empty():
		var a: FarmBody = animal_nodes[randi() % animal_nodes.size()]
		# prst na SREDINU tela, ne na stopala (ili ruke kod majmuna)
		var mid: Vector2 = a.position + Vector2(0, (a.body_size().y * 0.5) if a.hangs else -a.body_size().y * 0.5)
		return {"at": mid, "size": 1.9}
	if _open_gates.is_empty():
		return {}
	return {"at": _open_gates[randi() % _open_gates.size()].position, "size": 2.0}


## "Život": povremeno se neka životinja sama javi.
func _start_life_timers() -> void:
	idle_timer = Timer.new()
	idle_timer.wait_time = 4.5
	idle_timer.timeout.connect(_random_idle)
	add_child(idle_timer)
	idle_timer.start()

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
