extends BaseScreen
## Mini-igra: SORTIRAJ PO BOJI (okean). Na dnu stoje koralne posude — iste po
## obliku, različite po boji. Ribice plivaju u vodi i dete ih prevlači u posudu
## svoje boje.
##
## Posude MORAJU biti identičnog oblika: da se razlikuju i po obliku, dete bi
## zadatak rešavalo gledajući oblik i boju nikad ne bi ni pogledalo. Iz istog
## razloga je i ribica uvek ista, samo u drugoj boji.
##
## Pogrešna posuda ne kažnjava — samo odbije ribicu i ona otpliva nazad.

const COLORS := ["red", "yellow", "blue", "green"]
## Referentni telefon na kome je igra podesena (19,5:9 → viewport 2340x1080).
const REF := Vector2(2340.0, 1080.0)

const NEED := 6              # koliko ribica čini rundu
const SWIM_FRAMES := 4
const BOWL_W := 0.155
const FISH_W := 0.085
const IN_WATER := 3          # koliko ribica pliva istovremeno
## Otvor posude u njenom sopstvenom fajlu (360×300).
const MOUTH := Vector2(0.500, 0.42)

var _s := Vector2.ZERO
var _t := 0.0
var _round := 1
var _done := 0
var _bowls: Array = []       # {node, color, mouth, kept}
var _fishes: Array = []      # {node, color, drag, grab, ph, busy}
var _bubbles: Array = []
var _bub_in := 0.0
var _hint: Node2D
var _hint_fish: Dictionary = {}
var _idle := 0.0
var _busy_round := false
var _sub: Sprite2D
var _sub_frames: Array = []
var _sub_bub := 0.0
var _chests: Array = []
var _deco: Array = []


func _ready() -> void:
	home_target = "ocean"
	_s = UI.vs(self)
	Scenery.background(self, "background-colors")
	_scenery()
	_build_deco()
	_build_bowls()
	# Na startu su sve tri VEĆ u vodi; ranije su dolazile odozgo pa je prvih
	# desetak sekundi na ekranu bila samo jedna i delovalo je prazno.
	for i in IN_WATER:
		_spawn_fish(0.20 + 0.13 * float(i))
	add_home_button()
	_show_hint()
	set_process(true)
	set_process_input(true)


## Trava uz same ivice i mehurići — pozadina je namerno bleda zbog bojа, ali
## prazna voda je bila dosadna. Trava je siva-zelena i tiha, da ne uleti u
## zadatak sa još jednom bojom.
## Podmornica polako prolazi u dubini iza svega — daje pokret i priču bez ijedne
## nove boje koja bi ušla u zadatak. Sanduci i zvezde popunjavaju pesak.
func _build_deco() -> void:
	# Frejmova ima tačno onoliko koliko fajlova postoji — kad se tražilo 25 a
	# postoji 24, dvadeset peti se učita kao ništa i podmornica trepne.
	for i in 24:
		_sub_frames.append(load("res://art/svg/submarine-%d.svg" % (i + 1)))
	_sub = Sprite2D.new()
	_sub.texture = _sub_frames[0]
	_sub.scale = Vector2.ONE * ((_s.x * 0.16) / 600.0)
	_sub.position = Vector2(-_s.x * 0.2, _s.y * 0.20)
	_sub.modulate = Color(1, 1, 1, 0.65)
	_sub.z_index = 0
	add_child(_sub)



## Ukras se pravi zajedno sa posudama jer im se broj menja (od treće runde ih
## je četiri). Sanduci su UVEK iste veličine i stoje između posuda: kod tri
## posude u oba razmaka, kod četiri u drugom i trećem — dakle žuto-plavo i
## plavo-zeleno, da ne zatrpaju levu stranu.
func _sand_deco() -> void:
	for d in _deco:
		if is_instance_valid(d):
			d.queue_free()
	_deco.clear()
	for c in _chests:
		if is_instance_valid(c.node):
			c.node.queue_free()
	_chests.clear()

	var gaps: Array = []
	for i in _bowls.size() - 1:
		gaps.append(((_bowls[i].node as Sprite2D).position.x
			+ (_bowls[i + 1].node as Sprite2D).position.x) * 0.5 / _s.x)
	var pick: Array = [0, 1] if gaps.size() < 3 else [1, 2]
	var waits := [5.0, 15.0]
	for k in pick.size():
		if pick[k] < gaps.size():
			_add_chest(float(gaps[pick[k]]), waits[k])

	for spec in [[0.215, "starfish-sand"], [0.795, "starfish-sand-orange"]]:
		var st := Sprite2D.new()
		st.texture = load("res://art/svg/%s.svg" % spec[1])
		var stx := st.texture.get_size()
		st.scale = Vector2.ONE * ((_s.x * 0.075) / stx.x)
		st.offset = Vector2(0, -stx.y / 2.0)
		st.position = Vector2(_s.x * float(spec[0]), _s.y * 0.995)
		st.z_index = 2
		add_child(st)
		_deco.append(st)


func _add_chest(x: float, first_wait: float) -> void:
	var sc := (_s.x * 0.098) / 520.0
	var node := Node2D.new()
	node.position = Vector2(_s.x * x, _s.y * 0.985 - 400.0 * sc * 0.5)
	node.scale = Vector2.ONE * sc
	node.z_index = 2
	add_child(node)

	var lid := Sprite2D.new()
	lid.texture = load("res://art/svg/chest-lid.svg")
	var t := lid.texture.get_size()
	lid.offset = -Vector2((0.047 - 0.5) * t.x, (0.904 - 0.5) * t.y)
	lid.position = Vector2((0.169 - 0.5) * 520.0, (0.480 - 0.5) * 400.0)
	lid.z_index = -1
	node.add_child(lid)

	var body := Sprite2D.new()
	body.texture = load("res://art/svg/chest-body.svg")
	node.add_child(body)
	var c := {"node": node, "lid": lid, "open": 0.0, "left": 0, "gap": 0.0,
		"wait": first_wait, "emit": Vector2(_s.x * x, _s.y * 0.90)}
	_chests.append(c)

	# Deca su u hubu tražila da sanduk mogu i sama da otvore; isto važi i ovde.
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(440.0, 340.0)
	shape.shape = rect
	shape.position = Vector2(0.0, 30.0)
	area.add_child(shape)
	node.add_child(area)
	area.input_event.connect(func(_vp: Node, ev: InputEvent, _i: int) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			c.left = mini(c.left + randi_range(8, 14), 28)
			c.gap = 0.0
			c.wait = randf_range(16.0, 28.0)
			UI.haptic(22)
	)


func _scenery() -> void:
	# Trava mora biti IZVAN najkrajnjih posuda, inače posuda stane preko nje.
	# Krajnja posuda kod tri komada seže do ~0,09 širine, pa trava ide ispod toga.
	for spec in [[0.020, 0.30], [0.062, 0.22], [0.980, 0.30], [0.938, 0.22]]:
		var sp := Sprite2D.new()
		sp.texture = load("res://art/svg/seaweed-clump-medium.svg")
		var tex := sp.texture.get_size()
		# Pozicije skoljki su udeo SIRINE, pa i velicina mora u sirinskoj meri.
		# Vezana za _s.y, na iPadu skoljka naraste a razmak ostane isti.
		# Na referentnom telefonu daje tacno staru vrednost (_s.x = REF.x).
		sp.scale = Vector2.ONE * ((REF.y * (_s.x / REF.x) * spec[1]) / tex.y)
		if spec[0] > 0.5:
			sp.scale.x *= -1.0
		sp.offset = Vector2(0, -tex.y / 2.0)
		sp.position = Vector2(_s.x * spec[0], _s.y * 1.01)
		sp.modulate = Color(0.72, 0.78, 0.74, 0.55)
		sp.z_index = 1
		add_child(sp)


func _palette() -> Array:
	return COLORS.slice(0, 3) if _round < 3 else COLORS


func _build_bowls() -> void:
	for b in _bowls:
		if is_instance_valid(b.node):
			b.node.queue_free()
		for k in b.kept:
			if is_instance_valid(k):
				k.queue_free()
	_bowls.clear()

	var pal := _palette()
	for i in pal.size():
		var col: String = pal[i]
		var x: float = (float(i) + 0.5) / float(pal.size())
		var sp := Sprite2D.new()
		sp.texture = load("res://art/svg/coral-bowl-%s.svg" % col)
		var tex := sp.texture.get_size()
		var sc := (_s.x * BOWL_W) / tex.x
		sp.scale = Vector2.ONE * sc
		sp.offset = Vector2(0, -tex.y / 2.0)
		sp.position = Vector2(_s.x * x, _s.y * 0.95)
		sp.z_index = 3
		add_child(sp)
		_bowls.append({"node": sp, "color": col, "base": Vector2.ONE * sc,
			"mouth": sp.position + Vector2(0, (MOUTH.y - 1.0) * tex.y * sc),
			"kept": []})
	_sand_deco()


func _spawn_fish(at_y := 0.19) -> void:
	var pal := _palette()
	var sp := Sprite2D.new()
	var col: String = pal[randi() % pal.size()]
	sp.texture = load("res://art/svg/sortfish-%s-1.svg" % col)
	sp.scale = Vector2.ONE * ((_s.x * FISH_W) / 256.0)
	sp.position = Vector2(_s.x * randf_range(0.15, 0.85), _s.y * at_y)
	sp.z_index = 6
	add_child(sp)
	_fishes.append({"node": sp, "color": col, "drag": false,
		"grab": Vector2.ZERO, "ph": randf() * TAU, "busy": false})


# --------------------------------------------------------------- nagoveštaj

## Na početku runde se pokaže šta se traži: prsten oko jedne ribice i tačkice
## do posude njene boje. Bez teksta i bez glasa, jer igra nema ni jedno ni
## drugo — pokazivanje je jedini jezik koji ovaj uzrast razume odmah.
func _show_hint() -> void:
	if _fishes.is_empty():
		return
	_hint_fish = _fishes[0]
	if _hint == null:
		_hint = Node2D.new()
		_hint.z_index = 5
		UI.circle(_hint, Vector2.ZERO, _s.x * FISH_W * 0.85, Color(1, 1, 1, 0.32))
		add_child(_hint)
	_hint.visible = true
	var target := Vector2.ZERO
	for b in _bowls:
		if b.color == _hint_fish.color:
			target = b.mouth
	if target == Vector2.ZERO:
		return
	for i in 12:
		var p: Vector2 = (_hint_fish.node as Sprite2D).position.lerp(target, float(i) / 11.0)
		get_tree().create_timer(1.1 + i * 0.075).timeout.connect(_dot.bind(p))


func _dot(p: Vector2) -> void:
	if not is_inside_tree():
		return
	var sp := Sprite2D.new()
	# Bledi mehurić se na svetlom pesku ne vidi, pa je tačkica krupniji mehurić
	# sa tamnijim tonom — putanja mora da bude očigledna iz prvog pogleda.
	sp.texture = load("res://art/svg/bubble.svg")
	sp.position = p
	sp.scale = Vector2.ONE * (_s.x * 0.030 / 200.0)
	sp.modulate = Color(0.42, 0.56, 0.66, 0.0)
	sp.z_index = 4
	add_child(sp)
	var tw := sp.create_tween()
	tw.tween_property(sp, "modulate:a", 0.95, 0.15)
	tw.tween_interval(0.9)
	tw.tween_property(sp, "modulate:a", 0.0, 0.4)
	tw.tween_callback(sp.queue_free)


# -------------------------------------------------------------------- unos

func _input(event: InputEvent) -> void:
	if _busy_round:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			var best: Dictionary = {}
			var bd := _s.x * FISH_W * 1.1
			for f in _fishes:
				if f.busy or not is_instance_valid(f.node):
					continue
				var d: float = event.position.distance_to(f.node.position)
				if d < bd:
					bd = d
					best = f
			if not best.is_empty():
				best.drag = true
				best.grab = best.node.position - event.position
				_hint.visible = false
		else:
			for f in _fishes:
				if f.drag:
					f.drag = false
					_drop(f)
	elif event is InputEventMouseMotion:
		for f in _fishes:
			if not f.drag or not is_instance_valid(f.node):
				continue
			f.node.position = event.position + f.grab
			f.node.position.x = clampf(f.node.position.x, _s.x * 0.04, _s.x * 0.96)
			# Gornja granica je NISKO namerno: ako dete prevuče prst do same
			# ivice ekrana, Android spusti statusnu traku i izbaci ga iz igre.
			f.node.position.y = clampf(f.node.position.y, _s.y * 0.17, _s.y * 0.92)


func _drop(f: Dictionary) -> void:
	var best: Dictionary = {}
	var best_d := _s.x * 0.13          # velikodušno: dete ne mora precizno
	for b in _bowls:
		var d: float = f.node.position.distance_to(b.mouth)
		if d < best_d:
			best_d = d
			best = b
	if best.is_empty():
		return
	if best.color == f.color:
		_accept(f, best)
	else:
		_refuse(f, best)


func _accept(f: Dictionary, b: Dictionary) -> void:
	f.busy = true
	Audio.play("plop", -4.0, randf_range(0.98, 1.10))
	UI.haptic(30)
	var tw: Tween = f.node.create_tween()
	tw.set_parallel(true)
	tw.tween_property(f.node, "position", b.mouth + Vector2(0, _s.y * 0.015), 0.30)
	tw.tween_property(f.node, "scale", f.node.scale * 0.4, 0.30)
	tw.tween_property(f.node, "modulate:a", 0.0, 0.22).set_delay(0.10)
	tw.chain().tween_callback(func() -> void:
		_keep(f, b)
		f.node.queue_free()
		_fishes.erase(f)
		_after_accept())
	var bt: Tween = b.node.create_tween()
	bt.tween_property(b.node, "scale", b.base * Vector2(1.08, 0.92), 0.10)
	bt.tween_property(b.node, "scale", b.base, 0.16)


## Skupljena ribica ostaje da viri iz posude — za ovaj uzrast je to jedini
## brojač koji nešto znači.
func _keep(f: Dictionary, b: Dictionary) -> void:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/svg/sortfish-%s-1.svg" % f.color)
	sp.scale = Vector2.ONE * ((_s.x * 0.030) / 256.0)
	var i: int = b.kept.size()
	sp.position = b.mouth + Vector2((float(i % 3) - 1.0) * _s.x * 0.032,
		-_s.y * 0.012 - float(i / 3) * _s.y * 0.028)
	sp.z_index = 4
	add_child(sp)
	b.kept.append(sp)


func _after_accept() -> void:
	_done += 1
	if _done < NEED:
		get_tree().create_timer(0.35).timeout.connect(func() -> void:
			if not _busy_round:
				_spawn_fish())
		return
	_done = 0
	_round += 1
	_busy_round = true
	_celebrate()
	# Preostale ribice odmah otplivaju uvis i nestanu; ranije su stajale
	# zamrznute dok ne stignu nove, što je izgledalo kao da se igra zaglavila.
	for f in _fishes:
		if not is_instance_valid(f.node):
			continue
		f.busy = true
		var ft: Tween = f.node.create_tween()
		ft.set_parallel(true)
		ft.tween_property(f.node, "position:y", -_s.y * 0.15, 0.9).set_trans(Tween.TRANS_SINE)
		ft.tween_property(f.node, "modulate:a", 0.0, 0.8).set_delay(0.1)
	get_tree().create_timer(2.2).timeout.connect(func() -> void:
		for f in _fishes:
			if is_instance_valid(f.node):
				f.node.queue_free()
		_fishes.clear()
		_build_bowls()
		for i in IN_WATER:
			_spawn_fish(0.20 + 0.13 * float(i))
		_busy_round = false
		_show_hint())


func _refuse(f: Dictionary, b: Dictionary) -> void:
	Audio.play("tap", -8.0)
	var bt: Tween = b.node.create_tween()
	bt.tween_property(b.node, "scale", b.base * Vector2(1.06, 0.94), 0.08)
	bt.tween_property(b.node, "scale", b.base, 0.14)
	f.busy = true
	var back := Vector2(f.node.position.x, _s.y * randf_range(0.28, 0.42))
	var tw: Tween = f.node.create_tween()
	tw.tween_property(f.node, "position", back, 0.45).set_trans(Tween.TRANS_SINE)
	tw.tween_callback(func() -> void: f.busy = false)


func _celebrate() -> void:
	Audio.play(["yay", "giggle", "kid"][randi() % 3], -2.0)
	var center := Vector2(_s.x * 0.5, _s.y * 0.5)
	for i in 24:
		var ang := randf() * TAU
		var start: Vector2 = center + Vector2(cos(ang), sin(ang)) * _s.x * randf_range(0.01, 0.14)
		var sp := Sprite2D.new()
		sp.texture = load("res://art/svg/bubble.svg")
		sp.position = start
		sp.z_index = 9
		var s0: float = _s.x * randf_range(0.008, 0.022) / 200.0
		sp.scale = Vector2.ONE * s0
		add_child(sp)
		var dur: float = randf_range(0.7, 1.2)
		var tw := sp.create_tween()
		tw.set_parallel(true)
		tw.tween_property(sp, "scale", Vector2.ONE * s0 * randf_range(6.0, 11.0), dur).set_ease(Tween.EASE_IN)
		tw.tween_property(sp, "position", start + Vector2.from_angle(ang) * _s.x * randf_range(0.25, 0.6), dur).set_ease(Tween.EASE_IN)
		tw.tween_property(sp, "modulate:a", 0.0, dur * 0.4).set_delay(dur * 0.6)
		tw.finished.connect(sp.queue_free)


# ------------------------------------------------------------------- proces

func _process(delta: float) -> void:
	_t += delta

	# ambijentalni mehurići — voda je bez njih delovala mrtvo
	_bub_in -= delta
	if _bub_in <= 0.0:
		_bub_in = randf_range(0.5, 1.1)
		var sp := Sprite2D.new()
		sp.texture = load("res://art/svg/bubble-trail-mid-1.svg")
		sp.position = Vector2(_s.x * randf_range(0.03, 0.97), _s.y * 1.03)
		sp.scale = Vector2.ONE * (_s.x * randf_range(0.010, 0.022) / 96.0)
		sp.z_index = 1
		sp.modulate.a = 0.7
		add_child(sp)
		_bubbles.append({"node": sp, "x0": sp.position.x, "ph": randf() * TAU,
			"v": randf_range(0.05, 0.11)})

	for i in range(_bubbles.size() - 1, -1, -1):
		var b: Dictionary = _bubbles[i]
		if not is_instance_valid(b.node):
			_bubbles.remove_at(i)
			continue
		b.node.position.y -= _s.y * b.v * delta
		b.node.position.x = b.x0 + sin(_t * 1.9 + b.ph) * _s.x * 0.006
		if b.node.position.y < -_s.y * 0.05:
			b.node.queue_free()
			_bubbles.remove_at(i)

	var any_drag := false
	for f in _fishes:
		if not is_instance_valid(f.node):
			continue
		if f.drag:
			any_drag = true
		elif not f.busy:
			# Nova ribica koja je ušla previsoko brzo se spusti ispod te granice.
			if f.node.position.y < _s.y * 0.17:
				f.node.position.y += _s.y * 0.55 * delta
			# Ribica lagano tone; kad dođe do posuda VRAĆA se naviše umesto da
			# se teleportuje na vrh — ranije je izgledalo kao da je nestala.
			var y: float = f.node.position.y
			f.node.position.y += _s.y * (0.040 if y < _s.y * 0.62 else -0.055) * delta
			f.node.position.x += sin(_t * 1.2 + f.ph) * _s.x * 0.0007
		var fr := 1 + int(_t * 9.0 + f.ph) % SWIM_FRAMES
		f.node.texture = load("res://art/svg/sortfish-%s-%d.svg" % [f.color, fr])
		f.node.rotation = sin(_t * 2.0 + f.ph) * 0.06

	# Podmornica i sanduci
	_sub.texture = _sub_frames[int(_t * 10.0) % _sub_frames.size()]
	var su: float = fmod(_t / 40.0, 1.0)
	_sub.position.x = lerpf(-_s.x * 0.20, _s.x * 1.20, su)
	_sub.position.y = _s.y * (0.20 + 0.02 * sin(_t * 0.6))
	# Trag mehurića iza podmornice — bez njega izgleda kao nalepnica koja klizi.
	# Iza krme izlazi SKUPINA mehurića, po tri odjednom i krupnijih. Pojedinačne
	# sitne tačkice su na ovoj bledoj pozadini bile nevidljive.
	_sub_bub -= delta
	if _sub_bub <= 0.0 and _sub.position.x > -_s.x * 0.06 and _sub.position.x < _s.x * 1.06:
		_sub_bub = randf_range(0.14, 0.26)
		for k in 3:
			var sb := Sprite2D.new()
			sb.texture = load("res://art/svg/bubble-trail-mid-1.svg")
			sb.position = _sub.position + Vector2(-_s.x * 0.082,
				_s.y * randf_range(-0.010, 0.022)) + Vector2(randf_range(-0.012, 0.006) * _s.x, 0)
			sb.scale = Vector2.ONE * (_s.x * randf_range(0.013, 0.026) / 96.0)
			sb.z_index = 0
			sb.modulate.a = 0.85
			add_child(sb)
			_bubbles.append({"node": sb, "x0": sb.position.x, "ph": randf() * TAU,
				"v": randf_range(0.05, 0.10)})
	for c in _chests:
		var want: float = 1.0 if c.left > 0 else 0.0
		c.open = move_toward(c.open, want, delta * (2.6 if want > 0.0 else 0.7))
		c.lid.rotation = deg_to_rad(-22.0) * ease(c.open, 0.6)
		if c.left > 0:
			c.gap -= delta
			if c.gap <= 0.0:
				c.gap = randf_range(0.06, 0.13)
				c.left -= 1
				var bs := Sprite2D.new()
				bs.texture = load("res://art/svg/bubble-trail-mid-1.svg")
				bs.position = c.emit + Vector2(randf_range(-0.02, 0.02) * _s.x, 0)
				bs.scale = Vector2.ONE * (_s.x * randf_range(0.010, 0.020) / 96.0)
				bs.z_index = 2
				add_child(bs)
				_bubbles.append({"node": bs, "x0": bs.position.x,
					"ph": randf() * TAU, "v": randf_range(0.07, 0.13)})
		else:
			c.wait -= delta
			if c.wait <= 0.0:
				c.wait = randf_range(18.0, 32.0)
				c.left = randi_range(9, 15)
				c.gap = 0.0

	# prsten prati ribicu iz nagoveštaja dok dete ne krene
	if _hint != null and _hint.visible:
		if any_drag or _hint_fish.is_empty() or not is_instance_valid(_hint_fish.get("node")):
			_hint.visible = false
		else:
			_hint.position = _hint_fish.node.position
			_hint.scale = Vector2.ONE * (1.0 + 0.12 * sin(_t * 3.4))
