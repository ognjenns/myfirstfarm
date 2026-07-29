extends Node
## Autoload "Save" — trajno stanje (za sada samo "ukloni reklame" flag).

const PATH := "user://save.cfg"

var unlocked := OS.is_debug_build()  # debug: sve otključano (screenshotovi/razvoj); release: kupovina
var music_on := true
var sfx_on := true

func _ready() -> void:
	var cfg := ConfigFile.new()
	if cfg.load(PATH) == OK:
		unlocked = cfg.get_value("iap", "unlocked", OS.is_debug_build())
		music_on = cfg.get_value("audio", "music_on", true)
		sfx_on = cfg.get_value("audio", "sfx_on", true)

func _persist() -> void:
	var cfg := ConfigFile.new()
	cfg.set_value("iap", "unlocked", unlocked)
	cfg.set_value("audio", "music_on", music_on)
	cfg.set_value("audio", "sfx_on", sfx_on)
	cfg.save(PATH)

func set_unlocked(value: bool) -> void:
	unlocked = value
	_persist()

func set_music_on(value: bool) -> void:
	music_on = value
	_persist()

func set_sfx_on(value: bool) -> void:
	sfx_on = value
	_persist()
