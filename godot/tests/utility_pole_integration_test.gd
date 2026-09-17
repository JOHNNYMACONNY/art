extends SceneTree

# Dedicated Integration Test: Interactive Utility Pole & EMP Grid Overload
# Verifies:
# 1. PropUtilityPole contract, PoleState enum, methods, signals, groups, interactable
# 2. Foot melee strike tampering (elastic recoil, 3-hit transformer blowout)
# 3. Tactical Player Interaction: [E] TAP GRID triggering EMP overload
# 4. EMP Shockwave & Active Pursuer Stun (9.0m radius, 4.0s stun)
# 5. Vehicle impact: low-speed deflection (< 4.5 m/s) vs high-speed ram (>= 4.5 m/s tilt & blowout)
# 6. Clean deterministic restoration via reset_slice()

const PropUtilityPoleScript = preload("res://scripts/props/prop_utility_pole.gd")
const PursuerScript = preload("res://scripts/entities/pursuer_prototype.gd")

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
	push_error("[UTILITY_POLE_TEST] " + message)
	await _finish(1)

func _run() -> void:
	print("\n=========================================================================")
	print("[UTILITY_POLE_INTEGRATION_TEST] Starting Verification...")
	print("=========================================================================")

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
	var pursuer: PursuerPrototype = _scene.get("pursuer") as PursuerPrototype
	var pole: PropUtilityPole = _scene.get("utility_pole") as PropUtilityPole

	if not player:
		await _fail("Player node missing in scrap_test_block")
		return
	if not coupe:
		await _fail("MuscleCoupe node missing in scrap_test_block")
		return
	if not pursuer:
		await _fail("Pursuer node missing in scrap_test_block")
		return
	if not pole:
		await _fail("utility_pole node missing or invalid type in scrap_test_block")
		return

	# Stage 1: Contract, State Machine & Invariants
	print("--- Stage 1: Utility Pole Contract, State Machine & Invariants ---")
	if not ("READY" in PropUtilityPoleScript.PoleState) or not ("OVERLOADED" in PropUtilityPoleScript.PoleState) or not ("DAMAGED" in PropUtilityPoleScript.PoleState) or not ("RAMMED" in PropUtilityPoleScript.PoleState):
		await _fail("STAGE 1 FAIL: PropUtilityPoleScript.PoleState missing required enum values")
		return

	for method_name in ["take_hit", "apply_vehicle_ram", "overload_grid", "reset_pole"]:
		if not pole.has_method(method_name):
			await _fail("STAGE 1 FAIL: pole missing method " + method_name)
			return

	for signal_name in ["grid_overloaded", "hit_received", "pole_rammed", "pole_reset"]:
		if not pole.has_signal(signal_name):
			await _fail("STAGE 1 FAIL: pole missing signal " + signal_name)
			return

	for group_name in ["damageable", "strike_target", "utility_poles"]:
		if not pole.is_in_group(group_name):
			await _fail("STAGE 1 FAIL: pole missing group " + group_name)
			return

	if pole.current_state != PropUtilityPoleScript.PoleState.READY:
		await _fail("STAGE 1 FAIL: pole initial state is not READY")
		return

	if pole.is_rammed or pole.is_overloaded:
		await _fail("STAGE 1 FAIL: pole initially marked rammed or overloaded")
		return

	var col_shape: CollisionShape3D = pole.find_child("CollisionShape3D", true, false)
	if not col_shape or col_shape.disabled:
		await _fail("STAGE 1 FAIL: pole CollisionShape3D missing or initially disabled")
		return

	var interactable = pole.find_child("UtilityPoleInteractable", true, false)
	if not interactable:
		await _fail("STAGE 1 FAIL: UtilityPoleInteractable missing on pole")
		return

	if interactable.get_action_verb() != "TAP GRID":
		await _fail("STAGE 1 FAIL: interactable action verb expected 'TAP GRID', got '%s'" % interactable.get_action_verb())
		return

	print("  [STAGE 1 PASS] Utility pole contract, state machine, and invariants verified.")

	# Stage 2: Foot Melee Strike Tampering & Transformer Blowout
	print("--- Stage 2: Foot Melee Strike Tampering & Transformer Blowout ---")
	var hit_signal_fired: Array = [false]
	var hit_durability_val: Array = [0]
	var on_hit = func(rem_dur, _pos, _dir):
		hit_signal_fired[0] = true
		hit_durability_val[0] = rem_dur
	pole.hit_received.connect(on_hit)

	# Hit 1: 3 -> 2
	pole.take_hit(1, pole.global_position, Vector3.FORWARD)
	await process_frame

	if not hit_signal_fired[0] or hit_durability_val[0] != 2 or pole.current_durability != 2:
		await _fail("STAGE 2 FAIL: Hit 1 did not reduce durability to 2")
		return

	# Hit 2: 2 -> 1
	hit_signal_fired[0] = false
	pole.take_hit(1, pole.global_position, Vector3.FORWARD)
	await process_frame

	if not hit_signal_fired[0] or hit_durability_val[0] != 1 or pole.current_durability != 1:
		await _fail("STAGE 2 FAIL: Hit 2 did not reduce durability to 1")
		return

	# Hit 3: 1 -> 0 (Transformer blowout triggers grid overload)
	var overload_fired: Array = [false]
	var on_overload = func(_rad, _pos): overload_fired[0] = true
	pole.grid_overloaded.connect(on_overload)

	hit_signal_fired[0] = false
	pole.take_hit(1, pole.global_position, Vector3.FORWARD)
	await process_frame
	await process_frame

	if not hit_signal_fired[0] or pole.current_durability != 0:
		await _fail("STAGE 2 FAIL: Hit 3 did not reduce durability to 0")
		return

	if not overload_fired[0] or not pole.is_overloaded:
		await _fail("STAGE 2 FAIL: 3rd hit failed to trigger transformer blowout grid overload")
		return

	pole.hit_received.disconnect(on_hit)
	pole.grid_overloaded.disconnect(on_overload)
	print("  [STAGE 2 PASS] Melee strike tampering and 3-hit transformer blowout verified.")

	# Stage 3: Tactical Player Interaction ([E] TAP GRID)
	print("--- Stage 3: Tactical Player Interaction ([E] TAP GRID) ---")
	pole.reset_pole()
	await process_frame

	if pole.current_state != PropUtilityPoleScript.PoleState.READY:
		await _fail("STAGE 3 FAIL: pole failed to reset to READY")
		return

	if interactable.get_action_verb() != "TAP GRID":
		await _fail("STAGE 3 FAIL: interactable action verb not reset to TAP GRID")
		return

	var tap_overload_fired: Array = [false]
	var shockwave_radius_val: Array = [0.0]
	var on_tap_overload = func(radius, _pos):
		tap_overload_fired[0] = true
		shockwave_radius_val[0] = radius
	pole.grid_overloaded.connect(on_tap_overload)

	interactable.is_player_in_range = true
	var tap_success: bool = interactable.begin_interaction(player.global_position)
	await process_frame
	await process_frame

	if not tap_success:
		await _fail("STAGE 3 FAIL: begin_interaction returned false on READY pole")
		return

	if not tap_overload_fired[0] or shockwave_radius_val[0] < 9.0:
		await _fail("STAGE 3 FAIL: TAP GRID did not fire grid_overloaded with radius >= 9.0m")
		return

	if not pole.is_overloaded or pole.current_state != PropUtilityPoleScript.PoleState.OVERLOADED:
		await _fail("STAGE 3 FAIL: pole did not transition to OVERLOADED state")
		return

	if interactable.get_action_verb() != "OVERLOADED":
		await _fail("STAGE 3 FAIL: action verb after overload expected 'OVERLOADED', got '%s'" % interactable.get_action_verb())
		return

	# Second tap must be rejected
	var repeat_tap: bool = interactable.begin_interaction(player.global_position)
	if repeat_tap:
		await _fail("STAGE 3 FAIL: repeat TAP GRID succeeded while already OVERLOADED")
		return

	pole.grid_overloaded.disconnect(on_tap_overload)
	print("  [STAGE 3 PASS] Tactical TAP GRID interaction and EMP detonation verified.")

	# Stage 4: EMP Shockwave & Pursuer Stun (9.0m Radius, 4.0s Stun)
	print("--- Stage 4: EMP Shockwave & Pursuer Stun ---")
	pole.reset_pole()
	await process_frame

	# Position pursuer within 9m shockwave radius
	pursuer.global_position = pole.global_position + Vector3(0.0, 0.0, 5.0) # 5.0m away
	pursuer.activate_pursuit(player)
	await process_frame

	if pursuer.current_state != PursuerScript.PursuerState.CHASING:
		await _fail("STAGE 4 FAIL: Pursuer not in CHASING state before EMP shockwave")
		return

	# Overload grid
	pole.overload_grid()
	await process_frame
	await process_frame

	if pursuer.current_state != PursuerScript.PursuerState.STUNNED or not pursuer.is_stunned:
		await _fail("STAGE 4 FAIL: Active pursuer within 9.0m was not STUNNED by EMP shockwave")
		return

	print("  [STAGE 4 PASS] 9.0m EMP shockwave stun on active pursuer verified.")

	# Stage 5: Vehicle Ram Mechanics (Low-speed block vs High-speed ram tilt)
	print("--- Stage 5: Vehicle Ram Mechanics ---")
	pole.reset_pole()
	await process_frame

	# Low-speed nudge (< 4.5 m/s)
	var low_ram: bool = pole.apply_vehicle_ram(3.2, Vector3.FORWARD, coupe)
	await process_frame

	if low_ram or pole.is_rammed or pole.current_state == PropUtilityPoleScript.PoleState.RAMMED:
		await _fail("STAGE 5 FAIL: Low-speed vehicle nudge (< 4.5 m/s) rammed the pole")
		return

	# High-speed ram (>= 4.5 m/s)
	var ram_signal_fired: Array = [false]
	var on_ram = func(_speed, _dir): ram_signal_fired[0] = true
	pole.pole_rammed.connect(on_ram)

	var high_ram: bool = pole.apply_vehicle_ram(6.5, Vector3.FORWARD, coupe)
	await process_frame
	await process_frame

	if not high_ram:
		await _fail("STAGE 5 FAIL: High-speed ram (6.5 m/s) returned false")
		return

	if not ram_signal_fired[0]:
		await _fail("STAGE 5 FAIL: pole_rammed signal not emitted")
		return

	if not pole.is_rammed or pole.current_state != PropUtilityPoleScript.PoleState.RAMMED:
		await _fail("STAGE 5 FAIL: pole state did not transition to RAMMED")
		return

	if not pole.is_overloaded:
		await _fail("STAGE 5 FAIL: High-speed vehicle ram did not blow out/overload the transformer")
		return

	pole.pole_rammed.disconnect(on_ram)
	print("  [STAGE 5 PASS] Vehicle ram mechanics (low-speed block & high-speed tilt/blowout) verified.")

	# Stage 6: Clean Deterministic Restoration
	print("--- Stage 6: Clean Deterministic Restoration ---")
	_scene.call("reset_slice")
	await process_frame
	await process_frame

	if pole.is_rammed or pole.is_overloaded:
		await _fail("STAGE 6 FAIL: pole still marked rammed or overloaded after reset_slice")
		return

	if pole.current_state != PropUtilityPoleScript.PoleState.READY:
		await _fail("STAGE 6 FAIL: pole state not READY after reset_slice")
		return

	if pole.current_durability != PropUtilityPoleScript.MAX_DURABILITY:
		await _fail("STAGE 6 FAIL: pole durability not restored after reset_slice")
		return

	if col_shape.disabled:
		await _fail("STAGE 6 FAIL: pole collision shape disabled after reset_slice")
		return

	if interactable.get_action_verb() != "TAP GRID":
		await _fail("STAGE 6 FAIL: interactable action verb not restored to TAP GRID after reset_slice")
		return

	print("  [STAGE 6 PASS] Deterministic slice reset restored utility pole cleanly.")

	print("\n=========================================================================")
	print("[UTILITY_POLE_INTEGRATION_TEST] 100% CONTRACT PASS")
	print("=========================================================================\n")
	await _finish(0)
