extends BaseScreen
## Dino igra 2: STAZA PREKO LAVE — građenje putanje.
##
## Reka lave preko donje trećine, T-Rex čeka na levoj obali. Dete tapka prazna
## mesta u lavi — na svakom izroni kamen; kad se staza spoji, T-Rex je preskače
## kamen po kamen, sa oblačićem prašine pri odskoku i sletanju.
##
## Zašto ovako: prva igra u kojoj ono što dete uradi OSTAJE na ekranu i tek
## zbir poteza daje rezultat. Nema tajmera i nema pada u lavu — dino čeka.
##
## Ovo je namerno NAJTAMNIJI ekran dino sveta (jaja su najsvetliji): noć
## osvetljena odozdo žarom lave.

## Redosled tabli: dvaput po 3, dvaput po 4, dvaput po 5, jednom 6, pa iz početka.
## Dve table sa istim brojem kamenova dobijaju RAZLIČIT raspored (A pa B).
const LEVELS := [3, 3, 4, 4, 5, 5, 6]
## Svaka tabla druga vrsta; svaka ima stajanje i skok (triceratops nema skok u
## setu, pa mu trk igra skok). Frejmovi su isečeni sa zajedničkim okvirom po
## vrsti, pa smena stajanje → skok ne pomera životinju.
## T-Rex namerno nije prvi: zubi na prvom ekranu nisu dobar početak.
const SPECIES := [
	{"idle": "lb-idle", "in": 20, "jump": "lb-jump", "jn": 12, "h": 0.30},
	{"idle": "ls-idle", "in": 20, "jump": "ls-jump", "jn": 12, "h": 0.24},
	{"idle": "lc-idle", "in": 20, "jump": "lc-jump", "jn": 12, "h": 0.22},
	{"idle": "lt-idle", "in": 20, "jump": "lt-jump", "jn": 10, "h": 0.25},
]
## Dva rasporeda kamenja za svaki broj — bira se nasumično, da tabla sa istim
## brojem kamenova ne izgleda uvek isto. Vrednosti su (x, pomak po y) u
## frakcijama ekrana; x ide između obala.
const LAYOUTS := {
	3: [[[0.30, 0.00], [0.50, -0.03], [0.70, 0.01]], [[0.28, 0.02], [0.52, 0.03], [0.72, -0.02]]],
	4: [[[0.26, 0.01], [0.42, -0.03], [0.58, 0.02], [0.74, -0.01]], [[0.27, -0.02], [0.41, 0.03], [0.59, -0.03], [0.73, 0.02]]],
	5: [[[0.24, 0.00], [0.37, -0.03], [0.50, 0.02], [0.63, -0.02], [0.76, 0.01]], [[0.25, 0.03], [0.38, 0.00], [0.50, -0.03], [0.62, 0.02], [0.75, -0.01]]],
	6: [[[0.22, 0.01], [0.33, -0.02], [0.44, 0.02], [0.56, -0.02], [0.67, 0.02], [0.78, -0.01]], [[0.23, -0.02], [0.34, 0.02], [0.45, -0.03], [0.55, 0.02], [0.66, -0.02], [0.77, 0.02]]],
}
const RIVER_Y := 0.635            # sredina jezera lave (gotova scena iz kita)
const RIVER_H := 0.16
const BANK_LEFT := 0.14
const BANK_RIGHT := 0.86
## Ploče koje plutaju po lavi, iz lava kita (obrub lave je u samom crtežu).
const ROCKS := ["slab1", "slab1", "slab2", "slab1"]

var _level := 0
var _slots: Array = []            # {pos, filled, marker, ghost}
var _bank_top := 0.0              # vrh obalnih stubova, gde T-Rex stoji
var _lava_t := 0.0
var _dino: Sprite2D
var _idle: Array = []
var _jump: Array = []
var _species := -1
var _dino_f := 0.0
var _jumping := false
var _busy := false
var _level_nodes: Array = []      # sve što se briše pri novoj tabli
## Život na reci iz kupljenog lava kita: mehuri koji pucaju, para koja se diže,
## povremeni gejzir, i lavopad iz levog vulkana u reku.
var _bub_next := 0.6
var _vapours: Array = []          # {node, x, u, speed}
var _gey_next := 6.0
## Lavopadi: tri stuba lave u sceni su nacrtani; preko svakog ide kitova
## animacija (10 frejmova) razvučena po visini stuba, pa lava TEČE.
var _falls: Array = []
var _fall_f := 0.0
var _fbases: Array = []
var _streaks: Array = []
## Jezerce u tlu: isti piksel pozadine, sa mekom maskom, pulsira svetlinom.
var _pool: Sprite2D



func _ready() -> void:
	home_target = "dino"
	var s := UI.vs(self)
	var bg := Sprite2D.new()
	bg.texture = load("res://art/lava/bg-lava.png")
	var bt := bg.texture.get_size()
	bg.position = s / 2.0
	bg.scale = Vector2(s.x / bt.x, s.y / bt.y)
	bg.z_index = -50
	add_child(bg)


	_build_river(s)
	_build_life(s)
	_build_dino(s)
	_build_level()
	add_home_button()
	add_hint(5.0)
	set_process(true)


## Jezero lave je NACRTANO u pozadini (sastavljenoj iz lava kita). Ovde idu
## samo dve obale: bazaltni stubovi levo i desno, na kojima T-Rex čeka i na
## koje sleti. Život jezera (mehuri, para, gejzir) je u _build_life.
func _build_river(s: Vector2) -> void:
	for cx in [BANK_LEFT - 0.10, BANK_RIGHT + 0.10]:
		var sp := Sprite2D.new()
		sp.texture = load("res://art/lava/pillar.png")
		var tex := sp.texture.get_size()
		var sc: float = (s.x * 0.12) / tex.x
		sp.scale = Vector2.ONE * sc
		sp.offset = Vector2(0, -tex.y / 2.0)
		sp.position = Vector2(s.x * cx, s.y * (RIVER_Y + 0.04))
		sp.z_index = 3
		add_child(sp)
	_bank_top = s.y * (RIVER_Y + 0.04) - 0.259 * (s.x * 0.12) * 0.92


## Četiri pramena pare koja se stalno dižu sa površine reke.
func _build_life(s: Vector2) -> void:
	# Lavopadi: kitov crtež stuba (10 frejmova, 371×400, jezgro stuba je 258 px
	# široko od x=55) složen po visini preko nacrtanih stubova, u TAČNOJ širini
	# stuba. Smena sličica = lava teče. Prva dva pokušaja su bila pogrešna:
	# razvučen crtež je bio ravna žuta ploča, a mlazevi i kapi bledi oblici.
	# Ostao je samo levi, tanki lavopad — dva debela su obrisana iz pozadine.
	for f in [{"x": 0.100, "w": 0.026, "y1": 0.66}]:
		var sc: float = (s.x * float(f.w)) / 258.0
		var seg_h: float = 400.0 * sc
		var x: float = s.x * float(f.x) - 184.0 * sc + (371.0 * sc) / 2.0
		var y: float = s.y * float(f.y1) - seg_h / 2.0
		while y > -seg_h:
			var sp := Sprite2D.new()
			sp.texture = load("res://art/lava/fall-1.png")
			sp.scale = Vector2.ONE * sc
			sp.position = Vector2(x, y)
			sp.z_index = -49
			add_child(sp)
			_falls.append(sp)
			y -= seg_h - 4.0 * sc
		# Podnožje: kitova animacija prskanja tamo gde stub ulazi u jezero —
		# bez nje se vidi ravna crta na spoju.
		var base := Sprite2D.new()
		base.texture = load("res://art/lava/fbase-1.png")
		var bt := base.texture.get_size()
		base.scale = Vector2.ONE * ((s.x * float(f.w) * 2.6) / bt.x)
		base.offset = Vector2(0, -bt.y * 0.62)
		base.position = Vector2(s.x * float(f.x), s.y * float(f.y1) + s.y * 0.015)
		base.z_index = -48
		add_child(base)
		_fbases.append(base)
		# Svetli mlazevi PO SREDINI stuba: dva tanka mlaza koja klize nadole.
		for k in 2:
			var st := Sprite2D.new()
			st.texture = load("res://art/lava/streak-1.png")
			var stt := st.texture.get_size()
			st.scale = Vector2(((s.x * float(f.w)) * 0.10) / stt.x, (s.y * 0.20) / stt.y)
			st.z_index = -48
			add_child(st)
			_streaks.append({"node": st, "x": s.x * float(f.x) + s.x * float(f.w) * (-0.18 if k == 0 else 0.16),
				"y1": s.y * float(f.y1), "u": float(k) * 0.5, "speed": randf_range(0.35, 0.5), "f": randf() * 8.0})
	_pool = Sprite2D.new()
	_pool.texture = load("res://art/lava/pool-glow.png")
	var pt := _pool.texture.get_size()
	_pool.scale = Vector2(s.x / 2340.0, s.y / 1080.0)
	_pool.position = Vector2(s.x * 0.35, s.y * 0.875)
	_pool.z_index = -49
	add_child(_pool)

	# Lavopad iz kita je probano i izbačeno: žuta kolona iza T-Rexa, ne uklapa se.
	for i in 4:
		var sp := Sprite2D.new()
		sp.texture = load("res://art/lava/vap-1.png")
		var vt := sp.texture.get_size()
		sp.scale = Vector2.ONE * ((s.y * 0.14) / vt.y)
		sp.offset = Vector2(0, -vt.y / 2.0)
		sp.z_index = -1
		add_child(sp)
		_vapours.append({"node": sp, "x": s.x * randf_range(0.05, 0.95), "u": float(i) / 4.0,
			"speed": randf_range(0.10, 0.16), "f": randf() * 17.0})


## Mehur lave: pojavi se, nabubri i pukne (9 frejmova), pa nestane.
func _bubble(s: Vector2) -> void:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/lava/bub-1.png")
	var bt := sp.texture.get_size()
	sp.scale = Vector2.ONE * ((s.x * randf_range(0.05, 0.09)) / bt.x)
	sp.offset = Vector2(0, -bt.y / 2.0)
	sp.position = Vector2(s.x * randf_range(0.03, 0.97), s.y * (RIVER_Y + randf_range(-0.05, 0.06)))
	sp.z_index = -2
	add_child(sp)
	var tw := create_tween()
	for i in 9:
		var idx := i + 1
		tw.tween_callback(func() -> void: sp.texture = load("res://art/lava/bub-%d.png" % idx))
		tw.tween_interval(0.07)
	tw.tween_callback(sp.queue_free)


## Gejzir: podnožje (7) pa mlaz (5), jednokratno, na slobodnom mestu u reci.
func _geyser(s: Vector2) -> void:
	var x: float = s.x * randf_range(0.06, 0.94)
	for sl in _slots:
		if absf(sl.pos.x - x) < s.x * 0.09:
			return                       # pored kamena ne izbija
	var pos := Vector2(x, s.y * (RIVER_Y + 0.02))
	var base := Sprite2D.new()
	base.texture = load("res://art/lava/geyb-1.png")
	var bt := base.texture.get_size()
	base.scale = Vector2.ONE * ((s.x * 0.07) / bt.x)
	base.offset = Vector2(0, -bt.y / 2.0)
	base.position = pos
	base.z_index = -1
	add_child(base)
	var head := Sprite2D.new()
	head.texture = load("res://art/lava/gey-1.png")
	var ht := head.texture.get_size()
	head.scale = Vector2.ONE * ((s.x * 0.16) / ht.x)
	head.offset = Vector2(0, -ht.y / 2.0)
	head.position = pos + Vector2(0, -s.y * 0.05)
	head.z_index = -1
	head.visible = false
	add_child(head)
	var tw := create_tween()
	for i in 7:
		var bi := i + 1
		tw.tween_callback(func() -> void: base.texture = load("res://art/lava/geyb-%d.png" % bi))
		tw.tween_interval(0.06)
	tw.tween_callback(func() -> void: head.visible = true)
	for i in 5:
		var hi := i + 1
		tw.tween_callback(func() -> void: head.texture = load("res://art/lava/gey-%d.png" % hi))
		tw.tween_interval(0.08)
	tw.tween_callback(func() -> void:
		base.queue_free()
		head.queue_free()
	)


func _build_dino(s: Vector2) -> void:
	_dino = Sprite2D.new()
	_dino.z_index = 6
	add_child(_dino)
	_load_species(0, s)


## Učitava vrstu za tekuću tablu: frejmovi, veličina po visini, sidro na dnu.
func _load_species(idx: int, s: Vector2) -> void:
	_species = idx
	var sp: Dictionary = SPECIES[idx]
	_idle.clear()
	_jump.clear()
	for i in int(sp["in"]):
		_idle.append(load("res://art/lava/%s-%d.png" % [sp.idle, i + 1]))
	for i in int(sp.jn):
		_jump.append(load("res://art/lava/%s-%d.png" % [sp.jump, i + 1]))
	_dino.texture = _idle[0]
	var tex: Vector2 = _idle[0].get_size()
	var sc: float = (s.y * float(sp.h)) / tex.y
	_dino.scale = Vector2(-sc, sc)             # crtež gleda ulevo, on gleda ka reci
	_dino.offset = Vector2(0, -tex.y / 2.0)   # dno crteža na poziciji


func _dino_home(s: Vector2) -> Vector2:
	return Vector2(s.x * (BANK_LEFT - 0.10), _bank_top)


func _build_level() -> void:
	var s := UI.vs(self)
	_busy = false
	for n in _level_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_level_nodes.clear()
	_slots.clear()
	_dino.position = _dino_home(s)
	_dino.scale.x = -absf(_dino.scale.x)

	var count: int = LEVELS[_level % LEVELS.size()]
	_load_species(_level % SPECIES.size(), s)
	var variants: Array = LAYOUTS[count]
	# koja je ovo po redu tabla sa ovim brojem u ciklusu → varijanta A ili B
	var nth := 0
	for i in (_level % LEVELS.size()):
		if LEVELS[i] == count:
			nth += 1
	var layout: Array = variants[nth % variants.size()]
	for i in count:
		var pt: Array = layout[i]
		var pos := Vector2(s.x * float(pt[0]), s.y * (RIVER_Y + float(pt[1])))
		_slots.append(_build_slot(i, pos, s, count))


## Prazno mesto: tamna mrlja pod površinom — kamen koji tek treba da izroni.
func _build_slot(idx: int, pos: Vector2, s: Vector2, count: int) -> Dictionary:
	var marker := Node2D.new()
	marker.position = pos
	marker.z_index = 4
	add_child(marker)
	_level_nodes.append(marker)

	var ghost := UI.circle(marker, Vector2.ZERO, s.x * 0.040, Color(0.35, 0.15, 0.05, 0.45), 0)
	ghost.scale = Vector2(1.0, 0.45)

	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = s.x * (0.062 if count <= 4 else 0.052)
	shape.shape = circle
	area.add_child(shape)
	marker.add_child(area)
	var i := idx
	area.input_event.connect(func(_vp: Node, ev: InputEvent, _k: int) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			_place_stone(i)
	)
	return {"pos": pos, "filled": false, "marker": marker, "ghost": ghost, "w": (0.15 if count <= 4 else 0.12)}


func _place_stone(idx: int) -> void:
	if _busy:
		return
	var sl: Dictionary = _slots[idx]
	if sl.filled:
		UI.bounce(sl.marker, Vector2.ONE)
		Audio.play("tap")
		return
	sl.filled = true
	var s := UI.vs(self)
	sl.ghost.visible = false

	var stone := Sprite2D.new()
	stone.texture = load("res://art/lava/%s.png" % ROCKS[idx % ROCKS.size()])
	var tex := stone.texture.get_size()
	var sc: float = (s.x * float(sl.w)) / tex.x
	stone.scale = Vector2.ONE * sc
	# Ploča pluta: obrub lave iz crteža leži na površini, gornja ivica ploče je
	# tačka sletanja.
	stone.offset = Vector2(0, -tex.y * 0.30)
	sl["top"] = sl.pos + Vector2(0, -tex.y * 0.62 * sc)
	if idx % 2 == 1:
		stone.scale.x = -stone.scale.x            # naizmenično ogledano
	stone.z_index = 1
	sl.marker.add_child(stone)
	# Kamen IZRONI iz lave: kreće ispod površine i podigne se, uz prasak.
	stone.position = Vector2(0, s.y * 0.10)
	stone.modulate.a = 0.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(stone, "position", Vector2.ZERO, 0.32).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(stone, "modulate:a", 1.0, 0.15)
	tw.chain().tween_callback(func() -> void:
		Audio.play("lava_bubble", 0.0, randf_range(0.9, 1.1))
		UI.haptic(30)
		_puff("jump-land", 8, sl.pos + Vector2(0, -s.y * 0.01), s.x * 0.16)
		_check_done()
	)


## Efekat slavlja (10 frejmova), odigra se jednom oko zadate tačke.
func _charge(pos: Vector2, height: float) -> void:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/fx/charge-1.png")
	sp.scale = Vector2.ONE * (height / sp.texture.get_size().y)
	sp.position = pos
	sp.z_index = 8
	add_child(sp)
	var tw := create_tween()
	for i in 10:
		var idx := i + 1
		tw.tween_callback(func() -> void: sp.texture = load("res://art/fx/charge-%d.png" % idx))
		tw.tween_interval(0.07)
	tw.tween_callback(sp.queue_free)


## Oblačić iz kupljenog seta (odskok 7 / sletanje 8 frejmova), odigra se jednom.
func _puff(prefix: String, count: int, pos: Vector2, width: float) -> void:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/lava/%s-1.png" % prefix)
	var tex := sp.texture.get_size()
	sp.scale = Vector2.ONE * (width / tex.x)
	sp.offset = Vector2(0, -tex.y / 2.0)
	sp.position = pos
	sp.z_index = 7
	add_child(sp)
	var tw := create_tween()
	for i in count:
		var idx := i + 1
		tw.tween_callback(func() -> void: sp.texture = load("res://art/lava/%s-%d.png" % [prefix, idx]))
		tw.tween_interval(0.045)
	tw.tween_callback(sp.queue_free)


func _check_done() -> void:
	# Svaki kamen zove ovo posle izranjanja. Kad se dva zadnja postave brzo jedan
	# za drugim (najlakše sa 5 kamenova), oba vide "svi su tu" i prelazak bi
	# krenuo DVAPUT — dva tvina se otimaju oko T-Rexa i skok se ne vidi.
	if _busy:
		return
	for sl in _slots:
		if not sl.filled:
			return
	_busy = true
	_cross()


## Staza je spojena: T-Rex skače s kamena na kamen. Svaki skok je isti niz od
## deset frejmova, a putanja je luk — gore u prvoj polovini, dole u drugoj.
func _cross() -> void:
	_busy = true
	var s := UI.vs(self)
	var tw := create_tween()
	var from := _dino.position
	var stops: Array = []
	for sl in _slots:
		stops.append(sl.get("top", sl.pos))
	stops.append(Vector2(s.x * (BANK_RIGHT + 0.10), _bank_top))
	for target in stops:
		var a: Vector2 = from
		var b: Vector2 = target
		tw.tween_callback(func() -> void:
			_jumping = true
			_dino_f = 0.0
			_puff("jump-off", 7, a, s.x * 0.14)
		)
		tw.tween_method(func(u: float) -> void:
			_dino.position = a.lerp(b, u) + Vector2(0, -sin(u * PI) * s.y * 0.09)
		, 0.0, 1.0, 0.42)
		tw.tween_callback(func() -> void:
			_jumping = false
			Audio.play("tap")
			_puff("jump-land", 8, b, s.x * 0.14)
		)
		tw.tween_interval(0.12)
		from = target
	tw.tween_callback(func() -> void:
		# Slavlje: kupljeni "charge" efekat oko životinje umesto konfeta; glas
		# deteta ostaje (to je ono što nosi emociju).
		Audio.play(["yay", "giggle", "kid"][randi() % 3], -2.0)
		_charge(_dino.position + Vector2(0, -s.y * 0.10), s.y * 0.34)
		_level += 1
	)
	tw.tween_interval(2.4)
	tw.tween_callback(_build_level)


func _process(delta: float) -> void:
	_lava_t += delta
	var s := UI.vs(self)
	# Život reke: mehuri, para, gejzir, lavopad.
	# Mehuri i gejzir su probani i izbačeni — lava koja iskače je bila višak.
	_fall_f += delta * 12.0
	var fall_tex: Texture2D = load("res://art/lava/fall-%d.png" % (int(_fall_f) % 10 + 1))
	for sp in _falls:
		sp.texture = fall_tex
	var base_tex: Texture2D = load("res://art/lava/fbase-%d.png" % (int(_fall_f) % 8 + 1))
	for b in _fbases:
		b.texture = base_tex
	for st in _streaks:
		st.u += delta * st.speed
		st.f += delta * 10.0
		if st.u >= 1.0:
			st.u -= 1.0
		var node: Sprite2D = st.node
		node.texture = load("res://art/lava/streak-%d.png" % (int(st.f) % 8 + 1))
		node.position = Vector2(st.x, st.u * st.y1)
		node.modulate = Color(1.15, 1.12, 0.9, clampf(st.u * 5.0, 0.0, 1.0) * clampf((1.0 - st.u) * 5.0, 0.0, 1.0))
	var g: float = 1.0 + 0.18 * (0.5 + 0.5 * sin(_lava_t * 1.1))
	_pool.modulate = Color(g, g * 0.97, g * 0.9)
	for v in _vapours:
		v.u += delta * v.speed
		v.f += delta * 12.0
		if v.u >= 1.0:
			v.u -= 1.0
			v.x = s.x * randf_range(0.05, 0.95)
		var node: Sprite2D = v.node
		node.texture = load("res://art/lava/vap-%d.png" % (int(v.f) % 17 + 1))
		node.position = Vector2(v.x + sin(v.u * 4.0) * s.x * 0.01, s.y * (RIVER_Y - RIVER_H * 0.45) - v.u * s.y * 0.20)
		node.modulate.a = clampf(v.u * 5.0, 0.0, 1.0) * (1.0 - v.u) * 0.8

	_dino_f += delta * (16.0 if _jumping else 9.0)
	if _jumping:
		_dino.texture = _jump[mini(int(_dino_f * float(_jump.size()) / 10.0), _jump.size() - 1)]
	else:
		_dino.texture = _idle[int(_dino_f) % _idle.size()]


## Pokazivač: prvo prazno mesto sleva.
func hint_spot() -> Dictionary:
	if _busy:
		return {}
	for sl in _slots:
		if not sl.filled:
			return {"at": sl.pos, "size": 1.5}
	return {}
