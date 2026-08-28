extends SceneTree

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")

const TARGETS := [
	{
		"label": "panel peel",
		"event": AudioManagerScript.SoundEvent.PANEL_PEEL,
		"slot": "interaction.panel_peel",
		"path": "res://audio/interaction/sfx_interaction_panel_peel.wav",
		"min_duration": 0.20,
		"max_duration": 1.20,
	},
	{
		"label": "wire spark",
		"event": AudioManagerScript.SoundEvent.SPARK,
		"slot": "interaction.wire_spark",
		"path": "res://audio/interaction/sfx_interaction_wire_spark.wav",
		"min_duration": 0.05,
		"max_duration": 0.45,
	},
	{
		"label": "core extracted",
		"event": AudioManagerScript.SoundEvent.COMPLETION,
		"slot": "interaction.core_extracted",
		"path": "res://audio/interaction/sfx_interaction_core_extracted.wav",
		"min_duration": 0.15,
		"max_duration": 0.90,
	},
	{
		"label": "bike mount",
		"event": AudioManagerScript.SoundEvent.BIKE_MOUNT,
		"slot": "player.bike_mount",
		"path": "res://audio/player/sfx_player_bike_mount.wav",
		"min_duration": 0.05,
		"max_duration": 0.50,
	},
	{
		"label": "bike dismount",
		"event": AudioManagerScript.SoundEvent.BIKE_DISMOUNT,
		"slot": "player.bike_dismount",
		"path": "res://audio/player/sfx_player_bike_dismount.wav",
		"min_duration": 0.05,
		"max_duration": 0.50,
	},
	{
		"label": "brake screech",
		"event": AudioManagerScript.SoundEvent.BRAKE_SCREECH,
		"slot": "vehicle.brake_screech",
		"path": "res://audio/vehicle/sfx_vehicle_brake_screech.wav",
		"min_duration": 0.15,
		"max_duration": 1.20,
	},
]

func _init() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[AUDIO_PRODUCTION_01D] FAIL: %s" % message)
	await process_frame
	await process_frame
	quit(1)

func _run() -> void:
	var manager = AudioManagerScript.new()
	root.add_child(manager)
	await process_frame
	await process_frame

	for index in range(TARGETS.size()):
		var target: Dictionary = TARGETS[index]
		var label: String = target["label"]
		var event: int = target["event"]
		var slot_id: String = target["slot"]
		var asset_path: String = target["path"]

		if not AudioRegistryScript.has_slot(slot_id):
			manager.queue_free()
			await _fail("%s slot is not registered: %s" % [label, slot_id])
			return

		if AudioManagerScript.event_to_slot_id(event) != slot_id:
			manager.queue_free()
			await _fail("%s event does not map to %s" % [label, slot_id])
			return

		var slot: Dictionary = AudioRegistryScript.get_slot(slot_id)
		if slot.get("spatial_type") != AudioRegistryScript.SpatialType.DIEGETIC_3D:
			manager.queue_free()
			await _fail("%s must remain DIEGETIC_3D" % label)
			return
		if slot.get("playback_type") != AudioRegistryScript.PlaybackType.TRANSIENT:
			manager.queue_free()
			await _fail("%s must remain TRANSIENT" % label)
			return
		if bool(slot.get("is_looping", true)):
			manager.queue_free()
			await _fail("%s must remain non-looping" % label)
			return
		if slot.get("asset_status") != AudioRegistryScript.AssetStatus.LICENSED_FINAL:
			manager.queue_free()
			await _fail("%s must be promoted to production-final status" % label)
			return
		if slot.get("replacement_required") != false:
			manager.queue_free()
			await _fail("%s must clear replacement_required" % label)
			return
		if AudioRegistryScript.get_production_asset_path(slot_id) != asset_path:
			manager.queue_free()
			await _fail("%s production path must be %s" % [label, asset_path])
			return

		var provenance: String = AudioRegistryScript.get_source_provenance(slot_id)
		if not provenance.begins_with("GTA_SA:") or provenance.find(":BANK_") < 0 or provenance.find(":SOUND_") < 0:
			manager.queue_free()
			await _fail("%s must record exact GTA pak/bank/sound provenance" % label)
			return

		if not FileAccess.file_exists(asset_path):
			manager.queue_free()
			await _fail("%s production WAV is missing" % label)
			return
		var stream := load(asset_path) as AudioStreamWAV
		if stream == null or stream.data.is_empty():
			manager.queue_free()
			await _fail("%s failed to load as non-empty AudioStreamWAV" % label)
			return
		if stream.format != AudioStreamWAV.FORMAT_16_BITS:
			manager.queue_free()
			await _fail("%s must be 16-bit PCM" % label)
			return
		if stream.stereo:
			manager.queue_free()
			await _fail("%s must be mono for 3D localization" % label)
			return
		if stream.mix_rate < 8000 or stream.mix_rate > 48000:
			manager.queue_free()
			await _fail("%s has implausible native sample rate %d" % [label, stream.mix_rate])
			return
		var duration: float = stream.get_length()
		if duration < float(target["min_duration"]) or duration > float(target["max_duration"]):
			manager.queue_free()
			await _fail("%s duration %.4fs is outside approved transient range" % [label, duration])
			return

		manager.reset_audio_instant()
		var test_pos := Vector3(2.5 + float(index), 1.25, -8.0 - float(index))
		manager.play_event(event, test_pos)
		var active: Array = manager.get("_active_transients")
		if active.is_empty():
			manager.queue_free()
			await _fail("%s did not create a 3D transient voice" % label)
			return
		var player := active[-1] as AudioStreamPlayer3D
		if player == null:
			manager.queue_free()
			await _fail("%s did not use AudioStreamPlayer3D" % label)
			return
		if player.stream != stream:
			manager.queue_free()
			await _fail("%s event did not play its selected production stream" % label)
			return
		if player.global_position.distance_to(test_pos) > 0.01:
			manager.queue_free()
			await _fail("%s did not preserve supplied gameplay world position" % label)
			return

	manager.reset_audio_instant()
	manager.queue_free()
	await process_frame
	await process_frame
	print("[AUDIO_PRODUCTION_01D] PASS: six selected GTA transients resolve, map and play as bounded 3D production voices")
	quit(0)
