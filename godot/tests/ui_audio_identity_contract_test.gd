extends RefCounted

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")

const REQUIRED_UI_SLOTS := [
	"ui.nav_move",
	"ui.nav_confirm",
	"ui.nav_back",
	"ui.mode_switch",
	"ui.reject",
	"ui.radio_station_step",
	"ui.replay_retry_confirm",
]

static func _latest_ui_stream(manager: Node) -> AudioStreamWAV:
	var active: Array = manager.get("_active_2d_transients")
	if active.is_empty():
		return null
	var player := active.back() as AudioStreamPlayer
	if player == null or not (player.stream is AudioStreamWAV):
		return null
	return player.stream as AudioStreamWAV

static func _stream_hash(stream: AudioStreamWAV) -> int:
	return stream.data.hash() if stream else 0

static func verify(manager: Node) -> String:
	if manager == null:
		return "UI audio contract requires an AudioManager instance"
	if not manager.has_method("play_ui_semantic"):
		return "AudioManager UI semantic playback seam is absent"
	if not manager.has_method("get_ui_audio_snapshot"):
		return "AudioManager UI audio diagnostic snapshot is absent"

	for slot_id in REQUIRED_UI_SLOTS:
		if not AudioRegistryScript.has_slot(slot_id):
			return "Required UI semantic slot is absent: %s" % slot_id
		var slot: Dictionary = AudioRegistryScript.get_slot(slot_id)
		if int(slot.get("domain", -1)) != AudioRegistryScript.Domain.UI:
			return "%s is not registered in the UI domain" % slot_id
		if int(slot.get("spatial_type", -1)) != AudioRegistryScript.SpatialType.NON_DIEGETIC_2D:
			return "%s is not non-diegetic 2D UI audio" % slot_id
		if int(slot.get("mix_group", -1)) != AudioRegistryScript.MixGroup.INCIDENTAL_UI:
			return "%s escaped the incidental UI mix group" % slot_id
		if int(slot.get("playback_type", -1)) != AudioRegistryScript.PlaybackType.TRANSIENT:
			return "%s is not a bounded transient" % slot_id
		if int(slot.get("max_concurrency", 99)) > 3:
			return "%s allows excessive UI concurrency" % slot_id

	# Rapid navigation must stay cheap and fatigue-bounded. Immediate repeated
	# calls intentionally exercise cooldown collapse without a real-time sleep.
	manager.call("reset_audio_instant")
	for _i in range(40):
		manager.call("play_ui_semantic", "ui.nav_move")
	var nav_snapshot: Dictionary = manager.call("get_ui_audio_snapshot")
	if int(nav_snapshot.get("active_voice_count", 99)) > 3:
		return "Rapid UI navigation exceeded the UI transient voice budget"
	if int(nav_snapshot.get("accepted_counts", {}).get("ui.nav_move", 99)) > 2:
		return "Rapid UI navigation was not sufficiently cooldown-throttled"

	# Confirm/back/reject need measurably different generated signatures. Clear
	# cooldown/voices between samples so this compares the actual procedural cue.
	var signature_hashes: Dictionary = {}
	for slot_id in ["ui.nav_confirm", "ui.nav_back", "ui.reject"]:
		manager.call("reset_audio_instant")
		manager.call("play_ui_semantic", slot_id)
		var stream := _latest_ui_stream(manager)
		if stream == null or stream.data.is_empty():
			return "%s did not generate audible PCM" % slot_id
		signature_hashes[slot_id] = _stream_hash(stream)
	if signature_hashes.values().duplicate().size() != 3:
		return "Confirm/back/reject UI cues are not structurally distinct"
	if signature_hashes["ui.nav_confirm"] == signature_hashes["ui.nav_back"] \
	or signature_hashes["ui.nav_confirm"] == signature_hashes["ui.reject"] \
	or signature_hashes["ui.nav_back"] == signature_hashes["ui.reject"]:
		return "Confirm/back/reject UI cues share the same PCM signature"

	# Incidental UI must yield completely during the two strongest gameplay
	# priority states instead of stacking more texture into the mix.
	manager.call("reset_audio_instant")
	manager.call("set_mix_state", AudioManagerScript.MixState.MEMORY_ECHO)
	var before_echo: Dictionary = manager.call("get_ui_audio_snapshot")
	manager.call("play_ui_semantic", "ui.nav_move")
	var after_echo: Dictionary = manager.call("get_ui_audio_snapshot")
	if int(after_echo.get("accepted_total", 0)) != int(before_echo.get("accepted_total", 0)):
		return "Incidental UI navigation was not suppressed during Memory Echo"

	manager.call("reset_audio_instant")
	manager.call("set_pursuit_pressure", 7.0, Vector3.ZERO)
	var before_pursuit: Dictionary = manager.call("get_ui_audio_snapshot")
	manager.call("play_ui_semantic", "ui.nav_confirm")
	var after_pursuit: Dictionary = manager.call("get_ui_audio_snapshot")
	if int(after_pursuit.get("accepted_total", 0)) != int(before_pursuit.get("accepted_total", 0)):
		return "Incidental UI confirmation was not suppressed during critical pursuit"

	# Authoritative reset must remove every UI voice and all UI throttle/accounting state.
	manager.call("reset_audio_instant")
	manager.call("play_ui_semantic", "ui.replay_retry_confirm")
	var pre_reset: Dictionary = manager.call("get_ui_audio_snapshot")
	if int(pre_reset.get("active_voice_count", 0)) <= 0:
		return "Replay/retry confirmation created no UI voice"
	manager.call("reset_audio_instant")
	var reset_snapshot: Dictionary = manager.call("get_ui_audio_snapshot")
	if int(reset_snapshot.get("active_voice_count", 99)) != 0:
		return "Authoritative reset left UI voices alive"
	if int(reset_snapshot.get("accepted_total", 99)) != 0:
		return "Authoritative reset left UI event accounting behind"

	return ""
