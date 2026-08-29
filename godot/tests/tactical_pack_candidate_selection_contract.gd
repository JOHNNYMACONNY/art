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

const EXPECTED_SLOT_SET: Array[String] = [
	"interaction.battery_insert",
	"interaction.panel_pry",
	"interaction.wire_clip",
	"pursuit.pursuer_sweep",
	"world.radio_chatter",
]

const SELECTION_TRUTH: Dictionary = {
	"interaction.panel_pry": {
		"production_path": "res://audio/interaction/sfx_interaction_panel_pry.wav",
		"winner_provenance": "GTA_SA:GENRL:BANK_76:SOUND_2",
		"winner_sample_rate": 18000,
		"winner_channels": 1,
		"winner_bit_depth": 16,
		"winner_frames": 17463,
		"winner_raw_bytes": 34926,
		"winner_duration_sec": 0.9702,
		"winner_peak_db": -2.0,
		"winner_rms_db": -14.68,
		"winner_raw_sha256": "2b39bb47f1da6a037c3ddd9c16f07f3e1a657a2e7d7ea4937cb8d5ac62277fc8",
		"winner_container_sha256": "dbe6ee0c8eb57018e4b43ad2ebb40602bce45e21a3592061a0800c2a76f4a13b",
		"runner_provenance": "GTA_SA:GENRL:BANK_68:SOUND_1",
		"runner_sample_rate": 11025,
		"runner_frames": 7700,
		"runner_raw_bytes": 15400,
		"runner_duration_sec": 0.6984,
		"runner_peak_db": -2.38,
		"runner_rms_db": -10.69,
		"runner_raw_sha256": "49407aeab8c1164c250a3da8cf81d807c673af23a92e16523cb3bead8289884f",
		"runner_container_sha256": "74bdd593ccbddc5db69ad8835edaea0d602e00093697bbadf82f8f96e21def5a",
	},
	"interaction.wire_clip": {
		"production_path": "res://audio/interaction/sfx_interaction_wire_clip.wav",
		"winner_provenance": "GTA_SA:GENRL:BANK_143:SOUND_17",
		"winner_sample_rate": 23000,
		"winner_channels": 1,
		"winner_bit_depth": 16,
		"winner_frames": 1999,
		"winner_raw_bytes": 3998,
		"winner_duration_sec": 0.0869,
		"winner_peak_db": -1.97,
		"winner_rms_db": -10.11,
		"winner_raw_sha256": "1418770fc0089bf5e309c13c1efe0f275c967ae4dc5feb433b104b560d64263d",
		"winner_container_sha256": "8957d4026569878f41d08ff1bcfa63906214d4c5701c083646841935d034d50b",
		"runner_provenance": "GTA_SA:GENRL:BANK_143:SOUND_18",
		"runner_sample_rate": 23000,
		"runner_frames": 2164,
		"runner_raw_bytes": 4328,
		"runner_duration_sec": 0.0941,
		"runner_peak_db": -1.98,
		"runner_rms_db": -12.67,
		"runner_raw_sha256": "ce721044b32c74b48838e952972b6053bb16f0b1641b2cc79c22c14f207413d8",
		"runner_container_sha256": "504eb17e779644598c12f28b901952f05c5504f1c7d1d2104e05eca3f0f16475",
	},
	"interaction.battery_insert": {
		"production_path": "res://audio/interaction/sfx_interaction_battery_insert.wav",
		"winner_provenance": "GTA_SA:GENRL:BANK_45:SOUND_1",
		"winner_sample_rate": 18000,
		"winner_channels": 1,
		"winner_bit_depth": 16,
		"winner_frames": 13804,
		"winner_raw_bytes": 27608,
		"winner_duration_sec": 0.7669,
		"winner_peak_db": -2.04,
		"winner_rms_db": -12.1,
		"winner_raw_sha256": "495f76eaab687d1036d7424138c400724ec1a629c2cdfff5df931697bebd49ca",
		"winner_container_sha256": "ff79a2e2810579ce890cd1af208dcd48f38be5cf5212423d099211b380e79f1d",
		"runner_provenance": "GTA_SA:GENRL:BANK_44:SOUND_0",
		"runner_sample_rate": 18000,
		"runner_frames": 15512,
		"runner_raw_bytes": 31024,
		"runner_duration_sec": 0.8618,
		"runner_peak_db": -0.48,
		"runner_rms_db": -12.75,
		"runner_raw_sha256": "95dc39a9319ce344ff184e90a1c2157bba7910ffc41dfc4d8879bce45e06874a",
		"runner_container_sha256": "f232b804dbaa2daf18a742979a7d6859f6c79357bb166a57b850f7c3b052d7ca",
	},
	"pursuit.pursuer_sweep": {
		"production_path": "res://audio/pursuit/loop_pursuit_scanner_sweep.wav",
		"winner_provenance": "GTA_SA:GENRL:BANK_138:SOUND_43",
		"winner_sample_rate": 20900,
		"winner_channels": 1,
		"winner_bit_depth": 16,
		"winner_frames": 8041,
		"winner_raw_bytes": 16082,
		"winner_duration_sec": 0.3847,
		"winner_peak_db": -2.0,
		"winner_rms_db": -20.98,
		"winner_raw_sha256": "5e4808d31142881192f1273dfef7cb304a694bb597c9e2fac6afc6d56edb4d80",
		"winner_container_sha256": "46a40bebd9f3b390863dc4e1c472bd4cf14800b46f510539696c2ed796312093",
		"runner_provenance": "GTA_SA:GENRL:BANK_138:SOUND_44",
		"runner_sample_rate": 22050,
		"runner_frames": 7402,
		"runner_raw_bytes": 14804,
		"runner_duration_sec": 0.3357,
		"runner_peak_db": -7.76,
		"runner_rms_db": -20.46,
		"runner_raw_sha256": "b18e24194ab048b7fb9213d703a5abf6619b6cc7d6ea45146fee284a122616d9",
		"runner_container_sha256": "819e42aa2faecf95715eb626c5322c843ebe25381884911e23ac11389479212b",
	},
	"world.radio_chatter": {
		"production_path": "res://audio/world/sfx_world_radio_chatter.wav",
		"winner_provenance": "GTA_SA:SCRIPT:BANK_356:SOUND_16",
		"winner_sample_rate": 15000,
		"winner_channels": 1,
		"winner_bit_depth": 16,
		"winner_frames": 9909,
		"winner_raw_bytes": 19818,
		"winner_duration_sec": 0.6606,
		"winner_peak_db": -2.0,
		"winner_rms_db": -14.36,
		"winner_raw_sha256": "621aa1348b7d2e9bcdf40d10658e97b456ef594c925e983102a83342e5cc3c0b",
		"winner_container_sha256": "93358b3a23f17aeefdc8b5d10f4608e4c7f2c1fa507564d12bb32688ca147b49",
		"runner_provenance": "GTA_SA:SCRIPT:BANK_356:SOUND_1",
		"runner_sample_rate": 15000,
		"runner_frames": 16003,
		"runner_raw_bytes": 32006,
		"runner_duration_sec": 1.0669,
		"runner_peak_db": -2.0,
		"runner_rms_db": -14.4,
		"runner_raw_sha256": "95cc0a30a1a3ec2196ed51753c34978cf12b1a25ceb0e66de38517ff947ba60d",
		"runner_container_sha256": "35ef5bc11467571c596f64281ac091be2af1cb5a525273520e2587289eac33c4",
	},
}

static func verify() -> String:
	var target_slots := SelectionLockScript.get_target_slots()
	if target_slots != EXPECTED_SLOT_SET:
		return "01P target slots mismatch: expected %s, got %s" % [str(EXPECTED_SLOT_SET), str(target_slots)]

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
		var import_path := "%s.import" % prod_path
		if FileAccess.file_exists(import_path):
			return "%s production import sidecar %s must NOT exist prior to media authorization" % [slot_id, import_path]

		# Exact value verification against audition truth
		var truth: Dictionary = SELECTION_TRUTH.get(slot_id, {})
		if truth.is_empty():
			return "%s missing selection truth definition" % slot_id

		for k in truth.keys():
			if not lock.has(k):
				return "%s lock missing key %s" % [slot_id, k]
			if typeof(truth[k]) == TYPE_FLOAT:
				if absf(float(lock[k]) - float(truth[k])) > 0.001:
					return "%s lock float mismatch for %s: expected %f, got %f" % [slot_id, k, float(truth[k]), float(lock[k])]
			elif str(lock[k]) != str(truth[k]):
				return "%s lock mismatch for %s: expected %s, got %s" % [slot_id, k, str(truth[k]), str(lock[k])]

	return ""
