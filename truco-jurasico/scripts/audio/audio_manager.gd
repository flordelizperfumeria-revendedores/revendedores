extends Node
## Autoload "Audio": efectos y música.
## La música se sintetiza una sola vez en un hilo y se guarda en caché (user://).

const Synth = preload("res://scripts/audio/synth.gd")
const MUSIC_CACHE := "user://music_cache_v1.pcm"

var sfx := {}
var _players: Array = []
var _music: AudioStreamPlayer
var _thread: Thread


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 8:
		var p := AudioStreamPlayer.new()
		add_child(p)
		_players.append(p)
	_music = AudioStreamPlayer.new()
	_music.volume_db = -9.0
	add_child(_music)
	sfx = Synth.make_sfx()
	_load_music()


func play(sound: String, pitch: float = 1.0, volume_db: float = 0.0) -> void:
	if not Save.settings.get("sfx", true) or not sfx.has(sound):
		return
	for p in _players:
		if not p.playing:
			p.stream = sfx[sound]
			p.pitch_scale = pitch
			p.volume_db = volume_db
			p.play()
			return


func set_music_enabled(on: bool) -> void:
	Save.settings["music"] = on
	Save.save()
	if on and _music.stream and not _music.playing:
		_music.play()
	elif not on:
		_music.stop()


func _load_music() -> void:
	if FileAccess.file_exists(MUSIC_CACHE):
		var f := FileAccess.open(MUSIC_CACHE, FileAccess.READ)
		if f and f.get_length() > 1000:
			_music_ready(f.get_buffer(f.get_length()), false)
			return
	if OS.has_feature("threads") or not OS.has_feature("web"):
		_thread = Thread.new()
		_thread.start(_build_music)
	else:
		_music_ready(Synth.pcm_bytes(Synth.make_music()), true)


func _build_music() -> void:
	var bytes := Synth.pcm_bytes(Synth.make_music())
	call_deferred("_music_ready", bytes, true)


func _music_ready(bytes: PackedByteArray, store: bool) -> void:
	if _thread:
		_thread.wait_to_finish()
		_thread = null
	if store:
		var f := FileAccess.open(MUSIC_CACHE, FileAccess.WRITE)
		if f:
			f.store_buffer(bytes)
	_music.stream = Synth.wav_from_bytes(bytes, true)
	if Save.settings.get("music", true):
		_music.play()


func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()
