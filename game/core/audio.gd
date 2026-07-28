extends Node
## Autoload "Audio" — pool plejera za efekte + muzika u pozadini.
## Zvuci: res://sfx/<ime>.ogg (prioritet) ili .wav (placeholder).

var _players: Array[AudioStreamPlayer] = []
var _cache := {}
var _music: AudioStreamPlayer

func _ready() -> void:
	for i in 10:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_start_music()

func _start_music() -> void:
	_music = AudioStreamPlayer.new()
	add_child(_music)
	var stream := _load_stream("music")
	if stream == null:
		return
	_music.stream = stream
	_music.volume_db = -14.0
	_music.finished.connect(_music.play)  # ručni loop (WAV nema loop flag iz koda)
	if Save.music_on:
		_music.play()

## Roditeljski prekidač za muziku.
func set_music_enabled(on: bool) -> void:
	if on and not _music.playing:
		_music.play()
	elif not on:
		_music.stop()

func _load_stream(sound: String) -> AudioStream:
	if _cache.has(sound):
		return _cache[sound]
	for ext in ["ogg", "wav"]:
		var path := "res://sfx/%s.%s" % [sound, ext]
		if ResourceLoader.exists(path):
			_cache[sound] = load(path)
			return _cache[sound]
	return null

func play(sound: String, volume_db := 0.0, pitch := 1.0) -> void:
	if not Save.sfx_on:
		return
	var stream := _load_stream(sound)
	if stream == null:
		return
	for p in _players:
		if not p.playing:
			p.stream = stream
			p.volume_db = volume_db
			p.pitch_scale = pitch
			p.play()
			return
	_players[0].stream = stream
	_players[0].volume_db = volume_db
	_players[0].pitch_scale = pitch
	_players[0].play()

## Da li trenutno svira bilo koji efekat (koristi se da se automatska
## glasanja ne preklapaju sa onim što je dete izazvalo tapom).
func is_busy() -> bool:
	for p in _players:
		if p.playing:
			return true
	return false

func animal_voice(id: String) -> void:
	var name := "%s_%d" % [id, randi() % 2]
	if _load_stream(name) == null:
		play("%s_happy" % id)  # džungla još nema prava glasanja — veseli đingl
	else:
		play(name)

func animal_happy(id: String) -> void:
	play("%s_happy" % id)
