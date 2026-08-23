extends BaseScreen
## Mini-igra: SLONOVSKI TUŠ — dizajnerska scena: slon na kamenu levo,
## blatnjava životinja u pojilu desno; tap na slona → luk vode → spiranje.

var elephant: Area2D
var elephant_pos := Vector2.ZERO
var bather: AnimalSprite
var bather_pos := Vector2.ZERO
var bather_scale := 1.0
var mud_blobs: Array[Sprite2D] = []
var _queue: Array = []
var _busy := false
var spray: CPUParticles2D
var splash_pos := Vector2.ZERO

func _ready() -> void:
	home_target = "jungle"
	var s := UI.vs(self)
	Scenery.background(self, "background-shower", true)  # organska — puno razvlačenje
	add_ambient(0, "mosquito")
	add_home_button()

	# rekviziti: biljka levo, peškir desno
	Scenery.svg(self, "shower-plant", Vector2(s.x * 0.055, s.y * 0.80), (s.x * 0.10) / 300.0, -20)
	if s.x / s.y >= 1.6:
		# širok ekran (telefon): drvo uz desnu ivicu, krošnja izlazi preko vrha
		var tb_scale := (s.y * 0.80) / 620.0
		Scenery.svg(self, "towel-branch", Vector2(s.x - 260.0 * tb_scale, s.y * 0.42), tb_scale, -20)
	else:
		# uzak ekran (tablet 4:3/16:10): drvo bi pregazilo pojilo — umesto njega
		# peškir visi na lijani sa vrha ekrana
		var v_scale := (s.y * 0.34) / 500.0
		Scenery.svg(self, "vine", Vector2(s.x * 0.88, 250.0 * v_scale), v_scale, -20)
		Scenery.svg(self, "towel", Vector2(s.x * 0.88, 500.0 * v_scale + 130.0 * (s.x * 0.085) / 256.0), (s.x * 0.085) / 256.0, -19)

	# slon na kamenoj ploči (ploča je u pozadini) — sidrimo mu STOPALA na
	# vrh ploče (0.79h), pa visina ekrana ne može da ga "odlepi" od nje
	var e_scale := (s.x * 0.215) / 560.0
	elephant_pos = Vector2(s.x * 0.215, s.y * 0.79 - 230.0 * e_scale)
	elephant = Area2D.new()
	elephant.position = elephant_pos
	var spr := Sprite2D.new()
	spr.texture = load("res://art/svg/elephant-shower.svg")
	spr.scale = Vector2.ONE * e_scale
	elephant.add_child(spr)
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(560, 460) * e_scale * 1.15
	shape.shape = rect
	elephant.add_child(shape)
	elephant.input_event.connect(func(_vp: Node, event: InputEvent, _i: int) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_spray()
	)
	add_child(elephant)
	var pulse := elephant.create_tween()
	pulse.set_loops()
	pulse.tween_property(elephant, "scale", Vector2.ONE * 1.04, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	pulse.tween_property(elephant, "scale", Vector2.ONE, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	# mlaz iz surle → luk do pojila
	spray = CPUParticles2D.new()
	spray.texture = UI.drop_texture()
	spray.position = elephant_pos + Vector2(235.0, -175.0) * e_scale
	spray.one_shot = true
	spray.emitting = false
	spray.amount = 30
	spray.lifetime = 0.85
	spray.explosiveness = 0.85
	spray.direction = Vector2(1, -0.55)
	spray.spread = 9.0
	spray.initial_velocity_min = 1350.0
	spray.initial_velocity_max = 1650.0
	spray.gravity = Vector2(0, 1600)
	spray.scale_amount_min = 1.0
	spray.scale_amount_max = 1.7
	spray.z_index = 30
	add_child(spray)

	# blatnjava životinja u pojilu
	bather_scale = (s.x * 0.125) / 230.0
	bather_pos = Vector2(s.x * 0.755, s.y * 0.655)
	splash_pos = Vector2(s.x * 0.755, s.y * 0.79)
	_next_bather(false)

func _next_bather(announce := true) -> void:
	if bather:
		bather.queue_free()
	if _queue.is_empty():
		_queue = Animals.JUNGLE.filter(func(a): return a.id != "elephant")
		_queue.shuffle()
	var animal: Dictionary = _queue.pop_front()
	bather = AnimalSprite.new(animal, bather_scale)
	bather.position = bather_pos
	bather.interactive = false
	bather.z_index = 10
	add_child(bather)
	if announce:
		if not animal.id in Animals.SILENT:   # žvakanje uz kupanje nema smisla
			Audio.animal_voice(animal.id)
		UI.bounce(bather, bather.base_scale)
	_spawn_mud()
	_busy = false

func _spawn_mud() -> void:
	var s := UI.vs(self)
	for i in 9:
		var a := TAU * i / 9.0 + randf_range(-0.3, 0.3)
		var dist := randf_range(30, 120) * (s.x / 2340.0)
		var blob := Sprite2D.new()
		blob.texture = load("res://art/svg/mud-splat.svg")
		blob.scale = Vector2.ONE * randf_range(0.26, 0.45) * (s.x / 2340.0)
		blob.rotation = randf_range(0, TAU)
		blob.position = bather_pos + Vector2(cos(a) * dist * 1.4, sin(a) * dist)
		blob.z_index = 12
		add_child(blob)
		mud_blobs.append(blob)

## Tap na slona: mlaz + splash u pojilu + spiranje dela blata.
func _spray() -> void:
	if _busy:
		return
	Audio.play("splash", -4.0, randf_range(0.95, 1.1))
	UI.haptic(30)
	UI.bounce(elephant, Vector2.ONE)
	spray.restart()
	spray.emitting = true

	# splash-prsten na površini pojila kad kapi stignu
	get_tree().create_timer(0.5).timeout.connect(_show_splash_ring)

	get_tree().create_timer(0.4).timeout.connect(func() -> void:
		for i in 3:
			if mud_blobs.is_empty():
				break
			var blob: Sprite2D = mud_blobs.pop_at(randi() % mud_blobs.size())
			var tw := blob.create_tween()
			tw.tween_property(blob, "modulate:a", 0.0, 0.3)
			tw.parallel().tween_property(blob, "scale", blob.scale * 0.5, 0.3)
			tw.tween_callback(blob.queue_free)
		if mud_blobs.is_empty() and not _busy:
			_busy = true
			_celebrate_clean()
	)

func _show_splash_ring() -> void:
	var s := UI.vs(self)
	var ring := Sprite2D.new()
	ring.texture = load("res://art/svg/splash-ring.svg")
	ring.position = splash_pos
	ring.scale = Vector2.ONE * (s.x * 0.06) / 300.0
	ring.z_index = 25
	add_child(ring)
	var tw := ring.create_tween()
	tw.tween_property(ring, "scale", ring.scale * 1.8, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.4)
	tw.tween_callback(ring.queue_free)

func _celebrate_clean() -> void:
	if bather.animal.id in Animals.SILENT:
		UI.bounce(bather, bather.base_scale)   # samo poskoči, bez žvakanja
	else:
		bather.react(true)
	UI.haptic(60)
	celebrate(bather_pos + Vector2(0, -200))
	var tw := create_tween()
	for i in 3:
		tw.tween_property(bather, "rotation", 0.12, 0.15)
		tw.tween_property(bather, "rotation", -0.12, 0.15)
	tw.tween_property(bather, "rotation", 0.0, 0.1)
	tw.tween_interval(0.8)
	tw.tween_callback(_next_bather)
