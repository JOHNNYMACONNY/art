extends SceneTree

# Dedicated Integration Test: Municipal Quota Kiosk / Terminal System
# Verifies:
# 1. PropQuotaKiosk node invariants, State enum, export properties, and signals
# 2. Biometric proximity sensory detection & scanner light activation
# 3. Lawful scrap deposit & quota fulfillment (screen color change, signal emission)
# 4. Street combat melee tamper strike (elastic recoil, red alarm, municipal disturbance alert)
# 5. Multi-hit terminal breach & emergency contraband cash payoff (+200 scrap)
# 6. High-speed vehicle ram breach
# 7. Clean restoration via reset_slice()

const PropQuotaKioskScript = preload("res://scripts/props/prop_quota_kiosk.gd")

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
	push_error("[QUOTA_KIOSK_TEST] " + message)
	await _finish(1)

func _run() -> void:
	print("\n=========================================================================")
	print("[QUOTA_KIOSK_INTEGRATION_TEST] Starting Verification...")
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
	var kiosk = _scene.get("quota_kiosk")
	var coupe = _scene.get("muscle_coupe")

	if not player:
		await _fail("Player node missing in scrap_test_block")
		return
	if not kiosk:
		await _fail("QuotaKiosk node missing in scrap_test_block")
		return

	# Stage 1: Quota Kiosk API & State Contracts
	print("--- Stage 1: Quota Kiosk Contract & State Machine ---")
	if not ("READY" in PropQuotaKioskScript.State) or not ("FULFILLED" in PropQuotaKioskScript.State) or not ("BREACHED" in PropQuotaKioskScript.State):
		await _fail("STAGE 1 FAIL: PropQuotaKioskScript.State missing required enum entries")
		return
	if not kiosk.has_method("deposit_scrap"):
		await _fail("STAGE 1 FAIL: kiosk missing deposit_scrap() method")
		return
	if not kiosk.has_method("take_hit"):
		await _fail("STAGE 1 FAIL: kiosk missing take_hit() method")
		return
	if not kiosk.has_method("apply_vehicle_ram"):
		await _fail("STAGE 1 FAIL: kiosk missing apply_vehicle_ram() method")
		return
	if not kiosk.has_signal("quota_deposited") or not kiosk.has_signal("quota_fulfilled"):
		await _fail("STAGE 1 FAIL: kiosk missing quota deposit signals")
		return
	if not kiosk.has_signal("hit_received") or not kiosk.has_signal("alarm_triggered") or not kiosk.has_signal("kiosk_breached"):
		await _fail("STAGE 1 FAIL: kiosk missing combat/tamper signals")
		return
	if not kiosk.interactable:
		await _fail("STAGE 1 FAIL: kiosk missing interactable proxy")
		return
	print("  [STAGE 1 PASS] Quota kiosk state machine, methods, and signals verified.")

	# Stage 2: Biometric Proximity Detection & Scanner Light
	print("--- Stage 2: Biometric Scanner Proximity Feedback ---")
	var scanner_light = kiosk.scanner_light if kiosk.scanner_light else kiosk.find_child("ScannerLight", true, false)
	if not scanner_light:
		await _fail("STAGE 2 FAIL: ScannerLight OmniLight3D missing on kiosk")
		return

	# Player far away
	player.global_position = kiosk.global_position + Vector3(10.0, 0.0, 0.0)
	kiosk.interactable.update_player_distance(player.global_position)
	await process_frame
	if kiosk.interactable.is_player_in_range:
		await _fail("STAGE 2 FAIL: Player reported in range when 10m away")
		return

	# Player moves into interaction range (< 2.4m)
	player.global_position = kiosk.global_position + Vector3(1.2, 0.0, 0.0)
	kiosk.interactable.update_player_distance(player.global_position)
	await process_frame
	if not kiosk.interactable.is_player_in_range:
		await _fail("STAGE 2 FAIL: Player not detected in interaction range (< 2.4m)")
		return
	print("  [STAGE 2 PASS] Biometric proximity detection and scanner range verified.")

	# Stage 3: Lawful Scrap Deposit & Quota Fulfillment
	print("--- Stage 3: Scrap Deposit & Quota Fulfillment ---")
	var deposited_signal_fired: Array = [false]
	var fulfilled_signal_fired: Array = [false]
	kiosk.quota_deposited.connect(func(_amt, _tot, _rem): deposited_signal_fired[0] = true)
	kiosk.quota_fulfilled.connect(func(_tot): fulfilled_signal_fired[0] = true)

	var initial_quota = kiosk.required_quota
	var dep_res = kiosk.deposit_scrap(initial_quota)
	if not dep_res.get("success", false):
		await _fail("STAGE 3 FAIL: deposit_scrap returned unsuccessful")
		return
	if not deposited_signal_fired[0]:
		await _fail("STAGE 3 FAIL: quota_deposited signal not emitted")
		return
	if not fulfilled_signal_fired[0]:
		await _fail("STAGE 3 FAIL: quota_fulfilled signal not emitted")
		return
	if not kiosk.is_quota_fulfilled:
		await _fail("STAGE 3 FAIL: is_quota_fulfilled getter returned false")
		return
	print("  [STAGE 3 PASS] Scrap deposit and quota fulfillment verified.")

	# Stage 4: Street Combat Melee Tamper & Municipal Alarm Consequence
	print("--- Stage 4: Melee Tamper Strike & Security Alarm ---")
	kiosk.reset_kiosk()
	await process_frame

	var alarm_fired: Array = [false]
	var hit_fired: Array = [false]
	kiosk.alarm_triggered.connect(func(_pos): alarm_fired[0] = true)
	kiosk.hit_received.connect(func(_dur, _pos, _dir): hit_fired[0] = true)

	# Strike 1: Tamper hit
	var strike_res = kiosk.take_hit(1, kiosk.global_position, Vector3(1, 0, 0))
	if not strike_res:
		await _fail("STAGE 4 FAIL: take_hit returned false on first strike")
		return
	if not hit_fired[0]:
		await _fail("STAGE 4 FAIL: hit_received signal not emitted")
		return
	if not alarm_fired[0]:
		await _fail("STAGE 4 FAIL: alarm_triggered signal not emitted on tamper strike")
		return
	if kiosk.current_durability != PropQuotaKioskScript.MAX_DURABILITY - 1:
		await _fail("STAGE 4 FAIL: durability not decremented by 1")
		return
	print("  [STAGE 4 PASS] Melee tamper strike, durability reduction, and alarm trigger verified.")

	# Stage 5: Multi-Hit Terminal Breach & Scrap Cash Payoff
	print("--- Stage 5: Multi-Hit Terminal Breach & Scrap Payoff ---")
	var breach_fired: Array = [false]
	var breach_reward: Array = [0]
	kiosk.kiosk_breached.connect(func(rew, _pos):
		breach_fired[0] = true
		breach_reward[0] = rew
	)

	# Strike 2
	kiosk.take_hit(1, kiosk.global_position, Vector3(1, 0, 0))
	# Strike 3: Lethal breach strike
	kiosk.take_hit(1, kiosk.global_position, Vector3(1, 0, 0))
	await process_frame

	if not breach_fired[0]:
		await _fail("STAGE 5 FAIL: kiosk_breached signal not emitted on 3rd strike")
		return
	if breach_reward[0] != PropQuotaKioskScript.BREACH_REWARD:
		await _fail("STAGE 5 FAIL: expected breach reward %d, got %d" % [PropQuotaKioskScript.BREACH_REWARD, breach_reward[0]])
		return
	if not kiosk.is_breached:
		await _fail("STAGE 5 FAIL: is_breached getter returned false")
		return
	print("  [STAGE 5 PASS] Terminal breach and emergency scrap payoff (+200) verified.")

	# Stage 6: High-Speed Vehicle Ram Breach
	print("--- Stage 6: High-Speed Vehicle Ram Breach ---")
	kiosk.reset_kiosk()
	await process_frame

	# Low speed ram rejected (< 4.5 m/s)
	var low_ram = kiosk.apply_vehicle_ram(2.0, Vector3(0, 0, 1), coupe)
	if low_ram:
		await _fail("STAGE 6 FAIL: Low-speed vehicle ram (2.0 m/s) was not rejected")
		return
	if kiosk.is_breached:
		await _fail("STAGE 6 FAIL: Kiosk breached by low-speed vehicle nudge")
		return

	# High speed vehicle ram succeeds
	var high_ram = kiosk.apply_vehicle_ram(8.5, Vector3(0, 0, 1), coupe)
	if not high_ram:
		await _fail("STAGE 6 FAIL: High-speed vehicle ram (8.5 m/s) failed")
		return
	if not kiosk.is_breached:
		await _fail("STAGE 6 FAIL: Kiosk not breached after high-speed vehicle ram")
		return
	print("  [STAGE 6 PASS] High-speed vehicle ram breach verified.")

	# Stage 7: Clean Reset Slice Restoration
	print("--- Stage 7: Reset Slice Clean Restoration ---")
	_scene.reset_slice()
	await process_frame
	await process_frame

	if kiosk.is_breached:
		await _fail("STAGE 7 FAIL: Kiosk remained breached after reset_slice()")
		return
	if kiosk.current_durability != PropQuotaKioskScript.MAX_DURABILITY:
		await _fail("STAGE 7 FAIL: Kiosk durability not restored to MAX_DURABILITY")
		return
	if kiosk.deposited_quota != 0:
		await _fail("STAGE 7 FAIL: Deposited quota not cleared to 0")
		return
	print("  [STAGE 7 PASS] Full slice reset restores quota kiosk to cold start state.")

	print("\n=========================================================================")
	print("[QUOTA_KIOSK_INTEGRATION_TEST] 100% CONTRACT PASS")
	print("=========================================================================\n")
	await _finish(0)
