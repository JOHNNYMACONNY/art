class_name YardlineMusicAudioProductionContract
extends RefCounted

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const UIAudioSemanticRegistryScript = preload("res://scripts/audio/ui_audio_semantic_registry.gd")
const SelectionLockScript = preload("res://tests/yardline_music_selection_lock.gd")

const TARGETS: Array[Dictionary] = [
	{
		"slot": "radio.yardline.song_01.intro",
		"production_path": "res://audio/radio/yardline/music/sfx_radio_song01_intro.wav",
		"provenance": "GTA_SA:GENRL:BANK_81:SOUND_2",
		"rate": 18000,
		"frames": 15393,
		"channels": 1,
		"bit_depth": 16,
		"duration": 0.8552,
		"container_sha256": "463d61099f4210a4472f349b08e9f2b1d11d03a57860c45cbb2215b1ceb93d4a",
		"raw_pcm_sha256": "7148e41f97a8306476ac33309a7f9b772be1365b60ad3955fadb17d85dfc7e2d",
		"is_looping": false,
	},
	{
		"slot": "radio.yardline.song_01.body",
		"production_path": "res://audio/radio/yardline/music/sfx_radio_song01_body.wav",
		"provenance": "GTA_SA:GENRL:BANK_81:SOUND_0",
		"rate": 18000,
		"frames": 49756,
		"channels": 1,
		"bit_depth": 16,
		"duration": 2.7642,
		"container_sha256": "0c4b46c7ce33871bf55aa120605f1a07a64752eb9f4ae3e9dec109e210b544cb",
		"raw_pcm_sha256": "45eac308b2f4482581be0a2b7b92fe032a4a6d051786ac6df638fbef2d3312e6",
		"is_looping": false,
	},
	{
		"slot": "radio.yardline.song_01.outro",
		"production_path": "res://audio/radio/yardline/music/sfx_radio_song01_outro.wav",
		"provenance": "GTA_SA:GENRL:BANK_81:SOUND_1",
		"rate": 18000,
		"frames": 28699,
		"channels": 1,
		"bit_depth": 16,
		"duration": 1.5944,
		"container_sha256": "71871186feaf1c379fc05ad6c68e0fd9d818fef54e521c3ad0bb7c65dc8f0ecc",
		"raw_pcm_sha256": "c52ce1a17a7287ba85aa246830bbb632483c623f7077284d2cfdf8f8bb04f345",
		"is_looping": false,
	},
	{
		"slot": "radio.yardline.song_02.body",
		"production_path": "res://audio/radio/yardline/music/sfx_radio_song02_body.wav",
		"provenance": "GTA_SA:GENRL:BANK_87:SOUND_0",
		"rate": 18000,
		"frames": 70756,
		"channels": 1,
		"bit_depth": 16,
		"duration": 3.9309,
		"container_sha256": "9983f5a3fc405249cbd4c8869ab07e20e800ef8f583ccee2c56fb0d03983a2d5",
		"raw_pcm_sha256": "ae4890dcbd4107b0d831c146dbeacb6b31d5a0c65436f9dc00079db9bab0ee72",
		"is_looping": false,
	},
	{
		"slot": "radio.yardline.song_03.body",
		"production_path": "res://audio/radio/yardline/music/sfx_radio_song03_body.wav",
		"provenance": "GTA_SA:GENRL:BANK_89:SOUND_0",
		"rate": 18000,
		"frames": 50596,
		"channels": 1,
		"bit_depth": 16,
		"duration": 2.8109,
		"container_sha256": "ae362bb8ed4532df469790ad91578a8e9f5efb625e2a3a2939b5a8a297d95708",
		"raw_pcm_sha256": "856218a9fa55c79faedafc9a64c505ff09a5796147b67d5df2d972dd06541690",
		"is_looping": false,
	},
	{
		"slot": "radio.yardline.song_04.body",
		"production_path": "res://audio/radio/yardline/music/sfx_radio_song04_body.wav",
		"provenance": "GTA_SA:GENRL:BANK_99:SOUND_0",
		"rate": 18000,
		"frames": 54852,
		"channels": 1,
		"bit_depth": 16,
		"duration": 3.0473,
		"container_sha256": "03256ce856bafbfdfdfb742993c82cf34d8e99b48363a9b154e8d44c955f08b1",
		"raw_pcm_sha256": "50f51523c7066d3497dcbe86b8f505976b4b2f005dc208983f61b75c9b906d64",
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

	if licensed_count != 49:
		return "Combined LICENSED_FINAL count mismatch: expected 49, found %d" % licensed_count
	if procedural_count != 0:
		return "Combined PROCEDURAL_FALLBACK count mismatch: expected 0, found %d" % procedural_count

	var backlog := AudioRegistryScript.get_replacement_backlog()
	if not backlog.is_empty():
		return "Replacement backlog must be empty after 01Q final promotion, found %d items" % backlog.size()

	var expected_slots: Array[String] = []
	for target in TARGETS:
		expected_slots.append(String(target["slot"]))
	expected_slots.sort()
	var lock_slots := SelectionLockScript.get_all_slots()
	lock_slots.sort()
	if expected_slots != lock_slots:
		return "01Q production contract target set must exactly match SelectionLock target set"

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
