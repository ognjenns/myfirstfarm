extends BaseScreen
## Izbor sveta (posle splash-a): dizajnerske kartice My Farm i My Jungle.

func _ready() -> void:
	var s := UI.vs(self)
	add_child(GradientBG.new(Pal.SKY_TOP, Pal.SKY_LOW))
	add_ambient(2)

	# Pet svetova u DVA REDA (Ognjen 05.09.2026: pet u nizu je bilo sitno):
	# tri gore, dva dole, poravnati na prazna mesta gornjeg reda.
	_world_card(Vector2(s.x * 0.22, s.y * 0.245), "card-farm", "title-farm", "hub", s, "cow")
	_world_card(Vector2(s.x * 0.50, s.y * 0.245), "card-jungle", "title-jungle", "jungle", s, "monkey")
	_world_card(Vector2(s.x * 0.78, s.y * 0.245), "card-ocean", "title-ocean", "ocean", s, "fish")
	_world_card(Vector2(s.x * 0.36, s.y * 0.715), "card-dino", "title-dino", "dino", s)
	_world_card(Vector2(s.x * 0.64, s.y * 0.715), "card-polar", "title-arctic", "polar", s)
	add_hint(6.0)

var _card_spots: Array[Vector2] = []


## Tri kartice ništa ne rade same od sebe — prst pokaže da se u svet ULAZI.
func hint_spot() -> Dictionary:
	if _card_spots.is_empty():
		return {}
	return {"at": _card_spots[randi() % _card_spots.size()], "size": 2.2}


## Kartica sveta od naših crteža (04.09.2026): daska sa debelom konturom kao
## karte memorije, u njoj "prozor" sa isečkom kupljene pozadine tog sveta i
## životinja celim telom (okean: ronilac, dino: brontosaurus).
const INK := Color("#2B1A0E")
## "sprite" = gotova sličica (ronilac, T-rex) kad životinja nije u FarmBody.
const PICTURES := {
	"card-farm":   {"tex": "res://art/farm/bg-road.png", "cx": 0.50, "cy": 0.52, "w": 0.50},
	"card-jungle": {"tex": "res://art/jungle/bg.png", "cx": 0.50, "cy": 0.50, "w": 0.50},
	"card-ocean":  {"tex": "res://art/ocean/scene.png", "cx": 0.50, "cy": 0.58, "w": 0.55,
		"sprite": "res://art/ocean/diver-1.png", "sw": 300.0, "spos": Vector2(120, 10)},
	"card-dino":   {"tex": "res://art/dino/bg-scene.png", "cx": 0.50, "cy": 0.55, "w": 0.55,
		"sprite": "res://art/dino/bi-1.png", "sw": 360.0, "spos": Vector2(110, 40)},
	"card-polar":  {"tex": "res://art/polar/bg-scene.png", "cx": 0.50, "cy": 0.50, "w": 0.55,
		"sprite": "res://art/polar/penguin-idle-1.png", "sw": 300.0, "spos": Vector2(120, 30)},
}

func _world_card(pos: Vector2, art: String, title: String, target: String, s: Vector2, animal_id := "") -> void:
	var card := Area2D.new()
	card.position = pos
	_card_spots.append(pos)
	# ograniči i po širini da se kartice ne preklope na tabletu (4:3)
	# dva reda: visina reda je 0.32 ekrana (kartica + naslov ispod), po širini
	# tri kartice u redu
	var card_scale := minf((s.y * 0.32) / 600.0, (s.x * 0.22) / 700.0)
	var body := Node2D.new()
	body.scale = Vector2.ONE * card_scale
	card.add_child(body)
	if PICTURES.has(art):
		_board(body, art, animal_id)
	else:
		var spr := Sprite2D.new()
		spr.texture = load("res://art/svg/%s.svg" % art)
		body.add_child(spr)
	# Naslov je crtež, ne tekst: natpisi nose stil igre umesto podrazumevanog
	# font-a engine-a. `title` je ime SVG fajla; prazan = kartica još nema naslov.
	if title != "":
		_card_title(card, title, card_scale)
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
			# kratak pritisak (kao dugme), ne skok koji ostane "savijen" kad
			# se ekran promeni usred njega
			var tw := card.create_tween()
			tw.tween_property(card, "scale", Vector2.ONE * 0.94, 0.07).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			tw.tween_property(card, "scale", Vector2.ONE, 0.09).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
			get_tree().create_timer(0.2).timeout.connect(func() -> void: go(target))
	)


## Daska 700×600: senka, kontura, svetla ispuna, prozor sa slikom, životinja.
func _board(parent: Node2D, art: String, animal_id: String) -> void:
	UI.poly(parent, UI.rounded_rect_points(720, 620, 60), Color(0, 0, 0, 0.20), Vector2(0, 16))
	UI.poly(parent, UI.rounded_rect_points(720, 620, 60), INK)
	UI.poly(parent, UI.rounded_rect_points(700, 600, 52), Color("#F6E9CC"))
	UI.poly(parent, UI.rounded_rect_points(646, 470, 40), INK, Vector2(0, -40))
	var pic: Dictionary = PICTURES[art]
	var win := Polygon2D.new()
	var ww := 630.0
	var wh := 454.0
	win.polygon = UI.rounded_rect_points(ww, wh, 34)
	win.position = Vector2(0, -40)
	win.texture = load(pic.tex)
	var ts: Vector2 = win.texture.get_size()
	var cw: float = ts.x * float(pic.w)
	var ch: float = cw * wh / ww
	var cx: float = ts.x * float(pic.cx) - cw / 2.0
	var cy: float = clampf(ts.y * float(pic.cy) - ch / 2.0, 0.0, ts.y - ch)
	var uvs := PackedVector2Array()
	for v in win.polygon:
		uvs.append(Vector2(cx + (v.x + ww / 2.0) / ww * cw, cy + (v.y + wh / 2.0) / wh * ch))
	win.uv = uvs
	parent.add_child(win)
	# životinja u prozoru, uz donju ivicu
	if pic.has("sprite"):
		var f := Sprite2D.new()
		f.texture = load(pic.sprite)
		f.scale = Vector2.ONE * (float(pic.sw) / f.texture.get_size().x)
		f.position = pic.spos
		parent.add_child(f)
	elif animal_id != "":
		var a := FarmBody.portrait(animal_id, 270.0)
		a.position = Vector2(150, 60)
		parent.add_child(a)
	if art == "card-jungle":
		var vine := Sprite2D.new()
		vine.texture = load("res://art/jungle/vine-hang.png")
		var vs := vine.texture.get_size()
		vine.scale = Vector2(60.0 / vs.x, 250.0 / vs.y)
		vine.position = Vector2(-180, -142)
		parent.add_child(vine)


func _card_title(card: Node2D, title: String, card_scale: float) -> void:
	var t := Sprite2D.new()
	t.texture = load("res://art/svg/%s.svg" % title)
	t.scale = Vector2.ONE * ((640.0 * card_scale) / t.texture.get_size().x)
	t.position = Vector2(0, 350.0 * card_scale + 52.0)
	card.add_child(t)
