class_name DriftCloud
extends Sprite2D
## Oblak koji lagano pluta preko neba i vraća se na drugu stranu.

var speed := 18.0

func _ready() -> void:
	speed = randf_range(10.0, 26.0)

func _process(delta: float) -> void:
	position.x += speed * delta
	var w := get_viewport_rect().size.x
	if position.x > w + 250.0:
		position.x = -250.0
