extends RefCounted

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")

const TARGETS := [
	{
		"label": "panel peel",
		"event": AudioManagerScript.SoundEvent.PANEL_PEEL,
		"slot": "interaction.panel_peel",
		"path": "res://audio/interaction/sfx_interaction_panel_peel.wav",
		"provenance": "GTA_SA:GENRL:BANK_76:SOUND_1",
		"mix_rate": 18000,
		"duration": 0.6595,
		"unit_size": 10.0,
	},
	{
		"label": "wire spark",
		"event": AudioManagerScript.SoundEvent.SPARK,
		"slot": "interaction.wire_spark",
		"path": "res://audio/interaction/sfx_interaction_wire_spark.wav",
		"provenance": "GTA_SA:GENRL:BANK_143:SOUND_26",
		"mix_rate": 24000,
		"duration": 0.2631,
		"unit_size": 8.0,
	},
	{
		"label": "core extracted",
		"event": AudioManagerScript.SoundEvent.COMPLETION,
		"slot": "interaction.core_extracted",
		"path": "res://audio/interaction/sfx_interaction_core_extracted.wav",
		"provenance": "GTA_SA:SCRIPT:BANK_260:SOUND_0",
		"mix_rate": 22050,
		"duration": 0.6313,
		"unit_size": 12.0,
	},
	{
		"label": "bike mount",
		"event": AudioManagerScript.SoundEvent.BIKE_MOUNT,
		"slot": "player.bike_mount",
		"path": "res://audio/player/sfx_player_bike_mount.wav",
		"provenance": "GTA_SA:GENRL:BANK_143:SOUND_57",
		"mix_rate": 18000,
		"duration": 0.3443,
		"unit_size": 8.0,
	},
	{
		"label": "bike dismount",
		"event": AudioManagerScript.SoundEvent.BIKE_DISMOUNT,
		"slot": "player.bike_dismount",
		"path": "res://audio/player/sfx_player_bike_dismount.wav",
		"provenance": "GTA_SA:GENRL:BANK_143:SOUND_41",
		"mix_rate": 22050,
		"duration": 0.2115,
		"unit_size": 8.0,
	},
	{
		"label": "brake screech",
		"event": AudioManagerScript.SoundEvent.BRAKE_SCREECH,
		"slot": "vehicle.brake_screech",
		"path": "res://audio/vehicle/sfx_vehicle_brake_screech.wav",
		"provenance": "GTA_SA:GENRL:BANK_143:SOUND_28",
		"mix_rate": 28000,
		"duration": 0.4540,
		"unit_size": 10.0,
	},
]

static func verify(manager: Node) -> String:
	if manager == null:
		return "AudioManager is missing"

	var production_streams: Dictionary = manager.get("_production_transient_streams")
	if production_streams == null:
		return "AudioManager production transient cache is unavailable"

	for index in range(TARGETS.size()):
		var target: Dictionary = TARGETS[index]
		var label: String = target["label"]
		var event: int = target["event"]
		var slot_id: String = target["slot"]
		var asset_path: String = target["path"]

		if not AudioRegistryScript.has_slot(slot_id):
			return "%s slot is not registered: %s" % [label, slot_id]
		if AudioManagerScript.event_to_slot_id(event) != slot_id:
			return "%s event does not map to %s" % [label, slot_id]

		var slot: Dictionary = AudioRegistryScript.get_slot(slot_id)
		if slot.get("spatial_type") != AudioRegistryScript.SpatialType.DIEGETIC_3D:
			return "%s must remain DIEGETIC_3D" % label
		if slot.get("playback_type") != AudioRegistryScript.PlaybackType.TRANSIENT:
			return "%s must remain TRANSIENT" % label
		if bool(slot.get("is_looping", true)):
			return "%s must remain non-looping" % label
		if slot.get("asset_status") != AudioRegistryScript.AssetStatus.LICENSED_FINAL:
			return "%s must be promoted to production-final status" % label
		if slot.get("replacement_required") != false:
			return "%s must clear replacement_required" % label
		if AudioRegistryScript.get_production_asset_path(slot_id) != asset_path:
			return "%s production path must be %s" % [label, asset_path]
		if AudioRegistryScript.get_source_provenance(slot_id) != String(target["provenance"]):
			return "%s source provenance mismatch" % label

		if not FileAccess.file_exists(asset_path):
			return "%s production WAV is missing" % label
		var stream := load(asset_path) as AudioStreamWAV
		if stream == null or stream.data.is_empty():
			return "%s failed to load as non-empty AudioStreamWAV" % label
		if stream.format != AudioStreamWAV.FORMAT_16_BITS:
			return "%s must be 16-bit PCM" % label
		if stream.stereo:
			return "%s must be mono for 3D localization" % label
		if stream.mix_rate != int(target["mix_rate"]):
			return "%s must preserve native sample rate %d (got %d)" % [label, int(target["mix_rate"]), stream.mix_rate]
		if absf(stream.get_length() - float(target["duration"])) > 0.01:
			return "%s must preserve selected duration %.4fs (got %.4fs)" % [label, float(target["duration"]), stream.get_length()]

		if not production_streams.has(event) or production_streams[event] != stream:
			return "%s was not resolved into the production transient cache" % label

		manager.call("reset_audio_instant")
		var test_pos := Vector3(2.5 + float(index), 1.25, -8.0 - float(index))
		manager.call("play_event", event, test_pos)
		var active: Array = manager.get("_active_transients")
		if active.is_empty():
			return "%s did not create a production 3D transient voice" % label
		var player := active[-1] as AudioStreamPlayer3D
		if player == null or player.stream != stream:
			return "%s event did not play its selected production stream" % label
		if player.global_position.distance_to(test_pos) > 0.01:
			return "%s did not preserve supplied gameplay world position" % label
		if absf(player.unit_size - float(target["unit_size"])) > 0.01:
			return "%s changed spatial unit_size (expected %.1f, got %.1f)" % [label, float(target["unit_size"]), player.unit_size]

		# Remove only this production stream and prove its old procedural path is
		# independently reachable. Other cached production events remain intact.
		manager.call("reset_audio_instant")
		var saved_stream: AudioStream = production_streams[event]
		production_streams.erase(event)
		manager.set("_production_transient_streams", production_streams)
		manager.call("play_event", event, test_pos)
		var fallback: Array = manager.get("_active_transients")
		if fallback.is_empty():
			return "%s procedural fallback did not create a 3D transient" % label
		var fallback_player := fallback[-1] as AudioStreamPlayer3D
		if fallback_player == null or fallback_player.stream == stream:
			return "%s procedural fallback is not independently reachable" % label
		production_streams[event] = saved_stream
		manager.set("_production_transient_streams", production_streams)

	# Prove one missing cache entry does not disable a different production event.
	manager.call("reset_audio_instant")
	var first: Dictionary = TARGETS[0]
	var second: Dictionary = TARGETS[1]
	var first_event: int = first["event"]
	var second_event: int = second["event"]
	var saved_first: AudioStream = production_streams[first_event]
	production_streams.erase(first_event)
	manager.set("_production_transient_streams", production_streams)
	var isolation_pos := Vector3(19.0, 1.0, -11.0)
	manager.call("play_event", second_event, isolation_pos)
	var isolation_active: Array = manager.get("_active_transients")
	var second_stream := load(String(second["path"])) as AudioStreamWAV
	if isolation_active.is_empty() or (isolation_active[-1] as AudioStreamPlayer3D).stream != second_stream:
		production_streams[first_event] = saved_first
		manager.set("_production_transient_streams", production_streams)
		return "one missing production stream disabled another 01D production event"
	production_streams[first_event] = saved_first
	manager.set("_production_transient_streams", production_streams)

	manager.call("reset_audio_instant")
	return ""
