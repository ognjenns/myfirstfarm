extends BaseScreen
## Mini-igra: Žmurke — dizajnerska skrovišta (plast, štala, žbun).
## Životinja se javi na sredini, sakrije se iza jednog skrovišta; dete tapa.
## Promašaj = skrovište se zatrese; pogodak = iskoči + konfete. Viri povremeno.

const SPOT_DATA := [
	{"svg": "hide-haystack", "w": 520.0, "h": 440.0, "frac_w": 0.207, "x": 0.20},
	{"svg": "hide-barn", "w": 560.0, "h": 500.0, "frac_w": 0.222, "x": 0.50},
	{"svg": "hide-bush", "w": 560.0, "h": 420.0, "frac_w": 0.222, "x": 0.80},
]

var spots: Array[Dictionary] = []  # {pos: centar skrovišta, top: y gornje ivice}
var animal_node: AnimalSprite
var hiding_idx := -1
var accepting_taps := false
var spot_nodes: Array[Area2D] = []
var _peek_tw: Tween = null
var _hide_y := 0.0
var _animal_scale := 1.0

func _ready() -> void:
	var s := UI.vs(self)
	Scenery.background(self, "background-hideseek")
	add_home_button()
	add_ambient(1)

	_animal_scale = (s.x * 0.110) / 230.0
	var baseline := s.y * 0.95  # dno svih skrovišta

	for i in SPOT_DATA.size():
		var d: Dictionary = SPOT_DATA[i]
		var sc: float = (s.x * d.frac_w) / d.w
		var h: float = d.h * sc
		var center := Vector2(s.x * d.x, baseline - h / 2.0)
		spots.append({"pos": center, "top": baseline - h})
		spot_nodes.append(_build_spot(i, d.svg, center, sc, d.w * sc, h))

	_next_round()

func _build_spot(idx: int, svg_name: String, center: Vector2, sc: float, w: float, h: float) -> Area2D:
	var area := Area2D.new()
	area.position = center
	area.z_index = 20  # skrovišta su ISPRED sakrivene životinje
	var spr := Sprite2D.new()
	spr.texture = load("res://art/svg/%s.svg" % svg_name)
	spr.scale = Vector2.ONE * sc
	area.add_child(spr)

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

	# životinja se pojavi iznad sredine, javi se...
	animal_node = AnimalSprite.new(animal, _animal_scale)
	animal_node.position = Vector2(s.x / 2, s.y * 0.24)
	animal_node.interactive = false
	animal_node.z_index = 5
	add_child(animal_node)
	Audio.animal_voice(animal.id)
	UI.bounce(animal_node, animal_node.base_scale)

	# ...pa otrči iza skrovišta (celo lice ispod gornje ivice)
	var spot: Dictionary = spots[hiding_idx]
	var head_r := 115.0 * _animal_scale
	var target := Vector2(spot.pos.x, spot.top + head_r * 1.15)
	_hide_y = target.y
	var tw := create_tween()
	tw.tween_interval(1.1)
	tw.tween_property(animal_node, "position", target, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_callback(func() -> void:
		accepting_taps = true
		_start_peek()
	)

## Povremeno proviri iznad skrovišta pa se brzo uvuče.
func _start_peek() -> void:
	var head_r := 115.0 * _animal_scale
	_peek_tw = create_tween()
	_peek_tw.set_loops()
	_peek_tw.tween_interval(randf_range(1.6, 2.8))
	_peek_tw.tween_property(animal_node, "position:y", _hide_y - head_r * 1.5, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_peek_tw.tween_interval(0.35)
	_peek_tw.tween_property(animal_node, "position:y", _hide_y, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func _stop_peek() -> void:
	if _peek_tw:
		_peek_tw.kill()
		_peek_tw = null

func _on_spot_tapped(idx: int) -> void:
	if not accepting_taps:
		return
	if idx == hiding_idx:
		accepting_taps = false
		_stop_peek()
		UI.haptic(45)
		# našla ga! iskoči iznad skrovišta
		var above := Vector2(spots[idx].pos.x, spots[idx].top - 340.0 * _animal_scale)
		var tw := create_tween()
		tw.tween_property(animal_node, "position", above, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void:
			animal_node.react(true)
			UI.confetti(self, above, 45)
			Audio.play("success")
		)
		tw.tween_interval(1.4)
		tw.tween_callback(_next_round)
	else:
		Audio.play("tap")
		UI.head_shake(spot_nodes[idx])
