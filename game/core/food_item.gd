class_name FoodItem
extends Area2D
## Hrana za mini-igru Nahrani — SVG asset (art/svg/food-<kind>.svg),
## "lepljiv" drag za male prste.

signal dropped(food: FoodItem)

var kind: String
var home_pos: Vector2
var dragging := false
var locked := false  # posle uspešnog hranjenja — ignoriši dodire dok traje animacija
var base_s := Vector2.ONE

func _init(food_kind: String, pos: Vector2, visible_width := 150.0) -> void:
	kind = food_kind
	position = pos
	home_pos = pos
	z_index = 20

	var sprite := Sprite2D.new()
	# Kupljeni crteži hrane (art/food/<kind>.png) imaju prednost nad starim
	# SVG-ovima; ako za neku hranu ne postoje, ostaje stari crtež. Tako se
	# nova hrana dodaje samo ubacivanjem fajla, bez ijedne izmene koda.
	var bought := "res://art/food/%s.png" % kind
	if ResourceLoader.exists(bought):
		sprite.texture = load(bought)
		# Kupljeni su u kvadratu 320 px, a crtež zauzima gotovo ceo kvadrat.
		sprite.scale = Vector2.ONE * (visible_width / 260.0)
	else:
		sprite.texture = load("res://art/svg/food-%s.svg" % kind)
		# item zauzima ~75% od 256px kanvasa
		sprite.scale = Vector2.ONE * (visible_width / 192.0)
	add_child(sprite)

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = maxf(visible_width * 0.75, 95.0)  # velika tap zona
	shape.shape = circle
	add_child(shape)
	input_event.connect(_on_input)

func _ready() -> void:
	base_s = scale

func _on_input(_vp: Node, event: InputEvent, _idx: int) -> void:
	if locked:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = true
		z_index = 30
		Audio.play("pluck")
		var tw := create_tween()
		tw.tween_property(self, "scale", base_s * 1.25, 0.1)

func _input(event: InputEvent) -> void:
	if not dragging:
		return
	if event is InputEventMouseMotion:
		global_position = get_global_mouse_position()
	elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		dragging = false
		z_index = 20
		var tw := create_tween()
		tw.tween_property(self, "scale", base_s, 0.1)
		dropped.emit(self)

## Vrati se na korito (promašaj — bez kazne).
func go_home() -> void:
	var tw := create_tween()
	tw.tween_property(self, "position", home_pos, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

## Animacija jedenja: hrana upadne u činiju/usta i nestane.
func eaten_by(target_pos: Vector2) -> void:
	locked = true
	dragging = false
	var tw := create_tween()
	tw.tween_property(self, "global_position", target_pos, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(self, "scale", base_s * 0.1, 0.22)
	tw.parallel().tween_property(self, "rotation", randf_range(-0.8, 0.8), 0.22)
	tw.tween_callback(queue_free)
