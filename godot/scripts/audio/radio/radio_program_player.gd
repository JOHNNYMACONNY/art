extends Node

const RadioProgramDirectorScript = preload("res://scripts/audio/radio/radio_program_director.gd")
const RadioStationCatalogScript = preload("res://scripts/audio/radio/radio_station_catalog.gd")
const AudioReferenceResolverScript = preload("res://scripts/audio/audio_reference_resolver.gd")

signal segment_started(item: Dictionary)
signal segment_completed(item: Dictionary)
signal phase_changed(phase: int, item: Dictionary)
signal station_changed(station_id: String)
signal playback_state_changed(is_playing: bool, is_paused: bool)

var _director: RefCounted = null
var _player: AudioStreamPlayer = null
var _is_playing: bool = false
var _is_paused: bool = false
var _current_stream: AudioStream = null

## Multi-phase song playback state
var _current_phase: int = -1 # RadioStationCatalog.Phase or -1
var _body_only_mode: bool = false
var _current_item: Dictionary = {}

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

func get_current_phase() -> int:
	return _current_phase

func is_body_only_mode() -> bool:
	return _body_only_mode

func set_body_only_mode(enabled: bool) -> void:
	_body_only_mode = enabled

func get_playback_position() -> float:
	if _player and _player.is_playing():
		return _player.get_playback_position()
	return 0.0

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

	var old_item: Dictionary = _current_item
	if not old_item.is_empty():
		segment_completed.emit(old_item)

	var next_item: Dictionary = _director.advance_next_item()
	if next_item.is_empty():
		stop()
		return

	_current_item = next_item
	_start_item_playback(_current_item)
	segment_started.emit(_current_item)

func _start_item_playback(item: Dictionary) -> void:
	var category: int = item.get("category", RadioStationCatalogScript.Category.SONG)

	if category == RadioStationCatalogScript.Category.SONG:
		if _body_only_mode:
			_play_phase(RadioStationCatalogScript.Phase.BODY, item)
		else:
			var intro_sec: float = item.get("intro_sec", 0.0)
			if intro_sec > 0.0:
				_play_phase(RadioStationCatalogScript.Phase.INTRO, item)
			else:
				_play_phase(RadioStationCatalogScript.Phase.BODY, item)
	else:
		# Interstitials, Station IDs, Adverts, World Reactions are single-phase BODY items
		_play_phase(RadioStationCatalogScript.Phase.BODY, item)

func _play_phase(phase: int, item: Dictionary) -> void:
	_current_phase = phase
	phase_changed.emit(phase, item)

	var stream: AudioStream = null
	var slot_id: String = item.get("slot_id", "")

	# 1. Reference resolver check (slot override)
	if not slot_id.is_empty() and AudioReferenceResolverScript.is_reference_enabled():
		stream = AudioReferenceResolverScript.resolve_stream(slot_id)

	# 2. Synthesize phase-specific procedural audio
	if not stream:
		stream = _synthesize_phase_segment(item, phase)

	_current_stream = stream
	if _player:
		_player.stream = stream
		_player.play(0.0)

func _on_stream_finished() -> void:
	if not _is_playing or _is_paused:
		return

	var cat: int = _current_item.get("category", -1)
	if cat == RadioStationCatalogScript.Category.SONG:
		match _current_phase:
			RadioStationCatalogScript.Phase.INTRO:
				# Transition INTRO -> BODY
				_play_phase(RadioStationCatalogScript.Phase.BODY, _current_item)
				return
			RadioStationCatalogScript.Phase.BODY:
				if not _body_only_mode:
					var outro_sec: float = _current_item.get("outro_sec", 0.0)
					if outro_sec > 0.0:
						# Transition BODY -> OUTRO
						_play_phase(RadioStationCatalogScript.Phase.OUTRO, _current_item)
						return
				# If body-only or no outro, advance next item
				advance_segment()
				return
			RadioStationCatalogScript.Phase.OUTRO:
				# Song finished completely, advance next item
				advance_segment()
				return
			_:
				advance_segment()
				return
	else:
		advance_segment()

func pause() -> void:
	if not _is_playing or _is_paused:
		return

	_is_paused = true
	if _player and _player.is_playing():
		var playback_pos: float = _player.get_playback_position()
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
	_current_phase = -1
	_current_item = {}
	if _player:
		_player.stop()
		_player.stream = null
	_current_stream = null
	playback_state_changed.emit(_is_playing, _is_paused)

func reset() -> void:
	stop()
	if _director:
		_director.reset()

func _process(delta: float) -> void:
	if _is_playing and not _is_paused and _player and _player.is_playing():
		_director.set_cursor_position(_player.get_playback_position())

# -----------------------------------------------------------------------------
# PROCEDURAL PHASE SYNTHESIS
# -----------------------------------------------------------------------------

func _synthesize_phase_segment(item: Dictionary, phase: int) -> AudioStreamWAV:
	var category: int = item.get("category", RadioStationCatalogScript.Category.SONG)
	var freq: float = item.get("base_freq_hz", 440.0)

	var duration: float = item.get("duration_sec", 2.0)
	if category == RadioStationCatalogScript.Category.SONG:
		match phase:
			RadioStationCatalogScript.Phase.INTRO:
				duration = item.get("intro_sec", 0.5)
			RadioStationCatalogScript.Phase.BODY:
				duration = item.get("body_sec", 3.0)
			RadioStationCatalogScript.Phase.OUTRO:
				duration = item.get("outro_sec", 0.5)

	var sample_rate: int = 22050
	var total_samples: int = int(duration * sample_rate)
	if total_samples < 2:
		total_samples = 2
	if total_samples % 2 != 0:
		total_samples += 1

	var bytes: PackedByteArray = PackedByteArray()
	bytes.resize(total_samples * 2)

	for i in range(total_samples):
		var t: float = float(i) / float(sample_rate)
		var sample_val: float = 0.0

		match category:
			RadioStationCatalogScript.Category.SONG:
				match phase:
					RadioStationCatalogScript.Phase.INTRO:
						# Filter sweep into the track
						var filter_env := clampf(t / maxf(0.01, duration), 0.0, 1.0)
						var tone := sin(t * freq * TAU) * 0.4
						sample_val = tone * filter_env
					RadioStationCatalogScript.Phase.BODY:
						# Full dynamic groove
						var beat := sin(t * 8.0 * PI) * 0.3
						var tone := sin(t * freq * TAU) * 0.5
						var sub := sin(t * (freq * 0.5) * TAU) * 0.2
						sample_val = (tone + sub) * (0.7 + beat)
					RadioStationCatalogScript.Phase.OUTRO:
						# Fading tail
						var fade := clampf(1.0 - (t / maxf(0.01, duration)), 0.0, 1.0)
						var tone := sin(t * freq * TAU) * 0.4
						sample_val = tone * fade

			RadioStationCatalogScript.Category.DJ_LINK:
				var speech_mod := sin(t * 12.0 * TAU) * 0.4 + 0.6
				sample_val = sin(t * freq * TAU) * 0.4 * speech_mod

			RadioStationCatalogScript.Category.STATION_ID:
				var sweep_freq := freq + (t / maxf(0.01, duration)) * 220.0
				sample_val = sin(t * sweep_freq * TAU) * 0.5

			RadioStationCatalogScript.Category.ADVERT:
				var chime_freq := freq if fmod(t, 0.4) < 0.2 else freq * 1.25
				sample_val = sin(t * chime_freq * TAU) * 0.35

			RadioStationCatalogScript.Category.WORLD_REACTION:
				var staccato := 1.0 if fmod(t, 0.25) < 0.12 else 0.0
				sample_val = sin(t * freq * TAU) * 0.5 * staccato

			_:
				sample_val = sin(t * freq * TAU) * 0.3

		# Edge ramps
		var ramp := 1.0
		var ramp_time := 0.02
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
