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
var options: Array[Node2D] = []   # FarmBody tela na kamenju
var pedestals: Array[Node] = []
var busy := false
var streak := 0
## Sredine tri kamena i visina njihovog vrha (stopala životinja).
const XS := [0.253, 0.500, 0.747]
const ROCK_TOP := 0.76

func _ready() -> void:
	home_target = "jungle"
	var s := UI.vs(self)
	_build_scene(s)
	add_home_button()
	add_hint(6.0)
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

## Svoj kutak džungle, da ne liči na hub: bez krošnje i smeđe trake; tri
## odvojena kamena na kojima stoje životinje, palme sa strane, grana sa
## lišćem ulazi iz gornjeg desnog ugla, malo trave uz donju ivicu.
func _build_scene(s: Vector2) -> void:
	JungleScene.background(self)   # sa smeđom trakom: kamenje stoji na zemlji
	# lijane sa vrha (grana bez debla je lebdela)
	JungleScene.place(self, "vine-hang", Vector2(0.08, -0.01), 0.26, true, -42, Vector2(0.5, 0.0))
	JungleScene.place(self, "vine-hang-long", Vector2(0.90, -0.01), 0.34, true, -42, Vector2(0.5, 0.0), true)
	# palme: podnožje ispod ivice ekrana i lišće oko njega, da ne lebde
	JungleScene.place(self, "palm-trunk", Vector2(0.07, 1.06), 0.56, true, -40)
	JungleScene.place(self, "palm-leaves", Vector2(0.075, 0.535), 0.14, false, -39, Vector2(0.5, 0.55))
	JungleScene.place(self, "palm-trunk", Vector2(0.93, 1.06), 0.50, true, -40, Vector2(0.5, 1.0), true)
	JungleScene.place(self, "palm-leaves", Vector2(0.925, 0.59), 0.13, false, -39, Vector2(0.5, 0.55), true)
	JungleScene.place(self, "tuft-3", Vector2(0.06, 1.01), 0.08, false, -17)
	JungleScene.place(self, "tuft-3", Vector2(0.94, 1.01), 0.08, false, -17, Vector2(0.5, 1.0), true)
	# tri ODVOJENA kamena-postolja (Ognjen: red kamenja dole je bio previše);
	# uz donju ivicu samo malo trave i lišća
	for i in 3:
		JungleScene.place(self, "rock-2", Vector2(XS[i], 0.91), 0.21, false, -5)
		JungleScene.place(self, "grass-top", Vector2(XS[i] - 0.02, 0.775), 0.11, false, -4)
	for x in [0.12, 0.38, 0.62, 0.88]:
		JungleScene.place(self, "grass-top", Vector2(x, 1.01), 0.08, false, -18)
	JungleScene.place(self, "ground-leaves", Vector2(0.25, 1.02), 0.10, false, -18)
	JungleScene.place(self, "ground-leaves", Vector2(0.75, 1.02), 0.10, false, -18, Vector2(0.5, 1.0), true)

## Oblačić sa notom: pulsira, auto-pusti glas na startu runde, tap = ponovi.
func _build_bubble(s: Vector2) -> void:
	bubble = Area2D.new()
	bubble.position = Vector2(s.x * 0.5, s.y * 0.22)
	bubble_scale = (s.y * 0.33) / 280.0
	bubble.scale = Vector2.ONE * bubble_scale
	_draw_bubble(bubble)
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

## Oblačić u stilu paketa (kao karte memorije): senka, tamna kontura, svetla
## ispuna sa svetlijim unutrašnjim okvirom, rep dole-levo; unutra naše note
## (note-float, iste kao u orkestru). Lokalne mere 280×280 kao stari crtež.
const INK := Color("#2B1A0E")

func _draw_bubble(parent: Node2D) -> void:
	var w := 262.0
	var h := 186.0
	UI.poly(parent, UI.rounded_rect_points(w + 12, h + 12, 40), Color(0, 0, 0, 0.20), Vector2(0, 10))
	UI.poly(parent, UI.rounded_rect_points(w + 12, h + 12, 40), INK)
	UI.poly(parent, PackedVector2Array([Vector2(-104, 78), Vector2(-46, 78), Vector2(-96, 140)]), INK)
	UI.poly(parent, UI.rounded_rect_points(w, h, 34), Color("#F6E9CC"))
	UI.poly(parent, PackedVector2Array([Vector2(-96, 80), Vector2(-56, 80), Vector2(-90, 126)]), Color("#F6E9CC"))
	UI.poly(parent, UI.rounded_rect_points(w - 34, h - 34, 24), Color("#FFF7E4"))
	UI.poly(parent, UI.rounded_rect_points(w - 44, h - 44, 20), Color("#F6E9CC"))
	_note(parent, Vector2(-44, 4), 0.78, 1)
	_note(parent, Vector2(44, 4), 0.78, 2)

## Nota iz našeg SVG-a (note-float-1/2, 140×180).
func _note(parent: Node2D, pos: Vector2, sc: float, kind: int) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/svg/note-float-%d.svg" % kind)
	sp.position = pos
	sp.scale = Vector2.ONE * sc
	parent.add_child(sp)
	return sp

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

	# tri životinje celim telom, svaka na svom kamenu (stopala na vrhu kamena)
	var s := UI.vs(self)
	for i in opts.size():
		var a: Dictionary = opts[i]
		var cx: float = s.x * XS[i]
		# Krupno, ali da žirafa ne uđe u oblačić (dno mu je na ~0.46 visine).
		var rel: float = {"giraffe": 1.05, "elephant": 0.85, "hippo": 0.75, "lion": 0.80, "monkey": 0.68, "parrot": 0.50}.get(a.id, 0.7)
		var body := FarmBody.new(a, s.y * 0.40 * rel, i == 0)   # leva gleda udesno
		# Kamen ima ravan vrh na levoj polovini (desno se spušta): telo stoji
		# na sredini ravnog dela, ne na sredini celog kamena.
		body.position = Vector2(cx - s.x * 0.021 - body.feet_shift(), s.y * ROCK_TOP)
		body.interactive = false   # dodir vodi kviz (glas se ne sme sam pustiti)
		body.z_index = 2
		body.set_meta("animal_id", a.id)  # za pokazivač: koja je tačna
		body.set_meta("home_x", cx)
		add_child(body)
		options.append(body)
		var area := Area2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = body.body_size() * 1.15
		shape.shape = rect
		shape.position = Vector2(0, -body.body_size().y * 0.5)
		area.add_child(shape)
		body.add_child(area)
		area.input_event.connect(func(_vp: Node, event: InputEvent, _i: int) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_on_pick(body, a)
		)

	get_tree().create_timer(0.6).timeout.connect(func() -> void:
		if is_instance_valid(self) and not answer.is_empty():
			_play_voice()
	)

## Zvuk je već pušten, ali dete ne mora da poveže glas sa licem — posle pauze
## prst pokaže tačno lice. Bolje pokazati nego pustiti ga da odustane.
func hint_spot() -> Dictionary:
	if busy or answer.is_empty():
		return {}
	for o in options:
		if is_instance_valid(o) and o.get_meta("animal_id", "") == answer.id:
			return {"at": o.position + Vector2(0, -(o as FarmBody).body_size().y * 0.5), "size": 1.6}
	return {}


func _on_pick(btn: FarmBody, a: Dictionary) -> void:
	if busy:
		return
	if a.id != answer.id:
		# blaga reakcija, dete slobodno proba dalje
		Audio.play("wrong", -8.0)
		_shake_no(btn)
		return
	busy = true
	streak += 1
	UI.haptic(35)
	btn.react()          # svoj glas + svoja tačka (rika, skok, lepršanje...)
	_jump(btn)
	_sparkle(btn.global_position + Vector2(0, -btn.body_size().y * 0.5))
	if streak % 4 == 0:
		# bez konfeta: dečji glas + bljesak na sve tri životinje
		Audio.play(["yay", "giggle", "kid"][randi() % 3], -2.0)
		for o in options:
			if is_instance_valid(o):
				glow(o.position + Vector2(0, -(o as FarmBody).body_size().y * 0.5), (o as FarmBody).body_size().y * 1.3)
		get_tree().create_timer(2.2).timeout.connect(_start_round)
	else:
		get_tree().create_timer(1.4).timeout.connect(_start_round)

## Pogodak: životinja poskoči sa kamena i doskoči (bez okreta — tela iz
## paketa imaju svoju tačku, okret bi izgledao kao lutka).
func _jump(btn: FarmBody) -> void:
	var start_y := btn.position.y
	var tw := btn.create_tween()
	tw.tween_property(btn, "position:y", start_y - 160.0, 0.28).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(btn, "position:y", start_y, 0.30).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)

## Promašaj: kratko "ne-ne" drmanje levo-desno, bez drame.
func _shake_no(btn: Node2D) -> void:
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
	var note := _note(self, Vector2(x, s.y * 0.68), 1.0, 1 + randi() % 2)
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
