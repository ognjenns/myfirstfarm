extends BaseScreen
## Roditeljski ugao (iza parental gate-a): zvuk/muzika prekidači,
## ukloni reklame, privacy policy, o aplikaciji.
## Tekst je OK ovde — namenjen roditelju.

const VERSION := "0.1.0"
const PRIVACY_URL := ""  # TODO: GitHub Pages URL kad se objavi privacy policy

var music_btn: Button
var sfx_btn: Button

func _ready() -> void:
	ad_on_exit = false
	var s := UI.vs(self)
	add_child(GradientBG.new(Pal.SKY_LOW, Pal.BARN_TRIM))
	add_home_button()

	UI.label(self, "Za roditelje", Vector2(s.x / 2, s.y * 0.12), 72)

	var left := s.x * 0.28
	var right := s.x * 0.72

	music_btn = _menu_button("", Vector2(left, s.y * 0.32), _toggle_music)
	sfx_btn = _menu_button("", Vector2(right, s.y * 0.32), _toggle_sfx)
	_refresh_audio_labels()

	_menu_button("Ukloni reklame — 2,99 € (uskoro)", Vector2(left, s.y * 0.52), func() -> void:
		pass  # TODO (N5): IAP
	)
	_menu_button("Vrati kupovine (uskoro)", Vector2(right, s.y * 0.52), func() -> void:
		pass  # TODO (N5): restore
	)
	_menu_button("Politika privatnosti", Vector2(left, s.y * 0.72), func() -> void:
		if PRIVACY_URL != "":
			OS.shell_open(PRIVACY_URL)
	)
	_menu_button("Nazad na igru", Vector2(right, s.y * 0.72), func() -> void:
		go("hub")
	)

	# o aplikaciji — Oggie ćurkica + verzija
	Scenery.svg(self, "logo-mini", Vector2(s.x / 2 - 420, s.y * 0.90), 0.35, 0)
	UI.label(self, "My First Farm  •  Oggie Games  •  v%s" % VERSION, Vector2(s.x / 2 + 60, s.y * 0.90), 34, Color(0.5, 0.46, 0.42))

func _toggle_music() -> void:
	Save.set_music_on(not Save.music_on)
	Audio.set_music_enabled(Save.music_on)
	_refresh_audio_labels()

func _toggle_sfx() -> void:
	Save.set_sfx_on(not Save.sfx_on)
	_refresh_audio_labels()
	if Save.sfx_on:
		Audio.play("pop")  # potvrda da je zvuk opet tu

func _refresh_audio_labels() -> void:
	music_btn.text = "Muzika: %s" % ("UKLJUČENA" if Save.music_on else "isključena")
	sfx_btn.text = "Zvukovi: %s" % ("UKLJUČENI" if Save.sfx_on else "isključeni")

func _menu_button(text: String, pos: Vector2, action: Callable) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.add_theme_font_size_override("font_size", 44)
	btn.custom_minimum_size = Vector2(760, 120)
	btn.position = pos - Vector2(380, 60)
	btn.pressed.connect(action)
	add_child(btn)
	return btn
