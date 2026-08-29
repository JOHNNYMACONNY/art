extends SceneTree

const YardlineStationIdentityAudioProductionContractScript = preload("res://tests/yardline_station_identity_audio_production_contract.gd")

func _init() -> void:
	var err: String = YardlineStationIdentityAudioProductionContractScript.verify()
	if not err.is_empty():
		push_error("[01M_PRODUCTION_CONTRACT_FAIL] " + err)
		quit(1)
		return
	print("[01M_PRODUCTION_CONTRACT_PASS] Yardline station identity and sweeper production audio contract verified successfully.")
	quit(0)
