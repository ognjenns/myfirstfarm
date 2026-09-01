extends BaseScreen
## Ocean hub — ŽIV prizor, namerno nije šablon farme i džungle (tamo su
## životinje poređane u dva reda i stoje). Ovde ništa ne stoji: trava se
## leluja, ronilac se penje, kornjača i velika riba prolaze kroz kadar, jato
## kruži, rak šeta po dnu, mehurići se dižu iz školjke.
##
## Sve mere su frakcije širine/visine ekrana, tačno po dizajnerskoj
## specifikaciji (mock 2340×1080). Vrednosti se NE zaokružuju "na oko" —
## kompozicija zavisi od toga da se klasteri preklapaju a da prazan pesak
## između njih ostane prazan.

## U okeanu su besplatni ORKESTAR i SORTIRANJE PO BOJI; mehurići i vođenje
## ribice se otključavaju kupovinom. (Na farmi i u džungli su zaključane druge
## dve — svuda dve od četiri.)
const LOCKED_GAMES := ["bubbles", "leadfish"]
## Igre koje su stvarno napisane; ostale kapije stoje ali još ne vode nigde.
const IMPLEMENTED := ["bubbles", "leadfish", "orchestra", "colors"]

## Vlati i korali se ljuljaju oko OSLONCA NA DNU (pivot bottom-centre).
## amp = stepeni, per = sekunde. Koral-mozak se namerno NE ljulja: on je u
## prirodi kamen, pa svako talasanje odmah izgleda pogrešno.
var _sway: Array = []      # {node, amp_rad, period, phase, skew}
var _rig_parts: Array = []  # svi pokretni delovi bića (rep, peraja)
var _turtle_frames: Array = []   # sabljarka: gotova animacija od 24 frejma
var _jelly: Sprite2D
var _jelly_frames: Array = []
var _jelly_y := 0.62            # visina na kojoj lebdi
var _jelly_push := 0.0          # koliko još traje uzlet posle dodira
var _jelly_smoke: Array = []

## Svako biće ima SVOJ napredak kroz kadar, sopstveni sat za zamah peraja i
## množilac brzine. Bez toga ne može da pobegne nezavisno od ostalih.
var _prog := {"turtle": 0.0, "bigfish": 0.0, "shoal": 0.0}
var _dart := {"turtle": 1.0, "bigfish": 1.0, "shoal": 1.0}
var _wait := {"turtle": 0.0, "bigfish": 0.0, "shoal": 0.0}
## Koliko još traje nagli trzaj; posle toga se brzina vraća na normalu.
var _dart_left := {"turtle": 0.0, "bigfish": 0.0, "shoal": 0.0}
var _gtime := {"turtle": 0.0, "bigfish": 0.0, "shoal": 0.0}
var _t := 0.0

var _turtle: Node2D
var _big_fish: Node2D
var _shoal: Node2D
var _shoal_fish: Array = []
var _shoal_u := 0.0       # napredak jata kroz kadar, za detekciju izlaska
var _shoal_y := 0.43      # visina na kojoj jato prelazi ovaj put
var _crab: Node2D
var _crab_legs: Array = []   # noge: mašu samo dok kraba juri
var _crab_claws: Array = []  # klešta: tiho se njišu i kad stoji
var _crab_from := 0.34     # kraba se kreće u trzajima: kratak juriš pa pauza
var _crab_to := 0.34
var _crab_t := 1.0
var _crab_dur := 1.0
var _crab_pause := 2.0
var _crab_gait := 0.0      # 0 = miruje, 1 = pun kas
## Zakopavanje: 0 mirno, 1 tone, 2 pod peskom, 3 izranja.
var _crab_dig := 0.0
var _crab_dig_f := 0.0      # frejm animacije kopanja (1..8)
var _crab_dig_sprite: Sprite2D
var _crab_dig_state := 0
var _crab_dig_wait := 0.0
var _diver_extra := 0      # dodatni mehurići kad dete tapne ronioca
var _diver_gap := 0.0
var _diver_butt := Vector2.ZERO
var _crab_body: Sprite2D
var _crab_buried: Sprite2D
var _crab_normal: Array = []   # telo + noge + klešta — nestaju dok tone
var _dart_parts := {}          # delovi koji dobijaju "dart" teksturu u bekstvu
var _seahorses: Array = []
var _shy: Sprite2D
var _shy_home := Vector2.ZERO
var _diver: Node2D
var _diver_fins: Array = []
var _bubbles: Array = []   # {node, speed, wobble, phase, born}
var _emitter := Vector2.ZERO
var _next_bubble := 0.0
var _chest_lid: Sprite2D
var _chest_open := 0.0     # 0 = zatvoren, 1 = potpuno podignut poklopac
var _chest_emitter := Vector2.ZERO
var _chest_wait := 6.0     # tišina do sledećeg rafala
var _chest_left := 0       # koliko mehurića je ostalo u tekućem rafalu
var _chest_gap := 0.0      # razmak između mehurića unutar rafala
var _diver_emitter := Vector2.ZERO
var _next_diver_bubble := 0.0
var _s := Vector2.ZERO
var _open_gates: Array[TapButton] = []
var _hint_turn := 0


func _ready() -> void:
	var s := UI.vs(self)
	_s = s
	Scenery.background(self, "background-ocean")

	_build_kelp_grove(s)
	_build_diver(s)
	_build_swimmers(s)
	_build_jelly(s)
	_build_seabed(s)
	_build_shy_fish(s)
	_build_bubbles(s)

	_build_gates(s)
	_build_worlds_button()
	_build_parent_button(s)
	add_hint(6.0)
	set_process(true)


# ---------------------------------------------------------------- pomoćnici

## Postavi SVG tako da mu je OSLONAC na dnu (pivot bottom-centre), veličine
## zadate kao frakcija širine ekrana. Vraća Sprite2D.
func _plant(art: String, frac_w: float, cx: float, base_y: float, z: int) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/svg/%s.svg" % art)
	var tex := sp.texture.get_size()
	var sc := (_s.x * frac_w) / tex.x
	sp.scale = Vector2.ONE * sc
	sp.offset = Vector2(0, -tex.y / 2.0)      # ↓ origin na dnu slike
	sp.position = Vector2(_s.x * cx, _s.y * base_y)
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


## Sastavi biće od DELOVA sa zglobovima. Ovo je razlika između ribe koja
## stvarno pliva i slike koju savijamo: telo miruje, a rep i peraja se okreću
## oko svog korena, kao u prirodi.
##   pivot — tačka u viewBox-u SAMOG dela koja predstavlja koren (frakcija)
##   joint — gde na TELU taj koren stoji (frakcija tela)
## Vrednosti dolaze iz dizajnerske specifikacije i ne smeju se "zaokruživati".
func _rig(parent: Node, body_art: String, frac_w: float, parts: Array,
		pos: Vector2, z: int, grp := "") -> Dictionary:
	var node := Node2D.new()
	node.position = pos
	node.z_index = z
	parent.add_child(node)

	var body := Sprite2D.new()
	body.texture = load("res://art/svg/%s.svg" % body_art)
	var bt := body.texture.get_size()
	node.scale = Vector2.ONE * ((_s.x * frac_w) / bt.x)
	body.z_index = 0
	node.add_child(body)

	var joints: Array = []
	for p in parts:
		var sp := Sprite2D.new()
		sp.texture = load("res://art/svg/%s.svg" % p.art)
		var t := sp.texture.get_size()
		# Pivot dela pada tačno na njegov koren...
		sp.offset = -Vector2((p.pivot.x - 0.5) * t.x, (p.pivot.y - 0.5) * t.y)
		# ...a koren se postavlja na zglob na telu (telo je centrirano).
		sp.position = Vector2((p.joint.x - 0.5) * bt.x, (p.joint.y - 0.5) * bt.y)
		sp.z_index = p.z
		node.add_child(sp)
		joints.append({"node": sp, "amp": deg_to_rad(p.amp), "per": p.per,
			"ph": p.ph, "down": p.get("down", 0.0), "grp": grp})
	_rig_parts.append_array(joints)
	return {"node": node, "body": body, "parts": joints}


## Slobodan element (nije ukorenjen u dno) — centriran, veličina po frakciji.
func _piece(art: String, frac_w: float, pos: Vector2, z: int) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/svg/%s.svg" % art)
	var sc := (_s.x * frac_w) / sp.texture.get_size().x
	sp.scale = Vector2.ONE * sc
	sp.position = pos
	sp.z_index = z
	add_child(sp)
	return sp


# ------------------------------------------------------------------ elementi

func _build_kelp_grove(s: Vector2) -> void:
	# Gušće uz ivice, ređe ka sredini — time se kadar uokviri a centar ostane
	# čitljiv. Dve ivične vlati namerno izlaze iz kadra.
	var grove := [
		["seaweed-clump-large",  0.188, 0.045, 0.945],
		["seaweed-clump-medium", 0.147, 0.122, 0.952],
		["seaweed-clump-small",  0.108, 0.201, 0.926],
		["seaweed-clump-large",  0.198, 0.956, 0.941],
		["seaweed-clump-medium", 0.140, 0.863, 0.950],
		["seaweed-clump-small",  0.099, 0.782, 0.930],
	]
	for g in grove:
		var sp := _plant(g[0], g[1], g[2], g[3], -40)
		if g[2] > 0.5:
			sp.scale.x *= -1.0                 # desna strana je zrcaljena
		_add_sway(sp, 3.5, randf_range(3.5, 5.0))


func _build_seabed(s: Vector2) -> void:
	# KLASTER A (levo): sve se preklapa — korali sede NA kamenju, ne na
	# otvorenom pesku. Kamen namerno izlazi ispod donje ivice.
	_plant("rock", 0.159, 0.130, 1.056, -15)
	_plant("shell", 0.074, 0.206, 1.002, -14)
	_add_sway(_plant("coral-branch-small", 0.070, 0.249, 1.022, -14), 1.5, randf_range(3.5, 5.0))
	_plant("starfish", 0.063, 0.256, 1.050, -13)

	# PRAZAN PESAK x 0.390–0.509w — ovde se NIŠTA ne stavlja; jedino rak
	# prolazi kroz njega. Bez te praznine ceo prizor izgleda nabacano.

	# KLASTER B (desno od centra)
	_build_chest(s)
	_plant("rock", 0.089, 0.696, 0.981, -35)          # daleka dubina, iza svega
	_add_sway(_plant("coral-fan", 0.089, 0.703, 0.952, -12), 2.5, randf_range(3.5, 5.0))
	_add_sway(_plant("coral-branch-large", 0.113, 0.762, 0.985, -12), 1.5, randf_range(3.5, 5.0))
	# Spec ga šalje na 0.605w, ali to je SREDINA sanduka (0.509–0.685w) pa
	# koral završi na poklopcu kao jaje. Ide desno od sanduka, uz kamen.
	_plant("coral-brain", 0.082, 0.722, 1.030, -12)   # bez ljuljanja — to je kamen

	_build_crab(s)

	# Morski konjići: par, blago se klate u mestu, pola ciklusa razmaknuto
	var fin := [{"art": "seahorse-fin", "pivot": Vector2(0.167, 0.500),
		"joint": Vector2(0.775, 0.443), "z": 1, "amp": 9.0, "per": 0.18, "ph": 0.0}]
	var big: Node2D = _rig(self, "seahorse-body", 0.053, fin, Vector2(s.x * 0.815, s.y * 0.597), -6).node
	var small: Node2D = _rig(self, "seahorse-body", 0.041, fin.duplicate(true), Vector2(s.x * 0.851, s.y * 0.634), -6).node
	small.scale.x *= -1.0
	_seahorses = [
		{"node": big, "y0": big.position.y, "phase": 0.0},
		{"node": small, "y0": small.position.y, "phase": PI},
	]


## Sanduk je u dva dela da bi se pomerao SAMO poklopac. Šarka je donji-levi
## ugao poklopca; u fajlu je pomeren za translate(-70 -70), pa u sopstvenom
## viewBox-u pada na (18, 122) = (0.047w, 0.904h), a na telu na vrh kutije
## (88, 192) = (0.169w, 0.480h). Poklopac se crta IZA kutije, kao u originalu.
func _build_chest(s: Vector2) -> void:
	var sc := (s.x * 0.176) / 520.0
	var node := Node2D.new()
	node.position = Vector2(s.x * 0.597, s.y * 1.041 - 400.0 * sc * 0.5)
	node.scale = Vector2.ONE * sc
	node.z_index = -12
	add_child(node)

	_chest_lid = Sprite2D.new()
	_chest_lid.texture = load("res://art/svg/chest-lid.svg")
	var t := _chest_lid.texture.get_size()
	_chest_lid.offset = -Vector2((0.047 - 0.5) * t.x, (0.904 - 0.5) * t.y)
	_chest_lid.position = Vector2((0.169 - 0.5) * 520.0, (0.480 - 0.5) * 400.0)
	_chest_lid.z_index = -1
	node.add_child(_chest_lid)

	var body := Sprite2D.new()
	body.texture = load("res://art/svg/chest-body.svg")
	node.add_child(body)

	# Sanduk se može i TAPNUTI — deca su tražila da ga sama otvore, a ne samo
	# da čekaju. Automatski rafal ostaje netaknut; ovo je dodatak, ne zamena.
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(440.0, 340.0)      # kutija bez senke ispod nje
	shape.shape = rect
	shape.position = Vector2(0.0, 30.0)
	area.add_child(shape)
	node.add_child(area)
	area.input_event.connect(func(_vp: Node, ev: InputEvent, _i: int) -> void:
		if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_LEFT:
			get_viewport().set_input_as_handled()
			_burst_chest(true)
	)


## Rafal mehurića iz sanduka. `by_tap` = dete ga je samo otvorilo.
func _burst_chest(by_tap := false) -> void:
	if by_tap:
		# Bez zvuka: mehurići koji odmah pokuljaju su dovoljna potvrda, a hub
		# je namerno tih prizor — svaki dodatni zvuk ga pretvara u igru.
		UI.haptic(25)
		# Ponovljeni tap dopunjava rafal umesto da ga prekine — dete tapka
		# više puta zaredom i očekuje da svaki put nešto izađe.
		_chest_left = mini(_chest_left + randi_range(8, 14), 34)
	else:
		_chest_left = randi_range(12, 20)
	_chest_gap = 0.0
	_chest_wait = randf_range(20.0, 34.0)   # automatski se odlaže posle svakog rafala


## Kraba od delova. Pivoti su izvedeni iz translate() u samim fajlovima:
## crab-leg-outer ima translate(-46,-152) a kuk joj je (104,168) u originalu,
## pa u svom viewBox-u pada na (58,16) = (0.725w, 0.145h). Isto i za ostale.
## Noge i klešta idu IZA oklopa, da im se patrljci sakriju.
func _build_crab(s: Vector2) -> void:
	var sc := (s.x * 0.089) / 360.0
	_crab = Node2D.new()
	_crab.scale = Vector2.ONE * sc
	_crab.z_index = -8
	add_child(_crab)

	# [art, pivot, zglob na telu, ogledalo, amplituda, period, faza]
	var legs := [
		["crab-leg-outer", Vector2(0.725, 0.145), Vector2(0.289, 0.646), false, 0.00],
		["crab-leg-inner", Vector2(0.667, 0.140), Vector2(0.406, 0.685), false, 0.16],
		["crab-leg-inner", Vector2(0.667, 0.140), Vector2(0.594, 0.685), true, 0.00],
		["crab-leg-outer", Vector2(0.725, 0.145), Vector2(0.711, 0.646), true, 0.16],
	]
	for l in legs:
		_crab_legs.append({"node": _crab_part(l[0], l[1], l[2], l[3], -1), "ph": l[4]})

	var claws := [
		["crab-claw", Vector2(0.873, 0.867), Vector2(0.267, 0.477), false, 0.0],
		["crab-claw", Vector2(0.873, 0.867), Vector2(0.733, 0.477), true, 1.2],
	]
	for c in claws:
		_crab_claws.append({"node": _crab_part(c[0], c[1], c[2], c[3], -1), "ph": c[4]})

	_crab_body = Sprite2D.new()
	_crab_body.texture = load("res://art/svg/crab-body.svg")
	_crab.add_child(_crab_body)

	# Poza u kojoj viri samo vrh oklopa; ukršta se sa normalnom dok tone.
	_crab_dig_sprite = Sprite2D.new()
	_crab_dig_sprite.texture = load("res://art/svg/crab-dig-1.svg")
	_crab_dig_sprite.visible = false
	_crab_dig_sprite.z_index = 1
	_crab.add_child(_crab_dig_sprite)

	_crab_buried = Sprite2D.new()
	_crab_buried.texture = load("res://art/svg/crab-buried.svg")
	_crab_buried.modulate.a = 0.0
	_crab_buried.z_index = 1
	_crab.add_child(_crab_buried)

	_crab_normal.append(_crab_body)
	for l in _crab_legs:
		_crab_normal.append(l.node)
	for c in _crab_claws:
		_crab_normal.append(c.node)
	_add_tap(_crab, 360.0, 260.0, _crab_burrow)


func _crab_part(art: String, pivot: Vector2, joint: Vector2, mirror: bool, z: int) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/svg/%s.svg" % art)
	var t := sp.texture.get_size()
	sp.offset = -Vector2((pivot.x - 0.5) * t.x, (pivot.y - 0.5) * t.y)
	sp.position = Vector2((joint.x - 0.5) * 360.0, (joint.y - 0.5) * 260.0)
	if mirror:
		sp.scale.x = -1.0
	sp.z_index = z
	_crab.add_child(sp)
	return sp


## Meduza lebdi skroz desno i polako pulsira. Na dodir se odgurne naviše pa
## se lagano spusti nazad — meduze se tako i kreću, u trzajima pa klize.
func _build_jelly(s: Vector2) -> void:
	for i in 20:
		_jelly_frames.append(load("res://art/svg/jelly-rise-%d.svg" % (i + 1)))
	_jelly = Sprite2D.new()
	_jelly.texture = _jelly_frames[0]
	_jelly.scale = Vector2.ONE * ((s.x * 0.075) / 320.0)
	_jelly.position = Vector2(s.x * 0.945, s.y * _jelly_y)
	_jelly.z_index = -18
	add_child(_jelly)
	_add_tap(_jelly, 320.0, 460.0, func() -> void:
		if _jelly_push <= 0.0:
			_jelly_push = 1.6
			_puff_smoke()
			UI.haptic(18))


## Meduza pri odgurivanju ispusti oblačić — izlazi ISPOD nje, tamo gde se
## klobuk skupi i istisne vodu.
func _puff_smoke() -> void:
	for k in 2:
		var sp := Sprite2D.new()
		sp.texture = load("res://art/svg/jelly-smoke-1.svg")
		sp.position = _jelly.position + Vector2(randf_range(-0.012, 0.012) * _s.x,
			_s.y * randf_range(0.045, 0.075))
		sp.scale = Vector2.ONE * ((_s.x * randf_range(0.055, 0.085)) / 320.0)
		sp.z_index = -19
		add_child(sp)
		_jelly_smoke.append({"node": sp, "age": -0.10 * float(k), "base": sp.scale})


func _build_swimmers(s: Vector2) -> void:
	# KORNJAČA — četiri peraja, spori "leteći" zaveslaj (2,2 s). Daleke peraje
	# imaju svoju boju i pomerene zglobove, pa se čita druga strana tela.
	# Na mestu kornjače sada pliva SABLJARKA — gotova animacija od 24 frejma.
	# Kornjača je i kao rig i kao nacrtana animacija delovala ukočeno; izdužena
	# riba sa dugom sabljom i talasastim telom nosi pokret mnogo prirodnije.
	for i in 24:
		_turtle_frames.append(load("res://art/svg/swordfish-%d.svg" % (i + 1)))
	_turtle = Sprite2D.new()
	(_turtle as Sprite2D).texture = _turtle_frames[0]
	_turtle.scale = Vector2.ONE * ((s.x * 0.235) / 880.0)
	_turtle.position = Vector2(-s.x * 0.08, s.y * 0.38)
	_turtle.z_index = -25
	add_child(_turtle)
	_add_tap(_turtle, 880.0, 470.0, func() -> void: _flee("turtle"))

	# VELIKA RIBA — rep maše ređe i šire nego kod malih; prsna peraja kasni za
	# repom, a ona sa druge strane je još pola ciklusa pomerena.
	var bf := _rig(self, "big-fish-body", 0.174, [
		{"art": "big-fish-fin-far", "pivot": Vector2(0.500, 0.140), "joint": Vector2(0.548, 0.687), "z": -3, "amp": 16.0, "per": 0.9, "ph": 0.70},
		{"art": "big-fish-tail", "pivot": Vector2(0.933, 0.500), "joint": Vector2(0.304, 0.500), "z": -2, "amp": 11.0, "per": 0.9, "ph": 0.0},
		{"art": "big-fish-fin", "pivot": Vector2(0.500, 0.140), "joint": Vector2(0.587, 0.740), "z": -1, "amp": 16.0, "per": 0.9, "ph": 0.25},
	], Vector2(s.x * 1.08, s.y * 0.54), -20, "bigfish")
	_big_fish = bf.node
	_dart_parts["bigfish"] = [
		{"node": bf.parts[1].node, "off": "big-fish-tail", "on": "big-fish-tail-dart"},
	]
	_add_tap(_big_fish, 520.0, 300.0, func() -> void: _flee("bigfish"))
	_big_fish.scale.x *= -1.0                          # pliva ulevo

	_shoal = Node2D.new()
	_shoal.position = Vector2(s.x * 0.445, s.y * 0.433)
	_shoal.z_index = -22
	add_child(_shoal)
	# Šest ribica u kutiji koja putuje; svaka sa svojom fazom, da jato ne
	# izgleda kao jedna slika koja klizi.
	var spots := [Vector2(-0.045, -0.035), Vector2(0.030, -0.050), Vector2(0.062, 0.005),
		Vector2(-0.020, 0.030), Vector2(0.040, 0.055), Vector2(-0.058, 0.062)]
	for i in spots.size():
		var fw: float = 0.036 + 0.010 * (i % 3) / 2.0
		var r := _rig(_shoal, "small-fish-body", fw, [
			{"art": "small-fish-tail", "pivot": Vector2(0.925, 0.500), "joint": Vector2(0.310, 0.492), "z": -1, "amp": 14.0, "per": 0.55, "ph": randf() * 0.55},
		], Vector2(s.x * spots[i].x, s.y * spots[i].y), 0, "shoal")
		_shoal_fish.append({
			"node": r.node, "body": r.body, "home": r.node.position,
			"sx": r.node.scale.x, "per": randf_range(1.2, 1.8), "ph": randf() * TAU,
		})


func _build_shy_fish(s: Vector2) -> void:
	# Riba koja viri iz trave: sama riba je IZA vlati koja je zaklanja, pa se
	# vide samo glava i oko. Povremeno se pomeri napolje pa se vrati.
	_shy_home = Vector2(s.x * 0.133, s.y * 0.669)
	_shy = _piece("shy-fish", 0.063, _shy_home, -4)
	var screen := _plant("seaweed-clump-medium", 0.147, 0.149, 0.952, -2)
	_add_sway(screen, 3.5, randf_range(3.5, 5.0))


func _build_bubbles(s: Vector2) -> void:
	_emitter = Vector2(s.x * 0.205, s.y * 0.863)       # usta školjke
	_next_bubble = randf_range(1.2, 1.9)
	_chest_emitter = Vector2(s.x * 0.600, s.y * 0.800)  # otvor sanduka
	_chest_wait = randf_range(10.0, 18.0)


func _build_diver(s: Vector2) -> void:
	# Ronilac je sastavljen iz tri fajla i NIKAD nije ucrtan u pozadinu:
	# telo + dve peraje koje se okreću oko svog gornjeg centra (članak).
	_diver = Node2D.new()
	_diver.position = Vector2(s.x * 0.146, s.y * 1.10)
	_diver.z_index = -30                                # iza dna, ispred vode
	add_child(_diver)

	# Spec daje tačke u koordinatama mock kadra (telo gore-levo na 0.070w,
	# 0.178h; članci peraja na 0.118w/0.470h i 0.141w/0.481h; maska na
	# 0.178w/0.166h). Ovde je čvor usidren u CENTAR TELA, pa su sve te tačke
	# preračunate kao razlika u odnosu na njega — bez toga peraje odlutaju.
	var body := Sprite2D.new()
	body.texture = load("res://art/svg/diver-body.svg")
	var bsc := (s.x * 0.128) / body.texture.get_size().x
	body.scale = Vector2.ONE * bsc
	_diver.add_child(body)

	var fins := [
		{"local": Vector2(-0.016, 0.120), "rest": 16.0, "z": 1},
		{"local": Vector2(0.007, 0.131), "rest": -12.0, "z": -1},
	]
	for i in fins.size():
		var d: Dictionary = fins[i]
		var fin := Sprite2D.new()
		fin.texture = load("res://art/svg/diver-fin.svg")
		fin.scale = Vector2.ONE * bsc
		fin.offset = Vector2(0, fin.texture.get_size().y / 2.0)  # ↑ članak je VRH peraje
		fin.position = Vector2(s.x * d.local.x, s.y * d.local.y)
		fin.z_index = d.z                                # zadnja peraja ide iza tela
		_diver.add_child(fin)
		_diver_fins.append({"node": fin, "ph": PI * i, "rest": deg_to_rad(d.rest)})
	_diver_emitter = Vector2(s.x * 0.044, -s.y * 0.184)  # maska, u odnosu na centar tela
	_diver_butt = Vector2(-s.x * 0.020, s.y * 0.080)     # iza i ispod — odatle "iznenađenje"
	_add_tap(_diver, 420.0, 520.0, func() -> void:
		_diver_extra = randi_range(9, 15)
		_diver_gap = 0.0
		UI.haptic(20))
	_next_diver_bubble = randf_range(1.1, 1.6)


## Oblak peska — šest frejmova preko pola sekunde. Ide i pri zakopavanju i
## pri izranjanju, jer se pesak diže u oba smera.
## Nekoliko oblaka odjednom, razmaknutih i različitih veličina — jedan oblak
## deluje kao mrlja, tri deluju kao prašina koju kraba zaista diže.
func _sand_burst(pos: Vector2) -> void:
	for i in 3:
		var off := Vector2(randf_range(-0.022, 0.022) * _s.x, randf_range(-0.004, 0.010) * _s.y)
		var d := i * 0.09
		get_tree().create_timer(d).timeout.connect(func() -> void:
			if is_inside_tree():
				_sand_puff(pos + off, randf_range(0.075, 0.135)))


func _sand_puff(pos: Vector2, w := 0.115) -> void:
	var sp := Sprite2D.new()
	sp.position = pos
	sp.scale = Vector2.ONE * ((_s.x * w) / 256.0)
	sp.z_index = -7
	add_child(sp)
	for i in 6:
		sp.texture = load("res://art/svg/sand-puff-%d.svg" % (i + 1))
		await get_tree().create_timer(0.075).timeout
		if not is_instance_valid(sp):
			return
	sp.queue_free()


## Kraba se na dodir zakopa u pesak pa se posle izvuče. Dok je dole, ne šeta.
func _crab_burrow() -> void:
	if _crab_dig_state != 0:
		return
	_crab_dig_state = 1
	_sand_burst(_crab.position)
	UI.haptic(20)


## Pomeri biće kroz kadar. Vraća napredak 0..1. Dok `_wait` traje biće stoji
## na početku putanje, a to je van kadra — tako "kasnije se pojavi".
func _step(grp: String, dur: float, delta: float) -> float:
	# Trzaj traje oko sekundu pa se brzina mekano vrati na normalu. Ranije je
	# biće jurilo do izlaska iz kadra i onda se dugo nije vraćalo — dete bi
	# tapnulo i ostalo bez njega, umesto da vidi kako se trgne i nastavi.
	if _dart_left[grp] > 0.0:
		_dart_left[grp] -= delta
		if _dart_left[grp] <= 0.0:
			_dart[grp] = 1.0
		else:
			_dart[grp] = 1.0 + 4.0 * minf(1.0, _dart_left[grp] / 0.75)
	_gtime[grp] += delta * _dart[grp]
	_prog[grp] += delta / dur * _dart[grp]
	if _prog[grp] >= 1.0:
		_prog[grp] = 0.0
	return _prog[grp]


## Tap po biću: pojuri u smeru u kom je već išlo i izleti iz kadra. Ne okreće
## se i ne beži nasumično — dete tako vidi posledicu svog dodira.
func _flee(grp: String) -> void:
	if _dart_left[grp] > 0.0:
		return
	_dart_left[grp] = 1.0
	UI.haptic(20)
	if grp == "turtle":
		_dart_left["shoal"] = 1.0   # jato se trgne zajedno sa sabljarkom


## Velika tap zona na biću (mере su u koordinatama tela, čvor ih skalira).
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


# --------------------------------------------------------------------- pokret

func _process(delta: float) -> void:
	_t += delta
	var s := _s

	# Rep i peraja se okreću oko svog zgloba — telo se ne dira.
	# Rep i prednja peraja dobijaju "zabačenu" varijantu dok biće beži.
	for grp in _dart_parts:
		var fleeing: bool = _dart[grp] > 1.0
		for d in _dart_parts[grp]:
			var want: String = d.on if fleeing else d.off
			if d.get("cur", "") != want:
				d["cur"] = want
				d.node.texture = load("res://art/svg/%s.svg" % want)

	for r in _rig_parts:
		var rt: float = _gtime[r.grp] if _gtime.has(r.grp) else _t
		if r.down > 0.0:
			# Vreme se "savija": prva polovina sinusa se odvija za `down`
			# sekundi, druga za ostatak perioda — brz zamah, spor povratak.
			var tl: float = fmod(rt + r.ph, r.per)
			var u: float = (tl / r.down) * 0.5 if tl < r.down \
				else 0.5 + (tl - r.down) / (r.per - r.down) * 0.5
			r.node.rotation = sin(u * TAU) * r.amp
		else:
			r.node.rotation = sin((rt + r.ph) * TAU / r.per) * r.amp

	for w in _sway:
		var a: float = sin(_t * TAU / w.period + w.phase) * w.amp
		w.node.rotation = a
		w.node.skew = a * 0.5                           # mek pregib, ne kruta rotacija

	# Kornjača: pređe kadar za 26 s pa se vrati na početak
	var tt: float = _step("turtle", 26.0, delta)
	_turtle.position = Vector2(
		lerpf(-s.x * 0.08, s.x * 1.08, tt),
		lerpf(s.y * 0.38, s.y * 0.32, tt) + sin(tt * TAU * 2.0) * s.y * 0.03)
	# Bez sabijanja oklopa — oklop je tvrd. Ostaje samo blago propinjanje;
	# pravo veslanje čeka peraja kao zasebne fajlove.
	# Propinjanje ide na 5,6 s — tačno dva zamaha peraja, pa vrhovi nagiba
	# padaju na svaki drugi zaveslaj.
	(_turtle as Sprite2D).texture = _turtle_frames[int(_gtime["turtle"] * 11.0) % _turtle_frames.size()]
	_turtle.rotation = deg_to_rad(sin(tt * TAU * 2.0) * 4.0 + sin(_t * TAU / 5.6) * 3.0)

	# Velika riba: suprotan smer, brža
	var bt: float = _step("bigfish", 18.0, delta)
	_big_fish.position = Vector2(
		lerpf(s.x * 1.08, -s.x * 0.08, bt),
		lerpf(s.y * 0.54, s.y * 0.42, bt) + sin(bt * TAU * 2.0) * s.y * 0.04)
	_big_fish.rotation = -cos(bt * TAU * 2.0) * 0.09

	# Jato: kutija putuje levo-desno, ribice unutra svaka za sebe
	# Jato PRELAZI kadar i vraća se sa druge strane, ne okreće se u mestu —
	# okretanje u vazduhu je izgledalo kao da su na kanapu. Pri svakom novom
	# prolazu dobija drugu visinu, pa se ne ponavlja ista putanja.
	var u: float = _step("shoal", 26.0, delta)
	if u < _shoal_u:
		_shoal_y = randf_range(0.30, 0.56)
	_shoal_u = u
	_shoal.position = Vector2(lerpf(-s.x * 0.15, s.x * 1.15, u), s.y * _shoal_y)
	var heading := 1.0                                  # uvek udesno, art tako gleda
	for f in _shoal_fish:
		f.node.scale.x = f.sx * heading
		var vy: float = -sin(_t * TAU / (f.per * 1.3) + f.ph)
		f.node.position = f.home + Vector2(
			sin(_t * TAU / f.per + f.ph) * s.x * 0.008,
			cos(_t * TAU / (f.per * 1.3) + f.ph) * s.y * 0.010)
		f.node.rotation = vy * 0.14 * heading   # samo nos prati kuda riba ide
		f.body.scale.x = 1.0 - 0.03 * (0.5 + 0.5 * sin(_t * TAU / 1.1))

	# KRABA: kreće se BOČNO i u trzajima — kratak juriš pa duža pauza. Ne
	# okreće se (crtež je iz čela, kraba i u prirodi ide u stranu ne okrećući
	# se) i ne odskakuje: ono ranije poskakivanje je izgledalo kao žabica.
	if _crab_t >= 1.0:
		_crab_pause -= delta
		if _crab_pause <= 0.0:
			_crab_from = _crab_to
			_crab_to = randf_range(0.30, 0.46)
			# duže rastojanje = duži juriš, ali uvek brz
			_crab_dur = 0.45 + absf(_crab_to - _crab_from) * 4.0
			_crab_t = 0.0
			_crab_pause = randf_range(1.6, 4.0)
	else:
		_crab_t = minf(1.0, _crab_t + delta / _crab_dur)
	match _crab_dig_state:
		1:
			_crab_dig_f = minf(8.0, _crab_dig_f + delta / 0.070)
			_crab_dig_sprite.texture = load("res://art/svg/crab-dig-%d.svg" % clampi(int(_crab_dig_f) + 1, 1, 8))
			if _crab_dig_f >= 8.0:
				_crab_dig_state = 2
				_crab_dig_wait = randf_range(1.5, 2.4)
				_crab_dig_sprite.visible = false
				_crab_buried.modulate.a = 1.0
		2:
			_crab_dig_wait -= delta
			if _crab_dig_wait <= 0.0:
				_crab_dig_state = 3
				_crab_buried.modulate.a = 0.0
				_crab_dig_sprite.visible = true
				_sand_burst(_crab.position)
		3:
			_crab_dig_f = maxf(0.0, _crab_dig_f - delta / 0.070)
			_crab_dig_sprite.texture = load("res://art/svg/crab-dig-%d.svg" % clampi(int(_crab_dig_f) + 1, 1, 8))
			if _crab_dig_f <= 0.0:
				_crab_dig_state = 0
				_crab_dig_sprite.visible = false
	if _crab_dig_state != 0:
		_crab_t = 1.0                      # dok tone i izranja, ne juri
		if _crab_dig_state == 1 and _crab_dig_f < 0.6:
			_crab_dig_sprite.visible = true

	var ce: float = smoothstep(0.0, 1.0, _crab_t)
	var sc: float = (s.x * 0.089) / 360.0
	_crab.position.x = lerpf(s.x * _crab_from, s.x * _crab_to, ce)
	_crab.scale = Vector2.ONE * sc
	_crab.position.y = s.y * 0.983 - 260.0 * sc * 0.5
	# Prava kraba se sakrije čim počne kopanje; dalje se vidi samo animacija.
	var hidden: float = 0.0 if _crab_dig_state != 0 else 1.0
	for n in _crab_normal:
		n.modulate.a = hidden
	_crab.rotation = (sin(_t * 26.0) * 0.022) if _crab_t < 1.0 else 0.0

	# Noge rade SAMO dok juri i smiruju se kad stane; dve na istoj strani se
	# smenjuju, a dve strane su u suprotnoj fazi — to je kas, ne mahanje.
	var gait: float = 1.0 if _crab_t < 1.0 else 0.0
	_crab_gait = move_toward(_crab_gait, gait, delta * 5.0)
	for l in _crab_legs:
		l.node.rotation = sin((_t + l.ph) * TAU / 0.32) * deg_to_rad(18.0) * _crab_gait
	for c in _crab_claws:
		c.node.rotation = sin((_t + c.ph) * TAU / 2.4) * deg_to_rad(6.0)

	# Meduza: stalno lagano pulsira; posle dodira je uzlet nosi naviše pa se
	# vraća na svoju visinu.
	# 13 sličica u sekundi: na 8 se svaki frejm držao 125 ms i pokret je delovao
	# stepenasto. Uz to se telo penje i spušta U RITMU ciklusa, pa se kretanje
	# vidi i između frejmova — meduza se odgurne pri skupljanju pa klizne.
	var jt: float = _t * 13.0
	_jelly.texture = _jelly_frames[int(jt) % _jelly_frames.size()]
	var jc: float = fmod(jt, float(_jelly_frames.size())) / float(_jelly_frames.size())
	if _jelly_push > 0.0:
		_jelly_push -= delta
		_jelly_y = maxf(0.14, _jelly_y - 0.42 * delta)
	else:
		_jelly_y = minf(0.62, _jelly_y + 0.055 * delta)
	_jelly.position.y = s.y * _jelly_y + sin(_t * 1.1) * s.y * 0.006 - sin(jc * TAU) * s.y * 0.012

	for i in range(_jelly_smoke.size() - 1, -1, -1):
		var sm: Dictionary = _jelly_smoke[i]
		if not is_instance_valid(sm.node):
			_jelly_smoke.remove_at(i)
			continue
		sm.age += delta
		if sm.age < 0.0:
			sm.node.visible = false
			continue
		sm.node.visible = true
		var f := int(sm.age * 11.0)
		if f >= 8:
			sm.node.queue_free()
			_jelly_smoke.remove_at(i)
			continue
		sm.node.texture = load("res://art/svg/jelly-smoke-%d.svg" % (f + 1))
		sm.node.position.y += _s.y * 0.045 * delta
		sm.node.scale = sm.base * (1.0 + 0.5 * sm.age)

	for h in _seahorses:
		h.node.position.y = h.y0 + sin(_t * TAU / 2.5 + h.phase) * s.y * 0.004

	# Stidljiva riba: proviri pa se povuče
	var shy_c: float = fmod(_t, 6.4)
	var out := 0.0
	if shy_c < 1.2:
		out = shy_c / 1.2
	elif shy_c < 3.2:
		out = 1.0
	elif shy_c < 4.4:
		out = 1.0 - (shy_c - 3.2) / 1.2
	_shy.position.x = _shy_home.x + out * s.x * 0.008

	_process_diver(delta, s)
	_process_bubbles(delta, s)


func _process_diver(delta: float, s: Vector2) -> void:
	# Penjanje traje 34 s; x blago vijuga da uspon ne izgleda kao lift.
	# Ulazi sa LEVE strane pri dnu i izlazi gore — prirodnije nego da izranja
	# iz peska. Kriva je blaga: prvo napred, pa sve više naviše.
	var dt: float = fmod(_t / 34.0, 1.0)
	_diver.position = Vector2(
		lerpf(-s.x * 0.12, s.x * 0.34, dt) + sin(_t * TAU / 11.0) * s.x * 0.018,
		lerpf(s.y * 0.88, -s.y * 0.20, dt * dt))       # ubrzava ka površini
	_diver.rotation = deg_to_rad(14.0 + sin((_t + 1.4) * TAU / 5.5) * 4.0)
	for i in _diver_fins.size():
		var f: Dictionary = _diver_fins[i]
		# Peraje kasne za telom — to daje osećaj zamaha, ne krutog para nogu.
		f.node.rotation = f.rest + deg_to_rad(sin((_t - 0.12) * TAU / 1.6 + f.ph) * 22.0)

	if _diver_extra > 0:
		_diver_gap -= delta
		if _diver_gap <= 0.0:
			_diver_gap = randf_range(0.045, 0.095)
			_diver_extra -= 1
			_spawn_bubble("diver-bubble", _diver.position + _diver_butt,
				randf_range(0.010, 0.022), randf_range(0.10, 0.16), 1)

	_next_diver_bubble -= delta
	if _next_diver_bubble <= 0.0:
		_next_diver_bubble = randf_range(1.1, 1.6)
		_spawn_bubble("diver-bubble", _diver.position + _diver_emitter,
			randf_range(0.008, 0.014), 0.09, 1)


func _process_bubbles(delta: float, s: Vector2) -> void:
	_next_bubble -= delta
	if _next_bubble <= 0.0:
		_next_bubble = randf_range(1.2, 1.9)
		_spawn_bubble("bubble", _emitter, randf_range(0.009, 0.017), 0.16, 0)

	# SANDUK: dugo ništa, pa odjednom rafal mehurića, pa opet tišina. Stalno
	# curenje bi postalo pozadinski šum; iznenadan rafal dete primeti.
	# Poklopac je otvoren dok traje rafal, pa se polako spusti. Kretanje je
	# lerp ka cilju, ne skok — sanduk pod vodom nema zašto da lupi.
	var want: float = 1.0 if _chest_left > 0 else 0.0
	_chest_open = move_toward(_chest_open, want, delta * (2.6 if want > 0.0 else 0.7))
	_chest_lid.rotation = deg_to_rad(-22.0) * ease(_chest_open, 0.6)

	if _chest_left > 0:
		_chest_gap -= delta
		if _chest_gap <= 0.0:
			_chest_gap = randf_range(0.04, 0.11)
			_chest_left -= 1
			var jitter := Vector2(randf_range(-0.028, 0.028) * s.x,
				randf_range(-0.012, 0.012) * s.y)
			_spawn_bubble("bubble", _chest_emitter + jitter,
				randf_range(0.007, 0.020), randf_range(0.13, 0.21), -11)
	else:
		_chest_wait -= delta
		if _chest_wait <= 0.0:
			_burst_chest()

	for i in range(_bubbles.size() - 1, -1, -1):
		var b: Dictionary = _bubbles[i]
		if not is_instance_valid(b.node):
			_bubbles.remove_at(i)
			continue
		b.age += delta
		b.node.position.y -= s.y * b.speed * delta
		b.node.position.x = b.x0 + sin(b.age * 2.2 + b.ph) * s.x * 0.006
		b.node.scale = b.base_scale * (1.0 + 0.35 * minf(1.0, b.age / 6.0))
		if b.node.position.y < s.y * 0.10:
			b.node.modulate.a = maxf(0.0, b.node.modulate.a - delta * 1.6)
			if b.node.modulate.a <= 0.01:
				b.node.queue_free()
				_bubbles.remove_at(i)


func _spawn_bubble(art: String, pos: Vector2, frac_w: float, speed: float, z: int) -> void:
	var sp := _piece(art, frac_w, pos, z)
	_bubbles.append({
		"node": sp, "x0": pos.x, "speed": speed,
		"ph": randf() * TAU, "age": 0.0, "base_scale": sp.scale,
	})


# ------------------------------------------------------------------------ UI

func _build_gates(s: Vector2) -> void:
	var gates := [
		{"screen": "bubbles", "icon": "icon-bubble-catch"},
		{"screen": "leadfish", "icon": "icon-lead-fish"},
		{"screen": "colors", "icon": "icon-color-sort"},
		{"screen": "orchestra", "icon": "icon-orchestra"},
	]
	for i in gates.size():
		var g: Dictionary = gates[i]
		var pos := Vector2(s.x * (0.274 + 0.1505 * i), s.y * 0.170)
		var btn := TapButton.new(pos, 105, Pal.BUTTON_WHITE)
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
		if not locked and target in IMPLEMENTED:
			_open_gates.append(btn)


## PRVI pokazivač na hubu je uvek KAPIJA — dete pre svega treba da nađe put
## do igre, i to važi pri svakom dolasku na hub, ne samo prvi put.
## Tek od drugog pokazivača, i tek kad se vrati iz neke igre, pokazuje se i
## na bića — tada već zna gde su igre, pa je red da otkrije da i meduza
## reaguje na dodir.
## U listi meta su SAMO otključane kapije — na katanac se ne pokazuje nikad.
func hint_spot() -> Dictionary:
	_hint_turn += 1
	var main: Node = get_tree().get_first_node_in_group("main")
	if main.played_game and _hint_turn % 2 == 0:
		# Meduza, ronilac i sanduk odgovaraju na dodir, a ništa to ne najavljuje.
		var live: Array[Node2D] = []
		for n in [_jelly, _diver, _crab]:
			if is_instance_valid(n):
				live.append(n)
		if is_instance_valid(_chest_lid) and _chest_lid.get_parent() is Node2D:
			live.append(_chest_lid.get_parent())
		if not live.is_empty():
			return {"at": live[randi() % live.size()].position, "size": 1.9}
	if _open_gates.is_empty():
		return {}
	return {"at": _open_gates[randi() % _open_gates.size()].position, "size": 2.0}



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
	btn.z_index = 10
	add_child(btn)
