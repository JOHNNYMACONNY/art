extends RefCounted

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const SelectionLockScript = preload("res://tests/tactical_pack_selection_lock.gd")

const TARGET_METADATA: Dictionary = {
	"interaction.panel_pry": {
		"domain": AudioRegistryScript.Domain.INTERACTION,
		"diegesis": AudioRegistryScript.Diegesis.DIEGETIC,
		"spatial": AudioRegistryScript.SpatialType.DIEGETIC_3D,
		"mix": AudioRegistryScript.MixGroup.INCIDENTAL_UI,
		"playback": AudioRegistryScript.PlaybackType.TRANSIENT,
		"is_looping": false,
		"concurrency": 2,
	},
	"interaction.wire_clip": {
		"domain": AudioRegistryScript.Domain.INTERACTION,
		"diegesis": AudioRegistryScript.Diegesis.DIEGETIC,
		"spatial": AudioRegistryScript.SpatialType.DIEGETIC_3D,
		"mix": AudioRegistryScript.MixGroup.INCIDENTAL_UI,
		"playback": AudioRegistryScript.PlaybackType.TRANSIENT,
		"is_looping": false,
		"concurrency": 2,
	},
	"interaction.battery_insert": {
		"domain": AudioRegistryScript.Domain.INTERACTION,
		"diegesis": AudioRegistryScript.Diegesis.DIEGETIC,
		"spatial": AudioRegistryScript.SpatialType.DIEGETIC_3D,
		"mix": AudioRegistryScript.MixGroup.INCIDENTAL_UI,
		"playback": AudioRegistryScript.PlaybackType.TRANSIENT,
		"is_looping": false,
		"concurrency": 2,
	},
	"pursuit.pursuer_sweep": {
		"domain": AudioRegistryScript.Domain.PURSUIT,
		"diegesis": AudioRegistryScript.Diegesis.DIEGETIC,
		"spatial": AudioRegistryScript.SpatialType.DIEGETIC_3D,
		"mix": AudioRegistryScript.MixGroup.CRITICAL_THREAT,
		"playback": AudioRegistryScript.PlaybackType.CONTINUOUS_LOOP,
		"is_looping": true,
		"concurrency": 2,
	},
	"world.radio_chatter": {
		"domain": AudioRegistryScript.Domain.WORLD,
		"diegesis": AudioRegistryScript.Diegesis.DIEGETIC,
		"spatial": AudioRegistryScript.SpatialType.DIEGETIC_3D,
		"mix": AudioRegistryScript.MixGroup.RADIO_MUSIC,
		"playback": AudioRegistryScript.PlaybackType.TRANSIENT,
		"is_looping": false,
		"concurrency": 1,
	},
}

static func verify() -> String:
	var target_slots := SelectionLockScript.get_target_slots()
	if target_slots.size() != 5:
		return "Expected exactly 5 target slots in 01P tactical selection lock, found %d" % target_slots.size()

	for slot_id in target_slots:
		if not AudioRegistryScript.has_slot(slot_id):
			return "AudioRegistry missing target slot %s" % slot_id

		var slot_meta: Dictionary = AudioRegistryScript.get_slot(slot_id)
		var exp_meta: Dictionary = TARGET_METADATA.get(slot_id, {})
		if exp_meta.is_empty():
			return "Missing target metadata definition for %s" % slot_id

		if slot_meta.get("domain") != exp_meta["domain"]:
			return "%s domain mismatch: expected %d, got %d" % [slot_id, exp_meta["domain"], slot_meta.get("domain", -1)]
		if slot_meta.get("diegesis") != exp_meta["diegesis"]:
			return "%s diegesis mismatch: expected %d, got %d" % [slot_id, exp_meta["diegesis"], slot_meta.get("diegesis", -1)]
		if slot_meta.get("spatial_type") != exp_meta["spatial"]:
			return "%s spatial_type mismatch: expected %d, got %d" % [slot_id, exp_meta["spatial"], slot_meta.get("spatial_type", -1)]
		if slot_meta.get("mix_group") != exp_meta["mix"]:
			return "%s mix_group mismatch: expected %d, got %d" % [slot_id, exp_meta["mix"], slot_meta.get("mix_group", -1)]
		if slot_meta.get("playback_type") != exp_meta["playback"]:
			return "%s playback_type mismatch: expected %d, got %d" % [slot_id, exp_meta["playback"], slot_meta.get("playback_type", -1)]
		if bool(slot_meta.get("is_looping", false)) != bool(exp_meta["is_looping"]):
			return "%s is_looping mismatch: expected %s" % [slot_id, str(exp_meta["is_looping"])]
		if int(slot_meta.get("max_concurrency", 0)) != int(exp_meta["concurrency"]):
			return "%s max_concurrency mismatch: expected %d, got %d" % [slot_id, exp_meta["concurrency"], slot_meta.get("max_concurrency", 0)]

		# Frozen candidate-stage invariants:
		if slot_meta.get("asset_status") != AudioRegistryScript.AssetStatus.PROCEDURAL_FALLBACK:
			return "%s must remain PROCEDURAL_FALLBACK during candidate selection phase" % slot_id
		if not bool(slot_meta.get("replacement_required", false)):
			return "%s replacement_required must remain true during candidate selection phase" % slot_id
		if not AudioRegistryScript.get_production_asset_path(slot_id).is_empty():
			return "%s production_asset_path must remain empty before media ingestion" % slot_id
		if not AudioRegistryScript.get_source_provenance(slot_id).is_empty():
			return "%s source_provenance must remain empty before media ingestion" % slot_id

		var lock: Dictionary = SelectionLockScript.get_selection(slot_id)
		if lock.is_empty():
			return "%s selection lock missing" % slot_id
		var prod_path: String = String(lock.get("production_path", ""))
		if FileAccess.file_exists(prod_path):
			return "%s production WAV %s must NOT exist prior to media authorization" % [slot_id, prod_path]

		# Verify winner lock schema completeness
		var req_winner_fields := [
			"winner_provenance", "winner_sample_rate", "winner_frames",
			"winner_raw_bytes", "winner_duration_sec", "winner_peak_db",
			"winner_rms_db", "winner_raw_sha256", "winner_container_sha256",
			"runner_provenance", "runner_sample_rate", "runner_frames",
			"runner_raw_bytes", "runner_duration_sec", "runner_peak_db",
			"runner_rms_db", "runner_raw_sha256", "runner_container_sha256"
		]
		for f in req_winner_fields:
			if not lock.has(f):
				return "%s lock missing required field %s" % [slot_id, f]

	return ""
