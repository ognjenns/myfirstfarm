extends BaseScreen
## Dino igra 3: KAMENJE — razbij pa pogodi.
##
## Desno je gomila kamenja, iza nje senka dinosaurusa. Tap na kamen:
## praistorijski čekić udari gde si tapnuo, kamen napukne, pa se raspadne — i
## senka se otkriva deo po deo. Kad je gomila dovoljno srušena, dole se pojave tri
## kandidata; dete prevuče onog čija je senka. Pogrešan kaže "no no no" i
## vrati se, pravi legne u senku, zasvetli i oživi.
##
## Sedam kandidata bi bilo previše za 2–5; tri je taman, i gest je isti kao
## senke na farmi — poznato, samo sa otkrivanjem pre toga.

## Gomila kamenja: redovi odozdo nagore, {x pomak od centra, y iznad tla,
## širina, koji kamen, flip}. Slaže se tako da pokrije senku.
const PILE := [
	[-0.14, 0.00, 0.17, 3, false], [0.00, 0.00, 0.17, 2, true], [0.14, 0.00, 0.17, 3, true],
	[-0.08, 0.12, 0.16, 4, false], [0.07, 0.12, 0.16, 2, false],
	[-0.13, 0.22, 0.15, 2, true], [0.00, 0.23, 0.15, 3, false], [0.13, 0.22, 0.15, 4, true],
	[-0.06, 0.33, 0.14, 1, false], [0.07, 0.33, 0.14, 2, true],
	[0.00, 0.43, 0.13, 3, false],
]
## Koliko kamenja mora da padne da se pokažu kandidati — ne sve, dete bi
## tražilo poslednji kamen umesto da nastavi.
const REVEAL := 0.55
const HITS := 2
const SPECIES := [
	{"id": "bronto", "idle": "lb-idle", "n": 20, "h": 0.50},
	{"id": "stego", "idle": "ls-idle", "n": 20, "h": 0.44},
	{"id": "trike", "idle": "lc-idle", "n": 20, "h": 0.44},
	{"id": "trex", "idle": "lt-idle", "n": 20, "h": 0.46},
]

var _round := 0
var _phase := 0                 # 0 rušenje, 1 biranje, 2 gotovo
var _bricks: Array = []         # {node, hits, gone, pos}
var _gone := 0
var _sil: Sprite2D
var _sil_pos := Vector2.ZERO
var _target := 0
var _cands: Array = []          # {node, frames, sp, home, correct}
var _drag: Dictionary = {}
var _hammer: Sprite2D
var _hammer_tw: Tween
var _t := 0.0
var _round_nodes: Array = []
var _smoke: Array = []


func _ready() -> void:
	home_target = "dino"
	var s := UI.vs(self)
	for i in 2:
		Scenery.cloud(self, Vector2(s.x * (0.25 + 0.45 * i), s.y * (0.10 + 0.08 * i)), 1.1 + 0.2 * i, -40)
	var bg := Sprite2D.new()
	bg.texture = load("res://art/wall/bg-wall.png")
	var bt := bg.texture.get_size()
	bg.position = s / 2.0
	bg.scale = Vector2(s.x / bt.x, s.y / bt.y)
	bg.z_index = -50
	add_child(bg)
	_hammer = Sprite2D.new()
	_hammer.texture = load("res://art/wall/hammer.png")
	_hammer.scale = Vector2.ONE * ((s.y * 0.26) / _hammer.texture.get_size().y)
	# Drška je dole-desno, glava gore-levo; okreće se oko donjeg kraja drške.
	_hammer.offset = Vector2(0, -_hammer.texture.get_size().y * 0.5)
	_hammer.z_index = 30
	_hammer.visible = false
	add_child(_hammer)
	# Dim iz oba vulkana, kao na jajima.
	_build_smoke(s, 0.156, 0.345, 0.085)
	_build_smoke(s, 0.599, 0.425, 0.070)
	# Žbunje ispred reda kandidata — dinosaurusi stoje u travi, ne lebde.
	for b in [[0.12, 0.995, 0.16], [0.48, 1.0, 0.13]]:
		var bush := Sprite2D.new()
		bush.texture = load("res://art/dino/bush.png")
		var bsz := bush.texture.get_size()
		bush.scale = Vector2.ONE * ((s.x * float(b[2])) / bsz.x)
		bush.offset = Vector2(0, -bsz.y / 2.0)
		bush.position = Vector2(s.x * float(b[0]), s.y * float(b[1]))
		bush.z_index = 12   # ispod kandidata (14)
		add_child(bush)
	# Dva različita žbuna u podnožju gomile, ISPRED kamenja (z iznad svih
	# redova gomile, ispod čekića i kandidata dok se vuku).
	# Levo je žbunasta paprat (isti crtež kao na hubu), desno visoka trava.
	for b in [["dino/fern3", 0.585, 0.965, 0.135], ["wall/bush1", 0.950, 0.915, 0.080]]:
		var pb := Sprite2D.new()
		pb.texture = load("res://art/%s.png" % b[0])
		var pt := pb.texture.get_size()
		pb.scale = Vector2.ONE * ((s.x * float(b[3])) / pt.x)
		pb.offset = Vector2(0, -pt.y / 2.0)
		pb.position = Vector2(s.x * float(b[1]), s.y * float(b[2]))
		pb.z_index = 18
		add_child(pb)
	_build_round(s)
	add_home_button()
	add_hint(5.0)
	set_process(true)


func _build_round(s: Vector2) -> void:
	for n in _round_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_round_nodes.clear()
	_bricks.clear()
	_cands.clear()
	_drag = {}
	_gone = 0
	_phase = 0
	_target = _round % SPECIES.size()
	var sp: Dictionary = SPECIES[_target]

	# Senka iza zida, stoji na tlu.
	_sil = Sprite2D.new()
	_sil.texture = load("res://art/wall/sil-%s.png" % sp.id)
	var st := _sil.texture.get_size()
	var sc: float = (s.y * float(sp.h)) / st.y
	_sil.scale = Vector2(sc, sc)
	_sil.offset = Vector2(0, -st.y / 2.0)
	_sil.position = Vector2(s.x * 0.76, s.y * 0.88)
	_sil.z_index = 1
	add_child(_sil)
	_round_nodes.append(_sil)
	_sil_pos = _sil.position + Vector2(0, -st.y * sc * 0.5)

	# Gomila kamenja ispred senke.
	for i in PILE.size():
		var d: Array = PILE[i]
		var b := Sprite2D.new()
		b.texture = load("res://art/wall/rock%d.png" % int(d[3]))
		var ts: Vector2 = b.texture.get_size()
		var rs: float = (s.x * float(d[2])) / ts.x
		b.scale = Vector2(rs, rs)
		b.flip_h = bool(d[4])
		b.offset = Vector2(0, -ts.y / 2.0)
		b.position = Vector2(s.x * (0.76 + float(d[0])), s.y * (0.90 - float(d[1])))
		b.z_index = 5 + (PILE.size() - i)   # niži red ispred višeg
		add_child(b)
		_round_nodes.append(b)
		var area := Area2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = ts * 0.9
		shape.shape = rect
		shape.position = Vector2(0, -ts.y / 2.0)
		area.add_child(shape)
		b.add_child(area)
		var idx := _bricks.size()
		area.input_event.connect(func(_vp: Node, ev: InputEvent, _i: int) -> void:
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				get_viewport().set_input_as_handled()
				_hit_brick(idx)
		)
		_bricks.append({"node": b, "kind": int(d[3]), "hits": 0, "gone": false, "pos": b.position + Vector2(0, -ts.y * rs * 0.5), "w": ts.x * rs})


## Udarac čekićem: čekić se pojavi uz kamen, zamahne i udari; kamen napukne
## (prvi udarac) pa se raspadne (drugi) uz kišu kamenčića.
func _hit_brick(idx: int) -> void:
	if _phase != 0:
		return
	var br: Dictionary = _bricks[idx]
	if br.gone:
		return
	_swing(br.pos)
	br.hits += 1
	UI.haptic(30)
	Audio.play("rock_hit", 0.0, randf_range(0.92, 1.08))
	var node: Sprite2D = br.node
	if br.hits < HITS:
		# Prvi udarac: kamen se zatrese i napukne (iste pukotine kao na jajima).
		UI.bounce(node, node.scale)
		node.texture = load("res://art/wall/rock%d-crack.png" % int(br.kind))
	else:
		br.gone = true
		_gone += 1
		Audio.play("rock_break", 0.0, randf_range(0.9, 1.1))
		_shatter(br)
		if _phase == 0 and float(_gone) / float(_bricks.size()) >= REVEAL:
			_collapse()


## Kad je dovoljno srušeno, ostatak se sam obruši — jedan po jedan, da se
## senka vidi cela, a dete ne traži poslednji kamen.
func _collapse() -> void:
	_phase = -1
	var tw := create_tween()
	for i in _bricks.size():
		var br: Dictionary = _bricks[i]
		if br.gone:
			continue
		tw.tween_interval(0.13)
		tw.tween_callback(func() -> void:
			br.gone = true
			_shatter(br)
			Audio.play("rock_break", -8.0, randf_range(0.9, 1.15))
		)
	tw.tween_interval(0.5)
	tw.tween_callback(_start_choice)


func _shatter(br: Dictionary) -> void:
	var node: Sprite2D = br.node
	node.visible = false
	var fx := Sprite2D.new()
	fx.texture = load("res://art/wall/break-1.png")
	fx.scale = Vector2.ONE * (float(br.w) * 1.6 / 256.0)
	fx.position = br.pos
	fx.z_index = node.z_index + 1
	add_child(fx)
	var tw := create_tween()
	for i in 8:
		var f := i + 1
		tw.tween_callback(func() -> void: fx.texture = load("res://art/wall/break-%d.png" % f))
		tw.tween_interval(0.05)
	tw.tween_callback(fx.queue_free)


## Zamah čekića: pojavi se uz kamen, zamahne, udari, pa nestane. Ne stoji
## na ekranu stalno — dete ga vidi samo kad tapne.
func _swing(at: Vector2) -> void:
	var s := UI.vs(self)
	if _hammer_tw and _hammer_tw.is_valid():
		_hammer_tw.kill()
	_hammer.visible = true
	_hammer.modulate.a = 1.0
	_hammer.position = at + Vector2(s.x * 0.05, s.y * 0.07)
	_hammer.rotation = deg_to_rad(40.0)
	_hammer_tw = create_tween()
	_hammer_tw.tween_property(_hammer, "rotation", deg_to_rad(-35.0), 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	_hammer_tw.tween_property(_hammer, "rotation", deg_to_rad(25.0), 0.16).set_trans(Tween.TRANS_BACK)
	_hammer_tw.tween_interval(0.3)
	_hammer_tw.tween_property(_hammer, "modulate:a", 0.0, 0.2)
	_hammer_tw.tween_callback(func() -> void: _hammer.visible = false)


## Kandidati: pravi + dva druga, izmešani, dole levo. Svaki diše (frejmovi
## stajanja), i svaki se može prevući.
func _start_choice() -> void:
	_phase = 1
	Audio.play("success")
	var s := UI.vs(self)
	var others: Array = []
	for i in SPECIES.size():
		if i != _target:
			others.append(i)
	others.shuffle()
	var picks: Array = [_target, others[0], others[1]]
	picks.shuffle()
	for k in picks.size():
		var sp: Dictionary = SPECIES[picks[k]]
		var frames: Array = []
		for i in int(sp.n):
			frames.append(load("res://art/lava/%s-%d.png" % [sp.idle, i + 1]))
		var node := Sprite2D.new()
		node.texture = frames[0]
		var ft: Vector2 = frames[0].get_size()
		var sc: float = (s.y * float(sp.h) * 0.82) / ft.y   # isti odnos veličina kao u senci
		node.scale = Vector2(sc, sc)
		node.offset = Vector2(0, -ft.y / 2.0)
		var home := Vector2(s.x * (0.12 + 0.19 * k), s.y * 1.0)
		node.position = home + Vector2(0, s.y * 0.30)    # dolaze odozdo
		node.z_index = 14
		add_child(node)
		_round_nodes.append(node)
		var tw := create_tween()
		tw.tween_interval(0.12 * k)
		tw.tween_property(node, "position", home, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		_cands.append({"node": node, "frames": frames, "sp": picks[k], "home": home, "correct": picks[k] == _target, "f": randf() * 20.0})


## Dodir kao i u ostalim igrama: samo miš-događaji (dodir se emulira kao miš).
func _input(event: InputEvent) -> void:
	if _phase != 1:
		return
	var s := UI.vs(self)
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed and _drag.is_empty():
			var best: Dictionary = {}
			var bd: float = s.x * 0.12
			for c in _cands:
				var n: Sprite2D = c.node
				var d: float = event.position.distance_to(n.position + Vector2(0, -s.y * 0.18))
				if d < bd:
					bd = d
					best = c
			if not best.is_empty():
				_drag = best
				best.node.z_index = 20
				Audio.play("pluck")
		elif not event.pressed and not _drag.is_empty():
			_drop(s)
	elif event is InputEventMouseMotion and not _drag.is_empty():
		_drag.node.position = event.position + Vector2(0, s.y * 0.18)


func _drop(s: Vector2) -> void:
	var c: Dictionary = _drag
	_drag = {}
	var n: Sprite2D = c.node
	n.z_index = 14
	var near: bool = (n.position + Vector2(0, -s.y * 0.18)).distance_to(_sil_pos) < s.x * 0.16
	if not near or not c.correct:
		if near:
			# Pogrešan: "no no no" — glas + odmahivanje, pa nazad. Bez kazne.
			Audio.play("wrong", -4.0)
			UI.head_shake(n)
		var tw := create_tween()
		tw.tween_property(n, "position", c.home, 0.3).set_trans(Tween.TRANS_BACK)
		return
	_phase = 2
	_sil.z_index = 0
	var tw2 := create_tween()
	tw2.tween_property(n, "position", _sil.position, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw2.parallel().tween_property(n, "scale", _sil.scale, 0.18)
	tw2.tween_callback(func() -> void:
		UI.haptic(40)
		Audio.play(["yay", "giggle", "kid"][randi() % 3], -2.0)
		_charge(_sil_pos, s.y * 0.44)
		var tw3 := create_tween()
		tw3.tween_property(_sil, "modulate:a", 0.0, 0.3)
		for o in _cands:
			if o.node != n:
				tw3.parallel().tween_property(o.node, "position", o.home + Vector2(0, s.y * 0.30), 0.35)
	)
	tw2.tween_interval(2.8)
	tw2.tween_callback(func() -> void:
		_round += 1
		_build_round(s)
	)


func _charge(pos: Vector2, height: float) -> void:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/fx/charge-1.png")
	sp.scale = Vector2.ONE * (height / sp.texture.get_size().y)
	sp.position = pos
	sp.z_index = 25
	add_child(sp)
	var tw := create_tween()
	for i in 10:
		var idx := i + 1
		tw.tween_callback(func() -> void: sp.texture = load("res://art/fx/charge-%d.png" % idx))
		tw.tween_interval(0.07)
	tw.tween_callback(sp.queue_free)


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


func _process(delta: float) -> void:
	_t += delta
	_process_smoke(delta, UI.vs(self))
	for c in _cands:
		c.f += delta * 9.0
		var fr: Array = c.frames
		var n: Sprite2D = c.node
		if is_instance_valid(n):
			n.texture = fr[int(c.f) % fr.size()]


## Pokazivač: dok se ruši, tap na neki ceo blok; posle, prevlačenje pravog
## kandidata na senku.
func hint_spot() -> Dictionary:
	var s := UI.vs(self)
	if _phase == 0:
		for br in _bricks:
			if not br.gone:
				return {"at": br.pos, "size": 1.6}
		return {}
	if _phase == 1:
		for c in _cands:
			if c.correct:
				return {"from": c.node.position + Vector2(0, -s.y * 0.18), "to": _sil_pos, "size": 1.4}
	return {}
