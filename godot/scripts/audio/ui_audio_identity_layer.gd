class_name UIAudioIdentityLayer
extends Node

# Audio 06 — centralized, bounded, low-fatigue UI audio owner.
# This layer is intentionally subordinate to AudioManager: it borrows the
# manager's synthesis/reference seams and registers every voice in the existing
# authoritative 2D transient array so reset_audio_instant() remains the single
# lifecycle owner.

const UIAudioSemanticRegistryScript = preload("res://scripts/audio/ui_audio_semantic_registry.gd")
const AudioReferenceResolverScript = preload("res://scripts/audio/audio_reference_resolver.gd")
const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")

const MAX_UI_VOICES: int = 3
const CRITICAL_MIX_STATES: Array[int] = [
	AudioManagerScript.MixState.EXTRACTION_IMPACT,
	AudioManagerScript.MixState.DISTURBANCE,
	AudioManagerScript.MixState.PURSUIT_PRESSURE,
	AudioManagerScript.MixState.ROUTE_SWITCH_IMPACT,
	AudioManagerScript.MixState.MEMORY_ECHO,
]

var _manager: Node = null
var _active_ui_players: Array[AudioStreamPlayer] = []
var _player_slots: Dictionary = {}
var _last_slot_timestamp_msec: Dictionary = {}
var _attempted_counts: Dictionary = {}
var _accepted_counts: Dictionary = {}
var _accepted_total: int = 0
var _latest_player: AudioStreamPlayer = null

func _ready() -> void:
	if _manager == null and get_parent() != null:
		configure(get_parent())

func configure(manager: Node) -> void:
	_manager = manager

func reset_accounting() -> void:
	_prune_invalid_players()
	_last_slot_timestamp_msec.clear()
	_attempted_counts.clear()
	_accepted_counts.clear()
	_accepted_total = 0

func snapshot() -> Dictionary:
	_prune_invalid_players()
	return {
		"active_voice_count": _active_ui_players.size(),
		"accepted_total": _accepted_total,
		"attempted_counts": _attempted_counts.duplicate(true),
		"accepted_counts": _accepted_counts.duplicate(true),
		"latest_player": _latest_player if is_instance_valid(_latest_player) and not _latest_player.is_queued_for_deletion() else null,
	}

func play_semantic(slot_id: String) -> bool:
	_prune_invalid_players()
	if _manager == null or not is_instance_valid(_manager):
		return false
	if not UIAudioSemanticRegistryScript.has_slot(slot_id):
		return false
	_attempted_counts[slot_id] = int(_attempted_counts.get(slot_id, 0)) + 1
	var meta: Dictionary = UIAudioSemanticRegistryScript.get_slot(slot_id)
	if _should_suppress(meta):
		return false

	var now: int = Time.get_ticks_msec()
	var cooldown_msec: int = maxi(0, int(meta.get("cooldown_msec", 0)))
	if cooldown_msec > 0 and _last_slot_timestamp_msec.has(slot_id):
		if now - int(_last_slot_timestamp_msec[slot_id]) < cooldown_msec:
			return false

	var max_slot_concurrency: int = clampi(int(meta.get("max_concurrency", 1)), 1, MAX_UI_VOICES)
	while _count_slot_voices(slot_id) >= max_slot_concurrency:
		if not _evict_oldest_slot_voice(slot_id):
			break
	while _active_ui_players.size() >= MAX_UI_VOICES:
		_evict_player(_active_ui_players.front())

	var stream: AudioStream = AudioReferenceResolverScript.resolve_stream(slot_id)
	if stream == null:
		stream = _create_fallback_stream(slot_id)
	if stream == null:
		return false

	var player := AudioStreamPlayer.new()
	player.name = "UI_%s" % slot_id.replace(".", "_")
	player.bus = &"Master"
	player.volume_db = float(meta.get("gain_db", -16.0))
	player.stream = stream
	add_child(player)
	_register_with_manager(player)
	_active_ui_players.append(player)
	_player_slots[player.get_instance_id()] = slot_id
	_latest_player = player
	_last_slot_timestamp_msec[slot_id] = now
	_accepted_counts[slot_id] = int(_accepted_counts.get(slot_id, 0)) + 1
	_accepted_total += 1
	player.finished.connect(_on_player_finished.bind(player.get_instance_id()))
	player.play()
	return true

func on_action_confirmed() -> void:
	play_semantic("ui.nav_confirm")

func on_core_confirmed() -> void:
	play_semantic("ui.nav_confirm")

func on_radio_toggle_requested() -> void:
	play_semantic("ui.mode_switch")

func on_radio_station_step_requested() -> void:
	play_semantic("ui.radio_station_step")

func on_replay_requested() -> void:
	play_semantic("ui.replay_retry_confirm")

func on_retry_requested() -> void:
	play_semantic("ui.replay_retry_confirm")

func _should_suppress(meta: Dictionary) -> bool:
	if bool(meta.get("critical_essential", false)):
		return false
	var pursuit_pressure: float = float(_manager.get("_current_pursuit_pressure"))
	if pursuit_pressure > 0.01:
		return true
	var mix_state: int = int(_manager.get("current_mix_state"))
	return mix_state in CRITICAL_MIX_STATES

func _create_fallback_stream(slot_id: String) -> AudioStream:
	match slot_id:
		"ui.nav_move":
			return _manager.call("_create_tone_wav", 430.0, 0.025, 0.12)
		"ui.nav_confirm":
			return _manager.call("_create_harmonic_chime_wav", 520.0, 780.0, 0.11, 0.22)
		"ui.nav_back":
			return _manager.call("_create_sweep_wav", 470.0, 260.0, 0.09, 0.16)
		"ui.mode_switch":
			return _manager.call("_create_sweep_wav", 300.0, 520.0, 0.10, 0.18)
		"ui.reject":
			return _manager.call("_create_dual_beep_wav", 145.0, 0.14, 0.20)
		"ui.radio_station_step":
			return _manager.call("_create_sweep_wav", 620.0, 760.0, 0.06, 0.14)
		"ui.replay_retry_confirm":
			return _manager.call("_create_harmonic_chime_wav", 330.0, 660.0, 0.16, 0.24)
		_:
			return null

func _register_with_manager(player: AudioStreamPlayer) -> void:
	var manager_active = _manager.get("_active_2d_transients")
	if manager_active is Array:
		manager_active.append(player)

func _remove_from_manager(player: AudioStreamPlayer) -> void:
	if _manager == null or not is_instance_valid(_manager):
		return
	var manager_active = _manager.get("_active_2d_transients")
	if manager_active is Array:
		manager_active.erase(player)

func _count_slot_voices(slot_id: String) -> int:
	var count := 0
	for player in _active_ui_players:
		if is_instance_valid(player) and not player.is_queued_for_deletion():
			if String(_player_slots.get(player.get_instance_id(), "")) == slot_id:
				count += 1
	return count

func _evict_oldest_slot_voice(slot_id: String) -> bool:
	for player in _active_ui_players:
		if is_instance_valid(player) and String(_player_slots.get(player.get_instance_id(), "")) == slot_id:
			_evict_player(player)
			return true
	return false

func _evict_player(player: AudioStreamPlayer) -> void:
	if player == null:
		return
	var player_id := player.get_instance_id() if is_instance_valid(player) else 0
	_active_ui_players.erase(player)
	_player_slots.erase(player_id)
	_remove_from_manager(player)
	if is_instance_valid(player):
		player.stop()
		player.queue_free()
	if _latest_player == player:
		_latest_player = null

func _on_player_finished(player_id: int) -> void:
	var obj = instance_from_id(player_id)
	if obj is AudioStreamPlayer:
		_evict_player(obj as AudioStreamPlayer)
	else:
		_player_slots.erase(player_id)
		_prune_invalid_players()

func _prune_invalid_players() -> void:
	for index in range(_active_ui_players.size() - 1, -1, -1):
		var player: AudioStreamPlayer = _active_ui_players[index]
		if not is_instance_valid(player) or player.is_queued_for_deletion():
			var player_id := player.get_instance_id() if is_instance_valid(player) else 0
			_active_ui_players.remove_at(index)
			_player_slots.erase(player_id)
			if _latest_player == player:
				_latest_player = null
