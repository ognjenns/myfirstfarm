extends BaseScreen
## Roditeljski ugao u duhu igre: drvene daske-dugmad sa ikonicama,
## farm prekidači za muziku/zvuk, footer sa Oggie ćurkicom.

const VERSION := "1.1.1"  # držati u skladu sa version/name u export_presets.cfg
const PRIVACY_URL := "https://ognjenns.github.io/myfirstfarm/privacy.html"

var music_toggle: Sprite2D
var sfx_toggle: Sprite2D
var unlock_label: Label
var unlock_price: Label

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
	_row(lx, rows[1], "icon-lock", "", _unlock_pressed)
	_row(rx, rows[1], "icon-restore", "Restore purchases", _restore_pressed)
	Store.unlock_state_changed.connect(_refresh_unlock)
	_row(lx, rows[2], "icon-privacy", "Privacy policy", func() -> void:
		if PRIVACY_URL != "":
			OS.shell_open(PRIVACY_URL)
	)
	_row(rx, rows[2], "icon-home-small", "Back to game", func() -> void: go(home_target))

	# unlock daska u tri segmenta kao Music/Sounds: katanac | tekst | cena.
	# Tekst mora da stane IZMEĐU urezanih linija (art: x=200..565 od 760),
	# a cena/kvačica ide u desni segment — tamo gde ostale daske drže prekidač.
	var up_scale := (s.x * 0.36) / 760.0
	unlock_label = UI.label(self, "", Vector2(lx + s.x * 0.36 * 0.007, rows[1] - 6.0 * up_scale), 40)
	unlock_price = UI.label(self, "", Vector2(lx + s.x * 0.36 * 0.34, rows[1] - 6.0 * up_scale), 34)
	# ispod daske: šta se sve dobija (obećanje važi i za buduće svetove)
	UI.label(self, "All worlds + future updates", Vector2(lx, rows[1] + 92.0 * up_scale), 26, Color(0.55, 0.50, 0.45))
	_refresh_toggles()
	_refresh_unlock()

	# footer: Oggie ćurkica + verzija
	Scenery.svg(self, "logo-mini", Vector2(s.x / 2 - 460, s.y * 0.91), 0.3, 0)
	# ime se čita iz project.godot da više ne može da odluta od stvarnog imena appa;
	# na iOS-u App Store listing nosi i "Toddler Game" sufiks (golo ime je bilo zauzeto)
	var app_name: String = ProjectSettings.get_setting("application/config/name", "My First Animals")
	if OS.has_feature("ios"):
		app_name += ": Toddler Game"
	var footer := "%s  •  Oggie Games  •  v%s" % [app_name, VERSION]
	# duži iOS tekst: manji font + centar pomeren udesno da ne pređe preko ćurke
	UI.label(self, footer, Vector2(s.x / 2 + 80, s.y * 0.91), 26 if footer.length() > 45 else 32, Color(0.55, 0.50, 0.45))

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

## Prava kupovina preko Google Play; u debug buildu bez Billinga (ili u
## editoru) ostaje test-prekidač da možemo da probamo zaključavanje.
func _unlock_pressed() -> void:
	if Store.available:
		if not Save.unlocked:
			Store.buy()
	elif OS.is_debug_build():
		Save.set_unlocked(not Save.unlocked)
		_refresh_unlock()

func _restore_pressed() -> void:
	Store.restore()

func _refresh_unlock() -> void:
	if Save.unlocked:
		unlock_label.text = "All games unlocked"
		unlock_price.text = "✓"
		unlock_price.add_theme_font_size_override("font_size", 44)
		unlock_price.add_theme_color_override("font_color", Color("#5FA463"))
	else:
		unlock_label.text = "Unlock all games"
		unlock_price.text = Store.price_text
		# duže lokalizovane cene (npr. "RSD 349,99") — manji font da stanu u segment
		unlock_price.add_theme_font_size_override("font_size", 34 if Store.price_text.length() <= 6 else 24)

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
