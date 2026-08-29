extends RefCounted

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const UIAudioSemanticRegistryScript = preload("res://scripts/audio/ui_audio_semantic_registry.gd")
const SelectionLockScript = preload("res://tests/tactical_pack_selection_lock.gd")

const TARGETS: Array[Dictionary] = [
	{
		"slot": "interaction.panel_pry",
		"production_path": "res://audio/interaction/sfx_interaction_panel_pry.wav",
		"provenance": "GTA_SA:GENRL:BANK_76:SOUND_2",
		"rate": 18000,
		"frames": 17463,
		"channels": 1,
		"bit_depth": 16,
		"duration": 0.9702,
		"peak_db": -2.0,
		"rms_db": -14.68,
		"container_sha256": "dbe6ee0c8eb57018e4b43ad2ebb40602bce45e21a3592061a0800c2a76f4a13b",
		"raw_pcm_sha256": "2b39bb47f1da6a037c3ddd9c16f07f3e1a657a2e7d7ea4937cb8d5ac62277fc8",
		"is_looping": false,
	},
	{
		"slot": "interaction.wire_clip",
		"production_path": "res://audio/interaction/sfx_interaction_wire_clip.wav",
		"provenance": "GTA_SA:GENRL:BANK_143:SOUND_17",
		"rate": 23000,
		"frames": 1999,
		"channels": 1,
		"bit_depth": 16,
		"duration": 0.0869,
		"peak_db": -1.97,
		"rms_db": -10.11,
		"container_sha256": "8957d4026569878f41d08ff1bcfa63906214d4c5701c083646841935d034d50b",
		"raw_pcm_sha256": "1418770fc0089bf5e309c13c1efe0f275c967ae4dc5feb433b104b560d64263d",
		"is_looping": false,
	},
	{
		"slot": "interaction.battery_insert",
		"production_path": "res://audio/interaction/sfx_interaction_battery_insert.wav",
		"provenance": "GTA_SA:GENRL:BANK_45:SOUND_1",
		"rate": 18000,
		"frames": 13804,
		"channels": 1,
		"bit_depth": 16,
		"duration": 0.7669,
		"peak_db": -2.04,
		"rms_db": -12.1,
		"container_sha256": "ff79a2e2810579ce890cd1af208dcd48f38be5cf5212423d099211b380e79f1d",
		"raw_pcm_sha256": "495f76eaab687d1036d7424138c400724ec1a629c2cdfff5df931697bebd49ca",
		"is_looping": false,
	},
	{
		"slot": "pursuit.pursuer_sweep",
		"production_path": "res://audio/pursuit/loop_pursuit_scanner_sweep.wav",
		"provenance": "GTA_SA:GENRL:BANK_138:SOUND_43",
		"rate": 20900,
		"frames": 8041,
		"channels": 1,
		"bit_depth": 16,
		"duration": 0.3847,
		"peak_db": -2.0,
		"rms_db": -20.98,
		"container_sha256": "46a40bebd9f3b390863dc4e1c472bd4cf14800b46f510539696c2ed796312093",
		"raw_pcm_sha256": "5e4808d31142881192f1273dfef7cb304a694bb597c9e2fac6afc6d56edb4d80",
		"is_looping": true,
	},
	{
		"slot": "world.radio_chatter",
		"production_path": "res://audio/world/sfx_world_radio_chatter.wav",
		"provenance": "GTA_SA:SCRIPT:BANK_356:SOUND_16",
		"rate": 15000,
		"frames": 9909,
		"channels": 1,
		"bit_depth": 16,
		"duration": 0.6606,
		"peak_db": -2.0,
		"rms_db": -14.36,
		"container_sha256": "93358b3a23f17aeefdc8b5d10f4608e4c7f2c1fa507564d12bb32688ca147b49",
		"raw_pcm_sha256": "621aa1348b7d2e9bcdf40d10658e97b456ef594c925e983102a83342e5cc3c0b",
		"is_looping": false,
	},
]

const REQUIRED_IMPORT_SETTINGS: Array[String] = [
	"force/8_bit=false",
	"force/mono=false",
	"force/max_rate=false",
	"edit/trim=false",
	"edit/normalize=false",
	"edit/loop_mode=0",
	"compress/mode=0",
]

static func _verify_import_settings(prod_path: String) -> String:
	var import_path := "%s.import" % prod_path
	if not FileAccess.file_exists(import_path):
		return "production import sidecar missing: %s" % import_path
	var import_text := FileAccess.get_file_as_string(import_path)
	for required_setting in REQUIRED_IMPORT_SETTINGS:
		if not import_text.contains(required_setting):
			return "production import sidecar %s missing %s" % [import_path, required_setting]
	return ""

static func _verify_slot(target: Dictionary) -> String:
	var slot_id: String = String(target["slot"])
	if not AudioRegistryScript.has_slot(slot_id):
		return "AudioRegistry missing slot %s" % slot_id

	var slot_meta: Dictionary = AudioRegistryScript.get_slot(slot_id)
	if slot_meta.get("asset_status") != AudioRegistryScript.AssetStatus.LICENSED_FINAL:
		return "%s asset_status must be LICENSED_FINAL" % slot_id
	if bool(slot_meta.get("replacement_required", true)):
		return "%s replacement_required must be false" % slot_id
	if AudioRegistryScript.is_reference_allowed_for_status(int(slot_meta.get("asset_status", -1))):
		return "%s LICENSED_FINAL slot must reject local reference override" % slot_id

	var path: String = AudioRegistryScript.get_production_asset_path(slot_id)
	if path != String(target.get("production_path", "")):
		return "%s production_asset_path mismatch" % slot_id
	if AudioRegistryScript.get_source_provenance(slot_id) != String(target.get("provenance", "")):
		return "%s source_provenance mismatch" % slot_id

	var lock: Dictionary = SelectionLockScript.get_selection(slot_id)
	if lock.is_empty():
		return "%s selection lock missing" % slot_id
	if String(lock.get("production_path", "")) != String(target.get("production_path", "")):
		return "%s lock production path mismatch" % slot_id
	if String(lock.get("winner_provenance", "")) != String(target.get("provenance", "")):
		return "%s lock provenance mismatch" % slot_id
	if int(lock.get("winner_sample_rate", 0)) != int(target.get("rate", 0)):
		return "%s lock sample-rate mismatch" % slot_id
	if int(lock.get("winner_channels", 0)) != int(target.get("channels", 0)):
		return "%s lock channel-count mismatch" % slot_id
	if int(lock.get("winner_bit_depth", 0)) != int(target.get("bit_depth", 0)):
		return "%s lock bit-depth mismatch" % slot_id
	if int(lock.get("winner_frames", 0)) != int(target.get("frames", 0)):
		return "%s lock frame-count mismatch" % slot_id
	if absf(float(lock.get("winner_duration_sec", 0.0)) - float(target.get("duration", 0.0))) > 0.0001:
		return "%s lock duration mismatch" % slot_id
	if absf(float(lock.get("winner_peak_db", 0.0)) - float(target.get("peak_db", 0.0))) > 0.001:
		return "%s lock peak mismatch" % slot_id
	if absf(float(lock.get("winner_rms_db", 0.0)) - float(target.get("rms_db", 0.0))) > 0.001:
		return "%s lock RMS mismatch" % slot_id
	if String(lock.get("winner_container_sha256", "")) != String(target.get("container_sha256", "")):
		return "%s lock container SHA mismatch" % slot_id
	if String(lock.get("winner_raw_sha256", "")) != String(target.get("raw_pcm_sha256", "")):
		return "%s lock raw PCM SHA mismatch" % slot_id

	var import_err := _verify_import_settings(path)
	if not import_err.is_empty():
		return import_err

	var file_bytes := FileAccess.get_file_as_bytes(path)
	if file_bytes.is_empty():
		return "production WAV file missing or unreadable: %s" % path

	var actual_container_sha := FileAccess.get_sha256(path)
	if actual_container_sha != String(target.get("container_sha256", "")):
		return "%s container file SHA-256 mismatch: expected %s, got %s" % [slot_id, target.get("container_sha256", ""), actual_container_sha]

	var raw_pcm := _extract_raw_pcm_data(file_bytes)
	if raw_pcm.is_empty():
		return "%s failed to extract raw PCM data from %s" % [slot_id, path]
	var expected_raw_bytes := int(lock.get("winner_raw_bytes", 0))
	if raw_pcm.size() != expected_raw_bytes:
		return "%s raw PCM byte count mismatch: expected %d, got %d" % [slot_id, expected_raw_bytes, raw_pcm.size()]
	var bytes_per_frame := int(target.get("channels", 0)) * int(target.get("bit_depth", 0)) / 8
	if bytes_per_frame <= 0 or raw_pcm.size() % bytes_per_frame != 0:
		return "%s raw PCM byte count is not frame-aligned" % slot_id
	var actual_frames := raw_pcm.size() / bytes_per_frame
	if actual_frames != int(lock.get("winner_frames", 0)):
		return "%s raw PCM frame count mismatch: expected %d, got %d" % [slot_id, int(lock.get("winner_frames", 0)), actual_frames]

	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(raw_pcm)
	var actual_raw_sha := ctx.finish().hex_encode()
	if actual_raw_sha != String(target.get("raw_pcm_sha256", "")):
		return "%s raw PCM SHA-256 mismatch: expected %s, got %s" % [slot_id, target.get("raw_pcm_sha256", ""), actual_raw_sha]

	var stream := AudioStreamWAV.load_from_file(path)
	if stream == null or stream.data.is_empty():
		return "%s production WAV failed to load as non-empty AudioStreamWAV" % slot_id
	if stream.format != AudioStreamWAV.FORMAT_16_BITS:
		return "%s production WAV must remain PCM16" % slot_id
	if stream.stereo:
		return "%s production WAV must remain mono" % slot_id
	if stream.mix_rate != int(lock.get("winner_sample_rate", 0)):
		return "%s loaded sample-rate mismatch: expected %d, got %d" % [slot_id, int(lock.get("winner_sample_rate", 0)), stream.mix_rate]
	if stream.data.size() != expected_raw_bytes:
		return "%s loaded stream byte count mismatch: expected %d, got %d" % [slot_id, expected_raw_bytes, stream.data.size()]
	if absf(stream.get_length() - float(lock.get("winner_duration_sec", 0.0))) > 0.0005:
		return "%s loaded duration mismatch: expected %.4fs, got %.4fs" % [slot_id, float(lock.get("winner_duration_sec", 0.0)), stream.get_length()]

	return ""

static func verify() -> String:
	var audio_slots := AudioRegistryScript.get_all_slots()
	if audio_slots.size() != 42:
		return "AudioRegistry slot count mismatch: expected 42, found %d" % audio_slots.size()

	var ui_slots := UIAudioSemanticRegistryScript.get_all_slots()
	if ui_slots.size() != 7:
		return "UIAudioSemanticRegistry slot count mismatch: expected 7, found %d" % ui_slots.size()

	var total_slots := audio_slots.size() + ui_slots.size()
	if total_slots != 49:
		return "Total combined slot count mismatch: expected 49, found %d" % total_slots

	var licensed_count := 0
	var procedural_count := 0
	for s_id in audio_slots:
		var status: int = AudioRegistryScript.get_slot(s_id).get("asset_status", -1)
		if status == AudioRegistryScript.AssetStatus.LICENSED_FINAL:
			licensed_count += 1
		elif status == AudioRegistryScript.AssetStatus.PROCEDURAL_FALLBACK:
			procedural_count += 1

	for s_id in ui_slots:
		var status: int = UIAudioSemanticRegistryScript.get_slot(s_id).get("asset_status", -1)
		if status == AudioRegistryScript.AssetStatus.LICENSED_FINAL:
			licensed_count += 1
		elif status == AudioRegistryScript.AssetStatus.PROCEDURAL_FALLBACK:
			procedural_count += 1

	if licensed_count != 43:
		return "Combined LICENSED_FINAL count mismatch: expected 43, found %d" % licensed_count
	if procedural_count != 6:
		return "Combined PROCEDURAL_FALLBACK count mismatch: expected 6, found %d" % procedural_count

	var expected_slots: Array[String] = []
	for target in TARGETS:
		expected_slots.append(String(target["slot"]))
	expected_slots.sort()
	if expected_slots != SelectionLockScript.get_target_slots():
		return "01P production contract target set must exactly match SelectionLock target set"

	for target in TARGETS:
		var slot_err := _verify_slot(target)
		if not slot_err.is_empty():
			return slot_err

	return ""

static func _extract_raw_pcm_data(wav_bytes: PackedByteArray) -> PackedByteArray:
	if wav_bytes.size() < 44:
		return PackedByteArray()
	if wav_bytes[0] != 0x52 or wav_bytes[1] != 0x49 or wav_bytes[2] != 0x46 or wav_bytes[3] != 0x46:
		return PackedByteArray()
	var offset := 12
	while offset + 8 <= wav_bytes.size():
		var chunk_id := char(wav_bytes[offset]) + char(wav_bytes[offset + 1]) + char(wav_bytes[offset + 2]) + char(wav_bytes[offset + 3])
		var chunk_size := wav_bytes[offset + 4] | (wav_bytes[offset + 5] << 8) | (wav_bytes[offset + 6] << 16) | (wav_bytes[offset + 7] << 24)
		if chunk_id == "data":
			var start := offset + 8
			var end := mini(start + chunk_size, wav_bytes.size())
			return wav_bytes.slice(start, end)
		offset += 8 + chunk_size + (chunk_size % 2)
	return PackedByteArray()
