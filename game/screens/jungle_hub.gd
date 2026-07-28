extends BaseScreen
## Jungle hub — pravi art (Claude Design, proporcije iz mockupa):
## pećina sa vratima i stazom su u pozadini; lijana, drvo, kamen, cveće;
## 6 životinja u dva reda; 4 kapije (memorija radi, ostale uskoro).

func _ready() -> void:
	var s := UI.vs(self)
	Scenery.background(self, "background-jungle")
	add_ambient(0, "mosquito")  # bez oblaka; komični komarac umesto leptira

	# lijana sa vrha, drvo desno, kamen dole levo
	Scenery.svg(self, "vine", Vector2(s.x * 0.516, (s.y * 0.0) + 250.0 * (s.x * 0.060) / 200.0), (s.x * 0.060) / 200.0, -20)
	Scenery.svg(self, "jungle-tree", Vector2(s.x * (1.0 - 0.034 - 0.128), s.y * 0.798 - 273.0 * (s.x * 0.256) / 600.0 + 46.0 * (s.x * 0.256) / 600.0), (s.x * 0.256) / 600.0, -25)
	Scenery.svg(self, "rock", Vector2(s.x * 0.075, s.y * 0.93), (s.x * 0.128) / 400.0, -22)
	for f in [Vector2(0.37, 0.86), Vector2(0.65, 0.90), Vector2(0.88, 0.84)]:
		Scenery.svg(self, "jungle-flower", f * s, (s.x * 0.045) / 256.0, -18)

	# životinje: raširene preko cele širine, cik-cak da se ne preklapaju
	var back := [
		{"id": "monkey", "x": 0.205, "y": 0.46, "sc": 0.112},
		{"id": "elephant", "x": 0.355, "y": 0.50, "sc": 0.125},
		{"id": "giraffe", "x": 0.525, "y": 0.46, "sc": 0.115},
		{"id": "lion", "x": 0.70, "y": 0.50, "sc": 0.126},
	]
	for a in back:
		_spawn_animal(a.id, Vector2(s.x * a.x, s.y * a.y), (s.x * a.sc) / 230.0)
	_spawn_animal("hippo", Vector2(s.x * 0.27, s.y * 0.76), (s.x * 0.110) / 230.0)
	_spawn_animal("parrot", Vector2(s.x * 0.60, s.y * 0.77), (s.x * 0.108) / 230.0)

	_build_gates(s)
	_build_worlds_button()
	_build_parent_button(s)

func _spawn_animal(id: String, pos: Vector2, sc: float) -> void:
	var a := AnimalSprite.new(Animals.by_id_jungle(id), sc)
	a.position = pos
	add_child(a)

func _build_worlds_button() -> void:
	var btn := TapButton.new(Vector2(100, 100), 62, Color(1, 1, 1, 0.85))
	UI.poly(btn, PackedVector2Array([Vector2(14, -26), Vector2(-22, 0), Vector2(14, 26)]), Color(0.45, 0.40, 0.36))
	btn.tapped.connect(func() -> void: go("worlds"))
	add_child(btn)

func _build_parent_button(s: Vector2) -> void:
	var btn := TapButton.new(Vector2(s.x - 80, s.y - 80), 48, Color(0.99, 0.98, 0.96, 0.55))
	for y in [-12, 0, 12]:
		UI.poly(btn, UI.rect_points(34, 6), Color(0.55, 0.5, 0.45), Vector2(0, y))
	btn.tapped.connect(func() -> void: go("gate"))
	add_child(btn)

func _build_gates(s: Vector2) -> void:
	var gates := [
		{"screen": "memory", "icon": "icon-memory", "ready": true},
		{"screen": "", "icon": "icon-sound-game", "ready": false},  # čeka zvuke životinja
		{"screen": "shower", "icon": "icon-elephant-shower", "ready": true},
		{"screen": "jfeed", "icon": "icon-banana", "ready": true},
	]
	for i in gates.size():
		var g: Dictionary = gates[i]
		var pos := Vector2(s.x * (0.305 + 0.13 * i), 195)
		var btn := TapButton.new(pos, 105, Pal.BUTTON_WHITE)
		Scenery.svg(btn, g.icon, Vector2.ZERO, 0.66, 0)
		if g.ready:
			var target: String = g.screen
			btn.tapped.connect(func() -> void: go(target))
			btn.start_pulse()
		else:
			btn.tapped.connect(func() -> void: UI.head_shake(btn))  # uskoro
		add_child(btn)
