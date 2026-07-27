class_name GradientBG
extends Node2D
## Pozadina cele scene — vertikalni gradijent.

var top_color := Color("#aee9ff")
var bottom_color := Color("#e8ffd6")

func _init(top := Color("#aee9ff"), bottom := Color("#e8ffd6")) -> void:
	top_color = top
	bottom_color = bottom
	z_index = -50

func _ready() -> void:
	get_viewport().size_changed.connect(queue_redraw)

func _draw() -> void:
	var s := UI.vs(self)
	var pts := PackedVector2Array([Vector2.ZERO, Vector2(s.x, 0), s, Vector2(0, s.y)])
	var cols := PackedColorArray([top_color, top_color, bottom_color, bottom_color])
	draw_polygon(pts, cols)
