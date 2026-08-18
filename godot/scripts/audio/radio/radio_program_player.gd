extends Node

const RadioProgramDirectorScript = preload("res://scripts/audio/radio/radio_program_director.gd")
const RadioStationCatalogScript = preload("res://scripts/audio/radio/radio_station_catalog.gd")
const AudioReferenceResolverScript = preload("res://scripts/audio/audio_reference_resolver.gd")

signal segment_started(item: Dictionary)
signal segment_completed(item: Dictionary)
signal phase_changed(phase: int, item: Dictionary, segment: Dictionary)
signal station_changed(station_id: String)
signal playback_state_changed(is_playing: bool, is_paused: bool)

var _director: RefCounted = null
var _player: AudioStreamPlayer = null
var _is_playing: bool = false
var _is_paused: bool = false
var _current_stream: AudioStream = null

## Segment-driven playback state
var _current_item: Dictionary = {}
var _current_segment_index: int = 0
var _current_segment: Dictionary = {}

var _lifecycle_volume_db: float = 0.0
var _duck_volume_db: float = 0.0
var _contamination_volume_db: float = 0.0

var _fade_tween: Tween = null
var _fade_generation: int = 0

var _duck_tween: Tween = null
var _duck_generation: int = 0

func _init(director: RefCounted = null) -> void:
	if director:
		_director = director
	else:
		_director = RadioProgramDirectorScript.new()

func _ready() -> void:
	_ensure_player()

func _ensure_player() -> void:
	if not _player:
		_player = AudioStreamPlayer.new()
		_player.name = "RadioAudioStreamPlayer"
		_player.bus = "Master"
		add_child(_player)
		_player.finished.connect(_on_stream_finished)
		_update_composed_volume()

func _exit_tree() -> void:
	reset()

func get_director() -> RefCounted:
	return _director

func is_playing() -> bool:
	return _is_playing

func is_paused() -> bool:
	return _is_paused

func get_current_item() -> Dictionary:
	return _current_item

func get_current_segment_index() -> int:
	return _current_segment_index

func get_current_segment() -> Dictionary:
	return _current_segment

func get_current_phase() -> int:
	if not _current_segment.is_empty():
		return _current_segment.get("phase", RadioStationCatalogScript.Phase.BODY)
	return -1

func get_playback_position() -> float:
	if _player and _player.is_playing():
		return _player.get_playback_position()
	elif _director:
		return _director.get_cursor_position()
	return 0.0

# -----------------------------------------------------------------------------
# THREE-LAYER GAIN COMPOSITION (LIFECYCLE FADE + MIX DUCKING + HYBRID CONTAMINATION)
# -----------------------------------------------------------------------------

func _update_composed_volume() -> void:
	if _player:
		if _lifecycle_volume_db <= -70.0:
			_player.volume_db = -80.0
		else:
			_player.volume_db = clampf(_lifecycle_volume_db + _duck_volume_db + _contamination_volume_db, -80.0, 6.0)

func get_lifecycle_volume_db() -> float:
	return _lifecycle_volume_db

func get_duck_volume_db() -> float:
	return _duck_volume_db

func get_contamination_volume_db() -> float:
	return _contamination_volume_db

func get_composed_volume_db() -> float:
	if _lifecycle_volume_db <= -70.0:
		return -80.0
	return clampf(_lifecycle_volume_db + _duck_volume_db + _contamination_volume_db, -80.0, 6.0)

func _set_lifecycle_volume_db(vol: float) -> void:
	_lifecycle_volume_db = vol
	_update_composed_volume()

func _set_duck_volume_db(vol: float) -> void:
	_duck_volume_db = vol
	_update_composed_volume()

func set_contamination_volume_db(vol: float) -> void:
	_contamination_volume_db = vol
	_update_composed_volume()

func _cancel_radio_fade() -> void:
	_fade_generation += 1
	if _fade_tween and _fade_tween.is_valid():
		_fade_tween.kill()
		_fade_tween = null

func _cancel_duck_tween() -> void:
	_duck_generation += 1
	if _duck_tween and _duck_tween.is_valid():
		_duck_tween.kill()
		_duck_tween = null

func is_duck_tweening() -> bool:
	return _duck_tween != null and _duck_tween.is_valid() and _duck_tween.is_running()

## Independent Ducking API for pursuit pressure / critical mix layers
func set_duck_volume_db(target_db: float, duration: float = 0.0) -> void:
	_cancel_duck_tween()
	var gen: int = _duck_generation
	_ensure_player()
	if duration > 0.0 and is_inside_tree():
		_duck_tween = create_tween()
		if _duck_tween:
			_duck_tween.tween_method(_set_duck_volume_db, _duck_volume_db, target_db, duration)
			_duck_tween.tween_callback(func():
				if _duck_generation == gen:
					_duck_volume_db = target_db
					_update_composed_volume()
			)
			return
	_duck_volume_db = target_db
	_update_composed_volume()

func play_station(station_id: String = RadioStationCatalogScript.DEFAULT_STATION_ID) -> void:
	_cancel_radio_fade()
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
	_current_segment_index = 0
	_play_current_segment()
	segment_started.emit(_current_item)

func _play_current_segment() -> void:
	_ensure_player()
	var segments: Array = _current_item.get("segments", [])
	if segments.is_empty() or _current_segment_index >= segments.size():
		advance_segment()
		return

	_current_segment = segments[_current_segment_index]
	var phase: int = _current_segment.get("phase", RadioStationCatalogScript.Phase.BODY)
	phase_changed.emit(phase, _current_item, _current_segment)

	var slot_id: String = _current_segment.get("semantic_slot_id", "")
	var stream: AudioStream = null

	# 1. Check sandboxed local reference resolver for this specific segment slot
	if not slot_id.is_empty() and AudioReferenceResolverScript.is_reference_enabled():
		stream = AudioReferenceResolverScript.resolve_stream(slot_id)

	# 2. Synthesize segment-specific procedural fallback if not overridden
	if not stream:
		stream = _synthesize_segment_audio(_current_item, _current_segment)

	_current_stream = stream
	if _player:
		_update_composed_volume()
		_player.stream = stream
		_player.play(0.0)

func _on_stream_finished() -> void:
	if not _is_playing or _is_paused:
		return

	var segments: Array = _current_item.get("segments", [])
	_current_segment_index += 1

	if _current_segment_index < segments.size():
		# Advance to next phase within the same song/item
		_play_current_segment()
	else:
		# Item completed all phases -> advance to next program item from director
		advance_segment()

func pause() -> void:
	if not _is_playing or _is_paused:
		return

	_cancel_radio_fade()
	_is_paused = true
	var cur_pos := 0.0
	if _player and _player.is_playing():
		cur_pos = _player.get_playback_position()
		_player.stop()

	_director.set_cursor_position(cur_pos)
	_director.set_paused(true)
	playback_state_changed.emit(_is_playing, _is_paused)

func resume() -> void:
	if not _is_playing or not _is_paused:
		return

	_cancel_radio_fade()
	_is_paused = false
	_director.set_paused(false)

	_ensure_player()
	if _player and _current_stream:
		var resume_pos: float = _director.get_cursor_position()
		_player.stream = _current_stream
		_update_composed_volume()
		_player.play(resume_pos)

	playback_state_changed.emit(_is_playing, _is_paused)

func fade_out_and_pause(duration: float = 0.20) -> void:
	if not _is_playing or _is_paused:
		return
	_cancel_radio_fade()
	var gen: int = _fade_generation
	_ensure_player()
	if is_inside_tree() and _player:
		_fade_tween = create_tween()
		if _fade_tween:
			_fade_tween.tween_method(_set_lifecycle_volume_db, _lifecycle_volume_db, -80.0, maxf(0.01, duration))
			_fade_tween.tween_callback(func():
				if _fade_generation == gen:
					pause()
					_lifecycle_volume_db = 0.0
					_update_composed_volume()
			)
			return
	pause()
	_lifecycle_volume_db = 0.0
	_update_composed_volume()

func fade_in_and_resume(duration: float = 0.18) -> void:
	_cancel_radio_fade()
	var gen: int = _fade_generation
	_ensure_player()
	if not _is_playing:
		play_station(_director.get_station_id() if _director else RadioStationCatalogScript.DEFAULT_STATION_ID)
	elif _is_paused:
		resume()

	_lifecycle_volume_db = -80.0
	_update_composed_volume()

	if is_inside_tree() and _player:
		_fade_tween = create_tween()
		if _fade_tween:
			_fade_tween.tween_method(_set_lifecycle_volume_db, -80.0, 0.0, maxf(0.01, duration))
			_fade_tween.tween_callback(func():
				if _fade_generation == gen:
					_lifecycle_volume_db = 0.0
					_update_composed_volume()
			)
			return
	_lifecycle_volume_db = 0.0
	_update_composed_volume()

func stop() -> void:
	_cancel_radio_fade()
	_is_playing = false
	_is_paused = false
	_current_item = {}
	_current_segment_index = 0
	_current_segment = {}
	if _player:
		_player.stop()
		_player.stream = null
	_current_stream = null
	_lifecycle_volume_db = 0.0
	_update_composed_volume()
	playback_state_changed.emit(_is_playing, _is_paused)

func reset() -> void:
	stop()
	_cancel_duck_tween()
	_duck_volume_db = 0.0
	_lifecycle_volume_db = 0.0
	_update_composed_volume()
	if _director:
		_director.reset()

func _process(_delta: float) -> void:
	if _is_playing and not _is_paused and _player and _player.is_playing():
		_director.set_cursor_position(_player.get_playback_position())

# -----------------------------------------------------------------------------
# PROCEDURAL SEGMENT SYNTHESIS
# -----------------------------------------------------------------------------

func _synthesize_segment_audio(item: Dictionary, segment: Dictionary) -> AudioStreamWAV:
	var category: int = item.get("category", RadioStationCatalogScript.Category.SONG)
	var phase: int = segment.get("phase", RadioStationCatalogScript.Phase.BODY)
	var duration: float = segment.get("duration_sec", 2.0)
	var freq: float = segment.get("base_freq_hz", item.get("base_freq_hz", 440.0))

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
						var filter_env := clampf(t / maxf(0.01, duration), 0.0, 1.0)
						sample_val = sin(t * freq * TAU) * 0.4 * filter_env
					RadioStationCatalogScript.Phase.BODY:
						var beat := sin(t * 8.0 * PI) * 0.3
						var tone := sin(t * freq * TAU) * 0.5
						var sub := sin(t * (freq * 0.5) * TAU) * 0.2
						sample_val = (tone + sub) * (0.7 + beat)
					RadioStationCatalogScript.Phase.OUTRO:
						var fade := clampf(1.0 - (t / maxf(0.01, duration)), 0.0, 1.0)
						sample_val = sin(t * freq * TAU) * 0.4 * fade

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
