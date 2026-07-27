class_name Scenery
## Scenografija — SVG asseti iz Claude Design-a + par pomoćnih crtanih formi
## (brda i senke koje se koriste u mini-igrama).

static func svg(parent: Node, name: String, pos: Vector2, s := 1.0, z := -30) -> Sprite2D:
	var sp := Sprite2D.new()
	sp.texture = load("res://art/svg/%s.svg" % name)
	sp.position = pos
	sp.scale = Vector2.ONE * s
	sp.z_index = z
	parent.add_child(sp)
	return sp

## Pozadina cele scene (nebo + brda), razvučena na viewport.
static func background(parent: CanvasItem, name := "background") -> void:
	var size := UI.vs(parent)
	var sp := Sprite2D.new()
	sp.texture = load("res://art/svg/%s.svg" % name)
	sp.position = size / 2
	sp.scale = Vector2(size.x / 2340.0, size.y / 1080.0)
	sp.z_index = -50
	parent.add_child(sp)

static func sun(parent: Node, pos: Vector2, z := -35) -> void:
	svg(parent, "sun", pos, 0.8, z)

static func cloud(parent: Node, pos: Vector2, s := 1.0, z := -35) -> void:
	var c := DriftCloud.new()
	c.texture = load("res://art/svg/cloud.svg")
	c.position = pos
	c.scale = Vector2.ONE * (s * 0.75)
	c.z_index = z
	parent.add_child(c)

static func farmhouse(parent: Node, pos: Vector2, z := -30) -> void:
	svg(parent, "farmhouse", pos, 1.0, z)

static func silo(parent: Node, pos: Vector2, z := -31) -> void:
	svg(parent, "silo", pos, 1.0, z)

static func path_way(parent: Node, pos: Vector2, z := -32) -> void:
	svg(parent, "path", pos, 1.0, z)

## Ograda kao celina: dve neprekidne šine + stubići (boje iz fence.svg).
static func fence(parent: Node, pos: Vector2, posts := 5, z := -28) -> void:
	var f := Node2D.new()
	f.position = pos
	f.z_index = z
	parent.add_child(f)
	var spacing := 96.0
	var w := spacing * (posts - 1) + 28.0
	for y in [-14.0, 30.0]:
		UI.poly(f, UI.rounded_rect_points(w + 36.0, 20.0, 10.0), Color("#E8DABF"), Vector2(0, y))
	for i in posts:
		UI.poly(f, UI.rounded_rect_points(28.0, 112.0, 14.0), Color("#EFE3CC"), Vector2(i * spacing - w / 2 + 14.0, 0))

static func tree(parent: Node, pos: Vector2, z := -28) -> void:
	svg(parent, "tree", pos, 1.2, z)

static func pond(parent: Node, pos: Vector2, s := 0.85, z := -25) -> void:
	svg(parent, "pond", pos, s, z)

static func hay_bales(parent: Node, pos: Vector2, z := -24) -> void:
	svg(parent, "hay-bales", pos, 1.15, z)

static func bush(parent: Node, pos: Vector2, s := 1.6, z := -33) -> void:
	svg(parent, "bush", pos, s, z)

## Cvetić: vidljiva zelena stabljika sa listićem + 5 latica oko žutog centra.
static func flower(parent: Node, pos: Vector2, color: Color, z := -20) -> void:
	var f := Node2D.new()
	f.position = pos
	f.z_index = z
	parent.add_child(f)
	# stabljika + listić
	UI.poly(f, UI.rounded_rect_points(6, 34, 3), Color("#6FA861"), Vector2(0, 24))
	var leaf := Polygon2D.new()
	leaf.polygon = UI.circle_points(8, 12)
	leaf.scale = Vector2(1.4, 0.6)
	leaf.rotation = -0.5
	leaf.position = Vector2(-9, 28)
	leaf.color = Color("#7DB56F")
	f.add_child(leaf)
	# cvet
	for i in 5:
		var a := -PI / 2 + TAU * i / 5
		UI.circle(f, Vector2(cos(a), sin(a)) * 9.5, 7.5, color)
	UI.circle(f, Vector2.ZERO, 6, Pal.SUN)

## Mekano brdo (koriste ga mini-igre koje ne koriste background.svg).
static func hill(parent: Node, w: float, bottom: float, top_y: float, amp: float, color: Color, z: int, phase := 0.0) -> void:
	var pts := PackedVector2Array()
	var steps := 40
	for i in steps + 1:
		var x := w * i / steps
		pts.append(Vector2(x, top_y + sin(x / w * TAU * 1.3 + phase) * amp))
	pts.append(Vector2(w, bottom))
	pts.append(Vector2(0, bottom))
	UI.poly(parent, pts, color, Vector2.ZERO, z)

## Meka senka pod objektom/životinjom.
static func ground_shadow(parent: Node, pos: Vector2, rx := 80.0, z := -1) -> void:
	var pts := PackedVector2Array()
	for i in 24:
		var a := TAU * i / 24
		pts.append(Vector2(cos(a) * rx, sin(a) * rx * 0.28))
	UI.poly(parent, pts, Pal.SHADOW, pos, z)
