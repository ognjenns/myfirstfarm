extends BaseScreen
## Mini-igra: VODI RIBICU (okean). Dete drži prst na ribici i vodi je kroz
## prolaz u grebenu do mame. Ako digne prst — ribica STANE i čeka; to je
## namerno, jer igra koja se sama odvija prestane da drži pažnju.
##
## Nema greške ni gubitka: ako ribica dodirne koral, samo se ne pomera u tom
## smeru, kao da je zid tu. Sve dosadašnje igre traže tap; ova je jedina sa
## produženim prevlačenjem, pa vežba drugu motoriku.

const KINDS := ["clown", "tang", "puffer", "turtle", "octopus", "seahorse"]
const SWIM_FRAMES := 8
const FISH_W := 0.052          # širina ribice kao frakcija ekrana
const BOARDS := 5

## Table: [art, x_frakcija, sa_tavanice, VISINA kao frakcija visine ekrana]
## Visina se zadaje direktno jer ona određuje koliko je prolaz uzak — širina
## ispada iz proporcija crteža. Ranije je bila zadata širina, pa su zidovi
## jedva virili iz peska i table su bile prazne.
## Prolaz se sužava od table do table, ali nikad ispod ~2,5 širine ribice —
## uska rupa za ovaj uzrast nije izazov nego frustracija.
const LAYOUTS := [
	# KLJUČNO PRAVILO: zid sa dna i zid sa tavanice moraju ZAJEDNO da pređu punu
	# visinu ekrana (zbir > 1.0). Ako ne pređu, ostaje vodoravna traka i dete
	# provuče ribicu pravo, bez ijednog skretanja — igra tada nema smisla.
	# Razmak mora biti veći od širine zida (~0,15 pri ovim visinama), inače se
	# zidovi dodiruju.
	# 1 — blago vijuganje, uči se pravilo (zbir 1,05)
	[["reef-wall-tall", 0.30, false, 0.55], ["reef-wall-tall-top", 0.52, true, 0.50],
	 ["reef-wall-tall", 0.74, false, 0.55]],
	# 2 — jače (zbir 1,12)
	[["reef-wall-tall", 0.26, false, 0.58], ["reef-wall-tall-top", 0.46, true, 0.54],
	 ["reef-wall-tall", 0.66, false, 0.58], ["reef-wall-tall-top", 0.86, true, 0.52]],
	# 3 — cik-cak (zbir 1,16)
	[["reef-wall-tall-top", 0.24, true, 0.56], ["reef-wall-tall", 0.44, false, 0.60],
	 ["reef-wall-tall-top", 0.64, true, 0.56], ["reef-wall-tall", 0.84, false, 0.58]],
	# 4 — dublje skretanje (zbir 1,20)
	[["reef-wall-tall", 0.24, false, 0.62], ["reef-wall-tall-top", 0.44, true, 0.58],
	 ["reef-wall-tall", 0.64, false, 0.62], ["reef-wall-tall-top", 0.84, true, 0.56]],
	# 5 — najzahtevnija (zbir 1,24)
	[["reef-wall-tall-top", 0.22, true, 0.60], ["reef-wall-tall", 0.41, false, 0.64],
	 ["reef-wall-tall-top", 0.60, true, 0.60], ["reef-wall-tall", 0.79, false, 0.64]],
]

var _s := Vector2.ZERO
var _t := 0.0
var _board := 0
var _kind := "clown"
var _fish: Sprite2D
var _mama: Sprite2D
var _walls: Array = []          # {rect: Rect2, node}
var _decor: Array = []
var _dragging := false
var _target := Vector2.ZERO   # gde je prst; ribica ga stiže svojom brzinom
var _moved := 0.0               # koliko se ribica pomerila ovog kadra
var _trail: Array = []
var _trail_in := 0.0
var _busy := false
var _hint: Node2D
var _idle := 0.0          # koliko dugo dete nije pomerilo ribicu
var _start := Vector2.ZERO
var _goal := Vector2.ZERO


func _ready() -> void:
	home_target = "ocean"
	_s = UI.vs(self)
	Scenery.background(self, "background-reef")
	add_home_button()
	_build_board()
	set_process(true)
	set_process_input(true)


# -------------------------------------------------------------------- tabla

func _build_board() -> void:
	for w in _walls:
		if is_instance_valid(w.node):
			w.node.queue_free()
	for d in _decor:
		if is_instance_valid(d):
			d.queue_free()
	_walls.clear()
	_decor.clear()

	_kind = KINDS[_board % KINDS.size()]
	for spec in LAYOUTS[_board]:
		_add_wall(spec[0], spec[1], spec[2], spec[3])
	_scatter_decor()

	_start = Vector2(_s.x * 0.09, _s.y * 0.50)
	_goal = Vector2(_s.x * 0.945, _s.y * 0.50)

	if _mama == null:
		_mama = Sprite2D.new()
		add_child(_mama)
	_mama.texture = load("res://art/svg/bubble-fish-%s.svg" % _kind)
	_mama.scale = Vector2.ONE * ((_s.x * FISH_W * 1.9) / 256.0)
	_mama.position = _goal
	_mama.z_index = 4

	if _fish == null:
		_fish = Sprite2D.new()
		add_child(_fish)
	_fish.texture = load("res://art/svg/bubble-fish-%s-1.svg" % _kind)
	_fish.scale = Vector2.ONE * ((_s.x * FISH_W) / 256.0)
	_fish.position = _start
	_fish.z_index = 6
	_fish.modulate.a = 1.0
	_busy = false
	_dragging = false
	_idle = 0.0
	if _hint == null:
		# Prsten koji diše oko ribice — bez teksta i bez strelica, jer igra
		# nema ni jedno ni drugo. Nestane čim dete prvi put povuče.
		_hint = Node2D.new()
		_hint.z_index = 5
		UI.circle(_hint, Vector2.ZERO, _s.x * FISH_W * 0.95, Color(1, 1, 1, 0.30))
		add_child(_hint)
	_hint.position = _start
	_hint.visible = true
	_show_path_hint()


func _add_wall(art: String, x: float, from_top: bool, hf: float) -> void:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/svg/%s.svg" % art)
	var tex := sp.texture.get_size()
	var sc := (_s.y * hf) / tex.y
	sp.scale = Vector2.ONE * sc
	if randf() < 0.5:
		sp.scale.x *= -1.0                      # ogledanje: isti crtež ne pada u oko
	var h := tex.y * sc
	if from_top:
		sp.offset = Vector2(0, tex.y / 2.0)     # oslonac na VRHU
		sp.position = Vector2(_s.x * x, -_s.y * 0.02)
	else:
		sp.offset = Vector2(0, -tex.y / 2.0)    # oslonac na DNU
		sp.position = Vector2(_s.x * x, _s.y * 1.02)
	sp.z_index = 3
	add_child(sp)

	# Pojednostavljena kolizija: uspravni pravougaonik oko stabla korala.
	var half := tex.x * sc * 0.34
	var top: float = sp.position.y if from_top else sp.position.y - h
	_walls.append({"node": sp,
		"rect": Rect2(sp.position.x - half, top, half * 2.0, h)})


## Sitni korali i trava IZMEĐU zidova — čist ukras, ne prepreka, da tabla ne
## izgleda kao pet istih zidova.
func _scatter_decor() -> void:
	var arts := ["coral-branch-small", "coral-fan", "seaweed-clump-small", "starfish"]
	for i in 5:
		var sp := Sprite2D.new()
		sp.texture = load("res://art/svg/%s.svg" % arts[randi() % arts.size()])
		var w: float = randf_range(0.035, 0.06)
		var tex := sp.texture.get_size()
		sp.scale = Vector2.ONE * ((_s.x * w) / tex.x)
		sp.offset = Vector2(0, -tex.y / 2.0)
		sp.position = Vector2(_s.x * randf_range(0.14, 0.90), _s.y * randf_range(0.99, 1.02))
		sp.z_index = 1
		add_child(sp)
		_decor.append(sp)


## Na početku table putanja se NAKRATKO iscrta tačkicama, od ribice do mame.
## Za ovaj uzrast pokazivanje radi ono što uputstvo ne može — dete vidi šta se
## očekuje i krene samo. Tačkice se gase pa nestaju, ne ostaju na ekranu.
func _show_path_hint() -> void:
	var pts := _path_points()
	if pts.size() < 2:
		return
	var seg: Array[float] = []
	var total := 0.0
	for i in range(pts.size() - 1):
		var d: float = pts[i].distance_to(pts[i + 1])
		seg.append(d)
		total += d
	if total <= 1.0:
		return

	var dots := clampi(int(total / (_s.x * 0.030)), 8, 30)
	for i in dots:
		var want := total * float(i) / float(dots - 1)
		var acc := 0.0
		var p: Vector2 = pts[0]
		for k in range(seg.size()):
			if acc + seg[k] >= want:
				p = pts[k].lerp(pts[k + 1], (want - acc) / maxf(1.0, seg[k]))
				break
			acc += seg[k]
		var delay := 0.35 + float(i) * 0.045
		get_tree().create_timer(delay).timeout.connect(_pop_dot.bind(p))


func _pop_dot(p: Vector2) -> void:
	if not is_inside_tree() or _busy:
		return
	var sp := Sprite2D.new()
	sp.texture = load("res://art/svg/bubble-trail-small-1.svg")
	sp.position = p
	sp.scale = Vector2.ONE * (_s.x * 0.020 / 96.0)
	sp.modulate.a = 0.0
	sp.z_index = 4
	add_child(sp)
	var tw := sp.create_tween()
	tw.tween_property(sp, "modulate:a", 0.85, 0.16)
	tw.tween_interval(1.1)
	tw.tween_property(sp, "modulate:a", 0.0, 0.45)
	tw.tween_callback(sp.queue_free)


## Bezbedna putanja izvedena iz STVARNIH pravougaonika prepreka: iznad svakog
## zida sa dna, ispod svakog sa tavanice. Zato je uvek prohodna, i kad se
## raspored tabli menja.
func _path_points() -> Array:
	var r := _s.x * FISH_W * 0.42
	var ws := _walls.duplicate()
	ws.sort_custom(func(a, b): return a.rect.position.x < b.rect.position.x)
	var pts: Array = [_start]
	for w in ws:
		var rect: Rect2 = w.rect
		var cx: float = rect.position.x + rect.size.x * 0.5
		var y: float
		if rect.position.y < _s.y * 0.05:          # visi sa tavanice — prolazi se ISPOD
			y = rect.end.y + r + _s.y * 0.07
		else:                                       # raste sa dna — prolazi se IZNAD
			y = rect.position.y - r - _s.y * 0.07
		pts.append(Vector2(cx, clampf(y, _s.y * 0.10, _s.y * 0.90)))
	pts.append(_goal)
	return pts


# -------------------------------------------------------------------- unos

func _input(event: InputEvent) -> void:
	if _busy:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			# velikodušna zona hvatanja — dečji prst ne pogađa piksel
			if event.position.distance_to(_fish.position) < _s.x * FISH_W * 1.3:
				_dragging = true
				_target = event.position
		else:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		_target = event.position


## Ribica se pomera u _process, ograničenom brzinom po KADRU — ne po ulaznom
## događaju. Ranije je pomeraj zavisio od toga koliko događaja stigne, pa je
## brz prevlačaj davao ogroman skok u jednom potezu i ribica je preskakala
## koral. Ovako je pomeraj po kadru uvek mali i sudar se ne može promašiti.
func _step_fish(delta: float) -> void:
	var r := _s.x * FISH_W * 0.42
	var to := _target - _fish.position
	var dist := to.length()
	if dist < 1.0:
		return
	var travel: float = minf(dist, _s.x * 1.5 * delta)
	var dir := to / dist
	var sub: int = maxi(1, int(ceil(travel / maxf(1.0, r * 0.35))))
	var stepv := dir * (travel / float(sub))
	var pos := _depenetrate(_fish.position, r)
	for i in sub:
		var nxt := pos + stepv
		if not _hits_wall(nxt, r):
			pos = nxt
			continue
		# klizanje uz zid: probaj samo po jednoj pa samo po drugoj osi
		var sx := Vector2(nxt.x, pos.y)
		var sy := Vector2(pos.x, nxt.y)
		if not _hits_wall(sx, r):
			pos = sx
		elif not _hits_wall(sy, r):
			pos = sy
		else:
			break
	pos.x = clampf(pos.x, _s.x * 0.03, _s.x * 0.97)
	pos.y = clampf(pos.y, _s.y * 0.06, _s.y * 0.96)
	pos = _depenetrate(pos, r)          # klampovanje je moglo da je ugura u zid
	var moved := _fish.position.distance_to(pos)
	if moved > 0.5:
		var d := pos - _fish.position
		if absf(d.x) > 0.5:
			_fish.scale.y = absf(_fish.scale.y) * (-1.0 if d.x < 0.0 else 1.0)
	_fish.position = pos
	_moved = moved


## Ako je ribica ikako završila UNUTAR korala — a to se desi zbog klampovanja
## uz ivicu ekrana ili zbog zaokruživanja pri klizanju uz zid — svaki sledeći
## pomeraj i dalje javlja sudar i ribica ostane zauvek zarobljena. Zato se na
## početku svakog kadra gura napolje po najkraćem putu.
func _depenetrate(p: Vector2, r: float) -> Vector2:
	for attempt in 3:
		var pushed := false
		for w in _walls:
			var rect: Rect2 = w.rect
			var nearest := Vector2(clampf(p.x, rect.position.x, rect.end.x),
				clampf(p.y, rect.position.y, rect.end.y))
			var d := p - nearest
			var dist := d.length()
			if dist >= r:
				continue
			if dist > 0.001:
				p = nearest + (d / dist) * (r + 1.0)
			else:
				# centar je duboko unutra — izbaci ga kroz najbližu stranicu
				var l := p.x - rect.position.x
				var rr := rect.end.x - p.x
				var u := p.y - rect.position.y
				var dn := rect.end.y - p.y
				var m: float = minf(minf(l, rr), minf(u, dn))
				if is_equal_approx(m, l):
					p.x = rect.position.x - r - 1.0
				elif is_equal_approx(m, rr):
					p.x = rect.end.x + r + 1.0
				elif is_equal_approx(m, u):
					p.y = rect.position.y - r - 1.0
				else:
					p.y = rect.end.y + r + 1.0
			pushed = true
		if not pushed:
			break
	return p


func _hits_wall(p: Vector2, r: float) -> bool:
	for w in _walls:
		var rect: Rect2 = w.rect
		var nearest := Vector2(clampf(p.x, rect.position.x, rect.end.x),
			clampf(p.y, rect.position.y, rect.end.y))
		if p.distance_to(nearest) < r:
			return true
	return false


# ------------------------------------------------------------------- proces

func _process(delta: float) -> void:
	_t += delta
	if _fish == null:
		return

	# Animacija plivanja ide SAMO dok se ribica kreće — kad dete digne prst,
	# ribica se zaustavi i to se vidi.
	if not _busy:
		_fish.position = _depenetrate(_fish.position, _s.x * FISH_W * 0.42)
	if _dragging and not _busy:
		_step_fish(delta)

	# Dok dete ne krene, ribica se blago klati a prsten pulsira — to je jedini
	# način da joj se kaže "pomeri me" bez teksta i bez glasa.
	if not _dragging and not _busy:
		_idle += delta
		if _idle > 1.2:
			var k: float = fmod(_idle - 1.2, 1.6) / 1.6
			_hint.position = _fish.position
			_hint.scale = Vector2.ONE * (1.0 + 0.45 * k)
			_hint.modulate.a = 1.0 - k
			_fish.position.x += sin(_t * 5.0) * _s.x * 0.0012
	else:
		_idle = 0.0
		_hint.visible = false

	if _moved > 0.5:
		var fr := 1 + int(_t * 13.0) % SWIM_FRAMES
		_fish.texture = load("res://art/svg/bubble-fish-%s-%d.svg" % [_kind, fr])
		_trail_in -= delta
		if _trail_in <= 0.0:
			_trail_in = randf_range(0.06, 0.11)
			_spawn_trail(_fish.position)
	_moved = 0.0

	_mama.position.y = _goal.y + sin(_t * 1.4) * _s.y * 0.012

	for i in range(_trail.size() - 1, -1, -1):
		var tr: Dictionary = _trail[i]
		if not is_instance_valid(tr.node):
			_trail.remove_at(i)
			continue
		tr.age += delta
		var k: float = tr.age / tr.life
		tr.node.position.y -= _s.y * 0.05 * delta
		tr.node.modulate.a = clampf(1.0 if k < 0.4 else (1.0 - k) / 0.6, 0.0, 1.0)
		if k >= 1.0:
			tr.node.queue_free()
			_trail.remove_at(i)

	if not _busy and _fish.position.distance_to(_goal) < _s.x * 0.075:
		_win()


func _spawn_trail(pos: Vector2) -> void:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/svg/bubble-trail-mid-1.svg")
	sp.position = pos - Vector2(_s.x * 0.02 * signf(_fish.scale.y), 0)
	sp.scale = Vector2.ONE * (_s.x * randf_range(0.012, 0.024) / 96.0)
	sp.z_index = 5
	add_child(sp)
	_trail.append({"node": sp, "age": 0.0, "life": randf_range(0.6, 1.0)})


func _win() -> void:
	_busy = true
	_dragging = false
	Audio.play(["yay", "giggle", "kid"][randi() % 3], -2.0)
	UI.haptic(35)
	_celebrate_bubbles()
	var tw := _fish.create_tween()
	tw.tween_property(_fish, "position", _goal + Vector2(_s.x * 0.035, _s.y * 0.02), 0.6)
	tw.parallel().tween_property(_fish, "modulate:a", 0.0, 0.6).set_delay(0.5)
	get_tree().create_timer(1.9).timeout.connect(func() -> void:
		_board = (_board + 1) % BOARDS
		_build_board())


func _celebrate_bubbles() -> void:
	var center := _goal
	for i in 22:
		var ang := randf() * TAU
		var start: Vector2 = center + Vector2(cos(ang), sin(ang)) * _s.x * randf_range(0.01, 0.12)
		var sp := Sprite2D.new()
		sp.texture = load("res://art/svg/bubble.svg")
		sp.position = start
		sp.z_index = 9
		var s0: float = _s.x * randf_range(0.008, 0.022) / 200.0
		sp.scale = Vector2.ONE * s0
		add_child(sp)
		var dir: Vector2 = Vector2.from_angle(ang)
		var dur: float = randf_range(0.7, 1.2)
		var tw := sp.create_tween()
		tw.set_parallel(true)
		tw.tween_property(sp, "scale", Vector2.ONE * s0 * randf_range(6.0, 11.0), dur).set_ease(Tween.EASE_IN)
		tw.tween_property(sp, "position", start + dir * _s.x * randf_range(0.25, 0.6), dur).set_ease(Tween.EASE_IN)
		tw.tween_property(sp, "modulate:a", 0.0, dur * 0.4).set_delay(dur * 0.6)
		tw.finished.connect(sp.queue_free)
