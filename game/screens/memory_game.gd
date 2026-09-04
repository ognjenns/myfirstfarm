extends BaseScreen
## Mini-igra: MEMORIJA (džungla). Karte sa licima životinja, poleđina sa listom.
## Progresija bez teksta: 2, 2, 3, 3, 4, 4, pa 5 pari nadalje (Ognjen,
## 04.09.2026). Bez kazne, bez tajmera.
## Na kartama su životinje iz kupljenih paketa (lav još naša glava).

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
	_build_scene(s)
	add_home_button()
	add_hint(6.0)
	_start_round()

## "Stari hram" — svaka igra ima svoj kutak džungle, da ne liči na hub:
## gušća senka šume, uvijene lijane sa vrha, dva kamena totema koji vire
## iza karata, palme, kamenje i lišće dole. Bez smeđe trake tla.
func _build_scene(s: Vector2) -> void:
	var bg := Sprite2D.new()
	bg.texture = load("res://art/jungle/bg-deep.png")
	var bt := bg.texture.get_size()
	var sc: float = maxf(s.y / bt.y, s.x / bt.x)
	bg.scale = Vector2(sc, sc)
	bg.position = s / 2.0
	bg.z_index = -60
	add_child(bg)
	# lijane sa vrha uz ivice
	JungleScene.place(self, "vines-top", Vector2(0.05, -0.02), 0.70, true, -40, Vector2(0.5, 0.0))
	JungleScene.place(self, "vines-top", Vector2(0.95, -0.02), 0.60, true, -40, Vector2(0.5, 0.0), true)
	JungleScene.place(self, "vine-hang", Vector2(0.30, -0.01), 0.24, true, -41, Vector2(0.5, 0.0))
	JungleScene.place(self, "vine-hang-long", Vector2(0.72, -0.01), 0.30, true, -41, Vector2(0.5, 0.0), true)
	# palme iza totema
	JungleScene.place(self, "palm-trunk", Vector2(0.15, 0.92), 0.55, true, -38)
	JungleScene.place(self, "palm-leaves", Vector2(0.155, 0.40), 0.15, false, -37, Vector2(0.5, 0.55))
	JungleScene.place(self, "palm-trunk", Vector2(0.86, 0.94), 0.50, true, -38, Vector2(0.5, 1.0), true)
	JungleScene.place(self, "palm-leaves", Vector2(0.855, 0.47), 0.14, false, -37, Vector2(0.5, 0.55), true)
	# totemi: mirni levo, namršteni desno — vire iza karata
	JungleScene.place(self, "rock-head", Vector2(0.09, 0.98), 0.52, true, -30)
	JungleScene.place(self, "rock-head-2", Vector2(0.92, 0.98), 0.46, true, -30)
	# kamenje, lišće i busenje uz donju ivicu, ispred karata
	JungleScene.place(self, "rock-3", Vector2(0.24, 1.02), 0.13, false, 12)
	JungleScene.place(self, "rock-1", Vector2(0.77, 1.02), 0.06, false, 12)
	JungleScene.place(self, "grass-drape", Vector2(0.25, 0.92), 0.05, false, 13, Vector2(0.5, 0.0))
	JungleScene.place(self, "ground-leaves", Vector2(0.50, 1.02), 0.12, false, 12)
	JungleScene.place(self, "tuft-3", Vector2(0.37, 1.01), 0.07, false, 12)
	JungleScene.place(self, "tuft-3", Vector2(0.63, 1.01), 0.07, false, 12, Vector2(0.5, 1.0), true)
	JungleScene.place(self, "grass-top", Vector2(0.10, 1.0), 0.08, false, 12)
	JungleScene.place(self, "grass-top", Vector2(0.90, 1.0), 0.08, false, 12, Vector2(0.5, 1.0), true)
	JungleScene.place(self, "stump", Vector2(0.70, 1.0), 0.05, false, 12)

func _pairs_count() -> int:
	return clampi(2 + round_num / 2, 2, 5)

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

	# raspored: uvek dva reda — 4 karte → 2×2, 6 → 3×2, 8 → 4×2, 10 → 5×2.
	# Karta je po visini; kad pet kolona ne staje po širini (tablet 4:3),
	# smanji se toliko da stane.
	var cols := deck.size() / 2
	var card_scale := minf((s.y * 0.30) / CARD_H, (s.x * 0.94) / (cols * CARD_W * 1.30))
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

	# Karte u stilu paketa (debela tamna kontura, kao crteži životinja):
	# poleđina drvena sa pravim listom iz paketa, lice svetlo sa životinjom.
	var back := Node2D.new()
	back.name = "Back"
	_card_board(back, Color("#B97A34"), Color("#D3964C"))
	var leaf := Sprite2D.new()
	leaf.texture = load("res://art/jungle/leaf-1.png")
	leaf.scale = Vector2.ONE * ((CARD_H * 0.58) / leaf.texture.get_size().y)
	leaf.rotation = -0.35
	leaf.position = Vector2(0, 8)
	back.add_child(leaf)
	card.add_child(back)

	var front := Node2D.new()
	front.name = "Front"
	front.visible = false
	_card_board(front, Color("#F6E9CC"), Color("#FFF7E4"))
	var face := FarmBody.portrait(animal.id, CARD_H * 0.60)
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

## Daska karte: senka ispod, debela tamna kontura, ispuna i svetliji unutrašnji
## okvir — isti "jezik" kao kupljeni crteži (kontura ~10 px na 300 px karte).
func _card_board(parent: Node2D, fill: Color, inner: Color) -> void:
	UI.poly(parent, UI.rounded_rect_points(CARD_W + 22, CARD_H + 22, 44), Color(0, 0, 0, 0.22), Vector2(0, 14))
	UI.poly(parent, UI.rounded_rect_points(CARD_W + 22, CARD_H + 22, 44), Color("#2B1A0E"))
	UI.poly(parent, UI.rounded_rect_points(CARD_W, CARD_H, 36), fill)
	UI.poly(parent, UI.rounded_rect_points(CARD_W - 40, CARD_H - 40, 26), inner)
	UI.poly(parent, UI.rounded_rect_points(CARD_W - 52, CARD_H - 52, 22), fill)

## Prst tapne jednu zatvorenu kartu — pokazuje da se karte OKREĆU.
func hint_spot() -> Dictionary:
	if busy:
		return {}
	for c in cards:
		if is_instance_valid(c) and not c.get_meta("matched") and not c.get_meta("revealed"):
			return {"at": c.position}
	return {}


func _on_card_tapped(card: Area2D) -> void:
	if busy or card.get_meta("matched"):
		return
	# Prva otvorena karta se na ponovni tap ZATVARA (toggle) — dete sme da se
	# predomisli, i ne ostaje "zaglavljena" otvorena dok ne tapne drugu.
	if card.get_meta("revealed"):
		if card == first_pick:
			Audio.play("pluck", -4.0)
			_flip(card, false)
			first_pick = null
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
		# bez konfeta: dečji glas + bljesak na svakoj karti (Ognjen, 04.09.2026)
		Audio.play(["yay", "giggle", "kid"][randi() % 3], -2.0)
		for c in cards:
			if is_instance_valid(c):
				glow(c.position, CARD_H * float(c.get_meta("base_scale")) * 1.3)
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
