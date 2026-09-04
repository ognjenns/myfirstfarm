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
## Muzičari su kupljene ribe (art/ocean): prefiks sličica i broj. Nemaju
## crtež pevanja, pa "pevaju" bržim zamahom i poskokom.
## Osam muzičara = cela lestvica do-re-mi-fa-sol-la-si-do (03.09.2026).
const BAND := [
	["f4-orange", 1, Color("#D9645F"), 8],
	["f2-pink",   2, Color("#E0873E"), 12],
	["f3-yellow", 3, Color("#E8C34A"), 12],
	["f6-green",  4, Color("#6FAE64"), 12],
	["f5-blue",   5, Color("#4E9CC4"), 8],
	["horse-yellow", 6, Color("#3F7FB5"), 16],
	["jelly",     7, Color("#9B7BC4"), 10],
	["fc-orange", 8, Color("#D9645F"), 16],
]
## Stub je ruševni stub iz paketa, obojen u boju note; visine po lestvici.
const PERCH_H := [0.16, 0.21, 0.26, 0.31, 0.36, 0.41, 0.46, 0.51]
## Durska lestvica (čista intonacija): do re mi fa sol la si do.
const PITCH := [1.0, 1.125, 1.25, 1.3333, 1.5, 1.6667, 1.875, 2.0]
## Iz specifikacije: x centri stubova i visine njihovih sedišta.
## Ceo red je pomeren za 0,025 udesno u odnosu na specifikaciju, jer je prvi
## stub nalegao na levi sanduk. Razmak od 0,137 između stubova ostaje netaknut
## — on je i vizuelna lestvica, pa se ne sme menjati.
const PERCH_X := [0.135, 0.238, 0.341, 0.444, 0.547, 0.650, 0.753, 0.856]
const SIT_Y := [0.783, 0.709, 0.635, 0.561, 0.487, 0.413, 0.339, 0.265]
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
	_build_background()
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
## Pozadina iz kupljenog paketa: voda, zraci, daleke stene, olupina, pesak.
func _build_background() -> void:
	var bg := Sprite2D.new()
	bg.texture = load("res://art/ocean/bg-colour.png")
	var bt := bg.texture.get_size()
	bg.position = _s / 2.0
	bg.scale = Vector2(_s.x / bt.x, _s.y / bt.y)
	bg.z_index = -60
	add_child(bg)
	var sun := Sprite2D.new()
	sun.texture = load("res://art/ocean/sunlight.png")
	var st := sun.texture.get_size()
	sun.scale = Vector2.ONE * ((_s.x * 0.8) / st.x)
	sun.position = Vector2(_s.x * 0.5, st.y * sun.scale.y * 0.5 - _s.y * 0.02)
	sun.modulate.a = 0.6
	sun.z_index = -59
	add_child(sun)
	_pack("distant-rocks-1", 0.40, 0.14, 0.84, -57)
	_pack("distant-rocks-4", 0.42, 0.88, 0.84, -57)
	_pack("ship-wreck", 0.22, 0.50, 0.86, -56).modulate = Color(0.85, 0.92, 1.0, 0.8)
	var sand := Sprite2D.new()
	sand.texture = load("res://art/ocean/seabed.png")
	var sd := sand.texture.get_size()
	sand.scale = Vector2((_s.x * 1.02) / sd.x, (_s.y * 0.20) / sd.y)
	sand.position = Vector2(_s.x * 0.5, _s.y * 0.92)
	sand.z_index = -50
	add_child(sand)
	for g in [["grass-7", 0.045, 0.02, 1.08], ["grass-9", 0.045, 0.985, 1.08],
			["fg-piece-3", 0.30, 0.30, 1.05], ["fg-piece-5", 0.30, 0.72, 1.05]]:
		_pack(String(g[0]), float(g[1]), float(g[2]), float(g[3]), -8).modulate = Color(0.85, 0.9, 0.92)


func _pack(art: String, frac_w: float, cx: float, base_y: float, z: int) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/ocean/%s.png" % art)
	var tex := sp.texture.get_size()
	sp.scale = Vector2.ONE * ((_s.x * frac_w) / tex.x)
	sp.offset = Vector2(0, -tex.y / 2.0)
	sp.position = Vector2(_s.x * cx, _s.y * base_y)
	sp.z_index = z
	add_child(sp)
	return sp


func _fish_tex(i: int, frame: int) -> Texture2D:
	return load("res://art/ocean/%s-%d.png" % [BAND[i][0], 1 + (frame - 1) % int(BAND[i][3])])


func _above_ground(d: float) -> float:
	return _s.y * 0.917 - d * REF.y * (_s.x / REF.x)


func _build_band() -> void:
	for i in BAND.size():
		var kind: String = BAND[i][0]
		var perch: int = BAND[i][1]
		var cx: float = _s.x * PERCH_X[i]

		# Stub iz paketa: oslonac na dnu, visina po lestvici, boja note.
		var pv := Sprite2D.new()
		pv.texture = load("res://art/ocean/pillar-white.png")
		var ptex := pv.texture.get_size()
		var ph: float = REF.y * (_s.x / REF.x) * PERCH_H[perch - 1]
		# Širina prati visinu (kapitel ne sme da se spljošti), ali ne ispod 0,05w.
		pv.scale = Vector2(maxf(_s.x * 0.05, ph * 0.42) / ptex.x, ph / ptex.y)
		pv.offset = Vector2(0, -ptex.y / 2.0)
		pv.position = Vector2(cx, _s.y * 0.917)
		pv.modulate = (BAND[i][2] as Color).lerp(Color.WHITE, 0.12)
		pv.z_index = 2
		add_child(pv)

		# Muzičar sedi na vrhu stuba; crteži gledaju ulevo, pa se ogledaju da
		# gledaju ka sredini (levi ka desno, desni ka levo).
		var size := _s.x * 0.082
		var sp := Sprite2D.new()
		sp.texture = _fish_tex(i, 1)
		var ft := sp.texture.get_size()
		var fsc: float = size / maxf(ft.x, ft.y)
		sp.scale = Vector2(-fsc if i < 4 else fsc, fsc)
		sp.position = Vector2(cx, _s.y * 0.917 - ph - size * 0.30)
		sp.z_index = 3
		add_child(sp)

		var entry := {"node": sp, "kind": kind, "idx": i, "sing": -1.0, "base": sp.scale, "f": randf() * 8.0,
			"mouth": Vector2(cx + (size * 0.3 if i < 4 else -size * 0.3), sp.position.y - size * 0.15)}
		_players.append(entry)

		# Tap zona je NAMERNO mnogo veća od bića — dečji prst ne cilja precizno.
		var area := Area2D.new()
		var shape := CollisionShape2D.new()
		var rect := RectangleShape2D.new()
		rect.size = Vector2(_s.x * 0.10, _s.y * 0.20)
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
	var sc := (_s.x * 0.098) / 512.0
	var node := Node2D.new()
	node.position = Vector2(_s.x * x, _above_ground(0.917 - 0.97))
	node.scale = Vector2.ONE * sc
	node.z_index = 2
	add_child(node)

	var lid := Sprite2D.new()
	lid.texture = load("res://art/ocean/chest-closed.png")
	lid.offset = Vector2(0, -lid.texture.get_size().y / 2.0)
	node.add_child(lid)

	var c := {"node": node, "lid": lid, "open": 0.0, "left": 0, "gap": 0.0, "is_open": false,
		"wait": first_wait, "emit": Vector2(_s.x * x, _above_ground(0.917 - 0.875))}
	_chests.append(c)

	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(500.0, 430.0)
	shape.shape = rect
	shape.position = Vector2(0.0, -215.0)
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
		var open_now: bool = c.open > 0.35
		if open_now != c.is_open:
			c.is_open = open_now
			c.lid.texture = load("res://art/ocean/chest-%s.png" % ("open" if open_now else "closed"))
			c.lid.offset = Vector2(0, -c.lid.texture.get_size().y / 2.0)
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
	sp.texture = load("res://art/ocean/bubble.png")
	sp.position = pos
	sp.scale = Vector2.ONE * (_s.x * randf_range(0.010, 0.024) / 256.0)
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
		# Stalno lagano diše sličicama; dok "peva" (0,6 s) zamah je brz i
		# poskoči sa malim naduvavanjem — kupljene ribe nemaju usta koja pevaju.
		var singing: bool = p.sing >= 0.0
		p.f += delta * (22.0 if singing else 7.0)
		p.node.texture = _fish_tex(p.idx, 1 + int(p.f))
		if singing:
			p.sing += delta
			var k: float = p.sing / 0.6
			if k >= 1.0:
				p.sing = -1.0
				p.node.scale = p.base
			else:
				p.node.scale = p.base * (1.0 + 0.18 * sin(k * PI))

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
