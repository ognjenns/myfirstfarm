extends BaseScreen
## Dino igra 1: LEGU SE JAJA — napredak po objektu.
##
## Tri jaja u gnezdu. Svaki tap širi pukotinu i jaje se zaljulja; posle četiri
## tapa se otvori i izađe beba koja uradi nešto blesavo.
##
## Zašto baš ovako: sve dosadašnje igre su pogodak-ili-promašaj u JEDNOM
## potezu. Ovde isti tap ponovljen na istom mestu gura stanje napred, pa dete
## vidi da se nešto skuplja. To je jedina igra u kojoj ne postoji promašaj —
## svaki dodir nešto uradi.

## Koliko tapova do izleganja. Četiri je iz probe: tri je prebrzo da se primeti
## napredak, pet je duže nego što dvogodišnjak istraje bez rezultata.
const TAPS_TO_HATCH := 4
const EGG_Y := 0.85
## Napredovanje bez teksta, kao u hranjenju: 3 jaja, pa 4, pa 5, pa opet 3.
const ROUNDS := [3, 4, 5]
var _round := 0

## Boje ljuske i beba — svako jaje je druga vrsta.
## Svako jaje je druga vrsta: brontosaurus, ti-reks i dodo. Bebe su kupljeni
## sprajtovi (gamedeveloperstudio.com) — svaka ima svoju animaciju stajanja, pa
## posle izleganja nisu nepokretne slike nego dišu i vrpolje se.
## Jaja su kupljeni crteži (Colored eggs): celo jaje, odlomljeni vrh i donja
## ljuska, u tri uzorka — tufne, zvezdice, pruge. Vrh i dno su izvezeni istom
## merom kao celo jaje, pa smena celo → dva dela ne pomera ništa.
## Pet vrsta; runda uzima prvih 3, 4 ili 5 — redosled se meša da isto jaje ne
## bude uvek na istom mestu.
const SHELLS := [
	{"egg": "e1", "baby": "bi", "frames": 20, "flip": true},
	{"egg": "e2", "baby": "trex", "frames": 10, "flip": false},
	{"egg": "e3", "baby": "dodo", "frames": 10, "flip": false},
	{"egg": "e4", "baby": "si", "frames": 20, "flip": true},
	{"egg": "e5", "baby": "ci", "frames": 20, "flip": true},
]

var _eggs: Array = []          # {node, top, bottom, cracks, taps, hatched, pos, tint}
var _hatched := 0
var _t := 0.0
## Dim iz dva vulkana u pozadini — isti mehanizam kao u hubu: tri pramena po
## krateru, razmaknuta po fazi, dižu se, šire i gase.
var _smoke: Array = []
var _busy := false             # dok traje izleganje ili slavlje, tapovi ne rade


func _ready() -> void:
	home_target = "dino"
	var s := UI.vs(self)
	# Jutarnja verzija kupljene praistorijske scene — ovo je najsvetliji ekran
	# dino sveta, jer je prva igra koju dete može da otvori.
	var bg := Sprite2D.new()
	bg.texture = load("res://art/eggs/bg-eggs.png")
	var bt := bg.texture.get_size()
	bg.position = s / 2.0
	bg.scale = Vector2(s.x / bt.x, s.y / bt.y)
	bg.z_index = -50
	add_child(bg)
	# Oblaci koji plove (kupljeni set) — iz pozadine su obrisani nacrtani, da
	# ne budu isti kao u hubu i da se ne stoje.
	Scenery.cloud(self, Vector2(s.x * 0.22, s.y * 0.11), 1.3, -47)
	Scenery.cloud(self, Vector2(s.x * 0.58, s.y * 0.20), 0.9, -47)
	Scenery.cloud(self, Vector2(s.x * 0.86, s.y * 0.08), 1.1, -47)
	_build_smoke(s, 0.062, 0.336, 0.085)
	_build_smoke(s, 0.542, 0.366, 0.070)
	_build_nest(s)
	_build_round(s)
	add_home_button()
	add_hint(5.0)
	set_process(true)


func _build_smoke(s: Vector2, cx: float, cy: float, frac_w: float) -> void:
	for i in 3:
		var sm := Sprite2D.new()
		sm.texture = load("res://art/eggs/smoke%d.png" % (1 + i % 2))
		var st := sm.texture.get_size()
		sm.scale = Vector2.ONE * ((s.x * frac_w) / st.x)
		sm.offset = Vector2(0, -st.y / 2.0)
		sm.z_index = -46
		add_child(sm)
		_smoke.append({"node": sm, "x": s.x * cx, "y0": s.y * cy, "u": float(i) / 3.0, "w": frac_w})


func _process_smoke(delta: float, s: Vector2) -> void:
	for sm in _smoke:
		sm.u += delta * 0.085
		if sm.u >= 1.0:
			sm.u -= 1.0
		var u: float = sm.u
		var node: Sprite2D = sm.node
		node.position = Vector2(sm.x + sin(u * 3.1) * s.x * 0.012, sm.y0 - u * s.y * 0.26)
		node.scale = Vector2.ONE * (((s.x * float(sm.w)) / node.texture.get_size().x) * (0.6 + u * 0.9))
		node.modulate.a = clampf(u * 4.0, 0.0, 1.0) * (1.0 - u) * 0.85


## Gnezdo je sastavljeno unapred kao dva crteža (Python, po elipsi): pruće leži
## po tangenti ruba i preplitano se preklapa, trava je brežuljak u sredini.
## Zadnji sloj ide IZA jaja, prednji rub ISPRED — jaja sede u činiji. Ranije
## je bilo poređano iz koda, komad po komad, i izgledalo je baš tako.
const NEST_W := 1.04                      # preko cele širine, rub izlazi iz kadra
const NEST_Y := 0.80

func _build_nest(s: Vector2) -> void:
	_nest_layer(s, "nest-back", -5)
	_nest_layer(s, "nest-front", 5)


func _nest_layer(s: Vector2, art: String, z: int) -> void:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/eggs/%s.png" % art)
	sp.scale = Vector2.ONE * ((s.x * NEST_W) / sp.texture.get_size().x)
	sp.position = Vector2(s.x * 0.5, s.y * NEST_Y)
	sp.z_index = z
	add_child(sp)


## Crtež sa DNOM na liniji tla; širina je frakcija ekrana.
func _ground_piece(s: Vector2, art: String, frac_w: float, cx: float, base_y: float, z: int) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/eggs/%s.png" % art)
	var tex := sp.texture.get_size()
	sp.scale = Vector2.ONE * ((s.x * frac_w) / tex.x)
	sp.offset = Vector2(0, -tex.y / 2.0)
	sp.position = Vector2(s.x * cx, s.y * base_y)
	sp.z_index = z
	add_child(sp)
	return sp


## Jedna runda: `count` jaja ravnomerno raspoređenih; sa više jaja svako je
## malo manje da stanu u gnezdo bez preklapanja.
func _build_round(s: Vector2) -> void:
	var count: int = ROUNDS[_round % ROUNDS.size()]
	var order: Array = range(SHELLS.size())
	order.shuffle()
	for i in count:
		var fx: float = lerpf(0.22, 0.78, float(i) / float(count - 1))
		var r: float = s.x * (0.058 if count <= 3 else (0.050 if count == 4 else 0.044))
		_eggs.append(_build_egg(i, s, Vector2(s.x * fx, s.y * EGG_Y), SHELLS[order[i]], r))


func _build_egg(idx: int, s: Vector2, pos: Vector2, tint: Dictionary, r: float) -> Dictionary:

	var node := Node2D.new()
	node.position = pos
	node.z_index = 4
	add_child(node)

	# Sva tri crteža stoje na ISTOM dnu i ISTOJ sredini: celo jaje dok je celo,
	# pa donja ljuska (ostaje) i vrh (odleti) kad pukne.
	var egg_h: float = r * 2.6
	var whole := _egg_part(node, "%s-whole" % tint.egg, egg_h, 0)
	# Donja ljuska je IZNAD bebe (beba dobija z 0), pa beba stoji U ljusci, a ne
	# ispred nje — ljuska joj prekriva noge.
	var bottom := _egg_part(node, "%s-bottom" % tint.egg, egg_h, 1)
	var top := _egg_part(node, "%s-top" % tint.egg, egg_h, 2)
	# Vrh se poravnava po GORNJOJ ivici celog jajeta, ne po dnu.
	var wt: Texture2D = whole.texture
	var tt: Texture2D = top.texture
	top.position = Vector2(0, -(wt.get_size().y - tt.get_size().y) * whole.scale.y)
	bottom.visible = false
	top.visible = false

	# Pukotina: kupljeni crteži (crack overlays), unapred spojeni sa oblikom
	# baš ovog jajeta da ne izlaze van ljuske. Tri faze — mala, srednja,
	# velika — pa četvrti tap otvara jaje.
	var crack := _egg_part(node, "%s-crack1" % tint.egg, egg_h, 1)
	crack.visible = false

	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = r * 1.35            # tap zona šira od jajeta, prsti su mali
	shape.shape = circle
	shape.position = Vector2(0, -egg_h * 0.5)
	area.add_child(shape)
	node.add_child(area)
	var egg_idx := idx
	area.input_event.connect(func(_vp: Node, ev: InputEvent, _i: int) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			_tap_egg(egg_idx)
	)

	return {"node": node, "whole": whole, "top": top, "bottom": bottom, "crack": crack,
		"taps": 0, "hatched": false, "pos": pos, "r": r, "egg_h": egg_h, "tint": tint}


## Deo jajeta: crtež skaliran po visini celog jajeta, sa DNOM na poziciji čvora.
func _egg_part(parent: Node2D, art: String, egg_h: float, z: int) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/eggs/%s.png" % art)
	var tex := sp.texture.get_size()
	var whole_h := 420.0                           # svi delovi su izvezeni na ovoj meri
	var sc: float = egg_h / whole_h
	sp.scale = Vector2.ONE * sc
	sp.offset = Vector2(0, -tex.y / 2.0)           # dno crteža na čvoru
	sp.z_index = z
	parent.add_child(sp)
	return sp


func _tap_egg(idx: int) -> void:
	if _busy:
		return
	var e: Dictionary = _eggs[idx]
	if e.hatched:
		# Već se izleglo — beba samo poskoči, da tap nikad ne bude "ništa".
		UI.bounce(e.node, Vector2.ONE)
		Audio.play("pluck")
		return

	e.taps += 1
	UI.haptic(25)
	# Visina raste sa pukotinom: uho čuje da se nešto približava kraju.
	Audio.play("egg_crack", -7.0, 0.9 + 0.08 * float(e.taps))
	_grow_crack(e)
	_wobble(e.node, e.taps)
	if e.taps >= TAPS_TO_HATCH:
		_hatch(idx)


## Pukotina napreduje po fazama: svaki tap prebacuje na krupniji crtež.
func _grow_crack(e: Dictionary) -> void:
	var crack: Sprite2D = e.crack
	var stage: int = mini(e.taps, 3)
	crack.texture = load("res://art/eggs/%s-crack%d.png" % [e.tint.egg, stage])
	crack.visible = true


## Jaje se ljulja oko dna, sve jače kako se bliži kraj.
func _wobble(node: Node2D, taps: int) -> void:
	var amp: float = deg_to_rad(4.0 + 2.5 * float(taps))
	var tw := create_tween()
	tw.tween_property(node, "rotation", amp, 0.07)
	tw.tween_property(node, "rotation", -amp * 0.8, 0.10)
	tw.tween_property(node, "rotation", amp * 0.4, 0.09)
	tw.tween_property(node, "rotation", 0.0, 0.10)


func _hatch(idx: int) -> void:
	var e: Dictionary = _eggs[idx]
	e.hatched = true
	_hatched += 1
	_busy = true
	# Bez zvonca, glasa i konfeta: izleganje nosi samo zvuk ljuske koja se otvara.
	Audio.play("egg_hatch", -2.0)

	# Celo jaje se zameni sa dva dela; vrh odleti u stranu i padne pored gnezda.
	e.whole.visible = false
	e.crack.visible = false
	e.bottom.visible = true
	e.top.visible = true
	var away: float = 1.0 if idx != 0 else -1.0
	var tw := create_tween()
	tw.set_parallel(true)
	tw.tween_property(e.top, "position", Vector2(away * e.r * 1.9, e.r * 0.3), 0.45).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_property(e.top, "rotation", away * 0.9, 0.45)

	var baby := _build_baby(e)
	tw.chain().tween_callback(func() -> void: _baby_show_off(baby, e))


## Beba: zasad glava malog dinosaurusa iz huba, u tri boje — svako jaje druga
## vrsta. Prava beba (sa telom) ide kroz Design kad se ekran stilizuje.
## Boje se NE množe preko `modulate`: to je prvo probano i beba je ispala skoro
## crna, jer množenje mauve boje sa mauve bojom daje tamnu.
## Beba: niz frejmova stajanja iz kupljenog seta, skaliran po VISINI (crteži su
## različitih proporcija, pa bi skaliranje po širini davalo tri različite
## veličine). Dno crteža pada u ljusku.
func _build_baby(e: Dictionary) -> Node2D:
	var frames: Array = []
	for i in int(e.tint.frames):
		frames.append(load("res://art/dino/%s-%d.png" % [e.tint.baby, i + 1]))
	var f0: Texture2D = frames[0]
	var sp := Sprite2D.new()
	sp.texture = f0
	var sc: float = (e.r * 2.4) / f0.get_size().y
	sp.scale = Vector2(-sc if bool(e.tint.flip) else sc, sc)
	sp.offset = Vector2(0, -f0.get_size().y / 2.0)      # dno crteža u ljusci
	sp.position = Vector2(0, -e.egg_h * 0.12)      # stoji U donjoj ljusci, noge sakrivene
	sp.z_index = 0
	e.node.add_child(sp)
	e["baby_frames"] = frames
	e["baby_node"] = sp
	return sp


## Bebe dišu i vrpolje se posle izleganja — 8 sličica u sekundi je dovoljno
## sporo da izgleda mirno, a dovoljno da se vidi da su žive.
func _process(delta: float) -> void:
	_process_smoke(delta, UI.vs(self))
	_t += delta * 8.0
	for e in _eggs:
		if not e.hatched or not e.has("baby_node"):
			continue
		var sp: Sprite2D = e.baby_node
		if is_instance_valid(sp):
			var fr: Array = e.baby_frames
			sp.texture = fr[int(_t) % fr.size()]


## Blesava tačka: iskoči i sleti nazad u ljusku.
func _baby_show_off(baby: Node2D, e: Dictionary) -> void:
	var tw := create_tween()
	tw.tween_property(baby, "position", Vector2(0, -e.egg_h * 0.12 - e.r * 1.3), 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	# Bez okretanja: kupljene bebe su cele životinje sa nogama, i pun krug im
	# izgleda kao prevrtanje — kod glave iz huba je prolazilo, ovde ne.
	tw.tween_property(baby, "position", Vector2(0, -e.egg_h * 0.12), 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void:
		_busy = false
		if _hatched >= _eggs.size():
			_finish_round()
	)


## Kad se sva tri izlegnu: slavlje pa nova runda. Bez ekrana "kraj" i bez
## čekanja na dugme — igra se sama vraća u početno stanje.
func _finish_round() -> void:
	_busy = true
	var s := UI.vs(self)
	# Slavlje od naših crteža, bez konfeta: dečji glas, pa bebe skaču u
	# talasu, jednom, uz oblačić prašine na sletanju i sjaj oko svake.
	Audio.play(["yay", "giggle", "kid"][randi() % 3], -2.0)
	for k in _eggs.size():
		var e: Dictionary = _eggs[k]
		if not e.has("baby_node"):
			continue
		var baby: Node2D = e.baby_node
		var rest := Vector2(0, -e.egg_h * 0.12)
		var up := rest + Vector2(0, -e.r * 1.6)
		var tw := create_tween()
		tw.tween_interval(0.15 * k)
		tw.tween_callback(func() -> void: _glow(e.pos + Vector2(0, -e.r * 1.2), e.r * 2.8))
		tw.tween_property(baby, "position", up, 0.26).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
		tw.tween_property(baby, "position", rest, 0.22).set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
		tw.tween_callback(func() -> void:
			_puff(e.pos + Vector2(0, e.r * 0.2), e.r * 3.2)
			Audio.play("tap", -8.0)
		)
	get_tree().create_timer(2.6).timeout.connect(_reset_round)


## Oblačić prašine sa lave (jump-land), ovde pri sletanju bebe.
func _puff(pos: Vector2, width: float) -> void:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/lava/jump-land-1.png")
	var tex := sp.texture.get_size()
	sp.scale = Vector2.ONE * (width / tex.x)
	sp.offset = Vector2(0, -tex.y / 2.0)
	sp.position = pos
	sp.z_index = 6
	add_child(sp)
	var tw := create_tween()
	for i in 8:
		var idx := i + 1
		tw.tween_callback(func() -> void: sp.texture = load("res://art/lava/jump-land-%d.png" % idx))
		tw.tween_interval(0.045)
	tw.tween_callback(sp.queue_free)


## Sjaj (charge) kao kod otkrivanja u igri sa kamenjem.
func _glow(pos: Vector2, height: float) -> void:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/fx/charge-1.png")
	sp.scale = Vector2.ONE * (height / sp.texture.get_size().y)
	sp.position = pos
	sp.z_index = 5
	sp.modulate = Color(1.0, 0.62, 0.2)   # narandžast, kao lava i jaja
	add_child(sp)
	var tw := create_tween()
	for i in 10:
		var idx := i + 1
		tw.tween_callback(func() -> void: sp.texture = load("res://art/fx/charge-%d.png" % idx))
		tw.tween_interval(0.05)
	tw.tween_callback(sp.queue_free)


func _reset_round() -> void:
	for e in _eggs:
		e.node.queue_free()
	_eggs.clear()
	_hatched = 0
	_round += 1
	_build_round(UI.vs(self))
	_busy = false


## Pokazivač ide na jaje koje je NAJDALJE stiglo — dete tako vidi da se tapka
## isto mesto više puta, što je cela poenta ove igre.
func hint_spot() -> Dictionary:
	if _busy:
		return {}
	var best: Dictionary = {}
	for e in _eggs:
		if e.hatched:
			continue
		if best.is_empty() or e.taps > best.taps:
			best = e
	if best.is_empty():
		return {}
	# Sredina jajeta, ne tačka na kojoj stoji — inače ruka pokazuje u tlo.
	return {"at": best.pos - Vector2(0, best.egg_h * 0.5), "size": 1.6}
