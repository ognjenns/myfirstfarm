extends BaseScreen
## Mini-igra: Okupaj prase — pravo KUPATILO (Claude Design asseti).
## Faze: BLATO (trljaj prstom ili sunđerom) → PENA → TUŠ → SREĆA, pa ispočetka.
## Bonus: gumena patkica na ivici kade — tap = "kva!".

enum Phase { MUD, FOAM, SHOWER, HAPPY }

const RUB_RADIUS := 110.0

var pig_pos := Vector2.ZERO
var phase: int = Phase.MUD
var bather: FarmBody
var mud_blobs: Array[Sprite2D] = []
var foam_blobs: Array[Sprite2D] = []
var foam_progress := 0.0
var rubbing := false
var _scrub_cooldown := 0.0
var _bubble_cooldown := 0.0
var rain: CPUParticles2D
var sponge: Area2D
var sponge_home := Vector2.ZERO
var sponge_drag := false
var bather_scale := 1.0
var _bath_queue: Array = []
var _hint_cooldown := 0.0
var _sponge_pulse: Tween = null
var _sponge_idle := 0.0
var _fall: Sprite2D
var _drip: CPUParticles2D
var _splash: Sprite2D
var _tub_center := Vector2.ZERO
var _water_y := 0.0
var _fall_f := 0.0
## Raspored po visini ekrana (_lh = visina ekrana, _oy = 0). Uklapanje sobe
## po širini na iPadu je probano i odbačeno (Ognjen: ružno) — soba se seče sa
## strane kao i pre, samo je životinja manja na uskom ekranu.
var _oy := 0.0
var _lh := 0.0

func _ly(f: float) -> float:
	return _oy + _lh * f

func _ready() -> void:
	var s := UI.vs(self)
	_build_room(s)
	add_home_button()
	add_hint(6.0)

	# Sredina scene je prazna: tu stoji životinja koja se pere, na podu.
	_tub_center = Vector2(s.x * 0.52, _ly(0.97))
	_water_y = _ly(0.97)
	pig_pos = _tub_center
	_next_bather(false)

	# Tuš iz paketa na zidu iznad životinje, na mestu bivšeg lustera.
	# Tuš koji visi sa plafona (crtež "shower" iz paketa), daleko od šolje.
	_prop("shower", 0.10, 0.52, 0.40, -50)
	_make_rain(Vector2(s.x * 0.52, _ly(0.18)), _lh * 0.95)   # sa donje ivice glave tuša
	_fall = Sprite2D.new()
	_fall.texture = load("res://art/bath/fall-1.png")
	var ft := _fall.texture.get_size()
	var fsc: float = (_lh * 0.86 - _lh * 0.27) / ft.y
	_fall.scale = Vector2(fsc, fsc)
	_fall.offset = Vector2(0, ft.y / 2.0)
	_fall.position = Vector2(s.x * 0.55, _ly(0.27))
	_fall.z_index = 12
	_fall.visible = false
	add_child(_fall)
	_splash = Sprite2D.new()
	_splash.texture = load("res://art/bath/splash-1.png")
	var spt := _splash.texture.get_size()
	_splash.scale = Vector2.ONE * ((s.x * 0.20) / spt.x)
	_splash.offset = Vector2(0, -spt.y / 2.0)
	_splash.position = Vector2(s.x * 0.52, _ly(0.97))
	_splash.z_index = 17
	_splash.visible = false
	add_child(_splash)

	_make_sponge(Vector2(s.x * 0.93, _ly(0.92)), (s.x * 0.075) / 136.0)   # skroz desno, na podu
	_spawn_mud()

## Sledeća životinja ulazi u kadu (promešan redosled, bez ponavljanja dok krug ne prođe).
## Prostorija iz kupljenog paketa (bathroom interior): pločice, lampa,
## prozor, ormar, polica sa bočicama, ogledalo, peškir, prostirka.
func _build_room(s: Vector2) -> void:
	# Njihova originalna scena, samo sa navučenom zavesom (pokriva malu kadu)
	# i praznom sredinom.
	var bg := Sprite2D.new()
	bg.texture = load("res://art/bath/scene.png")
	var bt := bg.texture.get_size()
	var sc: float = maxf(s.y / bt.y, s.x / bt.x)
	_lh = s.y
	_oy = 0.0
	bg.scale = Vector2(sc, sc)
	bg.position = s / 2.0
	bg.z_index = -60
	add_child(bg)


func _prop(art: String, frac_w: float, cx: float, base_y: float, z: int) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/bath/%s.png" % art)
	var tex := sp.texture.get_size()
	var s := UI.vs(self)
	sp.scale = Vector2.ONE * ((s.x * frac_w) / tex.x)
	sp.offset = Vector2(0, -tex.y / 2.0)
	sp.position = Vector2(s.x * cx, _ly(base_y))
	sp.z_index = z
	add_child(sp)
	return sp


func _next_bather(announce := true) -> void:
	if bather:
		bather.queue_free()
	if _bath_queue.is_empty():
		_bath_queue = Animals.LIST.duplicate()
		_bath_queue.shuffle()
	var animal: Dictionary = _bath_queue.pop_front()
	var s := UI.vs(self)
	# U kadi su razlike manje nego na livadi — i svinja mora da viri iznad oboda.
	# Iste razmere kao na livadi: konj i krava najveći, patka i kokoška najmanje.
	var rel: float = {"horse": 1.10, "cow": 0.76, "goat": 0.85, "pig": 0.66, "chicken": 0.58, "duck": 0.58}[animal.id]   # krava 1,2× umesto 1,5×
	# Stopala su ispod oboda kade (sakrivena), telo viri iznad — "sedi" u vodi.
	# Stopala na dnu kade, između zadnjeg (15) i prednjeg (17) sloja kade.
	# Stopala na dnu velike kade, između zadnjeg (15) i prednjeg (17) sloja.
	# Na uskom ekranu (iPad 4:3) manja, inače bi bila ogromna; telefon isti.
	var shrink: float = clampf((s.x / s.y) / 2.14, 0.62, 1.0)
	var h: float = _lh * 0.72 * rel * shrink
	bather = FarmBody.new(animal, h, false)
	bather.position = Vector2(_tub_center.x, _water_y)   # stoji na podu
	bather.interactive = false
	bather.z_index = 16
	add_child(bather)
	pig_pos = Vector2(_tub_center.x, bather.position.y - h * 0.62)
	if announce:
		Audio.animal_voice(animal.id)

func _make_rubber_duck(pos: Vector2, s: float) -> void:
	var duck := Area2D.new()
	duck.position = pos
	duck.z_index = 25
	var spr := Sprite2D.new()
	spr.texture = load("res://art/bath/duck.png")
	spr.scale = Vector2.ONE * s
	duck.add_child(spr)
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = maxf(60.0 * s * 1.5, 90.0)
	shape.shape = c
	duck.add_child(shape)
	duck.input_event.connect(func(_vp: Node, event: InputEvent, _i: int) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			Audio.play("duck_0", -4.0, 1.3)  # "kva!" — mala tajna za decu
			UI.haptic(20)
			UI.bounce(duck, Vector2.ONE)
	)
	add_child(duck)

func _make_sponge(pos: Vector2, s: float) -> void:
	sponge_home = pos
	sponge = Area2D.new()
	sponge.position = pos
	sponge.z_index = 40
	var spr := Sprite2D.new()
	spr.texture = load("res://art/bath/sponge.png")
	spr.scale = Vector2.ONE * s
	sponge.add_child(spr)
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = maxf(70.0 * s * 1.4, 110.0)
	shape.shape = c
	sponge.add_child(shape)
	sponge.input_event.connect(func(_vp: Node, event: InputEvent, _i: int) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			sponge_drag = true
			Audio.play("tap")
			if _sponge_pulse:
				_sponge_pulse.kill()
				_sponge_pulse = null
				sponge.scale = Vector2.ONE
	)
	add_child(sponge)
	# dok ga niko ne uzme, sunđer blago pulsira — "uzmi me!"
	_sponge_pulse = sponge.create_tween()
	_sponge_pulse.set_loops()
	_sponge_pulse.tween_property(sponge, "scale", Vector2.ONE * 1.08, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_sponge_pulse.tween_property(sponge, "scale", Vector2.ONE, 0.6).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _spawn_mud() -> void:
	phase = Phase.MUD
	_cover("mud", mud_blobs)


## Prekrije CELO telo, ali SAMO unutar konture: blobovi su deca sprajta
## životinje, a sprajt seče decu po svojoj providnosti (clip_children), pa
## blato i sapunica ne mogu da vire van tela. Položaji su u pikselima crteža.
func _cover(kind: String, into: Array) -> void:
	var sp: Sprite2D = bather.sprite
	sp.clip_children = CanvasItem.CLIP_CHILDREN_AND_DRAW
	var tex := sp.texture.get_size()
	var center := Vector2(0, -tex.y * 0.5)      # crtež je iznad čvora (offset)
	# Blob se pravi SAMO tamo gde je crtež neprovidan: blob van konture bi bio
	# isečen (nevidljiv), a ostao bi u listi — dete vidi čistu životinju, a igra
	# i dalje čeka da se "očisti".
	var img: Image = sp.texture.get_image()
	var cols := 7
	var rows := 5
	for r in rows:
		for c in cols:
			var u: float = (float(c) + 0.5) / cols * 2.0 - 1.0
			var v: float = (float(r) + 0.5) / rows * 2.0 - 1.0
			var lp := center + Vector2(u * tex.x * 0.42, v * tex.y * 0.40)
			var px := Vector2i(int(lp.x + tex.x * 0.5), int(lp.y + tex.y))
			if px.x < 0 or px.y < 0 or px.x >= int(tex.x) or px.y >= int(tex.y):
				continue
			if img.get_pixelv(px).a < 0.5:
				continue
			var blob := Sprite2D.new()
			blob.texture = load("res://art/bath/%s-%d.png" % [kind, 1 + randi() % 3])
			var tw: float = blob.texture.get_size().x
			var want: float = tex.x * (0.34 if kind == "mud" else 0.40)
			blob.scale = Vector2.ONE * (want / tw) * randf_range(0.85, 1.15)
			blob.rotation = randf_range(-0.4, 0.4)
			blob.position = lp + Vector2(randf_range(-0.02, 0.02) * tex.x, randf_range(-0.02, 0.02) * tex.y)
			sp.add_child(blob)    # bez z_index: z bi zaobišao sečenje po konturi
			into.append(blob)


func _make_rain(from: Vector2, rim_y: float) -> void:
	var fall := rim_y - from.y  # kapi žive samo do oboda kade — "upadaju" u vodu
	var drop_tex := UI.drop_texture()
	rain = CPUParticles2D.new()
	rain.texture = drop_tex
	rain.position = from
	rain.amount = 170
	rain.lifetime = maxf(0.3, (sqrt(900.0 * 900.0 + 2.0 * 500.0 * fall) - 900.0) / 500.0)
	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(42, 6)   # uži slap
	rain.direction = Vector2(0, 1)
	rain.spread = 8.0
	rain.initial_velocity_min = 800.0
	rain.initial_velocity_max = 1000.0
	rain.gravity = Vector2(0, 500)
	rain.scale_amount_min = 1.4
	rain.scale_amount_max = 2.4
	rain.modulate = Color(0.75, 0.9, 1.0)
	rain.emitting = false
	rain.z_index = 18  # PREKO životinje (16) i sapunice
	add_child(rain)

	# tuš uvek pomalo kaplje — kupatilo deluje živo
	var drip := CPUParticles2D.new()
	drip.texture = drop_tex
	drip.position = from
	drip.amount = 10
	drip.lifetime = maxf(0.4, (sqrt(320.0 * 320.0 + 2.0 * 800.0 * fall) - 320.0) / 800.0)
	drip.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	drip.emission_rect_extents = Vector2(34, 4)
	drip.direction = Vector2(0, 1)
	drip.spread = 3.0
	drip.initial_velocity_min = 260.0
	drip.initial_velocity_max = 380.0
	drip.gravity = Vector2(0, 800)
	drip.scale_amount_min = 1.0
	drip.scale_amount_max = 1.6
	drip.z_index = 18
	add_child(drip)
	drip.emitting = false      # tuš ne curi dok se ne ispira
	_drip = drip

func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		rubbing = event.pressed
		if not event.pressed and sponge_drag:
			sponge_drag = false
			var tw := create_tween()
			tw.tween_property(sponge, "position", sponge_home, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	elif event is InputEventMouseMotion:
		if sponge_drag:
			sponge.global_position = get_global_mouse_position()
			_rub(sponge.global_position)
		elif rubbing and (phase == Phase.MUD or phase == Phase.FOAM):
			_sponge_hint()  # čisti se SAMO sunđerom — podseti dete gde je

## Prstom se ne čisti — sunđer se javi i poskoči.
## Blato se skida SAMO sunđerom, a sunđer stoji sa strane i ne pomera se sam —
## prst ga prevuče do životinje. U fazi tuširanja i slavlja nema šta da se radi.
func hint_spot() -> Dictionary:
	if sponge_drag or sponge == null or not (phase == Phase.MUD or phase == Phase.FOAM):
		return {}
	return {"from": sponge.position, "to": pig_pos}


func _sponge_hint() -> void:
	if _hint_cooldown > 0.0:
		return
	_hint_cooldown = 1.5
	Audio.play("pop", -6.0)
	UI.bounce(sponge, Vector2.ONE)

func _process(delta: float) -> void:
	if _fall and _fall.visible:
		_fall_f += delta * 16.0
		_fall.texture = load("res://art/bath/fall-%d.png" % (1 + int(_fall_f) % 12))
		_splash.texture = load("res://art/bath/splash-%d.png" % (1 + int(_fall_f * 0.8) % 8))
	_scrub_cooldown = maxf(0.0, _scrub_cooldown - delta)
	_bubble_cooldown = maxf(0.0, _bubble_cooldown - delta)
	_hint_cooldown = maxf(0.0, _hint_cooldown - delta)
	# ako je sunđer ostao van mesta (izgubljen dodir), vrati ga posle 2.5s
	if not sponge_drag and sponge.position.distance_to(sponge_home) > 20.0:
		_sponge_idle += delta
		if _sponge_idle > 2.5:
			_sponge_idle = 0.0
			var tw := create_tween()
			tw.tween_property(sponge, "position", sponge_home, 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		_sponge_idle = 0.0
	# tokom pene: mehurići lete uvis sami od sebe
	if phase == Phase.FOAM and _bubble_cooldown <= 0.0 and not foam_blobs.is_empty():
		_bubble_cooldown = 0.35
		_rise_bubble(foam_blobs[randi() % foam_blobs.size()].global_position)

func _rise_bubble(from: Vector2) -> void:
	var b := UI.circle(self, from, randf_range(8, 18), Color(0.85, 0.95, 1.0, 0.85), 45)
	var tw := b.create_tween()
	tw.tween_property(b, "position", from + Vector2(randf_range(-120, 120), -randf_range(250, 450)), randf_range(1.2, 2.0)).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(b, "modulate:a", 0.0, 1.6)
	tw.tween_callback(b.queue_free)

func _rub(pos: Vector2) -> void:
	if _scrub_cooldown <= 0.0:
		Audio.play("scrub", -8.0, randf_range(0.9, 1.1))
		_scrub_cooldown = 0.25
	match phase:
		Phase.MUD:
			_rub_off(pos, mud_blobs)
			if mud_blobs.is_empty():
				_start_foam()
		Phase.FOAM:
			_rub_off(pos, foam_blobs)
			if foam_blobs.is_empty():
				_start_shower()


func _rub_off(pos: Vector2, blobs: Array) -> void:
	for blob in blobs.duplicate():
		if pos.distance_to(blob.global_position) < RUB_RADIUS:
			blob.scale *= 0.86
			blob.modulate.a -= 0.12
			if blob.modulate.a <= 0.15:
				blobs.erase(blob)
				blob.queue_free()


func _start_foam() -> void:
	# Blato je otrljano: telo se prekrije SAPUNICOM koju dete isto trlja.
	phase = Phase.FOAM
	UI.haptic(30)          # bez vode i bez skoka — voda i tačka tek kad je oprana
	_cover("foam", foam_blobs)
	# Sunđer se vrati na svoje mesto: za sapunicu dete mora ponovo da ga uzme.
	sponge_drag = false
	var tw := create_tween()
	tw.tween_property(sponge, "position", sponge_home, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _start_shower() -> void:
	# Ispiranje: mlaz iz tuša (kupljena animacija vode) pada preko životinje
	# do poda gde prska, uz zvuk vode — 2,8 s, pa slavlje. Ranije je trajalo
	# koliko i nestajanje pene, a pene tu više nema, pa se voda nije ni videla.
	phase = Phase.SHOWER
	rain.emitting = true
	_drip.emitting = true
	_splash.visible = true
	Audio.play("splash", -3.0)
	get_tree().create_timer(1.4).timeout.connect(func() -> void:
		if phase == Phase.SHOWER:
			Audio.play("splash", -6.0, 0.95))
	get_tree().create_timer(2.8).timeout.connect(_start_happy)


func _glow(pos: Vector2, height: float) -> void:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/fx/charge-1.png")
	sp.scale = Vector2.ONE * (height / sp.texture.get_size().y)
	sp.position = pos
	sp.z_index = 45
	sp.modulate = Color(1.0, 0.62, 0.2)
	add_child(sp)
	var tw := create_tween()
	for i in 10:
		var idx := i + 1
		tw.tween_callback(func() -> void: sp.texture = load("res://art/fx/charge-%d.png" % idx))
		tw.tween_interval(0.05)
	tw.tween_callback(sp.queue_free)


func _start_happy() -> void:
	phase = Phase.HAPPY
	rain.emitting = false
	_drip.emitting = false
	_fall.visible = false
	_splash.visible = false
	for f in foam_blobs:
		f.queue_free()
	foam_blobs.clear()
	foam_progress = 0.0
	bather.react(true)
	UI.haptic(60)
	# Bez konfeta, klaćenja i bljeska: glas i tačka životinje.
	var tw := create_tween()
	tw.tween_interval(1.6)
	tw.tween_callback(_next_bather)  # sledeća životinja ulazi u kadu
	tw.tween_interval(0.5)
	tw.tween_callback(_spawn_mud)
