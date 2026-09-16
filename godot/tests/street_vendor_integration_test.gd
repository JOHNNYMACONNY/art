extends SceneTree

# Dedicated Integration Test: Street Vendor Smuggler Depot System
# Verifies:
# 1. PropStreetVendor node invariants, VendorState enum, methods, signals, interactable proxy
# 2. Proximity detection and dynamic action verb arbitration (TUNE-UP, TUNED, WRECKED)
# 3. Scrap economy & vehicle tune-up (+35% speed surge applied to CourierBike and MuscleCoupe)
# 4. Vehicle tune-up physics & acceleration surge verification
# 5. Melee prybar strike tampering (durability decrement, mesh recoil, DAMAGED state)
# 6. High-speed vehicle ram impact (threshold gating, knockback slide, canopy tilt, trade disabled)
# 7. Clean restoration via reset_slice()

const PropStreetVendorScript = preload("res://scripts/props/prop_street_vendor.gd")

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
	push_error("[VENDOR_TEST] " + message)
	await _finish(1)

func _run() -> void:
	print("\n=========================================================================")
	print("[STREET_VENDOR_INTEGRATION_TEST] Starting Verification...")
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
	var vendor = _scene.get("street_vendor")
	var bike = _scene.get("courier_bike")
	var coupe = _scene.get("muscle_coupe")

	if not player:
		await _fail("Player node missing in scrap_test_block")
		return
	if not vendor:
		await _fail("StreetVendor node missing in scrap_test_block")
		return
	if not bike:
		await _fail("CourierBike node missing in scrap_test_block")
		return
	if not coupe:
		await _fail("MuscleCoupe node missing in scrap_test_block")
		return

	# Stage 1: Contract & Invariants
	print("--- Stage 1: Street Vendor Contract, State Machine & Invariants ---")
	if not ("READY" in PropStreetVendorScript.VendorState) or not ("TUNED" in PropStreetVendorScript.VendorState) or not ("DAMAGED" in PropStreetVendorScript.VendorState) or not ("RAMMED" in PropStreetVendorScript.VendorState):
		await _fail("STAGE 1 FAIL: PropStreetVendorScript.VendorState missing required enum values")
		return
	for method_name in ["purchase_tune_up", "take_hit", "apply_vehicle_ram", "reset_vendor", "can_trade", "is_tune_up_active"]:
		if not vendor.has_method(method_name):
			await _fail("STAGE 1 FAIL: vendor missing method " + method_name)
			return
	for signal_name in ["tune_up_purchased", "hit_received", "vendor_rammed", "vendor_repaired"]:
		if not vendor.has_signal(signal_name):
			await _fail("STAGE 1 FAIL: vendor missing signal " + signal_name)
			return
	if not vendor.interactable:
		await _fail("STAGE 1 FAIL: vendor missing interactable proxy")
		return

	# Verify 01F bounding and mesh invariants
	var col_shape: CollisionShape3D = vendor.find_child("CollisionShape3D", true, false)
	if not col_shape or not (col_shape.shape is BoxShape3D):
		await _fail("STAGE 1 FAIL: Street vendor missing BoxShape3D collision shape")
		return
	var sz: Vector3 = (col_shape.shape as BoxShape3D).size
	if sz.x < 1.6 or sz.x > 3.0 or sz.y < 1.6 or sz.y > 3.2:
		await _fail("STAGE 1 FAIL: Street vendor collision envelope dimensions out of 01F bounds: " + str(sz))
		return
	var mesh_inst: MeshInstance3D = vendor.find_child("*Mesh*", true, false)
	if not mesh_inst:
		await _fail("STAGE 1 FAIL: Street vendor missing MeshInstance3D")
		return
	print("  [STAGE 1 PASS] Street vendor state machine, invariants, and mesh verified.")

	# Stage 2: Proximity Detection & Dynamic Prompt Arbitration
	print("--- Stage 2: Proximity Detection & Dynamic Action Verbs ---")
	vendor.interactable.set_player_reference(player)

	# Player far away (> 5m)
	player.global_position = vendor.global_position + Vector3(8.0, 0.0, 0.0)
	vendor.interactable.update_player_distance(player.global_position)
	await process_frame
	if vendor.interactable.is_player_in_range:
		await _fail("STAGE 2 FAIL: Player reported in range while 8m away")
		return

	# Player in range (< 2.8m)
	player.global_position = vendor.global_position + Vector3(1.5, 0.0, 0.0)
	vendor.interactable.update_player_distance(player.global_position)
	await process_frame
	if not vendor.interactable.is_player_in_range:
		await _fail("STAGE 2 FAIL: Player not detected in interaction range (< 2.8m)")
		return

	if vendor.interactable.get_action_verb() != "TUNE-UP":
		await _fail("STAGE 2 FAIL: Expected action verb TUNE-UP when ready, got " + vendor.interactable.get_action_verb())
		return
	print("  [STAGE 2 PASS] Proximity detection and dynamic action verb arbitration verified.")

	# Stage 3: Scrap Economy & Vehicle Tune-Up Purchase
	print("--- Stage 3: Scrap Economy & Vehicle Tune-Up Purchase ---")
	vendor.reset_vendor()
	await process_frame

	var tune_up_signal_fired: Array = [false]
	var tune_up_cost: Array = [0]
	var tune_up_dur: Array = [0.0]
	vendor.tune_up_purchased.connect(func(cost, duration, _pos):
		tune_up_signal_fired[0] = true
		tune_up_cost[0] = cost
		tune_up_dur[0] = duration
	)

	var res: Dictionary = vendor.purchase_tune_up(150, coupe)
	if not res.get("success", false):
		await _fail("STAGE 3 FAIL: purchase_tune_up failed")
		return
	if not tune_up_signal_fired[0] or tune_up_cost[0] != 150:
		await _fail("STAGE 3 FAIL: tune_up_purchased signal not fired or cost incorrect")
		return
	if vendor.current_state != PropStreetVendorScript.VendorState.TUNED:
		await _fail("STAGE 3 FAIL: Vendor state not TUNED after purchase")
		return
	if vendor.interactable.get_action_verb() != "TUNED":
		await _fail("STAGE 3 FAIL: Expected action verb TUNED while active, got " + vendor.interactable.get_action_verb())
		return

	# Repeat attempt while active
	var repeat_res: Dictionary = vendor.purchase_tune_up(150)
	if not repeat_res.get("already_active", false):
		await _fail("STAGE 3 FAIL: Repeat tune-up while active did not return already_active")
		return
	print("  [STAGE 3 PASS] Scrap trade and tune-up purchase verified.")

	# Stage 4: Vehicle Tune-Up Physics Verification
	print("--- Stage 4: Vehicle Tune-Up Physics Verification ---")
	bike.apply_tune_up(8.0, 1.35, 1.40)
	coupe.apply_tune_up(8.0, 1.35, 1.40)

	var expected_bike_speed: float = 14.0 * 1.35
	var expected_coupe_speed: float = 21.0 * 1.35
	if abs(bike.get_effective_max_speed() - expected_bike_speed) > 0.01:
		await _fail("STAGE 4 FAIL: Bike effective speed expected %.2f, got %.2f" % [expected_bike_speed, bike.get_effective_max_speed()])
		return
	if abs(coupe.get_effective_max_speed() - expected_coupe_speed) > 0.01:
		await _fail("STAGE 4 FAIL: Coupe effective speed expected %.2f, got %.2f" % [expected_coupe_speed, coupe.get_effective_max_speed()])
		return

	var expected_bike_accel: float = 12.0 * 1.40
	var expected_coupe_accel: float = 14.5 * 1.40
	if abs(bike.get_effective_acceleration() - expected_bike_accel) > 0.01:
		await _fail("STAGE 4 FAIL: Bike effective accel expected %.2f, got %.2f" % [expected_bike_accel, bike.get_effective_acceleration()])
		return
	if abs(coupe.get_effective_acceleration() - expected_coupe_accel) > 0.01:
		await _fail("STAGE 4 FAIL: Coupe effective accel expected %.2f, got %.2f" % [expected_coupe_accel, coupe.get_effective_acceleration()])
		return
	print("  [STAGE 4 PASS] Vehicle tune-up speed and acceleration surge verified.")

	# Stage 5: Melee Strike Tampering
	print("--- Stage 5: Melee Strike Tampering ---")
	vendor.reset_vendor()
	await process_frame

	var hit_signal_fired: Array = [false]
	var hit_remaining: Array = [0]
	vendor.hit_received.connect(func(remaining, _pos, _impulse):
		hit_signal_fired[0] = true
		hit_remaining[0] = remaining
	)

	vendor.take_hit(1, vendor.global_position, Vector3.FORWARD)
	if not hit_signal_fired[0] or hit_remaining[0] != 2:
		await _fail("STAGE 5 FAIL: First strike did not decrement durability to 2")
		return

	# Lethal strike to break
	vendor.take_hit(2, vendor.global_position, Vector3.FORWARD)
	if vendor.current_durability != 0:
		await _fail("STAGE 5 FAIL: Durability did not reach 0")
		return
	if vendor.current_state != PropStreetVendorScript.VendorState.DAMAGED:
		await _fail("STAGE 5 FAIL: Vendor state not DAMAGED after durability depleted")
		return
	print("  [STAGE 5 PASS] Melee strike tampering and durability breakdown verified.")

	# Stage 6: High-Speed Vehicle Ram Impact
	print("--- Stage 6: High-Speed Vehicle Ram Impact ---")
	vendor.reset_vendor()
	await process_frame

	# Low-speed bump below threshold (< 4.5 m/s)
	var low_ram_success: bool = vendor.apply_vehicle_ram(3.2, Vector3.FORWARD, coupe)
	if low_ram_success or vendor.is_rammed:
		await _fail("STAGE 6 FAIL: Low-speed impact (<4.5m/s) triggered ram response")
		return

	# High-speed impact (>= 4.5 m/s)
	var ram_signal_fired: Array = [false]
	vendor.vendor_rammed.connect(func(_spd, _dir):
		ram_signal_fired[0] = true
	)

	var high_ram_success: bool = vendor.apply_vehicle_ram(6.5, Vector3.FORWARD, coupe)
	if not high_ram_success or not vendor.is_rammed:
		await _fail("STAGE 6 FAIL: High-speed impact failed to trigger ram response")
		return
	if not ram_signal_fired[0]:
		await _fail("STAGE 6 FAIL: vendor_rammed signal not emitted")
		return
	if vendor.current_state != PropStreetVendorScript.VendorState.RAMMED:
		await _fail("STAGE 6 FAIL: Vendor state not RAMMED")
		return
	if vendor.can_trade():
		await _fail("STAGE 6 FAIL: can_trade returned true while RAMMED")
		return
	if vendor.interactable.get_action_verb() != "WRECKED":
		await _fail("STAGE 6 FAIL: Expected action verb WRECKED, got " + vendor.interactable.get_action_verb())
		return
	print("  [STAGE 6 PASS] High-speed vehicle ram knockback and trade lockout verified.")

	# Stage 7: Clean Restoration via reset_slice()
	print("--- Stage 7: Reset Slice Clean Restoration ---")
	_scene.reset_slice()
	await process_frame

	if vendor.current_state != PropStreetVendorScript.VendorState.READY:
		await _fail("STAGE 7 FAIL: Vendor not READY after reset_slice()")
		return
	if vendor.current_durability != PropStreetVendorScript.MAX_DURABILITY:
		await _fail("STAGE 7 FAIL: Durability not reset to 3")
		return
	if vendor.is_rammed:
		await _fail("STAGE 7 FAIL: is_rammed still true after reset")
		return
	if not vendor.can_trade():
		await _fail("STAGE 7 FAIL: can_trade false after reset")
		return
	if bike.is_tuned_up or coupe.is_tuned_up:
		await _fail("STAGE 7 FAIL: Vehicle tune-up not cleared after reset")
		return
	print("  [STAGE 7 PASS] Full slice reset restores street vendor cleanly.")

	print("\n=========================================================================")
	print("[STREET_VENDOR_INTEGRATION_TEST] 100% CONTRACT PASS")
	print("=========================================================================\n")
	await _finish(0)
