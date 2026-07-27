class_name Butterfly
extends Node2D
## Leptir koji preleti preko ekrana — čist ukras, mami tap (i beži od njega).

const COLORS := [Color("#ff9f43"), Color("#6FB7E8"), Color("#F7D954")]

var _t := 0.0
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _dur := 7.0
var _wing_l: Polygon2D
var _wing_r: Polygon2D

func _init(from: Vector2, to: Vector2, wing_color := Color("#ff9f43")) -> void:
	_from = from
	_to = to
	position = from
	z_index = 60
	UI.poly(self, UI.rect_points(6, 26), Color(0.35, 0.25, 0.2))
	_wing_l = UI.poly(self, UI.circle_points(16, 12), wing_color, Vector2(-13, -4))
	_wing_r = UI.poly(self, UI.circle_points(16, 12), wing_color, Vector2(13, -4))
	for w in [_wing_l, _wing_r]:
		w.scale = Vector2(1.0, 1.4)

func _process(delta: float) -> void:
	_t += delta
	var k := _t / _dur
	if k >= 1.0:
		queue_free()
		return
	# talasasta putanja + mahanje krilima
	position = _from.lerp(_to, k) + Vector2(0, sin(_t * 3.0) * 60.0)
	var flap := absf(sin(_t * 14.0))
	_wing_l.scale.x = 0.3 + 0.7 * flap
	_wing_r.scale.x = 0.3 + 0.7 * flap
