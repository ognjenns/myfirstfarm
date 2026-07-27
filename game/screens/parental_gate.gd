extends BaseScreen
## Parental gate u duhu igre: viseća drvena tabla sa pitanjem,
## tri okrugla dugmeta sa odgovorima. Tekst je za roditelja — OK je.

var a := 0
var b := 0

func _ready() -> void:
	ad_on_exit = false
	var s := UI.vs(self)
	Scenery.background(self, "background-parents")
	add_home_button()

	a = randi_range(11, 29)
	b = randi_range(11, 29)

	# viseća tabla sa pitanjem
	var sign_scale := (s.x * 0.42) / 900.0
	Scenery.svg(self, "sign-board", Vector2(s.x * 0.5, s.y * 0.30), sign_scale, 0)
	UI.label(self, "For parents", Vector2(s.x * 0.5, s.y * 0.10), 40, Color(0.45, 0.40, 0.36))
	UI.label(self, "What is %d + %d?" % [a, b], Vector2(s.x * 0.5, s.y * 0.34), 84)

	# tri okrugla dugmeta
	var correct := a + b
	var answers := [correct, correct + randi_range(1, 9), correct - randi_range(1, 9)]
	answers.shuffle()
	var btn_scale := (s.x * 0.095) / 256.0
	for i in answers.size():
		var val: int = answers[i]
		var btn := Area2D.new()
		btn.position = Vector2(s.x * (0.34 + 0.16 * i), s.y * 0.70)
		var spr := Sprite2D.new()
		spr.texture = load("res://art/svg/button-round.svg")
		spr.scale = Vector2.ONE * btn_scale
		btn.add_child(spr)
		UI.label(btn, str(val), Vector2(0, 0), 76)
		var shape := CollisionShape2D.new()
		var circle := CircleShape2D.new()
		circle.radius = 128.0 * btn_scale * 1.15
		shape.shape = circle
		btn.add_child(shape)
		btn.input_event.connect(func(_vp: Node, event: InputEvent, _i: int) -> void:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				Audio.play("pop")
				UI.bounce(btn, Vector2.ONE)
				if val == correct:
					go("parents")
				else:
					go("hub")
		)
		add_child(btn)
