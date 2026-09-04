extends BaseScreen
## Mini-igra: ŽMURKE (farma). Životinja se javi, odšeta i sakrije iza jednog
## od tri skrovišta, pa proviruje. Dete tapne skrovište; pogodak = životinja
## iskoči na vrh, oglasi se i uradi svoju tačku. Promašaj = skrovište se
## zatrese, bez kazne.
##
## Sve iz kupljenih paketa: livada, kokošinjac, suncokreti, kukuruz kao
## skrovišta, životinje celim telom (FarmBody) koje stvarno hodaju.

## Skrovišta moraju biti PUNA (bez rupa i bez nogara): štala, gomila sena
## (izvučena u visinu) i kukuruz.
const SPOT_DATA := [
	{"png": "barn", "frac_w": 0.26, "x": 0.19, "sy": 1.0},
	{"png": "sunflowers", "frac_w": 0.22, "x": 0.50, "sy": 1.0},
	{"png": "corn-group", "frac_w": 0.32, "x": 0.81, "sy": 1.0},
]
const BODY_H := 0.55          # visina KADRA konja (deo visine ekrana); vidljivo telo je ~0,67 toga
## Razmere po VIDLJIVOM telu (kadrovi imaju različito praznog prostora):
## konj 1,0, krava 0,9, koza 0,78, svinja 0,65, kokoška i patka 0,6.
const REL := {"horse": 1.0, "cow": 0.65, "goat": 0.75, "pig": 0.59, "chicken": 0.48, "duck": 0.50}
const BASELINE := 0.95        # tlo — dno skrovišta i stopala životinje

var spots: Array[Dictionary] = []   # {pos: centar, top: y gornje ivice, x: sredina}
var animal_node: FarmBody
var hiding_idx := -1
var accepting_taps := false
var spot_nodes: Array[Area2D] = []
var _peek_tw: Tween = null
var _hide_y := 0.0


func _ready() -> void:
	var s := UI.vs(self)
	_build_scene(s)
	add_home_button()
	add_hint(6.0)
	for i in SPOT_DATA.size():
		var d: Dictionary = SPOT_DATA[i]
		var tex: Vector2 = load("res://art/farm/%s.png" % d.png).get_size()
		var sc: float = (s.x * float(d.frac_w)) / tex.x
		var h: float = tex.y * sc * float(d.sy)
		var center := Vector2(s.x * float(d.x), s.y * BASELINE - h / 2.0)
		spots.append({"pos": center, "top": s.y * BASELINE - h, "x": s.x * float(d.x)})
		spot_nodes.append(_build_spot(i, String(d.png), center, sc, tex.x * sc, h, float(d.sy)))
	_next_round()


## Livada iz paketa; skrovišta su napred, sve ostalo daleko iza njih.
func _build_scene(s: Vector2) -> void:
	var bg := Sprite2D.new()
	bg.texture = load("res://art/farm/bg-field.png")
	var bt := bg.texture.get_size()
	var sc: float = maxf(s.y / bt.y, s.x / bt.x)
	bg.scale = Vector2(sc, sc)
	bg.position = s / 2.0
	bg.z_index = -60
	add_child(bg)
	Scenery.cloud(self, Vector2(s.x * 0.25, 110), 1.0, -50)
	Scenery.cloud(self, Vector2(s.x * 0.75, 90), 0.8, -50)
	_prop("tree-1", 0.13, 0.06, 0.56, -41)
	_prop("tree-2", 0.10, 0.36, 0.55, -42)
	_prop("windmill", 0.05, 0.62, 0.56, -38)
	_prop("tree-4", 0.13, 0.72, 0.57, -40)
	_prop("tree-3", 0.11, 0.95, 0.56, -41)
	add_ambient(0)


func _prop(art: String, frac_w: float, cx: float, base_y: float, z: int) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/farm/%s.png" % art)
	var tex := sp.texture.get_size()
	var s := UI.vs(self)
	sp.scale = Vector2.ONE * ((s.x * frac_w) / tex.x)
	sp.offset = Vector2(0, -tex.y / 2.0)
	sp.position = Vector2(s.x * cx, s.y * base_y)
	sp.z_index = z
	add_child(sp)
	return sp


func _build_spot(idx: int, png: String, center: Vector2, sc: float, w: float, h: float, sy: float) -> Area2D:
	var area := Area2D.new()
	area.position = center
	area.z_index = 20  # skrovišta su ISPRED sakrivene životinje
	var spr := Sprite2D.new()
	spr.texture = load("res://art/farm/%s.png" % png)
	spr.scale = Vector2(sc, sc * sy)
	area.add_child(spr)
	# Bilje ima rupe između stabljika: drugi primerak u ogledalu, malo pomeren
	# i iza prvog, zatvara rupe pa se sakrivena životinja ne vidi kroz njih.
	if png == "sunflowers" or png == "corn-group":
		var spr2 := Sprite2D.new()
		spr2.texture = spr.texture
		spr2.scale = Vector2(-sc, sc * sy)
		spr2.position = Vector2(w * 0.10, h * 0.02)
		spr2.z_index = -1
		area.add_child(spr2)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w * 1.15, h * 1.15)  # tap zona malo šira od crteža
	shape.shape = rect
	area.add_child(shape)

	area.input_event.connect(func(_vp: Node, event: InputEvent, _i: int) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_spot_tapped(idx)
	)
	add_child(area)
	return area


func _next_round() -> void:
	accepting_taps = false
	_stop_peek()
	if animal_node:
		animal_node.queue_free()

	var s := UI.vs(self)
	var animal: Dictionary = Animals.LIST[randi() % Animals.LIST.size()]
	hiding_idx = randi() % spots.size()
	var spot: Dictionary = spots[hiding_idx]

	# Ušeta sa ivice ekrana po tlu (sa strane suprotne od skrovišta, da hoda
	# što duže), ispred svega, pa kod skrovišta zađe iza njega.
	var from_right: bool = spot.x <= s.x * 0.5
	var start := Vector2(s.x * (1.12 if from_right else -0.12), s.y * BASELINE)
	var faces_right: bool = not from_right
	# Na uskom ekranu (iPad 4:3) manja, inače je ogromna; telefon isti.
	var shrink: float = clampf((s.x / s.y) / 2.14, 0.62, 1.0)
	animal_node = FarmBody.new(animal, s.y * BODY_H * float(REL[animal.id]) * shrink, faces_right)
	animal_node.position = start
	animal_node.interactive = false
	animal_node.z_index = 5        # hoda IZA skrovišta, ceo put
	add_child(animal_node)
	Audio.animal_voice(animal.id)

	var target := Vector2(spot.x, s.y * BASELINE)   # stopala na tlu, iza skrovišta
	_hide_y = target.y
	var dist: float = absf(spot.x - start.x)
	var tw := create_tween()
	tw.tween_interval(0.3)
	tw.tween_callback(func() -> void: animal_node.set_walking(true))
	tw.tween_property(animal_node, "position", target, dist / (s.x * 0.13))
	tw.tween_callback(func() -> void:
		animal_node.set_walking(false)
		accepting_taps = true
		_start_peek()
	)


func _start_peek() -> void:
	var s := UI.vs(self)
	_peek_tw = create_tween()
	_peek_tw.set_loops()
	_peek_tw.tween_interval(randf_range(1.6, 2.8))
	_peek_tw.tween_property(animal_node, "position:y", _hide_y - s.y * 0.15, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_peek_tw.tween_interval(0.35)
	_peek_tw.tween_property(animal_node, "position:y", _hide_y, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)


func _stop_peek() -> void:
	if _peek_tw:
		_peek_tw.kill()
		_peek_tw = null


func hint_spot() -> Dictionary:
	if not accepting_taps or hiding_idx < 0 or hiding_idx >= spots.size():
		return {}
	return {"at": spots[hiding_idx].pos}


func _on_spot_tapped(idx: int) -> void:
	if not accepting_taps:
		return
	if idx == hiding_idx:
		accepting_taps = false
		_stop_peek()
		UI.haptic(45)
		# Iskoči na vrh skrovišta, ispred njega, oglasi se i uradi tačku.
		var s := UI.vs(self)
		var above := Vector2(spots[idx].x, spots[idx].top + s.y * 0.02)
		animal_node.z_index = 25
		var tw := create_tween()
		tw.tween_property(animal_node, "position", above, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void:
			animal_node.react(true)
			_glow(above + Vector2(0, -s.y * BODY_H * 0.35), s.y * BODY_H * 0.7)
		)
		tw.tween_interval(1.6)
		tw.tween_callback(_next_round)
	else:
		Audio.play("tap")
		UI.head_shake(spot_nodes[idx])


func _glow(pos: Vector2, height: float) -> void:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/fx/charge-1.png")
	sp.scale = Vector2.ONE * (height / sp.texture.get_size().y)
	sp.position = pos
	sp.z_index = 40
	sp.modulate = Color(1.0, 0.62, 0.2, 0.55)   # blaže, upola providno
	add_child(sp)
	var tw := create_tween()
	for i in 10:
		var idx := i + 1
		tw.tween_callback(func() -> void: sp.texture = load("res://art/fx/charge-%d.png" % idx))
		tw.tween_interval(0.05)
	tw.tween_callback(sp.queue_free)
