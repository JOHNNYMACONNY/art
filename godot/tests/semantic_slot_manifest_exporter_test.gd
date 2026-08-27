extends SceneTree

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const UIAudioSemanticRegistryScript = preload("res://scripts/audio/ui_audio_semantic_registry.gd")

func _init() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[AUDIO_INTAKE_MANIFEST] FAIL: %s" % message)
	await process_frame
	await process_frame
	quit(1)

func _pass(summary: Dictionary) -> void:
	print("[AUDIO_INTAKE_MANIFEST] PASS: %s slots validated (AudioRegistry=%d, UIAudioRegistry=%d)" % [
		summary.get("total_slots", 0),
		summary.get("audio_registry_count", 0),
		summary.get("ui_registry_count", 0)
	])
	await process_frame
	await process_frame
	quit(0)

func _domain_name(val: Variant) -> String:
	if val is String:
		return val
	match int(val):
		AudioRegistryScript.Domain.PLAYER: return "PLAYER"
		AudioRegistryScript.Domain.WORLD: return "WORLD"
		AudioRegistryScript.Domain.VEHICLE: return "VEHICLE"
		AudioRegistryScript.Domain.INTERACTION: return "INTERACTION"
		AudioRegistryScript.Domain.PURSUIT: return "PURSUIT"
		AudioRegistryScript.Domain.ECHO: return "ECHO"
		AudioRegistryScript.Domain.UI: return "UI"
		AudioRegistryScript.Domain.RADIO: return "RADIO"
		_: return "UNKNOWN"

func _diegesis_name(val: Variant) -> String:
	if val is String:
		return val
	match int(val):
		AudioRegistryScript.Diegesis.DIEGETIC: return "DIEGETIC"
		AudioRegistryScript.Diegesis.NON_DIEGETIC: return "NON_DIEGETIC"
		AudioRegistryScript.Diegesis.HYBRID: return "HYBRID"
		_: return "UNKNOWN"

func _spatial_name(val: Variant) -> String:
	if val is String:
		return val
	match int(val):
		AudioRegistryScript.SpatialType.DIEGETIC_3D: return "DIEGETIC_3D"
		AudioRegistryScript.SpatialType.NON_DIEGETIC_2D: return "NON_DIEGETIC_2D"
		AudioRegistryScript.SpatialType.HYBRID: return "HYBRID"
		_: return "UNKNOWN"

func _mix_group_name(val: Variant) -> String:
	if val is String:
		return val
	match int(val):
		AudioRegistryScript.MixGroup.CRITICAL_THREAT: return "CRITICAL_THREAT"
		AudioRegistryScript.MixGroup.SIGNATURE_ECHO: return "SIGNATURE_ECHO"
		AudioRegistryScript.MixGroup.VEHICLE_FEEDBACK: return "VEHICLE_FEEDBACK"
		AudioRegistryScript.MixGroup.RADIO_MUSIC: return "RADIO_MUSIC"
		AudioRegistryScript.MixGroup.AMBIENT_TEXTURE: return "AMBIENT_TEXTURE"
		AudioRegistryScript.MixGroup.INCIDENTAL_UI: return "INCIDENTAL_UI"
		_: return "UNKNOWN"

func _playback_name(val: Variant) -> String:
	if val is String:
		return val
	match int(val):
		AudioRegistryScript.PlaybackType.TRANSIENT: return "TRANSIENT"
		AudioRegistryScript.PlaybackType.CONTINUOUS_LOOP: return "CONTINUOUS_LOOP"
		_: return "UNKNOWN"

func _status_name(val: Variant) -> String:
	match int(val):
		AudioRegistryScript.AssetStatus.PROCEDURAL_FALLBACK: return "PROCEDURAL_FALLBACK"
		AudioRegistryScript.AssetStatus.REFERENCE_ONLY: return "REFERENCE_ONLY"
		AudioRegistryScript.AssetStatus.ORIGINAL_WIP: return "ORIGINAL_WIP"
		AudioRegistryScript.AssetStatus.ORIGINAL_FINAL: return "ORIGINAL_FINAL"
		AudioRegistryScript.AssetStatus.LICENSED_FINAL: return "LICENSED_FINAL"
		_: return "UNKNOWN"

func _run() -> void:
	var master_slots: Dictionary = AudioRegistryScript.get_all_slots()
	var ui_slots: Dictionary = UIAudioSemanticRegistryScript.get_all_slots()

	if master_slots.is_empty():
		await _fail("AudioRegistry master slots dictionary is empty")
		return

	if ui_slots.is_empty():
		await _fail("UIAudioSemanticRegistry slots dictionary is empty")
		return

	var all_slot_keys: Array = []
	var consolidated_manifest: Dictionary = {
		"schema_version": 1,
		"exported_at": Time.get_datetime_string_from_system(true, true),
		"slots": {}
	}

	# Validate AudioRegistry slots
	for slot_id in master_slots.keys():
		if all_slot_keys.has(slot_id):
			await _fail("Duplicate slot ID across registries: %s" % slot_id)
			return
		all_slot_keys.append(slot_id)

		var def: Dictionary = master_slots[slot_id]
		if def.get("slot_id") != slot_id:
			await _fail("Slot key mismatch for %s" % slot_id)
			return

		var domain_str := _domain_name(def.get("domain"))
		if domain_str == "UNKNOWN":
			await _fail("Unknown domain for %s" % slot_id)
			return

		var spatial_str := _spatial_name(def.get("spatial_type"))
		if spatial_str == "UNKNOWN":
			await _fail("Unknown spatial_type for %s" % slot_id)
			return

		var mix_str := _mix_group_name(def.get("mix_group"))
		if mix_str == "UNKNOWN":
			await _fail("Unknown mix_group for %s" % slot_id)
			return

		var playback_str := _playback_name(def.get("playback_type"))
		if playback_str == "UNKNOWN":
			await _fail("Unknown playback_type for %s" % slot_id)
			return

		var status_str := _status_name(def.get("asset_status"))
		if status_str == "UNKNOWN":
			await _fail("Unknown asset_status for %s" % slot_id)
			return

		consolidated_manifest["slots"][slot_id] = {
			"slot_id": slot_id,
			"domain": domain_str,
			"diegesis": _diegesis_name(def.get("diegesis")),
			"spatial_type": spatial_str,
			"mix_group": mix_str,
			"playback_type": playback_str,
			"asset_status": status_str,
			"is_looping": def.get("is_looping", false),
			"cooldown_msec": def.get("cooldown_msec", 0),
			"max_concurrency": def.get("max_concurrency", 1),
			"replacement_required": def.get("replacement_required", false),
			"description": def.get("description", "")
		}

	# Validate UIAudioSemanticRegistry slots
	for slot_id in ui_slots.keys():
		if all_slot_keys.has(slot_id):
			await _fail("Duplicate slot ID in UI registry: %s" % slot_id)
			return
		all_slot_keys.append(slot_id)

		var def: Dictionary = ui_slots[slot_id]
		if def.get("slot_id") != slot_id:
			await _fail("UI Slot key mismatch for %s" % slot_id)
			return

		consolidated_manifest["slots"][slot_id] = {
			"slot_id": slot_id,
			"domain": "UI",
			"diegesis": _diegesis_name(def.get("diegesis")),
			"spatial_type": _spatial_name(def.get("spatial_type")),
			"mix_group": _mix_group_name(def.get("mix_group")),
			"playback_type": _playback_name(def.get("playback_type")),
			"asset_status": _status_name(def.get("asset_status")),
			"is_looping": false,
			"cooldown_msec": def.get("cooldown_msec", 0),
			"max_concurrency": def.get("max_concurrency", 1),
			"replacement_required": def.get("replacement_required", true),
			"description": def.get("description", "")
		}

	var summary := {
		"total_slots": all_slot_keys.size(),
		"audio_registry_count": master_slots.size(),
		"ui_registry_count": ui_slots.size()
	}

	await _pass(summary)
