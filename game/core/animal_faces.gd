class_name AnimalFaces
## Face životinja — SVG asseti iz Claude Design-a (art/svg/<id>.svg).
## build(id) vraća Node2D efektivne veličine ~R95 kao ranije nacrtane face,
## pa sve postojeće skale u igri i dalje važe.

const SVG_SCALE := 0.55  # 512px SVG → ~230px faca (poklapa se sa starim R95 + uši)

static func build(id: String) -> Node2D:
	var n := Node2D.new()
	var s := Sprite2D.new()
	s.texture = load("res://art/svg/%s.svg" % id)
	s.scale = Vector2.ONE * SVG_SCALE
	n.add_child(s)
	return n
