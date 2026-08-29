extends RefCounted

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const UIAudioSemanticRegistryScript = preload("res://scripts/audio/ui_audio_semantic_registry.gd")
const SelectionLockScript = preload("res://tests/ui_audio_identity_selection_lock.gd")

# path, winner provenance, sample rate, frames, raw bytes, duration, peak, RMS,
# raw PCM SHA, runner-up provenance, runner-up sample rate, frames, duration.
const EXPECTED_SELECTIONS: Dictionary = {
	"ui.nav_move": ["res://audio/ui/sfx_ui_nav_move.wav", "GTA_SA:GENRL:BANK_143:SOUND_76", 44100, 1302, 2604, 0.0295, -11.50, -23.68, "aa2141c9430efe3b245ee5b44157ab077ddd89d934655fa7961ffe275e41805c", "GTA_SA:GENRL:BANK_138:SOUND_29", 44100, 840, 0.0190],
	"ui.nav_confirm": ["res://audio/ui/sfx_ui_nav_confirm.wav", "GTA_SA:GENRL:BANK_143:SOUND_77", 44100, 2824, 5648, 0.0640, -2.00, -18.02, "0c669ad54e911728ab16b883cc555df3067c50e29ddc2910734f4b0c93d2bf27", "GTA_SA:GENRL:BANK_143:SOUND_55", 19700, 1036, 0.0526],
	"ui.nav_back": ["res://audio/ui/sfx_ui_nav_back.wav", "GTA_SA:GENRL:BANK_143:SOUND_44", 18000, 623, 1246, 0.0346, -13.73, -22.95, "061b9cc26d1e6af092267fc0b949d2573c81b0d8a57dbdf772de6485539faab2", "GTA_SA:GENRL:BANK_143:SOUND_34", 22050, 1490, 0.0676],
	"ui.mode_switch": ["res://audio/ui/sfx_ui_mode_switch.wav", "GTA_SA:GENRL:BANK_143:SOUND_17", 23000, 1999, 3998, 0.0869, -1.97, -10.11, "1418770fc0089bf5e309c13c1efe0f275c967ae4dc5feb433b104b560d64263d", "GTA_SA:GENRL:BANK_143:SOUND_18", 23000, 2164, 0.0941],
	"ui.reject": ["res://audio/ui/sfx_ui_reject.wav", "GTA_SA:GENRL:BANK_143:SOUND_4", 22000, 2143, 4286, 0.0974, -3.00, -9.64, "04964bf39958d7a8489e05a177de7a36c466415b121524e3584043d01f0b09f5", "GTA_SA:GENRL:BANK_143:SOUND_71", 17600, 1711, 0.0972],
	"ui.radio_station_step": ["res://audio/ui/sfx_ui_radio_step.wav", "GTA_SA:GENRL:BANK_143:SOUND_47", 24000, 2381, 4762, 0.0992, -2.00, -17.26, "283cd247c21b3e3e6f05fab00d2aaf843bbbc87e6a8ba87569023894cc5e9d2f", "GTA_SA:GENRL:BANK_143:SOUND_50", 16000, 1589, 0.0993],
	"ui.replay_retry_confirm": ["res://audio/ui/sfx_ui_replay_retry_confirm.wav", "GTA_SA:GENRL:BANK_143:SOUND_73", 26000, 2697, 5394, 0.1037, -1.96, -14.16, "eaff3fbad94ab16329f976307d94b6220452f4933cca4d847d67ed68afdf3c02", "GTA_SA:GENRL:BANK_143:SOUND_84", 22400, 2975, 0.1328],
}

const EXPECTED_RUNTIME_POLICY: Dictionary = {
	"ui.nav_move": [55, 2, -18.0, false],
	"ui.nav_confirm": [90, 2, -14.0, false],
	"ui.nav_back": [90, 2, -16.0, false],
	"ui.mode_switch": [120, 1, -15.0, false],
	"ui.reject": [150, 1, -12.0, true],
	"ui.radio_station_step": [100, 2, -16.0, false],
	"ui.replay_retry_confirm": [160, 1, -11.0, true],
}

static func verify(manager: Node, layer: Node) -> String:
	if manager == null or layer == null:
		return "01N candidate guard requires AudioManager + UIAudioIdentityLayer"
	if not layer.has_method("_create_fallback_stream"):
		return "UIAudioIdentityLayer procedural fallback seam is absent"

	var locked_slots := SelectionLockScript.get_target_slots()
	var expected_slots: Array[String] = []
	for slot_id in EXPECTED_SELECTIONS.keys():
		expected_slots.append(String(slot_id))
	expected_slots.sort()
	if locked_slots != expected_slots:
		return "01N selection lock target set drifted: %s" % [locked_slots]
	if UIAudioSemanticRegistryScript.get_all_slots().size() != expected_slots.size():
		return "01N expects exactly seven UI semantic slots"

	var fallback_hashes: Dictionary = {}
	for slot_id in expected_slots:
		if not UIAudioSemanticRegistryScript.has_slot(slot_id):
			return "01N target slot missing from UI semantic registry: %s" % slot_id
		var meta: Dictionary = UIAudioSemanticRegistryScript.get_slot(slot_id)
		if String(meta.get("domain", "")) != "UI" \
		or String(meta.get("diegesis", "")) != "NON_DIEGETIC" \
		or String(meta.get("spatial_type", "")) != "NON_DIEGETIC_2D" \
		or String(meta.get("mix_group", "")) != "INCIDENTAL_UI" \
		or String(meta.get("playback_type", "")) != "TRANSIENT":
			return "%s escaped the locked incidental UI semantic policy" % slot_id
		if int(meta.get("asset_status", -1)) != AudioRegistryScript.AssetStatus.PROCEDURAL_FALLBACK:
			return "%s was promoted before 01N production ingestion authorization" % slot_id
		if not bool(meta.get("replacement_required", false)):
			return "%s cleared replacement_required before 01N production ingestion" % slot_id
		if not String(meta.get("production_asset_path", "")).is_empty() or not String(meta.get("source_provenance", "")).is_empty():
			return "%s gained production metadata during candidate selection" % slot_id

		var runtime_policy: Array = EXPECTED_RUNTIME_POLICY[slot_id]
		if int(meta.get("cooldown_msec", -1)) != int(runtime_policy[0]) \
		or int(meta.get("max_concurrency", -1)) != int(runtime_policy[1]) \
		or not is_equal_approx(float(meta.get("gain_db", 99.0)), float(runtime_policy[2])) \
		or bool(meta.get("critical_essential", false)) != bool(runtime_policy[3]):
			return "%s runtime UI mix/concurrency policy drifted during candidate selection" % slot_id

		var selection: Dictionary = SelectionLockScript.get_selection(slot_id)
		var expected: Array = EXPECTED_SELECTIONS[slot_id]
		if String(selection.get("production_path", "")) != String(expected[0]) \
		or String(selection.get("winner_provenance", "")) != String(expected[1]) \
		or int(selection.get("sample_rate_hz", 0)) != int(expected[2]) \
		or int(selection.get("frames", 0)) != int(expected[3]) \
		or int(selection.get("raw_bytes", 0)) != int(expected[4]) \
		or not is_equal_approx(float(selection.get("duration_sec", 0.0)), float(expected[5])) \
		or not is_equal_approx(float(selection.get("peak_db", 0.0)), float(expected[6])) \
		or not is_equal_approx(float(selection.get("rms_db", 0.0)), float(expected[7])) \
		or String(selection.get("raw_pcm_sha256", "")) != String(expected[8]) \
		or String(selection.get("runner_up_provenance", "")) != String(expected[9]) \
		or int(selection.get("runner_up_sample_rate_hz", 0)) != int(expected[10]) \
		or int(selection.get("runner_up_frames", 0)) != int(expected[11]) \
		or not is_equal_approx(float(selection.get("runner_up_duration_sec", 0.0)), float(expected[12])):
			return "%s winner/runner-up selection lock drifted" % slot_id
		if int(selection.get("channels", 0)) != 1 or int(selection.get("bit_depth", 0)) != 16:
			return "%s winner format is not locked to mono PCM16" % slot_id
		if int(selection.get("runner_up_channels", 0)) != 1 or int(selection.get("runner_up_bit_depth", 0)) != 16:
			return "%s runner-up format is not locked to mono PCM16" % slot_id
		if int(selection.get("raw_bytes", 0)) != int(selection.get("frames", 0)) * 2:
			return "%s raw byte count is inconsistent with mono PCM16 frames" % slot_id

		var production_path := String(selection.get("production_path", ""))
		if ResourceLoader.exists(production_path) or FileAccess.file_exists(production_path):
			return "%s production media exists before the 01N ingestion checkpoint" % slot_id

		var fallback = layer.call("_create_fallback_stream", slot_id)
		if not (fallback is AudioStreamWAV):
			return "%s procedural fallback is no longer independently reachable" % slot_id
		var wav := fallback as AudioStreamWAV
		if wav.data.is_empty() or wav.stereo or int(wav.loop_mode) != 0:
			return "%s procedural fallback is not a bounded mono transient" % slot_id
		var fallback_hash := hash(wav.data)
		if fallback_hashes.has(fallback_hash):
			return "%s procedural fallback collided with another 01N slot signature" % slot_id
		fallback_hashes[fallback_hash] = slot_id

	return ""
