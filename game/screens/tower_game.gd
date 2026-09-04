extends BaseScreen
## Dino igra 4: KULA DO LIŠĆA — prevlačenje.
##
## Levo je gomila kamenih ploča, desno drvo sa krošnjom do koje mali bronto ne
## dohvata. Dete prevuče ploču pod bronta: ploča legne na kulu, bronto skoči
## na nju. Posle pet ploča dohvati lišće, pojede ga i slavi; onda se kula
## sama raspadne nazad u gomilu i kreće ispočetka.
##
## Bez fizike i bez rušenja (odluka 03.09.2026): gest je isti kao u ostalim
## igrama — prevuci na pravo mesto — a napredak je vidljiv na svakom potezu
## (bronto je svaki put viši). Pogrešno mesto nije greška: ploča se samo
## vrati u gomilu.

const GROUND_Y := 0.90
const TOWER_X := 0.70
const SLAB_H := 0.052          # visina jedne ploče u kuli (deo visine ekrana)
const NEED := 5                # koliko ploča do lišća
const PILE_N := 6
## Biljojedi koji se smenjuju: svaki dođe, pojede, naraste i ode; T-Rex ne
## jede lišće pa ga nema. Visina je u odnosu na bronta (isti odnos kao na
## kamenju).
## Isti crteži kao šetači na hubu (hod + stajanje); crtež gleda ulevo pa se
## ogleda. `ax` je tačka ispod stopala u širini okvira (bronto ima širi okvir).
const SPECIES := [
	{"walk": "bw", "wn": 16, "idle": "bi", "in": 20, "jump": "lb-jump", "jn": 12, "h": 0.30, "fps": 12.0, "ax": 0.664},
	{"walk": "sw", "wn": 16, "idle": "si", "in": 20, "jump": "ls-jump", "jn": 12, "h": 0.24, "fps": 13.0, "ax": 0.5},
	{"walk": "cw", "wn": 12, "idle": "ci", "in": 20, "jump": "lc-jump", "jn": 12, "h": 0.23, "fps": 14.0, "ax": 0.516},
]

var _pile: Array = []          # {node, home, used}
var _stack: Array = []         # ploče u kuli, odozdo
var _drag: Dictionary = {}
var _bronto: Sprite2D
var _frames: Array = []
var _walk_frames: Array = []
var _jump_frames: Array = []
var _walking := false
var _jumping := false
var _grown := 1.0              # 1.38 posle jela
var _walk_offset := Vector2.ZERO
var _dust: Array = []          # {node, age, vel}
var _dust_t := 0.0
var _fps := 12.0
var _f := 0.0
var _busy := false
var _bronto_scale := 1.0       # osnovna skala crteža trenutne vrste
var _species := 0
var _smoke: Array = []
var _sway: Array = []          # {node, amp, period, phase}
var _t := 0.0
var _ptero: Sprite2D
var _ptero_frames: Array = []
var _ptero_u := 1.0            # napredak preleta, 1 = završen
var _ptero_wait := 4.0
var _ptero_f := 0.0


func _ready() -> void:
	home_target = "dino"
	var s := UI.vs(self)
	var bg := Sprite2D.new()
	bg.texture = load("res://art/dino/bg-scene.png")
	var bt := bg.texture.get_size()
	bg.position = s / 2.0
	bg.scale = Vector2(s.x / bt.x, s.y / bt.y)
	bg.z_index = -50
	add_child(bg)
	# Dim iz oba vulkana u pozadini, kao na jajima i kamenju.
	_build_smoke(s, 0.100, 0.335, 0.085)
	_build_smoke(s, 0.525, 0.365, 0.070)
	_build_scenery(s)
	_build_ptero(s)
	_build_tree(s)
	_build_bronto(s)
	_build_pile(s)
	add_home_button()
	add_hint(5.0)
	set_process(true)


func _build_tree(s: Vector2) -> void:
	# Drvo iz kupljenog paketa (jungle-tree-2), uvećano 1.7× visine ekrana:
	# stablo se vidi uz desnu ivicu, grana ide preko vrha, a krošnja visi
	# "sa plafona" — vidi se samo lišće odozgo. Ogledalo, da grana ide ulevo.
	var tree := Sprite2D.new()
	tree.texture = load("res://art/dino/tree-tall.png")
	var tt := tree.texture.get_size()
	var sc: float = (s.y * 1.7) / tt.y
	tree.scale = Vector2(sc, sc)
	tree.flip_h = true
	tree.offset = Vector2(0, -tt.y / 2.0)
	# Spušteno ispod donje ivice: koren se ne vidi, a fronde grane vise
	# dovoljno nisko da ih bronto sa kule dohvati.
	tree.position = Vector2(s.x * 0.86, s.y * 1.22)
	tree.z_index = 1
	add_child(tree)

	_add_sway(tree, 0.6, 7.0)


## Scena kao na hubu: palma levo, kosti i busenje po pesku, paprati u
## prednjem planu uz donju ivicu (tamne, jer su najbliže oku).
func _build_scenery(s: Vector2) -> void:
	# Dve palme levo, velike: zadnja tamnija i niža, prednja viša.
	var palm_back := _plant("palm2", 0.0, 0.19, 0.895, -1, 0.66)
	palm_back.modulate = Color(0.70, 0.68, 0.68)
	_add_sway(palm_back, 1.0, 7.0)
	var palm := _plant("palm1", 0.0, 0.07, 0.905, 0, 0.80)
	palm.modulate = Color(0.84, 0.82, 0.80)
	_add_sway(palm, 1.2, 6.5)
	for pr in [{"a": "p-bones", "w": 0.120, "x": 0.560, "y": 0.905},
			{"a": "p-tuft", "w": 0.065, "x": 0.490, "y": 0.900},
			{"a": "p-stone2", "w": 0.050, "x": 0.640, "y": 0.895},
			{"a": "p-plant2", "w": 0.024, "x": 0.600, "y": 0.895}]:
		_plant(String(pr.a), float(pr.w), float(pr.x), float(pr.y), 3)
	for b in [{"art": "fern3", "w": 0.20, "x": 0.02, "y": 1.20, "dim": 0.30},
			{"art": "fern1", "w": 0.17, "x": 0.41, "y": 1.24, "dim": 0.27},
			{"art": "fern2", "w": 0.19, "x": 0.86, "y": 1.22, "dim": 0.28},
			{"art": "fern3", "w": 0.16, "x": 0.98, "y": 1.20, "dim": 0.25}]:
		var node := _plant(String(b.art), float(b.w), float(b.x), float(b.y), 12)
		var d: float = float(b.dim)
		node.modulate = Color(d, d + 0.04, d + 0.02)
		_add_sway(node, randf_range(1.8, 2.6), randf_range(4.4, 6.6))


func _plant(art: String, frac_w: float, cx: float, base_y: float, z: int, frac_h := 0.0) -> Sprite2D:
	var s := UI.vs(self)
	var sp := Sprite2D.new()
	sp.texture = load("res://art/dino/%s.png" % art)
	var tex := sp.texture.get_size()
	sp.scale = Vector2.ONE * ((s.y * frac_h) / tex.y if frac_h > 0.0 else (s.x * frac_w) / tex.x)
	sp.offset = Vector2(0, -tex.y / 2.0)
	sp.position = Vector2(s.x * cx, s.y * base_y)
	sp.z_index = z
	add_child(sp)
	return sp


## Pterodaktil daleko u pozadini: mali, iza dima, preleti zdesna nalevo
## pa čeka. Isti crteži kao na hubu, samo bez tapa.
func _build_ptero(s: Vector2) -> void:
	for i in 12:
		_ptero_frames.append(load("res://art/dino/pf-%d.png" % (i + 1)))
	_ptero = Sprite2D.new()
	_ptero.texture = _ptero_frames[0]
	_ptero.scale = Vector2.ONE * ((s.y * 0.07) / _ptero.texture.get_size().y)
	_ptero.modulate = Color(0.75, 0.72, 0.80)   # izmaglica daljine
	_ptero.z_index = -47
	_ptero.visible = false
	add_child(_ptero)


func _process_ptero(delta: float, s: Vector2) -> void:
	if _ptero_u >= 1.0:
		_ptero_wait -= delta
		if _ptero_wait <= 0.0:
			_ptero_u = 0.0
			_ptero.visible = true
		return
	_ptero_u += delta / 16.0
	_ptero_f += delta * 12.0
	_ptero.texture = _ptero_frames[int(_ptero_f) % _ptero_frames.size()]
	var u := _ptero_u
	_ptero.position = Vector2(lerpf(s.x * 1.08, -s.x * 0.08, u), s.y * 0.20 + sin(u * PI) * s.y * 0.05)
	if _ptero_u >= 1.0:
		_ptero.visible = false
		_ptero_wait = randf_range(6.0, 12.0)


func _add_sway(node: Node2D, amp_deg: float, period: float) -> void:
	_sway.append({"node": node, "amp": deg_to_rad(amp_deg), "period": period, "phase": randf() * TAU})


func _build_smoke(s: Vector2, cx: float, cy: float, frac_w: float) -> void:
	for i in 3:
		var sm := Sprite2D.new()
		sm.texture = load("res://art/eggs/smoke%d.png" % (1 + i % 2))
		var st := sm.texture.get_size()
		sm.scale = Vector2.ONE * ((s.x * frac_w) / st.x)
		sm.offset = Vector2(0, -st.y / 2.0)
		sm.z_index = -46
		add_child(sm)
		_smoke.append({"node": sm, "x": s.x * cx, "y0": s.y * cy, "u": float(i) / 3.0, "w": frac_w})


func _process_smoke(delta: float, s: Vector2) -> void:
	for sm in _smoke:
		sm.u += delta * 0.085
		if sm.u >= 1.0:
			sm.u -= 1.0
		var u: float = sm.u
		var node: Sprite2D = sm.node
		node.position = Vector2(sm.x + sin(u * 3.1) * s.x * 0.012, sm.y0 - u * s.y * 0.26)
		node.scale = Vector2.ONE * (((s.x * float(sm.w)) / node.texture.get_size().x) * (0.6 + u * 0.9))
		node.modulate.a = clampf(u * 4.0, 0.0, 1.0) * (1.0 - u) * 0.85


func _build_bronto(s: Vector2) -> void:
	_bronto = Sprite2D.new()
	_bronto.z_index = 6
	add_child(_bronto)
	_load_species(s)
	_bronto.position = _top(s)


func _load_species(s: Vector2) -> void:
	var sp: Dictionary = SPECIES[_species]
	_frames.clear()
	_walk_frames.clear()
	for i in int(sp["in"]):
		_frames.append(load("res://art/dino/%s-%d.png" % [sp.idle, i + 1]))
	for i in int(sp.wn):
		_walk_frames.append(load("res://art/dino/%s-%d.png" % [sp.walk, i + 1]))
	_jump_frames.clear()
	for i in int(sp.jn):
		_jump_frames.append(load("res://art/lava/%s-%d.png" % [sp.jump, i + 1]))
	_fps = float(sp.fps) * 0.8
	_grown = 1.0
	_bronto.texture = _frames[0]
	var ft: Vector2 = _walk_frames[0].get_size()
	_bronto_scale = (s.y * float(sp.h)) / ft.y
	_bronto.scale = Vector2(-_bronto_scale, _bronto_scale)   # ogledalo: gleda ka drvetu
	_walk_offset = Vector2((0.5 - float(sp.ax)) * ft.x, -ft.y / 2.0)
	_bronto.offset = _walk_offset


## Skok koristi crteže sa lave (isti stil, drugi okvir): za vreme skoka se
## menjaju skala i pomak da stopala ostanu na položaju čvora, pa se vrate.
func _set_jumping(on: bool, s: Vector2) -> void:
	_jumping = on
	var sp: Dictionary = SPECIES[_species]
	if on:
		var jt: Vector2 = _jump_frames[0].get_size()
		var sc: float = (s.y * float(sp.h) * 1.05) / jt.y * _grown
		_bronto.scale = Vector2(-sc, sc)
		_bronto.offset = Vector2(0, -jt.y / 2.0)
		_f = 0.0
	else:
		_bronto.scale = Vector2(-_bronto_scale, _bronto_scale) * _grown
		_bronto.offset = _walk_offset


## Hod do zadatog x: sličice hoda dok traje, pa stajanje.
func _walk_to(tw: Tween, x: float, s: Vector2, duration: float) -> void:
	tw.tween_callback(func() -> void: _walking = true)
	tw.tween_property(_bronto, "position", Vector2(x, s.y * GROUND_Y), duration)
	tw.tween_callback(func() -> void: _walking = false)


func _build_pile(s: Vector2) -> void:
	# Gomila levo: nisko, jedan red po pesku i samo jedan kamen odozgo — visoka
	# gomila je stizala do pola palme i izgledala kao zid.
	var spots := [[0.10, 0.0], [0.19, 0.0], [0.28, 0.0], [0.37, 0.0], [0.15, 0.05], [0.24, 0.05]]
	# Nepomično kamenje oko korena OBE palme: sakriva mesto gde stablo ulazi
	# u pesak. Nije deo gomile za vučenje. Zadnja palma je na z -1, pa njeno
	# kamenje ide na 0; prednja je na 0, njeno na 3.
	# GOMILA, ne put: nepomično kamenje složeno u brdo oko x 0.25 (četiri
	# reda, sve uže ka vrhu). Dinosaurus koji ulazi prolazi iza nje, a ploče
	# za vučenje leže po njenoj prednjoj strani.
	for r in [[3, 0.02, 0.935, 0.06, true], [1, 0.035, 0.92, 0.075, false],
			[2, 0.10, 0.925, 0.085, false], [1, 0.17, 0.93, 0.085, true], [4, 0.24, 0.925, 0.09, false],
			[3, 0.31, 0.93, 0.085, true], [2, 0.38, 0.925, 0.085, false], [1, 0.435, 0.93, 0.07, true],
			[4, 0.135, 0.875, 0.08, true], [2, 0.21, 0.87, 0.085, false], [1, 0.285, 0.875, 0.08, true], [3, 0.355, 0.87, 0.08, false],
			[2, 0.175, 0.825, 0.075, false], [4, 0.25, 0.82, 0.08, true], [1, 0.32, 0.825, 0.075, false],
			[3, 0.215, 0.775, 0.07, true], [2, 0.29, 0.775, 0.07, false]]:
		var st := Sprite2D.new()
		st.texture = load("res://art/wall/rock%d.png" % int(r[0]))
		var tt := st.texture.get_size()
		st.scale = Vector2.ONE * ((s.x * float(r[3])) / tt.x)
		st.offset = Vector2(0, -tt.y / 2.0)
		st.flip_h = bool(r[4])
		st.position = Vector2(s.x * float(r[1]), s.y * float(r[2]))
		st.z_index = 3
		add_child(st)
	for i in PILE_N:
		var sp := Sprite2D.new()
		# Isto kamenje kao u igri sa gomilom (rock4 pljosnat, rock2 oblutak).
		sp.texture = load("res://art/wall/rock%d.png" % (4 if i % 3 != 2 else 2))
		_size_slab(sp, s)
		sp.flip_h = i % 2 == 0
		var home := Vector2(s.x * float(spots[i][0]), s.y * (GROUND_Y - float(spots[i][1])))
		sp.position = home
		sp.rotation = randf_range(-0.06, 0.06)
		sp.z_index = 4 + i
		add_child(sp)
		_pile.append({"node": sp, "home": home, "used": false})


func _size_slab(sp: Sprite2D, s: Vector2) -> void:
	var t := sp.texture.get_size()
	sp.scale = Vector2.ONE * ((s.x * 0.09) / t.x)
	sp.offset = Vector2(0, -t.y / 2.0)


## Koliko jedan kamen digne kulu: nešto manje od visine crteža, jer se gornja
## ivica (perspektiva) preklapa sa sledećim kamenom.
func _slab_lift(sp: Sprite2D) -> float:
	return sp.texture.get_size().y * sp.scale.y * 0.72


## Vrh kule (tu bronto stoji).
func _top(s: Vector2) -> Vector2:
	var y: float = s.y * GROUND_Y
	for n in _stack:
		y -= _slab_lift(n)
	return Vector2(s.x * TOWER_X, y)


func _input(event: InputEvent) -> void:
	if _busy:
		return
	var s := UI.vs(self)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _drag.is_empty():
			var best: Dictionary = {}
			# Tap bilo gde po gomili hvata najbliži slobodan kamen: dete ne zna
			# koji je "sledeći", pa bi inače vuklo prazno.
			var on_heap: bool = event.position.x < s.x * 0.50 and event.position.y > s.y * 0.70
			var bd: float = s.x * (0.6 if on_heap else 0.10)
			for p in _pile:
				if p.used:
					continue
				var d: float = event.position.distance_to(p.node.position + Vector2(0, -s.y * SLAB_H * 0.5))
				if d < bd:
					bd = d
					best = p
			if not best.is_empty():
				_drag = best
				best.node.z_index = 20
				best.node.rotation = 0.0
				Audio.play("pluck")
		elif not event.pressed and not _drag.is_empty():
			_drop(s)
	elif event is InputEventMouseMotion and not _drag.is_empty():
		_drag.node.position = event.position + Vector2(0, s.y * 0.07)


func _drop(s: Vector2) -> void:
	var p: Dictionary = _drag
	_drag = {}
	var n: Sprite2D = p.node
	var target := _top(s)
	if n.position.distance_to(target) > s.x * 0.16:
		# Nije kod kule: ploča se vrati u gomilu, bez zvuka greške.
		n.z_index = 4 + _pile.find(p)
		var tw := create_tween()
		tw.tween_property(n, "position", p.home, 0.3).set_trans(Tween.TRANS_BACK)
		return
	p.used = true
	_busy = true
	n.z_index = 4 + _stack.size()
	n.rotation = 0.0
	_stack.append(n)
	var land := target + Vector2(s.x * randf_range(-0.008, 0.008), 0)
	var tw2 := create_tween()
	tw2.tween_property(n, "position", land, 0.14).set_trans(Tween.TRANS_SINE)
	tw2.tween_callback(func() -> void:
		Audio.play("rock_hit", -4.0, randf_range(0.9, 1.1))
		UI.haptic(30)
		_hop(s)
	)


## Bronto skoči na novu ploču: gore pa dole sa odskokom.
func _hop(s: Vector2) -> void:
	var top := _top(s)
	var tw := create_tween()
	tw.tween_property(_bronto, "position", top + Vector2(0, -s.y * 0.08), 0.22).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.tween_property(_bronto, "position", top, 0.2).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		Audio.play("tap", -8.0)
		if _stack.size() >= NEED:
			_eat(s)
		else:
			_busy = false
	)


## Dohvatio fronde: zagrize, lišće se prospe, slavi, pa se kula vrati u gomilu.
func _eat(s: Vector2) -> void:
	Audio.play("nom")
	var h: float = float(SPECIES[_species].h)
	var bite := _bronto.position + Vector2(s.x * 0.04, -s.y * h * 0.95)
	for i in 6:
		_leaf_bit(s, bite, i)
	var tw := create_tween()
	tw.tween_interval(0.4)
	tw.tween_callback(func() -> void:
		UI.haptic(40)
		Audio.play(["yay", "giggle", "kid"][randi() % 3], -2.0)
		_glow(_bronto.position + Vector2(0, -s.y * h * 0.5), s.y * h * 1.3)
		# Od jela se raste: sit dinosaurus je za trećinu veći.
		var tg := create_tween()
		_grown = 1.38
		tg.tween_property(_bronto, "scale", Vector2(-_bronto_scale, _bronto_scale) * _grown, 0.6).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	)
	tw.tween_interval(1.6)
	tw.tween_callback(func() -> void: _reset(s))


## Otkinut listić: padne uz vrtenje i nestane.
func _leaf_bit(s: Vector2, from: Vector2, i: int) -> void:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/svg/big-leaf.svg")
	sp.scale = Vector2.ONE * ((s.x * randf_range(0.025, 0.04)) / sp.texture.get_size().x)
	sp.position = from
	sp.rotation = randf() * TAU
	sp.z_index = 8
	add_child(sp)
	var to := from + Vector2(s.x * randf_range(-0.09, 0.09), s.y * randf_range(0.25, 0.4))
	var tw := create_tween()
	tw.tween_interval(0.05 * i)
	tw.set_parallel(true)
	tw.tween_property(sp, "position", to, randf_range(0.9, 1.3)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	tw.tween_property(sp, "rotation", sp.rotation + randf_range(-3.0, 3.0), 1.2)
	tw.tween_property(sp, "modulate:a", 0.0, 0.5).set_delay(0.7)
	tw.chain().tween_callback(sp.queue_free)


func _reset(s: Vector2) -> void:
	# Sit dinosaurus SKOČI sa kule na pesak pored nje (a ne da propadne pre
	# kamenja), tek onda se kamenje jedno po jedno vrati u gomilu dok on
	# odlazi udesno iza debla. Sledeći ušeta s leva, ispred svega kao na hubu
	# (iza kamenja su mu virile noge, kao da lebdi).
	var start := _bronto.position
	var land := Vector2(s.x * (TOWER_X + 0.13), s.y * GROUND_Y)
	var tw := create_tween()
	tw.tween_callback(func() -> void: _set_jumping(true, s))
	tw.tween_method(func(u: float) -> void:
		_bronto.position = start.lerp(land, u) + Vector2(0, -sin(u * PI) * s.y * 0.10)
	, 0.0, 1.0, 0.7).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void:
		_set_jumping(false, s)
		Audio.play("tap", -8.0)
		UI.haptic(25)
		_puff(land, s.x * 0.16)
		_bronto.z_index = 0        # dalje ide iza debla
	)
	for i in range(_stack.size() - 1, -1, -1):
		var n: Sprite2D = _stack[i]
		for p in _pile:
			if p.node == n:
				p.used = false
				tw.parallel().tween_property(n, "position", p.home, 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN_OUT).set_delay(0.15 * (_stack.size() - i))
	_walk_to(tw, s.x * 1.25, s, 3.0)
	# Sledeći ušeta s leva IZA zida kamenja (z 2, kamenje na 3+), a čim ga
	# prođe, pređe ispred (z 6) i stane kod kule.
	tw.tween_callback(func() -> void:
		_species = (_species + 1) % SPECIES.size()
		_load_species(s)
		_bronto.z_index = 2
		_bronto.position = Vector2(-s.x * 0.2, s.y * GROUND_Y)
	)
	_walk_to(tw, s.x * 0.56, s, 4.2)
	tw.tween_callback(func() -> void: _bronto.z_index = 6)
	_walk_to(tw, land.x - s.x * 0.13, s, 0.8)
	tw.tween_callback(func() -> void:
		_stack.clear()
		_busy = false
	)


## Prašina pod nogama dok hoda po pesku (kao na hubu): zrnca se dignu i
## zaostanu za životinjom.
func _kick_dust(s: Vector2) -> void:
	var base := _bronto.position + Vector2(0, -s.y * 0.004)
	for i in 3:
		var node := UI.circle(self, base + Vector2(randf_range(-8.0, 8.0), 0.0),
			s.x * randf_range(0.004, 0.007), Color("#C99A70"), _bronto.z_index - 1)
		_dust.append({"node": node, "age": 0.0,
			"vel": Vector2(randf_range(-0.9, -0.2) * s.x * 0.03, -randf_range(0.2, 0.5) * s.y * 0.06)})


func _process_dust(delta: float) -> void:
	var live: Array = []
	for d in _dust:
		d.age += delta
		var node: Node2D = d.node
		if d.age > 0.7:
			node.queue_free()
			continue
		node.position += d.vel * delta
		node.modulate.a = 1.0 - d.age / 0.7
		live.append(d)
	_dust = live


## Oblačić prašine sa lave (jump-land) pri sletanju.
func _puff(pos: Vector2, width: float) -> void:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/lava/jump-land-1.png")
	var tex := sp.texture.get_size()
	sp.scale = Vector2.ONE * (width / tex.x)
	sp.offset = Vector2(0, -tex.y / 2.0)
	sp.position = pos
	sp.z_index = 7
	add_child(sp)
	var tw := create_tween()
	for i in 8:
		var idx := i + 1
		tw.tween_callback(func() -> void: sp.texture = load("res://art/lava/jump-land-%d.png" % idx))
		tw.tween_interval(0.045)
	tw.tween_callback(sp.queue_free)


func _glow(pos: Vector2, height: float) -> void:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/fx/charge-1.png")
	sp.scale = Vector2.ONE * (height / sp.texture.get_size().y)
	sp.position = pos
	sp.z_index = 25
	sp.modulate = Color(1.0, 0.62, 0.2)
	add_child(sp)
	var tw := create_tween()
	for i in 10:
		var idx := i + 1
		tw.tween_callback(func() -> void: sp.texture = load("res://art/fx/charge-%d.png" % idx))
		tw.tween_interval(0.05)
	tw.tween_callback(sp.queue_free)


func _process(delta: float) -> void:
	_t += delta
	if _jumping:
		_f += delta * 17.0
		_bronto.texture = _jump_frames[mini(int(_f), _jump_frames.size() - 1)]
	else:
		_f += delta * (_fps if _walking else 9.0)
		var fr: Array = _walk_frames if _walking else _frames
		_bronto.texture = fr[int(_f) % fr.size()]
	if _walking:
		_dust_t += delta
		if _dust_t > 0.28:
			_dust_t = 0.0
			_kick_dust(UI.vs(self))
	_process_dust(delta)
	_process_smoke(delta, UI.vs(self))
	_process_ptero(delta, UI.vs(self))
	for w in _sway:
		var n: Node2D = w.node
		n.rotation = float(w.amp) * sin(_t * TAU / float(w.period) + float(w.phase))


## Pokazivač: prevuci slobodnu ploču iz gomile na vrh kule.
func hint_spot() -> Dictionary:
	if _busy:
		return {}
	var s := UI.vs(self)
	for p in _pile:
		if not p.used:
			return {"from": p.node.position + Vector2(0, -s.y * SLAB_H * 0.5), "to": _top(s), "size": 1.4}
	return {}
