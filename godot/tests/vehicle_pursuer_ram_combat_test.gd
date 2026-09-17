extends SceneTree

# Dedicated Integration Test: Vehicle-on-Vehicle Pursuit Interceptor Ram Combat
# Verifies:
# 1. PursuerPrototype API & state contracts (STUNNED state, apply_vehicle_ram method, signals)
# 2. Low-speed ram rejection (< ram_threshold_speed does not stun pursuer)
# 3. High-speed vehicle ram execution (knocks back pursuer, triggers STUNNED, emits pursuer_rammed)
# 4. Stunned state safety (pursuer cannot intercept target while stunned)
# 5. Stun reboot recovery back to CHASING and stun_recovered signal
# 6. Live world integration via scrap_test_block (vehicle ram contact disables pursuer)
# 7. Clean restoration via reset_slice()

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
	push_error("[PURSUER_RAM_TEST] " + message)
	await _finish(1)

func _run() -> void:
	print("\n=========================================================================")
	print("[VEHICLE_PURSUER_RAM_TEST] Starting Verification...")
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
	var pursuer = _scene.get("pursuer")
	var coupe = _scene.get("muscle_coupe")
	var hauler = _scene.get("scrap_hauler")

	if not pursuer:
		await _fail("Pursuer node missing in scrap_test_block")
		return
	if not coupe or not hauler:
		await _fail("MuscleCoupe or ScrapHauler node missing in scrap_test_block")
		return

	# Stage 1: Pursuer State & API Contract Checks
	print("--- Stage 1: Pursuer Ram & Stun Contract ---")
	if not ("STUNNED" in PursuerScript.PursuerState):
		await _fail("STAGE 1 FAIL: PursuerScript.PursuerState missing 'STUNNED' enum entry")
		return
	if not pursuer.has_method("apply_vehicle_ram"):
		await _fail("STAGE 1 FAIL: pursuer missing apply_vehicle_ram() method")
		return
	if not pursuer.has_signal("pursuer_rammed"):
		await _fail("STAGE 1 FAIL: pursuer missing 'pursuer_rammed' signal")
		return
	if not pursuer.has_signal("stun_recovered"):
		await _fail("STAGE 1 FAIL: pursuer missing 'stun_recovered' signal")
		return
	if not ("stun_recovery_time" in pursuer):
		await _fail("STAGE 1 FAIL: pursuer missing stun_recovery_time property")
		return
	if not ("ram_threshold_speed" in pursuer):
		await _fail("STAGE 1 FAIL: pursuer missing ram_threshold_speed property")
		return
	print("  [STAGE 1 PASS] Pursuer ram contract and stun definitions verified.")

	# Stage 2: Low-Speed Ram Rejection
	print("--- Stage 2: Low-Speed Ram Rejection ---")
	pursuer.reset_pursuer(Vector3(0.0, 0.6, 10.0))
	pursuer.activate_pursuit(player)
	await process_frame

	if pursuer.current_state != PursuerScript.PursuerState.CHASING:
		await _fail("STAGE 2 FAIL: Pursuer should be CHASING after activation")
		return

	var low_speed_result: bool = pursuer.apply_vehicle_ram(2.0, Vector3(0, 0, 1), coupe)
	if low_speed_result:
		await _fail("STAGE 2 FAIL: Low-speed ram (2.0 m/s) should be rejected (< ram_threshold_speed)")
		return
	if pursuer.current_state != PursuerScript.PursuerState.CHASING:
		await _fail("STAGE 2 FAIL: Pursuer state altered by rejected low-speed ram")
		return
	print("  [STAGE 2 PASS] Low-speed vehicle collision rejection verified.")

	# Stage 3: High-Speed Vehicle Ram Execution
	print("--- Stage 3: High-Speed Vehicle Ram Execution ---")
	var rammed_emitted: Array = [false]
	var recorded_speed: Array = [0.0]
	pursuer.pursuer_rammed.connect(func(spd: float, _pos: Vector3):
		rammed_emitted[0] = true
		recorded_speed[0] = spd
	)

	var ram_impulse_speed: float = 8.5
	var ram_dir := Vector3(0.0, 0.0, 1.0)
	var high_speed_result: bool = pursuer.apply_vehicle_ram(ram_impulse_speed, ram_dir, coupe)

	if not high_speed_result:
		await _fail("STAGE 3 FAIL: High-speed ram (8.5 m/s) was rejected")
		return
	if not rammed_emitted[0]:
		await _fail("STAGE 3 FAIL: pursuer_rammed signal was not emitted")
		return
	if abs(recorded_speed[0] - ram_impulse_speed) > 0.01:
		await _fail("STAGE 3 FAIL: recorded ram speed mismatch (expected 8.5, got %.2f)" % recorded_speed[0])
		return
	if pursuer.current_state != PursuerScript.PursuerState.STUNNED:
		await _fail("STAGE 3 FAIL: Pursuer did not enter STUNNED state")
		return
	if not pursuer.is_stunned:
		await _fail("STAGE 3 FAIL: pursuer.is_stunned getter returned false")
		return
	if pursuer.velocity.z <= 0.0:
		await _fail("STAGE 3 FAIL: Pursuer did not receive forward knockback velocity")
		return
	print("  [STAGE 3 PASS] High-speed vehicle ram impact, knockback, and STUNNED state verified.")

	# Stage 4: Stunned Safety (No Target Interception While Stunned)
	print("--- Stage 4: Stunned Safety (Target Interception Inhibited) ---")
	var intercepted_while_stunned: Array = [false]
	pursuer.intercepted_target.connect(func():
		intercepted_while_stunned[0] = true
	)

	# Place target directly inside intercept distance (< 1.5m)
	player.global_position = pursuer.global_position + Vector3(0.0, 0.0, 0.5)
	for f in range(25):
		pursuer._physics_process(0.016)
		await process_frame

	if intercepted_while_stunned[0]:
		await _fail("STAGE 4 FAIL: Pursuer emitted intercepted_target while in STUNNED state")
		return
	print("  [STAGE 4 PASS] Target interception strictly inhibited during stun.")

	# Stage 5: Stun Reboot Recovery
	print("--- Stage 5: Stun Reboot Recovery ---")
	var recovered_emitted: Array = [false]
	pursuer.stun_recovered.connect(func():
		recovered_emitted[0] = true
	)

	# Advance stun timer to trigger reboot
	pursuer._stun_timer = 0.02
	pursuer._physics_process(0.03)
	await process_frame
	await process_frame

	if not recovered_emitted[0]:
		await _fail("STAGE 5 FAIL: stun_recovered signal not emitted upon timer expiry")
		return
	if pursuer.current_state != PursuerScript.PursuerState.CHASING:
		await _fail("STAGE 5 FAIL: Pursuer did not resume CHASING state after stun recovery")
		return
	print("  [STAGE 5 PASS] Stun timer expiration and reboot recovery verified.")

	# Stage 6: World Level Integration (ScrapTestBlock Ram Processing)
	print("--- Stage 6: ScrapTestBlock World Ram Processing ---")
	pursuer.reset_pursuer(Vector3(0.0, 0.6, 5.0))
	pursuer.activate_pursuit(coupe)
	_scene.current_pursuit_state = 2 # PursuitState.PURSUIT_ACTIVE
	await process_frame

	if not _scene.has_method("_check_pursuer_ram"):
		await _fail("STAGE 6 FAIL: scrap_test_block missing _check_pursuer_ram() handler")
		return

	# Trigger vehicle collision ram via scrap_test_block handler
	var world_ram_success: bool = _scene.call("_check_pursuer_ram", 9.0, pursuer.global_position, coupe)
	if not world_ram_success:
		await _fail("STAGE 6 FAIL: _check_pursuer_ram() failed to disable active pursuer")
		return
	if pursuer.current_state != PursuerScript.PursuerState.STUNNED:
		await _fail("STAGE 6 FAIL: pursuer state not STUNNED after world ram execution")
		return
	print("  [STAGE 6 PASS] ScrapTestBlock world ram routing and pursuer disable verified.")

	# Stage 7: Clean Reset Slice Restoration
	print("--- Stage 7: Reset Slice Clean Restoration ---")
	_scene.reset_slice()
	await process_frame
	await process_frame

	if pursuer.is_active or pursuer.current_state != PursuerScript.PursuerState.INACTIVE:
		await _fail("STAGE 7 FAIL: Pursuer not reset to INACTIVE after reset_slice()")
		return
	if pursuer.is_stunned:
		await _fail("STAGE 7 FAIL: Pursuer remained stunned after reset_slice()")
		return
	print("  [STAGE 7 PASS] Full slice reset restores pursuer to cold inactive state.")

	print("\n=========================================================================")
	print("[VEHICLE_PURSUER_RAM_TEST] 100% CONTRACT PASS")
	print("=========================================================================\n")
	await _finish(0)
