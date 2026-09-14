extends SceneTree

# Dedicated Integration & Contract Test for Muscle Coupe Full Drive Integration
# Verifies:
# 1. Vehicle hierarchy, rider socket, mount interactable
# 2. V8 Muscle high-performance constants & physical parameters
# 3. Mount flow, smoothstep posture blend, car driving posture
# 4. Driving physics, gear transitions, steering, brake screech
# 5. Dismount rejection at speed & safe dismount resolution
# 6. Checkpoint ram breach capability
# 7. Reset slice restoration

const ScrapTestBlockScript = preload("res://scripts/prototype/scrap_test_block.gd")
const MuscleCoupeScript = preload("res://scripts/vehicles/muscle_coupe.gd")

var _scene: Node = null

func _init() -> void:
	call_deferred("_run")

func _finish(exit_code: int) -> void:
	if is_instance_valid(_scene):
		_scene.queue_free()
		await process_frame
		await process_frame
	quit(exit_code)

func _fail(message: String) -> void:
	push_error("[MUSCLE_COUPE_TEST] " + message)
	await _finish(1)

func _run() -> void:
	print("\n=========================================================================")
	print("[MUSCLE_COUPE_INTEGRATION_TEST] Starting Verification...")
	print("=========================================================================\n")

	var scene_res := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if not scene_res:
		await _fail("Failed to load scrap_test_block.tscn")
		return

	_scene = scene_res.instantiate()
	root.add_child(_scene)
	await process_frame
	await process_frame

	var coupe = _scene.get("muscle_coupe") as MuscleCoupe
	if not coupe:
		await _fail("STAGE 1 FAIL: muscle_coupe node missing on scrap_test_block controller")
		return

	# Stage 1: Hierarchy & Nodes
	print("--- Stage 1: Vehicle Hierarchy & Components ---")
	if not coupe.has_node("CollisionShape3D"):
		await _fail("STAGE 1 FAIL: CollisionShape3D missing")
		return
	if not coupe.has_node("VisualRoot"):
		await _fail("STAGE 1 FAIL: VisualRoot missing")
		return
	if not coupe.has_node("RiderSocket"):
		await _fail("STAGE 1 FAIL: RiderSocket missing")
		return
	if not coupe.has_node("MountInteractable"):
		await _fail("STAGE 1 FAIL: MountInteractable missing")
		return
	print("  [STAGE 1 PASS] Vehicle hierarchy verified.")

	# Stage 2: Constants & Contract
	print("\n--- Stage 2: Performance & Vehicle Constants ---")
	if not is_equal_approx(coupe.max_speed, 21.0):
		await _fail("STAGE 2 FAIL: max_speed expected 21.0, got %.2f" % coupe.max_speed)
		return
	if not is_equal_approx(coupe.acceleration, 14.5):
		await _fail("STAGE 2 FAIL: acceleration expected 14.5, got %.2f" % coupe.acceleration)
		return
	if not is_equal_approx(coupe.braking_friction, 14.0):
		await _fail("STAGE 2 FAIL: braking_friction expected 14.0, got %.2f" % coupe.braking_friction)
		return
	if not is_equal_approx(coupe.steering_speed, 2.4):
		await _fail("STAGE 2 FAIL: steering_speed expected 2.4, got %.2f" % coupe.steering_speed)
		return
	if not is_equal_approx(coupe.dismount_speed_limit, 1.5):
		await _fail("STAGE 2 FAIL: dismount_speed_limit expected 1.5, got %.2f" % coupe.dismount_speed_limit)
		return
	print("  [STAGE 2 PASS] Performance constants verified.")

	# Stage 3: Mount & Seating Posture
	print("\n--- Stage 3: Mount & Seating Posture ---")
	var player = _scene.get("player")
	if not player:
		await _fail("STAGE 3 FAIL: player missing")
		return

	player.global_position = coupe.global_position + Vector3(0.5, 0.0, 0.5)
	coupe.mount_interactable.update_player_distance(player.global_position)
	var mount_ok: bool = coupe.request_mount(player)
	if not mount_ok:
		await _fail("STAGE 3 FAIL: coupe.request_mount returned false")
		return

	# Wait for 0.25s mount blend timer
	await create_timer(0.25).timeout
	await process_frame

	if coupe.current_state != MuscleCoupe.VehicleState.DRIVING:
		await _fail("STAGE 3 FAIL: coupe state not DRIVING after mount blend")
		return
	if coupe.occupant != player:
		await _fail("STAGE 3 FAIL: coupe occupant is not player")
		return
	if player.current_vehicle_posture != "car":
		await _fail("STAGE 3 FAIL: player posture not 'car', got: %s" % player.current_vehicle_posture)
		return
	if not player.is_mounted:
		await _fail("STAGE 3 FAIL: player.is_mounted is false")
		return
	if _scene.get("active_vehicle") != coupe:
		await _fail("STAGE 3 FAIL: controller active_vehicle is not coupe")
		return
	print("  [STAGE 3 PASS] Mount and car posture verified.")

	# Stage 4: Driving Physics, Gears & Brake
	print("\n--- Stage 4: Driving Physics & Gear Transitions ---")
	# Forward drive
	for _i in range(30):
		coupe.set_drive_inputs(1.0, 0.0, 1.0 / 60.0, false)
		coupe._physics_process(1.0 / 60.0)
	if coupe.current_speed <= 0.0:
		await _fail("STAGE 4 FAIL: coupe current_speed not positive under throttle")
		return

	# Brake to stop
	for _i in range(60):
		coupe.set_drive_inputs(-1.0, 0.0, 1.0 / 60.0, false)
		coupe._physics_process(1.0 / 60.0)
	if coupe.current_speed > 0.0:
		await _fail("STAGE 4 FAIL: coupe failed to brake to zero")
		return

	# Reverse
	coupe._gear_settle_timer = 0.0
	for _i in range(30):
		coupe.set_drive_inputs(-1.0, 0.0, 1.0 / 60.0, false)
		coupe._physics_process(1.0 / 60.0)
	if coupe.current_speed >= 0.0:
		await _fail("STAGE 4 FAIL: coupe failed to enter reverse gear")
		return

	# Handbrake screech signal test
	var screech_received: Array = [false]
	var screech_cb = func(_pos: Vector3): screech_received[0] = true
	coupe.brake_screech_triggered.connect(screech_cb)
	coupe.current_speed = 10.0
	coupe.set_drive_inputs(0.0, 0.0, 1.0 / 60.0, true)
	if not screech_received[0]:
		await _fail("STAGE 4 FAIL: brake_screech_triggered signal not emitted on handbrake at 10 m/s")
		return
	coupe.brake_screech_triggered.disconnect(screech_cb)
	print("  [STAGE 4 PASS] Driving physics, reverse gear, and handbrake screech verified.")

	# Stage 5: Dismount Rejection & Resolution
	print("\n--- Stage 5: Dismount Rejection & Resolution ---")
	coupe.current_speed = 6.0
	var rejected_reasons: Array = []
	var rej_cb = func(reason, _spd, _lim): rejected_reasons.append(reason)
	coupe.dismount_rejected.connect(rej_cb)
	var dismount_ok: bool = coupe.request_dismount()
	if dismount_ok or rejected_reasons.is_empty() or rejected_reasons[0] != MuscleCoupe.DismountRejectReason.TOO_FAST:
		await _fail("STAGE 5 FAIL: high-speed dismount must be rejected with TOO_FAST")
		return
	coupe.dismount_rejected.disconnect(rej_cb)

	# Stop and dismount cleanly
	coupe.current_speed = 0.0
	dismount_ok = coupe.request_dismount()
	if not dismount_ok:
		await _fail("STAGE 5 FAIL: request_dismount failed when stopped")
		return

	# Wait for 0.25s dismount blend timer
	await create_timer(0.25).timeout
	await process_frame

	if coupe.current_state != MuscleCoupe.VehicleState.PARKED:
		await _fail("STAGE 5 FAIL: coupe state not PARKED after dismount")
		return
	if coupe.occupant != null:
		await _fail("STAGE 5 FAIL: coupe occupant not cleared after dismount")
		return
	if player.is_mounted:
		await _fail("STAGE 5 FAIL: player is_mounted still true after dismount")
		return
	if player.is_input_locked:
		await _fail("STAGE 5 FAIL: player input locked after dismount")
		return
	if _scene.get("active_vehicle") != null:
		await _fail("STAGE 5 FAIL: controller active_vehicle not cleared after dismount")
		return
	print("  [STAGE 5 PASS] Dismount rejection and clean dismount verified.")

	# Stage 6: Reset Slice Restoration
	print("\n--- Stage 6: Reset Slice Restoration ---")
	_scene.reset_slice()
	await process_frame
	await process_frame

	if coupe.current_state != MuscleCoupe.VehicleState.PARKED:
		await _fail("STAGE 6 FAIL: coupe not PARKED after reset_slice")
		return
	if coupe.occupant != null:
		await _fail("STAGE 6 FAIL: coupe occupant not null after reset_slice")
		return
	if not coupe.global_position.is_equal_approx(Vector3(-3.5, 0.05, 3.0)):
		await _fail("STAGE 6 FAIL: coupe position not reset to Vector3(-3.5, 0.05, 3.0), got %s" % coupe.global_position)
		return
	if not coupe.mount_interactable.is_powered:
		await _fail("STAGE 6 FAIL: coupe mount_interactable not powered after reset")
		return
	print("  [STAGE 6 PASS] Reset slice clean restoration verified.")

	# Stage 7: Security Checkpoint Ram Breach
	print("\n--- Stage 7: Security Checkpoint Ram Breach with Muscle Coupe ---")
	player.global_position = coupe.global_position + Vector3(0.5, 0.0, 0.5)
	coupe.mount_interactable.update_player_distance(player.global_position)
	coupe.request_mount(player)
	await create_timer(0.25).timeout
	await process_frame

	var checkpoint_event = _scene.get_node_or_null("SecurityCheckpointWorldEvent")
	if not checkpoint_event:
		await _fail("STAGE 7 FAIL: SecurityCheckpointWorldEvent missing")
		return

	# Drive near checkpoint
	coupe.global_position = Vector3(-4.5, 0.05, -40.0)
	await process_frame

	# Simulate high-speed ram impact (12 m/s head on)
	coupe.collision_contact.emit(0.95, 12.0, Vector3(-4.5, 0.5, -42.0))
	await process_frame

	if checkpoint_event.current_state != 3: # State.BREACHED
		await _fail("STAGE 7 FAIL: Checkpoint not BREACHED (expected 3, got %d)" % checkpoint_event.current_state)
		return
	print("  [STAGE 7 PASS] Security checkpoint ram breach with Muscle Coupe verified.")

	_scene.reset_slice()
	await process_frame

	print("\n=========================================================================")
	print("[MUSCLE_COUPE_INTEGRATION_TEST] 100% CONTRACT PASS")
	print("=========================================================================\n")
	await _finish(0)
