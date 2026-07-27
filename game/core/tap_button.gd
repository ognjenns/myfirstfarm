class_name TapButton
extends Area2D
## Okruglo dugme za dečije prste — velika tap zona, poskoči na dodir.

signal tapped

var radius: float
var _base_scale := Vector2.ONE
var _pulse_tw: Tween = null

func _init(pos: Vector2, r: float, bg_color := Color.WHITE) -> void:
	position = pos
	radius = r
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = r * 1.15  # tap zona veća od vizuelnog kruga
	shape.shape = circle
	add_child(shape)
	UI.circle(self, Vector2.ZERO, r, bg_color)
	input_event.connect(_on_input)

func _on_input(_vp: Node, event: InputEvent, _idx: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if _pulse_tw:
			_pulse_tw.kill()
			_pulse_tw = null
		Audio.play("pop")
		UI.haptic(25)
		UI.bounce(self, _base_scale)
		tapped.emit()

func set_base_scale(s: Vector2) -> void:
	_base_scale = s
	scale = s

## Blago "disanje" — privlači pažnju na kapije mini-igara.
func start_pulse() -> void:
	_pulse_tw = create_tween()
	_pulse_tw.set_loops()
	_pulse_tw.tween_property(self, "scale", _base_scale * 1.06, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_pulse_tw.tween_property(self, "scale", _base_scale, 0.7).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
