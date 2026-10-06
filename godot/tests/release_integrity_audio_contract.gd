extends RefCounted
const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const UIAudioSemanticRegistryScript = preload("res://scripts/audio/ui_audio_semantic_registry.gd")
const AudioReferenceResolverScript = preload("res://scripts/audio/audio_reference_resolver.gd")

static func _all_slots() -> Dictionary:
	var result: Dictionary = {}
	for slot_id in AudioRegistryScript.get_all_slots().keys():
		result[slot_id] = AudioRegistryScript.get_slot(slot_id)
	for slot_id in UIAudioSemanticRegistryScript.get_all_slots().keys():
		result[slot_id] = UIAudioSemanticRegistryScript.get_slot(slot_id)
	return result

static func verify(manager: Node) -> String:
	var slots := _all_slots()
	if slots.size() != 49:
		return "Expected 49 retained semantic audio slots; found %d" % slots.size()
	for slot_id in slots.keys():
		var meta: Dictionary = slots[slot_id]
		if int(meta.get("asset_status", -1)) != AudioRegistryScript.AssetStatus.PROCEDURAL_FALLBACK:
			return "%s is not PROCEDURAL_FALLBACK" % slot_id
		if not bool(meta.get("replacement_required", false)):
			return "%s is not replacement-tracked" % slot_id
		if not String(meta.get("production_asset_path", "")).is_empty():
			return "%s still requires packaged production media" % slot_id
		if String(meta.get("source_provenance", "")) != "ORIGINAL_PROCEDURAL:RI01:%s" % slot_id:
			return "%s release provenance mismatch" % slot_id
		if not AudioRegistryScript.is_reference_allowed_for_status(int(meta.get("asset_status", -1))):
			return "%s dev-only reference override policy changed" % slot_id
	if AudioReferenceResolverScript.is_reference_enabled():
		return "Local reference resolver unexpectedly enabled in clean release verification"
	if manager == null:
		return "AudioManager missing"
	for field_name in ["_engine_stream", "_hum_stream", "_static_stream", "_siren_stream", "_tension_stream", "_ambient_wind_stream", "_radio_interference_stream"]:
		var stream = manager.get(field_name)
		if not (stream is AudioStreamWAV) or (stream as AudioStreamWAV).data.is_empty():
			return "%s lacks non-empty procedural PCM" % field_name
	return ""
