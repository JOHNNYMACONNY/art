extends SceneTree

# #214 — authored tuner/panel guidance, selection and transition contract.
# These are scene-runtime assertions with fixture placement, NOT proof of real
# keyboard steering, dismount, mouse tuning, or mission completion.
const MissionScript = preload("res://scripts/missions/scrap_job_mission.gd")
const SCENE := "res://scenes/prototype/scrap_test_block.tscn"

func _init() -> void:
	call_deferred("_run")

func _finish(code: int, scene: Node = null) -> void:
	if is_instance_valid(scene):
		scene.queue_free()
	await process_frame
	await process_frame
	quit(code)

func _fail(message: String, scene: Node = null) -> void:
	push_error("[MISSION_TUNER_GUIDANCE_214] %s" % message)
	await _finish(1, scene)

func _select_at(game: Node3D, runner: Node3D, position: Vector3) -> String:
	runner.global_position = position
	for item in game.get("_interactables"):
		if is_instance_valid(item):
			item.update_player_distance(runner.global_position)
	game.call("_evaluate_target_selection")
	var ui: Node = game.get("touch_ui") as Node
	var button: Button = ui.get("action_button") as Button if ui != null else null
	return button.text if button != null else ""

func _run() -> void:
	var packed: PackedScene = load(SCENE) as PackedScene
	if packed == null:
		await _fail("Opening playable scene failed to load")
		return
	var game: Node3D = packed.instantiate() as Node3D
	root.add_child(game)
	await process_frame
	await physics_frame
	await physics_frame
	var runner: Node3D = game.get_node_or_null("Runner") as Node3D
	var adapter: Node = game.get_node_or_null("MissionScrapJobRuntime")
	var tuner: SignalTuner = game.get("signal_tuner") as SignalTuner
	var panel: CorrodedPanel = game.get("corroded_panel") as CorrodedPanel
	var bike: CourierBike = game.get("courier_bike") as CourierBike
	var mount: MountInteractable = bike.get_node_or_null("MountInteractable") as MountInteractable if bike != null else null
	if runner == null or adapter == null or tuner == null or panel == null or bike == null or mount == null or not bool(adapter.get("_bound")):
		await _fail("Retained playable mission/tuner/panel not bound", game)
		return

	var mission = adapter.get("mission")
	var marker: Label3D = tuner.get_node_or_null("MissionTunerMastMarker") as Label3D
	if marker == null or marker.visible:
		await _fail("Mast marker missing or prematurely revealing future mission target", game)
		return
	if not mission.on_courier_bike_mounted():
		await _fail("Mission fixture could not enter tuner traversal", game)
		return
	adapter.call("_update_tuner_mast_marker")
	if not marker.visible or marker.text != "TUNER MAST":
		await _fail("Authored mast landmark absent during traverse", game)
		return
	if not mission.on_tuner_arrived():
		await _fail("Mission fixture could not enter signal spoof", game)
		return
	adapter.call("_update_tuner_mast_marker")
	if not marker.visible or marker.text != "SPOOF SIGNAL":
		await _fail("Mast landmark failed to switch to spoof objective", game)
		return

	# Simulate two simultaneously eligible targets to reproduce the exact
	# real-browser bug: after dismount E would remount the nearer parked bike.
	# Placement is a WHITE-BOX fixture only, never part of browser gameplay.
	var parked_position: Vector3 = bike.global_position
	bike.global_position = tuner.global_position + Vector3(0.0, -0.35, 0.9)
	var tuner_prompt := _select_at(game, runner, tuner.global_position + Vector3(0.0, 0.0, 0.5))
	if not mount.can_interact(runner.global_position) or not tuner.can_interact(runner.global_position):
		await _fail("Recreated tuner-versus-bike interaction overlap is not eligible", game)
		return
	if tuner_prompt != "[E] TUNE SIGNAL" or game.get("_active_target") != tuner:
		await _fail("Bike incorrectly stole active tuner objective: %s" % tuner_prompt, game)
		return
	bike.global_position = parked_position

	# Existing production signal—not direct mission mutation—powers the panel.
	tuner.call("_lock_signal")
	adapter.call("_update_tuner_mast_marker")
	if marker.visible or int(mission.phase) != int(MissionScript.Phase.EXTRACT_CORE):
		await _fail("Signal-lock transition failed to retire mast marker or enable extraction", game)
		return
	if not panel.is_powered:
		await _fail("Retained tuner-to-panel power dependency broke", game)
		return
	panel.call("_on_body_entered", runner)
	bike.global_position = panel.global_position + Vector3(0.0, -0.45, 0.9)
	var panel_prompt := _select_at(game, runner, panel.global_position + Vector3(0.0, 0.0, 0.5))
	if not mount.can_interact(runner.global_position) or not panel.can_interact(runner.global_position):
		await _fail("Recreated panel-versus-bike interaction overlap is not eligible", game)
		return
	if panel_prompt != "[E] PEEL PANEL" or game.get("_active_target") != panel:
		await _fail("Bike incorrectly stole active core-panel objective: %s" % panel_prompt, game)
		return

	print("[MISSION_TUNER_GUIDANCE_214] PASS — phase-gated markers, priority of eligible mission terminals over parked bike, retained signal gate")
	await _finish(0, game)
