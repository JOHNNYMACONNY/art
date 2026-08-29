extends RefCounted

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const RadioStationCatalogScript = preload("res://scripts/audio/radio/radio_station_catalog.gd")
const RadioProgramPlayerScript = preload("res://scripts/audio/radio/radio_program_player.gd")
const SelectionLockScript = preload("res://tests/yardline_radio_interstitial_selection_lock.gd")
const AudioReferenceResolverScript = preload("res://scripts/audio/audio_reference_resolver.gd")

const TARGETS: Array[Dictionary] = [
	{
		"slot": "radio.yardline.dj_link_intro",
		"item_id": "dj_01_track_intro",
		"category": RadioStationCatalogScript.Category.DJ_LINK,
		"context": "INTRO",
		"production_path": "res://audio/radio/rad_yardline_dj_link_intro.wav",
		"provenance": "GTA_SA:GENRL:BANK_84:SOUND_0",
		"rate": 11025,
		"duration": 4.9067,
		"fallback_duration": 1.2,
		"container_sha256": "a57fdf9505a477e1481862a2cb39e30ad8bd128e3571aee3a1db699fbe8fb932",
	},
	{
		"slot": "radio.yardline.dj_link_outro",
		"item_id": "dj_02_track_outro",
		"category": RadioStationCatalogScript.Category.DJ_LINK,
		"context": "OUTRO",
		"production_path": "res://audio/radio/rad_yardline_dj_link_outro.wav",
		"provenance": "GTA_SA:GENRL:BANK_84:SOUND_1",
		"rate": 11025,
		"duration": 2.7986,
		"fallback_duration": 1.0,
		"container_sha256": "441127de705099889ef45a489f2362f3f9306467a4a6afdf26e53b50ce21690b",
	},
	{
		"slot": "radio.yardline.advert_01",
		"item_id": "ad_01_scrap_parts",
		"category": RadioStationCatalogScript.Category.ADVERT,
		"context": "",
		"production_path": "res://audio/radio/rad_yardline_advert_01.wav",
		"provenance": "GTA_SA:GENRL:BANK_82:SOUND_0",
		"rate": 28000,
		"duration": 9.896,
		"fallback_duration": 1.5,
		"container_sha256": "b1117029ce70e68e113416837790952cb34ed8ca2d9bc708306cc750e11c47f9",
	},
	{
		"slot": "radio.yardline.advert_02",
		"item_id": "ad_02_courier_rations",
		"category": RadioStationCatalogScript.Category.ADVERT,
		"context": "",
		"production_path": "res://audio/radio/rad_yardline_advert_02.wav",
		"provenance": "GTA_SA:GENRL:BANK_82:SOUND_4",
		"rate": 28000,
		"duration": 9.897,
		"fallback_duration": 1.5,
		"container_sha256": "4d81f826a4ee7822139edcf29dbc3533395b9fa944add9c0f47f01a47c32d747",
	},
	{
		"slot": "radio.yardline.world_pursuit",
		"item_id": "world_01_pursuit_advisory",
		"category": RadioStationCatalogScript.Category.WORLD_REACTION,
		"context": "",
		"production_path": "res://audio/radio/rad_yardline_world_pursuit.wav",
		"provenance": "GTA_SA:GENRL:BANK_91:SOUND_0",
		"rate": 18000,
		"duration": 0.9613,
		"fallback_duration": 1.5,
		"container_sha256": "99a7acb0437ba59c22a645f6563201f57b44a6fd636b6fd2853754e0cec6831d",
	},
	{
		"slot": "radio.yardline.world_gate",
		"item_id": "world_02_gate_activity",
		"category": RadioStationCatalogScript.Category.WORLD_REACTION,
		"context": "",
		"production_path": "res://audio/radio/rad_yardline_world_gate.wav",
		"provenance": "GTA_SA:GENRL:BANK_91:SOUND_1",
		"rate": 18000,
		"duration": 3.2528,
		"fallback_duration": 1.2,
		"container_sha256": "43bb8e9092381dbc49e0d8538b2926d2b9116e2d5b1bdbd8e15a7f21c20e85a0",
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
			return "%s missing locked import setting: %s" % [prod_path, required_setting]
	return ""

static func _verify_slot(target: Dictionary) -> String:
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
	if slot.get("asset_status") != AudioRegistryScript.AssetStatus.LICENSED_FINAL:
		return "%s must be LICENSED_FINAL" % slot_id
	if bool(slot.get("replacement_required", true)):
		return "%s replacement_required must be false" % slot_id
	if AudioRegistryScript.is_reference_allowed_for_status(slot.get("asset_status")):
		return "%s LICENSED_FINAL slots must reject local reference override" % slot_id
	if AudioRegistryScript.get_production_asset_path(slot_id) != String(target["production_path"]):
		return "%s production path mismatch" % slot_id
	if AudioRegistryScript.get_source_provenance(slot_id) != String(target["provenance"]):
		return "%s source provenance mismatch" % slot_id

	var lock: Dictionary = SelectionLockScript.get_selection(slot_id)
	if lock.is_empty():
		return "%s selection lock missing" % slot_id
	if String(lock.get("production_path", "")) != String(target["production_path"]):
		return "%s production path mismatch against lock" % slot_id
	if String(lock.get("winner_provenance", "")) != String(target["provenance"]):
		return "%s provenance mismatch against lock" % slot_id

	var path: String = String(target["production_path"])
	if not FileAccess.file_exists(path):
		return "%s production media file missing" % slot_id
	var import_error := _verify_import_settings(path)
	if not import_error.is_empty():
		return "%s: %s" % [slot_id, import_error]

	var stream := load(path) as AudioStreamWAV
	if stream == null or stream.data.is_empty():
		return "%s production stream failed to load" % slot_id
	if stream.format != AudioStreamWAV.FORMAT_16_BITS or stream.stereo:
		return "%s must be mono PCM16" % slot_id
	if stream.mix_rate != int(target["rate"]) or stream.mix_rate != int(lock.get("winner_sample_rate", 0)):
		return "%s sample rate mismatch" % slot_id
	if stream.data.size() != int(lock.get("winner_raw_bytes", 0)):
		return "%s raw PCM byte count mismatch against lock" % slot_id
	if (stream.data.size() / 2) != int(lock.get("winner_frames", 0)):
		return "%s exact frame count mismatch against lock" % slot_id

	var actual_dur := float(stream.data.size() / 2) / float(stream.mix_rate)
	if absf(actual_dur - float(lock.get("winner_duration_sec", 0.0))) > 0.001:
		return "%s actual stream duration mismatch against lock" % slot_id

	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(stream.data)
	var data_sha: String = ctx.finish().hex_encode()
	if data_sha != String(lock.get("winner_raw_sha256", "")):
		return "%s exact PCM SHA-256 mismatch against lock" % slot_id

	var file_sha: String = FileAccess.get_sha256(path)
	if file_sha != String(target.get("container_sha256", "")):
		return "%s container file SHA-256 mismatch against spec" % slot_id

	if stream.loop_mode != AudioStreamWAV.LOOP_DISABLED:
		return "%s must remain non-looping" % slot_id
	return ""

static func verify() -> String:
	var station: Dictionary = RadioStationCatalogScript.get_station(RadioStationCatalogScript.DEFAULT_STATION_ID)
	if station.is_empty():
		return "Yardline station missing"
	if String(station.get("name", "")) != "YARDLINE 88.3":
		return "Yardline station name changed"

	var expected_slots: Array[String] = []
	for target in TARGETS:
		expected_slots.append(String(target["slot"]))
	expected_slots.sort()
	if expected_slots != SelectionLockScript.get_target_slots():
		return "01O production contract target set must exactly match SelectionLock target set"

	for target in TARGETS:
		var slot_err := _verify_slot(target)
		if not slot_err.is_empty():
			return slot_err

	var program_player := RadioProgramPlayerScript.new()
	program_player.call("_ensure_player")
	var player := program_player.get_node_or_null("RadioAudioStreamPlayer") as AudioStreamPlayer
	if player == null:
		program_player.free()
		return "RadioAudioStreamPlayer missing"

	for target in TARGETS:
		var item: Dictionary = RadioStationCatalogScript.get_item_by_id(
			RadioStationCatalogScript.DEFAULT_STATION_ID,
			String(target["item_id"])
		)
		if item.is_empty():
			program_player.free()
			return "%s catalog item missing" % String(target["slot"])
		
		# Test playing segment with production stream
		program_player.set("_current_item", item)
		program_player.set("_current_segment_index", 0)
		program_player.call("_play_current_segment")
		
		var cur_stream := program_player.get("_current_stream") as AudioStreamWAV
		if cur_stream == null:
			program_player.free()
			return "%s did not resolve to production AudioStreamWAV" % String(target["slot"])
		if cur_stream.mix_rate != int(target["rate"]):
			program_player.free()
			return "%s resolved stream sample rate mismatch" % String(target["slot"])
		if absf(cur_stream.get_length() - float(target["duration"])) > 0.01:
			program_player.free()
			return "%s resolved stream duration mismatch" % String(target["slot"])

		# Verify procedural fallback is independently synthesizable
		var segments: Array = item.get("segments", [])
		var fallback_stream := program_player.call("_synthesize_segment_audio", item, segments[0]) as AudioStreamWAV
		if fallback_stream == null or fallback_stream.data.is_empty():
			program_player.free()
			return "%s procedural fallback synthesis failed" % String(target["slot"])
		if absf(fallback_stream.get_length() - float(target["fallback_duration"])) > 0.01:
			program_player.free()
			return "%s procedural fallback duration mismatch" % String(target["slot"])

	program_player.free()
	return ""
