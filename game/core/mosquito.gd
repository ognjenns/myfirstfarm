class_name Mosquito
extends Node2D
## Komični komarac za džunglu: buljave oči, dugačka rilica, frenetična
## krilca i nervozan cik-cak let preko ekrana.

var _t := 0.0
var _to := Vector2.ZERO
var _wp := Vector2.ZERO       # trenutna među-meta (waypoint)
var _hover_t := 0.0           # > 0: lebdi u mestu pre sledećeg naleta
var _hover_anchor := Vector2.ZERO
var _dart_speed := 0.0
var _vel := Vector2.ZERO
var _wing_l: Polygon2D
var _wing_r: Polygon2D

func _init(from: Vector2, to: Vector2) -> void:
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


## Pravi komarački let (steering kao kod leptira): brzina se SAVIJA ka meti
## pa su putanje lukovi, meta ume da bude i bočno i unazad, a lebdenje
## vidljivo treperi u mestu. Nikad prava linija.
func _process(delta: float) -> void:
	_t += delta
	if _t >= 12.0 or position.distance_to(_to) < 70.0:
		queue_free()
		return
	if _wp == Vector2.ZERO:
		_pick_waypoint()

	if _hover_t > 0.0:
		# lebdi: vidljivo nervozno treperenje oko sidra
		_hover_t -= delta
		_vel = _vel.lerp(Vector2.ZERO, 8.0 * delta)
		position = _hover_anchor + Vector2(sin(_t * 21.0) * 10.0, cos(_t * 16.0) * 9.0)
		rotation = lerpf(rotation, 0.0, 6.0 * delta)
		if _hover_t <= 0.0:
			_pick_waypoint()
	else:
		# skretanje sa ograničenjem → let u lukovima, ne po lenjiru
		var desired := (_wp - position).normalized() * _dart_speed
		_vel = _vel.lerp(desired, 4.5 * delta)
		position += _vel * delta
		# lice i nagib prate STVARNU brzinu (ne metu)
		if absf(_vel.x) > 60.0:
			scale.x = absf(scale.x) * (1.0 if _vel.x >= 0.0 else -1.0)
		rotation = clampf(_vel.y * 0.0008, -0.35, 0.35) * signf(scale.x)
		if position.distance_to(_wp) < 26.0:
			_hover_anchor = position
			_hover_t = randf_range(0.25, 0.8)

	# frenetično zujanje krilima
	var flap := absf(sin(_t * 34.0))
	_wing_l.scale.y = 0.25 + 0.8 * flap
	_wing_r.scale.y = 0.2 + 0.7 * (1.0 - flap)

## Nova među-meta: uglavnom napreduje ka izlazu, ali ume i bočno/unazad.
func _pick_waypoint() -> void:
	var ahead := position.lerp(_to, randf_range(0.12, 0.38))
	_wp = ahead + Vector2(randf_range(-170.0, 170.0), randf_range(-190.0, 190.0))
	_wp.y = clampf(_wp.y, 80.0, 620.0)
	_dart_speed = randf_range(380.0, 720.0)
