extends Node

const RadioProgramDirectorScript = preload("res://scripts/audio/radio/radio_program_director.gd")
const RadioStationCatalogScript = preload("res://scripts/audio/radio/radio_station_catalog.gd")
const AudioReferenceResolverScript = preload("res://scripts/audio/audio_reference_resolver.gd")

signal segment_started(item: Dictionary)
signal segment_completed(item: Dictionary)
signal station_changed(station_id: String)
signal playback_state_changed(is_playing: bool, is_paused: bool)

var _director: RefCounted = null
var _player: AudioStreamPlayer = null
var _is_playing: bool = false
var _is_paused: bool = false
var _current_stream: AudioStream = null

func _init(director: RefCounted = null) -> void:
	if director:
		_director = director
	else:
		_director = RadioProgramDirectorScript.new()

func _ready() -> void:
	if not _player:
		_player = AudioStreamPlayer.new()
		_player.name = "RadioAudioStreamPlayer"
		_player.bus = "Master"
		add_child(_player)
		_player.finished.connect(_on_stream_finished)

func _exit_tree() -> void:
	reset()

func get_director() -> RefCounted:
	return _director

func is_playing() -> bool:
	return _is_playing

func is_paused() -> bool:
	return _is_paused

func play_station(station_id: String = RadioStationCatalogScript.DEFAULT_STATION_ID) -> void:
	if _director.get_station_id() != station_id:
		_director.set_station(station_id)
		station_changed.emit(station_id)

	if _is_paused:
		resume()
		return

	_is_playing = true
	_is_paused = false
	advance_segment()
	playback_state_changed.emit(_is_playing, _is_paused)

func advance_segment() -> void:
	if not _is_playing:
		return

	var old_item: Dictionary = _director.get_current_item()
	if not old_item.is_empty():
		segment_completed.emit(old_item)

	var next_item: Dictionary = _director.advance_next_item()
	if next_item.is_empty():
		stop()
		return

	_play_item(next_item)
	segment_started.emit(next_item)

func _play_item(item: Dictionary) -> void:
	var slot_id: String = item.get("slot_id", "")
	var stream: AudioStream = null

	# 1. Check if reference resolver has an asset for this slot
	if not slot_id.is_empty() and AudioReferenceResolverScript.is_reference_enabled():
		stream = AudioReferenceResolverScript.resolve_stream(slot_id)

	# 2. If null, synthesize procedural fallback stream
	if not stream:
		stream = _synthesize_procedural_segment(item)

	_current_stream = stream
	if _player:
		_player.stream = stream
		_player.play(0.0)

func pause() -> void:
	if not _is_playing or _is_paused:
		return

	_is_paused = true
	if _player and _player.is_playing():
		var playback_pos: float = _player.get_playback_position()
		if playback_pos > 0.0:
			_director.set_cursor_position(playback_pos)
		_player.stop()

	_director.set_paused(true)
	playback_state_changed.emit(_is_playing, _is_paused)

func resume() -> void:
	if not _is_playing or not _is_paused:
		return

	_is_paused = false
	_director.set_paused(false)

	if _player and _current_stream:
		var resume_pos: float = _director.get_cursor_position()
		_player.stream = _current_stream
		_player.play(resume_pos)

	playback_state_changed.emit(_is_playing, _is_paused)

func stop() -> void:
	_is_playing = false
	_is_paused = false
	if _player:
		_player.stop()
		_player.stream = null
	_current_stream = null
	playback_state_changed.emit(_is_playing, _is_paused)

func reset() -> void:
	stop()
	if _director:
		_director.reset()

func _on_stream_finished() -> void:
	if _is_playing and not _is_paused:
		advance_segment()

func _process(delta: float) -> void:
	if _is_playing and not _is_paused and _player and _player.is_playing():
		_director.set_cursor_position(_player.get_playback_position())

# -----------------------------------------------------------------------------
# PROCEDURAL FALLBACK SYNTHESIS
# -----------------------------------------------------------------------------

func _synthesize_procedural_segment(item: Dictionary) -> AudioStreamWAV:
	var duration: float = item.get("duration_sec", 2.0)
	var freq: float = item.get("base_freq_hz", 440.0)
	var category: int = item.get("category", RadioStationCatalogScript.Category.SONG)

	var sample_rate: int = 22050
	var total_samples: int = int(duration * sample_rate)
	# Ensure even sample count for 16-bit alignment
	if total_samples % 2 != 0:
		total_samples += 1

	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(total_samples * 2)

	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)
		var sample_val: float = 0.0

		match category:
			RadioStationCatalogScript.Category.SONG:
				# Synth melodic pattern: root tone with pulsating harmonic envelope
				var beat := sin(t * 8.0 * PI) * 0.3
				var tone := sin(t * freq * TAU) * 0.5
				var sub := sin(t * (freq * 0.5) * TAU) * 0.2
				sample_val = (tone + sub) * (0.7 + beat)

			RadioStationCatalogScript.Category.DJ_LINK:
				# Synth vocal format chatter pulse
				var speech_mod := sin(t * 12.0 * TAU) * 0.4 + 0.6
				sample_val = sin(t * freq * TAU) * 0.4 * speech_mod

			RadioStationCatalogScript.Category.STATION_ID:
				# Rising jingle chirp
				var sweep_freq := freq + (t / duration) * 220.0
				sample_val = sin(t * sweep_freq * TAU) * 0.5

			RadioStationCatalogScript.Category.ADVERT:
				# Rapid two-tone chime
				var chime_freq := freq if fmod(t, 0.4) < 0.2 else freq * 1.25
				sample_val = sin(t * chime_freq * TAU) * 0.35

			RadioStationCatalogScript.Category.WORLD_REACTION:
				# Urgent pulsing staccato tone
				var staccato := 1.0 if fmod(t, 0.25) < 0.12 else 0.0
				sample_val = sin(t * freq * TAU) * 0.5 * staccato

			_:
				sample_val = sin(t * freq * TAU) * 0.3

		# Apply smooth 0.05s edge ramps to prevent clicks
		var ramp := 1.0
		var ramp_time := 0.05
		if t < ramp_time:
			ramp = t / ramp_time
		elif t > duration - ramp_time:
			ramp = maxf(0.0, (duration - t) / ramp_time)

		var val_16 := int(clampf(sample_val * ramp, -1.0, 1.0) * 32767.0)
		bytes.encode_s16(i * 2, val_16)

	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = sample_rate
	wav.stereo = false
	wav.data = bytes
	return wav
