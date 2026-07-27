class_name AnimalSprite
extends Area2D
## Životinja na sceni: vektorska faca (AnimalFaces) + senka na zemlji.
## Idle "disanje", tap → glasanje + squash-and-stretch.

signal tapped(animal: Dictionary)

var animal: Dictionary
var base_scale := Vector2.ONE
var interactive := true
var face: Node2D

func _init(animal_data: Dictionary, spr_scale := 1.0) -> void:
	animal = animal_data
	base_scale = Vector2.ONE * spr_scale

	Scenery.ground_shadow(self, Vector2(0, 100), 88.0)
	face = AnimalFaces.build(animal.id)
	add_child(face)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 105.0  # u lokalnim koordinatama, skalira se sa node-om
	shape.shape = circle
	add_child(shape)

	scale = base_scale
	input_event.connect(_on_input)

func _ready() -> void:
	_start_idle()

func _start_idle() -> void:
	# blago "disanje" sa random faznim pomakom da farma deluje živo
	var tw := create_tween()
	tw.set_loops()
	var d := randf_range(0.9, 1.4)
	tw.tween_interval(randf_range(0.0, 0.8))
	tw.tween_property(face, "scale", Vector2(1.0, 1.035), d).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(face, "scale", Vector2.ONE, d).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _on_input(_vp: Node, event: InputEvent, _idx: int) -> void:
	if not interactive:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		react()
		tapped.emit(animal)

## Glasanje + poskok (poziva se i spolja, npr. kad je nahranjena).
func react(happy := false) -> void:
	if happy:
		Audio.animal_happy(animal.id)
	else:
		Audio.animal_voice(animal.id)
	UI.bounce(self, base_scale)

func shake() -> void:
	UI.head_shake(self)
