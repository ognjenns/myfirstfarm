class_name Autotest
extends RefCounted
## Automatski "odigra" svaku mini-igru pozivajući njihovu logiku direktno.
## Pokretanje: godot --headless --path . -- --autotest

var main: Node2D
var failed := false

func _init(main_node: Node2D) -> void:
	main = main_node

func _frames(n: int) -> void:
	for i in n:
		await main.get_tree().process_frame

func _sleep(sec: float) -> void:
	await main.get_tree().create_timer(sec).timeout

func check(cond: bool, what: String) -> void:
	if cond:
		print("AUTOTEST OK: ", what)
	else:
		failed = true
		printerr("AUTOTEST FAIL: ", what)

func _test_memory() -> void:
	main.goto("memory")
	await _frames(5)
	var g: Node = main.current
	check(g.cards.size() == 4, "memory: prva runda ima 4 karte")
	# nađi par i promašaj
	var by_id := {}
	for c in g.cards:
		var id: String = c.get_meta("animal").id
		if not by_id.has(id):
			by_id[id] = []
		by_id[id].append(c)
	var ids := by_id.keys()
	# promašaj: karta prve i karta druge životinje
	g._on_card_tapped(by_id[ids[0]][0])
	g._on_card_tapped(by_id[ids[1]][0])
	await _sleep(1.2)
	check(not by_id[ids[0]][0].get_meta("revealed"), "memory: promašene karte se vraćaju")
	# pogodi oba para
	for id in ids:
		g._on_card_tapped(by_id[id][0])
		g._on_card_tapped(by_id[id][1])
		await _sleep(0.7)
		check(by_id[id][0].get_meta("matched"), "memory: par %s spojen" % id)
	check(g.pairs_left == 0, "memory: runda kompletna")
	check(g.round_num == 1, "memory: prešlo na sledeću rundu")
	await _sleep(2.0)

func _test_shower() -> void:
	main.goto("shower")
	await _frames(5)
	var g: Node = main.current
	check(not g.mud_blobs.is_empty(), "shower: životinja je blatnjava na startu")
	var first_id: String = g.bather.animal.id
	check(first_id != "elephant", "shower: slon ne kupa sam sebe")
	for i in 5:
		g._spray()
		await _sleep(0.6)
	check(g.mud_blobs.is_empty() or g._busy, "shower: blato oprano posle prskanja")
	await _sleep(2.6)
	check(not g.mud_blobs.is_empty(), "shower: sledeća životinja stigla blatnjava")

func run() -> void:
	# failsafe: ako bilo šta zaglavi, ugasi se posle 90s sa greškom
	main.get_tree().create_timer(90.0).timeout.connect(func() -> void:
		printerr("AUTOTEST TIMEOUT")
		main.get_tree().quit(3)
	)
	await _test_feed()
	await _test_shadows()
	await _test_bath()
	await _test_hideseek()
	await _test_memory()
	await _test_shower()
	if failed:
		printerr("AUTOTEST: NEUSPEH")
		main.get_tree().quit(1)
	else:
		print("AUTOTEST: SVE PROSLO")
		main.get_tree().quit(0)

func _foods_of(node: Node) -> Array:
	return node.get_children().filter(func(c): return c is FoodItem)

func _test_feed() -> void:
	main.goto("feed")
	await _frames(5)
	var g: Node = main.current
	for round_i in 4:
		var expected_round: int = g.round_num
		var animals: Array = g.animals_on_screen.duplicate()
		check(animals.size() == clampi(2 + expected_round / 3, 2, 4), "feed: broj životinja u rundi %d" % expected_round)
		# prvo namerno promaši: prva hrana u pogrešnu činiju
		var foods := _foods_of(g)
		if animals.size() >= 2:
			var wrong_target: Node = null
			for a in animals:
				if a.animal.food != foods[0].kind:
					wrong_target = a
					break
			foods[0].global_position = g.plates[wrong_target.animal.id].global_position
			g._on_food_dropped(foods[0])
			check(is_instance_valid(foods[0]), "feed: promašaj ne uništava hranu")
		# pa nahrani sve (svaka hrana u svoju činiju)
		for a in animals:
			for f in _foods_of(g):
				if f.kind == a.animal.food:
					f.global_position = g.plates[a.animal.id].global_position
					g._on_food_dropped(f)
					break
		check(g.foods_left == 0, "feed: sve nahranjeno u rundi %d" % expected_round)
		check(g.round_num == expected_round + 1, "feed: runda prešla na %d" % (expected_round + 1))
		await _sleep(2.2)  # konfete + nova runda

func _test_shadows() -> void:
	main.goto("shadows")
	await _frames(5)
	var g: Node = main.current
	for scene_i in 2:
		var expected_scene: int = g.scene_idx
		var drags: Array = g.get_children().filter(func(c): return c.get_script() != null and "solved" in c and "animal" in c)
		check(drags.size() >= 3, "shadows: scena %d ima %d životinja" % [expected_scene, drags.size()])
		# promašaj: spusti prvu na pogrešno mesto
		drags[0].global_position = Vector2(100, 100)
		g._on_dropped(drags[0])
		check(not drags[0].solved, "shadows: promašaj se ne računa")
		await _sleep(0.4)
		for d in drags:
			var sh: Node2D = g.shadows[d.animal.id]
			d.global_position = sh.global_position
			g._on_dropped(d)
			check(d.solved, "shadows: %s legla na senku" % d.animal.id)
		check(g.remaining == 0, "shadows: scena %d kompletna" % expected_scene)
		check(g.scene_idx == expected_scene + 1, "shadows: prešlo na scenu %d" % (expected_scene + 1))
		await _sleep(2.3)

func _test_bath() -> void:
	main.goto("bath")
	await _frames(5)
	var g: Node = main.current
	check(g.phase == g.Phase.MUD, "bath: kreće od blata")
	for blob in g.mud_blobs.duplicate():
		if g.phase != g.Phase.MUD:
			break  # blato već očišćeno usput (blobovi se preklapaju)
		for i in 10:
			g._rub(blob.position)
	check(g.mud_blobs.is_empty(), "bath: blato očišćeno")
	check(g.phase == g.Phase.FOAM, "bath: prešlo na penu")
	for i in 80:
		g._rub(g.pig_pos + Vector2(randf_range(-100, 100), randf_range(-100, 100)))
	check(g.phase == g.Phase.SHOWER, "bath: prešlo na tuširanje")
	await _sleep(2.2)
	check(g.phase == g.Phase.HAPPY, "bath: prase srećno")
	await _sleep(2.5)
	check(g.phase == g.Phase.MUD and not g.mud_blobs.is_empty(), "bath: novi krug (blato se vratilo)")

func _test_hideseek() -> void:
	main.goto("hideseek")
	await _frames(5)
	var g: Node = main.current
	await _sleep(2.2)  # intro + trčanje iza objekta
	check(g.accepting_taps, "hideseek: prima tapove posle sakrivanja")
	var first_animal: String = g.animal_node.animal.id
	# promašaj
	var wrong_idx: int = (g.hiding_idx + 1) % 3
	g._on_spot_tapped(wrong_idx)
	check(g.accepting_taps, "hideseek: promašaj ne prekida rundu")
	# pogodak
	g._on_spot_tapped(g.hiding_idx)
	check(not g.accepting_taps, "hideseek: pogodak registrovan")
	await _sleep(2.6)  # iskakanje + konfete + nova runda
	await _sleep(2.2)  # intro nove runde
	check(g.accepting_taps, "hideseek: nova runda krenula (bila: %s, sad: %s)" % [first_animal, g.animal_node.animal.id])
