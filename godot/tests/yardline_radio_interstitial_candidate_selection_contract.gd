extends RefCounted

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const RadioStationCatalogScript = preload("res://scripts/audio/radio/radio_station_catalog.gd")
const RadioProgramPlayerScript = preload("res://scripts/audio/radio/radio_program_player.gd")
const SelectionLockScript = preload("res://tests/yardline_radio_interstitial_selection_lock.gd")

const TARGETS: Array[Dictionary] = [
	{
		"slot": "radio.yardline.dj_link_intro",
		"item_id": "dj_01_track_intro",
		"category": RadioStationCatalogScript.Category.DJ_LINK,
		"context": "INTRO",
		"duration": 1.2,
		"base_freq_hz": 440.0,
		"production_path": "res://audio/radio/rad_yardline_dj_link_intro.wav",
		"winner_provenance": "GTA_SA:GENRL:BANK_84:SOUND_0",
		"winner_sample_rate": 11025,
		"winner_frames": 54096,
		"winner_duration_sec": 4.9067,
		"winner_peak_db": -1.78,
		"winner_rms_db": -13.15,
		"winner_raw_sha256": "8d1b2f2d7f6fdef285619f5092642dfff17fd85b7d1b2091ad546e865c35b526",
		"runner_up_provenance": "GTA_SA:GENRL:BANK_65:SOUND_0",
		"runner_up_sample_rate": 18000,
		"runner_up_frames": 73045,
		"runner_up_duration_sec": 4.0581,
	},
	{
		"slot": "radio.yardline.dj_link_outro",
		"item_id": "dj_02_track_outro",
		"category": RadioStationCatalogScript.Category.DJ_LINK,
		"context": "OUTRO",
		"duration": 1.0,
		"base_freq_hz": 440.0,
		"production_path": "res://audio/radio/rad_yardline_dj_link_outro.wav",
		"winner_provenance": "GTA_SA:GENRL:BANK_84:SOUND_1",
		"winner_sample_rate": 11025,
		"winner_frames": 30855,
		"winner_duration_sec": 2.7986,
		"winner_peak_db": -2.04,
		"winner_rms_db": -13.97,
		"winner_raw_sha256": "8aae0b29afb325f841a404fd8925ce1e9cd58510dd1eada70d13fd0c3290b0f0",
		"runner_up_provenance": "GTA_SA:GENRL:BANK_130:SOUND_0",
		"runner_up_sample_rate": 18000,
		"runner_up_frames": 12179,
		"runner_up_duration_sec": 0.6766,
	},
	{
		"slot": "radio.yardline.advert_01",
		"item_id": "ad_01_scrap_parts",
		"category": RadioStationCatalogScript.Category.ADVERT,
		"context": "",
		"duration": 1.5,
		"base_freq_hz": 350.0,
		"production_path": "res://audio/radio/rad_yardline_advert_01.wav",
		"winner_provenance": "GTA_SA:GENRL:BANK_82:SOUND_0",
		"winner_sample_rate": 28000,
		"winner_frames": 277088,
		"winner_duration_sec": 9.896,
		"winner_peak_db": -0.80,
		"winner_rms_db": -16.69,
		"winner_raw_sha256": "e4d4d6da12ce7672ba48e55f3313fad7996d4fcf151d3021b19d666cb731dd1c",
		"runner_up_provenance": "GTA_SA:GENRL:BANK_82:SOUND_2",
		"runner_up_sample_rate": 28000,
		"runner_up_frames": 277172,
		"runner_up_duration_sec": 9.899,
	},
	{
		"slot": "radio.yardline.advert_02",
		"item_id": "ad_02_courier_rations",
		"category": RadioStationCatalogScript.Category.ADVERT,
		"context": "",
		"duration": 1.5,
		"base_freq_hz": 380.0,
		"production_path": "res://audio/radio/rad_yardline_advert_02.wav",
		"winner_provenance": "GTA_SA:GENRL:BANK_82:SOUND_4",
		"winner_sample_rate": 28000,
		"winner_frames": 277116,
		"winner_duration_sec": 9.897,
		"winner_peak_db": -2.86,
		"winner_rms_db": -16.54,
		"winner_raw_sha256": "2d3b2a11053b8aa57903d88a5bba0362e527712ac60f5024dfd1baf990084063",
		"runner_up_provenance": "GTA_SA:GENRL:BANK_82:SOUND_6",
		"runner_up_sample_rate": 28000,
		"runner_up_frames": 276724,
		"runner_up_duration_sec": 9.883,
	},
	{
		"slot": "radio.yardline.world_pursuit",
		"item_id": "world_01_pursuit_advisory",
		"category": RadioStationCatalogScript.Category.WORLD_REACTION,
		"context": "",
		"duration": 1.5,
		"base_freq_hz": 587.33,
		"production_path": "res://audio/radio/rad_yardline_world_pursuit.wav",
		"winner_provenance": "GTA_SA:GENRL:BANK_91:SOUND_0",
		"winner_sample_rate": 18000,
		"winner_frames": 17303,
		"winner_duration_sec": 0.9613,
		"winner_peak_db": -0.50,
		"winner_rms_db": -13.23,
		"winner_raw_sha256": "30384854c45363f4bd599ddecb65f7bbaf8df4a975319a7e44f5e12847f0cfc4",
		"runner_up_provenance": "GTA_SA:GENRL:BANK_81:SOUND_0",
		"runner_up_sample_rate": 18000,
		"runner_up_frames": 49756,
		"runner_up_duration_sec": 2.7642,
	},
	{
		"slot": "radio.yardline.world_gate",
		"item_id": "world_02_gate_activity",
		"category": RadioStationCatalogScript.Category.WORLD_REACTION,
		"context": "",
		"duration": 1.2,
		"base_freq_hz": 554.37,
		"production_path": "res://audio/radio/rad_yardline_world_gate.wav",
		"winner_provenance": "GTA_SA:GENRL:BANK_91:SOUND_1",
		"winner_sample_rate": 18000,
		"winner_frames": 58550,
		"winner_duration_sec": 3.2528,
		"winner_peak_db": -2.00,
		"winner_rms_db": -12.61,
		"winner_raw_sha256": "3b2069e92b5c5bac4722550e62054094eaf7d34e022858985e10a3ce5f08f8ee",
		"runner_up_provenance": "GTA_SA:GENRL:BANK_115:SOUND_1",
		"runner_up_sample_rate": 18000,
		"runner_up_frames": 21083,
		"runner_up_duration_sec": 1.1713,
	},
]

static func _verify_selection_lock(target: Dictionary) -> String:
	var slot_id: String = String(target["slot"])
	var selection: Dictionary = SelectionLockScript.get_selection(slot_id)
	if selection.is_empty():
		return "%s locked source selection missing" % slot_id
	if String(selection.get("production_path", "")) != String(target["production_path"]):
		return "%s production path lock changed" % slot_id
	if String(selection.get("winner_provenance", "")) != String(target["winner_provenance"]):
		return "%s winner provenance lock changed" % slot_id
	if int(selection.get("winner_sample_rate", 0)) != int(target["winner_sample_rate"]):
		return "%s winner sample-rate lock changed" % slot_id
	if int(selection.get("winner_channels", 0)) != 1:
		return "%s winner channel lock changed" % slot_id
	if int(selection.get("winner_bit_depth", 0)) != 16:
		return "%s winner bit-depth lock changed" % slot_id
	if int(selection.get("winner_frames", 0)) != int(target["winner_frames"]):
		return "%s winner frame-count lock changed" % slot_id
	if absf(float(selection.get("winner_duration_sec", 0.0)) - float(target["winner_duration_sec"])) > 0.0001:
		return "%s winner duration lock changed" % slot_id
	if absf(float(selection.get("winner_peak_db", 0.0)) - float(target["winner_peak_db"])) > 0.001:
		return "%s winner peak lock changed" % slot_id
	if absf(float(selection.get("winner_rms_db", 0.0)) - float(target["winner_rms_db"])) > 0.001:
		return "%s winner RMS lock changed" % slot_id
	if String(selection.get("winner_raw_sha256", "")) != String(target["winner_raw_sha256"]):
		return "%s winner raw SHA lock changed" % slot_id
	if String(selection.get("runner_up_provenance", "")) != String(target["runner_up_provenance"]):
		return "%s runner-up provenance lock changed" % slot_id
	if int(selection.get("runner_up_sample_rate", 0)) != int(target["runner_up_sample_rate"]):
		return "%s runner-up sample-rate lock changed" % slot_id
	if int(selection.get("runner_up_frames", 0)) != int(target["runner_up_frames"]):
		return "%s runner-up frame-count lock changed" % slot_id
	if absf(float(selection.get("runner_up_duration_sec", 0.0)) - float(target["runner_up_duration_sec"])) > 0.0001:
		return "%s runner-up duration lock changed" % slot_id
	return ""

static func _verify_registry_slot(target: Dictionary) -> String:
	var slot_id: String = String(target["slot"])
	var slot: Dictionary = AudioRegistryScript.get_slot(slot_id)
	if slot.is_empty():
		return "%s slot missing" % slot_id
	if slot.get("domain") != AudioRegistryScript.Domain.RADIO:
		return "%s domain changed" % slot_id
	if slot.get("diegesis") != AudioRegistryScript.Diegesis.DIEGETIC:
		return "%s diegesis changed" % slot_id
	if slot.get("spatial_type") != AudioRegistryScript.SpatialType.NON_DIEGETIC_2D:
		return "%s spatial type changed" % slot_id
	if slot.get("mix_group") != AudioRegistryScript.MixGroup.RADIO_MUSIC:
		return "%s mix group changed" % slot_id
	if slot.get("playback_type") != AudioRegistryScript.PlaybackType.TRANSIENT:
		return "%s playback type changed" % slot_id
	if bool(slot.get("is_looping", true)):
		return "%s must remain non-looping" % slot_id
	if int(slot.get("max_concurrency", 0)) != 1:
		return "%s max concurrency changed" % slot_id
	if slot.get("asset_status") != AudioRegistryScript.AssetStatus.PROCEDURAL_FALLBACK:
		return "%s must remain PROCEDURAL_FALLBACK at candidate selection checkpoint" % slot_id
	if not bool(slot.get("replacement_required", false)):
		return "%s replacement_required must remain true before media ingestion" % slot_id
	if not AudioRegistryScript.get_production_asset_path(slot_id).is_empty():
		return "%s production asset path must remain empty at candidate stage" % slot_id
	if not AudioRegistryScript.get_source_provenance(slot_id).is_empty():
		return "%s source provenance must remain empty at candidate stage" % slot_id
	var planned_path: String = String(target["production_path"])
	if FileAccess.file_exists(planned_path) or ResourceLoader.exists(planned_path):
		return "%s production media must remain absent before ingestion authorization" % slot_id
	if FileAccess.file_exists("%s.import" % planned_path):
		return "%s production import sidecar must remain absent before ingestion authorization" % slot_id
	return ""

static func _verify_catalog_target(target: Dictionary) -> String:
	var slot_id: String = String(target["slot"])
	var item: Dictionary = RadioStationCatalogScript.get_item_by_id(
		RadioStationCatalogScript.DEFAULT_STATION_ID,
		String(target["item_id"])
	)
	if item.is_empty():
		return "%s catalog item missing" % slot_id
	if int(item.get("category", -1)) != int(target["category"]):
		return "%s catalog category changed" % slot_id
	var expected_context: String = String(target["context"])
	if not expected_context.is_empty() and String(item.get("context", "")) != expected_context:
		return "%s catalog context changed" % slot_id
	var segments: Array = item.get("segments", [])
	if segments.size() != 1:
		return "%s must remain a single-segment interstitial" % slot_id
	var segment: Dictionary = segments[0]
	if int(segment.get("phase", -1)) != RadioStationCatalogScript.Phase.BODY:
		return "%s segment phase changed" % slot_id
	if String(segment.get("semantic_slot_id", "")) != slot_id:
		return "%s semantic slot routing changed" % slot_id
	if absf(float(segment.get("duration_sec", -1.0)) - float(target["duration"])) > 0.001:
		return "%s fallback duration changed" % slot_id
	if absf(float(segment.get("base_freq_hz", -1.0)) - float(target["base_freq_hz"])) > 0.01:
		return "%s fallback base frequency changed" % slot_id
	return ""

static func _verify_fallback_synthesis(program_player: Node, target: Dictionary) -> String:
	var slot_id: String = String(target["slot"])
	var item: Dictionary = RadioStationCatalogScript.get_item_by_id(
		RadioStationCatalogScript.DEFAULT_STATION_ID,
		String(target["item_id"])
	)
	var segment: Dictionary = item.get("segments", [])[0]
	var stream := program_player.call("_synthesize_segment_audio", item, segment) as AudioStreamWAV
	if stream == null:
		return "%s procedural fallback did not synthesize" % slot_id
	if stream.data.is_empty():
		return "%s procedural fallback contains no PCM data" % slot_id
	if stream.format != AudioStreamWAV.FORMAT_16_BITS:
		return "%s procedural fallback must remain PCM16" % slot_id
	if stream.stereo:
		return "%s procedural fallback must remain mono" % slot_id
	if stream.mix_rate != 22050:
		return "%s procedural fallback mix rate changed" % slot_id
	if stream.loop_mode != AudioStreamWAV.LOOP_DISABLED:
		return "%s procedural fallback must remain non-looping" % slot_id
	if absf(stream.get_length() - float(target["duration"])) > 0.01:
		return "%s synthesized fallback length changed" % slot_id
	return ""

static func verify() -> String:
	var station: Dictionary = RadioStationCatalogScript.get_station(RadioStationCatalogScript.DEFAULT_STATION_ID)
	if station.is_empty():
		return "Yardline station missing"
	if String(station.get("name", "")) != "YARDLINE 88.3":
		return "Yardline station name changed"
	if absf(float(station.get("frequency_mhz", 0.0)) - 88.3) > 0.001:
		return "Yardline frequency changed"

	var expected_slots: Array[String] = [
		"radio.yardline.advert_01",
		"radio.yardline.advert_02",
		"radio.yardline.dj_link_intro",
		"radio.yardline.dj_link_outro",
		"radio.yardline.world_gate",
		"radio.yardline.world_pursuit",
	]
	expected_slots.sort()
	if SelectionLockScript.get_target_slots() != expected_slots:
		return "01O source-selection lock must contain exactly the six authorized interstitial targets"

	for target in TARGETS:
		var selection_error := _verify_selection_lock(target)
		if not selection_error.is_empty():
			return selection_error
		var registry_error := _verify_registry_slot(target)
		if not registry_error.is_empty():
			return registry_error
		var catalog_error := _verify_catalog_target(target)
		if not catalog_error.is_empty():
			return catalog_error

	var program_player := RadioProgramPlayerScript.new()
	program_player.call("_ensure_player")
	if int(program_player.call("get_audio_stream_player_count")) != 1:
		program_player.free()
		return "RadioProgramPlayer must retain exactly one AudioStreamPlayer owner"
	var player := program_player.get_node_or_null("RadioAudioStreamPlayer") as AudioStreamPlayer
	if player == null:
		program_player.free()
		return "RadioAudioStreamPlayer owner missing"
	if StringName(player.bus) != &"Master":
		program_player.free()
		return "RadioAudioStreamPlayer bus changed"

	var fallback_hashes: Dictionary = {}
	for target in TARGETS:
		var fallback_error := _verify_fallback_synthesis(program_player, target)
		if not fallback_error.is_empty():
			program_player.free()
			return fallback_error
		var slot_id: String = String(target["slot"])
		var item: Dictionary = RadioStationCatalogScript.get_item_by_id(
			RadioStationCatalogScript.DEFAULT_STATION_ID,
			String(target["item_id"])
		)
		var segment: Dictionary = item.get("segments", [])[0]
		var stream := program_player.call("_synthesize_segment_audio", item, segment) as AudioStreamWAV
		var h := hash(stream.data)
		if fallback_hashes.has(h):
			program_player.free()
			return "%s procedural fallback collided with another 01O slot signature" % slot_id
		fallback_hashes[h] = slot_id

	program_player.free()
	return ""
