extends BaseScreen
## Mini-igra: Senka-slagalica. Prevuci životinju na njen obris.
## 6 scena u krug, bez fail-stanja, velikodušan snap.

const SNAP_DIST := 160.0
const SCENES := [
	["cow", "pig", "chicken"],
	["horse", "duck", "goat"],
	["chicken", "goat", "cow", "duck"],
	["pig", "horse", "chicken"],
	["duck", "cow", "goat", "pig"],
	["horse", "chicken", "goat", "cow"],
]

var scene_idx := 0
var remaining := 0
var shadows := {}  # id -> Node2D (silueta)
var scene_nodes: Array[Node] = []

## Prevlačiva životinja (obojena, dole u redu).
class DragAnimal extends Area2D:
	signal dropped(node)
	var animal: Dictionary
	var home_pos: Vector2
	var dragging := false
	var solved := false

	func _init(animal_data: Dictionary, pos: Vector2) -> void:
		animal = animal_data
		position = pos
		home_pos = pos
		z_index = 20
		add_child(AnimalFaces.build(animal.id))
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 105.0
		shape.shape = circle
		add_child(shape)
		input_event.connect(_on_input)

	func _on_input(_vp: Node, event: InputEvent, _idx: int) -> void:
		if solved:
			return
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dragging = true
			z_index = 30
			Audio.play("pluck")

	func _input(event: InputEvent) -> void:
		if not dragging:
			return
		if event is InputEventMouseMotion:
			global_position = get_global_mouse_position()
		elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dragging = false
			z_index = 20
			dropped.emit(self)

	func go_home() -> void:
		var tw := create_tween()
		tw.tween_property(self, "position", home_pos, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _ready() -> void:
	Scenery.background(self, "background-shadows")
	add_home_button()
	_start_scene()

func _start_scene() -> void:
	for n in scene_nodes:
		if is_instance_valid(n):
			n.queue_free()
	scene_nodes.clear()
	shadows.clear()

	var s := UI.vs(self)
	var ids: Array = SCENES[scene_idx % SCENES.size()]
	remaining = ids.size()
	var n := ids.size()

	# siluete gore (promešan raspored u odnosu na donji red)
	var shadow_order := ids.duplicate()
	shadow_order.shuffle()
	for i in n:
		var id: String = shadow_order[i]
		var sh := AnimalFaces.build(id)
		sh.modulate = Color(0.30, 0.27, 0.32, 0.95)
		sh.scale = Vector2(1.4, 1.4)
		sh.position = Vector2(s.x * (i + 1) / (n + 1), s.y * 0.37)
		add_child(sh)
		shadows[id] = sh
		scene_nodes.append(sh)

	# obojene životinje dole
	for i in n:
		var d := DragAnimal.new(Animals.by_id(ids[i]), Vector2(s.x * (i + 1) / (n + 1), s.y * 0.81))
		d.dropped.connect(_on_dropped)
		add_child(d)
		scene_nodes.append(d)

func _on_dropped(d: DragAnimal) -> void:
	var sh: Node2D = shadows.get(d.animal.id)
	if sh and d.global_position.distance_to(sh.global_position) < SNAP_DIST:
		d.solved = true
		remaining -= 1
		var tw := create_tween()
		tw.tween_property(d, "position", sh.position, 0.2).set_trans(Tween.TRANS_SINE)
		tw.parallel().tween_property(d, "scale", Vector2(1.4, 1.4), 0.2)
		tw.tween_callback(func() -> void:
			sh.visible = false
			Audio.animal_voice(d.animal.id)
			UI.haptic(35)
			_sparkle(d.global_position)
		)
		if remaining == 0:
			_scene_done()
		return
	# nije pogodila — samo se vrati, bez drame
	Audio.play("wrong", -8.0)
	d.go_home()

## Male "zvezdice" kad životinja legne na senku.
func _sparkle(pos: Vector2) -> void:
	for i in 6:
		var a := TAU * i / 6.0
		var star := UI.circle(self, pos, 9, Pal.SUN, 50)
		var tw := star.create_tween()
		tw.tween_property(star, "position", pos + Vector2(cos(a), sin(a)) * 110.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(star, "modulate:a", 0.0, 0.4)
		tw.tween_callback(star.queue_free)

func _scene_done() -> void:
	scene_idx += 1
	var s := UI.vs(self)
	celebrate(Vector2(s.x / 2, s.y * 0.37))
	get_tree().create_timer(2.0).timeout.connect(_start_scene)
