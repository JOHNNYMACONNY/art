extends RefCounted

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const UIAudioSemanticRegistryScript = preload("res://scripts/audio/ui_audio_semantic_registry.gd")
const UIAudioIdentityLayerScript = preload("res://scripts/audio/ui_audio_identity_layer.gd")
const AudioReferenceResolverScript = preload("res://scripts/audio/audio_reference_resolver.gd")

const REPORT_PATH := "res://verification/audio/audio_first_retention_summary.json"
const EXPECTED_BEHAVIOR_SHA := "204a92b7e79ae5c35876633c2a37ac018ba5abdb"
const STATUS_NAMES := [
	"PROCEDURAL_FALLBACK",
	"REFERENCE_ONLY",
	"ORIGINAL_WIP",
	"ORIGINAL_FINAL",
	"LICENSED_FINAL",
]
const REQUIRED_PLAYBACK_SCENARIOS := [
	"calm_yard_vehicle_entry",
	"radio_driving",
	"exit_reenter_persistence",
	"station_off_switching",
	"disturbance_over_radio",
	"active_pursuit_mix",
	"echo_hybrid_transition",
	"evasion_quiet_recovery",
	"replay_reset",
	"local_reference_ab",
]

static func _status_name(status: int) -> String:
	if status < 0 or status >= STATUS_NAMES.size():
		return "UNKNOWN"
	return STATUS_NAMES[status]

static func _all_current_slots() -> Dictionary:
	var result: Dictionary = {}
	for slot_id in AudioRegistryScript.get_all_slots().keys():
		result[slot_id] = AudioRegistryScript.get_slot(slot_id)
	for slot_id in UIAudioSemanticRegistryScript.get_all_slots().keys():
		result[slot_id] = UIAudioSemanticRegistryScript.get_slot(slot_id)
	return result

static func verify() -> String:
	if not FileAccess.file_exists(REPORT_PATH):
		return "Audio 07 retention/replacement report is absent"
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(REPORT_PATH))
	if not (parsed is Dictionary):
		return "Audio 07 retention report is not valid JSON object data"
	var report: Dictionary = parsed
	if int(report.get("schema_version", 0)) != 1 or int(report.get("ticket", 0)) != 27:
		return "Audio 07 retention report schema/ticket mismatch"
	if String(report.get("integrated_behavior_sha", "")) != EXPECTED_BEHAVIOR_SHA:
		return "Audio 07 integrated behavior SHA does not match the verified pre-ticket main"
	if String(report.get("completion_state", "")) != "FUNCTIONAL_VERIFIED__PERCEPTUAL_GATE_PENDING":
		return "Audio 07 completion state overclaims or is missing"

	var dispositions = report.get("candidate_dispositions", {})
	if not (dispositions is Dictionary):
		return "Audio 07 candidate disposition table is absent"
	for ticket in ["21", "22", "23", "24", "25", "26"]:
		var entry = dispositions.get(ticket, {})
		if not (entry is Dictionary) or String(entry.get("disposition", "")) != "FUNCTIONALLY_RETAINED":
			return "Audio ticket #%s is not truthfully classified FUNCTIONALLY_RETAINED" % ticket

	var playback = report.get("playback_proof", {})
	if not (playback is Dictionary):
		return "Audio 07 playback-proof classification is absent"
	for scenario in REQUIRED_PLAYBACK_SCENARIOS:
		var entry = playback.get(scenario, {})
		if not (entry is Dictionary):
			return "Audio 07 playback scenario is absent: %s" % scenario
		if scenario == "local_reference_ab":
			if String(entry.get("physical_status", "")) != "NOT_RUN_LOCAL_ONLY":
				return "Local reference A/B must remain NOT_RUN_LOCAL_ONLY unless actually performed"
		else:
			if String(entry.get("physical_status", "")) != "PENDING":
				return "Physical playback was overclaimed for scenario: %s" % scenario
		if String(entry.get("automated_status", "")) != "COVERED":
			return "Automated coverage classification is missing for scenario: %s" % scenario

	var replacement = report.get("replacement_report", {})
	if not (replacement is Dictionary):
		return "Audio 07 replacement report is absent"
	var groups = replacement.get("slots_by_status", {})
	if not (groups is Dictionary):
		return "Audio 07 status-grouped slot inventory is absent"
	for status_name in STATUS_NAMES:
		if not (groups.get(status_name, []) is Array):
			return "Replacement report missing status group: %s" % status_name

	var current_slots := _all_current_slots()
	if int(replacement.get("total_slots", -1)) != current_slots.size():
		return "Replacement report total slot count drifted from runtime registry"
	for slot_id in current_slots.keys():
		var meta: Dictionary = current_slots[slot_id]
		var status_name := _status_name(int(meta.get("asset_status", -1)))
		if status_name == "UNKNOWN":
			return "Runtime slot has unknown replacement status: %s" % slot_id
		var reported_group: Array = groups.get(status_name, [])
		if not reported_group.has(slot_id):
			return "Replacement report omitted/misclassified slot: %s" % slot_id

	var seen_count := 0
	for status_name in STATUS_NAMES:
		var group: Array = groups[status_name]
		seen_count += group.size()
		for slot_id in group:
			if not current_slots.has(slot_id):
				return "Replacement report contains stale/unknown slot: %s" % slot_id
	if seen_count != current_slots.size():
		return "Replacement report duplicates or omits semantic slots"

	# Current retained slice is entirely procedural/original-in-repo fallback.
	# REFERENCE_ONLY remains a resolver status, but no such slot/media ships today.
	if not (groups["REFERENCE_ONLY"] as Array).is_empty():
		return "Current retained slice unexpectedly contains REFERENCE_ONLY slots"
	var shipping = report.get("shipping_boundary", {})
	if not (shipping is Dictionary):
		return "Audio 07 shipping/reference boundary is absent"
	if bool(shipping.get("reference_media_committed", true)):
		return "Retention report claims reference media is committed"
	if bool(shipping.get("local_manifest_committed", true)):
		return "Retention report claims a local reference manifest is committed"
	if bool(shipping.get("clean_export_requires_reference", true)):
		return "Clean export is incorrectly classified as requiring local reference media"
	if AudioReferenceResolverScript.is_reference_enabled():
		return "Reference resolver unexpectedly enabled in normal Audio 07 verification"

	var performance = report.get("performance_voice_policy", {})
	if not (performance is Dictionary):
		return "Audio 07 performance/voice policy is absent"
	if int(performance.get("ui_voice_cap", -1)) != UIAudioIdentityLayerScript.MAX_UI_VOICES:
		return "Audio 07 UI voice-cap report drifted from runtime policy"

	return ""
