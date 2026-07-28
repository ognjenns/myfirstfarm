class_name Mosquito
extends Node2D
## Komični komarac za džunglu: buljave oči, dugačka rilica, frenetična
## krilca i nervozan cik-cak let preko ekrana.

var _t := 0.0
var _from := Vector2.ZERO
var _to := Vector2.ZERO
var _dur := 6.0
var _wing_l: Polygon2D
var _wing_r: Polygon2D

func _init(from: Vector2, to: Vector2) -> void:
	_from = from
	_to = to
	position = from
	z_index = 60
	scale = Vector2.ONE * 1.15
	if to.x < from.x:
		scale.x = -scale.x  # gleda u smeru leta

	# telo + zadak
	var abdomen := Polygon2D.new()
	abdomen.polygon = UI.circle_points(10, 12)
	abdomen.scale = Vector2(1.5, 0.8)
	abdomen.rotation = 0.4
	abdomen.position = Vector2(-14, 6)
	abdomen.color = Color("#8A8578")
	add_child(abdomen)
	UI.circle(self, Vector2.ZERO, 9, Color("#6E6A5E"))
	# buljave oči (komično prevelike)
	UI.circle(self, Vector2(7, -7), 7, Color.WHITE)
	UI.circle(self, Vector2(13, -4), 7, Color.WHITE)
	UI.circle(self, Vector2(8.5, -6), 3, Pal.EYE)
	UI.circle(self, Vector2(14.5, -3), 3, Pal.EYE)
	# rilica — dugačka tanka "igla"
	var nose := Polygon2D.new()
	nose.polygon = UI.rect_points(22, 2.5)
	nose.position = Vector2(24, 2)
	nose.rotation = 0.18
	nose.color = Pal.OUTLINE
	add_child(nose)
	# nožice koje vise
	for i in 3:
		var leg := Polygon2D.new()
		leg.polygon = UI.rect_points(2, 12)
		leg.position = Vector2(-8 + i * 6, 14)
		leg.rotation = 0.25 - i * 0.25
		leg.color = Color("#5A564C")
		add_child(leg)
	# krilca — providna, flap u _process
	_wing_l = UI.poly(self, UI.circle_points(11, 10), Color(0.9, 0.95, 1.0, 0.55), Vector2(-4, -12))
	_wing_r = UI.poly(self, UI.circle_points(11, 10), Color(0.85, 0.92, 1.0, 0.45), Vector2(-10, -10))
	for w in [_wing_l, _wing_r]:
		w.scale = Vector2(1.5, 0.7)


func _process(delta: float) -> void:
	_t += delta
	var k := _t / _dur
	if k >= 1.0:
		queue_free()
		return
	# nervozan let: osnovna putanja + dva sloja cik-caka
	var jitter := Vector2(
		sin(_t * 7.0) * 34.0 + sin(_t * 13.0) * 18.0,
		sin(_t * 9.0) * 30.0 + cos(_t * 17.0) * 16.0
	)
	position = _from.lerp(_to, k) + jitter
	# frenetično zujanje krilima
	var flap := absf(sin(_t * 34.0))
	_wing_l.scale.y = 0.25 + 0.8 * flap
	_wing_r.scale.y = 0.2 + 0.7 * (1.0 - flap)
