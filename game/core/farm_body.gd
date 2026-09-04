class_name FarmBody
extends Node2D
## Životinja CELIM TELOM iz kupljenih paketa (art/<dir>/<key>-<anim>-N.png).
## Stoji na nogama (čvor je na tlu ispod stopala), diše sličicama stajanja,
## a na dodir se oglasi i uradi svoju "tačku" (jede, skoči, zaleprša).
## API je isti kao kod AnimalSprite (glava), da hub i igre rade sa oba.
##
## Ko još nema kupljen paket (lav u džungli) dobija ISTI API sa starom
## vektorskom glavom: senka na tlu, poskok na dodir. Tako ekrani ne moraju
## da znaju ko je "pravi", a kad paket stigne, dodaje se samo red u ANIMS.

signal tapped(animal: Dictionary)

## Koliko sličica ima koja animacija i šta je "tačka" na dodir.
##   dir   — folder u art/ (podrazumevano "farm")
##   react — ime animacije-tačke; "jump"/"fly" dobijaju i luk položaja
##   eat   — broj sličica jedenja (ime animacije je u eat_anim, inače "eat")
##   hang  — visi (majmun na lijani): čvor je kod RUKU, ne kod stopala
const ANIMS := {
	"cow":     {"idle": 20, "walk": 10, "react": "eat", "rn": 20, "eat": 20},
	"horse":   {"idle": 25, "walk": 15, "react": "jump", "rn": 10, "eat": 25},
	"pig":     {"idle": 25, "walk": 15, "react": "jump", "rn": 10},
	"goat":    {"idle": 25, "walk": 15, "react": "jump", "rn": 10, "eat": 25},
	"chicken": {"idle": 20, "walk": 16, "react": "jump", "rn": 12},
	"duck":    {"idle": 25, "walk": 15, "react": "fly", "rn": 15},
	# Džungla (03.09.2026): majmun čuči, na dodir skoči; nilski konj zeva na
	# sav glas i istim pokretom žvaće; slon trubi surlom; žirafa pruži vrat,
	# a kad jede — sagne se do tla; papagaj zaleprša.
	"monkey":      {"dir": "jungle", "idle": 20, "walk": 10, "react": "jump", "rn": 10},
	"monkey-vine": {"dir": "jungle", "idle": 20, "walk": 0, "react": "bounce", "rn": 10, "hang": true},
	"hippo":       {"dir": "jungle", "idle": 20, "walk": 16, "react": "bite", "rn": 10, "eat": 10, "eat_anim": "bite"},
	"elephant":    {"dir": "jungle", "idle": 20, "walk": 16, "react": "blow", "rn": 10},
	"giraffe":     {"dir": "jungle", "idle": 20, "walk": 8, "react": "reach", "rn": 10, "eat": 10, "eat_anim": "graze"},
	# Lav (04.09.2026): sličice sklopljene iz Spriter fajla bez obrva i očnjaka
	# (assets/cut_jungle.py) — kupljeni keyframe-ovi su namršteni.
	"lion":        {"dir": "jungle", "idle": 20, "walk": 16, "react": "roar", "rn": 10},
	# Papagaj je jedini nacrtan okrenut UDESNO.
	"parrot":      {"dir": "jungle", "idle": 12, "walk": 16, "react": "fly", "rn": 16, "faces_right": true},
}

## Gde je vizuelna SREDINA tela u sličici stajanja, kao deo širine platna
## (sredina okvira neprovidnih piksela). Platno je šire od tela, pa sredina
## slike nije sredina životinje; ko hoće da životinja stane tačno na nešto
## (kamen u kvizu) koristi feet_shift().
const FEET := {"monkey": 0.47, "hippo": 0.504, "elephant": 0.587, "giraffe": 0.613, "parrot": 0.50, "lion": 0.493}

var animal: Dictionary
var base_scale := Vector2.ONE
var sprite: Sprite2D
var face: Node2D            # samo kad nema paketa (lav)
var _key := ""
var _dir := "farm"
var _idle: Array = []
var _react: Array = []
var _eat: Array = []
var _walk: Array = []
var _f := 0.0
var _mode := "idle"
var _height := 200.0
var _face_right := false
var _size := Vector2.ZERO   # vidljiva veličina tela u pikselima ekrana
var hangs := false           # visi (majmun na lijani) — čvor je kod ruku
var interactive := true      # false = dodir ne radi ništa (kupanje, žmurke vode svoju logiku)


static func has_pack(id: String) -> bool:
	return ANIMS.has(id)


## Nepokretna slika za kartice, dugmad i kartu sveta: prva sličica stajanja
## iz paketa, ili stara glava. Vraća čvor centriran na sredinu crteža.
static func portrait(id: String, height_px: float) -> Node2D:
	var n := Node2D.new()
	if ANIMS.has(id):
		var a: Dictionary = ANIMS[id]
		var sp := Sprite2D.new()
		sp.texture = load("res://art/%s/%s-idle-1.png" % [a.get("dir", "farm"), id])
		var t := sp.texture.get_size()
		sp.scale = Vector2.ONE * (height_px / maxf(t.y, t.x * 0.75))
		n.add_child(sp)
	else:
		var f := AnimalFaces.build(id)
		f.scale = Vector2.ONE * (height_px / 230.0)
		n.add_child(f)
	return n


func _init(animal_data: Dictionary, height_px: float, face_right := false, key := "") -> void:
	animal = animal_data
	_height = height_px
	_face_right = face_right
	_key = key if key != "" else String(animal.id)
	if not ANIMS.has(_key):
		_init_face(height_px)
		return
	var a: Dictionary = ANIMS[_key]
	_dir = String(a.get("dir", "farm"))
	hangs = bool(a.get("hang", false))
	_idle = _frames("idle", int(a.idle))
	_walk = _frames("walk", int(a.walk))
	_react = _frames(String(a.react), int(a.rn))
	if a.has("eat"):
		_eat = _frames(String(a.get("eat_anim", "eat")), int(a.eat))
	sprite = Sprite2D.new()
	sprite.texture = _idle[0]
	var t := sprite.texture.get_size()
	var sc: float = height_px / t.y
	# Crteži gledaju ulevo (papagaj udesno): ogledaj kad treba suprotno.
	var mirror: bool = face_right != bool(a.get("faces_right", false))
	base_scale = Vector2(-sc if mirror else sc, sc)
	sprite.scale = base_scale
	_size = t * sc
	# stopala na čvoru; ko visi — ruke na čvoru
	sprite.offset = Vector2(0, t.y / 2.0) if a.get("hang", false) else Vector2(0, -t.y / 2.0)
	add_child(sprite)

	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(t.x * sc * 1.1, height_px * 1.15)
	shape.shape = rect
	shape.position = Vector2(0, height_px * 0.5) if a.get("hang", false) else Vector2(0, -height_px * 0.5)
	area.add_child(shape)
	add_child(area)
	area.input_event.connect(_on_input)
	_f = randf() * 20.0


## Bez paketa: stara glava, skalirana na traženu visinu, sa senkom na tlu.
func _init_face(height_px: float) -> void:
	var sc: float = height_px / 230.0
	face = AnimalFaces.build(_key)
	face.scale = Vector2.ONE * sc
	face.position = Vector2(0, -height_px * 0.5)
	base_scale = face.scale
	_size = Vector2(230.0, 230.0) * sc
	Scenery.ground_shadow(self, Vector2(0, -height_px * 0.02), 95.0 * sc)
	add_child(face)
	var area := Area2D.new()
	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = height_px * 0.55
	shape.shape = circle
	shape.position = Vector2(0, -height_px * 0.5)
	area.add_child(shape)
	add_child(area)
	area.input_event.connect(_on_input)


## Vidljiva širina i visina tela na ekranu (za razmak rekvizita uz njušku).
func body_size() -> Vector2:
	return _size


## Koliko je sredina tela desno od čvora, u pikselima ekrana (negativno =
## levo). Uzima u obzir ogledanje.
func feet_shift() -> float:
	var fx: float = float(FEET.get(_key, 0.5))
	return (fx - 0.5) * _size.x * signf(base_scale.x)


## Meka senka pod stopalima — bez nje na ravnom tlu džungle životinje "lebde".
## Crta se kao dete iza tela (z -1 relativno), pa ostaje ispod te životinje,
## a iznad svega što je dublje u sceni.
func add_shadow() -> void:
	if hangs:
		return
	# Tamnija od farmske senke: tlo džungle je tamnozeleno, 16 % se ne vidi.
	Scenery.ground_shadow(self, Vector2(0, -_size.y * 0.01), _size.x * 0.40, -1, Color(0.05, 0.16, 0.06, 0.38))


func _frames(anim: String, n: int) -> Array:
	var out: Array = []
	for i in n:
		out.append(load("res://art/%s/%s-%s-%d.png" % [_dir, _key, anim, i + 1]))
	return out


func _ready() -> void:
	set_process(sprite != null)


func _on_input(_vp: Node, event: InputEvent, _idx: int) -> void:
	if not interactive:
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		get_viewport().set_input_as_handled()
		react()
		tapped.emit(animal)


## Glas + tačka. Isto ime i potpis kao kod glave.
func react(happy := false) -> void:
	Audio.animal_voice(animal.id)
	UI.haptic(20)
	# Kad je nahranjena: JEDE ako paket ima jedenje (krava, konj, koza),
	# inače svoja tačka (skok, lepršanje).
	if happy and not _eat.is_empty():
		_mode = "eat"
		_f = 0.0
	else:
		play_react()


## Bez glasa: ko ima jedenje žvaće, ostali skoče. Za slavlje na kraju runde.
func play_happy() -> void:
	if not _eat.is_empty():
		_mode = "eat"
		_f = 0.0
	else:
		play_react()


func play_react() -> void:
	if face:
		UI.bounce(face, base_scale)
		return
	if _mode == "react":
		return
	_mode = "react"
	_f = 0.0
	# Skok iz paketa je samo poza; bez pomeranja tela izgleda ukočeno. Telo
	# ide u luk gore-dole tačno koliko traju sličice.
	var kind: String = String(ANIMS[_key].react)
	if kind == "jump" or kind == "fly":
		var dur: float = _react.size() / 16.0
		var tw := create_tween()
		tw.tween_property(self, "position:y", position.y - _height * 0.35, dur * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tw.tween_property(self, "position:y", position.y, dur * 0.5).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)


func set_walking(on: bool) -> void:
	if _mode == "react" or _walk.is_empty():
		return
	_mode = "walk" if on else "idle"


func is_busy() -> bool:
	return _mode == "react" or _mode == "eat"


func shake() -> void:
	UI.head_shake(self)


func _process(delta: float) -> void:
	match _mode:
		"eat":
			_f += delta * 14.0
			if int(_f) >= _eat.size() * 2:      # dva zalogaja
				_mode = "idle"
				_f = 0.0
				sprite.texture = _idle[0]
			else:
				sprite.texture = _eat[int(_f) % _eat.size()]
		"react":
			_f += delta * 16.0
			if int(_f) >= _react.size():
				_mode = "idle"
				_f = 0.0
				sprite.texture = _idle[0]
			else:
				sprite.texture = _react[int(_f)]
		"walk":
			_f += delta * 14.0
			sprite.texture = _walk[int(_f) % _walk.size()]
		_:
			_f += delta * 10.0
			sprite.texture = _idle[int(_f) % _idle.size()]
