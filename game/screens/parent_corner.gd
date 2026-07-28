extends BaseScreen
## Roditeljski ugao u duhu igre: drvene daske-dugmad sa ikonicama,
## farm prekidači za muziku/zvuk, footer sa Oggie ćurkicom.

const VERSION := "0.1.0"
const PRIVACY_URL := "https://ognjenns.github.io/myfirstfarm/privacy.html"

var music_toggle: Sprite2D
var sfx_toggle: Sprite2D
var unlock_label: Label

func _ready() -> void:
	home_target = get_tree().get_first_node_in_group("main").last_world
	var s := UI.vs(self)
	Scenery.background(self, "background-parents")
	add_home_button()

	UI.label(self, "For parents", Vector2(s.x * 0.5, s.y * 0.12), 64, Color(0.45, 0.40, 0.36))

	var lx := s.x * 0.30
	var rx := s.x * 0.70
	var rows := [s.y * 0.32, s.y * 0.52, s.y * 0.72]

	music_toggle = _row(lx, rows[0], "icon-music", "Music", _toggle_music, true)
	sfx_toggle = _row(rx, rows[0], "icon-sound", "Sounds", _toggle_sfx, true)
	_row(lx, rows[1], "icon-lock", "", _toggle_unlock_test, false, 36)
	_row(rx, rows[1], "icon-restore", "Restore purchases — soon", func() -> void: pass, false, 36)
	_row(lx, rows[2], "icon-privacy", "Privacy policy", func() -> void:
		if PRIVACY_URL != "":
			OS.shell_open(PRIVACY_URL)
	)
	_row(rx, rows[2], "icon-home-small", "Back to game", func() -> void: go(home_target))

	# tekst na unlock dasci (menja se sa stanjem)
	var up_scale := (s.x * 0.36) / 760.0
	unlock_label = UI.label(self, "", Vector2(lx + s.x * 0.36 * 0.03, rows[1] - 6.0 * up_scale), 36)
	_refresh_toggles()
	_refresh_unlock()

	# footer: Oggie ćurkica + verzija
	Scenery.svg(self, "logo-mini", Vector2(s.x / 2 - 420, s.y * 0.91), 0.3, 0)
	UI.label(self, "My First Farm  •  Oggie Games  •  v%s" % VERSION, Vector2(s.x / 2 + 60, s.y * 0.91), 32, Color(0.55, 0.50, 0.45))

## Jedna daska-dugme: ikonica levo, tekst, opciono prekidač desno. Vraća toggle sprite.
func _row(x: float, y: float, icon: String, text: String, action: Callable, with_toggle := false, font_size := 40) -> Sprite2D:
	var s := UI.vs(self)
	var w := s.x * 0.36
	var plank_scale := w / 760.0
	var btn := Area2D.new()
	btn.position = Vector2(x, y)

	var plank := Sprite2D.new()
	plank.texture = load("res://art/svg/button-wide.svg")
	plank.scale = Vector2.ONE * plank_scale
	btn.add_child(plank)

	var ic := Sprite2D.new()
	ic.texture = load("res://art/svg/%s.svg" % icon)
	ic.scale = Vector2.ONE * plank_scale * 0.62
	ic.position = Vector2(-w * 0.40, -6.0 * plank_scale)
	btn.add_child(ic)

	var toggle: Sprite2D = null
	if with_toggle:
		toggle = Sprite2D.new()
		toggle.scale = Vector2.ONE * plank_scale * 0.62
		toggle.position = Vector2(w * 0.36, -6.0 * plank_scale)
		btn.add_child(toggle)
		UI.label(btn, text, Vector2(-w * 0.06, -6.0 * plank_scale), font_size)
	else:
		UI.label(btn, text, Vector2(w * 0.03, -6.0 * plank_scale), font_size)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(w * 1.05, 140.0 * plank_scale * 1.3)
	shape.shape = rect
	btn.add_child(shape)
	btn.input_event.connect(func(_vp: Node, event: InputEvent, _i: int) -> void:
		if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
			Audio.play("pop", -6.0)
			UI.bounce(btn, Vector2.ONE)
			action.call()
	)
	add_child(btn)
	return toggle

## PRIVREMENO za testiranje: prekidač umesto prave kupovine.
## TODO (IAP): zameniti Google Play Billing / StoreKit kupovinom.
func _toggle_unlock_test() -> void:
	Save.set_unlocked(not Save.unlocked)
	_refresh_unlock()

func _refresh_unlock() -> void:
	unlock_label.text = "All games unlocked  ✓" if Save.unlocked else "Unlock all games — €2.99"

func _toggle_music() -> void:
	Save.set_music_on(not Save.music_on)
	Audio.set_music_enabled(Save.music_on)
	_refresh_toggles()

func _toggle_sfx() -> void:
	Save.set_sfx_on(not Save.sfx_on)
	_refresh_toggles()

func _refresh_toggles() -> void:
	music_toggle.texture = load("res://art/svg/toggle-%s.svg" % ("on" if Save.music_on else "off"))
	sfx_toggle.texture = load("res://art/svg/toggle-%s.svg" % ("on" if Save.sfx_on else "off"))
