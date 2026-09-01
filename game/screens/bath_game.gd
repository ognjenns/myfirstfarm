extends BaseScreen
## Mini-igra: Okupaj prase — pravo KUPATILO (Claude Design asseti).
## Faze: BLATO (trljaj prstom ili sunđerom) → PENA → TUŠ → SREĆA, pa ispočetka.
## Bonus: gumena patkica na ivici kade — tap = "kva!".

enum Phase { MUD, FOAM, SHOWER, HAPPY }

const RUB_RADIUS := 110.0

var pig_pos := Vector2.ZERO
var phase: int = Phase.MUD
var bather: AnimalSprite
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

func _ready() -> void:
	var s := UI.vs(self)
	Scenery.background(self, "background-bath")
	add_home_button()
	add_hint(6.0)

	# kada — širina 0.462w, gornja ivica (rim) na 0.548h
	var tub_scale := (s.x * 0.462) / 1000.0
	var rim_y := s.y * 0.548
	Scenery.svg(self, "bathtub", Vector2(s.x * 0.5, rim_y + 180.0 * tub_scale), tub_scale, 15)

	# kupač "sedi" u kadi — brada na obodu; posle svakog kupanja dolazi sledeća životinja
	bather_scale = (s.x * 0.135) / 230.0
	pig_pos = Vector2(s.x * 0.5, rim_y - 95.0 * bather_scale)
	_next_bather(false)

	# tuš iznad kade
	var sh_scale := (s.x * 0.115) / 300.0
	Scenery.svg(self, "shower-head", Vector2(s.x * 0.5, 170.0 * sh_scale), sh_scale, 20)
	_make_rain(Vector2(s.x * 0.5, 300.0 * sh_scale), rim_y)

	# peškir desno, patkica na obodu kade
	Scenery.svg(self, "towel", Vector2(s.x * 0.715, s.y * 0.10 + 150.0 * (s.x * 0.09) / 256.0), (s.x * 0.09) / 256.0, 5)
	_make_rubber_duck(Vector2(s.x * 0.5 + (s.x * 0.462) * 0.38, rim_y - 40.0), (s.x * 0.065) / 256.0)

	_make_sponge(Vector2(s.x * 0.115, s.y * 0.80), (s.x * 0.10) / 256.0)
	_spawn_mud()

## Sledeća životinja ulazi u kadu (promešan redosled, bez ponavljanja dok krug ne prođe).
func _next_bather(announce := true) -> void:
	if bather:
		bather.queue_free()
	if _bath_queue.is_empty():
		_bath_queue = Animals.LIST.duplicate()
		_bath_queue.shuffle()
	var animal: Dictionary = _bath_queue.pop_front()
	bather = AnimalSprite.new(animal, bather_scale)
	bather.position = pig_pos
	bather.interactive = false
	bather.z_index = 10
	add_child(bather)
	if announce:
		Audio.animal_voice(animal.id)
		UI.bounce(bather, bather.base_scale)

func _make_rubber_duck(pos: Vector2, s: float) -> void:
	var duck := Area2D.new()
	duck.position = pos
	duck.z_index = 25
	var spr := Sprite2D.new()
	spr.texture = load("res://art/svg/rubber-duck.svg")
	spr.scale = Vector2.ONE * s
	duck.add_child(spr)
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = 128.0 * s * 1.3
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
	spr.texture = load("res://art/svg/sponge.svg")
	spr.scale = Vector2.ONE * s
	sponge.add_child(spr)
	var shape := CollisionShape2D.new()
	var c := CircleShape2D.new()
	c.radius = maxf(128.0 * s * 1.2, 100.0)
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
	var s := UI.vs(self)
	for i in 10:
		var a := TAU * i / 10.0 + randf_range(-0.3, 0.3)
		var dist := randf_range(20, 130) * (s.x / 2340.0)
		var blob := Sprite2D.new()
		blob.texture = load("res://art/svg/mud-splat.svg")
		blob.scale = Vector2.ONE * randf_range(0.28, 0.5) * (s.x / 2340.0)
		blob.rotation = randf_range(0, TAU)
		blob.position = pig_pos + Vector2(cos(a) * dist * 1.4, sin(a) * dist)
		blob.z_index = 12
		add_child(blob)
		mud_blobs.append(blob)

func _make_rain(from: Vector2, rim_y: float) -> void:
	var fall := rim_y - from.y  # kapi žive samo do oboda kade — "upadaju" u vodu
	var drop_tex := UI.drop_texture()
	rain = CPUParticles2D.new()
	rain.texture = drop_tex
	rain.position = from
	rain.amount = 100
	rain.lifetime = maxf(0.3, (sqrt(900.0 * 900.0 + 2.0 * 500.0 * fall) - 900.0) / 500.0)
	rain.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	rain.emission_rect_extents = Vector2(70, 6)
	rain.direction = Vector2(0, 1)
	rain.spread = 8.0
	rain.initial_velocity_min = 800.0
	rain.initial_velocity_max = 1000.0
	rain.gravity = Vector2(0, 500)
	rain.scale_amount_min = 1.2
	rain.scale_amount_max = 2.0
	rain.emitting = false
	rain.z_index = 12  # iznad životinje, ispod kade → kapi nestaju iza oboda
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
	drip.z_index = 12
	add_child(drip)
	drip.emitting = true

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
		_rise_bubble(foam_blobs[randi() % foam_blobs.size()].position)

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
			for blob in mud_blobs.duplicate():
				if pos.distance_to(blob.position) < RUB_RADIUS:
					blob.scale *= 0.86
					blob.modulate.a -= 0.12
					if blob.modulate.a <= 0.15:
						mud_blobs.erase(blob)
						blob.queue_free()
			if mud_blobs.is_empty():
				_start_foam()
		Phase.FOAM:
			if pos.distance_to(pig_pos) < 320:
				foam_progress += 0.02
				if foam_blobs.size() < 14 and randf() < 0.35:
					var s := UI.vs(self)
					var f := Sprite2D.new()
					f.texture = load("res://art/svg/foam-puff.svg")
					f.scale = Vector2.ONE * randf_range(0.3, 0.55) * (s.x / 2340.0)
					f.position = pos + Vector2(randf_range(-40, 40), randf_range(-40, 40))
					f.z_index = 13
					add_child(f)
					foam_blobs.append(f)
				if foam_progress >= 1.0:
					_start_shower()

func _start_foam() -> void:
	phase = Phase.FOAM
	Audio.play("splash", -8.0, 1.15)   # prelazak na penu: voda, ne zvonce
	UI.haptic(30)
	UI.bounce(bather, bather.base_scale)

func _start_shower() -> void:
	phase = Phase.SHOWER
	rain.emitting = true
	Audio.play("splash", -3.0)
	# pena se spira
	var tw := create_tween()
	for f in foam_blobs:
		tw.parallel().tween_property(f, "modulate:a", 0.0, 1.6)
	tw.tween_callback(_start_happy)

func _start_happy() -> void:
	phase = Phase.HAPPY
	rain.emitting = false
	for f in foam_blobs:
		f.queue_free()
	foam_blobs.clear()
	foam_progress = 0.0
	bather.react(true)
	UI.haptic(60)
	celebrate(pig_pos + Vector2(0, -200))
	# malo "plesa", pa ispočetka
	var tw := create_tween()
	for i in 3:
		tw.tween_property(bather, "rotation", 0.12, 0.15)
		tw.tween_property(bather, "rotation", -0.12, 0.15)
	tw.tween_property(bather, "rotation", 0.0, 0.1)
	tw.tween_interval(1.0)
	tw.tween_callback(_next_bather)  # sledeća životinja ulazi u kadu
	tw.tween_interval(0.5)
	tw.tween_callback(_spawn_mud)
