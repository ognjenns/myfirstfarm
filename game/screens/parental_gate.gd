extends BaseScreen
## Parental gate — matematičko pitanje pre roditeljskog ugla.
## Tekst je OK ovde: namenjen je roditelju, ne detetu.

var a := 0
var b := 0

func _ready() -> void:
	ad_on_exit = false
	add_child(GradientBG.new(Color("#f2f2f2"), Color("#e0e0e0")))
	add_home_button()

	var s := UI.vs(self)
	a = randi_range(11, 29)
	b = randi_range(11, 29)
	UI.label(self, "Za roditelje", Vector2(s.x / 2, 220), 56, Color(0.45, 0.45, 0.45))
	UI.label(self, "Koliko je %d + %d?" % [a, b], Vector2(s.x / 2, 380), 96)

	var correct := a + b
	var answers := [correct, correct + randi_range(1, 9), correct - randi_range(1, 9)]
	answers.shuffle()
	for i in answers.size():
		var val: int = answers[i]
		var btn := TapButton.new(Vector2(s.x / 2 + (i - 1) * 420, 680), 130, Color.WHITE)
		UI.label(btn, str(val), Vector2.ZERO, 84)
		btn.tapped.connect(func() -> void:
			if val == correct:
				go("parents")
			else:
				go("hub")
		)
		add_child(btn)
