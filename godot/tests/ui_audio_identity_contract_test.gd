extends RefCounted

const UIAudioSemanticRegistryScript = preload("res://scripts/audio/ui_audio_semantic_registry.gd")
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

static func _latest_ui_stream(layer: Node) -> AudioStreamWAV:
	var snapshot: Dictionary = layer.call("snapshot")
	var player = snapshot.get("latest_player")
	if player == null or not is_instance_valid(player) or not (player.stream is AudioStreamWAV):
		return null
	return player.stream as AudioStreamWAV

static func _stream_hash(stream: AudioStreamWAV) -> int:
	return stream.data.hash() if stream else 0

static func verify(manager: Node, layer: Node) -> String:
	if manager == null or layer == null:
		return "UI audio contract requires AudioManager + UIAudioIdentityLayer"
	if not layer.has_method("play_semantic") or not layer.has_method("snapshot"):
		return "UIAudioIdentityLayer playback/diagnostic seam is absent"

	for slot_id in REQUIRED_UI_SLOTS:
		if not UIAudioSemanticRegistryScript.has_slot(slot_id):
			return "Required UI semantic slot is absent: %s" % slot_id
		var slot: Dictionary = UIAudioSemanticRegistryScript.get_slot(slot_id)
		if String(slot.get("domain", "")) != "UI":
			return "%s is not registered in the UI domain" % slot_id
		if String(slot.get("spatial_type", "")) != "NON_DIEGETIC_2D":
			return "%s is not non-diegetic 2D UI audio" % slot_id
		if String(slot.get("mix_group", "")) != "INCIDENTAL_UI":
			return "%s escaped the incidental UI mix group" % slot_id
		if String(slot.get("playback_type", "")) != "TRANSIENT":
			return "%s is not a bounded transient" % slot_id
		if int(slot.get("max_concurrency", 99)) > 3:
			return "%s allows excessive UI concurrency" % slot_id

	# Rapid navigation must stay cheap and fatigue-bounded. Immediate repeated
	# calls intentionally exercise cooldown collapse without a real-time sleep.
	manager.call("reset_audio_instant")
	layer.call("reset_accounting")
	for _i in range(40):
		layer.call("play_semantic", "ui.nav_move")
	var nav_snapshot: Dictionary = layer.call("snapshot")
	if int(nav_snapshot.get("active_voice_count", 99)) > 3:
		return "Rapid UI navigation exceeded the UI transient voice budget"
	if int(nav_snapshot.get("accepted_counts", {}).get("ui.nav_move", 99)) > 2:
		return "Rapid UI navigation was not sufficiently cooldown-throttled"

	# Confirm/back/reject need measurably different generated signatures. Clear
	# cooldown/voices between samples so this compares the actual procedural cue.
	var signature_hashes: Dictionary = {}
	for slot_id in ["ui.nav_confirm", "ui.nav_back", "ui.reject"]:
		manager.call("reset_audio_instant")
		layer.call("reset_accounting")
		layer.call("play_semantic", slot_id)
		var stream := _latest_ui_stream(layer)
		if stream == null or stream.data.is_empty():
			return "%s did not generate audible PCM" % slot_id
		signature_hashes[slot_id] = _stream_hash(stream)
	if signature_hashes["ui.nav_confirm"] == signature_hashes["ui.nav_back"] \
	or signature_hashes["ui.nav_confirm"] == signature_hashes["ui.reject"] \
	or signature_hashes["ui.nav_back"] == signature_hashes["ui.reject"]:
		return "Confirm/back/reject UI cues share the same PCM signature"

	# Incidental UI must yield completely during the two strongest gameplay
	# priority states instead of stacking more texture into the mix.
	manager.call("reset_audio_instant")
	layer.call("reset_accounting")
	manager.call("set_mix_state", AudioManagerScript.MixState.MEMORY_ECHO)
	var before_echo: Dictionary = layer.call("snapshot")
	layer.call("play_semantic", "ui.nav_move")
	var after_echo: Dictionary = layer.call("snapshot")
	if int(after_echo.get("accepted_total", 0)) != int(before_echo.get("accepted_total", 0)):
		return "Incidental UI navigation was not suppressed during Memory Echo"

	manager.call("reset_audio_instant")
	layer.call("reset_accounting")
	manager.call("set_pursuit_pressure", 7.0, Vector3.ZERO)
	var before_pursuit: Dictionary = layer.call("snapshot")
	layer.call("play_semantic", "ui.nav_confirm")
	var after_pursuit: Dictionary = layer.call("snapshot")
	if int(after_pursuit.get("accepted_total", 0)) != int(before_pursuit.get("accepted_total", 0)):
		return "Incidental UI confirmation was not suppressed during critical pursuit"

	# Authoritative reset must remove every registered UI voice. Accounting is
	# diagnostic state owned by the helper and is reset explicitly for test seams;
	# production correctness is voice lifecycle + cooldown pruning, not counters.
	manager.call("reset_audio_instant")
	layer.call("reset_accounting")
	layer.call("play_semantic", "ui.replay_retry_confirm")
	var pre_reset: Dictionary = layer.call("snapshot")
	if int(pre_reset.get("active_voice_count", 0)) <= 0:
		return "Replay/retry confirmation created no UI voice"
	manager.call("reset_audio_instant")
	var reset_snapshot: Dictionary = layer.call("snapshot")
	if int(reset_snapshot.get("active_voice_count", 99)) != 0:
		return "Authoritative reset left UI voices alive"

	return ""
