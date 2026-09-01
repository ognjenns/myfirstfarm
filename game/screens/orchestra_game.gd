extends BaseScreen
## Mini-igra: PODVODNI ORKESTAR (okean). Šest bića sedi na koralnim stubovima
## različite visine; tap na neko od njih pusti notu, biće otpeva jedan ciklus,
## a iz usta mu izleti mehurić sa notom.
##
## Jedina igra u aplikaciji BEZ zadatka: nema cilja, nema kraja, nema greške.
## Za uzrast 2–3 je uzrok-posledica najjača mehanika, a pentatonska lestvica
## znači da bilo koji redosled zvuči lepo — dete ne može da "pogreši".
##
## Visina stuba je i visina tona: prvi stub najniži ton, šesti najviši. Time se
## lestvica VIDI, ne samo čuje.

## [vrsta, stub, boja note] — redosled je i redosled tonova
const BAND := [
	["clown",    1, Color("#D9645F")],
	["tang",     2, Color("#E0873E")],
	["puffer",   3, Color("#E8C34A")],
	["turtle",   4, Color("#6FAE64")],
	["seahorse", 5, Color("#4E9CC4")],
	["octopus",  6, Color("#9B7BC4")],
]
## Pentatonika: prima, sekunda, terca, kvinta, seksta, oktava.
const PITCH := [1.0, 1.125, 1.25, 1.5, 1.6875, 2.0]
## Iz specifikacije: x centri stubova i visine njihovih sedišta.
## Ceo red je pomeren za 0,025 udesno u odnosu na specifikaciju, jer je prvi
## stub nalegao na levi sanduk. Razmak od 0,137 između stubova ostaje netaknut
## — on je i vizuelna lestvica, pa se ne sme menjati.
const PERCH_X := [0.160, 0.297, 0.434, 0.571, 0.708, 0.845]
const SIT_Y := [0.783, 0.709, 0.635, 0.561, 0.487, 0.413]
## Referentni telefon na kome je igra podesena (19,5:9 → viewport 2340x1080).
const REF := Vector2(2340.0, 1080.0)

const SING_FPS := 14.0
const SING_FRAMES := 8

var _s := Vector2.ZERO
var _t := 0.0
var _players: Array = []     # {node, kind, idx, sing_t, mouth}
var _notes: Array = []        # mehurići sa notom koji se dižu
var _chests: Array = []       # dva sanduka, levo i desno
var _bubbles: Array = []
var _staff: Sprite2D
var _staff_frames: Array = []   # 24 frejma; keširaju se jednom, ne pri svakom kadru


func _ready() -> void:
	home_target = "ocean"
	_s = UI.vs(self)
	Scenery.background(self, "background-orchestra")
	# Notni sistem stoji IZA muzičara, u gornjoj polovini kadra — voda je tu
	# bila prazna. Najviši stub prolazi ispred njega, što daje dubinu.
	_staff = Sprite2D.new()
	for i in 24:
		_staff_frames.append(load("res://art/svg/staff-backdrop-%d.svg" % (i + 1)))
	_staff.texture = _staff_frames[0]
	_staff.scale = Vector2.ONE * ((_s.x * 0.62) / 1600.0)
	_staff.position = Vector2(_s.x * 0.50, _s.y * 0.31)
	_staff.z_index = 1
	add_child(_staff)

	# Pozadinska muzika se gasi: ovo je instrument, pa bi svirala preko onoga
	# što dete samo svira. Vraća se pri izlasku iz igre.
	Audio.set_music_enabled(false)

	# Strane kadra su prazne, a deca su u hubu tražila sanduk koji same otvaraju.
	# Dva su namerno pomerena u vremenu da nikad ne pucaju zajedno.
	_build_chest(0.044, 3.0)
	_build_chest(0.956, 11.0)
	_build_band()
	add_home_button()
	add_hint(6.0)
	set_process(true)


## Pesak je deo pozadine koja se RASTEZE po visini, pa uvek stoji na 0,917h.
## Stubovi se skaliraju po SIRINI, pa im visina u pikselima prati _s.x. Zato se
## rastojanja OD PESKA moraju meriti istom, sirinskom merom — vezana za _s.y,
## sediste i muzicar se na iPadu razidju za oko trecinu stuba.
## Na referentnom telefonu (_s.x = REF.x) vraca 1080 * (0,917 - d), sto je
## identicno starom racunu — telefon se ne menja nimalo.
func _above_ground(d: float) -> float:
	return _s.y * 0.917 - d * REF.y * (_s.x / REF.x)


func _build_band() -> void:
	for i in BAND.size():
		var kind: String = BAND[i][0]
		var perch: int = BAND[i][1]
		var cx: float = _s.x * PERCH_X[i]

		# Stub: oslonac na dnu, sedi na liniji peska.
		var pv := Sprite2D.new()
		pv.texture = load("res://art/svg/coral-perch-%d.svg" % perch)
		var ptex := pv.texture.get_size()
		var psc := (_s.x * 0.103) / ptex.x
		pv.scale = Vector2.ONE * psc
		pv.offset = Vector2(0, -ptex.y / 2.0)
		pv.position = Vector2(cx, _s.y * 0.917)
		pv.z_index = 2
		add_child(pv)

		# Muzičar: dno crteža ulazi 0,061h ispod ivice kapice, da SEDI a ne lebdi.
		var size := _s.x * 0.089
		var sp := Sprite2D.new()
		sp.texture = load("res://art/svg/bubble-fish-%s-sing-1.svg" % kind)
		sp.scale = Vector2.ONE * (size / 256.0)
		sp.position = Vector2(cx, _above_ground(0.917 - SIT_Y[i] - 0.061) - size * 0.5)
		sp.z_index = 3
		add_child(sp)

		var entry := {"node": sp, "kind": kind, "idx": i, "sing": -1.0,
			"mouth": Vector2(cx + size * 0.26, sp.position.y - size * 0.42)}
		_players.append(entry)

		# Tap zona je NAMERNO mnogo veća od bića — dečji prst ne cilja precizno.
		var area := Area2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(_s.x * 0.12, _s.y * 0.20)
		shape.shape = rect
		area.add_child(shape)
		area.position = sp.position
		add_child(area)
		area.input_event.connect(func(_vp: Node, ev: InputEvent, _i: int) -> void:
			if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
				get_viewport().set_input_as_handled()
				_sing(entry)
		)


## Igra nema zadatak, pa dete i ne zna da bića sviraju — prst tapne jedno.
func hint_spot() -> Dictionary:
	if _players.is_empty():
		return {}
	var p: Dictionary = _players[randi() % _players.size()]
	if not is_instance_valid(p.node):
		return {}
	return {"at": p.node.position}


func _build_chest(x: float, first_wait: float) -> void:
	var sc := (_s.x * 0.098) / 520.0
	var node := Node2D.new()
	node.position = Vector2(_s.x * x, _above_ground(0.917 - 0.965) - 400.0 * sc * 0.5)
	node.scale = Vector2.ONE * sc
	node.z_index = 2
	add_child(node)

	var lid := Sprite2D.new()
	lid.texture = load("res://art/svg/chest-lid.svg")
	var t := lid.texture.get_size()
	lid.offset = -Vector2((0.047 - 0.5) * t.x, (0.904 - 0.5) * t.y)
	lid.position = Vector2((0.169 - 0.5) * 520.0, (0.480 - 0.5) * 400.0)
	lid.z_index = -1
	node.add_child(lid)

	var body := Sprite2D.new()
	body.texture = load("res://art/svg/chest-body.svg")
	node.add_child(body)

	var c := {"node": node, "lid": lid, "open": 0.0, "left": 0, "gap": 0.0,
		"wait": first_wait, "emit": Vector2(_s.x * x, _above_ground(0.917 - 0.875))}
	_chests.append(c)

	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(440.0, 340.0)
	shape.shape = rect
	shape.position = Vector2(0.0, 30.0)
	area.add_child(shape)
	node.add_child(area)
	area.input_event.connect(func(_vp: Node, ev: InputEvent, _i: int) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			c.left = mini(c.left + randi_range(8, 14), 30)
			c.gap = 0.0
			c.wait = randf_range(14.0, 26.0)
			UI.haptic(25)
	)


func _process_chests(delta: float) -> void:
	for c in _chests:
		var want: float = 1.0 if c.left > 0 else 0.0
		c.open = move_toward(c.open, want, delta * (2.6 if want > 0.0 else 0.7))
		c.lid.rotation = deg_to_rad(-22.0) * ease(c.open, 0.6)
		if c.left > 0:
			c.gap -= delta
			if c.gap <= 0.0:
				c.gap = randf_range(0.05, 0.12)
				c.left -= 1
				_spawn_bubble(c.emit + Vector2(randf_range(-0.022, 0.022) * _s.x, 0.0))
		else:
			c.wait -= delta
			if c.wait <= 0.0:
				c.wait = randf_range(16.0, 30.0)
				c.left = randi_range(10, 18)
				c.gap = 0.0


func _spawn_bubble(pos: Vector2) -> void:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/svg/bubble.svg")
	sp.position = pos
	sp.scale = Vector2.ONE * (_s.x * randf_range(0.010, 0.024) / 200.0)
	sp.z_index = 5
	add_child(sp)
	_bubbles.append({"node": sp, "age": 0.0, "x0": pos.x, "ph": randf() * TAU,
		"speed": randf_range(0.13, 0.20), "base": sp.scale})


func _sing(p: Dictionary) -> void:
	# Ponovljeni tap prekida i kreće iz početka — dete lupka brzo i očekuje da
	# svaki dodir nešto uradi.
	p.sing = 0.0
	Audio.play("note", -3.0, PITCH[p.idx])
	UI.haptic(18)
	_spawn_note(p)


func _spawn_note(p: Dictionary) -> void:
	var id: int = 1 + randi() % 3
	var sp := Sprite2D.new()
	sp.texture = load("res://art/svg/note-bubble-%d-1.svg" % id)
	sp.position = p.mouth
	sp.scale = Vector2.ONE * (_s.x * 0.068 / 160.0)
	sp.z_index = 6
	# Boja se meša ka beloj: puna boja obojila bi i samu opnu mehurića, a on
	# treba da ostane bledo staklast kao svi ostali u igri.
	sp.modulate = (BAND[p.idx][2] as Color).lerp(Color.WHITE, 0.45)
	add_child(sp)
	_notes.append({"node": sp, "id": id, "age": 0.0, "x0": sp.position.x,
		"y0": sp.position.y, "ph": randf() * TAU})


func _exit_tree() -> void:
	Audio.set_music_enabled(Save.music_on)


func _process(delta: float) -> void:
	_t += delta
	# 24 frejma na 12 sličica u sekundi = dvosekundna petlja, dovoljno spora
	# da talasanje ne odvlači pažnju sa muzičara.
	_staff.texture = _staff_frames[int(_t * 12.0) % _staff_frames.size()]
	_process_chests(delta)

	for i in range(_bubbles.size() - 1, -1, -1):
		var b: Dictionary = _bubbles[i]
		if not is_instance_valid(b.node):
			_bubbles.remove_at(i)
			continue
		b.age += delta
		b.node.position.y -= _s.y * b.speed * delta
		b.node.position.x = b.x0 + sin(b.age * 2.2 + b.ph) * _s.x * 0.006
		b.node.scale = b.base * (1.0 + 0.3 * minf(1.0, b.age / 5.0))
		if b.node.position.y < _s.y * 0.08:
			b.node.modulate.a -= delta * 1.6
			if b.node.modulate.a <= 0.02:
				b.node.queue_free()
				_bubbles.remove_at(i)

	# Notni sistem se blago talasa — 24 frejma na 12 sličica u sekundi daju
	# dvosekundnu petlju, dovoljno sporu da ne odvlači pažnju sa muzičara.
	_staff.texture = _staff_frames[int(_t * 12.0) % _staff_frames.size()]

	for p in _players:
		if p.sing < 0.0:
			continue
		p.sing += delta
		var f := int(p.sing * SING_FPS)
		if f >= SING_FRAMES:
			p.sing = -1.0
			p.node.texture = load("res://art/svg/bubble-fish-%s-sing-1.svg" % p.kind)
			continue
		p.node.texture = load("res://art/svg/bubble-fish-%s-sing-%d.svg" % [p.kind, f + 1])

	for i in range(_notes.size() - 1, -1, -1):
		var n: Dictionary = _notes[i]
		if not is_instance_valid(n.node):
			_notes.remove_at(i)
			continue
		n.age += delta
		var k: float = n.age / 2.2
		n.node.position.y = n.y0 - _s.y * 0.55 * k
		n.node.position.x = n.x0 + sin(n.age * 2.4 + n.ph) * _s.x * 0.02
		n.node.scale = Vector2.ONE * (_s.x * lerpf(0.068, 0.038, k) / 160.0)
		n.node.modulate.a = 1.0 if k < 0.73 else clampf((1.0 - k) / 0.27, 0.0, 1.0)
		n.node.texture = load("res://art/svg/note-bubble-%d-%d.svg"
			% [n.id, 1 + int(n.age * 8.0) % 4])
		if k >= 1.0:
			n.node.queue_free()
			_notes.remove_at(i)
