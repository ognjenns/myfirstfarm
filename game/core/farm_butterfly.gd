class_name FarmButterfly
extends Node2D
## Leptir iz kupljenog paketa (bočni pogled, 16 sličica zamaha). Leti od
## `from` do `to` uz blago talasanje i luta; nestane kad stigne. Isti posao
## kao stari nacrtani Butterfly, samo sa pravim crtežom.

const COLORS := ["blue", "orange", "purple", "yellow", "white"]

var _to := Vector2.ZERO
var _vel := Vector2.ZERO
var _t := 0.0
var _wander := 0.0
var _frames: Array = []
var _f := 0.0
var _sprite: Sprite2D
var _sc := 1.0


func _init(from: Vector2, to: Vector2, color := "blue") -> void:
	position = from
	_to = to
	z_index = 20
	for i in 16:
		_frames.append(load("res://art/farm/butterfly-%s-%d.png" % [color, i + 1]))
	_sprite = Sprite2D.new()
	_sprite.texture = _frames[0]
	var s := UI.vs(self) if is_inside_tree() else Vector2(2316, 1080)
	_sc = (s.x * 0.045) / 228.0
	_sprite.scale = Vector2.ONE * _sc
	add_child(_sprite)
	var dir := (to - from).normalized()
	_vel = dir * 170.0
	_f = randf() * 16.0


func _process(delta: float) -> void:
	_t += delta
	if _t >= 16.0 or position.distance_to(_to) < 60.0:
		queue_free()
		return
	# Lutanje: pravac ka cilju plus sinusno talasanje po visini.
	_wander += delta
	var dir := (_to - position).normalized()
	_vel = _vel.lerp(dir * 170.0, delta * 0.8)
	position += _vel * delta + Vector2(0, sin(_wander * 3.0) * 70.0 * delta)
	# Crtež gleda ulevo: ko leti udesno, ogleda se.
	_sprite.scale = Vector2(-_sc if _vel.x > 0.0 else _sc, _sc)
	_f += delta * 18.0
	_sprite.texture = _frames[int(_f) % _frames.size()]
