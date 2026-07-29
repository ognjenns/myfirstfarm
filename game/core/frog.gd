class_name Frog
extends Area2D
## Žabica na bari (farma): sedi, "diše", povremeno poskoči uz plop,
## a na tap skoči više — mali živi detalj koji mami tap.

var _t := 0.0
var _hop_timer := 0.0
var _hopping := false
var _body: Node2D
var _base_y := 0.0

func _init(pos: Vector2) -> void:
	position = pos
	_base_y = pos.y
	z_index = 10  # iznad bare I ispred životinja (skače ispred svinje)
	_hop_timer = randf_range(3.0, 6.0)

	_body = Node2D.new()
	add_child(_body)
	# telo sa konturom
	UI.circle(_body, Vector2(2, 26), 26, Color(0.2, 0.3, 0.15, 0.18))  # senka na vodi
	UI.circle(_body, Vector2.ZERO, 37, Pal.OUTLINE)
	UI.circle(_body, Vector2.ZERO, 32, Color("#8FBF6F"))
	# stomačić svetliji
	UI.circle(_body, Vector2(0, 12), 18, Color("#C9E4AE"))
	# nožice sa strane
	for sx in [-1, 1]:
		UI.circle(_body, Vector2(sx * 28, 22), 12, Pal.OUTLINE)
		UI.circle(_body, Vector2(sx * 28, 22), 9, Color("#7FAF60"))
	# oči-kupole na vrhu (buljave, ali male zenice nisko — simpatično ne strašno)
	for sx in [-1, 1]:
		UI.circle(_body, Vector2(sx * 16, -28), 14, Pal.OUTLINE)
		UI.circle(_body, Vector2(sx * 16, -28), 11, Color.WHITE)
		UI.circle(_body, Vector2(sx * 16, -24), 4.5, Pal.EYE)
	# rumeni obraščići + osmeh
	for sx in [-1, 1]:
		UI.circle(_body, Vector2(sx * 22, -6), 5, Color(0.95, 0.6, 0.6, 0.55))
	UI.poly(_body, UI.rect_points(16, 3), Pal.OUTLINE, Vector2(0, 2))

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 75.0
	shape.shape = circle
	add_child(shape)
	input_event.connect(func(_vp: Node, event: InputEvent, _i: int) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_hop(true)
	)

func _process(delta: float) -> void:
	_t += delta
	if not _hopping:
		# disanje
		_body.scale.y = 1.0 + sin(_t * 2.2) * 0.035
		_hop_timer -= delta
		if _hop_timer <= 0.0:
			_hop_timer = randf_range(4.0, 8.0)
			_hop(false)

## Skok: čučanj → skok sa istezanjem → sleti uz plop i squash.
func _hop(big: bool) -> void:
	if _hopping:
		return
	_hopping = true
	var h := 90.0 if big else 45.0
	# pravo kreketanje: glasnije na tap, tiše kad sama skakuće
	Audio.play("frog", -4.0 if big else -12.0, randf_range(0.92, 1.12))
	if big:
		UI.haptic(20)
	var tw := create_tween()
	tw.tween_property(_body, "scale", Vector2(1.15, 0.8), 0.09)
	tw.tween_property(_body, "scale", Vector2(0.9, 1.15), 0.1)
	tw.parallel().tween_property(self, "position:y", _base_y - h, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(self, "position:y", _base_y, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_property(_body, "scale", Vector2(1.18, 0.82), 0.08)
	tw.tween_property(_body, "scale", Vector2.ONE, 0.12)
	tw.tween_callback(func() -> void: _hopping = false)
