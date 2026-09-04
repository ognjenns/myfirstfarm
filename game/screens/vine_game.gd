extends BaseScreen
## Mini-igra: MAJMUN SA LIJANE NA LIJANU (džungla). Lijane se ljuljaju,
## majmun visi na prvoj; dete tapne bilo gde i majmun preleti na sledeću,
## pa na sledeću, do banane na poslednjoj. Bez promašaja — svaki skok stigne,
## a draž je u tajmingu i letu. Runde: 3, 3, 4, 4, 5, 5, pa 6 lijana.
## Veštine: tapni u pravom trenutku, uzrok i posledica. Ništa slično nema
## ni farma ni okean.

const VINE_LEN := 0.40       # dužina lijane kao deo visine ekrana
const MONKEY_H := 0.26       # visina majmuna kao deo visine ekrana

var round_num := 0
var _vines: Array = []       # {node, len, phase, amp, speed}
var _monkey: FarmBody        # visi (monkey-vine)
var _flyer: Sprite2D         # sličice skoka dok leti
var _jump_frames: Array = []
var _banana: Sprite2D
var _at := 0                 # na kojoj lijani visi
var _flying := false
var _busy := false
var _t := 0.0
var _fly_t := 0.0
var _fly_from := Vector2.ZERO
var _round_nodes: Array = []


func _ready() -> void:
	home_target = "jungle"
	var s := UI.vs(self)
	_build_scene(s)
	add_home_button()
	add_hint(6.0)
	for i in 10:
		_jump_frames.append(load("res://art/jungle/monkey-jump-%d.png" % (i + 1)))
	_flyer = Sprite2D.new()
	_flyer.texture = _jump_frames[0]
	_flyer.scale = Vector2.ONE * ((s.y * MONKEY_H) / _flyer.texture.get_size().y)
	_flyer.visible = false
	_flyer.z_index = 6
	add_child(_flyer)
	_start_round()


## "Gornji sprat" džungle — svoj kutak, ne liči na hub: krošnja gore, visoka
## debla uz obe ivice, dole vrhovi žbunja i palminog lišća, bez trake tla.
func _build_scene(_s: Vector2) -> void:
	JungleScene.background(self, false)
	JungleScene.place(self, "canopy-2", Vector2(0.50, -0.01), 1.08, false, -45, Vector2(0.5, 0.0))
	JungleScene.place(self, "trunk-3", Vector2(0.035, 1.05), 1.25, true, -44)
	JungleScene.place(self, "trunk-4", Vector2(0.965, 1.05), 1.20, true, -44, Vector2(0.5, 1.0), true)
	JungleScene.place(self, "palm-leaves", Vector2(0.20, 1.04), 0.16, false, 12, Vector2(0.5, 0.3))
	JungleScene.place(self, "palm-leaves", Vector2(0.80, 1.04), 0.16, false, 12, Vector2(0.5, 0.3), true)
	JungleScene.place(self, "bush-2", Vector2(0.50, 1.06), 0.20, false, 12)
	JungleScene.place(self, "bush-1", Vector2(0.03, 1.05), 0.14, false, 12)
	JungleScene.place(self, "bush-3", Vector2(0.97, 1.05), 0.14, false, 12, Vector2(0.5, 1.0), true)


func _vine_count() -> int:
	return clampi(3 + round_num / 2, 3, 6)


func _start_round() -> void:
	for n in _round_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_round_nodes.clear()
	_vines.clear()
	_flying = false
	_busy = false
	_flyer.visible = false

	var s := UI.vs(self)
	var n := _vine_count()
	var span := 0.74 if n <= 5 else 0.80
	for i in n:
		var x: float = s.x * (0.5 + (float(i) - float(n - 1) / 2.0) * (span / float(n - 1)))
		var v := Node2D.new()
		v.position = Vector2(x, -4.0)
		v.z_index = 3
		add_child(v)
		_round_nodes.append(v)
		var sp := Sprite2D.new()
		sp.texture = load("res://art/jungle/vine-hang-long.png")
		var th := sp.texture.get_size()
		var len: float = s.y * VINE_LEN * (1.0 + 0.12 * float(i % 2))
		sp.scale = Vector2((s.x * 0.032) / th.x, len / th.y)
		sp.offset = Vector2(0, th.y / 2.0)   # visi sa čvora
		v.add_child(sp)
		_vines.append({"node": v, "len": len, "phase": randf() * TAU,
			"amp": deg_to_rad(randf_range(11.0, 16.0)), "speed": randf_range(1.2, 1.6)})

	_monkey = FarmBody.new(Animals.by_id_jungle("monkey"), s.y * MONKEY_H, false, "monkey-vine")
	_monkey.interactive = false
	_monkey.z_index = 1
	_round_nodes.append(_monkey)
	_attach(0)

	# banana visi na poslednjoj lijani
	_banana = Sprite2D.new()
	_banana.texture = load("res://art/food/banana.png")
	_banana.scale = Vector2.ONE * ((s.y * 0.11) / 260.0)
	_banana.position = Vector2(0, _vines[n - 1].len + s.y * 0.02)
	_banana.rotation = 0.6
	_vines[n - 1].node.add_child(_banana)


## Majmun se prikači na lijanu i: čvor su mu ruke, na kraju lijane.
func _attach(i: int) -> void:
	_at = i
	var v: Dictionary = _vines[i]
	if _monkey.get_parent():
		_monkey.get_parent().remove_child(_monkey)
	v.node.add_child(_monkey)
	_monkey.position = Vector2(0, v.len)
	_monkey.rotation = 0.0
	_monkey.visible = true


func _process(delta: float) -> void:
	_t += delta
	for v in _vines:
		v.node.rotation = sin(_t * v.speed + v.phase) * v.amp
	if _flying:
		_fly_t += delta / 0.62
		var u: float = minf(_fly_t, 1.0)
		var to: Vector2 = _hands_of(_at + 1)
		var s := UI.vs(self)
		var pos: Vector2 = _fly_from.lerp(to, u) + Vector2(0, -sin(u * PI) * s.y * 0.22)
		_flyer.global_position = pos + Vector2(0, s.y * MONKEY_H * 0.5)
		_flyer.rotation = lerpf(-0.3, 0.25, u) * signf(to.x - _fly_from.x)
		_flyer.texture = _jump_frames[clampi(int(u * 9.0), 0, 9)]
		_flyer.scale.x = absf(_flyer.scale.x) * (-1.0 if to.x > _fly_from.x else 1.0)
		if u >= 1.0:
			_land()


## Gde su TRENUTNO ruke na kraju lijane i (u koordinatama ekrana).
func _hands_of(i: int) -> Vector2:
	var v: Dictionary = _vines[i]
	return v.node.to_global(Vector2(0, v.len))


func _input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		# kućica gore levo ostaje kućica
		if event.position.x < 230.0 and event.position.y < 230.0:
			return
		_jump()


func _jump() -> void:
	if _flying or _busy or _at >= _vines.size() - 1:
		return
	_flying = true
	_fly_t = 0.0
	_fly_from = _hands_of(_at)
	_monkey.visible = false
	_flyer.visible = true
	Audio.play("pluck")
	UI.haptic(25)


func _land() -> void:
	_flying = false
	_flyer.visible = false
	_attach(_at + 1)
	_monkey.play_react()   # ljuljne se gore-dole na novoj lijani
	if _at == _vines.size() - 1:
		_reach_banana()
	else:
		Audio.play("pop", -6.0)


## Stigao do banane: pojede je (skupi se u ruke), glas, bljesak, nova runda.
func _reach_banana() -> void:
	_busy = true
	round_num += 1
	var tw := create_tween()
	tw.tween_property(_banana, "scale", Vector2.ZERO, 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	Audio.play("nom")
	UI.haptic(50)
	get_tree().create_timer(0.35).timeout.connect(func() -> void:
		Audio.animal_voice("monkey")
		var s := UI.vs(self)
		glow(_monkey.global_position + Vector2(0, s.y * MONKEY_H * 0.5), s.y * MONKEY_H * 1.4)
	)
	get_tree().create_timer(1.1).timeout.connect(func() -> void: Audio.play(["yay", "giggle", "kid"][randi() % 3], -2.0))
	get_tree().create_timer(2.4).timeout.connect(_start_round)


## Prst tapne majmuna — to je sve što treba da se uradi.
func hint_spot() -> Dictionary:
	if _flying or _busy or _vines.is_empty():
		return {}
	var s := UI.vs(self)
	return {"at": _hands_of(_at) + Vector2(0, s.y * MONKEY_H * 0.5), "size": 1.6}
