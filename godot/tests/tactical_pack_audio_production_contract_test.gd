extends SceneTree

const TacticalPackAudioProductionContract = preload("res://tests/tactical_pack_audio_production_contract.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var error: String = TacticalPackAudioProductionContract.verify()
	if not error.is_empty():
		push_error("[AUDIO_PRODUCTION_01P] FAIL: %s" % error)
		quit(1)
		return

	print("[AUDIO_PRODUCTION_01P] PASS: 5 tactical slots promoted to LICENSED_FINAL, raw PCM SHA-256 verified, uncompressed import sidecars validated, stream resolution confirmed")
	quit(0)
