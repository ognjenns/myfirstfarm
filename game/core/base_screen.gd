class_name BaseScreen
extends Node2D
## Zajedničko za sve ekrane: navigacija + kućica za povratak na hub.

## Gde vodi "kućica" — mini-igre iz džungle postavljaju "jungle".
var home_target := "hub"

func go(screen_name: String) -> void:
	get_tree().get_first_node_in_group("main").goto(screen_name)

func add_home_button() -> void:
	var btn := TapButton.new(Vector2(110, 110), 75, Color(1, 1, 1, 0.9))
	# ikonica kućice
	UI.poly(btn, PackedVector2Array([Vector2(-42, 0), Vector2(0, -38), Vector2(42, 0)]), Color("#e2574c"))  # krov
	UI.poly(btn, UI.rect_points(56, 36), Color("#f5b971"), Vector2(0, 18))  # zid
	UI.poly(btn, UI.rect_points(16, 20), Color("#8d5524"), Vector2(0, 26))  # vrata
	btn.tapped.connect(func() -> void: go(home_target))
	# Izlaz mora biti IZNAD svega i uvek dodirljiv — visok z_index takodje
	# znaci da dugme prvo hvata dodir. U vodi-ribicu ga je na tabletu
	# pokrivala tavanica pecine, koja stoji na z 5.
	btn.z_index = 100
	add_child(btn)

## Ambijent za mini-igre: oblaci + leptir (džungla nema letača).
var ambient_flyer := "butterfly"

func add_ambient(cloud_count := 2, flyer := "butterfly") -> void:
	ambient_flyer = flyer
	var s := UI.vs(self)
	for i in cloud_count:
		Scenery.cloud(self, Vector2(s.x * randf_range(0.1, 0.9), randf_range(80, 230)), randf_range(0.7, 1.0))
	var fly_timer := Timer.new()
	fly_timer.wait_time = 7.0
	fly_timer.timeout.connect(_spawn_ambient_flyer)
	add_child(fly_timer)
	fly_timer.start()
	get_tree().create_timer(2.5).timeout.connect(_spawn_ambient_flyer)

func _spawn_ambient_flyer() -> void:
	var s := UI.vs(self)
	var y := randf_range(120, 380)
	var from_left := randf() < 0.5
	var from := Vector2(-60 if from_left else s.x + 60, y)
	var to := Vector2(s.x + 60 if from_left else -60, y + randf_range(-80, 80))
	add_child(FarmButterfly.new(from, to, FarmButterfly.COLORS[randi() % FarmButterfly.COLORS.size()]))

## Pokazivač: ako ekran miruje `delay` sekundi, prst pokaže šta se radi, i
## ponavlja to dok dete ne dodirne ekran. Ekran samo kaže GDE (`hint_spot`).
var _hint_node: Hint = null
var _hint_timer: Timer = null
var _hint_delay := 6.0


## Posle koliko pokretanja aplikacije dete više "zna igru".
const LEARNED_AFTER := 2
## Tada se pokazivač ne gasi nego se povuče: javlja se tek posle dugog
## mirovanja. Potpuno gašenje bi vratilo problem zbog kog je i uveden — dete
## koje zaboravi (ili mlađi brat koji prvi put uzme tablet) ostaje bez ičega.
const LEARNED_FIRST := 12.0
const LEARNED_DELAY := 20.0


func add_hint(delay := 6.0, first := 2.0) -> void:
	if "--nohint" in OS.get_cmdline_user_args():
		return   # screenshotovi za prodavnice: bez prsta
	if Save.launches > LEARNED_AFTER:
		delay = LEARNED_DELAY
		first = LEARNED_FIRST
	# Prst pokaže ODMAH na svakom ulasku (03.09.2026): deca i pri drugom ulasku
	# krenu da tapkaju bilo gde pre nego što se prst javi. Kasnije ponavljanje
	# ostaje ređe kad je igra naučena.
	var script_path: String = get_script().resource_path
	Save.first_visit(script_path.get_file().get_basename())
	first = 0.4
	_hint_delay = delay
	_hint_timer = Timer.new()
	# Prvi put pokazivač dolazi posle dve sekunde — dete koje tek uđe u igru ne
	# zna šta se traži, a čekanje od šest sekundi je za taj uzrast večnost.
	# Posle toga se javlja ređe, da ne smeta onome ko je već shvatio.
	_hint_timer.wait_time = first
	_hint_timer.timeout.connect(_fire_hint)
	add_child(_hint_timer)
	_hint_timer.start()
	var watcher := HintWatcher.new()
	watcher.touched.connect(_on_hint_touch)
	add_child(watcher)


## Gde pokazivač da pokaže: {"at": Vector2} za tap, {"from": ..., "to": ...}
## za prevlačenje, uz opciono {"size": 1.8} kad meta traži krupniji prsten.
## Prazan rečnik = trenutno nema šta da se pokaže (runda se slavi, dete već
## drži prst na ekranu...). Svaki ekran ga piše za sebe.
func hint_spot() -> Dictionary:
	return {}


func _fire_hint() -> void:
	_hint_timer.wait_time = _hint_delay
	if is_instance_valid(_hint_node):
		return
	var spot := hint_spot()
	if spot.is_empty():
		return
	var size: float = spot.get("size", 1.0)
	if spot.has("from"):
		_hint_node = Hint.drag(self, spot["from"], spot["to"], size)
	else:
		_hint_node = Hint.tap(self, spot["at"], size)


func _on_hint_touch() -> void:
	if is_instance_valid(_hint_node):
		_hint_node.vanish()
		_hint_node = null
	if _hint_timer:
		_hint_timer.start()  # odbrojavanje kreće ispočetka posle svakog dodira


## Dodir se prati zasebnim čvorom: ekran koji ima svoj `_input` bi inače
## prekrio nasleđeni (GDScript ne zove roditeljski automatski).
class HintWatcher extends Node:
	signal touched

	func _input(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.pressed:
			touched.emit()


## Mali narandžasti bljesak (kupljeni "charge" efekat, 10 sličica) — zamena
## za konfete tamo gde one odvlače pažnju.
func glow(pos: Vector2, height: float) -> void:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/fx/charge-1.png")
	sp.scale = Vector2.ONE * (height / sp.texture.get_size().y)
	sp.position = pos
	sp.z_index = 25
	sp.modulate = Color(1.0, 0.62, 0.2, 0.55)
	add_child(sp)
	var tw := create_tween()
	for i in 10:
		var idx := i + 1
		tw.tween_callback(func() -> void: sp.texture = load("res://art/fx/charge-%d.png" % idx))
		tw.tween_interval(0.05)
	tw.tween_callback(sp.queue_free)


func celebrate(pos: Vector2) -> void:
	# Slavlje je SAMO pravi dečji glas. Pobednički đingl je zvučao kao arkadna
	# igra, a aplauz malog skupa na tihom nivou pucketa kao vatromet — oba su
	# izbačena. Konfete nose vizuelni deo, glas nosi emociju.
	var kid: String = ["yay", "giggle", "kid"][randi() % 3]
	Audio.play(kid, -2.0)
	UI.confetti(self, pos, 90)
	UI.confetti(self, pos + Vector2(-350, 60), 50)
	UI.confetti(self, pos + Vector2(350, 60), 50)
