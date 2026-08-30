class_name YardlineMusicCandidateSelectionContract
extends RefCounted

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const SelectionLockScript = preload("res://tests/yardline_music_selection_lock.gd")

const TARGET_SLOTS: Array[String] = [
	"radio.yardline.song_01.intro",
	"radio.yardline.song_01.body",
	"radio.yardline.song_01.outro",
	"radio.yardline.song_02.body",
	"radio.yardline.song_03.body",
	"radio.yardline.song_04.body",
]

static func _verify_slot_state(slot_id: String) -> String:
	if not AudioRegistryScript.has_slot(slot_id):
		return "AudioRegistry missing slot %s" % slot_id

	var meta: Dictionary = AudioRegistryScript.get_slot(slot_id)
	if meta.get("domain") != AudioRegistryScript.Domain.RADIO:
		return "%s domain must remain Domain.RADIO" % slot_id
	if meta.get("diegesis") != AudioRegistryScript.Diegesis.DIEGETIC:
		return "%s diegesis must remain Diegesis.DIEGETIC" % slot_id
	if meta.get("mix_group") != AudioRegistryScript.MixGroup.RADIO_MUSIC:
		return "%s mix_group must remain MixGroup.RADIO_MUSIC" % slot_id
	if meta.get("playback_type") != AudioRegistryScript.PlaybackType.TRANSIENT:
		return "%s playback_type must remain PlaybackType.TRANSIENT" % slot_id

	# Candidate selection stage invariants: must remain procedural fallback until media ingestion
	if meta.get("asset_status") != AudioRegistryScript.AssetStatus.PROCEDURAL_FALLBACK:
		return "%s asset_status must remain PROCEDURAL_FALLBACK at candidate lock stage" % slot_id
	if not bool(meta.get("replacement_required", false)):
		return "%s replacement_required must remain true at candidate lock stage" % slot_id
	if not AudioRegistryScript.get_production_asset_path(slot_id).is_empty():
		return "%s production path must remain empty at candidate lock stage" % slot_id
	if not AudioRegistryScript.get_source_provenance(slot_id).is_empty():
		return "%s source provenance must remain empty at candidate lock stage" % slot_id

	var lock: Dictionary = SelectionLockScript.get_selection(slot_id)
	if lock.is_empty():
		return "%s missing selection lock entry" % slot_id
	if String(lock.get("winner_provenance", "")).is_empty():
		return "%s missing winner provenance in selection lock" % slot_id
	if String(lock.get("winner_container_sha256", "")).is_empty():
		return "%s missing winner container SHA-256 in selection lock" % slot_id
	if String(lock.get("winner_raw_sha256", "")).is_empty():
		return "%s missing winner raw PCM SHA-256 in selection lock" % slot_id
	if String(lock.get("runner_up_provenance", "")).is_empty():
		return "%s missing runner-up provenance in selection lock" % slot_id
	if String(lock.get("runner_up_container_sha256", "")).is_empty():
		return "%s missing runner-up container SHA-256 in selection lock" % slot_id
	if String(lock.get("runner_up_raw_sha256", "")).is_empty():
		return "%s missing runner-up raw PCM SHA-256 in selection lock" % slot_id

	# Ensure production media files are NOT yet committed in tree
	var planned_path: String = String(lock.get("production_path", ""))
	if not planned_path.is_empty() and FileAccess.file_exists(planned_path):
		return "%s production WAV %s must not be committed at candidate lock stage" % [slot_id, planned_path]

	return ""

static func verify() -> String:
	var all_slots := SelectionLockScript.get_all_slots()
	if all_slots.size() != 6:
		return "Selection lock must define exactly 6 slots, found %d" % all_slots.size()

	for slot_id in TARGET_SLOTS:
		var err := _verify_slot_state(slot_id)
		if not err.is_empty():
			return err

	return ""
