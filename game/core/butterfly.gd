class_name Butterfly
extends Node2D
## Leptir koji preleti preko ekrana — čist ukras, mami tap (i beži od njega).
## Let je "fizički": zamasi krila ga podignu, između zamaha jedri naniže,
## uz blago naginjanje u pravcu leta — ništa se ne kreće po pravoj liniji.

## Boje su "ključevi" varijanti — mapiraju se na butterfly-wing-*.svg fajlove.
const COLORS := [Color("#F4A7B9"), Color("#9EC7EA"), Color("#FFD873")]
const WING_TEX := ["pink", "blue", "yellow"]

var _t := 0.0
var _to := Vector2.ZERO
var _vel := Vector2.ZERO
var _flap_burst := 0.0   # koliko još traje nalet zamaha
var _flap_pause := 0.0   # pauza do sledećeg naleta
var _wander := 0.0
var _wing_l: Sprite2D
var _wing_r: Sprite2D
var _body: Sprite2D

func _init(from: Vector2, to: Vector2, wing_color := Color("#F4A7B9")) -> void:
	_to = to
	position = from
	z_index = 60
	scale = Vector2.ONE * 0.32  # sklopljen je 280px širok → ~90px na ekranu
	_wander = randf() * TAU
	_flap_pause = randf_range(0.1, 0.4)
	_vel = Vector2(signf(to.x - from.x) * randf_range(120.0, 180.0), randf_range(-40.0, 20.0))

	# dizajnerski leptir iz delova (assets 13): krila iza, telo preko šava
	var idx := COLORS.find(wing_color)
	if idx < 0:
		idx = randi() % WING_TEX.size()
	var wing_tex: Texture2D = load("res://art/svg/butterfly-wing-%s.svg" % WING_TEX[idx])
	for side in [-1.0, 1.0]:
		var w := Sprite2D.new()
		w.texture = wing_tex
		w.centered = false
		w.offset = Vector2(-200, -130)  # pivot = unutrašnja ivica krila (200,130)
		w.scale.x = side
		add_child(w)
		if side < 0.0:
			_wing_r = w  # scaleX(-1) = desno krilo
		else:
			_wing_l = w
	_body = Sprite2D.new()
	_body.texture = load("res://art/svg/butterfly-body.svg")
	_body.position = Vector2(0, 34)  # tačka kačenja (60,96) u 120×260 platnu
	add_child(_body)

func _process(delta: float) -> void:
	_t += delta
	if _t >= 14.0 or absf(position.x - _to.x) < 50.0:
		queue_free()
		return

	# ritam zamaha: nalet (diže) → jedrenje (tone) → novi nalet
	if _flap_burst > 0.0:
		_flap_burst -= delta
		_vel.y -= 420.0 * delta
	else:
		_flap_pause -= delta
		if _flap_pause <= 0.0:
			_flap_burst = randf_range(0.25, 0.5)
			_flap_pause = randf_range(0.3, 0.85)
			_vel.x += randf_range(-55.0, 55.0)  # mali bočni "trzaj" uz zamah

	# jedrenje: blaga "gravitacija" + vučenje ka cilju + lutanje
	_vel.y += 230.0 * delta
	_vel.x += signf(_to.x - position.x) * 150.0 * delta
	_vel.x += sin(_t * 1.6 + _wander) * 90.0 * delta
	_vel = _vel.limit_length(300.0)
	position += _vel * delta

	# meko drži visinu u gornjem pojasu ekrana
	if position.y < 60.0:
		position.y = 60.0
		_vel.y = maxf(_vel.y, 0.0)
	elif position.y > 560.0:
		_vel.y -= 500.0 * delta

	# naginjanje u pravcu leta
	rotation = lerpf(rotation, clampf(_vel.x * 0.0012, -0.3, 0.3), 5.0 * delta)

	# krila: brzo mašu u naletu, lenjo u jedrenju (scaleX 0.35→1 oko pivota)
	var flap_speed := 24.0 if _flap_burst > 0.0 else 8.0
	var flap := 0.35 + 0.65 * absf(sin(_t * flap_speed))
	_wing_l.scale.x = flap
	_wing_r.scale.x = -flap
	# mali bob tela u ritmu zamaha — "živost"
	_body.position.y = 34.0 + sin(_t * flap_speed) * 7.0
