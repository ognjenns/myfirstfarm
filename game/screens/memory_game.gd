extends BaseScreen
## Mini-igra: MEMORIJA (džungla). Karte sa licima životinja, poleđina sa listom.
## Progresija bez teksta: 2 para → 2 para → 3 para → ... Bez kazne, bez tajmera.
## PRIVREMENO koristi farm lica dok ne stigne džungla-art (ista mehanika).

const CARD_W := 300.0
const CARD_H := 380.0

var round_num := 0
var cards: Array[Area2D] = []
var first_pick: Area2D = null
var busy := false  # zaključan unos dok se karte vraćaju/slave
var pairs_left := 0

func _ready() -> void:
	home_target = "jungle"
	var s := UI.vs(self)
	Scenery.background(self, "background-memory")
	# list-tepih na kom leže karte
	Scenery.svg(self, "leaf-mat", Vector2(s.x * 0.5, s.y * 0.55), (s.x * 0.60) / 1700.0, -20)
	add_home_button()
	add_hint(6.0)
	_start_round()

func _pairs_count() -> int:
	return clampi(2 + round_num / 2, 2, 3)

func _start_round() -> void:
	for c in cards:
		c.queue_free()
	cards.clear()
	first_pick = null
	busy = false

	var s := UI.vs(self)
	var n_pairs := _pairs_count()
	pairs_left = n_pairs
	var chosen := Animals.random_set(n_pairs, Animals.JUNGLE)
	var deck: Array = []
	for a in chosen:
		deck.append(a)
		deck.append(a)
	deck.shuffle()

	# raspored: 4 karte → 2×2, 6 karata → 3×2
	var cols := 2 if deck.size() == 4 else 3
	var card_scale := (s.y * 0.30) / CARD_H
	var gap_x := CARD_W * card_scale * 1.30
	var gap_y := CARD_H * card_scale * 1.18
	for i in deck.size():
		var col := i % cols
		var row := i / cols
		var pos := Vector2(
			s.x / 2 + (col - (cols - 1) / 2.0) * gap_x,
			s.y * 0.55 + (row - 0.5) * gap_y
		)
		var card := _make_card(deck[i], pos, card_scale)
		add_child(card)
		cards.append(card)

func _make_card(animal: Dictionary, pos: Vector2, card_scale: float) -> Area2D:
	var card := Area2D.new()
	card.position = pos
	card.scale = Vector2.ONE * card_scale
	card.set_meta("animal", animal)
	card.set_meta("revealed", false)
	card.set_meta("matched", false)
	card.set_meta("base_scale", card_scale)  # prava širina — flip se UVEK vraća na ovo

	# poleđina: dizajnerska karta sa listom (card-back.svg, 360×440)
	var back := Node2D.new()
	back.name = "Back"
	var back_spr := Sprite2D.new()
	back_spr.texture = load("res://art/svg/card-back.svg")
	back_spr.scale = Vector2(CARD_W / 360.0, CARD_H / 440.0)
	back.add_child(back_spr)
	card.add_child(back)

	# lice: dizajnerska karta (card-front.svg) sa životinjom
	var front := Node2D.new()
	front.name = "Front"
	front.visible = false
	var front_spr := Sprite2D.new()
	front_spr.texture = load("res://art/svg/card-front.svg")
	front_spr.scale = Vector2(CARD_W / 360.0, CARD_H / 440.0)
	front.add_child(front_spr)
	var face := AnimalFaces.build(animal.id)
	face.scale = Vector2.ONE * 0.60
	face.position = Vector2(0, 12)
	card.add_child(front)
	front.add_child(face)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(CARD_W * 1.1, CARD_H * 1.1)
	shape.shape = rect
	card.add_child(shape)

	card.input_event.connect(func(_vp: Node, event: InputEvent, _i: int) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			_on_card_tapped(card)
	)
	return card

## Prst tapne jednu zatvorenu kartu — pokazuje da se karte OKREĆU.
func hint_spot() -> Dictionary:
	if busy:
		return {}
	for c in cards:
		if is_instance_valid(c) and not c.get_meta("matched") and not c.get_meta("revealed"):
			return {"at": c.position}
	return {}


func _on_card_tapped(card: Area2D) -> void:
	if busy or card.get_meta("revealed") or card.get_meta("matched"):
		return
	Audio.play("pluck")
	_flip(card, true)
	if first_pick == null:
		first_pick = card
		return
	# drugi izbor
	busy = true
	var a: Dictionary = first_pick.get_meta("animal")
	var b: Dictionary = card.get_meta("animal")
	if a.id == b.id:
		get_tree().create_timer(0.45).timeout.connect(_match_found.bind(first_pick, card))
	else:
		get_tree().create_timer(0.9).timeout.connect(_flip_back.bind(first_pick, card))

func _match_found(c1: Area2D, c2: Area2D) -> void:
	c1.set_meta("matched", true)
	c2.set_meta("matched", true)
	first_pick = null
	busy = false
	pairs_left -= 1
	Audio.animal_voice(c1.get_meta("animal").id)
	UI.haptic(35)
	for c in [c1, c2]:
		UI.bounce(c, Vector2.ONE * float(c.get_meta("base_scale")))
		_star_pop(c.global_position)
	if pairs_left == 0:
		round_num += 1
		celebrate(UI.vs(self) / 2)
		get_tree().create_timer(1.8).timeout.connect(_start_round)

## Zvezdica iskoči i zavrti se na pogođenom paru.
func _star_pop(pos: Vector2) -> void:
	var star := Sprite2D.new()
	star.texture = load("res://art/svg/memory-star.svg")
	star.position = pos + Vector2(randf_range(-30, 30), -60)
	star.scale = Vector2.ONE * 0.1
	star.z_index = 60
	add_child(star)
	var tw := star.create_tween()
	tw.tween_property(star, "scale", Vector2.ONE * 0.55, 0.25).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(star, "rotation", randf_range(-0.4, 0.4), 0.25)
	tw.tween_interval(0.25)
	tw.tween_property(star, "modulate:a", 0.0, 0.3)
	tw.parallel().tween_property(star, "position:y", star.position.y - 60.0, 0.3)
	tw.tween_callback(star.queue_free)

func _flip_back(c1: Area2D, c2: Area2D) -> void:
	Audio.play("wrong", -8.0)
	_flip(c1, false)
	_flip(c2, false)
	first_pick = null
	busy = false

## Flip animacija: skupi po X, zameni stranu, raširi.
## Uvek se vraća na base_scale iz meta — tap usred animacije ne može da "zaglavi" kartu usku.
func _flip(card: Area2D, reveal: bool) -> void:
	card.set_meta("revealed", reveal)
	if card.has_meta("flip_tw"):
		var old: Tween = card.get_meta("flip_tw")
		if old and old.is_valid():
			old.kill()
	var base_x: float = card.get_meta("base_scale")
	var tw := card.create_tween()
	card.set_meta("flip_tw", tw)
	tw.tween_property(card, "scale:x", 0.0, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func() -> void:
		card.get_node("Back").visible = not reveal
		card.get_node("Front").visible = reveal
	)
	tw.tween_property(card, "scale:x", base_x, 0.11).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
