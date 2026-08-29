extends SceneTree

const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")
const UIAudioIdentityLayerScript = preload("res://scripts/audio/ui_audio_identity_layer.gd")
const CandidateContract = preload("res://tests/ui_audio_identity_candidate_selection_contract.gd")

var _manager: Node = null

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	_manager = AudioManagerScript.new()
	root.add_child(_manager)
	var layer := UIAudioIdentityLayerScript.new()
	layer.name = "UIAudioIdentityLayer"
	_manager.add_child(layer)
	layer.call("configure", _manager)
	await process_frame

	var error := CandidateContract.verify(_manager, layer)
	if not error.is_empty():
		push_error("[AUDIO_PRODUCTION_01N_CANDIDATE] %s" % error)
		_manager.queue_free()
		await process_frame
		quit(1)
		return

	print("[AUDIO_PRODUCTION_01N_CANDIDATE] PASS (7 UI winner selections locked; registry fallback-only; production media absent; procedural fallbacks retained)")
	_manager.queue_free()
	await process_frame
	quit(0)
