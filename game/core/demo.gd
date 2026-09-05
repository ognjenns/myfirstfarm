class_name Demo
extends RefCounted
## Demo prolaz za promo video: aplikacija se sama igra PRAVIM dodirima, a na
## ekranu se vidi prst. Pokretanje: marketing/record_short.sh (Movie Maker).
##
## Razlika u odnosu na Autotest: on zove logiku igara direktno (brzo, za
## proveru), a ovde ide pravi InputEvent kroz viewport — na snimku se dešava
## tačno ono što vidi i dete: kapija poskoči, riba zapeva, mehurići krenu.
##
## Ekrani se NE traže po tvrdim koordinatama nego po čvorovima (kartice sveta,
## kapije, muzičari), pa raspored igre može da se pomeri a demo i dalje pogađa.

## Poluprečnik "jastučića" prsta u dizajnerskim koordinatama (1920×1080).
const R := 52.0
## Pentatonika okeanskog orkestra: 0 = najniži stub, 5 = najviši (oktava).
const MELODY := [0, 2, 4, 2, 0, 1, 3, 5, 3, 1, 0, 2, 4, 5, 0]

var main: Node2D
var layer: CanvasLayer
var hand: Node2D


func _init(main_node: Node2D) -> void:
	main = main_node


func run() -> void:
	main.get_tree().create_timer(120.0).timeout.connect(func() -> void:
		printerr("DEMO TIMEOUT")
		main.get_tree().quit(3))
	seed(20260901)  # isti raspored ribica pri svakom snimanju
	_build_hand()

	# 1) pokretanje aplikacije — splash sam prelazi na izbor svetova u 5,0 s
	print("DEMO: splash")
	main.goto("splash")
	await _sleep(5.15)

	# 2) izbor sveta: prst uleti odozdo i tapne OKEAN (treća kartica)
	print("DEMO: worlds")
	# Prst prvo uleti u kadar i stane — tri sveta moraju da se vide pre nego
	# što jedan bude izabran, inače ekran promakne za manje od sekunde.
	await _move_to(Vector2(_vs().x * 0.5, _vs().y * 0.80))
	await _sleep(0.9)
	var cards := _children_of_type(main.current, "Area2D")
	await _tap(_at(cards, 2, Vector2(_vs().x * 0.80, _vs().y * 0.50)), 0.9)

	# 3) okeanski hub je živ i pre nego što se bilo šta izabere: sabljarka
	#    prolazi, kraba kopa. Jedan tap na sanduk pokaže da SVE reaguje.
	print("DEMO: ocean hub")
	await _sleep(1.5)
	var hub: Node = main.current
	if "_chest_lid" in hub and is_instance_valid(hub._chest_lid):
		await _tap(hub._chest_lid.get_parent().position + Vector2(0, 20), 1.5)

	# 4) besplatna igra — ORKESTAR je četvrta kapija (bez katanca)
	var gates := _children_of_type(hub, "TapButton")
	await _tap(_at(gates, 3, Vector2(_vs().x * 0.726, _vs().y * 0.170)), 1.4)

	# 5) sviranje: svaki tap je jedan ton, visina tona je visina stuba
	print("DEMO: orchestra")
	var band: Array = main.current._players if "_players" in main.current else []
	for idx in MELODY:
		if idx >= band.size():
			continue
		var musician: Node2D = band[idx].node
		await _tap(musician.position + Vector2(0, -10), 0.22)

	# 6) prst izađe iz kadra, poslednje note otplivaju gore
	await _slide_out()
	await _sleep(1.6)
	print("DEMO DONE")
	main.get_tree().quit()


## Kratki obilazak za 12-sekundni Short (Ognjen 05.09.2026: "uđi u svaku igru
## da se vidi hub", bez splash-a). Svetovi se menjaju direktnim rezom
## (main.goto), prst tapka po jednu stvar u svakom hubu, pa na lavi postavi
## tri kamena i dinosaurus pređe. Ukupno ~10 s igre.
func run_tour() -> void:
	main.get_tree().create_timer(60.0).timeout.connect(func() -> void:
		printerr("DEMO TIMEOUT")
		main.get_tree().quit(3))
	seed(20260905)
	_build_hand()

	print("DEMO: worlds")
	main.goto("worlds")
	await _move_to(Vector2(_vs().x * 0.5, _vs().y * 0.82))
	await _sleep(0.15)
	var cards := _children_of_type(main.current, "Area2D")
	await _tap(_at(cards, 0, Vector2(_vs().x * 0.14, _vs().y * 0.50)), 0.3)

	# farma: tap na životinju (krava je prva u listi)
	print("DEMO: farm")
	await _sleep(0.3)
	var farm: Node = main.current
	var animals: Array = farm.animal_nodes if "animal_nodes" in farm else []
	await _tap(_at(animals, 0, Vector2(_vs().x * 0.30, _vs().y * 0.70)) + Vector2(0, -20), 0.5)

	print("DEMO: jungle")
	main.goto("jungle")
	await _sleep(0.4)
	var jungle: Node = main.current
	var janimals: Array = jungle.animal_nodes if "animal_nodes" in jungle else []
	await _tap(_at(janimals, 0, Vector2(_vs().x * 0.30, _vs().y * 0.70)) + Vector2(0, -20), 0.5)

	print("DEMO: ocean")
	main.goto("ocean")
	await _sleep(0.4)
	var ocean: Node = main.current
	if "_chest_lid" in ocean and is_instance_valid(ocean._chest_lid):
		await _tap(ocean._chest_lid.get_parent().position + Vector2(0, 20), 0.5)
	else:
		await _sleep(1.2)

	print("DEMO: dino")
	main.goto("dino")
	await _sleep(0.3)
	var dino: Node = main.current
	if "_dino_area" in dino and is_instance_valid(dino._dino_area):
		await _tap(dino._dino_area.position, 0.4)
	else:
		await _sleep(1.0)

	print("DEMO: lava")
	main.goto("lava")
	await _sleep(0.25)
	var lava: Node = main.current
	var slots: Array = lava._slots if "_slots" in lava else []
	for i in slots.size():
		await _tap(slots[i].pos, 0.05)
	await _slide_out()
	await _sleep(3.0)
	print("DEMO DONE")
	main.get_tree().quit()


# ------------------------------------------------------------------ prst

func _build_hand() -> void:
	layer = CanvasLayer.new()
	layer.layer = 128  # iznad svega, i iznad konfeta (z_index 100)
	main.add_child(layer)
	hand = Node2D.new()
	hand.position = Vector2(_vs().x * 0.5, _vs().y + 200.0)
	layer.add_child(hand)
	# Meka bela tačka sa tamnim oreolom — čita se i na svetlom nebu farme i na
	# tamnoj vodi okeana.
	UI.circle(hand, Vector2.ZERO, R + 12.0, Color(0.05, 0.09, 0.13, 0.18))
	UI.circle(hand, Vector2.ZERO, R, Color(1, 1, 1, 0.32))
	UI.circle(hand, Vector2.ZERO, R * 0.68, Color(1, 1, 1, 0.55))
	UI.circle(hand, Vector2.ZERO, R * 0.38, Color(1, 1, 1, 0.95))


## Talas koji se širi sa mesta dodira — bez njega se na 60 fps ne vidi ŠTA je
## tapnuto, samo da je prst poskočio.
func _ripple(pos: Vector2) -> void:
	var pts := UI.circle_points(R, 48)
	pts.append(pts[0])
	var ring := Line2D.new()
	ring.points = pts
	ring.width = 7.0
	ring.default_color = Color(1, 1, 1, 0.9)
	ring.position = pos
	layer.add_child(ring)
	var tw := ring.create_tween()
	tw.tween_property(ring, "scale", Vector2.ONE * 2.6, 0.55).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(ring, "modulate:a", 0.0, 0.55)
	tw.tween_callback(ring.queue_free)


func _move_to(pos: Vector2) -> void:
	var dur := clampf(0.18 + hand.position.distance_to(pos) / 2600.0, 0.24, 0.62)
	var tw := hand.create_tween()
	tw.tween_property(hand, "position", pos, dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	await tw.finished


## Odlazak do mete, pritisak (pravi InputEvent) i pauza da se vidi posledica.
func _tap(pos: Vector2, settle := 0.4) -> void:
	await _move_to(pos)
	var tw := hand.create_tween()
	tw.tween_property(hand, "scale", Vector2.ONE * 0.72, 0.07).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(hand, "scale", Vector2.ONE, 0.18).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_ripple(pos)
	_click(pos, true)
	await _sleep(0.08)
	_click(pos, false)
	await _sleep(settle)


func _slide_out() -> void:
	var tw := hand.create_tween()
	tw.tween_property(hand, "position", Vector2(hand.position.x, _vs().y + 220.0), 0.5).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	await tw.finished


## `push_input` sa lokalnim koordinatama zaobilazi stretch transformaciju —
## demo računa u dizajnerskim koordinatama bez obzira na veličinu prozora.
func _click(pos: Vector2, pressed: bool) -> void:
	var ev := InputEventMouseButton.new()
	ev.button_index = MOUSE_BUTTON_LEFT
	ev.pressed = pressed
	ev.position = pos
	ev.global_position = pos
	main.get_viewport().push_input(ev, true)


# -------------------------------------------------------------- pomoćnici

func _sleep(sec: float) -> void:
	await main.get_tree().create_timer(sec).timeout


func _vs() -> Vector2:
	return main.get_viewport_rect().size


func _children_of_type(node: Node, type_name: String) -> Array:
	return node.get_children().filter(func(c: Node) -> bool: return c.is_class(type_name) or (c.get_script() != null and c.get_script().get_global_name() == type_name))


## Pozicija i-tog čvora, sa rezervnom koordinatom ako se raspored promenio.
func _at(nodes: Array, i: int, fallback: Vector2) -> Vector2:
	if i < nodes.size() and nodes[i] is Node2D:
		return (nodes[i] as Node2D).position
	printerr("DEMO: nema čvora %d, koristim rezervnu poziciju" % i)
	return fallback
