class_name UI
## Pomoćne funkcije za crtanje i efekte — sve iz koda, bez scena.

const W := 1920.0
const H := 1080.0

## Stvarna veličina viewporta u design koordinatama — na širokim telefonima
## (21:9) širina je VEĆA od 1920, pa raspored uvek računati iz ovoga.
static func vs(node: CanvasItem) -> Vector2:
	return node.get_viewport_rect().size

## Kratka vibracija na mobilnom (pogodak/uspeh) — deca to vole.
static func haptic(ms := 40) -> void:
	if OS.has_feature("mobile"):
		Input.vibrate_handheld(ms)

static func circle_points(r: float, segments := 40) -> PackedVector2Array:
	var pts := PackedVector2Array()
	for i in segments:
		var a := TAU * i / segments
		pts.append(Vector2(cos(a), sin(a)) * r)
	return pts

static func circle(parent: Node, pos: Vector2, r: float, color: Color, z := 0) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = circle_points(r)
	p.color = color
	p.position = pos
	p.z_index = z
	parent.add_child(p)
	return p

static func poly(parent: Node, points: PackedVector2Array, color: Color, pos := Vector2.ZERO, z := 0) -> Polygon2D:
	var p := Polygon2D.new()
	p.polygon = points
	p.color = color
	p.position = pos
	p.z_index = z
	parent.add_child(p)
	return p

static func rect_points(w: float, h: float) -> PackedVector2Array:
	return PackedVector2Array([Vector2(-w / 2, -h / 2), Vector2(w / 2, -h / 2), Vector2(w / 2, h / 2), Vector2(-w / 2, h / 2)])

## Pravougaonik sa zaobljenim uglovima (centriran), radius r.
static func rounded_rect_points(w: float, h: float, r: float, seg := 5) -> PackedVector2Array:
	r = minf(r, minf(w, h) / 2.0)
	var pts := PackedVector2Array()
	var corners := [Vector2(w / 2 - r, -h / 2 + r), Vector2(w / 2 - r, h / 2 - r), Vector2(-w / 2 + r, h / 2 - r), Vector2(-w / 2 + r, -h / 2 + r)]
	for c in 4:
		var start := -PI / 2 + c * PI / 2
		for i in seg + 1:
			var a: float = start + PI / 2 * i / seg
			pts.append(corners[c] + Vector2(cos(a), sin(a)) * r)
	return pts

static func label(parent: Node, text: String, pos: Vector2, size := 64, color := Color(0.25, 0.2, 0.15)) -> Label:
	var l := Label.new()
	l.text = text
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(l)
	# centriranje se ponovi kad god label izračuna/promeni veličinu — uvek tačno
	var recenter := func() -> void:
		l.position = pos - l.size / 2.0
	l.resized.connect(recenter)
	l.reset_size()
	recenter.call()
	return l

## Konfete — CPUParticles2D eksplozija koja se sama počisti.
static func confetti(parent: Node, pos: Vector2, amount := 60) -> void:
	var p := CPUParticles2D.new()
	p.position = pos
	p.amount = amount
	p.one_shot = true
	p.explosiveness = 1.0
	p.lifetime = 1.4
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.initial_velocity_min = 500.0
	p.initial_velocity_max = 900.0
	p.gravity = Vector2(0, 1400)
	p.scale_amount_min = 6.0
	p.scale_amount_max = 12.0
	p.color_ramp = _confetti_gradient()
	p.z_index = 100
	parent.add_child(p)
	p.emitting = true
	parent.get_tree().create_timer(2.0).timeout.connect(p.queue_free)

static func _confetti_gradient() -> Gradient:
	var g := Gradient.new()
	g.colors = PackedColorArray([Color("#ff5d5d"), Color("#ffd93d"), Color("#6bcb77"), Color("#4d96ff")])
	g.offsets = PackedFloat32Array([0.0, 0.33, 0.66, 1.0])
	return g

## Squash & stretch "poskok" animacija.
static func bounce(node: Node2D, base_scale: Vector2) -> void:
	var tw := node.create_tween()
	tw.tween_property(node, "scale", base_scale * Vector2(1.2, 0.75), 0.08).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(node, "scale", base_scale * Vector2(0.85, 1.2), 0.10)
	tw.tween_property(node, "scale", base_scale, 0.3).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

## Blago odmahivanje ("nije to") — bez kazne.
static func head_shake(node: Node2D) -> void:
	var tw := node.create_tween()
	for angle in [0.08, -0.08, 0.05, -0.05, 0.0]:
		tw.tween_property(node, "rotation", angle, 0.07)
