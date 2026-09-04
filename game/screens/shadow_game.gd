extends BaseScreen
## Mini-igra: Senka-slagalica. Prevuci životinju na njen obris.
## 6 scena u krug, bez fail-stanja, velikodušan snap.

const SNAP_DIST := 190.0
## Visina tela po vrsti (deo visine ekrana): konj i krava najveći.
const REL := {"horse": 1.0, "cow": 0.80, "goat": 0.74, "pig": 0.58, "chicken": 0.52, "duck": 0.52}
const BODY_H := 0.45
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

	func _init(animal_data: Dictionary, pos: Vector2, height: float) -> void:
		animal = animal_data
		position = pos
		home_pos = pos
		z_index = 20
		# Kupljeno telo (prva sličica stajanja), stopala na čvoru; gleda ulevo.
		var sp := Sprite2D.new()
		sp.texture = load("res://art/farm/%s-idle-1.png" % animal.id)
		var tex := sp.texture.get_size()
		sp.scale = Vector2.ONE * (height / tex.y)
		sp.offset = Vector2(0, -tex.y / 2.0)
		add_child(sp)
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(maxf(tex.x * sp.scale.x, 180.0), maxf(height, 180.0))
		shape.shape = rect
		shape.position = Vector2(0, -height * 0.5)
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
	_build_scene(UI.vs(self))
	add_home_button()
	add_hint(6.0)
	_start_scene()

## Livada iz kupljenog paketa: štala i drveće daleko, strašilo desno čuva
## red senki, žbun i busenje napred. Oblaci iza drveća.
func _build_scene(s: Vector2) -> void:
	var bg := Sprite2D.new()
	bg.texture = load("res://art/farm/bg-road.png")
	var bt := bg.texture.get_size()
	var sc: float = maxf(s.y / bt.y, s.x / bt.x)
	bg.scale = Vector2(sc, sc)
	bg.position = s / 2.0
	bg.z_index = -60
	add_child(bg)
	Scenery.cloud(self, Vector2(s.x * 0.30, 110), 1.0, -50)
	Scenery.cloud(self, Vector2(s.x * 0.80, 90), 0.8, -50)
	# Drugačije dvorište nego u hranjenju: kokošinjac, limun, vetrenjača,
	# kukuruz i strašilo — bez štale.
	_prop("tree-3", 0.11, 0.04, 0.55, -41)
	_prop("coop", 0.21, 0.19, 0.60, -36)
	_prop("lemon-tree", 0.075, 0.40, 0.58, -38)
	_prop("windmill", 0.055, 0.62, 0.55, -38)
	var fan := _prop("windmill-fan", 0.075, 0.62, 0.55, -37)
	fan.offset = Vector2.ZERO
	var mill_h: float = load("res://art/farm/windmill.png").get_size().y * ((s.x * 0.055) / 206.0)
	fan.position = Vector2(s.x * 0.62, s.y * 0.55 - mill_h + fan.texture.get_size().y * fan.scale.y * 0.32)
	_prop("corn-group", 0.13, 0.78, 0.60, -35)
	_prop("haypile", 0.10, 0.54, 0.60, -34)
	_prop("scarecrow", 0.11, 0.935, 0.63, -30)
	_prop("bush-1", 0.10, 0.03, 1.01, 12)
	_prop("bush-2", 0.10, 0.97, 1.02, 12)
	for tx in [0.14, 0.50, 0.84]:
		_prop("tuft", 0.045, tx, 1.005, 11)


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

	# Senke gore: tamne siluete kupljenih tela, stoje na liniji livade
	# (promešan raspored u odnosu na donji red).
	var shadow_order := ids.duplicate()
	shadow_order.shuffle()
	var span: float = 0.72 if n <= 3 else 0.80
	for i in n:
		var id: String = shadow_order[i]
		var sh := Sprite2D.new()
		sh.texture = load("res://art/farm/%s-sil.png" % id)
		var tex := sh.texture.get_size()
		var h: float = s.y * BODY_H * float(REL[id])
		sh.scale = Vector2.ONE * (h / tex.y)
		sh.offset = Vector2(0, -tex.y / 2.0)
		sh.position = Vector2(s.x * (0.5 + (float(i) - float(n - 1) / 2.0) * span / float(n - 1 if n > 1 else 1)), s.y * 0.62)
		sh.z_index = 2
		add_child(sh)
		shadows[id] = sh
		scene_nodes.append(sh)

	# Obojene životinje dole, isti razmak kao senke.
	for i in n:
		var id2: String = ids[i]
		var h2: float = s.y * BODY_H * float(REL[id2])
		var d := DragAnimal.new(Animals.by_id(id2),
			Vector2(s.x * (0.5 + (float(i) - float(n - 1) / 2.0) * span / float(n - 1 if n > 1 else 1)), s.y * 0.97), h2)
		d.dropped.connect(_on_dropped)
		add_child(d)
		scene_nodes.append(d)

## Prst pokaže jednu životinju i njenu senku — inače dete vidi dva reda sličica
## i ne zna da se donji red PREVLAČI na gornji.
func hint_spot() -> Dictionary:
	for d in scene_nodes:
		if d is DragAnimal and not d.solved and not d.dragging and shadows.has(d.animal.id):
			var sh: Node2D = shadows[d.animal.id]
			if sh.visible:
				return {"from": d.position, "to": sh.position}
	return {}


func _on_dropped(d: DragAnimal) -> void:
	var s := UI.vs(self)
	var sh: Node2D = shadows.get(d.animal.id)
	if sh and d.global_position.distance_to(sh.global_position) < SNAP_DIST:
		d.solved = true
		remaining -= 1
		var tw := create_tween()
		tw.tween_property(d, "position", sh.position, 0.2).set_trans(Tween.TRANS_SINE)
		tw.tween_callback(func() -> void:
			sh.visible = false
			Audio.animal_voice(d.animal.id)
			UI.haptic(35)
			_sparkle(d.global_position + Vector2(0, -s.y * 0.12))
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


func _scene_done() -> void:
	scene_idx += 1
	var s := UI.vs(self)
	# Bez konfeta: dečji glas i mali narandžasti sjaj oko složenih životinja.
	Audio.play(["yay", "giggle", "kid"][randi() % 3], -2.0)
	for d in scene_nodes:
		if d is DragAnimal:
			_glow(d.position + Vector2(0, -s.y * 0.12), s.y * 0.16)
	get_tree().create_timer(2.0).timeout.connect(_start_scene)
