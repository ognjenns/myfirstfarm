extends BaseScreen
## Izbor sveta (posle splash-a): dizajnerske kartice My Farm i My Jungle.

func _ready() -> void:
	var s := UI.vs(self)
	add_child(GradientBG.new(Pal.SKY_TOP, Pal.SKY_LOW))
	add_ambient(2)

	_world_card(Vector2(s.x * 0.30, s.y * 0.50), "card-farm", "My Farm", "hub", s, "cow")
	_world_card(Vector2(s.x * 0.70, s.y * 0.50), "card-jungle", "My Jungle", "jungle", s, "monkey")

func _world_card(pos: Vector2, art: String, title: String, target: String, s: Vector2, animal_id := "") -> void:
	var card := Area2D.new()
	card.position = pos
	var card_scale := (s.y * 0.62) / 600.0
	var spr := Sprite2D.new()
	spr.texture = load("res://art/svg/%s.svg" % art)
	spr.scale = Vector2.ONE * card_scale
	card.add_child(spr)
	if animal_id != "":
		var face := AnimalFaces.build(animal_id)
		face.position = Vector2(175.0, 70.0) * card_scale
		face.scale = Vector2.ONE * card_scale * 1.15
		card.add_child(face)
	UI.label(card, title, Vector2(0, 350.0 * card_scale + 40.0), 44, Color(0.32, 0.29, 0.26))

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
