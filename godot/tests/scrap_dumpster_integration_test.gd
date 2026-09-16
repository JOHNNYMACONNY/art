extends SceneTree

# Dedicated Integration Test: Municipal Scrap Dumpster System
# Verifies:
# 1. PropScrapDumpster node invariants, DumpsterState enum, methods, signals, interactable proxy
# 2. Proximity detection and dynamic action verb arbitration (SEARCH, HIDE, EXIT)
# 3. Scrap scavenging (+75 scrap reward, state transition, single-claim rule)
# 4. Stealth hiding evasion (player concealing, pursuit heat de-escalation, unhiding)
# 5. Melee prybar strike tampering (durability decrement, hit reaction, player ejection if hiding)
# 6. High-speed vehicle ram impact (threshold gating, knockback slide, player ejection)
# 7. Clean restoration via reset_slice()

const PropScrapDumpsterScript = preload("res://scripts/props/prop_scrap_dumpster.gd")

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
	push_error("[DUMPSTER_TEST] " + message)
	await _finish(1)

func _run() -> void:
	print("\n=========================================================================")
	print("[SCRAP_DUMPSTER_INTEGRATION_TEST] Starting Verification...")
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
	var dumpster = _scene.get("scrap_dumpster")
	var coupe = _scene.get("muscle_coupe")

	if not player:
		await _fail("Player node missing in scrap_test_block")
		return
	if not dumpster:
		await _fail("ScrapDumpster node missing in scrap_test_block")
		return

	# Stage 1: Contract & Invariants
	print("--- Stage 1: Dumpster Contract, State Machine & Invariants ---")
	if not ("READY" in PropScrapDumpsterScript.DumpsterState) or not ("SCAVENGED" in PropScrapDumpsterScript.DumpsterState) or not ("OCCUPIED_HIDING" in PropScrapDumpsterScript.DumpsterState):
		await _fail("STAGE 1 FAIL: PropScrapDumpsterScript.DumpsterState missing required enum values")
		return
	for method_name in ["scavenge_scrap", "enter_hiding", "exit_hiding", "take_hit", "apply_vehicle_ram", "reset_dumpster"]:
		if not dumpster.has_method(method_name):
			await _fail("STAGE 1 FAIL: dumpster missing method " + method_name)
			return
	for signal_name in ["hit_received", "dumpster_scavenged", "player_entered_hiding", "player_exited_hiding", "dumpster_rammed"]:
		if not dumpster.has_signal(signal_name):
			await _fail("STAGE 1 FAIL: dumpster missing signal " + signal_name)
			return
	if not dumpster.interactable:
		await _fail("STAGE 1 FAIL: dumpster missing interactable proxy")
		return
	print("  [STAGE 1 PASS] Dumpster state machine, methods, and signals verified.")

	# Stage 2: Proximity Detection & Dynamic Prompt Arbitration
	print("--- Stage 2: Proximity Detection & Dynamic Action Verbs ---")
	dumpster.interactable.set_player_reference(player)

	# Player far away (> 5m)
	player.global_position = dumpster.global_position + Vector3(8.0, 0.0, 0.0)
	dumpster.interactable.update_player_distance(player.global_position)
	await process_frame
	if dumpster.interactable.is_player_in_range:
		await _fail("STAGE 2 FAIL: Player reported in range while 8m away")
		return

	# Player in range (< 2.4m)
	player.global_position = dumpster.global_position + Vector3(1.2, 0.0, 0.0)
	dumpster.interactable.update_player_distance(player.global_position)
	await process_frame
	if not dumpster.interactable.is_player_in_range:
		await _fail("STAGE 2 FAIL: Player not detected in interaction range (< 2.4m)")
		return

	dumpster.interactable.set_pursuit_active(false)
	if dumpster.interactable.get_action_verb() != "SEARCH":
		await _fail("STAGE 2 FAIL: Expected action verb SEARCH when calm, got " + dumpster.interactable.get_action_verb())
		return

	dumpster.interactable.set_pursuit_active(true)
	if dumpster.interactable.get_action_verb() != "HIDE":
		await _fail("STAGE 2 FAIL: Expected action verb HIDE when pursuit active, got " + dumpster.interactable.get_action_verb())
		return
	print("  [STAGE 2 PASS] Proximity detection and dynamic action verb arbitration verified.")

	# Stage 3: Scrap Scavenging
	print("--- Stage 3: Scrap Scavenging & Single-Claim Rule ---")
	dumpster.reset_dumpster()
	await process_frame

	var scavenged_signal_fired: Array = [false]
	var scavenged_reward: Array = [0]
	dumpster.dumpster_scavenged.connect(func(reward, _pos):
		scavenged_signal_fired[0] = true
		scavenged_reward[0] = reward
	)

	var reward: int = dumpster.scavenge_scrap()
	if reward != 75:
		await _fail("STAGE 3 FAIL: Expected 75 scrap reward, got %d" % reward)
		return
	if not scavenged_signal_fired[0]:
		await _fail("STAGE 3 FAIL: dumpster_scavenged signal not emitted")
		return
	if dumpster.current_state != PropScrapDumpsterScript.DumpsterState.SCAVENGED:
		await _fail("STAGE 3 FAIL: Dumpster state not SCAVENGED after scavenge")
		return

	# Second scavenge attempt must be rejected (single claim)
	var repeat_reward: int = dumpster.scavenge_scrap()
	if repeat_reward != 0:
		await _fail("STAGE 3 FAIL: Repeat scavenge returned non-zero scrap: %d" % repeat_reward)
		return
	print("  [STAGE 3 PASS] Scrap scavenging (+75 scrap) and single-claim rule verified.")

	# Stage 4: Stealth Hiding & Pursuit Evasion
	print("--- Stage 4: Stealth Hiding Evasion & De-escalation ---")
	dumpster.reset_dumpster()
	await process_frame

	# Trigger pursuit in world slice
	_scene.call("trigger_disturbance_alert")
	await process_frame
	var cur_pursuit = _scene.get("current_pursuit_state")
	# PursuitState.DISTURBANCE_ALERT = 1
	if cur_pursuit != 1:
		await _fail("STAGE 4 FAIL: Pursuit disturbance alert failed to activate")
		return

	var entered_hiding_fired: Array = [false]
	var exited_hiding_fired: Array = [false]
	dumpster.player_entered_hiding.connect(func(_p): entered_hiding_fired[0] = true)
	dumpster.player_exited_hiding.connect(func(_p): exited_hiding_fired[0] = true)

	var entered: bool = dumpster.enter_hiding(player)
	if not entered:
		await _fail("STAGE 4 FAIL: enter_hiding returned false")
		return
	if not entered_hiding_fired[0]:
		await _fail("STAGE 4 FAIL: player_entered_hiding signal not emitted")
		return
	if not player.is_input_locked:
		await _fail("STAGE 4 FAIL: Player input not locked while hiding in dumpster")
		return
	if player.visible:
		await _fail("STAGE 4 FAIL: Player node still visible while hiding in dumpster")
		return
	if dumpster.current_state != PropScrapDumpsterScript.DumpsterState.OCCUPIED_HIDING:
		await _fail("STAGE 4 FAIL: Dumpster state not OCCUPIED_HIDING")
		return

	# Check verb while inside
	if dumpster.interactable.get_action_verb() != "EXIT":
		await _fail("STAGE 4 FAIL: Expected action verb EXIT while hiding, got " + dumpster.interactable.get_action_verb())
		return

	# Exit hiding
	var exited: bool = dumpster.exit_hiding(player)
	if not exited:
		await _fail("STAGE 4 FAIL: exit_hiding returned false")
		return
	if not exited_hiding_fired[0]:
		await _fail("STAGE 4 FAIL: player_exited_hiding signal not emitted")
		return
	if player.is_input_locked:
		await _fail("STAGE 4 FAIL: Player input still locked after exiting dumpster")
		return
	if not player.visible:
		await _fail("STAGE 4 FAIL: Player node still hidden after exiting dumpster")
		return
	print("  [STAGE 4 PASS] Stealth hiding evasion and clean exit verified.")

	# Stage 5: Melee Strike Tampering & Ejection
	print("--- Stage 5: Melee Strike Tampering & Hiding Ejection ---")
	dumpster.reset_dumpster()
	await process_frame

	var hit_fired: Array = [false]
	dumpster.hit_received.connect(func(_dur, _pos, _dir): hit_fired[0] = true)

	# Put player inside
	dumpster.enter_hiding(player)
	await process_frame

	# Melee strike on dumpster while occupied
	dumpster.take_hit(1, dumpster.global_position, Vector3.FORWARD)
	await process_frame

	if not hit_fired[0]:
		await _fail("STAGE 5 FAIL: hit_received signal not emitted on melee strike")
		return
	if dumpster.current_durability != 2:
		await _fail("STAGE 5 FAIL: Expected durability 2 after strike, got %d" % dumpster.current_durability)
		return
	if dumpster.current_state == PropScrapDumpsterScript.DumpsterState.OCCUPIED_HIDING:
		await _fail("STAGE 5 FAIL: Player not automatically ejected from dumpster upon melee strike")
		return
	if not player.visible or player.is_input_locked:
		await _fail("STAGE 5 FAIL: Ejected player left in locked or hidden state")
		return
	print("  [STAGE 5 PASS] Melee strike tampering and hiding player ejection verified.")

	# Stage 6: High-Speed Vehicle Ram Impact
	print("--- Stage 6: High-Speed Vehicle Ram Impact ---")
	dumpster.reset_dumpster()
	await process_frame

	# Slow ram (< 4.5 m/s) should be safely rejected
	var slow_ram: bool = dumpster.apply_vehicle_ram(3.2, Vector3.FORWARD)
	if slow_ram:
		await _fail("STAGE 6 FAIL: Low-speed ram (< 4.5 m/s) should have been rejected")
		return

	# Put player inside
	dumpster.enter_hiding(player)
	await process_frame

	var initial_pos: Vector3 = dumpster.global_position
	var ram_fired: Array = [false]
	dumpster.dumpster_rammed.connect(func(_spd, _dir): ram_fired[0] = true)

	# High-speed ram
	var fast_ram: bool = dumpster.apply_vehicle_ram(8.5, Vector3.FORWARD, coupe)
	if not fast_ram:
		await _fail("STAGE 6 FAIL: High-speed vehicle ram rejected")
		return
	if not ram_fired[0]:
		await _fail("STAGE 6 FAIL: dumpster_rammed signal not emitted")
		return
	if not dumpster.is_rammed:
		await _fail("STAGE 6 FAIL: dumpster is_rammed flag false after ram")
		return
	if dumpster.current_state != PropScrapDumpsterScript.DumpsterState.RAMMED:
		await _fail("STAGE 6 FAIL: Dumpster state not RAMMED")
		return
	if dumpster.current_state == PropScrapDumpsterScript.DumpsterState.OCCUPIED_HIDING:
		await _fail("STAGE 6 FAIL: Hiding player not ejected after vehicle ram")
		return

	await process_frame
	await process_frame
	var displacement: float = dumpster.global_position.distance_to(initial_pos)
	if displacement < 0.2:
		await _fail("STAGE 6 FAIL: Dumpster position not displaced after heavy ram impact")
		return
	print("  [STAGE 6 PASS] High-speed vehicle ram knockback and ejection verified.")

	# Stage 7: Clean Slice Reset
	print("--- Stage 7: Reset Slice Clean Restoration ---")
	_scene.call("reset_slice")
	await process_frame
	await process_frame

	if dumpster.current_state != PropScrapDumpsterScript.DumpsterState.READY:
		await _fail("STAGE 7 FAIL: Dumpster state not READY after reset_slice()")
		return
	if dumpster.current_durability != 3:
		await _fail("STAGE 7 FAIL: Dumpster durability not restored to 3 after reset")
		return
	if dumpster.reward_granted != 0:
		await _fail("STAGE 7 FAIL: Dumpster reward_granted not reset to 0")
		return
	if dumpster.is_rammed:
		await _fail("STAGE 7 FAIL: Dumpster is_rammed still true after reset")
		return
	if dumpster.global_position.distance_to(initial_pos) > 0.1:
		await _fail("STAGE 7 FAIL: Dumpster position not restored to initial position")
		return
	print("  [STAGE 7 PASS] Full slice reset restores dumpster to cold start state cleanly.")

	print("\n=========================================================================")
	print("[SCRAP_DUMPSTER_INTEGRATION_TEST] 100% CONTRACT PASS")
	print("=========================================================================\n")
	await _finish(0)
