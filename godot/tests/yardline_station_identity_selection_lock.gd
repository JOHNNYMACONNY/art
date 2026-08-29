extends RefCounted

## Audio Production 01M source-selection lock.
## These values are human-auditioned source identity and technical metadata.
## Production integration contracts should consume this lock rather than duplicate it.

const LOCKED_SELECTIONS: Dictionary = {
	"radio.yardline.dj_sweeper": {
		"production_path": "res://audio/radio/rad_yardline_dj_sweeper.wav",
		"winner_provenance": "GTA_SA:GENRL:BANK_44:SOUND_2",
		"winner_sample_rate": 18000,
		"winner_channels": 1,
		"winner_bit_depth": 16,
		"winner_frames": 8016,
		"winner_duration_sec": 0.4453,
		"winner_raw_bytes": 16032,
		"winner_raw_sha256": "188837f05074b791060d41d5265851be7ef84b443c54b4f42d8fd40f941022b3",
		"runner_up_provenance": "GTA_SA:SCRIPT:BANK_356:SOUND_16",
		"runner_up_sample_rate": 15000,
		"runner_up_channels": 1,
		"runner_up_bit_depth": 16,
		"runner_up_frames": 9909,
		"runner_up_duration_sec": 0.6606,
		"runner_up_raw_bytes": 19818,
		"runner_up_raw_sha256": "621aa1348b7d2e9bcdf40d10658e97b456ef594c925e983102a83342e5cc3c0b",
		"edge_treatment": "NONE_NATURAL_BOUNDARY",
	},
	"radio.yardline.station_id_01": {
		"production_path": "res://audio/radio/rad_yardline_station_id_01.wav",
		"winner_provenance": "GTA_SA:GENRL:BANK_44:SOUND_3",
		"winner_sample_rate": 18000,
		"winner_channels": 1,
		"winner_bit_depth": 16,
		"winner_frames": 18176,
		"winner_duration_sec": 1.0098,
		"winner_raw_bytes": 36352,
		"winner_raw_sha256": "a742e3d686fcfa91f8b643e0a820580a78dcd40db34f4c73ce517c894340c842",
		"runner_up_provenance": "GTA_SA:SCRIPT:BANK_356:SOUND_2",
		"runner_up_sample_rate": 15000,
		"runner_up_channels": 1,
		"runner_up_bit_depth": 16,
		"runner_up_frames": 28244,
		"runner_up_duration_sec": 1.8829,
		"runner_up_raw_bytes": 56488,
		"runner_up_raw_sha256": "96677f627d502e1650f48841b00ab828f1117ddef117c36b00093f8fb85854a1",
		"edge_treatment": "NONE_NATURAL_BOUNDARY",
	},
	"radio.yardline.station_id_02": {
		"production_path": "res://audio/radio/rad_yardline_station_id_02.wav",
		"winner_provenance": "GTA_SA:GENRL:BANK_44:SOUND_4",
		"winner_sample_rate": 18000,
		"winner_channels": 1,
		"winner_bit_depth": 16,
		"winner_frames": 11872,
		"winner_duration_sec": 0.6596,
		"winner_raw_bytes": 23744,
		"winner_raw_sha256": "7550cdb3f12086f78bea71b752b0edbd5e1f46b1e83136c459de5cc978d99051",
		"runner_up_provenance": "GTA_SA:SCRIPT:BANK_356:SOUND_13",
		"runner_up_sample_rate": 12000,
		"runner_up_channels": 1,
		"runner_up_bit_depth": 16,
		"runner_up_frames": 8534,
		"runner_up_duration_sec": 0.7112,
		"runner_up_raw_bytes": 17068,
		"runner_up_raw_sha256": "a3c7719ce246781d50c261898890aced94d0fb632064cc1e51b01846b536b4f5",
		"edge_treatment": "NONE_NATURAL_BOUNDARY",
	},
}

static func get_selection(slot_id: String) -> Dictionary:
	return LOCKED_SELECTIONS.get(slot_id, {}).duplicate(true)

static func get_target_slots() -> Array[String]:
	var result: Array[String] = []
	for slot_id in LOCKED_SELECTIONS.keys():
		result.append(String(slot_id))
	result.sort()
	return result
