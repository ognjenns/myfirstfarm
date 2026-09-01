extends BaseScreen
## Izbor sveta (posle splash-a): dizajnerske kartice My Farm i My Jungle.

func _ready() -> void:
	var s := UI.vs(self)
	add_child(GradientBG.new(Pal.SKY_TOP, Pal.SKY_LOW))
	add_ambient(2)

	_world_card(Vector2(s.x * 0.20, s.y * 0.50), "card-farm", "title-farm", "hub", s, "cow")
	_world_card(Vector2(s.x * 0.50, s.y * 0.50), "card-jungle", "title-jungle", "jungle", s, "monkey")
	_world_card(Vector2(s.x * 0.80, s.y * 0.50), "card-ocean", "title-ocean", "ocean", s, "fish")
	add_hint(6.0)

var _card_spots: Array[Vector2] = []


## Tri kartice ništa ne rade same od sebe — prst pokaže da se u svet ULAZI.
func hint_spot() -> Dictionary:
	if _card_spots.is_empty():
		return {}
	return {"at": _card_spots[randi() % _card_spots.size()], "size": 2.2}


func _world_card(pos: Vector2, art: String, title: String, target: String, s: Vector2, animal_id := "") -> void:
	var card := Area2D.new()
	card.position = pos
	_card_spots.append(pos)
	# ograniči i po širini da se kartice ne preklope na tabletu (4:3)
	var card_scale := minf((s.y * 0.62) / 600.0, (s.x * 0.270) / 700.0)
	var spr := Sprite2D.new()
	spr.texture = load("res://art/svg/%s.svg" % art)
	spr.scale = Vector2.ONE * card_scale
	card.add_child(spr)
	if animal_id != "":
		var face := AnimalFaces.build(animal_id)
		face.position = Vector2(175.0, 70.0) * card_scale
		face.scale = Vector2.ONE * card_scale * 1.15
		card.add_child(face)
	# Naslov je crtež, ne tekst: u igri postoje samo tri natpisa, pa nose stil
	# igre umesto podrazumevanog font-a engine-a. `title` je ime SVG fajla.
	var t := Sprite2D.new()
	t.texture = load("res://art/svg/%s.svg" % title)
	t.scale = Vector2.ONE * ((640.0 * card_scale) / t.texture.get_size().x)
	t.position = Vector2(0, 350.0 * card_scale + 52.0)
	card.add_child(t)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(700.0, 600.0) * card_scale * 1.08
	shape.shape = rect
	card.add_child(shape)
	add_child(card)

	card.input_event.connect(func(_vp: Node, event: InputEvent, _i: int) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			Audio.play("pop")
			UI.haptic(25)
			UI.bounce(card, Vector2.ONE)
			get_tree().create_timer(0.18).timeout.connect(func() -> void: go(target))
	)
