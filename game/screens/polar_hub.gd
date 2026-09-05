extends BaseScreen
## Polarni hub — peti svet: santa leda pod niskim suncem.
##
## Pozadina je kupljena "Arctic scene" kompozicija (assets/cut_polar.py) sa
## nebom zagrejanim ka horizontu, da se na ekranu svetova ne meša sa plavim
## okeanom. Snežna ploča (y 0.52–0.74) je pozornica, prednji led (y > 0.74)
## je nacrtan u pozadini.
##
## NIKO NE ŠETA (Ognjen 05.09.2026: "da ne bude da kopiramo dino"). Svih šest
## životinja su STANOVNICI na svom mestu, svaka sa animacijom stajanja u
## petlji i svojim potezom na dodir: pingvin, lisica i foka skoče, morž se
## uspravi, medved i irvas OTRČE van ekrana pa se vrate hodom. S vremena na
## vreme neko to uradi i sam, da scena ne miruje.

## Oblačenje i polarna svetlost se otključavaju kupovinom.
const LOCKED_GAMES := ["dress", "aurora"]
## Igre koje su stvarno napisane; ostale kapije stoje ali još ne vode nigde.
const IMPLEMENTED: Array[String] = []

const ART := "res://art/polar/"

var _s := Vector2.ZERO
var _t := 0.0

## Stanovnici. Crteži gledaju ULEVO (foka udesno), `mirror` okreće ka
## sredini. `act` je animacija na dodir; `dash` = otrči van ekrana u smeru
## u kom gleda i vrati se hodom (`walk`/`wn`).
const RESIDENTS := [
	{"id": "penguin",    "idle": "idle", "in": 20, "act": "jump", "an": 10, "h": 0.27, "x": 0.47,  "y": 0.745, "mirror": true,  "z": 2},
	{"id": "fox",        "idle": "idle", "in": 10, "act": "jump", "an": 10, "h": 0.24, "x": 0.29,  "y": 0.735, "mirror": true,  "z": 2},
	{"id": "bear",       "idle": "idle", "in": 20, "act": "run",  "an": 8,  "h": 0.33, "x": 0.74,  "y": 0.75,  "mirror": false, "z": 2, "dash": true, "walk": "walk", "wn": 8,  "speed": 0.30},
	{"id": "reindeer",   "idle": "eat",  "in": 20, "act": "run",  "an": 12, "h": 0.30, "x": 0.155, "y": 0.655, "mirror": true,  "z": -1, "dash": true, "walk": "walk", "wn": 12, "speed": 0.34},
	{"id": "walrus",     "idle": "idle", "in": 20, "act": "up",   "an": 20, "h": 0.19, "x": 0.585, "y": 0.63,  "mirror": false, "z": -1},
	{"id": "seal-white", "idle": "idle", "in": 16, "act": "jump", "an": 5,  "h": 0.12, "x": 0.43,  "y": 0.60,  "mirror": true,  "z": -2},
]
## Koliko čeka između samostalnih poteza (nasumično u ovom rasponu).
const AUTO_MIN := 4.0
const AUTO_MAX := 8.0

var _res: Array = []                      # {cfg, node, shadow, idle, act, walk, f, acting, phase, x, home, sc, wait}
var _auto_t := 3.0

## Šta pluta u daljini: oblaci i bregovi, svaki svojom brzinom, u petlji.
var _drift: Array = []                    # {node, speed, w}
## Sneško se zaljulja na dodir.
var _snowman: Sprite2D
## Sneg: čestice.
var _snow: Array = []

var _open_gates: Array[TapButton] = []


func _ready() -> void:
	var s := UI.vs(self)
	_s = s
	var bg := Sprite2D.new()
	bg.texture = load(ART + "bg-scene.png")
	var bt := bg.texture.get_size()
	bg.position = s / 2.0
	bg.scale = Vector2(s.x / bt.x, s.y / bt.y)
	bg.z_index = -50
	add_child(bg)

	_build_far(s)
	_build_scenery(s)
	_build_residents(s)
	_build_foreground(s)
	_build_snow(s)

	_build_gates(s)
	_build_worlds_button()
	_build_parent_button(s)
	add_hint(6.0)
	set_process(true)


# ---------------------------------------------------------------- pomoćnici

func _frames(prefix: String, count: int) -> Array:
	var out: Array = []
	for i in count:
		out.append(load(ART + "%s-%d.png" % [prefix, i + 1]))
	return out


func _add_tap(node: Node2D, w: float, h: float, cb: Callable) -> void:
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, h)
	shape.shape = rect
	area.add_child(shape)
	node.add_child(area)
	area.input_event.connect(func(_vp: Node, ev: InputEvent, _i: int) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			cb.call()
	)


## Senka pod nogama — bez nje životinja lebdi iznad snega.
func _shadow(r: float, z: int) -> Polygon2D:
	var sh := UI.circle(self, Vector2.ZERO, r, Color(0.20, 0.30, 0.45, 0.22), z)
	sh.scale = Vector2(1.0, 0.22)
	return sh


## Crtež sa OSLONCEM NA DNU (pivot bottom-centre), visina kao frakcija ekrana.
## Kupljeni PNG (art/polar/<ime>.png) ili SVG (art/polar/<ime>.svg, uvezen 6×).
func _prop(art: String, frac_h: float, cx: float, base_y: float, z: int, mirror := false) -> Sprite2D:
	var sp := Sprite2D.new()
	var png := ART + art + ".png"
	sp.texture = load(png) if ResourceLoader.exists(png) else load(ART + art + ".svg")
	var tex := sp.texture.get_size()
	var shrink: float = clampf((_s.x / _s.y) / 2.14, 0.62, 1.0)
	var sc: float = (_s.y * frac_h * shrink) / tex.y
	sp.scale = Vector2(-sc if mirror else sc, sc)
	sp.offset = Vector2(0, -tex.y / 2.0)
	sp.position = Vector2(_s.x * cx, _s.y * base_y)
	sp.z_index = z
	add_child(sp)
	return sp


# ----------------------------------------------------------------- elementi

## Daljina: oblaci, bregovi i led plutaju s desna ulevo, iza svega. Nebo je u
## pozadinskoj slici, ovo je samo ono što se MIČE.
func _build_far(s: Vector2) -> void:
	for d in [
		{"art": "cloud-3", "h": 0.030, "y": 0.075, "speed": 0.006, "x": 0.15},
		{"art": "cloud-2", "h": 0.034, "y": 0.135, "speed": 0.009, "x": 0.62},
		{"art": "iceberg-3", "h": 0.10, "y": 0.415, "speed": 0.004, "x": 0.40},
		{"art": "iceberg-5", "h": 0.075, "y": 0.43, "speed": 0.003, "x": 0.85},
		{"art": "ice-piece-3", "h": 0.035, "y": 0.475, "speed": 0.007, "x": 0.25},
		{"art": "ice-piece-2", "h": 0.03, "y": 0.49, "speed": 0.005, "x": 0.70},
	]:
		var sp := _prop(d.art, float(d.h), float(d.x), float(d.y), -46)
		_drift.append({"node": sp, "speed": float(d.speed), "w": sp.texture.get_size().x * sp.scale.x / s.x})


## Rekviziti na ploči: jelke levo i desno (oslonci kompozicije), sneško,
## zaleđeno jezerce u sredini, ledene gomile. Sve ukorenjeno na ploči
## (y 0.55–0.72); prednja traka ostaje za životinje u prvom planu.
func _build_scenery(s: Vector2) -> void:
	# levo: dve jelke i ledena gomila
	_prop("tree-05", 0.34, 0.04, 0.615, -3, true)
	_prop("tree-02", 0.22, 0.095, 0.64, -2)
	_prop("rock-01", 0.05, 0.25, 0.60, -3)
	# sredina: zaleđeno jezerce (ravno, na ploči) i led oko njega
	_prop("pond", 0.09, 0.50, 0.625, -4)
	_prop("ice-piece-1", 0.09, 0.44, 0.585, -3)
	_prop("ice-piece-2", 0.07, 0.62, 0.575, -3, true)
	_prop("rock-group", 0.12, 0.30, 0.575, -3)
	# prednja ivica ploče: sitni led
	_prop("rock-01", 0.045, 0.60, 0.80, 1, true)
	_prop("rock-01", 0.04, 0.88, 0.815, 1)
	# desno: jelke i sneško
	_prop("tree-03", 0.30, 0.955, 0.60, -2)
	_prop("tree-05", 0.38, 0.905, 0.635, -1)
	_prop("tree-02", 0.24, 0.975, 0.66, 0)
	# Sneško stoji ISPRED jelki, pa mu osnova mora biti NIŽA od njihovih
	# (ranije 0.615 ispred jelke na 0.635 — lebdeo je); senka kao životinjama.
	_snowman = _prop("snowman", 0.17, 0.865, 0.70, 0)
	var ssh := _shadow(_snowman.texture.get_size().x * _snowman.scale.y * 0.42, -1)
	ssh.position = _snowman.position + Vector2(0, -2)
	_add_tap(_snowman, _snowman.texture.get_size().x * 0.9, _snowman.texture.get_size().y * 0.95,
		func() -> void:
			UI.haptic(30)
			Audio.play("pop")
			UI.bounce(_snowman, _snowman.scale))


## Prednji plan: komadi leda uz donju ivicu, ISPRED svega, ukorenjeni ispod
## ivice ekrana da ne lebde.
func _build_foreground(s: Vector2) -> void:
	_prop("ice-piece-1", 0.14, 0.08, 1.04, 6)
	_prop("ice-piece-3", 0.12, 0.93, 1.03, 6, true)
	_prop("ice-piece-2", 0.10, 0.52, 1.05, 6)


func _build_residents(s: Vector2) -> void:
	for cfg in RESIDENTS:
		var idle := _frames(cfg.id + "-" + cfg.idle, int(cfg["in"]))
		var act := _frames(cfg.id + "-" + cfg.act, int(cfg.an))
		var walk: Array = _frames(cfg.id + "-" + cfg.walk, int(cfg.wn)) if cfg.get("dash", false) else []
		var sp := Sprite2D.new()
		var f0: Texture2D = idle[0]
		var tex := f0.get_size()
		var shrink: float = clampf((s.x / s.y) / 2.14, 0.62, 1.0)
		var sc: float = (s.y * float(cfg.h) * shrink) / tex.y
		sp.texture = f0
		sp.scale = Vector2(-sc if cfg.mirror else sc, sc)
		sp.offset = Vector2(0, -tex.y / 2.0)
		var home := Vector2(s.x * float(cfg.x), s.y * float(cfg.y))
		sp.position = home
		sp.z_index = int(cfg.z)
		add_child(sp)
		var sh := _shadow(tex.x * sc * 0.36, int(cfg.z) - 1)
		sh.position = home + Vector2(0, -tex.y * sc * 0.01)
		var r := {"cfg": cfg, "node": sp, "shadow": sh, "idle": idle, "act": act, "walk": walk,
			"f": randf() * 20.0, "acting": -1.0, "phase": "", "x": float(cfg.x), "home": home, "sc": sc, "wait": 0.0}
		_add_tap(sp, tex.x * 0.8, tex.y * 0.9, func() -> void: _poke(r, true))
		_res.append(r)


## Potez stanovnika: na dodir (sa zvukom) ili sam od sebe.
func _poke(r: Dictionary, by_tap: bool) -> void:
	if r.acting >= 0.0 or r.phase != "":
		return
	if by_tap:
		UI.haptic(30)
		Audio.play("pop")
	if r.cfg.get("dash", false):
		r.phase = "out"
	else:
		r.acting = 0.0


# ---------------------------------------------------------------------- UI

func _build_gates(s: Vector2) -> void:
	var gates := [
		{"screen": "slide", "icon": "icon-slide"},
		{"screen": "fishing", "icon": "icon-fishing"},
		{"screen": "dress", "icon": "icon-clothes"},
		{"screen": "aurora", "icon": "icon-aurora"},
	]
	for i in gates.size():
		var g: Dictionary = gates[i]
		var pos := Vector2(s.x * (0.274 + 0.1505 * i), s.y * 0.170)
		var btn := TapButton.new(pos, 105, Pal.BUTTON_WHITE)
		UI.circle(btn, Vector2.ZERO, 105 + 11, Pal.OUTLINE, -2)
		UI.circle(btn, Vector2.ZERO, 105 + 4, Color("#E9DCC4"), -1)
		# Ikonica: složeni PNG (art/polar/<ikonica>.png) ima prednost nad SVG-om.
		var icon_png := ART + "%s.png" % g.icon
		if ResourceLoader.exists(icon_png):
			var ic := Sprite2D.new()
			ic.texture = load(icon_png)
			ic.scale = Vector2.ONE * (150.0 / 256.0)
			btn.add_child(ic)
		else:
			Scenery.svg(btn, g.icon, Vector2.ZERO, 0.66, 0)
		var target: String = g.screen
		var locked: bool = target in LOCKED_GAMES and not Save.unlocked
		if not target in IMPLEMENTED:
			# Igra još ne postoji — kapija samo poskoči, da tap ne ruši ekran.
			btn.tapped.connect(func() -> void: UI.bounce(btn, Vector2.ONE))
		elif locked:
			Scenery.svg(btn, "icon-lock", Vector2(58, 58), 0.55, 5)
			btn.tapped.connect(func() -> void: go("gate"))
		else:
			btn.tapped.connect(func() -> void: go(target))
		btn.z_index = 10
		add_child(btn)
		btn.start_pulse()
		if not locked:
			_open_gates.append(btn)


func _build_worlds_button() -> void:
	var btn := TapButton.new(Vector2(100, 100), 62, Color(1, 1, 1, 0.85))
	UI.poly(btn, PackedVector2Array([Vector2(14, -26), Vector2(-22, 0), Vector2(14, 26)]), Color(0.45, 0.40, 0.36))
	btn.tapped.connect(func() -> void: go("worlds"))
	btn.z_index = 10
	add_child(btn)


func _build_parent_button(s: Vector2) -> void:
	var btn := TapButton.new(Vector2(s.x - 80, s.y - 80), 48, Color(0.99, 0.98, 0.96, 0.55))
	for y in [-12, 0, 12]:
		UI.poly(btn, UI.rect_points(34, 6), Color(0.55, 0.5, 0.45), Vector2(0, y))
	btn.tapped.connect(func() -> void: go("gate"))
	btn.z_index = 100
	add_child(btn)


func _build_snow(s: Vector2) -> void:
	# Sneg su čestice, ne kupljene pahulje (Ognjen 05.09.2026: krupne pahulje
	# su izgledale neprirodno). Sitne meke tačke, lagano padaju i njišu se.
	var snow := CPUParticles2D.new()
	var tex := GradientTexture2D.new()
	tex.width = 24
	tex.height = 24
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.5)
	tex.fill_to = Vector2(0.5, 0.0)
	var g := Gradient.new()
	g.set_color(0, Color(1, 1, 1, 0.95))
	g.set_color(1, Color(1, 1, 1, 0.0))
	tex.gradient = g
	snow.texture = tex
	snow.amount = 90
	snow.lifetime = 11.0
	snow.preprocess = 11.0                  # ekran je već pun snega na ulasku
	snow.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	snow.emission_rect_extents = Vector2(s.x * 0.6, 10)
	snow.position = Vector2(s.x / 2.0, -20)
	snow.direction = Vector2(0, 1)
	snow.spread = 12.0
	snow.gravity = Vector2(0, 0)
	snow.initial_velocity_min = s.y * 0.055
	snow.initial_velocity_max = s.y * 0.10
	snow.scale_amount_min = 0.35
	snow.scale_amount_max = 1.0
	snow.tangential_accel_min = -18.0
	snow.tangential_accel_max = 18.0
	snow.z_index = 4
	add_child(snow)
	_snow = [snow]


# -------------------------------------------------------------------- pokret

func _process(delta: float) -> void:
	_t += delta
	_process_residents(delta, _s)
	_process_far(delta, _s)


func _process_residents(delta: float, s: Vector2) -> void:
	# Samostalni potezi: svakih nekoliko sekundi jedan nasumičan stanovnik.
	_auto_t -= delta
	if _auto_t <= 0.0:
		_auto_t = randf_range(AUTO_MIN, AUTO_MAX)
		_poke(_res[randi() % _res.size()], false)

	for r in _res:
		var sp: Sprite2D = r.node
		r.f += delta * 10.0

		if r.phase != "":
			_process_dash(r, delta, s)
			continue

		if r.acting >= 0.0:
			r.acting += delta * 10.0
			if int(r.acting) >= r.act.size():
				r.acting = -1.0
			else:
				sp.texture = r.act[int(r.acting)]
				continue

		sp.texture = r.idle[int(r.f) % r.idle.size()]


## Otrči van ekrana u smeru u kom gleda (trk), sačeka, pa se vrati hodom
## okrenut ka kući; kod kuće se okrene kako je i stajao.
func _process_dash(r: Dictionary, delta: float, s: Vector2) -> void:
	var sp: Sprite2D = r.node
	var cfg: Dictionary = r.cfg
	var faces_right: bool = bool(cfg.mirror)
	var dir: float = 1.0 if faces_right else -1.0
	var sc: float = float(r.sc)
	if r.phase == "out":
		sp.scale.x = -sc if faces_right else sc
		sp.texture = r.act[int(r.f * 1.4) % r.act.size()]
		r.x += delta * float(cfg.speed) * dir
		if r.x < -0.25 or r.x > 1.25:
			r.phase = "wait"
			r.wait = randf_range(2.0, 3.5)
			sp.visible = false
			r.shadow.visible = false
	elif r.phase == "wait":
		r.wait -= delta
		if r.wait <= 0.0:
			r.phase = "back"
			sp.visible = true
			r.shadow.visible = true
	elif r.phase == "back":
		# vraća se hodom u SUPROTNOM smeru, okrenut ka kući
		sp.scale.x = sc if faces_right else -sc
		sp.texture = r.walk[int(r.f) % r.walk.size()]
		r.x -= delta * float(cfg.speed) * 0.55 * dir
		var arrived: bool = (r.x <= float(cfg.x)) if faces_right else (r.x >= float(cfg.x))
		if arrived:
			r.x = float(cfg.x)
			r.phase = ""
			sp.scale.x = -sc if faces_right else sc
	sp.position.x = s.x * r.x
	r.shadow.position.x = sp.position.x


func _process_far(delta: float, s: Vector2) -> void:
	for d in _drift:
		var sp: Sprite2D = d.node
		sp.position.x -= delta * float(d.speed) * s.x
		if sp.position.x < -float(d.w) * s.x * 0.6:
			sp.position.x = s.x * (1.0 + float(d.w) * 0.6)


func hint_spot() -> Dictionary:
	if _open_gates.is_empty():
		return {}
	return {"at": _open_gates[randi() % _open_gates.size()].position, "size": 2.0}
