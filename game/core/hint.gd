class_name Hint
extends Node2D
## Pokazivač: bela tačka kao dečji prst koja pokaže ŠTA se radi na ekranu —
## tapne mesto ili prevuče od jednog do drugog. Bez teksta i bez glasa, jer
## igra nema ni jedno ni drugo; pokazivanje je jedini jezik koji uzrast 2–5
## razume odmah.
##
## Javlja se tek kad ekran miruje (vidi `BaseScreen.add_hint`), nestaje čim
## dete dodirne ekran i ne prima dodire (ne može da "ukrade" tap).

const R := 44.0
const DRAG_TIME := 1.15
## Vrh podignutog prsta u crtežu (165×256) — obe poze dele platno, pa se pri
## pritisku menja samo tekstura i vrh prirodno "klone" ka meti.
const TIP := Vector2(44.0, 6.0)
var _hand: Sprite2D

static func tap(parent: Node, pos: Vector2, size := 1.0, times := 2) -> Hint:
	var h := Hint.new()
	parent.add_child(h)
	h.position = pos
	h._set_size(size)
	h._appear()
	var tw := h.create_tween()
	for i in times:
		tw.tween_interval(0.12)
		tw.tween_callback(h._press)
		tw.tween_callback(h._ripple)
		tw.tween_interval(0.18)
		tw.tween_callback(h._release)
		tw.tween_interval(0.36)
	tw.tween_callback(h._vanish)
	return h

static func drag(parent: Node, from: Vector2, to: Vector2, size := 1.0) -> Hint:
	var h := Hint.new()
	parent.add_child(h)
	h.position = from
	h._set_size(size)
	h._appear()
	var tw := h.create_tween()
	tw.tween_interval(0.18)
	tw.tween_callback(h._press)
	tw.tween_callback(h._trail.bind(from, to))
	tw.tween_property(h, "position", to, DRAG_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(h._release)
	tw.tween_interval(0.25)
	tw.tween_callback(h._vanish)
	return h


func _init() -> void:
	z_index = 300  # iznad svega u igri
	modulate.a = 0.0
	# Beo krug se GUBI na svetlim ekranima (kupatilo, izbor svetova, memorija),
	# a taman na okeanu. Zato pokazivač ima i tamnu i svetlu ivicu jednu do
	# druge — takav prsten se vidi na svakoj podlozi, kao i sve ostalo u igri
	# što je crtano tamnim obrubom.
	_ring(R, 18.0, Color(Pal.OUTLINE, 0.9))
	_ring(R, 9.0, Color(1, 1, 1, 1.0))
	UI.circle(self, Vector2.ZERO, R - 9.0, Color(1, 1, 1, 0.22))  # blaga svetlost unutra
	# Ruka (kupljeni crtež, dve poze: podignut i pritisnut prst). Vrh prsta je
	# tačno na meti, dlan ide dole-desno. Prsten ostaje — kroz njega se vidi
	# ŠTA se tapka, a ruka kaže KAKO.
	_hand = Sprite2D.new()
	_hand.texture = load("res://art/fx/finger-up.png")
	var ht := _hand.texture.get_size()
	_hand.offset = Vector2(ht.x / 2.0 - TIP.x, ht.y / 2.0 - TIP.y)
	_hand.scale = Vector2.ONE * 0.52
	_hand.z_index = 2
	add_child(_hand)


## Prsten kao Line2D — Polygon2D ume samo punu površinu, a ovde je rupa bitna:
## kroz nju se vidi ono što se tapka.
func _ring(radius: float, width: float, color: Color) -> Line2D:
	var pts := UI.circle_points(radius, 44)
	pts.append(pts[0])
	var line := Line2D.new()
	line.points = pts
	line.width = width
	line.default_color = color
	add_child(line)
	return line


## Veličina se zadaje po ekranu: na hubu je prizor širok i sitan prsten se
## izgubi među životinjama, u mini-igri je meta blizu i prsten sme da bude manji.
func _set_size(size: float) -> void:
	scale = Vector2.ONE * size


func _press() -> void:
	_hand.texture = load("res://art/fx/finger-down.png")


func _release() -> void:
	_hand.texture = load("res://art/fx/finger-up.png")


func _appear() -> void:
	create_tween().tween_property(self, "modulate:a", 1.0, 0.25)


## Ukloni pokazivač — zove se i kad dete dodirne ekran, usred animacije.
func vanish() -> void:
	_vanish()


func _vanish() -> void:
	if not is_inside_tree():
		return
	var tw := create_tween()
	tw.tween_property(self, "modulate:a", 0.0, 0.25)
	tw.tween_callback(queue_free)


## Talas oko dodira — bez njega se ne vidi da je tačka baš TAPNULA.
func _ripple() -> void:
	var wave := Node2D.new()
	add_child(wave)
	var dark := _ring(R, 12.0, Color(Pal.OUTLINE, 0.75))
	var light := _ring(R, 6.0, Color(1, 1, 1, 0.95))
	for n in [dark, light]:
		remove_child(n)
		wave.add_child(n)
	var tw := wave.create_tween()
	tw.tween_property(wave, "scale", Vector2.ONE * 2.4, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(wave, "modulate:a", 0.0, 0.55)
	tw.tween_callback(wave.queue_free)


## Tačkice po putanji prevlačenja — pokazuju KUDA, ne samo odakle.
func _trail(from: Vector2, to: Vector2) -> void:
	var parent := get_parent()
	if parent == null:
		return
	for i in 10:
		var p := from.lerp(to, float(i + 1) / 10.0)
		var t := get_tree().create_timer(i * DRAG_TIME / 11.0)
		t.timeout.connect(func() -> void:
			if not is_instance_valid(parent) or not is_inside_tree():
				return
			var dot := Node2D.new()
			dot.position = p
			dot.z_index = 299
			dot.modulate.a = 0.0
			parent.add_child(dot)
			UI.circle(dot, Vector2.ZERO, 15.0, Pal.OUTLINE)
			UI.circle(dot, Vector2.ZERO, 10.0, Color(1, 1, 1, 1.0))
			var tw := dot.create_tween()
			tw.tween_property(dot, "modulate:a", 0.9, 0.12)
			tw.tween_interval(0.5)
			tw.tween_property(dot, "modulate:a", 0.0, 0.35)
			tw.tween_callback(dot.queue_free))
