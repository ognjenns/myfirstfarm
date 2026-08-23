extends BaseScreen
## Mini-igra: KO SE TO JAVIO? (džungla). Iz oblačića se čuje glas životinje,
## dete tapne pravu od tri ponuđene. Bez teksta, bez kazne, bez tajmera.
## U pitanju su SAMO životinje sa pravim snimljenim glasom — roster se sam
## proširuje kad u sfx/ dodamo novi <id>_0.wav (npr. papagaj).

var roster: Array = []
var answer: Dictionary = {}
var last_answer_id := ""
var bubble: Area2D
var bubble_scale := 1.0
var options: Array[TapButton] = []
var pedestals: Array[Node] = []
var busy := false
var streak := 0

func _ready() -> void:
	home_target = "jungle"
	var s := UI.vs(self)
	Scenery.background(self, "background-quiz")
	add_home_button()
	for a in Animals.JUNGLE:
		if a.id in Animals.SILENT:   # žvakanje se ne može pogoditi kao glas
			continue
		if ResourceLoader.exists("res://sfx/%s_0.wav" % a.id):
			roster.append(a)
	_build_bubble(s)
	_start_round()
	# lebdeće note uz ivice (nikad preko oblačića ni lica)
	var note_timer := Timer.new()
	note_timer.wait_time = 2.6
	note_timer.timeout.connect(_spawn_note)
	add_child(note_timer)
	note_timer.start()
	get_tree().create_timer(1.0).timeout.connect(_spawn_note)

## Oblačić sa notom: pulsira, auto-pusti glas na startu runde, tap = ponovi.
func _build_bubble(s: Vector2) -> void:
	bubble = Area2D.new()
	bubble.position = Vector2(s.x * 0.5, s.y * 0.295)  # centar "glow" zone u pozadini
	bubble_scale = (s.y * 0.40) / 280.0
	bubble.scale = Vector2.ONE * bubble_scale
	var spr := Sprite2D.new()
	spr.texture = load("res://art/svg/sound-bubble.svg")
	bubble.add_child(spr)
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 175.0
	shape.shape = circle
	bubble.add_child(shape)
	bubble.input_event.connect(func(_vp: Node, event: InputEvent, _i: int) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_play_voice()
	)
	add_child(bubble)
	var tw := bubble.create_tween().set_loops()
	tw.tween_property(bubble, "scale", Vector2.ONE * bubble_scale * 1.06, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(bubble, "scale", Vector2.ONE * bubble_scale, 0.55).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

func _play_voice() -> void:
	if answer.is_empty():
		return
	Audio.animal_voice(answer.id)
	UI.bounce(bubble, Vector2.ONE * bubble_scale)

func _start_round() -> void:
	for o in options:
		o.queue_free()
	options.clear()
	for p in pedestals:
		if is_instance_valid(p):
			p.queue_free()
	pedestals.clear()
	busy = false

	# ne ponavljaj istu životinju dva puta zaredom
	var pick: Dictionary = roster[randi() % roster.size()]
	while roster.size() > 1 and pick.id == last_answer_id:
		pick = roster[randi() % roster.size()]
	answer = pick
	last_answer_id = answer.id

	# opcije: tačna + 2 druge iz cele džungle (mamci ne moraju imati glas)
	var pool := Animals.JUNGLE.filter(func(a: Dictionary) -> bool: return a.id != answer.id)
	pool.shuffle()
	var opts: Array = [answer, pool[0], pool[1]]
	opts.shuffle()

	# raspored po dizajnu: centri x 0.253/0.500/0.747, lica y=0.705, postolja ispod
	var s := UI.vs(self)
	var r := s.x * 0.0755
	const XS := [0.253, 0.500, 0.747]
	var ped_scale := (r * 2.0) / 420.0
	for i in opts.size():
		var a: Dictionary = opts[i]
		var cx: float = s.x * XS[i]
		var ped := Scenery.svg(self, "quiz-pedestal", Vector2(cx, s.y * 0.737 + 120.0 * ped_scale), ped_scale, -5)
		pedestals.append(ped)
		var btn := TapButton.new(Vector2(cx, s.y * 0.705), r, Pal.BUTTON_WHITE)
		var face := AnimalFaces.build(a.id)
		face.scale = Vector2.ONE * (r / 130.0)
		btn.add_child(face)
		btn.tapped.connect(_on_pick.bind(btn, a))
		add_child(btn)
		options.append(btn)

	get_tree().create_timer(0.6).timeout.connect(func() -> void:
		if is_instance_valid(self) and not answer.is_empty():
			_play_voice()
	)

func _on_pick(btn: TapButton, a: Dictionary) -> void:
	if busy:
		return
	if a.id != answer.id:
		# blaga reakcija, dete slobodno proba dalje
		Audio.play("wrong", -10.0)
		_shake_no(btn)
		return
	busy = true
	streak += 1
	Audio.play("success", -4.0)
	Audio.animal_voice(a.id)
	UI.haptic(35)
	_jump_spin(btn)
	_sparkle(btn.global_position)
	if streak % 4 == 0:
		celebrate(UI.vs(self) / 2)
		get_tree().create_timer(2.2).timeout.connect(_start_round)
	else:
		get_tree().create_timer(1.4).timeout.connect(_start_round)

## Pogodak: životinja skoči sa postolja i napravi ceo okret, pa doskoči.
func _jump_spin(btn: TapButton) -> void:
	var start_y := btn.position.y
	var tw := btn.create_tween()
	tw.tween_property(btn, "position:y", start_y - 230.0, 0.30).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(btn, "rotation", TAU, 0.62).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tw.tween_property(btn, "position:y", start_y, 0.32).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: btn.rotation = 0.0)

## Promašaj: kratko "ne-ne" drmanje levo-desno, bez drame.
func _shake_no(btn: TapButton) -> void:
	if btn.has_meta("shake_tw"):
		var old: Tween = btn.get_meta("shake_tw")
		if old and old.is_valid():
			old.kill()
	var x: float = btn.get_meta("home_x") if btn.has_meta("home_x") else btn.position.x
	btn.set_meta("home_x", x)
	var tw := btn.create_tween()
	btn.set_meta("shake_tw", tw)
	for off in [26.0, -26.0, 16.0, -16.0, 0.0]:
		tw.tween_property(btn, "position:x", x + off, 0.06)

## Nota koja polako lebdi naviše uz levu ili desnu ivicu, njiše se i bledi.
func _spawn_note() -> void:
	var s := UI.vs(self)
	var left := randf() < 0.5
	var x := s.x * (randf_range(0.07, 0.22) if left else randf_range(0.78, 0.93))
	var note := Sprite2D.new()
	note.texture = load("res://art/svg/note-float-%d.svg" % (1 + randi() % 2))
	note.position = Vector2(x, s.y * 0.68)
	note.scale = Vector2.ONE * randf_range(0.45, 0.72)
	note.rotation = randf_range(-0.15, 0.15)
	note.z_index = -2
	add_child(note)
	var rise := randf_range(4.5, 6.0)
	var tw := note.create_tween()
	tw.tween_property(note, "position:y", s.y * 0.10, rise)
	tw.parallel().tween_property(note, "modulate:a", 0.0, rise).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(note.queue_free)
	var sway := note.create_tween().set_loops()
	sway.tween_property(note, "position:x", x + 26.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	sway.tween_property(note, "position:x", x - 26.0, 0.9).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

## Zvezdice oko pogođene životinje.
func _sparkle(pos: Vector2) -> void:
	for i in 6:
		var ang := TAU * i / 6.0
		var star := UI.circle(self, pos, 9, Pal.SUN, 50)
		var tw := star.create_tween()
		tw.tween_property(star, "position", pos + Vector2(cos(ang), sin(ang)) * 130.0, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw.parallel().tween_property(star, "modulate:a", 0.0, 0.4)
		tw.tween_callback(star.queue_free)
