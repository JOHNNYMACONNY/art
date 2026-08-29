extends RefCounted

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const RadioStationCatalogScript = preload("res://scripts/audio/radio/radio_station_catalog.gd")
const RadioProgramPlayerScript = preload("res://scripts/audio/radio/radio_program_player.gd")
const SelectionLockScript = preload("res://tests/yardline_station_identity_selection_lock.gd")

const TARGETS := [
	{
		"slot": "radio.yardline.dj_sweeper",
		"item_id": "dj_03_sweeper",
		"category": RadioStationCatalogScript.Category.DJ_LINK,
		"context": "SWEEPER",
		"duration": 0.8,
		"base_freq_hz": 520.0,
		"production_path": "res://audio/radio/rad_yardline_dj_sweeper.wav",
		"winner_provenance": "GTA_SA:GENRL:BANK_44:SOUND_2",
		"winner_sample_rate": 18000,
		"winner_frames": 8016,
		"winner_duration_sec": 0.4453,
		"winner_raw_sha256": "188837f05074b791060d41d5265851be7ef84b443c54b4f42d8fd40f941022b3",
		"runner_up_provenance": "GTA_SA:SCRIPT:BANK_356:SOUND_16",
	},
	{
		"slot": "radio.yardline.station_id_01",
		"item_id": "id_01_yardline_jingle",
		"category": RadioStationCatalogScript.Category.STATION_ID,
		"context": "",
		"duration": 1.5,
		"base_freq_hz": 660.0,
		"production_path": "res://audio/radio/rad_yardline_station_id_01.wav",
		"winner_provenance": "GTA_SA:GENRL:BANK_44:SOUND_3",
		"winner_sample_rate": 18000,
		"winner_frames": 18176,
		"winner_duration_sec": 1.0098,
		"winner_raw_sha256": "a742e3d686fcfa91f8b643e0a820580a78dcd40db34f4c73ce517c894340c842",
		"runner_up_provenance": "GTA_SA:SCRIPT:BANK_356:SOUND_2",
	},
	{
		"slot": "radio.yardline.station_id_02",
		"item_id": "id_02_yardline_sting",
		"category": RadioStationCatalogScript.Category.STATION_ID,
		"context": "",
		"duration": 0.8,
		"base_freq_hz": 880.0,
		"production_path": "res://audio/radio/rad_yardline_station_id_02.wav",
		"winner_provenance": "GTA_SA:GENRL:BANK_44:SOUND_4",
		"winner_sample_rate": 18000,
		"winner_frames": 11872,
		"winner_duration_sec": 0.6596,
		"winner_raw_sha256": "7550cdb3f12086f78bea71b752b0edbd5e1f46b1e83136c459de5cc978d99051",
		"runner_up_provenance": "GTA_SA:SCRIPT:BANK_356:SOUND_13",
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
	if String(selection.get("winner_raw_sha256", "")) != String(target["winner_raw_sha256"]):
		return "%s winner raw SHA lock changed" % slot_id
	if String(selection.get("runner_up_provenance", "")) != String(target["runner_up_provenance"]):
		return "%s runner-up provenance lock changed" % slot_id
	if String(selection.get("edge_treatment", "")) != "NONE_NATURAL_BOUNDARY":
		return "%s edge-treatment lock changed" % slot_id
	if ResourceLoader.exists(String(selection["production_path"])):
		return "%s production media appeared while candidate-stage guard is still active" % slot_id
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
		return "%s must remain non-looping before production ingestion" % slot_id
	if int(slot.get("max_concurrency", 0)) != 1:
		return "%s max concurrency changed" % slot_id
	if slot.get("asset_status") != AudioRegistryScript.AssetStatus.PROCEDURAL_FALLBACK:
		return "%s must remain PROCEDURAL_FALLBACK until production ingestion begins" % slot_id
	if not bool(slot.get("replacement_required", false)):
		return "%s must remain replacement-required until production ingestion begins" % slot_id
	if not AudioRegistryScript.get_production_asset_path(slot_id).is_empty():
		return "%s acquired a production path before production ingestion" % slot_id
	if not AudioRegistryScript.get_source_provenance(slot_id).is_empty():
		return "%s acquired registry provenance before production ingestion" % slot_id
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
		"radio.yardline.dj_sweeper",
		"radio.yardline.station_id_01",
		"radio.yardline.station_id_02",
	]
	expected_slots.sort()
	if SelectionLockScript.get_target_slots() != expected_slots:
		return "01M source-selection lock must contain exactly the three authorized Yardline targets"

	var station_ids: Array[Dictionary] = RadioStationCatalogScript.get_items_by_category(
		RadioStationCatalogScript.DEFAULT_STATION_ID,
		RadioStationCatalogScript.Category.STATION_ID
	)
	if station_ids.size() != 2:
		return "01M expects exactly the existing two Yardline station ID items"

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

	for target in TARGETS:
		var fallback_error := _verify_fallback_synthesis(program_player, target)
		if not fallback_error.is_empty():
			program_player.free()
			return fallback_error

	program_player.free()
	return ""
