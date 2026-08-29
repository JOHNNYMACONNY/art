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
		"production_path": "res://audio/radio/rad_yardline_dj_sweeper.wav",
		"provenance": "GTA_SA:GENRL:BANK_44:SOUND_2",
		"rate": 18000,
		"duration": 0.4453,
		"fallback_duration": 0.8,
	},
	{
		"slot": "radio.yardline.station_id_01",
		"item_id": "id_01_yardline_jingle",
		"category": RadioStationCatalogScript.Category.STATION_ID,
		"context": "",
		"production_path": "res://audio/radio/rad_yardline_station_id_01.wav",
		"provenance": "GTA_SA:GENRL:BANK_44:SOUND_3",
		"rate": 18000,
		"duration": 1.0098,
		"fallback_duration": 1.5,
	},
	{
		"slot": "radio.yardline.station_id_02",
		"item_id": "id_02_yardline_sting",
		"category": RadioStationCatalogScript.Category.STATION_ID,
		"context": "",
		"production_path": "res://audio/radio/rad_yardline_station_id_02.wav",
		"provenance": "GTA_SA:GENRL:BANK_44:SOUND_4",
		"rate": 18000,
		"duration": 0.6596,
		"fallback_duration": 0.8,
	},
]

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

	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(stream.data)
	var data_sha: String = ctx.finish().hex_encode()
	if data_sha != String(lock.get("winner_raw_sha256", "")):
		return "%s exact PCM SHA-256 mismatch against lock" % slot_id

	if stream.loop_mode != AudioStreamWAV.LOOP_DISABLED:
		return "%s must remain non-looping" % slot_id
	return ""

static func verify() -> String:
	var station: Dictionary = RadioStationCatalogScript.get_station(RadioStationCatalogScript.DEFAULT_STATION_ID)
	if station.is_empty():
		return "Yardline station missing"
	if String(station.get("name", "")) != "YARDLINE 88.3":
		return "Yardline station name changed"

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
