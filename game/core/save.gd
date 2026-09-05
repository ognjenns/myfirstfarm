extends Node
## Autoload "Save" — trajno stanje (za sada samo "ukloni reklame" flag).

const PATH := "user://save.cfg"

## Debug build otključava sve (screenshotovi, razvoj na Androidu) — ali NIKAD
## na iOS-u: 2.0.0 je u App Store otišao sa debug šablonom (export-debug pa
## Xcode Release arhiva) i svi kupci su dobili sve igre besplatno (05.09.2026).
## Na iOS-u otključava samo kupovina, ma kakav bio build.
var unlocked := OS.is_debug_build() and OS.get_name() != "iOS"
var music_on := true
var sfx_on := true
## Koliko je puta aplikacija pokrenuta. Po ovome pokazivač zna da li dete tek
## upoznaje igru ili je već zna (vidi BaseScreen.add_hint).
var launches := 0
## Ekrani koje je dete već otvorilo — na prvom ulasku pokazivač ne čeka.
var seen: Array = []

func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		unlocked = cfg.get_value("iap", "unlocked", unlocked)
		music_on = cfg.get_value("audio", "music_on", true)
		sfx_on = cfg.get_value("audio", "sfx_on", true)
		launches = cfg.get_value("play", "launches", 0)
		seen = cfg.get_value("play", "seen", [])
	if OS.get_cmdline_user_args().is_empty():
		launches += 1
		_persist()
	else:
		# Alatke (screenshotovi, testovi, snimanje promo videa) se ponašaju kao
		# prvo pokretanje: ne broje se i uvek vide pokazivač. Inače bi posle par
		# provera utihnuo na snimcima pa bismo mislili da je pokvaren.
		launches = 1

func _persist() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("iap", "unlocked", unlocked)
	cfg.set_value("audio", "music_on", music_on)
	cfg.set_value("audio", "sfx_on", sfx_on)
	cfg.set_value("play", "launches", launches)
	cfg.set_value("play", "seen", seen)
	cfg.save(PATH)

## Da li je ovo prvi ulazak na ekran; odmah ga upiše kao viđen.
func first_visit(screen: String) -> bool:
	if screen in seen:
		return false
	seen.append(screen)
	if OS.get_cmdline_user_args().is_empty():
		_persist()
	return true

func set_unlocked(value: bool) -> void:
	unlocked = value
	_persist()

func set_music_on(value: bool) -> void:
	music_on = value
	_persist()

func set_sfx_on(value: bool) -> void:
	sfx_on = value
	_persist()
