class_name YardlineMusicCandidateSelectionContract
extends RefCounted

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const UIAudioSemanticRegistryScript = preload("res://scripts/audio/ui_audio_semantic_registry.gd")
const RadioStationCatalogScript = preload("res://scripts/audio/radio/radio_station_catalog.gd")
const RadioProgramPlayerScript = preload("res://scripts/audio/radio/radio_program_player.gd")
const SelectionLockScript = preload("res://tests/yardline_music_selection_lock.gd")

const TARGETS: Array[Dictionary] = [
	{
		"slot": "radio.yardline.song_01.intro",
		"item_id": "song_01_scrap_pulse",
		"phase": RadioStationCatalogScript.Phase.INTRO,
		"fallback_duration": 0.5,
		"fallback_freq": 220.0,
		"production_path": "res://audio/radio/yardline/music/sfx_radio_song01_intro.wav",
		"winner_provenance": "GTA_SA:GENRL:BANK_81:SOUND_2",
		"winner_sample_rate": 18000,
		"winner_channels": 1,
		"winner_bit_depth": 16,
		"winner_frames": 15393,
		"winner_raw_bytes": 30786,
		"winner_duration_sec": 0.8552,
		"winner_container_sha256": "463d61099f4210a4472f349b08e9f2b1d11d03a57860c45cbb2215b1ceb93d4a",
		"winner_raw_sha256": "7148e41f97a8306476ac33309a7f9b772be1365b60ad3955fadb17d85dfc7e2d",
		"runner_up_provenance": "GTA_SA:GENRL:BANK_85:SOUND_3",
		"runner_up_sample_rate": 18021,
		"runner_up_frames": 8596,
		"runner_up_raw_bytes": 17192,
		"runner_up_duration_sec": 0.477,
		"runner_up_container_sha256": "cdfd972ac5becb94ca65d7b5ffcf65c165747f7b46221c7a19677f8a993960ec",
		"runner_up_raw_sha256": "6ea80c18b1a64a43f70ddc1b6799ac202232e9cf8a822773881a69981567f71d",
	},
	{
		"slot": "radio.yardline.song_01.body",
		"item_id": "song_01_scrap_pulse",
		"phase": RadioStationCatalogScript.Phase.BODY,
		"fallback_duration": 3.0,
		"fallback_freq": 220.0,
		"production_path": "res://audio/radio/yardline/music/sfx_radio_song01_body.wav",
		"winner_provenance": "GTA_SA:GENRL:BANK_81:SOUND_0",
		"winner_sample_rate": 18000,
		"winner_channels": 1,
		"winner_bit_depth": 16,
		"winner_frames": 49756,
		"winner_raw_bytes": 99512,
		"winner_duration_sec": 2.7642,
		"winner_container_sha256": "0c4b46c7ce33871bf55aa120605f1a07a64752eb9f4ae3e9dec109e210b544cb",
		"winner_raw_sha256": "45eac308b2f4482581be0a2b7b92fe032a4a6d051786ac6df638fbef2d3312e6",
		"runner_up_provenance": "GTA_SA:GENRL:BANK_73:SOUND_0",
		"runner_up_sample_rate": 18000,
		"runner_up_frames": 57344,
		"runner_up_raw_bytes": 114688,
		"runner_up_duration_sec": 3.1858,
		"runner_up_container_sha256": "d9bdbe992e3f5fd44442d9f1b36bb2817cf9dd86472a3214fee34ec1d2de92d5",
		"runner_up_raw_sha256": "63c1749b5681d9d49fcae6762f472ba7dc4ae6997e65d381163fe24a15c17aa0",
	},
	{
		"slot": "radio.yardline.song_01.outro",
		"item_id": "song_01_scrap_pulse",
		"phase": RadioStationCatalogScript.Phase.OUTRO,
		"fallback_duration": 0.5,
		"fallback_freq": 220.0,
		"production_path": "res://audio/radio/yardline/music/sfx_radio_song01_outro.wav",
		"winner_provenance": "GTA_SA:GENRL:BANK_81:SOUND_1",
		"winner_sample_rate": 18000,
		"winner_channels": 1,
		"winner_bit_depth": 16,
		"winner_frames": 28699,
		"winner_raw_bytes": 57398,
		"winner_duration_sec": 1.5944,
		"winner_container_sha256": "71871186feaf1c379fc05ad6c68e0fd9d818fef54e521c3ad0bb7c65dc8f0ecc",
		"winner_raw_sha256": "c52ce1a17a7287ba85aa246830bbb632483c623f7077284d2cfdf8f8bb04f345",
		"runner_up_provenance": "GTA_SA:GENRL:BANK_87:SOUND_1",
		"runner_up_sample_rate": 18000,
		"runner_up_frames": 16687,
		"runner_up_raw_bytes": 33374,
		"runner_up_duration_sec": 0.9271,
		"runner_up_container_sha256": "aef62db06c568c81e13051dbaa74d342f3bd3c1303d4ee90c998764560f44ad7",
		"runner_up_raw_sha256": "80cece894b93476bf2495bb1f474bfe072d1217fdbb8d8962e1a32130d0f1a38",
	},
	{
		"slot": "radio.yardline.song_02.body",
		"item_id": "song_02_neon_drift",
		"phase": RadioStationCatalogScript.Phase.BODY,
		"fallback_duration": 3.5,
		"fallback_freq": 261.63,
		"production_path": "res://audio/radio/yardline/music/sfx_radio_song02_body.wav",
		"winner_provenance": "GTA_SA:GENRL:BANK_87:SOUND_0",
		"winner_sample_rate": 18000,
		"winner_channels": 1,
		"winner_bit_depth": 16,
		"winner_frames": 70756,
		"winner_raw_bytes": 141512,
		"winner_duration_sec": 3.9309,
		"winner_container_sha256": "9983f5a3fc405249cbd4c8869ab07e20e800ef8f583ccee2c56fb0d03983a2d5",
		"winner_raw_sha256": "ae4890dcbd4107b0d831c146dbeacb6b31d5a0c65436f9dc00079db9bab0ee72",
		"runner_up_provenance": "GTA_SA:GENRL:BANK_103:SOUND_0",
		"runner_up_sample_rate": 18000,
		"runner_up_frames": 64568,
		"runner_up_raw_bytes": 129136,
		"runner_up_duration_sec": 3.5871,
		"runner_up_container_sha256": "338b031fb2b97cc8c5cd70fb0f26ac35ee48d07596d713b6c533a2d19b246c53",
		"runner_up_raw_sha256": "43ace378cec276c5102566927762029aa965c0979cbb3c1c1a52fae5192b7466",
	},
	{
		"slot": "radio.yardline.song_03.body",
		"item_id": "song_03_rust_groove",
		"phase": RadioStationCatalogScript.Phase.BODY,
		"fallback_duration": 3.5,
		"fallback_freq": 196.0,
		"production_path": "res://audio/radio/yardline/music/sfx_radio_song03_body.wav",
		"winner_provenance": "GTA_SA:GENRL:BANK_89:SOUND_0",
		"winner_sample_rate": 18000,
		"winner_channels": 1,
		"winner_bit_depth": 16,
		"winner_frames": 50596,
		"winner_raw_bytes": 101192,
		"winner_duration_sec": 2.8109,
		"winner_container_sha256": "ae362bb8ed4532df469790ad91578a8e9f5efb625e2a3a2939b5a8a297d95708",
		"winner_raw_sha256": "856218a9fa55c79faedafc9a64c505ff09a5796147b67d5df2d972dd06541690",
		"runner_up_provenance": "GTA_SA:GENRL:BANK_123:SOUND_1",
		"runner_up_sample_rate": 18000,
		"runner_up_frames": 63010,
		"runner_up_raw_bytes": 126020,
		"runner_up_duration_sec": 3.5006,
		"runner_up_container_sha256": "52911314915da56fb2d1aa87811cc6b19c004d9fc1335867a92d659f2756161f",
		"runner_up_raw_sha256": "3cc45fe9c876259e270ebf89dc1ee6ec9bbea02408e3ef02152c18e1fa463456",
	},
	{
		"slot": "radio.yardline.song_04.body",
		"item_id": "song_04_signal_loss",
		"phase": RadioStationCatalogScript.Phase.BODY,
		"fallback_duration": 3.5,
		"fallback_freq": 329.63,
		"production_path": "res://audio/radio/yardline/music/sfx_radio_song04_body.wav",
		"winner_provenance": "GTA_SA:GENRL:BANK_99:SOUND_0",
		"winner_sample_rate": 18000,
		"winner_channels": 1,
		"winner_bit_depth": 16,
		"winner_frames": 54852,
		"winner_raw_bytes": 109704,
		"winner_duration_sec": 3.0473,
		"winner_container_sha256": "03256ce856bafbfdfdfb742993c82cf34d8e99b48363a9b154e8d44c955f08b1",
		"winner_raw_sha256": "50f51523c7066d3497dcbe86b8f505976b4b2f005dc208983f61b75c9b906d64",
		"runner_up_provenance": "GTA_SA:GENRL:BANK_95:SOUND_0",
		"runner_up_sample_rate": 18000,
		"runner_up_frames": 57932,
		"runner_up_raw_bytes": 115864,
		"runner_up_duration_sec": 3.2184,
		"runner_up_container_sha256": "f0176c0fd3afd0e1bb069a9323d4d351485c90dd02d6d3d71734a9409292a0b9",
		"runner_up_raw_sha256": "553e1b9fd45ba38a70732a3304c6da10914a4ed013044ab8e4fb7b198dc6b795",
	},
]

static func _expected_slots() -> Array[String]:
	var result: Array[String] = []
	for target in TARGETS:
		result.append(String(target["slot"]))
	result.sort()
	return result

static func _verify_lock(target: Dictionary) -> String:
	var slot_id := String(target["slot"])
	var lock: Dictionary = SelectionLockScript.get_selection(slot_id)
	if lock.is_empty():
		return "%s missing selection lock entry" % slot_id

	for key in [
		"production_path",
		"winner_provenance",
		"winner_sample_rate",
		"winner_channels",
		"winner_bit_depth",
		"winner_frames",
		"winner_raw_bytes",
		"winner_duration_sec",
		"winner_container_sha256",
		"winner_raw_sha256",
		"runner_up_provenance",
		"runner_up_sample_rate",
		"runner_up_frames",
		"runner_up_raw_bytes",
		"runner_up_duration_sec",
		"runner_up_container_sha256",
		"runner_up_raw_sha256",
	]:
		if not lock.has(key):
			return "%s selection lock missing %s" % [slot_id, key]
		var expected = target[key]
		var actual = lock[key]
		if typeof(expected) == TYPE_FLOAT:
			if absf(float(actual) - float(expected)) > 0.0001:
				return "%s selection lock mismatch for %s" % [slot_id, key]
		elif str(actual) != str(expected):
			return "%s selection lock mismatch for %s" % [slot_id, key]

	if int(lock["winner_raw_bytes"]) != int(lock["winner_frames"]) * 2:
		return "%s winner raw byte count is not mono PCM16" % slot_id
	return ""

static func _verify_registry(target: Dictionary) -> String:
	var slot_id := String(target["slot"])
	if not AudioRegistryScript.has_slot(slot_id):
		return "AudioRegistry missing slot %s" % slot_id
	var meta: Dictionary = AudioRegistryScript.get_slot(slot_id)
	if meta.get("domain") != AudioRegistryScript.Domain.RADIO:
		return "%s domain must remain RADIO" % slot_id
	if meta.get("diegesis") != AudioRegistryScript.Diegesis.DIEGETIC:
		return "%s diegesis must remain DIEGETIC" % slot_id
	if meta.get("spatial_type") != AudioRegistryScript.SpatialType.NON_DIEGETIC_2D:
		return "%s spatial_type must remain NON_DIEGETIC_2D" % slot_id
	if meta.get("mix_group") != AudioRegistryScript.MixGroup.RADIO_MUSIC:
		return "%s mix_group must remain RADIO_MUSIC" % slot_id
	if meta.get("playback_type") != AudioRegistryScript.PlaybackType.TRANSIENT:
		return "%s playback_type must remain TRANSIENT" % slot_id
	if bool(meta.get("is_looping", true)):
		return "%s must remain non-looping" % slot_id
	if int(meta.get("max_concurrency", 0)) != 1:
		return "%s max_concurrency must remain 1" % slot_id
	if meta.get("asset_status") != AudioRegistryScript.AssetStatus.PROCEDURAL_FALLBACK:
		return "%s asset_status must remain PROCEDURAL_FALLBACK at candidate lock stage" % slot_id
	if not bool(meta.get("replacement_required", false)):
		return "%s replacement_required must remain true at candidate lock stage" % slot_id
	if not AudioRegistryScript.get_production_asset_path(slot_id).is_empty():
		return "%s production path must remain empty at candidate lock stage" % slot_id
	if not AudioRegistryScript.get_source_provenance(slot_id).is_empty():
		return "%s source provenance must remain empty at candidate lock stage" % slot_id
	var planned_path := String(target["production_path"])
	if FileAccess.file_exists(planned_path) or ResourceLoader.exists(planned_path):
		return "%s production WAV must not exist before ingestion authorization" % slot_id
	if FileAccess.file_exists("%s.import" % planned_path):
		return "%s production import sidecar must not exist before ingestion authorization" % slot_id
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

static func _raw_pcm_sha256(path: String) -> String:
	var wav_bytes := FileAccess.get_file_as_bytes(path)
	var raw_pcm := _extract_raw_pcm_data(wav_bytes)
	if raw_pcm.is_empty():
		return ""
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(raw_pcm)
	return ctx.finish().hex_encode()

static func _verify_collision_free() -> String:
	var winner_provenances: Dictionary = {}
	var winner_raw_hashes: Dictionary = {}
	for target in TARGETS:
		var slot_id := String(target["slot"])
		var provenance := String(target["winner_provenance"])
		var raw_hash := String(target["winner_raw_sha256"])
		if winner_provenances.has(provenance):
			return "%s winner provenance collides with %s" % [slot_id, winner_provenances[provenance]]
		if winner_raw_hashes.has(raw_hash):
			return "%s winner raw PCM collides with %s" % [slot_id, winner_raw_hashes[raw_hash]]
		winner_provenances[provenance] = slot_id
		winner_raw_hashes[raw_hash] = slot_id

	for existing_slot_id in AudioRegistryScript.get_all_slots().keys():
		var existing_meta: Dictionary = AudioRegistryScript.get_slot(String(existing_slot_id))
		if existing_meta.get("asset_status") != AudioRegistryScript.AssetStatus.LICENSED_FINAL:
			continue
		var existing_provenance := AudioRegistryScript.get_source_provenance(String(existing_slot_id))
		if not existing_provenance.is_empty() and winner_provenances.has(existing_provenance):
			return "%s winner provenance collides with promoted slot %s" % [winner_provenances[existing_provenance], existing_slot_id]
		var existing_path := AudioRegistryScript.get_production_asset_path(String(existing_slot_id))
		if existing_path.is_empty() or not FileAccess.file_exists(existing_path):
			continue
		var existing_raw_hash := _raw_pcm_sha256(existing_path)
		if existing_raw_hash.is_empty():
			return "failed to fingerprint promoted production asset %s" % existing_slot_id
		if winner_raw_hashes.has(existing_raw_hash):
			return "%s winner raw PCM collides with promoted slot %s" % [winner_raw_hashes[existing_raw_hash], existing_slot_id]

	for existing_slot_id in UIAudioSemanticRegistryScript.get_all_slots().keys():
		var existing_meta: Dictionary = UIAudioSemanticRegistryScript.get_slot(String(existing_slot_id))
		if existing_meta.get("asset_status") != AudioRegistryScript.AssetStatus.LICENSED_FINAL:
			continue
		var existing_provenance := UIAudioSemanticRegistryScript.get_source_provenance(String(existing_slot_id))
		if not existing_provenance.is_empty() and winner_provenances.has(existing_provenance):
			return "%s winner provenance collides with promoted UI slot %s" % [winner_provenances[existing_provenance], existing_slot_id]
		var existing_path := UIAudioSemanticRegistryScript.get_production_asset_path(String(existing_slot_id))
		if existing_path.is_empty() or not FileAccess.file_exists(existing_path):
			continue
		var existing_raw_hash := _raw_pcm_sha256(existing_path)
		if existing_raw_hash.is_empty():
			return "failed to fingerprint promoted UI production asset %s" % existing_slot_id
		if winner_raw_hashes.has(existing_raw_hash):
			return "%s winner raw PCM collides with promoted UI slot %s" % [winner_raw_hashes[existing_raw_hash], existing_slot_id]

	return ""

static func _find_segment(item: Dictionary, slot_id: String) -> Dictionary:
	for segment in item.get("segments", []):
		if String(segment.get("semantic_slot_id", "")) == slot_id:
			return segment
	return {}

static func _verify_catalog_and_fallback(program_player: Node, target: Dictionary) -> String:
	var slot_id := String(target["slot"])
	var item := RadioStationCatalogScript.get_item_by_id(
		RadioStationCatalogScript.DEFAULT_STATION_ID,
		String(target["item_id"])
	)
	if item.is_empty():
		return "%s catalog item missing" % slot_id
	if int(item.get("category", -1)) != RadioStationCatalogScript.Category.SONG:
		return "%s catalog item must remain SONG" % slot_id
	var segment := _find_segment(item, slot_id)
	if segment.is_empty():
		return "%s catalog segment routing missing" % slot_id
	if int(segment.get("phase", -1)) != int(target["phase"]):
		return "%s catalog phase changed" % slot_id
	if absf(float(segment.get("duration_sec", -1.0)) - float(target["fallback_duration"])) > 0.001:
		return "%s procedural fallback duration changed" % slot_id
	if absf(float(segment.get("base_freq_hz", -1.0)) - float(target["fallback_freq"])) > 0.01:
		return "%s procedural fallback frequency changed" % slot_id

	var stream := program_player.call("_synthesize_segment_audio", item, segment) as AudioStreamWAV
	if stream == null or stream.data.is_empty():
		return "%s procedural fallback did not synthesize" % slot_id
	if stream.format != AudioStreamWAV.FORMAT_16_BITS or stream.stereo:
		return "%s procedural fallback must remain mono PCM16" % slot_id
	if stream.mix_rate != 22050:
		return "%s procedural fallback mix rate changed" % slot_id
	if stream.loop_mode != AudioStreamWAV.LOOP_DISABLED:
		return "%s procedural fallback must remain non-looping" % slot_id
	if absf(stream.get_length() - float(target["fallback_duration"])) > 0.01:
		return "%s procedural fallback synthesized length changed" % slot_id
	return ""

static func verify() -> String:
	var actual_slots: Array[String] = []
	for slot_id in SelectionLockScript.get_all_slots():
		actual_slots.append(String(slot_id))
	actual_slots.sort()
	if actual_slots != _expected_slots():
		return "01Q selection lock must contain exactly the six authorized music slots"

	var collision_error := _verify_collision_free()
	if not collision_error.is_empty():
		return collision_error

	var station := RadioStationCatalogScript.get_station(RadioStationCatalogScript.DEFAULT_STATION_ID)
	if station.is_empty() or String(station.get("name", "")) != "YARDLINE 88.3":
		return "Yardline station identity changed"

	var program_player := RadioProgramPlayerScript.new()
	program_player.call("_ensure_player")
	if int(program_player.call("get_audio_stream_player_count")) != 1:
		program_player.free()
		return "RadioProgramPlayer must retain exactly one AudioStreamPlayer owner"

	for target in TARGETS:
		var err := _verify_lock(target)
		if not err.is_empty():
			program_player.free()
			return err
		err = _verify_registry(target)
		if not err.is_empty():
			program_player.free()
			return err
		err = _verify_catalog_and_fallback(program_player, target)
		if not err.is_empty():
			program_player.free()
			return err

	program_player.free()
	return ""
