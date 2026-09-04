extends BaseScreen
## Dino hub — vulkanski sumrak, četvrti svet.
##
## Sve mere su frakcije širine/visine ekrana, tačno iz dizajnerske tabele
## (mock 2340×1080, `docs/DINO.md`). Vrednosti se NE zaokružuju "na oko" —
## biljke i stene stoje na SREDNJOJ TERASI, a prednja traka peska
## (y 0.830–1.000) je namerno prazna: tuda će brontosaurus da prošeta.
##
## Redosled po dubini: nebo (pozadina) → lava-kanal → veliki vulkan → mali
## vulkan → pterodaktil → drvo → biljke i kamenje. Pterodaktil leti ISPRED
## vulkana jer je blizu, a planina je daleko; iza krošnje, jer je krošnja
## u prednjem planu.

## Iskopavanje i kula se otključavaju kupovinom; jaja i staza su besplatni.
const LOCKED_GAMES := ["dig", "tower"]
## Igre koje su stvarno napisane; ostale kapije stoje ali još ne vode nigde.
const IMPLEMENTED: Array[String] = ["eggs", "lava", "dig", "tower"]

var _s := Vector2.ZERO
var _t := 0.0

## Biljke se ljuljaju oko oslonca na dnu (pivot bottom-centre).
var _sway: Array = []              # {node, amp, period, phase}

## Žar iz kratera: pet čestica koje se dižu i gase, pa kreću ispočetka.
## Nijedna ne sme da uđe u pojas neba y 0.26–0.40 kojim leti pterodaktil.
var _embers: Array = []            # {node, x0, u, speed, jitter, base_scale}
var _crater := Vector2.ZERO

## Oba vulkana su ŽIVA: dim izlazi u kolutovima, 36 frejmova u petlji (frejm 36
## se poklapa sa 1). Platno puff-frejmova je prošireno NAVIŠE da dim ima gde da
## se digne, pa se sprajt podiže za polovinu te razlike — inače bi kupa sela
## niže nego u pozadini.
##   veliki: viewBox 0 -360 1100 1140, kupa 1100×760 → pomak -170
##   mali:   viewBox 0 -240  800  680, kupa  800×420 → pomak -110
## Svaki vulkan ima DVA sprajta jedan preko drugog: donji nosi tekući frejm i
## potpuno je neproziran, gornji sledeći frejm sa providnošću koja raste od 0
## do 1. Tako se frejmovi PRELIVAJU umesto da se smenjuju, i dim je gladak i
## na 12 sličica u sekundi. Donji sprajt je neproziran i zato kupa ostaje puna
## boja — preliva se samo ono što se razlikuje, a to je dim.
var _puff_big: Array = []          # [donji, gornji]
var _puff_small: Array = []
var _puff_big_frames: Array = []
var _puff_small_frames: Array = []
var _puff_t := 0.0
## Kupljeni vulkani: lavi se menja providnost, dim se diže u pramenovima.
var _smoke: Array = []

## Ptica se crta kao i dim: dva sprajta u čvoru, donji neproziran sa tekućom
## sličicom, gornji sa sledećom i providnošću koja raste — sličice se prelivaju
## umesto da se smenjuju.
var _ptero: Node2D
var _ptero_pair: Array = []        # [donji, gornji]
var _ptero_frames: Array = []      # zamah krila
var _ptero_glide_frames: Array = []
var _ptero_gphase := 0.0
var _ptero_area: Area2D
## Dodir na pticu je isto što i dodir na dinosaurusa: ubrza. Njoj to znači brži
## prelet i pojačan zamah — jedrenje se prekida, ptica "šiba".
var _ptero_dash := 0.0
const PTERO_DASH_TIME := 2.4
const PTERO_DASH_SPEED := 2.6
const PTERO_DASH_FPS := 1.8
var _ptero_u := 1.0                # napredak preleta, 1 = završen
var _ptero_wait := 0.0
var _ptero_y := 0.32
## Zamah pa jedrenje: ptica mahne nekoliko puta, pa "seče" vazduh sa mirnim
## krilima. Stalno mahanje na 11 sličica u sekundi je i seckalo i izgledalo
## kao lepršanje leptira, a ne kao let velike ptice.
var _ptero_flap := 0.0             # koliko još traje zamah
## Zamah se NE prekida usred pokreta: kad vreme istekne, ptica maše dok ne
## stigne do sličice sa ravnim krilima, i tek onda pređe u jedrenje. Bez toga
## krila skoče iz zamaha u ravnu pozu i to se vidi kao trzaj.
var _ptero_stopping := false
var _ptero_glide := 0.0            # koliko još traje jedrenje
var _ptero_fphase := 0.0           # sopstveni sat zamaha, da se ne trza pri smeni
## Prava mreža lista je 862×970 (a ne 862×582 kako sam prvo pretpostavio) —
## zbog toga su frejmovi bili presečeni i pomereni, pa je ptica u letu čas
## gubila telo, čas se pojavljivala samo glava. Let ima 12 frejmova, jedrenje
## 20, i oba su na istoj meri, pa se smenjuju bez pomeranja.
## Zamah prelazi u jedrenje na frejmu sa najravnijim krilima.
const PTERO_GLIDE_FRAME := 4

## Mali dino viri iz paprati: sam proviruje, a na dodir se sakrije.
var _peek: Sprite2D
var _peek_idle: Array = []
var _peek_peck: Array = []
var _peek_f := 0.0
var _peek_pecking := 0.0
var _peek_home := Vector2.ZERO
var _peek_hide := 0.0              # koliko još ostaje sakriven

## Jezerce lave: 24 frejma u petlji, prelivena kao dim i krila — ranije je to
## bio moj trik sa drugim, poluprozirnim primerkom istog crteža, sad je prava
## animacija mehurova.
var _lava_pair: Array = []
var _lava_frames: Array = []
var _lava_t := 0.0

## BRONTOSAURUS — jedini stanovnik prednjeg plana, hoda trakom peska koja je
## zato i ostavljena prazna (y 0.830–1.000), ispred svih biljaka i kamenja.
##
## Od 02.09.2026 je kupljeni sprite (gamedeveloperstudio.com, licenca dozvoljava
## komercijalnu upotrebu i izmene, atribucija se ne traži). Listovi su isečeni
## na frejmove ISTIM isečkom za sve tri animacije, pa se hod, stajanje i
## spuštanje vrata smenjuju bez trzaja: hod 16, stajanje 20, vrat 8.
## Crtež gleda ULEVO, pa se sprajt ogleda kad ide udesno.
## Veličina se meri po VISINI, ne po širini: kupljeni crtež je uzan i visok
## (272×348), a moj raniji je bio širok i nizak, pa je isto "0.26 širine" ovde
## davalo životinju preko pola ekrana.
## Trakom ne šeta jedna životinja nego se SMENJUJU — svaki prolazak druga
## vrsta, svaka sa svojom visinom, brzinom i tempom koraka. Veliki idu sporije.
## Svi crteži gledaju ULEVO, pa se sprajt ogleda kad ide udesno.
## Koja pozadina se koristi: "pack" ili "design".
const SCENE := "pack"

const SPECIES := [
	{"id": "trex",   "walk": "tw", "wn": 20, "idle": "ti", "in": 20, "h": 0.42, "speed": 0.052, "fps": 14.0, "ax": 0.448, "run": "td", "rn": 10, "skip": [14, 15, 16]},
	# Brontosaurusov okvir je unija SVA TRI lista (hod, stajanje, spuštanje
	# vrata), jer u stajanju glava izlazi levo van okvira hoda — prvi put mu je
	# zato njuška bila odsečena. Zbog šireg okvira stopala nisu u sredini slike,
	# nego na 0.664 širine; ostale vrste su centrirane.
	{"id": "bronto", "walk": "bw", "wn": 16, "idle": "bi", "in": 20, "h": 0.46, "speed": 0.040, "fps": 12.0, "ax": 0.664},
	{"id": "stego",  "walk": "sw", "wn": 16, "idle": "si", "in": 20, "h": 0.36, "speed": 0.046, "fps": 13.0},
	{"id": "trike",  "walk": "cw", "wn": 12, "idle": "ci", "in": 20, "h": 0.34, "speed": 0.056, "fps": 14.0, "ax": 0.516, "run": "cr", "rn": 12},
]
## Crteži su u dnevnom, hladnom zelenom, a scena je vulkanski sumrak — svi se
## množe istom bojom da stoje pod istim svetlom kao paprat i pesak.
const DINO_TINT := Color(0.94, 0.83, 0.70)
const DINO_GROUND := 0.955                # gde su mu stopala (dno crteža)
const DINO_START := -0.22
const DINO_END := 1.22
const DINO_REST_AT := 0.42
var _dino: Sprite2D
var _dino_w := 0.15                       # koliko zauzima po širini, računa se pri gradnji
var _species := 0
var _speed := 0.05
var _fps := 14.0
## Trčanje: dete tapne životinju i ona potrči. T-Rex i triceratops imaju gotovu
## animaciju trčanja; brontosaurus i stegosaurus je nemaju, pa im se hod ubrza
## u kas — noge i brzina rastu zajedno, tako da ne klize.
var _dino_area: Area2D
var _dino_shadow: Polygon2D
var _dino_h_px := 0.0
var _run_frames: Array = []
var _run_left := 0.0
## Dok trči, iza stopala se dižu oblaci prašine (kupljeni efekat sletanja iz
## seta za skok), jedan svakih četvrt sekunde.
var _run_puff_t := 0.0
const RUN_TIME := 2.6
const RUN_SPEED := 2.4
const RUN_FPS := 1.7
var _walk_frames: Array = []
var _idle_frames: Array = []
var _dino_x := DINO_START
var _dino_f := 0.0
var _dino_wait := 0.0
var _dino_rest := 0.0
var _dino_rested := false
## Stope i prašina: traka je namerno prazna da hod ne prolazi iza žbunja, pa je
## izgledala kao prazna pozornica. Ovo je pune onim što ih je i napravilo.
const PRINT_LIFE := 14.0
const DUST_LIFE := 0.75
var _prints: Array = []
var _dust: Array = []
var _print_half := -1

var _open_gates: Array[TapButton] = []
var _hint_turn := 0


func _ready() -> void:
	var s := UI.vs(self)
	_s = s
	# Pozadina: "pack" je kupljena praistorijska scena obojena u naš sumrak
	# (vulkani, mese i ispucalo tlo su u njoj nacrtani), "design" je ranija
	# Claude Design pozadina uz koju idu naši vulkani sa dimom.
	if SCENE == "pack":
		var bg := Sprite2D.new()
		bg.texture = load("res://art/dino/bg-scene.png")
		var bt := bg.texture.get_size()
		bg.position = s / 2.0
		bg.scale = Vector2(s.x / bt.x, s.y / bt.y)
		bg.z_index = -50
		add_child(bg)
	else:
		Scenery.background(self, "background-dino")

	_build_far(s)
	_build_tree(s)
	_build_plants(s)
	_build_lava_pool(s)
	_build_peek(s)
	_build_ptero(s)
	_build_dino(s)

	_build_gates(s)
	_build_worlds_button()
	_build_parent_button(s)
	add_hint(6.0)
	set_process(true)


# ---------------------------------------------------------------- pomoćnici

## SVG sa OSLONCEM NA DNU (pivot bottom-centre), veličina kao frakcija širine.
func _plant(art: String, frac_w: float, cx: float, base_y: float, z: int) -> Sprite2D:
	var sp := Sprite2D.new()
	# Kupljeni crteži (art/dino/<ime>.png) imaju prednost; ako ih nema, ostaje
	# stari SVG. Isti postupak kao kod hrane — nova biljka je samo nov fajl.
	var bought := "res://art/dino/%s.png" % art
	sp.texture = load(bought) if ResourceLoader.exists(bought) else load("res://art/svg/%s.svg" % art)
	var tex := sp.texture.get_size()
	sp.scale = Vector2.ONE * ((_s.x * frac_w) / tex.x)
	sp.offset = Vector2(0, -tex.y / 2.0)
	sp.position = Vector2(_s.x * cx, _s.y * base_y)
	sp.z_index = z
	add_child(sp)
	return sp


## Slobodan element — centriran na datoj frakciji ekrana.
func _piece(art: String, frac_w: float, fx: float, fy: float, z: int) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/svg/%s.svg" % art)
	sp.scale = Vector2.ONE * ((_s.x * frac_w) / sp.texture.get_size().x)
	sp.position = Vector2(_s.x * fx, _s.y * fy)
	sp.z_index = z
	add_child(sp)
	return sp


func _add_sway(node: Node2D, amp_deg: float, period: float) -> void:
	_sway.append({
		"node": node,
		"amp": deg_to_rad(amp_deg),
		"period": period,
		"phase": randf() * TAU,
	})


## Velika tap zona na elementu (mere su u koordinatama samog sprajta).
func _add_tap(node: Node2D, w: float, h: float, cb: Callable) -> void:
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w, h)
	shape.shape = rect
	area.add_child(shape)
	node.add_child(area)
	area.input_event.connect(func(_vp: Node, ev: InputEvent, _i: int) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			cb.call()
	)


# ----------------------------------------------------------------- elementi

func _build_far(s: Vector2) -> void:
	# Lava-kanal je IZA vulkana: konus mu skriva gornji kraj, a donji se sužava
	# u tačku, pa lava iščezne umesto da bude odsečena.
	if SCENE == "pack":
		# Vulkani i lava su nacrtani u pozadini (kupljena scena), ali JE IZ NJE
		# OBRISAN DIM — svaka kolona iznad kupe je prefarbana nebom, pa se dim
		# sad crta kao živi sprajtovi tačno iznad kratera.
		_build_smoke_column(s, 0.062, 0.336, 0.085)
		_build_smoke_column(s, 0.542, 0.366, 0.070)
		_crater = Vector2(s.x * 0.335, s.y * 0.470)
		for i in 5:
			var e_sp := Sprite2D.new()
			e_sp.texture = load("res://art/svg/ember.svg")
			e_sp.z_index = -43
			add_child(e_sp)
			_embers.append({"node": e_sp, "u": float(i) / 5.0, "speed": randf_range(0.055, 0.085),
				"phase": randf() * TAU, "frac": randf_range(0.007, 0.012)})
		return
	_piece("lava-channel", 0.155, 0.479, 0.527, -46)
	_puff_big = _puff("volcano-big-puff", 36, _puff_big_frames,
		0.275, 1100.0, 170.0, Vector2(s.x * 0.613, s.y * 0.335), -45)
	_puff_small = _puff("volcano-puff", 36, _puff_small_frames,
		0.142, 800.0, 110.0, Vector2(s.x * 0.435, s.y * 0.472), -44)

	_crater = Vector2(s.x * 0.435, s.y * 0.437)
	for i in 5:
		var sp := Sprite2D.new()
		sp.texture = load("res://art/svg/ember.svg")
		sp.z_index = -43
		add_child(sp)
		var e := {
			"node": sp,
			"u": float(i) / 5.0,                       # razmaknute po putanji
			"speed": randf_range(0.055, 0.085),
			"phase": randf() * TAU,
			"frac": randf_range(0.007, 0.012),
		}
		_embers.append(e)


## Vulkan koji dimi: niz frejmova u petlji, usidren tako da kupa ostane tačno
## tamo gde je i bila kad je bila nepokretna slika.
##   frac_w — širina KUPE kao frakcija ekrana (ne celog, proširenog platna)
##   art_w  — širina kupe u originalnom crtežu
##   lift   — koliko je platno pomereno naviše, u pola razlike
func _puff(prefix: String, count: int, frames: Array, frac_w: float,
		art_w: float, lift: float, pos: Vector2, z: int) -> Array:
	for i in count:
		frames.append(load("res://art/svg/%s-%d.svg" % [prefix, i + 1]))
	var sc: float = (_s.x * frac_w) / art_w
	var pair: Array = []
	for k in 2:
		var sp := Sprite2D.new()
		sp.texture = frames[0]
		sp.scale = Vector2.ONE * sc
		sp.position = pos + Vector2(0, -lift * sc)
		sp.z_index = z + k
		if k == 1:
			sp.modulate.a = 0.0            # gornji ulazi tek kad počne preliv
		add_child(sp)
		pair.append(sp)
	return pair


## Kolona dima iznad kratera: tri pramena razmaknuta po fazi. Dok jedan bledi,
## sledeći tek kreće, pa se kolona nikad ne prekine.
func _build_smoke_column(s: Vector2, cx: float, cy: float, frac_w: float) -> void:
	# Gust stub: pet pramenova gusto po fazi, krupni i skoro neprozirni —
	# kao na naslovnoj slici paketa, ne tanki pramičak.
	for i in 5:
		var sm := Sprite2D.new()
		sm.texture = load("res://art/dino/smoke%d.png" % (1 + i % 2))
		var st := sm.texture.get_size()
		sm.scale = Vector2.ONE * ((s.x * frac_w * 1.8) / st.x)
		sm.offset = Vector2(0, -st.y / 2.0)          # dno pramena na krateru
		sm.z_index = -46
		add_child(sm)
		_smoke.append({"node": sm, "x": s.x * cx, "y0": s.y * cy,
			"u": float(i) / 5.0, "w": frac_w * 1.8})


func _build_tree(s: Vector2) -> void:
	# Arukarija: stablo je ukorenjeno na gornjoj ivici trake za šetnju
	# (y 0.830), krošnja izlazi iz kadra gore i desno — namerno.
	# Palme iz praistorijskog paketa (kruna + stablo sklopljeni unapred) —
	# drvo iz "Jungle level trees" je sklonjeno i čuva se za džunglu.
	for pm in [{"a": "palm1", "x": 0.905, "y": 0.86, "h": 0.70, "z": -20, "dim": 0.74},
			{"a": "palm2", "x": 0.960, "y": 0.83, "h": 0.56, "z": -20, "dim": 0.70},
			{"a": "palm2", "x": 0.115, "y": 0.80, "h": 0.52, "z": -22, "dim": 0.66}]:
		var palm := Sprite2D.new()
		palm.texture = load("res://art/dino/%s.png" % pm.a)
		var ptx := palm.texture.get_size()
		var psc: float = (s.y * float(pm.h)) / ptx.y
		palm.scale = Vector2.ONE * psc
		palm.offset = Vector2(0, -ptx.y / 2.0)
		palm.position = Vector2(s.x * float(pm.x), s.y * float(pm.y))
		palm.z_index = int(pm.z)
		var d: float = float(pm.dim)
		palm.modulate = Color(d + 0.02, d - 0.04, d - 0.06)
		add_child(palm)
		_add_sway(palm, 1.2, randf_range(5.5, 7.5))


func _build_plants(s: Vector2) -> void:
	_add_sway(_plant("fern-dino", 0.075, 0.060, 0.765, -6), 3.5, randf_range(3.6, 5.2))
	_add_sway(_plant("cycad", 0.095, 0.102, 0.739, -6), 3.0, randf_range(3.8, 5.4))
	_add_sway(_plant("fern-dino", 0.090, 0.158, 0.770, -5), 3.5, randf_range(3.4, 4.9))
	_plant("p-stone2", 0.062, 0.196, 0.786, -7)

	# Sitnice iz kupljenog paketa po srednjoj terasi: kosti (tiha najava igre
	# iskopavanja), kamenje, busenje i suvo bilje. Sve stoji IZA trake za
	# šetnju, pa ništa ne smeta hodu.
	# Kostur leži u podnožju desne palme (uz veliko drvo se preklapao, sa
	# tankim stablom palme staje) — tiha najava igre iskopavanja.
	for pr in [{"a": "p-bones", "w": 0.140, "x": 0.800, "y": 0.818},
			{"a": "p-rock1", "w": 0.190, "x": 0.470, "y": 0.762},
			{"a": "p-rock2", "w": 0.165, "x": 0.062, "y": 0.792},
			{"a": "p-stone1", "w": 0.038, "x": 0.352, "y": 0.806},
			{"a": "p-stone2", "w": 0.055, "x": 0.660, "y": 0.800},
			{"a": "p-cactus", "w": 0.048, "x": 0.245, "y": 0.786},
			{"a": "p-plant2", "w": 0.024, "x": 0.520, "y": 0.796},
			{"a": "p-plant1", "w": 0.017, "x": 0.905, "y": 0.788},
			{"a": "p-tuft", "w": 0.070, "x": 0.760, "y": 0.812}]:
		_plant(String(pr.a), float(pr.w), float(pr.x), float(pr.y), -7)

	# Niski žbunovi na SREDNJOJ terasi — popunjavaju prazninu između jezerca i
	# paprati, a ne diraju traku za šetnju. Osvetljeni su kao terasa (ne kao
	# prednji plan), pa su svetliji od venca ispred.
	for b in [{"x": 0.132, "w": 0.115, "y": 0.792, "dim": 0.62},
			{"x": 0.402, "w": 0.135, "y": 0.806, "dim": 0.58},
			{"x": 0.712, "w": 0.105, "y": 0.813, "dim": 0.64}]:
		var bush := _plant("bush", float(b.w), float(b.x), float(b.y), -6)
		var d: float = float(b.dim)
		bush.modulate = Color(d + 0.06, d, d - 0.06)
		# Bez njihanja: žbun je nizak i ima ravnu donju ivicu, pa bi se videlo
		# da se ceo crtež ljulja. Njišu se samo paprati i drveće.
	_add_sway(_plant("cycad", 0.085, 0.555, 0.722, -7), 3.0, randf_range(3.7, 5.1))
	_add_sway(_plant("fern-dino", 0.080, 0.652, 0.813, -4), 3.5, randf_range(3.5, 5.0))

	# PREDNJI PLAN: dve tamne paprati ukorenjene ISPOD donje ivice, u kadru samo
	# vrhovima. Dinosaurus im prolazi IZA (z 4 protiv njegovih 2), pa traka
	# peska dobija dubinu a da mu ništa ne smeta u hodu — a to je i bio razlog
	# što je ostala prazna. Zatamnjene su jer su najbliže oku, van svetla lave.
	var near_left := _plant("fern3", 0.30, 0.055, 1.20, 4)
	near_left.modulate = Color(0.30, 0.34, 0.32)
	_add_sway(near_left, 2.0, randf_range(5.0, 6.5))
	var near_right := _plant("cycad", 0.26, 0.955, 1.16, 4)
	near_right.modulate = Color(0.28, 0.32, 0.30)
	_add_sway(near_right, 2.2, randf_range(4.6, 6.0))

	# Dva busena i po SREDINI donje ivice. Ukorenjeni su dublje ispod kadra
	# (1.26 i 1.32) nego oni u ćoškovima, pa vire samo vrhovima — dinosaurusu
	# prekriju noge dok prolazi, a telo i glava ostaju čisti.
	var near_mid := _plant("fern1", 0.26, 0.435, 1.26, 4)
	near_mid.modulate = Color(0.26, 0.30, 0.28)
	_add_sway(near_mid, 2.0, randf_range(5.2, 6.8))
	var near_mid2 := _plant("cycad", 0.20, 0.655, 1.32, 4)
	near_mid2.modulate = Color(0.24, 0.28, 0.27)
	_add_sway(near_mid2, 2.4, randf_range(4.8, 6.2))

	# Gušći venac duž cele donje ivice. Razlog nije samo dubina: noge su
	# najslabiji deo crteža, pa ih rastinje prikriva dok prolazi. Svaki busen
	# ima svoju dubinu ukorenjenja, veličinu, tamninu i ritam — inače se odmah
	# vidi da je isti crtež upotrebljen deset puta.
	# Kupljene paprati (fern creator) — tri različita crteža, pa se ne vidi da je
	# isti oblik ponovljen deset puta. Ostaju tamne: najbliže su oku i van
	# domašaja svetla iz kratera.
	var band := [
		{"art": "fern2", "w": 0.22, "x": 0.210, "y": 1.20, "dim": 0.30},
		{"art": "fern1", "w": 0.18, "x": 0.305, "y": 1.28, "dim": 0.25},
		{"art": "fern3", "w": 0.24, "x": 0.545, "y": 1.22, "dim": 0.27},
		{"art": "fern1", "w": 0.21, "x": 0.760, "y": 1.24, "dim": 0.23},
		{"art": "fern2", "w": 0.19, "x": 0.862, "y": 1.30, "dim": 0.29},
		{"art": "fern3", "w": 0.23, "x": 0.700, "y": 1.19, "dim": 0.26},
		{"art": "fern1", "w": 0.20, "x": 0.815, "y": 1.26, "dim": 0.31},
		{"art": "fern2", "w": 0.25, "x": 0.918, "y": 1.21, "dim": 0.24},
	]
	for b in band:
		var node := _plant(String(b.art), float(b.w), float(b.x), float(b.y), 4)
		var d: float = float(b.dim)
		node.modulate = Color(d, d + 0.04, d + 0.02)
		_add_sway(node, randf_range(1.8, 2.6), randf_range(4.4, 6.6))


func _build_lava_pool(s: Vector2) -> void:
	# Frejmovi 1 i 13 su isporučeni skoro bez žara (563 užarena piksela naspram
	# ~4500 u ostalima) — u petlji su blinkali dvaput po krugu i jezerce je
	# treperilo. Izbačeni su; ostala 22 daju glatke mehure.
	for i in 24:
		if i == 0 or i == 12:
			continue
		_lava_frames.append(load("res://art/svg/lava-pool-%d.svg" % (i + 1)))
	var sc: float = (s.x * 0.160) / _lava_frames[0].get_size().x
	var pos := Vector2(s.x * 0.322, s.y * 0.713)
	for k in 2:
		var sp := Sprite2D.new()
		sp.texture = _lava_frames[0]
		sp.scale = Vector2.ONE * sc
		sp.position = pos
		sp.z_index = -8 + k
		if k == 1:
			sp.modulate.a = 0.0
		add_child(sp)
		_lava_pair.append(sp)
	_plant("p-stone1", 0.042, 0.246, 0.700, -7)


func _build_peek(s: Vector2) -> void:
	# Dodo viri IZA prednje paprati (paprat je na z -4, ptica na -6), pa se vidi
	# tek toliko da dete poželi da je dodirne. Na dodir kljucne pa se sakrije.
	for i in 20:
		_peek_idle.append(load("res://art/dino/dodoi-%d.png" % (i + 1)))
	for i in 10:
		_peek_peck.append(load("res://art/dino/dodop-%d.png" % (i + 1)))
	# Stoji na SREDNJOJ TERASI, na istoj liniji na kojoj je ukorenjena paprat
	# ispred njega (0.821) — ranije je bio na 0.735 i vidno je lebdeo iznad tla.
	_peek_home = Vector2(s.x * 0.597, s.y * 0.826)
	var sh := UI.circle(self, _peek_home + Vector2(0, -s.y * 0.004), s.x * 0.022,
		Color(0.15, 0.10, 0.12, 0.28), -7)
	sh.scale = Vector2(1.0, 0.24)
	_peek = Sprite2D.new()
	var f0: Texture2D = _peek_idle[0]
	_peek.texture = f0
	var sc: float = (s.y * 0.16) / f0.get_size().y
	_peek.scale = Vector2.ONE * sc
	_peek.offset = Vector2(0, -f0.get_size().y / 2.0)   # dno crteža na tlu
	_peek.position = _peek_home
	_peek.modulate = DINO_TINT
	_peek.z_index = -6
	add_child(_peek)
	# Dodo samo stoji i vrpolji se — bez reakcije na dodir. Ranije je kljucao i
	# skrivao se; sklonjeno namerno, jedina interaktivna životinja u hubu je ona
	# koja šeta.
	# Paprat koja ga zaklanja ide POSLE njega, da bude ispred.
	_add_sway(_plant("fern-dino", 0.095, 0.547, 0.821, -4), 3.5, randf_range(3.3, 4.7))


func _build_ptero(s: Vector2) -> void:
	# Kupljeni pterodaktil (20 frejmova leta, 16 jedrenja). Oko mu je u paketu
	# poluzatvoreno kapkom i deluje ljuto, pa je u svakom frejmu prefarbano u
	# okruglo — program nađe belo u kadru, pa preko njega nacrta obrub, punu
	# beonjaču, krupnu zenicu i odsjaj.
	for i in 12:
		_ptero_frames.append(load("res://art/dino/pf-%d.png" % (i + 1)))
	for i in 20:
		_ptero_glide_frames.append(load("res://art/dino/pg-%d.png" % (i + 1)))

	_ptero = Node2D.new()
	# Ispred drveta (-20): otkad leti zdesna nalevo, ulazi tačno iza krošnje i
	# pola puta bi provela sakrivena. Iza kapija ostaje, one su na 10.
	_ptero.z_index = -21   # između palmi: iza desne (-20), ispred leve (-22)
	_ptero.visible = false
	add_child(_ptero)
	var f0: Texture2D = _ptero_frames[0]
	var psc: float = (s.y * 0.20) / f0.get_size().y
	for k in 2:
		var sp := Sprite2D.new()
		sp.texture = f0
		# Crtež gleda ULEVO i tako i leti — suprotno od dinosaurusa koji ide
		# udesno. Dva bića koja se mimoilaze čine kadar življim od dva koja
		# putuju u istom smeru.
		sp.scale = Vector2(psc, psc)
		if k == 1:
			sp.modulate.a = 0.0
		_ptero.add_child(sp)
		_ptero_pair.append(sp)
	# Tap zona prati pticu; mere su u koordinatama crteža pa se skalira sa njom.
	_ptero_area = Area2D.new()
	var pshape := CollisionShape2D.new()
	var prect := RectangleShape2D.new()
	prect.size = Vector2(f0.get_size().x * psc * 0.8, f0.get_size().y * psc * 0.7)
	pshape.shape = prect
	_ptero_area.add_child(pshape)
	_ptero_area.z_index = 3
	add_child(_ptero_area)
	_ptero_area.input_event.connect(func(_vp: Node, ev: InputEvent, _i: int) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			_on_ptero_tapped()
	)
	_ptero_wait = randf_range(2.0, 4.0)


## Dodir na pticu — kao i kod dinosaurusa, svaki dodir iznova pokreće ubrzanje.
func _on_ptero_tapped() -> void:
	if not _ptero.visible:
		return
	UI.haptic(35)
	Audio.play("pop")
	_ptero_dash = PTERO_DASH_TIME
	_ptero_glide = 0.0
	_ptero_stopping = false
	if _ptero_flap <= 0.0:
		_ptero_flap = PTERO_DASH_TIME


func _build_dino(s: Vector2) -> void:
	# Senka pod nogama: bez nje životinja izgleda kao da lebdi iznad tla, ma
	# koliko tačno bila postavljena. Ide ISPOD sprajta i prati ga.
	_dino_shadow = UI.circle(self, Vector2.ZERO, s.x * 0.055, Color(0.15, 0.10, 0.12, 0.30), 1)
	_dino_shadow.scale = Vector2(1.0, 0.22)
	_dino = Sprite2D.new()
	_dino.z_index = 2
	_dino.visible = false
	_dino.modulate = DINO_TINT
	add_child(_dino)

	# Tap zona je čvor za sebe koji prati sprajt: vrste su različitih veličina,
	# pa se pri svakoj smeni menja i njen oblik.
	_dino_area = Area2D.new()
	var shape := CollisionShape2D.new()
	shape.shape = RectangleShape2D.new()
	_dino_area.add_child(shape)
	_dino_area.z_index = 3
	add_child(_dino_area)
	_dino_area.input_event.connect(func(_vp: Node, ev: InputEvent, _i: int) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			_on_dino_tapped()
	)
	# Prvi šetač nikad nije T-Rex (on je na indeksu 0) — biljojed otvara scenu.
	_load_species(1 + randi() % (SPECIES.size() - 1), s)
	_dino_wait = 1.0


## Učitavanje jedne vrste: frejmovi, veličina po VISINI (crteži su različitih
## proporcija), brzina i tempo koraka.
func _load_species(idx: int, s: Vector2) -> void:
	_species = idx
	var sp: Dictionary = SPECIES[idx]
	_walk_frames.clear()
	_idle_frames.clear()
	_run_frames.clear()
	_run_left = 0.0
	var skip: Array = sp.get("skip", [])       # kadrovi hoda sa razjapljenim ustima
	for i in int(sp.wn):
		if (i + 1) in skip:
			continue
		_walk_frames.append(load("res://art/dino/%s-%d.png" % [sp.walk, i + 1]))
	for i in int(sp["in"]):
		_idle_frames.append(load("res://art/dino/%s-%d.png" % [sp.idle, i + 1]))
	if sp.has("run"):
		for i in int(sp.rn):
			_run_frames.append(load("res://art/dino/%s-%d.png" % [sp.run, i + 1]))
	var f0: Texture2D = _walk_frames[0]
	var tex := f0.get_size()
	# Na uskom ekranu (iPad 4:3) dinosaurusi mereni po visini ispadnu ogromni —
	# smanje se srazmerno odnosu strana (isto kao na farmi i u džungli).
	var shrink: float = clampf((s.x / s.y) / 2.14, 0.62, 1.0)
	var sc: float = (s.y * float(sp.h) * shrink) / tex.y
	_dino.texture = f0
	_dino.scale = Vector2(-sc, sc)             # ogledalo: crtež gleda ulevo
	# Na poziciji čvora je DNO crteža i tačka ispod stopala (`ax`).
	var ax: float = float(sp.get("ax", 0.5))
	_dino.offset = Vector2((0.5 - ax) * tex.x, -tex.y / 2.0)
	_dino_w = (tex.x * sc) / s.x
	_speed = float(sp.speed)
	_fps = float(sp.fps)
	_dino_h_px = tex.y * sc
	if is_instance_valid(_dino_area):
		var rect: RectangleShape2D = _dino_area.get_child(0).shape
		rect.size = Vector2(tex.x * sc * 0.72, _dino_h_px * 0.85)


# ---------------------------------------------------------------------- UI

func _build_gates(s: Vector2) -> void:
	var gates := [
		{"screen": "eggs", "icon": "icon-egg"},
		{"screen": "lava", "icon": "icon-stepping-stone"},
		{"screen": "dig", "icon": "sil"},   # silueta iz same igre (kamenje krije senku)
		{"screen": "tower", "icon": "icon-stone-stack"},
	]
	for i in gates.size():
		var g: Dictionary = gates[i]
		var pos := Vector2(s.x * (0.274 + 0.1505 * i), s.y * 0.170)
		var btn := TapButton.new(pos, 105, Pal.BUTTON_WHITE)
		# Okvir: debeo tamni obrub kao na kupljenim crtežima, pa tanak krem
		# prsten između — belo dugme bez ivice je lebdelo nad scenom.
		UI.circle(btn, Vector2.ZERO, 105 + 11, Pal.OUTLINE, -2)
		UI.circle(btn, Vector2.ZERO, 105 + 4, Color("#E9DCC4"), -1)
		# Ikonica: kupljeni crtež (art/dino/<ikonica>.png) ima prednost nad SVG-om.
		var icon_png := "res://art/dino/%s.png" % g.icon
		if g.icon == "sil":
			var ic := Sprite2D.new()
			ic.texture = load("res://art/wall/sil-bronto.png")
			ic.scale = Vector2.ONE * (140.0 / ic.texture.get_size().y)
			ic.position = Vector2(0, 4)
			btn.add_child(ic)
		elif ResourceLoader.exists(icon_png):
			var ic := Sprite2D.new()
			ic.texture = load(icon_png)
			ic.scale = Vector2.ONE * (150.0 / 256.0)
			btn.add_child(ic)
		else:
			Scenery.svg(btn, g.icon, Vector2.ZERO, 0.66, 0)
		var target: String = g.screen
		var locked: bool = target in LOCKED_GAMES and not Save.unlocked
		if not target in IMPLEMENTED:
			# Igra još ne postoji — kapija samo poskoči, da tap ne ruši ekran.
			btn.tapped.connect(func() -> void: UI.bounce(btn, Vector2.ONE))
		elif locked:
			Scenery.svg(btn, "icon-lock", Vector2(58, 58), 0.55, 5)
			btn.tapped.connect(func() -> void: go("gate"))
		else:
			btn.tapped.connect(func() -> void: go(target))
		btn.z_index = 10
		add_child(btn)
		btn.start_pulse()
		if not locked:
			_open_gates.append(btn)


func _build_worlds_button() -> void:
	var btn := TapButton.new(Vector2(100, 100), 62, Color(1, 1, 1, 0.85))
	UI.poly(btn, PackedVector2Array([Vector2(14, -26), Vector2(-22, 0), Vector2(14, 26)]), Color(0.45, 0.40, 0.36))
	btn.tapped.connect(func() -> void: go("worlds"))
	btn.z_index = 10
	add_child(btn)


func _build_parent_button(s: Vector2) -> void:
	var btn := TapButton.new(Vector2(s.x - 80, s.y - 80), 48, Color(0.99, 0.98, 0.96, 0.55))
	for y in [-12, 0, 12]:
		UI.poly(btn, UI.rect_points(34, 6), Color(0.55, 0.5, 0.45), Vector2(0, y))
	btn.tapped.connect(func() -> void: go("gate"))
	btn.z_index = 100   # iznad žbunja i rekvizita uz ivicu
	add_child(btn)


# -------------------------------------------------------------------- pokret

func _on_peek_tapped() -> void:
	# Bez zvuka: hub je namerno tih prizor. Ostaje vibracija, kljucanje i to
	# što se posle sakrije.
	UI.haptic(25)
	_peek_pecking = 1.2
	_peek_hide = randf_range(2.6, 4.0)


func _process(delta: float) -> void:
	_t += delta
	var s := _s

	for w in _sway:
		var a: float = sin(_t * TAU / w.period + w.phase) * w.amp
		w.node.rotation = a
		w.node.skew = a * 0.5                    # mek pregib, ne kruta rotacija

	_process_puffs(delta)
	_process_embers(delta, s)
	_process_ptero(delta, s)
	_process_dino(delta, s)
	_process_prints(delta)
	_process_dust(delta)
	_process_peek(delta, s)
	_process_lava(delta)


## Dim: 12 sličica u sekundi, pun krug za tri sekunde. Oba vulkana dele isti
## sat namerno — dva različita ritma dima na istom horizontu se primete.
func _process_puffs(delta: float) -> void:
	_puff_t += delta * 12.0

	# Kupljeni vulkani: lava "teče" promenom providnosti, dim se diže, širi i gasi.
	for sm in _smoke:
		sm.u += delta * 0.06
		if sm.u >= 1.0:
			sm.u -= 1.0
		var u: float = sm.u
		var node: Sprite2D = sm.node
		node.position = Vector2(sm.x + sin(u * 3.1) * _s.x * 0.012, sm.y0 - u * _s.y * 0.26)
		node.scale = Vector2.ONE * (((_s.x * float(sm.w) * 0.5) / node.texture.get_size().x) * (0.6 + u * 0.9))
		node.modulate.a = clampf(u * 4.0, 0.0, 1.0) * (1.0 - u * u) * 0.95

	if _puff_big.is_empty():
		return
	_set_pair(_puff_big, _puff_big_frames, _puff_t)
	_set_pair(_puff_small, _puff_small_frames, _puff_t)


## Donji sprajt = tekuća sličica, neproziran. Gornji = sledeća, sa providnošću
## jednakom pređenom delu razmaka. Zbir je tačna linearna smena dva crteža —
## isto se koristi za dim iz vulkana i za krila pterodaktila.
func _set_pair(pair: Array, frames: Array, phase: float) -> void:
	var n: int = frames.size()
	var i: int = int(phase) % n
	var j: int = (i + 1) % n
	var low: Sprite2D = pair[0]
	var high: Sprite2D = pair[1]
	if low.texture != frames[i]:
		low.texture = frames[i]
	if high.texture != frames[j]:
		high.texture = frames[j]
	high.modulate.a = phase - floorf(phase)


func _process_embers(delta: float, s: Vector2) -> void:
	# Žar se diže od kratera (y 0.478) do y 0.420 i tu se ugasi — ceo život
	# ostaje ISPOD pojasa leta (y 0.40), da ne šara po nebu kroz koje prolazi
	# pterodaktil.
	for e in _embers:
		e.u += e.speed * delta
		if e.u >= 1.0:
			e.u -= 1.0
			e.phase = randf() * TAU
			e.speed = randf_range(0.055, 0.085)
		var u: float = e.u
		var sp: Sprite2D = e.node
		sp.position = Vector2(
			_crater.x + sin(u * 3.4 + e.phase) * s.x * 0.008,
			lerpf(s.y * 0.478, s.y * 0.420, u))
		var sc: float = (s.x * e.frac) / sp.texture.get_size().x
		sp.scale = Vector2.ONE * sc * (1.0 - u * 0.35)
		# Upali se brzo, gasi se dugo — kao pravo iskra iz vatre.
		sp.modulate.a = clampf(u * 6.0, 0.0, 1.0) * (1.0 - u) * 0.95


func _process_ptero(delta: float, s: Vector2) -> void:
	if _ptero_u >= 1.0:
		_ptero_wait -= delta
		if _ptero_wait > 0.0:
			_ptero.visible = false
			if is_instance_valid(_ptero_area):
				_ptero_area.position = Vector2(-9999, 0)
			return
		# Nov prelet: svaki put druga visina unutar pojasa y 0.26–0.40.
		_ptero_u = 0.0
		_ptero_y = randf_range(0.28, 0.38)
		_ptero_flap = 1.1                     # kreće zamahom, pa pređe u jedrenje
		_ptero_glide = 0.0

	_ptero.visible = true
	var dash: bool = _ptero_dash > 0.0
	if dash:
		_ptero_dash -= delta
	_ptero_u += delta / 18.0 * (PTERO_DASH_SPEED if dash else 1.0)   # prelet 18 s, na dodir brže
	if _ptero_u >= 1.0:
		_ptero.visible = false
		_ptero_wait = randf_range(7.0, 13.0)
		return

	var u := _ptero_u
	# Putanja je blag luk: spusti se ka sredini kadra pa se opet digne, kao
	# ptica koja iskoristi topao vazduh iznad vulkana.
	# Ulazi sa desne ivice i prolazi IZA palme (krošnja je uska, ne krije je
	# dugo), izlazi levo.
	_ptero.position = Vector2(
		lerpf(s.x * 1.12, -s.x * 0.12, u),
		s.y * _ptero_y + sin(u * PI) * s.y * 0.045)
	_ptero_area.position = _ptero.position     # tap zona prati pticu

	if _ptero_flap > 0.0 or _ptero_stopping:
		# 18 sličica u sekundi: pun zamah za 1,3 s. Na 11 se videla svaka
		# sličica posebno, pogotovo otkad je ptica veća.
		_ptero_fphase += delta * 18.0 * (PTERO_DASH_FPS if dash else 1.0)
		var cur: int = int(_ptero_fphase) % _ptero_frames.size()
		if _ptero_flap > 0.0:
			_ptero_flap -= delta
			if _ptero_flap <= 0.0:
				_ptero_stopping = true      # dovrši zamah do ravnih krila
		elif cur == PTERO_GLIDE_FRAME % _ptero_frames.size():
			_ptero_stopping = false
			_ptero_glide = randf_range(1.8, 3.2)
			_ptero_fphase = float(PTERO_GLIDE_FRAME)
		_set_pair(_ptero_pair, _ptero_frames, _ptero_fphase)
		# Telo prati zamah: blago se digne na zaveslaju, spusti kad krila miruju.
		_ptero.rotation = deg_to_rad(sin(_ptero_fphase * TAU / 24.0) * 4.0)
	else:
		_ptero_glide -= delta
		if _ptero_glide <= 0.0:
			_ptero_flap = randf_range(0.9, 1.5)
			# Zamah kreće od ravnih krila, da se poza ne "preskoči".
			_ptero_fphase = float(PTERO_GLIDE_FRAME)
		# Jedrenje: krila mirna, telo blago nagnuto — ptica seče vazduh.
		_ptero_gphase += delta * 8.0
		_set_pair(_ptero_pair, _ptero_glide_frames, _ptero_gphase)
		_ptero.rotation = deg_to_rad(-3.0 + sin(u * PI) * 6.0)


## Oblak prašine iza stopala dok trči — 8 sličica, odigra se jednom.
func _run_puff(s: Vector2) -> void:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/lava/jump-land-1.png")
	var tex := sp.texture.get_size()
	sp.scale = Vector2.ONE * ((s.x * 0.13) / tex.x)
	sp.offset = Vector2(0, -tex.y / 2.0)
	sp.position = Vector2(s.x * (_dino_x - _dino_w * 0.22), s.y * (DINO_GROUND - 0.01))
	sp.modulate = Color(0.95, 0.86, 0.76)          # prašina peska u sumraku, ne bela
	sp.z_index = 3                                  # iza prednjih paprati (z 4)
	add_child(sp)
	var tw := create_tween()
	for i in 8:
		var idx := i + 1
		tw.tween_callback(func() -> void: sp.texture = load("res://art/lava/jump-land-%d.png" % idx))
		tw.tween_interval(0.05)
	tw.tween_callback(sp.queue_free)


## Dodir na životinju: potrči. Ako je usred pauze, pauza se prekida — dete je
## dodirnulo i mora nešto da se desi odmah.
func _on_dino_tapped() -> void:
	if not _dino.visible:
		return
	UI.haptic(35)
	Audio.play("pop")
	# SVAKI tap ponovo pokreće trčanje — i dok već trči, sat se vraća na početak.
	_run_left = RUN_TIME
	_dino_rest = 0.0


func _process_dino(delta: float, s: Vector2) -> void:
	if _dino_x > DINO_END:
		_dino.visible = false
		_dino_shadow.visible = false
		_dino_area.position = Vector2(-9999, 0)      # van domašaja dok ga nema
		_dino_wait -= delta
		if _dino_wait <= 0.0:
			# Sledeći prolazak je DRUGA vrsta — nikad ista dvaput zaredom.
			var next: int = randi() % SPECIES.size()
			if next == _species:
				next = (next + 1) % SPECIES.size()
			_load_species(next, s)
			_dino_x = DINO_START
			_dino_rested = false
			_dino.visible = true
		return

	_dino.visible = true
	_dino.position = Vector2(s.x * _dino_x, s.y * DINO_GROUND)
	# Zona prati životinju; centar joj je na pola visine iznad stopala.
	_dino_area.position = _dino.position + Vector2(0, -_dino_h_px * 0.45)
	_dino_shadow.position = _dino.position + Vector2(0, -_dino_h_px * 0.01)
	_dino_shadow.scale = Vector2(_dino_w * _s.x / (_s.x * 0.11), 0.22)
	_dino_shadow.visible = _dino.visible
	var run: bool = _run_left > 0.0
	if run:
		_run_left -= delta
		_run_puff_t -= delta
		if _run_puff_t <= 0.0 and not _run_frames.is_empty():
			# Prašina samo uz pravo trčanje; brzi hod bronta i stega je ne diže.
			_run_puff_t = 0.22
			_run_puff(s)
	_dino_f += delta * _fps * (RUN_FPS if run else 1.0)

	if _dino_rest > 0.0:
		# Stoji: ide animacija STAJANJA, ne zamrznut frejm hoda. Isti isečak za
		# oba lista znači da se smena ne primeti.
		_dino_rest -= delta
		_dino.texture = _idle_frames[int(_dino_f) % _idle_frames.size()]
		return

	if run and not _run_frames.is_empty():
		_dino.texture = _run_frames[int(_dino_f) % _run_frames.size()]
	else:
		_dino.texture = _walk_frames[int(_dino_f) % _walk_frames.size()]

	# Dok trči ne staje na sredini — stane tek kad se umori.
	if not run and not _dino_rested and _dino_x > DINO_REST_AT:
		_dino_rested = true
		_dino_rest = randf_range(1.2, 2.2)
		return

	var half: int = int(_dino_f / 8.0)
	if half != _print_half:
		_print_half = half
		var foot: float = -0.05 if half % 2 == 0 else 0.05
		_drop_print(s, foot)
		_kick_dust(s, foot)

	_dino_x += delta * _speed * (RUN_SPEED if run else 1.0)
	if _dino_x > DINO_END:
		_dino_wait = 1.5   # čim jedan ode, za sekund i po izlazi sledeći


## Jedan otisak: spljoštena mrlja u boji tamnijeg peska, malo nasumična da red
## otisaka ne izgleda kao šara. Crta se ISPOD svega u prednjem planu (z 1), da
## dinosaurus prolazi preko svojih ranijih tragova.
func _drop_print(s: Vector2, at: float) -> void:
	var pos := Vector2(s.x * (_dino_x + at * _dino_w), s.y * (DINO_GROUND + 0.004))
	var node := UI.circle(self, pos, s.x * randf_range(0.011, 0.014), Color("#8A6349"), 1)
	node.scale = Vector2(1.0, 0.34)
	node.rotation = randf_range(-0.25, 0.25)
	_prints.append({"node": node, "age": 0.0})


## Zrna prašine iz jednog koraka — tri komada, svaki sa svojim smerom i brzinom.
func _kick_dust(s: Vector2, at: float) -> void:
	var base := Vector2(s.x * (_dino_x + at * _dino_w), s.y * (DINO_GROUND - 0.004))
	for i in 3:
		var node := UI.circle(self, base + Vector2(randf_range(-8.0, 8.0), 0.0),
			s.x * randf_range(0.004, 0.007), Color("#C99A70"), 3)
		_dust.append({
			"node": node,
			"age": 0.0,
			# Prašina se diže i zaostaje za životinjom, ne ide s njom napred.
			"vel": Vector2(randf_range(-0.9, -0.2) * s.x * 0.03, -randf_range(0.2, 0.5) * s.y * 0.06),
		})


func _process_dust(delta: float) -> void:
	var live: Array = []
	for d in _dust:
		d.age += delta
		if d.age >= DUST_LIFE:
			d.node.queue_free()
			continue
		var u: float = d.age / DUST_LIFE
		d.node.position += d.vel * delta
		d.node.scale = Vector2.ONE * (1.0 + u * 1.6)      # oblak se širi dok se gasi
		d.node.color.a = 0.5 * (1.0 - u) * (1.0 - u)
		live.append(d)
	_dust = live


func _process_prints(delta: float) -> void:
	var live: Array = []
	for pr in _prints:
		pr.age += delta
		if pr.age >= PRINT_LIFE:
			pr.node.queue_free()
			continue
		# Odmah je najtamniji, pa ga pesak polako zatrpa.
		pr.node.color.a = 0.42 * (1.0 - pr.age / PRINT_LIFE)
		live.append(pr)
	_prints = live


## Dodo samo stoji i vrpolji se u mestu — ranije je i provirivao (dizao se i
## spuštao), pa je izgledalo kao da poskakuje bez razloga.
func _process_peek(delta: float, s: Vector2) -> void:
	_peek_f += delta * 10.0
	_peek.texture = _peek_idle[int(_peek_f) % _peek_idle.size()]
	_peek.position = _peek_home


## Mehuri u jezercu: 10 sličica u sekundi, BEZ prelivanja. Dim i krila se
## prelivaju jer su neprozirni, ali crtež lave ima slojeve na 22–90%
## providnosti — kad se dva takva frejma poklope, providni slojevi se
## udvostruče i jezerce vidno treperi. Zato ovde ide obična smena sličica.
func _process_lava(delta: float) -> void:
	_lava_t += delta * 10.0
	var low: Sprite2D = _lava_pair[0]
	low.texture = _lava_frames[int(_lava_t) % _lava_frames.size()]
	var high: Sprite2D = _lava_pair[1]
	if high.visible:
		high.visible = false


## PRVI pokazivač na hubu je uvek KAPIJA — dete pre svega treba da nađe put do
## igre. Tek od drugog, i tek kad se vrati iz neke igre, pokazuje se i na mali
## dino koji se krije, jer ništa ne najavljuje da on reaguje na dodir.
## Na katanac se ne pokazuje nikad.
func hint_spot() -> Dictionary:
	# Pokazivač NE ide na dodoa: dete tapne, dodo ne odreaguje vidljivo, i
	# prst je pokazao "ništa". Samo kapije.
	if _open_gates.is_empty():
		return {}
	return {"at": _open_gates[randi() % _open_gates.size()].position, "size": 2.0}
