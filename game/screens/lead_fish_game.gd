extends BaseScreen
## Mini-igra: VODI RIBICU (okean). Dete drži prst na ribici i vodi je kroz
## prolaz u grebenu do mame. Ako digne prst — ribica STANE i čeka; to je
## namerno, jer igra koja se sama odvija prestane da drži pažnju.
##
## Nema greške ni gubitka: ako ribica dodirne koral, samo se ne pomera u tom
## smeru, kao da je zid tu. Sve dosadašnje igre traže tap; ova je jedina sa
## produženim prevlačenjem, pa vežba drugu motoriku.

## Kupljene ribe (art/ocean): prefiks sličica i broj; crteži gledaju ULEVO.
const FISH_ART := {
	"orange": {"p": "f4-orange", "n": 8}, "blue": {"p": "f4-blue", "n": 8},
	"pink": {"p": "f2-pink", "n": 12}, "striped": {"p": "f3-yellow", "n": 12},
	"gold": {"p": "fc-orange", "n": 16}, "green": {"p": "f6-green", "n": 12},
}
const KINDS := ["orange", "blue", "pink", "striped", "gold", "green"]
const FISH_W := 0.052          # širina ribice kao frakcija ekrana
## Referentni telefon na kome je igra podesena (19,5:9 → viewport 2340x1080).
const REF := Vector2(2340.0, 1080.0)
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
var _mama_bubble: Sprite2D     # mama je u mehuriću; pukne kad mala stigne
var _walls: Array = []          # {rect: Rect2, node}
var _decor: Array = []
var _dragging := false
var _target := Vector2.ZERO   # gde je prst; ribica ga stiže svojom brzinom
var _moved := 0.0               # koliko se ribica pomerila ovog kadra
var _trail: Array = []
var _trail_in := 0.0
var _busy := false
var _hint: Node2D
var _stage: Node2D        # igrivo polje u odnosu telefona, centrirano u viewportu
var _idle := 0.0          # koliko dugo dete nije pomerilo ribicu
var _start := Vector2.ZERO
var _goal := Vector2.ZERO


func _ready() -> void:
	home_target = "ocean"
	# LETTERBOX. Sa stretch/aspect="expand" viewport menja oblik po uredjaju
	# (telefon 2340x1080, iPad 1920x1334). Da se raspored ne bi svaki put
	# iznova stelovao — i da se crtezi ne bi deformisali — igrivo polje uvek
	# ima odnos referentnog telefona i centrira se u viewportu. Visak visine
	# na iPadu pokriva pozadina, koja i inace popunjava ceo ekran.
	var view := UI.vs(self)
	_s = Vector2(view.x, view.x * REF.y / REF.x)
	if _s.y > view.y:
		_s = Vector2(view.y * REF.x / REF.y, view.y)
	_stage = Node2D.new()
	_stage.position = (view - _s) / 2.0
	add_child(_stage)

	# Pozadina ide U polje, ne preko celog viewporta: njen viewBox je 2340x1080,
	# dakle tacno odnos polja, pa se skalira uniformno i ne izoblicava.
	# Pozadina iz kupljenog paketa: boja vode preko CELOG viewporta, zraci,
	# daleke stene u izmaglici i pesak uz dno polja.
	var bg := Sprite2D.new()
	bg.texture = load("res://art/ocean/bg-colour.png")
	var bt := bg.texture.get_size()
	bg.position = view / 2.0
	bg.scale = Vector2(view.x / bt.x, view.y / bt.y)
	bg.z_index = -60
	add_child(bg)
	var sun := Sprite2D.new()
	sun.texture = load("res://art/ocean/sunlight.png")
	var st := sun.texture.get_size()
	sun.scale = Vector2.ONE * ((_s.x * 0.8) / st.x)
	sun.position = Vector2(_s.x * 0.5, st.y * sun.scale.y * 0.5 - _s.y * 0.02)
	sun.modulate.a = 0.6
	sun.z_index = -59
	_stage.add_child(sun)
	_deco("distant-rocks-1", 0.36, 0.12, 0.90, -57)
	_deco("distant-rocks-4", 0.38, 0.90, 0.90, -57)
	_deco("distant-rocks-2", 0.14, 0.50, 0.88, -56)
	_deco("ship-wreck", 0.20, 0.50, 0.92, -55).modulate = Color(0.8, 0.9, 1.0, 0.75)
	var sand := Sprite2D.new()
	sand.texture = load("res://art/ocean/seabed.png")
	var sd := sand.texture.get_size()
	sand.scale = Vector2((_s.x * 1.02) / sd.x, (_s.y * 0.16) / sd.y)
	sand.position = Vector2(_s.x * 0.5, _s.y * 0.94)
	sand.z_index = -50
	_stage.add_child(sand)

	# Iznad polja tavanica pecine, ispod pesak. Oba crteza imaju viewBox
	# 2340x400, dakle odnos polja, pa se skaliraju uniformno.
	#
	# PAZNJA na dva praga. Crtez se skalira po SIRINI (mora da pokrije ekran),
	# pa mu visina ispadne ~400 jedinica bez obzira koliko je traka siroka. Na
	# telefonu 1080x2316 traka je svega 5 px — bez ovoga bi tavanica ulazila
	# 390 px u igru. Zato:
	#   1. ispod 2% visine polja se ne crta nista (telefoni),
	#   2. inace se prikazuje samo UNUTRASNJI deo crteza, tacno traka plus mali
	#      preklop, a ostatak ode van ekrana. Preklop je ono zbog cega zidovi
	#      izranjaju IZA kamena i peska.
	# z_index 5 je iznad zidova (3) a ispod ribice (6).
	# Tavanica od sivog kamenja je izbačena (Ognjen, 04.09.2026, iPad). Gornju
	# traku (samo tablet) puni PUNA traka plave stene iz paketa (mid-rock-1,
	# ravna osnova uz vrh ekrana), komadi gusto sa preklopom — bez šiljaka
	# koji vise. Dole i dalje pesak sa zvezdama.
	var top_band: float = _stage.position.y
	if top_band > _s.y * 0.02:
		_build_ceiling(view, top_band)
	for gore in [false]:
		var traka: float = _stage.position.y if gore else view.y - _stage.position.y - _s.y
		if traka <= _s.y * 0.02:
			continue
		var vidljivo: float = traka + _s.y * 0.12
		var sp := Sprite2D.new()
		sp.texture = load("res://art/svg/%s.svg" % ("cave-ceiling" if gore else "sand-floor-band"))
		var tex := sp.texture.get_size()
		var sc: float = maxf(view.x / tex.x, vidljivo / tex.y)
		sp.scale = Vector2.ONE * sc
		# Sidro na unutrasnjoj ivici crteza; spoljni deo ide van ekrana.
		sp.offset = Vector2(0, (-tex.y / 2.0) if gore else (tex.y / 2.0))
		sp.position = Vector2(view.x / 2.0, vidljivo if gore else view.y - vidljivo)
		sp.z_index = 5
		add_child(sp)
		if not gore:
			_scatter_bank(view, view.y - vidljivo)

	add_home_button()
	_build_board()
	add_hint(5.0)
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
		_stage.add_child(_mama)
	_mama.texture = _fish_tex(1)
	_mama.scale = Vector2.ONE * ((_s.x * FISH_W * 1.9) / _fish_dim())
	_mama.position = _goal
	_mama.z_index = 4
	if _mama_bubble == null:
		_mama_bubble = Sprite2D.new()
		_mama_bubble.texture = load("res://art/ocean/bubble.png")
		_mama_bubble.z_index = 5
		_stage.add_child(_mama_bubble)
	_mama_bubble.scale = Vector2.ONE * ((_s.x * FISH_W * 1.9 * 1.45) / 256.0)
	_mama_bubble.position = _goal
	_mama_bubble.visible = true

	if _fish == null:
		_fish = Sprite2D.new()
		_stage.add_child(_fish)
	_fish.texture = _fish_tex(1)
	var fsc: float = (_s.x * FISH_W) / _fish_dim()
	_fish.scale = Vector2(-fsc, fsc)            # kreće udesno, crtež gleda ulevo
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
		_stage.add_child(_hint)
	_hint.position = _start
	_hint.visible = true
	_show_path_hint()


## Tavanica na tabletu: greben iz paketa (stena sa koralima) OBRNUT, pa
## korali vise sa tavanice; stena je prebojena u PLAVO (art/ocean/
## reef-wall-blue-*, samo ljubičasti pikseli, korali netaknuti), iza puna
## podloga u istoj plavoj, po njoj pukotine iz paketa pukotina. Telefon nema
## traku, pa ovo ne dobija.
func _build_ceiling(view: Vector2, band: float) -> void:
	# bez pune podloge: između vrhova grebena se vidi voda (Ognjen, 04.09.2026)
	var cracks := [[0.10, 0.30, 0.55, 0.2], [0.36, 0.26, 0.6, -0.1], [0.63, 0.32, 0.5, 0.35], [0.88, 0.28, 0.55, -0.3]]
	for i in cracks.size():
		var c: Array = cracks[i]
		var cr := Sprite2D.new()
		cr.texture = load("res://art/ocean/crack-%d.png" % (1 + i % 3))
		var ct := cr.texture.get_size()
		cr.scale = Vector2.ONE * ((band * float(c[2])) / ct.y)
		cr.rotation = float(c[3])
		cr.position = Vector2(view.x * float(c[0]), band * float(c[1]))
		cr.modulate = Color(0.05, 0.22, 0.34, 0.8)
		cr.z_index = 4
		add_child(cr)
	var tex0: Texture2D = load("res://art/ocean/reef-wall-blue-1.png")
	var tex1: Texture2D = load("res://art/ocean/reef-wall-blue-2.png")
	var tt := tex0.get_size()
	var rsc: float = (band * 1.15) / tt.y
	var step: float = tt.x * rsc * 0.62
	var n := int(ceil(view.x / step)) + 1
	for i in n:
		var rock := Sprite2D.new()
		rock.texture = tex0 if i % 2 == 0 else tex1
		rock.scale = Vector2(rsc, -rsc)                # obrnuto: korali nadole
		rock.offset = Vector2(0, -tt.y / 2.0)          # osnova crteža na vrhu ekrana
		rock.position = Vector2(step * float(i), -band * 0.02)
		rock.z_index = 5
		add_child(rock)
	for i in 5:
		var k := Sprite2D.new()
		k.texture = load("res://art/ocean/coral-%d.png" % (1 + (i * 3) % 12))
		var kt := k.texture.get_size()
		var ksc: float = (band * randf_range(0.30, 0.45)) / kt.y
		k.scale = Vector2(ksc * (-1.0 if i % 2 == 1 else 1.0), -ksc)
		k.offset = Vector2(0, -kt.y / 2.0)
		k.position = Vector2(view.x * (0.12 + 0.19 * float(i)), band * 0.80)
		k.z_index = 5
		add_child(k)


func _deco(art: String, frac_w: float, cx: float, base_y: float, z: int) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/ocean/%s.png" % art)
	var tex := sp.texture.get_size()
	sp.scale = Vector2.ONE * ((_s.x * frac_w) / tex.x)
	sp.offset = Vector2(0, -tex.y / 2.0)
	sp.position = Vector2(_s.x * cx, _s.y * base_y)
	sp.z_index = z
	_stage.add_child(sp)
	return sp


func _fish_tex(frame: int) -> Texture2D:
	var k: Dictionary = FISH_ART[_kind]
	return load("res://art/ocean/%s-%d.png" % [k.p, 1 + (frame - 1) % int(k.n)])


func _fish_dim() -> float:
	var tex := _fish_tex(1).get_size()
	return maxf(tex.x, tex.y)


## Zid je kamena stena iz paketa (dva šiljka sa konturom), sa dna ili obešena
## sa tavanice (obrnuta) — ista stena gore i dole, pa se čita kao pećina.
## Donja stena u podnožju dobija koralni greben u prirodnoj razmeri (ukras).
func _add_wall(_art: String, x: float, from_top: bool, hf: float) -> void:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/ocean/wall-rock-%d.png" % (1 + randi() % 2))
	var tex := sp.texture.get_size()
	# +0.09: toliko osnove ide van ekrana, pa vidljiva visina ostaje hf.
	var sc := (_s.y * (hf + 0.09)) / tex.y
	var scx := sc * 1.7                         # šiljak je u crtežu uzak, ovako je zid pun
	sp.scale = Vector2(scx if randf() < 0.5 else -scx, sc)
	var h := tex.y * sc
	sp.offset = Vector2(0, -tex.y / 2.0)        # oslonac na dnu crteža
	if from_top:
		sp.scale.y = -sc                        # obrnut: oslonac ide na vrh
		# Ravna osnova crteža ide van ekrana, da se ne vidi "odsečen" vrh.
		sp.position = Vector2(_s.x * x, -_s.y * 0.09)
	else:
		sp.position = Vector2(_s.x * x, _s.y * 1.09)
		var reef := Sprite2D.new()
		reef.texture = load("res://art/ocean/reef-wall-%d.png" % (1 + randi() % 2))
		var rt := reef.texture.get_size()
		var rsc: float = (_s.x * 0.15) / rt.x
		reef.scale = Vector2.ONE * rsc
		reef.offset = Vector2(0, -rt.y / 2.0)
		reef.position = Vector2(_s.x * x, _s.y * 1.03)
		reef.z_index = 4
		_stage.add_child(reef)
		_decor.append(reef)
	sp.z_index = 3
	_stage.add_child(sp)

	# Pojednostavljena kolizija: uspravni pravougaonik oko zida.
	# Kolizija samo po stablu šiljka: sam crtež je u kadru uzak, a zid je
	# raširen 1,7×, pa je pri 0,19 pravougaonik gutao ceo prolaz između
	# susednih zidova (0,20 širine ekrana) i riba nije mogla da prođe.
	var half := tex.x * scx * 0.10
	var top: float = sp.position.y if from_top else sp.position.y - h
	_walls.append({"node": sp,
		"rect": Rect2(sp.position.x - half, top, half * 2.0, h)})


## Sitni korali i trava IZMEĐU zidova — čist ukras, ne prepreka, da tabla ne
## izgleda kao pet istih zidova.
func _scatter_decor() -> void:
	var arts := ["coral-3", "coral-8", "coral-17", "coral-18", "grass-2", "grass-11", "grass-13"]
	for i in 7:
		var sp := Sprite2D.new()
		sp.texture = load("res://art/ocean/%s.png" % arts[randi() % arts.size()])
		var w: float = randf_range(0.035, 0.06)
		var tex := sp.texture.get_size()
		sp.scale = Vector2.ONE * ((_s.x * w) / tex.x)
		sp.offset = Vector2(0, -tex.y / 2.0)
		sp.position = Vector2(_s.x * randf_range(0.14, 0.90), _s.y * randf_range(0.99, 1.02))
		sp.z_index = 1
		_stage.add_child(sp)
		_decor.append(sp)


## Poneka skoljka i zvezda po donjoj traci peska. Kamenje vise ne crtamo rucno
## — tavanica i pesak su sada crtezi. Iznad polja se ne stavlja nista: sa
## tavanice pecine ne vise skoljke.
func _scatter_bank(view: Vector2, ivica: float) -> void:
	var arts := ["star-red-1", "star-yellow-1", "coral-16", "coral-17"]
	for i in 4:
		var sp := Sprite2D.new()
		sp.texture = load("res://art/ocean/%s.png" % arts[randi() % arts.size()])
		var tex := sp.texture.get_size()
		var sc: float = (_s.x * randf_range(0.030, 0.052)) / tex.x
		sp.scale = Vector2(sc * (1.0 if randf() < 0.5 else -1.0), sc)
		sp.offset = Vector2(0, -tex.y / 2.0)
		sp.position = Vector2(view.x * ((i + randf_range(0.2, 0.8)) / 4.0),
			ivica + (view.y - ivica) * randf_range(0.35, 0.8))
		sp.z_index = 6
		add_child(sp)


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
	sp.texture = load("res://art/ocean/bubble.png")
	sp.position = p
	sp.scale = Vector2.ONE * (_s.x * 0.020 / 256.0)
	sp.modulate.a = 0.0
	sp.z_index = 4
	_stage.add_child(sp)
	var tw := sp.create_tween()
	tw.tween_property(sp, "modulate:a", 0.85, 0.16)
	tw.tween_interval(1.1)
	tw.tween_property(sp, "modulate:a", 0.0, 0.45)
	tw.tween_callback(sp.queue_free)


## Bezbedna putanja izvedena iz STVARNIH pravougaonika prepreka: iznad svakog
## zida sa dna, ispod svakog sa tavanice. Zato je uvek prohodna, i kad se
## raspored tabli menja.
## Pokazivač (prst): prevuci ribicu ka prvoj tački putanje. Tačkice ostaju
## kao mapa, prst pokazuje GEST — dete odmah vidi da se ribica vuče.
func hint_spot() -> Dictionary:
	if _busy or _dragging or not is_instance_valid(_fish):
		return {}
	var pts := _path_points()
	var to: Vector2 = pts[1] if pts.size() > 1 else _goal
	return {"from": _fish.position + _stage.position, "to": to + _stage.position, "size": 1.3}


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
			if (event.position - _stage.position).distance_to(_fish.position) < _s.x * FISH_W * 1.3:
				_dragging = true
				_target = event.position - _stage.position
		else:
			_dragging = false
	elif event is InputEventMouseMotion and _dragging:
		_target = event.position - _stage.position


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
			_fish.scale.x = absf(_fish.scale.x) * (-1.0 if d.x > 0.0 else 1.0)
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
		_fish.texture = _fish_tex(1 + int(_t * 13.0))
		_trail_in -= delta
		if _trail_in <= 0.0:
			_trail_in = randf_range(0.06, 0.11)
			_spawn_trail(_fish.position)
	_moved = 0.0

	_mama.position.y = _goal.y + sin(_t * 1.4) * _s.y * 0.012
	_mama_bubble.position = _mama.position

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
	sp.texture = load("res://art/ocean/bubble.png")
	sp.position = pos - Vector2(_s.x * 0.02 * signf(_fish.scale.y), 0)
	sp.scale = Vector2.ONE * (_s.x * randf_range(0.012, 0.024) / 256.0)
	sp.z_index = 5
	_stage.add_child(sp)
	_trail.append({"node": sp, "age": 0.0, "life": randf_range(0.6, 1.0)})


func _win() -> void:
	_busy = true
	_dragging = false
	# Mehurić oko mame pukne čim mala stigne, pa tek onda slavlje.
	Audio.play("bubble_pop", -1.0)
	_mama_bubble.visible = false
	_play_pop(_mama.position, _s.x * FISH_W * 1.9 * 0.72)
	Audio.play(["yay", "giggle", "kid"][randi() % 3], -2.0)
	UI.haptic(35)
	_celebrate_bubbles()
	var tw := _fish.create_tween()
	tw.tween_property(_fish, "position", _goal + Vector2(_s.x * 0.035, _s.y * 0.02), 0.6)
	tw.parallel().tween_property(_fish, "modulate:a", 0.0, 0.6).set_delay(0.5)
	get_tree().create_timer(1.9).timeout.connect(func() -> void:
		_board = (_board + 1) % BOARDS
		_build_board())


## Pucanje mehurića: isti crteži kao u igri sa mehurićima (art/fx pop).
func _play_pop(pos: Vector2, r: float) -> void:
	var sp := Sprite2D.new()
	sp.position = pos
	sp.scale = Vector2.ONE * ((r * 2.0) / (256.0 * 372.0 / 512.0))
	sp.z_index = 8
	_stage.add_child(sp)
	var set_name: String = ["pop", "popb"][randi() % 2]
	for i in 7:
		sp.texture = load("res://art/fx/%s-%d.png" % [set_name, i + 1])
		await get_tree().create_timer(0.045).timeout
		if not is_instance_valid(sp):
			return
	sp.queue_free()


func _celebrate_bubbles() -> void:
	var center := _goal
	for i in 22:
		var ang := randf() * TAU
		var start: Vector2 = center + Vector2(cos(ang), sin(ang)) * _s.x * randf_range(0.01, 0.12)
		var sp := Sprite2D.new()
		sp.texture = load("res://art/ocean/bubble.png")
		sp.position = start
		sp.z_index = 9
		var s0: float = _s.x * randf_range(0.008, 0.022) / 256.0
		sp.scale = Vector2.ONE * s0
		_stage.add_child(sp)
		var dir: Vector2 = Vector2.from_angle(ang)
		var dur: float = randf_range(0.7, 1.2)
		var tw := sp.create_tween()
		tw.set_parallel(true)
		tw.tween_property(sp, "scale", Vector2.ONE * s0 * randf_range(6.0, 11.0), dur).set_ease(Tween.EASE_IN)
		tw.tween_property(sp, "position", start + dir * _s.x * randf_range(0.25, 0.6), dur).set_ease(Tween.EASE_IN)
		tw.tween_property(sp, "modulate:a", 0.0, dur * 0.4).set_delay(dur * 0.6)
		tw.finished.connect(sp.queue_free)
