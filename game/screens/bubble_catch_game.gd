extends BaseScreen
## Mini-igra: MEHURIĆI (okean). Mehurići se dižu sa dna; u nekima je zarobljena
## ribica. Tap na PRAZAN mehurić ga samo zatrese — ne puca. Tap na onaj sa
## ribicom ga rasprsne, ribica otpliva u koralnu kućicu desno. Kad ih se skupi
## dovoljno, runda je gotova i sledeća je malo brža.
##
## Zašto prazan mehurić reaguje iako ne puca: da dete ne pomisli da je aplikacija
## zaglavila. Tap MORA nešto da uradi, samo ne ono što dete želi — tako uči
## razliku, bez kazne.

## Kupljene ribe (art/ocean): prefiks sličica i koliko ih ima. Sve gledaju
## ULEVO, pa se pri plivanju ka kućici okreću suprotno od starih SVG riba.
const KINDS := {
	"blue": {"p": "f4-blue", "n": 8}, "green": {"p": "f4-green", "n": 8},
	"orange": {"p": "f4-orange", "n": 8}, "purple": {"p": "f4-purple", "n": 8},
	"yellow": {"p": "f4-yellow", "n": 8}, "round": {"p": "f6-blue", "n": 12},
	"pink": {"p": "f2-pink", "n": 12}, "striped": {"p": "f3-yellow", "n": 12},
	"gold": {"p": "fc-orange", "n": 16}, "jelly": {"p": "jelly", "n": 10},
	"horse": {"p": "horse-green", "n": 16},
}
const FISH := ["blue", "green", "orange", "purple", "yellow", "round", "pink",
	"striped", "gold", "jelly", "horse"]
const NEED := 5          # koliko ribica čini rundu
const POP_FRAMES := 12

var _s := Vector2.ZERO
var _t := 0.0
var _round := 1
var _caught := 0
var _spawn_in := 0.6
var _last_x := 0.4
## Broj praznih mehurića zaredom. Startuje visoko da PRVI mehurić runde
## sigurno ima ribicu — niz praznih na početku deluje kao da igra ne radi.
var _empty_run := 99
var _bubbles: Array = []     # {node, area, fish, speed, x0, ph, r}
var _swimmers: Array = []    # ribice na putu ka kućici
var _ambient: Array = []     # sitni ukrasni mehurići u pozadini
var _trail: Array = []       # tragovi mehurića iza ribica koje plivaju kući
var _home_open := Vector2.ZERO
var _home_scale := 1.0
var _parked: Array = []


func _ready() -> void:
	home_target = "ocean"
	_s = UI.vs(self)
	_build_background()
	_build_scenery()
	_build_home()
	add_home_button()
	add_hint(6.0)
	set_process(true)


## Statican ukras. Ekran je bio skoro prazna voda: mehurici se radjaju samo u
## koloni x 0,18–0,72, levo je izuzeto zbog dugmeta za kucu a desno zbog koralne
## kucice, pa je citava leva ivica stajala prazna.
## SVE je namerno NEPOMICNO i ukorenjeno u dno. Sve sto lebdi u sredini vode
## dvogodisnjak pokusa da tapne, a kad se nista ne desi to je frustracija —
## igra je gradjena na pravilu da svaki dodir nesto uradi.
## Pozadina iz kupljenog paketa: boja vode, sunčevi zraci, daleke stene sa
## strana i pesak. Bez ruševina — mehurići moraju da ostanu čitljivi.
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
	sun.modulate.a = 0.7
	sun.z_index = -59
	add_child(sun)
	_deco("distant-rocks-1", 0.40, 0.14, 0.80, -57)
	_deco("distant-rocks-4", 0.42, 0.88, 0.80, -57)
	_deco("distant-rocks-3", 0.12, 0.52, 0.79, -57)
	var sand := Sprite2D.new()
	sand.texture = load("res://art/ocean/seabed.png")
	var sd := sand.texture.get_size()
	sand.scale = Vector2((_s.x * 1.02) / sd.x, (_s.y * 0.26) / sd.y)
	sand.position = Vector2(_s.x * 0.5, _s.y * 0.87)
	sand.z_index = -50
	add_child(sand)


func _deco(art: String, frac_w: float, cx: float, base_y: float, z: int) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/ocean/%s.png" % art)
	var tex := sp.texture.get_size()
	sp.scale = Vector2.ONE * ((_s.x * frac_w) / tex.x)
	sp.offset = Vector2(0, -tex.y / 2.0)
	sp.position = Vector2(_s.x * cx, _s.y * base_y)
	sp.z_index = z
	add_child(sp)
	return sp


func _build_scenery() -> void:
	# Potonuli brod iz kupljenog paketa, na pesku iza svega; malo tamniji od
	# daleke izmaglice paketa da se vidi kao deo prizora, ne kao pozadina.
	var w := _deco("ship-wreck", 0.58, 0.50, 0.92, -20)
	w.modulate = Color(0.78, 0.86, 0.95)

	# Trave i korali iz paketa uz levu ivicu i po dnu; desno samo malo, tamo
	# je kaciga.
	_deco("grass-7", 0.055, 0.035, 1.08, -18)
	_deco("grass-2", 0.110, 0.095, 1.02, -17)
	_deco("grass-11", 0.080, 0.030, 1.00, -16)
	_deco("coral-3", 0.070, 0.150, 1.06, -16)
	_deco("coral-17", 0.075, 0.075, 1.07, -15)
	_deco("grass-13", 0.090, 0.42, 1.03, -17)
	_deco("coral-8", 0.085, 0.60, 1.07, -16)
	_deco("grass-2", 0.085, 0.72, 1.04, -17)
	_deco("coral-18", 0.075, 0.96, 1.06, -16)
	_deco("grass-11", 0.070, 0.99, 1.02, -17)


func _build_home() -> void:
	# Stari ronilacki slem na dnu, desno. Zamenio je koralnu kucicu: okno mu je
	# OTVORENO i ispunjeno bojom dubine, pa ribice uplivavaju kroz njega i tu se
	# parkiraju da dete vidi koliko ih je skupilo.
	# Crtez je 420x400; okno je na (213, 205), a pescana mrlja mu je dno na
	# 0,985h — zato se sidri po dnu i uvecava dok okno ne primi tri ribice u redu.
	_home_scale = (_s.x * 0.24) / 420.0
	var sp := Sprite2D.new()
	sp.texture = load("res://art/svg/diver-helmet.svg")
	sp.scale = Vector2.ONE * _home_scale
	sp.offset = Vector2(0, -400.0 / 2.0)
	sp.position = Vector2(_s.x * 0.865, _s.y * 0.975)
	sp.z_index = 5
	add_child(sp)
	_home_open = sp.position + Vector2(
		(213.0 / 420.0 - 0.5) * 420.0 * _home_scale,
		(205.0 / 400.0 - 1.0) * 400.0 * _home_scale)


# ------------------------------------------------------------------ mehurići

func _spawn_bubble() -> void:
	# Posle dva prazna zaredom sledeći OBAVEZNO nosi ribicu; inače je moguć
	# niz od četiri prazna i dete odustane pre prve nagrade.
	var has_fish: bool = _empty_run >= 2 or randf() < 0.42
	_empty_run = 0 if has_fish else _empty_run + 1
	var r: float = _s.x * (randf_range(0.042, 0.058) if not has_fish else randf_range(0.055, 0.070))

	var node := Node2D.new()
	# Novi mehurić se ne sme roditi tik uz prethodni — inače se skupe u grozd
	# i dete ne razaznaje koji je koji.
	# Dugme "kuća" stoji na (110,110) sa tap zonom ~86 px. Mehurić koji preleti
	# preko njega propuštao je dodir na dugme ispod, pa je dete umesto pucanja
	# izlazilo iz igre. Zato se mehurići uopšte NE rađaju u toj koloni.
	var x := 0.0
	for attempt in 8:
		x = randf_range(0.18, 0.72)
		if absf(x - _last_x) > 0.16:
			break
	_last_x = x
	node.position = Vector2(_s.x * x, _s.y * 1.10)
	node.z_index = 3
	add_child(node)

	var fish := ""
	if has_fish:
		fish = FISH[randi() % FISH.size()]
		var f := Sprite2D.new()
		f.texture = _fish_tex(fish, 1)
		f.scale = Vector2.ONE * (r * 1.45 / _fish_dim(fish))
		node.add_child(f)

	var b := Sprite2D.new()
	b.texture = load("res://art/ocean/bubble.png")
	b.scale = Vector2.ONE * (r * 2.0 / 256.0)
	b.z_index = 1                            # opna se vidi PREKO ribice
	node.add_child(b)

	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = r * 1.25                 # velikodušna meta za dečji prst
	shape.shape = circle
	area.add_child(shape)
	node.add_child(area)

	var entry := {"node": node, "fish": fish, "r": r, "x0": node.position.x,
		"speed": _rise_speed(), "ph": randf() * TAU, "popped": false}
	_bubbles.append(entry)
	area.input_event.connect(func(_vp: Node, ev: InputEvent, _i: int) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()   # da dodir ne procuri ispod
			_on_bubble_tapped(entry)
	)


## Mehurići se dižu i sami pucaju na vrhu, pa dete može da gleda ceo minut a
## da ne shvati da se TAPKAJU. Prst tapne onaj koji je najbliži vrhu.
func _fish_tex(kind: String, frame: int) -> Texture2D:
	var k: Dictionary = KINDS[kind]
	return load("res://art/ocean/%s-%d.png" % [k.p, 1 + (frame - 1) % int(k.n)])


## Veća strana crteža — ribe su široke, meduza i konjić visoki, pa se svi
## uklapaju u istu kružnicu po većoj dimenziji.
func _fish_dim(kind: String) -> float:
	var tex := _fish_tex(kind, 1).get_size()
	return maxf(tex.x, tex.y)


func hint_spot() -> Dictionary:
	var best: Dictionary = {}
	for b in _bubbles:
		if b.popped or not is_instance_valid(b.node):
			continue
		if best.is_empty() or b.node.position.y < best.node.position.y:
			best = b
	if best.is_empty():
		return {}
	return {"at": best.node.position}


func _rise_speed() -> float:
	# Ubrzanje staje posle treće runde; dalje raste samo gustina mehurića, jer
	# više meta čini igru bogatijom, a veća brzina samo teže pogodljivom.
	return 0.100 * (1.0 + 0.10 * float(mini(_round, 3) - 1))


func _on_bubble_tapped(b: Dictionary) -> void:
	if b.popped or not is_instance_valid(b.node):
		return
	if b.fish == "":
		_wobble(b)
		return
	b.popped = true
	Audio.play("bubble_pop", -1.0)
	UI.haptic(25)
	_play_pop(b.node.position, b.r)
	_release_fish(b.fish, b.node.position)
	b.node.queue_free()
	_bubbles.erase(b)


## Prazan mehurić: zatrese se i malo skrene, ali ostaje ceo.
func _wobble(b: Dictionary) -> void:
	Audio.play("tap", -6.0)
	b.x0 += _s.x * (0.02 if randf() < 0.5 else -0.02)
	var n: Node2D = b.node
	var tw := n.create_tween()
	tw.tween_property(n, "scale", Vector2(1.14, 0.88), 0.09)
	tw.tween_property(n, "scale", Vector2(0.93, 1.09), 0.09)
	tw.tween_property(n, "scale", Vector2.ONE, 0.12)


## Pucanje mehurića — kupljena animacija (gamedeveloperstudio.com, 8 frejmova).
## Kapljice u poslednjim frejmovima izlaze VAN kruga mehurića, pa se crtež
## skalira po prečniku mehurića u PRVOM frejmu (386 od 512 px), a ne po celom
## platnu — inače bi pucanje bilo osetno manje od samog mehurića.
## Dve varijante pucanja se biraju nasumično — isti mehurić koji puca uvek
## isto posle par minuta počne da izgleda mašinski.
const POP_ART := 7
const POP_SETS := ["pop", "popb"]
const POP_BUBBLE_FRAC := 372.0 / 512.0

func _play_pop(pos: Vector2, r: float) -> void:
	var sp := Sprite2D.new()
	sp.position = pos
	sp.scale = Vector2.ONE * ((r * 2.0) / (256.0 * POP_BUBBLE_FRAC))
	sp.z_index = 6
	add_child(sp)
	var set_name: String = POP_SETS[randi() % POP_SETS.size()]
	for i in POP_ART:
		sp.texture = load("res://art/fx/%s-%d.png" % [set_name, i + 1])
		await get_tree().create_timer(0.045).timeout
		if not is_instance_valid(sp):
			return
	sp.queue_free()


# -------------------------------------------------------------- ribice ka kući

func _release_fish(kind: String, from: Vector2) -> void:
	Audio.play("fish_go", -2.0, randf_range(0.95, 1.08))
	var sp := Sprite2D.new()
	sp.texture = _fish_tex(kind, 1)
	sp.position = from
	sp.scale = Vector2.ONE * (_s.x * 0.085 / _fish_dim(kind))
	sp.z_index = 4
	add_child(sp)
	# Blagi luk umesto prave linije — riba ne pliva kao strela.
	var mid := (from + _home_open) * 0.5 + Vector2(0, -_s.y * randf_range(0.06, 0.14))
	_swimmers.append({"node": sp, "kind": kind, "from": from, "mid": mid,
		"t": 0.0, "dur": randf_range(1.1, 1.5), "trail": 0.0})


func _park_fish(kind: String) -> void:
	# Skupljene ribice ostaju vidljive u otvoru — za ovaj uzrast je to jedini
	# "brojač" koji nešto znači.
	var sp := Sprite2D.new()
	sp.texture = _fish_tex(kind, 1)
	# Ribice stoje zbijeno, delimično jedna preko druge — tako izgleda kao
	# društvo koje se sklonilo u kućicu, a ne kao poređane figurice.
	sp.scale = Vector2.ONE * (_s.x * 0.048 / _fish_dim(kind))
	var i := _parked.size()
	sp.position = _home_open + Vector2(
		(-1.0 + 0.5 * float(i % 3)) * _s.x * 0.028,
		(0.0 if i < 3 else 1.0) * _s.y * 0.045 - _s.y * 0.012)
	sp.z_index = 6
	add_child(sp)
	_parked.append(sp)


## Mehurići koje ribica ostavlja za sobom dok pliva ka kućici. Kratko žive i
## gase se — trag mora da nestane pre nego što ribica stigne, inače ostane
## niz mehurića koji visi u vodi.
func _spawn_trail(pos: Vector2) -> void:
	# Pozadina ove igre je svetloplava, a mehurići su bledi — zato su gušći,
	# krupniji i mešaju veličine, inače se na ekranu praktično ne vide.
	var size: String = ["small", "mid", "mid", "large"][randi() % 4]
	var sp := Sprite2D.new()
	sp.texture = load("res://art/svg/bubble-trail-%s-1.svg" % size)
	sp.position = pos
	sp.scale = Vector2.ONE * (_s.x * randf_range(0.016, 0.032) / 96.0)
	sp.z_index = 3
	add_child(sp)
	_trail.append({"node": sp, "age": 0.0, "life": randf_range(0.9, 1.5),
		"vy": randf_range(0.03, 0.07), "x0": pos.x, "ph": randf() * TAU,
		"base": sp.scale, "size": size})


# ------------------------------------------------------------------- ambijent

func _spawn_ambient() -> void:
	var size: String = ["small", "mid", "large"][randi() % 3]
	var sp := Sprite2D.new()
	sp.texture = load("res://art/svg/bubble-trail-%s-1.svg" % size)
	sp.position = Vector2(_s.x * randf_range(0.02, 0.98), _s.y * 1.05)
	sp.scale = Vector2.ONE * (_s.x * randf_range(0.012, 0.03) / 96.0)
	sp.z_index = 1
	add_child(sp)
	_ambient.append({"node": sp, "size": size, "speed": randf_range(0.05, 0.11),
		"x0": sp.position.x, "ph": randf() * TAU})


# --------------------------------------------------------------------- proces

func _process(delta: float) -> void:
	_t += delta

	_spawn_in -= delta
	if _spawn_in <= 0.0:
		# gušće sa svakom rundom — više prilika, ne veća težina
		_spawn_in = maxf(0.70, 1.55 - 0.11 * float(_round - 1)) * randf_range(0.85, 1.15)
		_spawn_bubble()
		if randf() < 0.7:
			_spawn_ambient()

	for i in range(_bubbles.size() - 1, -1, -1):
		var b: Dictionary = _bubbles[i]
		if not is_instance_valid(b.node):
			_bubbles.remove_at(i)
			continue
		b.node.position.y -= _s.y * b.speed * delta
		b.node.position.x = b.x0 + sin(_t * 1.6 + b.ph) * _s.x * 0.012
		if b.node.position.y < -_s.y * 0.12:     # otišao — bez kazne
			b.node.queue_free()
			_bubbles.remove_at(i)

	for i in range(_ambient.size() - 1, -1, -1):
		var a: Dictionary = _ambient[i]
		if not is_instance_valid(a.node):
			_ambient.remove_at(i)
			continue
		a.node.position.y -= _s.y * a.speed * delta
		a.node.position.x = a.x0 + sin(_t * 2.1 + a.ph) * _s.x * 0.008
		var fr := 1 + int(_t * 8.0 + a.ph) % 4
		a.node.texture = load("res://art/svg/bubble-trail-%s-%d.svg" % [a.size, fr])
		if a.node.position.y < -_s.y * 0.06:
			a.node.queue_free()
			_ambient.remove_at(i)

	for i in range(_trail.size() - 1, -1, -1):
		var tr: Dictionary = _trail[i]
		if not is_instance_valid(tr.node):
			_trail.remove_at(i)
			continue
		tr.age += delta
		var k: float = tr.age / tr.life
		tr.node.position.y -= _s.y * tr.vy * delta
		tr.node.position.x = tr.x0 + sin(tr.age * 5.0 + tr.ph) * _s.x * 0.004
		tr.node.scale = tr.base * (1.0 + 0.25 * k)
		tr.node.modulate.a = clampf(1.0 if k < 0.45 else (1.0 - k) / 0.55, 0.0, 1.0)
		tr.node.texture = load("res://art/svg/bubble-trail-%s-%d.svg" % [tr.size, 1 + int(tr.age * 10.0) % 4])
		if k >= 1.0:
			tr.node.queue_free()
			_trail.remove_at(i)

	for i in range(_swimmers.size() - 1, -1, -1):
		var w: Dictionary = _swimmers[i]
		if not is_instance_valid(w.node):
			_swimmers.remove_at(i)
			continue
		w.t = minf(1.0, w.t + delta / w.dur)
		var e: float = smoothstep(0.0, 1.0, w.t)
		# kvadratna Bezijeova kriva kroz srednju tačku = mek luk
		var p: Vector2 = w.from.lerp(w.mid, e).lerp(w.mid.lerp(_home_open, e), e)
		var dir: Vector2 = p - w.node.position
		w.node.position = p
		if dir.length() > 0.5:
			# Crtež gleda ulevo: nos ide u smeru kretanja, pa je rotacija
			# obrnuta, a ogledanje po y kad ide udesno.
			w.node.rotation = lerp_angle(w.node.rotation, dir.angle() + PI, 0.25)
			w.node.scale.y = absf(w.node.scale.y) * (-1.0 if dir.x > 0.0 else 1.0)
		w.node.texture = _fish_tex(w.kind, 1 + int(_t * 14.0))
		# trag ide IZA ribice — suprotno od smera kretanja
		w.trail -= delta
		if w.trail <= 0.0 and w.t < 0.92:
			w.trail = randf_range(0.035, 0.070)
			var back: Vector2 = -dir.normalized() * _s.x * 0.030 if dir.length() > 0.5 else Vector2.ZERO
			_spawn_trail(p + back + Vector2(0, randf_range(-0.008, 0.008) * _s.y))
		if w.t >= 1.0:
			_park_fish(w.kind)
			w.node.queue_free()
			_swimmers.remove_at(i)
			_on_fish_home()


## Ulazak u kućicu je namerno NEM — zvuk nosi trenutak kad ribica krene, a
## dupli zvuk na tako kratkoj putanji zvuči kao kvar.
## Slavlje u okeanu: roj mehurića NALEĆE ka gledaocu — kreću sitni iz sredine,
## naglo rastu i razleću se ka ivicama, pa se gase. Konfete su ostale farmi i
## džungli; pod vodom nemaju šta da traže.
func _celebrate_bubbles() -> void:
	Audio.play(["yay", "giggle", "kid"][randi() % 3], -2.0)
	var center := Vector2(_s.x * 0.5, _s.y * 0.55)
	for i in 34:
		var ang := randf() * TAU
		var start: Vector2 = center + Vector2(cos(ang), sin(ang)) * _s.x * randf_range(0.01, 0.20)
		var sp := Sprite2D.new()
		sp.texture = load("res://art/ocean/bubble.png")
		sp.position = start
		sp.z_index = 9
		var s0: float = _s.x * randf_range(0.008, 0.024) / 256.0
		sp.scale = Vector2.ONE * s0
		add_child(sp)

		var dir: Vector2 = (start - center)
		dir = dir.normalized() if dir.length() > 1.0 else Vector2.from_angle(ang)
		var dur: float = randf_range(0.75, 1.30)
		var wait: float = randf_range(0.0, 0.38)
		var tw := sp.create_tween()
		tw.set_parallel(true)
		# ubrzavaju kako se približavaju — otud osećaj da idu ka tebi
		tw.tween_property(sp, "scale", Vector2.ONE * s0 * randf_range(7.0, 13.0), dur) \
			.set_delay(wait).set_ease(Tween.EASE_IN)
		tw.tween_property(sp, "position", start + dir * _s.x * randf_range(0.30, 0.80), dur) \
			.set_delay(wait).set_ease(Tween.EASE_IN)
		tw.tween_property(sp, "modulate:a", 0.0, dur * 0.42) \
			.set_delay(wait + dur * 0.58)
		tw.finished.connect(sp.queue_free)


func _on_fish_home() -> void:
	_caught += 1
	if _caught < NEED:
		return
	_caught = 0
	_round += 1
	_empty_run = 99          # i nova runda počinje ribicom
	_celebrate_bubbles()
	for p in _parked:
		if is_instance_valid(p):
			var tw: Tween = p.create_tween()
			tw.tween_property(p, "modulate:a", 0.0, 0.5)
			tw.tween_callback(p.queue_free)
	_parked.clear()
