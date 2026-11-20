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
	# Scene-level location fixtures only: no keyboard movement or mission outcome
	# is inferred from these waypoint assertions.
	var wayfinding: Label = adapter.get("_bike_wayfinding_label") as Label
	var camera: Camera3D = game.get_node_or_null("ChinatownCamera3D") as Camera3D
	if wayfinding == null or camera == null or not wayfinding.visible or not wayfinding.text.begins_with("COURIER BIKE // "):
		await _fail("Opening courier bearing/distance HUD missing", game)
		return
	var spawn: Vector3 = runner.global_position
	var spawn_delta: Vector3 = bike.global_position - spawn
	spawn_delta.y = 0.0
	if not wayfinding.text.contains("%dm" % ceili(spawn_delta.length())):
		await _fail("Courier HUD does not measure actual bike distance", game)
		return

	var right: Vector3 = camera.global_transform.basis.x
	right.y = 0.0
	runner.global_position = bike.global_position - right.normalized() * 8.0
	adapter.call("_update_bike_wayfinding")
	if not wayfinding.text.ends_with(" // RIGHT"):
		await _fail("Courier bearing is not camera-right: %s" % wayfinding.text, game)
		return

	var forward: Vector3 = -camera.global_transform.basis.z
	forward.y = 0.0
	runner.global_position = bike.global_position - forward.normalized() * 8.0
	adapter.call("_update_bike_wayfinding")
	if not wayfinding.text.ends_with(" // AHEAD"):
		await _fail("Courier bearing is not camera-forward: %s" % wayfinding.text, game)
		return

	runner.global_position = bike.global_position + Vector3(0.0, 0.0, 1.0)
	adapter.call("_update_bike_wayfinding")
	if not wayfinding.text.ends_with(" // SEEK [E] RIDE BIKE"):
		await _fail("Near-bike affordance hides the actual interaction verb", game)
		return
	runner.global_position = spawn
	adapter.call("_update_bike_wayfinding")

	var marker: Label3D = tuner.get_node_or_null("MissionTunerMastMarker") as Label3D
	var tuner_wayfinding: Label = adapter.get("_tuner_wayfinding_label") as Label
	if tuner_wayfinding == null or tuner_wayfinding.visible:
		await _fail("Tuner approach cue revealed before courier mission phase", game)
		return
	if marker == null or marker.visible:
		await _fail("Mast marker missing or prematurely revealing future mission target", game)
		return
	if not mission.on_courier_bike_mounted():
		await _fail("Mission fixture could not enter tuner traversal", game)
		return
	adapter.call("_update_bike_wayfinding")
	if wayfinding.visible:
		await _fail("Courier waypoint leaked into later mission phases", game)
		return
	adapter.call("_update_tuner_mast_marker")
	adapter.call("_update_tuner_wayfinding")
	if not tuner_wayfinding.visible or not tuner_wayfinding.text.begins_with("TUNER MAST // "):
		await _fail("Tuner travel phase lacks range/direction cue", game)
		return
	if not marker.visible or marker.text != "TUNER MAST":
		await _fail("Authored mast landmark absent during traverse", game)
		return
	if not mission.on_tuner_arrived():
		await _fail("Mission fixture could not enter signal spoof", game)
		return
	adapter.call("_update_tuner_mast_marker")
	adapter.call("_update_tuner_wayfinding")
	if not tuner_wayfinding.visible or not tuner_wayfinding.text.begins_with("SPOOF SIGNAL // "):
		await _fail("Spoof phase lost tuner range/direction cue", game)
		return
	if not marker.visible or marker.text != "SPOOF SIGNAL":
		await _fail("Mast landmark failed to switch to spoof objective", game)
		return

	# Arrival at 5m does not mean E is valid at the terminal's 2.5m radius.
	# Verify real game visibility semantics without widening the action range.
	var tuner_far := _select_at(game, runner, tuner.global_position + Vector3(0.0, 0.0, 4.0))
	adapter.call("_update_tuner_wayfinding")
	if tuner_wayfinding.text.find("MOVE CLOSER") == -1 or tuner_far == "[E] TUNE SIGNAL":
		await _fail("Tuner falsely advertises E at the arrival boundary: %s" % tuner_wayfinding.text, game)
		return
	_select_at(game, runner, tuner.global_position + Vector3(0.0, 0.0, 0.5))
	adapter.call("_update_tuner_wayfinding")
	if not tuner_wayfinding.text.ends_with("SEEK [E] TUNE SIGNAL"):
		await _fail("Eligible near tuner did not reveal E guidance: %s" % tuner_wayfinding.text, game)
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
	adapter.call("_update_tuner_wayfinding")
	if tuner_wayfinding.visible:
		await _fail("Tuner distance cue leaked after signal lock", game)
		return
	if marker.visible or int(mission.phase) != int(MissionScript.Phase.EXTRACT_CORE):
		await _fail("Signal-lock transition failed to retire mast marker or enable extraction", game)
		return
	if not panel.is_powered:
		await _fail("Retained tuner-to-panel power dependency broke", game)
		return

	var panel_marker: Label3D = panel.get_node_or_null("MissionCorePanelMarker") as Label3D
	var panel_wayfinding: Label = adapter.get("_panel_wayfinding_label") as Label
	if panel_marker == null or not panel_marker.visible or panel_wayfinding == null or not panel_wayfinding.visible:
		await _fail("Retained extraction objective lacks its phase-gated panel landmark and HUD", game)
		return
	if not panel_wayfinding.text.begins_with("CORE PANEL // "):
		await _fail("Core panel distance/bearing label missing", game)
		return

	panel.call("_on_body_entered", runner)
	# Magnetism is 3.5m wide, but E becomes valid only within the
	# interactable's 2.5m radius. This reproduces the black-box false
	# [E] PEEL PANEL at an unreachable distance after tuner lock.
	var too_far: Vector3 = panel.global_position + Vector3(0.0, 0.0, 3.0)
	var far_prompt := _select_at(game, runner, too_far)
	if game.get("_active_target") == panel or far_prompt == "[E] PEEL PANEL":
		await _fail("Panel action falsely advertised outside its actual E radius", game)
		return
	adapter.call("_update_panel_wayfinding")
	if not panel_wayfinding.text.contains("3m"):
		await _fail("Panel bearing failed to measure the three-meter approach", game)
		return
	bike.global_position = panel.global_position + Vector3(0.0, -0.45, 0.9)
	var panel_prompt := _select_at(game, runner, panel.global_position + Vector3(0.0, 0.0, 0.5))
	if not mount.can_interact(runner.global_position) or not panel.can_interact(runner.global_position):
		await _fail("Recreated panel-versus-bike interaction overlap is not eligible", game)
		return
	if panel_prompt != "[E] PEEL PANEL" or game.get("_active_target") != panel:
		await _fail("Bike incorrectly stole active core-panel objective: %s" % panel_prompt, game)
		return
	game.call("_on_action_pressed")
	if int(panel.current_step) != int(CorrodedPanel.Step.PEELING):
		await _fail("Visible E panel action did not begin actual peeling", game)
		return

	print("[MISSION_TUNER_GUIDANCE_214] PASS — courier/tuner/panel bearings, tuner arrival-versus-E radius, panel E parity, peel start, phase markers, mission-terminal priority")
	await _finish(0, game)
