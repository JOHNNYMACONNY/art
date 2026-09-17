extends SceneTree

# Dedicated Integration Test: Destructible Traffic Barrier Shortcut Breach System
# Verifies:
# 1. PropTrafficBarrier invariants, BarrierState enum, methods, signals, groups
# 2. Foot melee strike tampering (elastic recoil, zero breach, collision intact)
# 3. Low-speed vehicle nudge (< 5.0 m/s: solid collision block, zero breach)
# 4. High-speed vehicle ram (>= 5.0 m/s: launched mesh, debris scatter, collision disabled, disturbance alert)
# 5. Dual-barrier shortcut corridor breach (clearing both barriers at z = -28.0)
# 6. Clean deterministic restoration via reset_slice()

const PropTrafficBarrierScript = preload("res://scripts/props/prop_traffic_barrier.gd")

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
	push_error("[BARRIER_TEST] " + message)
	await _finish(1)

func _run() -> void:
	print("\n=========================================================================")
	print("[TRAFFIC_BARRIER_INTEGRATION_TEST] Starting Verification...")
	print("=========================================================================\n")

	var scene_res := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if not scene_res:
		await _fail("Failed to load scrap_test_block.tscn")
		return

	_scene = scene_res.instantiate()
	root.add_child(_scene)
	await process_frame
	await process_frame

	var player = _scene.get("player")
	var coupe = _scene.get("muscle_coupe")
	var barriers = _scene.get("traffic_barriers")

	if not player:
		await _fail("Player node missing in scrap_test_block")
		return
	if not coupe:
		await _fail("MuscleCoupe node missing in scrap_test_block")
		return
	if barriers == null or barriers.is_empty():
		await _fail("traffic_barriers list missing or empty in scrap_test_block")
		return

	var barrier: PropTrafficBarrier = barriers[0] as PropTrafficBarrier
	if not barrier:
		await _fail("First traffic barrier is not of type PropTrafficBarrier")
		return

	# Stage 1: Contract, State Machine & Invariants
	print("--- Stage 1: Traffic Barrier Contract, State Machine & Invariants ---")
	if not ("INTACT" in PropTrafficBarrierScript.BarrierState) or not ("BREACHED" in PropTrafficBarrierScript.BarrierState):
		await _fail("STAGE 1 FAIL: PropTrafficBarrierScript.BarrierState missing required enum values")
		return

	for method_name in ["take_hit", "apply_vehicle_ram", "reset_barrier"]:
		if not barrier.has_method(method_name):
			await _fail("STAGE 1 FAIL: barrier missing method " + method_name)
			return

	for signal_name in ["barrier_hit", "barrier_breached", "barrier_reset"]:
		if not barrier.has_signal(signal_name):
			await _fail("STAGE 1 FAIL: barrier missing signal " + signal_name)
			return

	for group_name in ["damageable", "strike_target", "traffic_barriers"]:
		if not barrier.is_in_group(group_name):
			await _fail("STAGE 1 FAIL: barrier missing group " + group_name)
			return

	if barrier.current_state != PropTrafficBarrierScript.BarrierState.INTACT:
		await _fail("STAGE 1 FAIL: barrier initial state is not INTACT")
		return

	if barrier.is_breached:
		await _fail("STAGE 1 FAIL: barrier initial is_breached is true")
		return

	var col_shape: CollisionShape3D = barrier.find_child("CollisionShape3D", true, false)
	if not col_shape or col_shape.disabled:
		await _fail("STAGE 1 FAIL: barrier CollisionShape3D missing or initially disabled")
		return

	print("  [STAGE 1 PASS] Traffic barrier contract, state machine, and invariants verified.")

	# Stage 2: Foot Melee Strike Tampering
	print("--- Stage 2: Foot Melee Strike Tampering ---")
	var hit_signal_fired: Array = [false]
	var on_hit = func(_pos, _dir): hit_signal_fired[0] = true
	barrier.barrier_hit.connect(on_hit)

	barrier.take_hit(1, barrier.global_position, Vector3.FORWARD)
	await process_frame

	if not hit_signal_fired[0]:
		await _fail("STAGE 2 FAIL: barrier_hit signal was not emitted on take_hit")
		return

	if barrier.is_breached or barrier.current_state != PropTrafficBarrierScript.BarrierState.INTACT:
		await _fail("STAGE 2 FAIL: foot strike breached the barrier (must be zero breach)")
		return

	if col_shape.disabled:
		await _fail("STAGE 2 FAIL: foot strike disabled collision shape")
		return

	barrier.barrier_hit.disconnect(on_hit)
	print("  [STAGE 2 PASS] Melee strike recoil and zero breach verified.")

	# Stage 3: Low-Speed Vehicle Nudge (< 5.0 m/s)
	print("--- Stage 3: Low-Speed Vehicle Nudge (< 5.0 m/s) ---")
	var low_nudge_result: bool = barrier.apply_vehicle_ram(3.5, Vector3.FORWARD, coupe)
	await process_frame

	if low_nudge_result:
		await _fail("STAGE 3 FAIL: apply_vehicle_ram succeeded at 3.5 m/s (expected failure < 5.0 m/s)")
		return

	if barrier.is_breached or barrier.current_state != PropTrafficBarrierScript.BarrierState.INTACT:
		await _fail("STAGE 3 FAIL: low speed nudge breached the barrier")
		return

	if col_shape.disabled:
		await _fail("STAGE 3 FAIL: low speed nudge disabled collision shape")
		return

	print("  [STAGE 3 PASS] Low-speed vehicle deflection and solid block verified.")

	# Stage 4: High-Speed Vehicle Ram Breach (>= 5.0 m/s)
	print("--- Stage 4: High-Speed Vehicle Ram Breach (>= 5.0 m/s) ---")
	var breach_signal_fired: Array = [false]
	var breach_speed_received: Array = [0.0]
	var on_breach = func(speed, _dir):
		breach_signal_fired[0] = true
		breach_speed_received[0] = speed
	barrier.barrier_breached.connect(on_breach)

	var high_ram_result: bool = barrier.apply_vehicle_ram(7.5, Vector3.FORWARD, coupe)
	await process_frame
	await process_frame

	if not high_ram_result:
		await _fail("STAGE 4 FAIL: apply_vehicle_ram returned false at 7.5 m/s")
		return

	if not breach_signal_fired[0] or absf(breach_speed_received[0] - 7.5) > 0.01:
		await _fail("STAGE 4 FAIL: barrier_breached signal not fired with correct speed")
		return

	if not barrier.is_breached or barrier.current_state != PropTrafficBarrierScript.BarrierState.BREACHED:
		await _fail("STAGE 4 FAIL: barrier state not transitioned to BREACHED")
		return

	if not col_shape.disabled:
		await _fail("STAGE 4 FAIL: barrier collision shape was not disabled on breach")
		return

	if barrier.debris_instances.is_empty():
		await _fail("STAGE 4 FAIL: barrier failed to scatter debris on breach")
		return

	# Subsequent ram should return false once already breached
	var repeat_ram: bool = barrier.apply_vehicle_ram(8.0, Vector3.FORWARD, coupe)
	if repeat_ram:
		await _fail("STAGE 4 FAIL: repeat ram returned true on already-breached barrier")
		return

	barrier.barrier_breached.disconnect(on_breach)
	print("  [STAGE 4 PASS] High-speed vehicle ram breach, launch, debris, and collision disable verified.")

	# Stage 5: Alleyway Dual-Barrier Clearance
	print("--- Stage 5: Alleyway Dual-Barrier Clearance ---")
	if barriers.size() < 2:
		await _fail("STAGE 5 FAIL: Expected at least 2 traffic barriers blocking shortcut at z = -28.0")
		return

	var barrier2: PropTrafficBarrier = barriers[1] as PropTrafficBarrier
	var ram2_result: bool = barrier2.apply_vehicle_ram(6.5, Vector3.FORWARD, coupe)
	await process_frame

	if not ram2_result or not barrier2.is_breached:
		await _fail("STAGE 5 FAIL: second barrier failed to breach at speed")
		return

	var col2: CollisionShape3D = barrier2.find_child("CollisionShape3D", true, false)
	if not col2 or not col2.disabled:
		await _fail("STAGE 5 FAIL: second barrier collision shape not disabled")
		return

	print("  [STAGE 5 PASS] Dual-barrier shortcut corridor clearance verified.")

	# Stage 6: Deterministic Slice Reset
	print("--- Stage 6: Deterministic Slice Reset ---")
	_scene.call("reset_slice")
	await process_frame
	await process_frame

	for i in range(barriers.size()):
		var b: PropTrafficBarrier = barriers[i]
		if b.is_breached:
			await _fail("STAGE 6 FAIL: barrier %d is still breached after reset_slice" % i)
			return
		if b.current_state != PropTrafficBarrierScript.BarrierState.INTACT:
			await _fail("STAGE 6 FAIL: barrier %d state is not INTACT after reset_slice" % i)
			return
		var b_col: CollisionShape3D = b.find_child("CollisionShape3D", true, false)
		if not b_col or b_col.disabled:
			await _fail("STAGE 6 FAIL: barrier %d collision shape is disabled after reset_slice" % i)
			return
		if not b.debris_instances.is_empty():
			await _fail("STAGE 6 FAIL: barrier %d still has debris instances after reset_slice" % i)
			return

	print("  [STAGE 6 PASS] Full slice reset restores all traffic barriers cleanly.")

	print("\n=========================================================================")
	print("[TRAFFIC_BARRIER_INTEGRATION_TEST] 100% CONTRACT PASS")
	print("=========================================================================\n")
	await _finish(0)
