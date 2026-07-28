extends BaseScreen
## Splash (~5s): bedž sa ćurkom stoji, SLOVA kruže oko njega brzo pa sve
## sporije dok se ne zaustave na svom mestu; ćurka namigne; topli akord; farma.
## Zvuk: splash_theme.wav — komponovan po ovoj vremenskoj liniji.

var badge: Sprite2D
var ring: Sprite2D
var holder: Node2D

func _ready() -> void:
	var s := UI.vs(self)
	add_child(GradientBG.new(Pal.BARN_TRIM, Color("#F3E8D5")))

	var target := (minf(s.x, s.y) * 0.62) / 512.0
	holder = Node2D.new()
	holder.position = s / 2
	holder.scale = Vector2.ONE * target * 0.22
	add_child(holder)

	badge = Sprite2D.new()
	badge.texture = load("res://art/svg/logo-badge-open.svg")
	holder.add_child(badge)

	ring = Sprite2D.new()
	ring.texture = load("res://art/svg/logo-ring.svg")
	holder.add_child(ring)

	Audio.play("splash_theme")

	# bedž raste do pune veličine; SLOVA se vrte 4 kruga, brzo pa sve sporije,
	# i zaustave se tačno na svom mestu (TAU*4 → isti položaj kao na početku)
	var tw := create_tween()
	tw.tween_property(holder, "scale", Vector2.ONE * target, 2.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(ring, "rotation", TAU * 4.0, 2.2).set_trans(Tween.TRANS_QUINT).set_ease(Tween.EASE_OUT)
	# sletanje: mali elastični poskok celog loga
	tw.tween_property(holder, "scale", Vector2.ONE * target * 1.06, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(holder, "scale", Vector2.ONE * target, 0.35).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

	_at(3.2, _wink)
	_at(3.75, _unwink)
	_at(4.55, _fade_out)
	_at(5.0, func() -> void: go("worlds"))

## Timer kao dete node — umire zajedno sa scenom, bez visećih callbackova.
func _at(sec: float, action: Callable) -> void:
	var t := Timer.new()
	t.wait_time = sec
	t.one_shot = true
	t.timeout.connect(action)
	add_child(t)
	t.start()

func _wink() -> void:
	badge.texture = load("res://art/svg/logo-badge-wink.svg")

func _unwink() -> void:
	badge.texture = load("res://art/svg/logo-badge-open.svg")

func _fade_out() -> void:
	var tw := create_tween()
	tw.tween_property(holder, "modulate:a", 0.0, 0.4)
