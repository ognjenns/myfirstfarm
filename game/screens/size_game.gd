extends BaseScreen
## Mini-igra: VELIKO I MALO (džungla). Životinje stoje na ivici terase,
## dole su žbunovi-kućice različitih veličina. Dete prevuče slona u veliki
## žbun, majmuna u mali. Runde: odmah 3 veličine, posle tri runde 4.
## Veština: poređenje veličina — nema je ni u jednom drugom svetu.

## Ko je koje veličine; iz svake klase se bira jedan nasumično.
const SIZES := {
	"xl":     {"ids": ["elephant", "giraffe"], "h": 0.36, "bush": 0.27},
	"big":    {"ids": ["hippo", "lion"],       "h": 0.26, "bush": 0.20},
	"medium": {"ids": ["monkey"],              "h": 0.18, "bush": 0.145},
	"small":  {"ids": ["parrot"],              "h": 0.12, "bush": 0.10},
}
const LOG_TOP := 0.58     # prednja ivica gornje terase (stopala životinja)
const BUSH_Y := 1.02      # oslonac žbunova (koren ispod ivice)

var round_num := 0
var animals_on_screen: Array = []   # DragBody
var bushes: Array = []              # {node, size, x}
var left := 0
var _round_nodes: Array = []


func _ready() -> void:
	home_target = "jungle"
	var s := UI.vs(self)
	_build_scene(s)
	add_home_button()
	add_hint(6.0)
	_start_round()


## Svoj kutak: proplanak na dve terase — gornja terasa (na njoj stoje
## životinje) sa travom po ivici, donja traka tla sa žbunovima-kućicama.
func _build_scene(s: Vector2) -> void:
	JungleScene.background(self)
	JungleScene.place(self, "vine-hang", Vector2(0.10, -0.01), 0.24, true, -42, Vector2(0.5, 0.0))
	JungleScene.place(self, "vine-hang-long", Vector2(0.88, -0.01), 0.30, true, -42, Vector2(0.5, 0.0), true)
	# travnat brežuljak: trava od gornje terase do donje trake tla, sa
	# zemljanom ivicom terase na LOG_TOP — na njoj stoje životinje
	var top := s.y * (LOG_TOP - 0.13)
	var edge := s.y * LOG_TOP
	var edge_b := s.y * (LOG_TOP + 0.05)
	UI.poly(self, PackedVector2Array([Vector2(0, top), Vector2(s.x, top), Vector2(s.x, s.y), Vector2(0, s.y)]), Color("#7DC945"), Vector2.ZERO, -58)
	UI.poly(self, PackedVector2Array([Vector2(0, edge), Vector2(s.x, edge), Vector2(s.x, s.y), Vector2(0, s.y)]), Color("#69B23A"), Vector2.ZERO, -58)
	UI.poly(self, PackedVector2Array([Vector2(0, edge), Vector2(s.x, edge), Vector2(s.x, edge_b), Vector2(0, edge_b)]), Color("#6B4526"), Vector2.ZERO, -30)
	UI.poly(self, PackedVector2Array([Vector2(0, edge), Vector2(s.x, edge), Vector2(s.x, edge + 10.0), Vector2(0, edge + 10.0)]), Color("#4E2F18"), Vector2.ZERO, -29)
	for x in [0.05, 0.22, 0.40, 0.58, 0.76, 0.94]:
		JungleScene.place(self, "grass-top", Vector2(x, LOG_TOP + 0.005), 0.08, false, -28)
	JungleScene.place(self, "grass-drape", Vector2(0.31, LOG_TOP), 0.04, false, -28, Vector2(0.5, 0.0))
	JungleScene.place(self, "grass-drape", Vector2(0.67, LOG_TOP), 0.04, false, -28, Vector2(0.5, 0.0), true)
	JungleScene.place(self, "rock-4", Vector2(0.95, LOG_TOP + 0.01), 0.07, false, -31)
	JungleScene.place(self, "plant-1", Vector2(0.03, LOG_TOP + 0.01), 0.08, false, -31)


func _sizes_for_round() -> Array:
	return ["xl", "big", "medium"] if round_num < 3 else ["xl", "big", "medium", "small"]


func _start_round() -> void:
	for n in _round_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_round_nodes.clear()
	animals_on_screen.clear()
	bushes.clear()

	var s := UI.vs(self)
	var sizes := _sizes_for_round()
	var n := sizes.size()
	left = n
	var xs: Array = []
	for i in n:
		xs.append(0.5 + (float(i) - float(n - 1) / 2.0) * (0.30 if n == 3 else 0.24))

	# žbunovi-kućice dole, nasumičnim redom veličina
	var bush_order := sizes.duplicate()
	bush_order.shuffle()
	for i in n:
		var size: String = bush_order[i]
		var b := JungleScene.place(self, "bush-2", Vector2(xs[i], BUSH_Y), float(SIZES[size].bush), false, 12)
		_round_nodes.append(b)
		bushes.append({"node": b, "size": size, "x": s.x * float(xs[i])})

	# životinje na deblu, drugim nasumičnim redom
	var animal_order := sizes.duplicate()
	animal_order.shuffle()
	for i in n:
		var size: String = animal_order[i]
		var ids: Array = SIZES[size].ids
		var id: String = ids[randi() % ids.size()]
		var d := DragBody.new(Animals.by_id_jungle(id), size, s.y * float(SIZES[size].h), float(xs[i]) < 0.5)
		d.position = Vector2(s.x * float(xs[i]), s.y * LOG_TOP)
		d.dropped.connect(_on_dropped)
		add_child(d)
		animals_on_screen.append(d)
		_round_nodes.append(d)


func _bush_hit(d: DragBody) -> Dictionary:
	var s := UI.vs(self)
	var best := {}
	var best_d: float = s.x * 0.14
	for b in bushes:
		var target := Vector2(b.x, s.y * 0.90)
		var dist: float = d.global_position.distance_to(target)
		if dist < best_d:
			best_d = dist
			best = b
	return best


func _on_dropped(d: DragBody) -> void:
	var b := _bush_hit(d)
	if b.is_empty():
		d.go_home()
		return
	if b.size != d.size:
		Audio.play("wrong", -8.0)
		d.body.shake()
		d.go_home()
		return
	# pogodak: ušeta u svoj žbun (iza njega) i javi se
	left -= 1
	d.locked = true
	var s := UI.vs(self)
	Audio.play("plop")
	UI.haptic(35)
	d.z_index = 5   # iza žbuna (z 12)
	var tw := create_tween()
	tw.tween_property(d, "position", Vector2(b.x, s.y * 0.97), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		d.body.react()
		glow(Vector2(b.x, s.y * 0.88), s.y * 0.22)
	)
	if left == 0:
		round_num += 1
		get_tree().create_timer(1.2).timeout.connect(func() -> void: Audio.play(["yay", "giggle", "kid"][randi() % 3], -2.0))
		get_tree().create_timer(2.6).timeout.connect(_start_round)


## Prevlačenje se iz slike ne vidi: prst pokaže jednu životinju i njen žbun.
func hint_spot() -> Dictionary:
	var s := UI.vs(self)
	for d in animals_on_screen:
		if not is_instance_valid(d) or d.locked or d.dragging:
			continue
		for b in bushes:
			if b.size == d.size:
				return {"from": d.position + Vector2(0, -d.body.body_size().y * 0.5), "to": Vector2(b.x, s.y * 0.90)}
	return {}


## Životinja koja se prevlači: telo iz paketa u Area2D sa "lepljivim" hvatom
## za male prste (isto kao hrana na farmi).
class DragBody extends Area2D:
	signal dropped(d: DragBody)

	var body: FarmBody
	var size: String
	var home_pos := Vector2.ZERO
	var dragging := false
	var locked := false

	func _init(animal: Dictionary, size_name: String, height: float, face_right: bool) -> void:
		size = size_name
		z_index = 8
		body = FarmBody.new(animal, height, face_right)
		body.interactive = false
		add_child(body)
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(maxf(body.body_size().x * 1.1, 190.0), maxf(height * 1.15, 190.0))
		shape.shape = rect
		shape.position = Vector2(0, -height * 0.5)
		add_child(shape)
		input_event.connect(_on_input)

	func _ready() -> void:
		home_pos = position

	func _on_input(_vp: Node, event: InputEvent, _idx: int) -> void:
		if locked:
			return
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dragging = true
			z_index = 30
			Audio.play("pluck")
			body.set_walking(true)

	func _input(event: InputEvent) -> void:
		if not dragging:
			return
		if event is InputEventMouseMotion:
			global_position = get_global_mouse_position() + Vector2(0, body.body_size().y * 0.45)
		elif event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			dragging = false
			z_index = 8
			body.set_walking(false)
			dropped.emit(self)

	func go_home() -> void:
		var tw := create_tween()
		tw.tween_property(self, "position", home_pos, 0.4).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
