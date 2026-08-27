extends SceneTree

const CAPTURE_ENV := "GEARS_VERIFICATION_CAPTURE"
const SCENE_PATH := "res://scenes/prototype/scrap_test_block.tscn"
const WATCHDOG_SECONDS := 120.0

func _init() -> void:
	call_deferred("_bootstrap")

func _bootstrap() -> void:
	# Set the activation flag in this same Godot process before the real scene is
	# instantiated, so the embedded verification driver cannot miss activation.
	OS.set_environment(CAPTURE_ENV, "1")

	var packed := load(SCENE_PATH) as PackedScene
	if packed == null:
		push_error("[GEARS_VERIFICATION_RUNNER] Could not load %s" % SCENE_PATH)
		quit(1)
		return

	var scene := packed.instantiate() as Node3D
	if scene == null:
		push_error("[GEARS_VERIFICATION_RUNNER] Could not instantiate real playable scene")
		quit(1)
		return

	root.add_child(scene)
	await process_frame
	var driver := scene.get_node_or_null("VerificationCaptureDriver")
	if driver == null:
		push_error("[GEARS_VERIFICATION_RUNNER] Real scene is missing VerificationCaptureDriver")
		quit(1)
		return

	print("[GEARS_VERIFICATION_RUNNER] Real scene instantiated; capture driver activated")
	await create_timer(WATCHDOG_SECONDS).timeout
	# Successful capture exits the tree before this watchdog. Reaching here means
	# the driver started but failed to terminate deterministically.
	push_error("[GEARS_VERIFICATION_RUNNER] Capture driver watchdog expired")
	quit(1)
