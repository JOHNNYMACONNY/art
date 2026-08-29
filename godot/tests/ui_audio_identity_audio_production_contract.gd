extends RefCounted

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const UIAudioSemanticRegistryScript = preload("res://scripts/audio/ui_audio_semantic_registry.gd")
const SelectionLockScript = preload("res://tests/ui_audio_identity_selection_lock.gd")

const EXPECTED_SELECTIONS: Dictionary = {
	"ui.nav_move": {
		"path": "res://audio/ui/sfx_ui_nav_move.wav",
		"provenance": "GTA_SA:GENRL:BANK_143:SOUND_76",
		"sample_rate": 44100,
		"frames": 1302,
		"raw_bytes": 2604,
		"raw_sha256": "aa2141c9430efe3b245ee5b44157ab077ddd89d934655fa7961ffe275e41805c",
		"file_sha256": "15f58f00f0fc0ed737aa3ce70c7bc15836e146b1d296e16d989ae5d1eaaa7fe9",
	},
	"ui.nav_confirm": {
		"path": "res://audio/ui/sfx_ui_nav_confirm.wav",
		"provenance": "GTA_SA:GENRL:BANK_143:SOUND_77",
		"sample_rate": 44100,
		"frames": 2824,
		"raw_bytes": 5648,
		"raw_sha256": "0c669ad54e911728ab16b883cc555df3067c50e29ddc2910734f4b0c93d2bf27",
		"file_sha256": "6790e442ce044678298174b0b028a4ced0e5cc72d3a165d478b4d12e92448be5",
	},
	"ui.nav_back": {
		"path": "res://audio/ui/sfx_ui_nav_back.wav",
		"provenance": "GTA_SA:GENRL:BANK_143:SOUND_44",
		"sample_rate": 18000,
		"frames": 623,
		"raw_bytes": 1246,
		"raw_sha256": "061b9cc26d1e6af092267fc0b949d2573c81b0d8a57dbdf772de6485539faab2",
		"file_sha256": "b4f9abb16fd1e79407904dc44b55c4803f6ceb653c88c57986763cfd78835de7",
	},
	"ui.mode_switch": {
		"path": "res://audio/ui/sfx_ui_mode_switch.wav",
		"provenance": "GTA_SA:GENRL:BANK_143:SOUND_17",
		"sample_rate": 23000,
		"frames": 1999,
		"raw_bytes": 3998,
		"raw_sha256": "1418770fc0089bf5e309c13c1efe0f275c967ae4dc5feb433b104b560d64263d",
		"file_sha256": "8957d4026569878f41d08ff1bcfa63906214d4c5701c083646841935d034d50b",
	},
	"ui.reject": {
		"path": "res://audio/ui/sfx_ui_reject.wav",
		"provenance": "GTA_SA:GENRL:BANK_143:SOUND_4",
		"sample_rate": 22000,
		"frames": 2143,
		"raw_bytes": 4286,
		"raw_sha256": "04964bf39958d7a8489e05a177de7a36c466415b121524e3584043d01f0b09f5",
		"file_sha256": "24fff4d27aaf2f4125f7ef2acb93450596fb10042e28f41e1442a492dc33287b",
	},
	"ui.radio_station_step": {
		"path": "res://audio/ui/sfx_ui_radio_step.wav",
		"provenance": "GTA_SA:GENRL:BANK_143:SOUND_47",
		"sample_rate": 24000,
		"frames": 2381,
		"raw_bytes": 4762,
		"raw_sha256": "283cd247c21b3e3e6f05fab00d2aaf843bbbc87e6a8ba87569023894cc5e9d2f",
		"file_sha256": "f8c28c58a46875cfc6b4b50c515356332e2e4b03412243ba7d5f5dbc32ff6451",
	},
	"ui.replay_retry_confirm": {
		"path": "res://audio/ui/sfx_ui_replay_retry_confirm.wav",
		"provenance": "GTA_SA:GENRL:BANK_143:SOUND_73",
		"sample_rate": 26000,
		"frames": 2697,
		"raw_bytes": 5394,
		"raw_sha256": "eaff3fbad94ab16329f976307d94b6220452f4933cca4d847d67ed68afdf3c02",
		"file_sha256": "8df5b3b1fc615648b39ed2080cb5562252555c11ad7c00d9bbf66bc16cd7dc80",
	},
}

static func verify(manager: Node, layer: Node) -> String:
	if manager == null or layer == null:
		return "01N production guard requires AudioManager + UIAudioIdentityLayer"
	if not layer.has_method("_create_fallback_stream"):
		return "UIAudioIdentityLayer procedural fallback seam is absent"

	var expected_slots: Array[String] = []
	for slot_id in EXPECTED_SELECTIONS.keys():
		expected_slots.append(String(slot_id))
	expected_slots.sort()

	for slot_id in expected_slots:
		if not UIAudioSemanticRegistryScript.has_slot(slot_id):
			return "01N target slot missing from UI semantic registry: %s" % slot_id
		var meta: Dictionary = UIAudioSemanticRegistryScript.get_slot(slot_id)
		if int(meta.get("asset_status", -1)) != AudioRegistryScript.AssetStatus.LICENSED_FINAL:
			return "%s was not promoted to LICENSED_FINAL" % slot_id
		if bool(meta.get("replacement_required", true)):
			return "%s has replacement_required != false" % slot_id

		var exp_info: Dictionary = EXPECTED_SELECTIONS[slot_id]
		var prod_path: String = String(meta.get("production_asset_path", ""))
		if prod_path != String(exp_info["path"]):
			return "%s production asset path mismatch: %s vs %s" % [slot_id, prod_path, exp_info["path"]]
		var prov: String = String(meta.get("source_provenance", ""))
		if prov != String(exp_info["provenance"]):
			return "%s provenance mismatch: %s vs %s" % [slot_id, prov, exp_info["provenance"]]

		if not ResourceLoader.exists(prod_path):
			return "%s production resource does not exist: %s" % [slot_id, prod_path]

		var stream = load(prod_path)
		if not (stream is AudioStreamWAV):
			return "%s production stream is not AudioStreamWAV" % slot_id
		var wav := stream as AudioStreamWAV
		if wav.stereo:
			return "%s production WAV is stereo (expected mono)" % slot_id
		if int(wav.format) != AudioStreamWAV.FORMAT_16_BITS:
			return "%s production WAV format is not 16-bit PCM" % slot_id
		if int(wav.loop_mode) != 0:
			return "%s production WAV loop mode is not disabled" % slot_id
		if int(wav.mix_rate) != int(exp_info["sample_rate"]):
			return "%s mix rate mismatch: %d vs %d" % [slot_id, wav.mix_rate, exp_info["sample_rate"]]
		if wav.data.size() != int(exp_info["raw_bytes"]):
			return "%s raw byte size mismatch: %d vs %d" % [slot_id, wav.data.size(), exp_info["raw_bytes"]]

		# File SHA check
		var file_sha := FileAccess.get_sha256(prod_path)
		if file_sha != String(exp_info["file_sha256"]):
			return "%s file SHA256 mismatch: %s vs %s" % [slot_id, file_sha, exp_info["file_sha256"]]

		# Raw PCM SHA check
		var ctx := HashingContext.new()
		ctx.start(HashingContext.HASH_SHA256)
		ctx.update(wav.data)
		var pcm_sha := ctx.finish().hex_encode()
		if pcm_sha != String(exp_info["raw_sha256"]):
			return "%s raw PCM SHA256 mismatch: %s vs %s" % [slot_id, pcm_sha, exp_info["raw_sha256"]]

		# Verify fallback remains functional
		var fallback = layer.call("_create_fallback_stream", slot_id)
		if not (fallback is AudioStreamWAV):
			return "%s procedural fallback is not AudioStreamWAV" % slot_id

	return ""
