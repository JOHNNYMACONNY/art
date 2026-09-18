extends SceneTree

# Dedicated Integration Test: Street Combat & Physical Tool Improvisation
# Verifies:
# 1. Player melee strike verb on foot (impulse, arm swing, cooldown, rejection while mounted/locked)
# 2. StreetCombatContract interface & node invariants
# 3. Hit registration, physical contact, and damage application on SalvageLockbox
# 4. Municipal security alarm triggering city disturbance alert & pursuer tracking
# 5. Lockbox breach, scrap payoff (+150 credits), and completion state
# 6. Clean restoration via reset_slice()

const StreetCombatContractScript = preload("res://tests/street_combat_contract.gd")
const SalvageLockboxScript = preload("res://scripts/props/salvage_lockbox.gd")

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
	push_error("[STREET_COMBAT_TEST] " + message)
	await _finish(1)

func _run() -> void:
	print("\n=========================================================================")
	print("[STREET_COMBAT_INTEGRATION_TEST] Starting Verification...")
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
	if not player:
		await _fail("Player node missing in scrap_test_block")
		return

	# Stage 1: Player Strike Verb on Foot
	print("--- Stage 1: Player Melee Strike Verb ---")
	if not player.has_method("strike"):
		await _fail("STAGE 1 FAIL: player missing strike() method")
		return

	var strike_performed_emitted: Array = [false]
	var strike_triggered_emitted: Array = [false]
	var last_hit_target: Array = [null]

	player.strike_performed.connect(func(): strike_performed_emitted[0] = true)
	player.strike_triggered.connect(func(t, pos):
		strike_triggered_emitted[0] = true
		last_hit_target[0] = t
	)

	# Initial strike test
	var initial_pos: Vector3 = player.global_position
	var struck: bool = player.strike()
	if not struck:
		await _fail("STAGE 1 FAIL: initial player.strike() returned false")
		return
	if not player.is_striking:
		await _fail("STAGE 1 FAIL: player.is_striking is false immediately after strike")
		return
	if not strike_performed_emitted[0]:
		await _fail("STAGE 1 FAIL: strike_performed signal was not emitted")
		return

	# Rapid successive strike must be rejected due to cooldown
	var rapid_struck: bool = player.strike()
	if rapid_struck:
		await _fail("STAGE 1 FAIL: rapid strike was not rejected by cooldown")
		return

	# Wait for strike animation and cooldown to complete
	while player._strike_cooldown > 0.0 or player.is_striking:
		await process_frame
	if player.is_striking:
		await _fail("STAGE 1 FAIL: player.is_striking did not reset after duration")
		return

	# Strike rejection while mounted
	player.is_mounted = true
	var mounted_strike: bool = player.strike()
	player.is_mounted = false
	if mounted_strike:
		await _fail("STAGE 1 FAIL: player was able to strike while mounted")
		return

	# Strike rejection while input locked
	player.is_input_locked = true
	var locked_strike: bool = player.strike()
	player.is_input_locked = false
	if locked_strike:
		await _fail("STAGE 1 FAIL: player was able to strike while input locked")
		return

	print("  [STAGE 1 PASS] Player melee strike verb and constraints verified.")

	# Stage 2: Contract Verification
	print("\n--- Stage 2: Street Combat Contract Verification ---")
	var contract_res := StreetCombatContractScript.verify(_scene)
	if not contract_res["ok"]:
		await _fail("STAGE 2 FAIL: Contract verification errors: %s" % str(contract_res["errors"]))
		return
	print("  [STAGE 2 PASS] Street combat contract passed.")

	# Stage 3: Direct Strike Hit Registration on Lockbox
	print("\n--- Stage 3: Strike Hit Registration on Salvage Lockbox ---")
	var lockbox: Node = _scene.get("salvage_lockbox")
	if not lockbox:
		lockbox = _scene.find_child("PropSalvageLockbox", true, false)
	if not lockbox:
		await _fail("STAGE 3 FAIL: SalvageLockbox not found")
		return

	# Position player facing the lockbox within strike reach
	player.global_position = lockbox.global_position + Vector3(0, 0, 1.2)
	player.mesh_pivot.rotation.y = 0.0 # Facing -Z toward lockbox
	await process_frame

	var hit_signal_received: Array = [false]
	var hit_durability_val: Array = [-1]
	lockbox.hit_received.connect(func(rem_dur, pos, dir):
		hit_signal_received[0] = true
		hit_durability_val[0] = rem_dur
	)

	strike_triggered_emitted[0] = false
	last_hit_target[0] = null

	# Post-147 regression: an off-axis target inside the strike arc must still
	# respect its own line of sight. The narrow blocker sits on the candidate ray
	# but deliberately misses the straight-ahead center ray.
	player.global_position = lockbox.global_position + Vector3(-0.65, 0, 1.2)
	player.mesh_pivot.rotation.y = 0.0
	var blocker := StaticBody3D.new()
	blocker.name = "StrikeLineOfSightBlocker"
	var blocker_shape := CollisionShape3D.new()
	var blocker_box := BoxShape3D.new()
	blocker_box.size = Vector3(0.24, 1.8, 0.22)
	blocker_shape.shape = blocker_box
	blocker.add_child(blocker_shape)
	_scene.add_child(blocker)
	blocker.global_position = Vector3(
		(player.global_position.x + lockbox.global_position.x) * 0.5,
		player.global_position.y + 0.9,
		(player.global_position.z + lockbox.global_position.z) * 0.5
	)
	await physics_frame
	var durability_before_blocked_strike: int = lockbox.current_durability
	var blocked_strike_ok: bool = player.strike()
	if not blocked_strike_ok:
		await _fail("STAGE 3 FAIL: blocked strike could not execute")
		return
	await physics_frame
	if lockbox.current_durability != durability_before_blocked_strike:
		await _fail("STAGE 3 FAIL: melee damaged off-axis lockbox through a blocking collider")
		return
	while player._strike_cooldown > 0.0 or player.is_striking:
		await process_frame
	blocker.queue_free()
	await physics_frame
	# Keep the target off-axis after removing the blocker. The center ray should
	# miss, so this proves the proximity fallback can hit a visible candidate
	# through its own LOS query.
	player.global_position = lockbox.global_position + Vector3(-0.65, 0, 1.2)
	player.mesh_pivot.rotation.y = 0.0
	await physics_frame

	var hit_strike_ok: bool = player.strike()
	if not hit_strike_ok:
		await _fail("STAGE 3 FAIL: player.strike() facing lockbox returned false (cooldown=%.3f, is_striking=%s)" % [player._strike_cooldown, player.is_striking])
		return

	await process_frame
	if not hit_signal_received[0]:
		await _fail("STAGE 3 FAIL: lockbox hit_received signal was not emitted")
		return
	if hit_durability_val[0] != 2:
		await _fail("STAGE 3 FAIL: expected remaining durability 2 after first hit, got %d" % hit_durability_val[0])
		return
	if lockbox.current_durability != 2:
		await _fail("STAGE 3 FAIL: lockbox.current_durability expected 2, got %d" % lockbox.current_durability)
		return
	print("  [STAGE 3 PASS] Hit registration and durability decrement verified.")

	# Stage 4: Municipal Security Alarm & City Pursuit Trigger
	print("\n--- Stage 4: Security Alarm & Disturbance Pursuit ---")
	# Striking restricted municipal lockbox triggers city disturbance alert
	if _scene.current_pursuit_state != _scene.PursuitState.DISTURBANCE_ALERT and _scene.current_pursuit_state != _scene.PursuitState.PURSUIT_ACTIVE:
		await _fail("STAGE 4 FAIL: striking lockbox did not trigger city DISTURBANCE_ALERT (state is %s)" % _scene.PursuitState.keys()[_scene.current_pursuit_state])
		return

	# Wait for pursuer activation
	await create_timer(0.85).timeout
	if _scene.current_pursuit_state != _scene.PursuitState.PURSUIT_ACTIVE:
		await _fail("STAGE 4 FAIL: pursuit did not transition to PURSUIT_ACTIVE (state is %s)" % _scene.PursuitState.keys()[_scene.current_pursuit_state])
		return
	var pursuer = _scene.get("pursuer")
	if not pursuer or not pursuer.is_active:
		await _fail("STAGE 4 FAIL: pursuer not active following disturbance")
		return
	print("  [STAGE 4 PASS] Municipal alarm disturbance sequence and pursuer tracking verified.")

	# Stage 5: Lockbox Breach & Scrap Payoff
	print("\n--- Stage 5: Lockbox Breach & Scrap Payoff ---")
	var breach_emitted: Array = [false]
	var breach_reward: Array = [0]
	lockbox.lockbox_breached.connect(func(rew, pos):
		breach_emitted[0] = true
		breach_reward[0] = rew
	)

	# Second hit
	while player._strike_cooldown > 0.0 or player.is_striking:
		await process_frame
	player.strike()
	await process_frame
	if lockbox.current_durability != 1:
		await _fail("STAGE 5 FAIL: expected durability 1 after second hit, got %d" % lockbox.current_durability)
		return

	# Third hit (Breach)
	while player._strike_cooldown > 0.0 or player.is_striking:
		await process_frame
	player.strike()
	await process_frame
	if not breach_emitted[0]:
		await _fail("STAGE 5 FAIL: lockbox_breached signal not emitted on lethal strike")
		return
	if breach_reward[0] != 150:
		await _fail("STAGE 5 FAIL: expected breach reward 150, got %d" % breach_reward[0])
		return
	if lockbox.current_state != SalvageLockboxScript.State.BREACHED:
		await _fail("STAGE 5 FAIL: expected lockbox state BREACHED, got %d" % lockbox.current_state)
		return
	print("  [STAGE 5 PASS] Lockbox breach, scrap reward, and state transition verified.")

	# Stage 6: Reset Slice Clean Restoration
	print("\n--- Stage 6: Reset Slice Clean Restoration ---")
	_scene.reset_slice()
	await process_frame
	await process_frame

	if lockbox.current_durability != 3:
		await _fail("STAGE 6 FAIL: lockbox durability not restored to 3 after reset, got %d" % lockbox.current_durability)
		return
	if lockbox.current_state != SalvageLockboxScript.State.SECURED:
		await _fail("STAGE 6 FAIL: lockbox state not restored to SECURED after reset, got %d" % lockbox.current_state)
		return
	if _scene.current_pursuit_state != _scene.PursuitState.CALM:
		await _fail("STAGE 6 FAIL: pursuit state not restored to CALM after reset, got %s" % _scene.PursuitState.keys()[_scene.current_pursuit_state])
		return
	print("  [STAGE 6 PASS] Full slice reset restoration verified.")

	print("\n=========================================================================")
	print("[STREET_COMBAT_INTEGRATION_TEST] 100% CONTRACT PASS")
	print("=========================================================================\n")
	await _finish(0)
