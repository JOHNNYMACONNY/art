extends SceneTree

# Issue #30 regression: desktop/touch traversal remains live-camera-relative while
# the camera follows on-foot movement and vehicle heading without snaps.
# Issue #60 adds a bounded visual-style integration contract here because this test
# is already an exact-head PR gate in godot-web-playtest.yml.
var _scene_under_test: Node = null

const GEARS_REQUIRED_PROOF_NODES := [
	"MixedUseBlock",
	"PrimaryRouteBand",
	"ShortcutRouteBand",
	"MunicipalGantry",
	"Storefront",
	"DistantRelay",
	"PracticalLights",
	"Storefront/HeroSignIcon",
]

const GEARS_REQUIRED_TREATED_ACTORS := [
	"Runner",
	"CourierBike",
	"ScrapHauler",
	"PursuerPrototype",
	"ScrapWorker1",
	"UtilityCrawler",
]

const GEARS_REQUIRED_RUNTIME_CONTOURS := [
	"Runner/MeshPivot/Torso/TorsoOutline",
	"CourierBike/VisualRoot/FrontTank/TankOutline",
	"ScrapHauler/VisualRoot/Cabin/CabinOutline",
	"ScrapHauler/VisualRoot/Hood/HoodOutline",
	"PursuerPrototype/VisualRoot/GearsPursuitBodyContour",
	"ScrapWorker1/MeshPivot/GearsWorkerTorsoContour",
	"UtilityCrawler/Chassis/GearsCrawlerBodyContour",
	"CorrodedPanel/GearsInteractablePanelContour",
]

const GEARS_REQUIRED_RUNTIME_MARKINGS := [
	"CourierBike/VisualRoot/GearsAmberCourierPanel",
	"PursuerPrototype/VisualRoot/GearsPursuitRoofID",
	"PursuerPrototype/VisualRoot/GearsPursuitFrontBand",
	"PursuerPrototype/VisualRoot/PursuitAssetLabel",
	"UtilityCrawler/Chassis/GearsReplacementPanel",
	"UtilityCrawler/Chassis/CrawlerAssetID",
]

const GEARS_REQUIRED_FLAGS := [
	"stacked_mixed_use",
	"primary_route",
	"shortcut_route",
	"municipal_anchor",
	"storefront_family",
	"worker_treatment",
	"courier_bike_treatment",
	"courier_repair_panel",
	"utility_vehicle_treatment",
	"pursuit_vehicle_treatment",
	"pursuit_civic_livery",
	"utility_robot_treatment",
	"utility_robot_asset_marking",
	"interactable_treatment",
	"distant_landmark",
	"practical_lighting",
	"uses_retained_camera",
]

const GEARS_GRAPHIC_FAMILIES := ["municipal", "commercial", "aftermarket", "asset_marking"]

func _init() -> void:
	call_deferred("_run")

func _finish(exit_code: int) -> void:
	_release_key(KEY_W)
	if is_instance_valid(_scene_under_test):
		_scene_under_test.queue_free()
		await process_frame
		await process_frame
	quit(exit_code)

func _fail(message: String) -> void:
	push_error("[DYNAMIC_CAMERA_AB] %s" % message)
	await _finish(1)

func _proof_fail(message: String, exit_code: int) -> void:
	push_error("[GEARS_STYLE_PROOF_60] %s [diagnostic=%d]" % [message, exit_code])
	await _finish(exit_code)

func _key_event(key: Key, pressed: bool) -> InputEventKey:
	var event := InputEventKey.new()
	event.physical_keycode = key
	event.keycode = key
	event.pressed = pressed
	return event

func _inject_key(key: Key, pressed: bool) -> void:
	Input.parse_input_event(_key_event(key, pressed))
	Input.flush_buffered_events()

func _release_key(key: Key) -> void:
	_inject_key(key, false)

func _yaw_error(actual: float, expected: float) -> float:
	return abs(wrapf(actual - expected, -PI, PI))

func _verify_gears_style_proof() -> bool:
	var toon_shader := load("res://materials/gears_toon.gdshader") as Shader
	var outline_shader := load("res://materials/gears_outline.gdshader") as Shader
	if toon_shader == null or outline_shader == null:
		await _proof_fail("Lightweight toon/outline shader resources are missing or invalid", 60)
		return false

	var proof := _scene_under_test.get_node_or_null("GearsStyleProof")
	if proof == null or not proof.has_method("get_proof_contract"):
		await _proof_fail("GearsStyleProof integration node/contract is missing", 61)
		return false

	for i in range(GEARS_REQUIRED_PROOF_NODES.size()):
		var child_name: String = GEARS_REQUIRED_PROOF_NODES[i]
		if proof.get_node_or_null(child_name) == null:
			await _proof_fail("Proof composition node missing: %s" % child_name, 70 + i)
			return false

	for i in range(GEARS_REQUIRED_TREATED_ACTORS.size()):
		var actor_name: String = GEARS_REQUIRED_TREATED_ACTORS[i]
		var actor := _scene_under_test.get_node_or_null(actor_name)
		if actor == null or not actor.has_meta("gears_style_proof_treatment"):
			await _proof_fail("Actor treatment missing: %s" % actor_name, 80 + i)
			return false

	var panel := _scene_under_test.get_node_or_null("CorrodedPanel")
	if panel == null or not panel.has_meta("gears_style_proof_treatment"):
		await _proof_fail("Interactable proof treatment missing: CorrodedPanel", 86)
		return false

	for i in range(GEARS_REQUIRED_RUNTIME_CONTOURS.size()):
		var contour_path: String = GEARS_REQUIRED_RUNTIME_CONTOURS[i]
		var contour := _scene_under_test.get_node_or_null(contour_path) as MeshInstance3D
		if contour == null:
			await _proof_fail("Selective gameplay contour missing: %s" % contour_path, 130 + i)
			return false
		var contour_material := contour.material_override as ShaderMaterial
		if contour_material == null or contour_material.shader == null:
			await _proof_fail("Selective gameplay contour has no outline shader: %s" % contour_path, 140 + i)
			return false
		if contour_material.shader.resource_path != outline_shader.resource_path:
			await _proof_fail("Selective gameplay contour uses wrong shader: %s" % contour_path, 150 + i)
			return false

	for i in range(GEARS_REQUIRED_RUNTIME_MARKINGS.size()):
		var marking_path: String = GEARS_REQUIRED_RUNTIME_MARKINGS[i]
		if _scene_under_test.get_node_or_null(marking_path) == null:
			await _proof_fail("Required bounded identity/repair marking missing: %s" % marking_path, 160 + i)
			return false

	var contract: Dictionary = proof.call("get_proof_contract")
	for i in range(GEARS_REQUIRED_FLAGS.size()):
		var flag: String = GEARS_REQUIRED_FLAGS[i]
		if contract.get(flag, false) != true:
			await _proof_fail("Proof contract flag failed: %s" % flag, 90 + i)
			return false

	var graphics: Array = contract.get("graphic_families", [])
	for i in range(GEARS_GRAPHIC_FAMILIES.size()):
		var family: String = GEARS_GRAPHIC_FAMILIES[i]
		if not graphics.has(family):
			await _proof_fail("Graphic proof family missing: %s" % family, 110 + i)
			return false

	var generated_meshes := int(contract.get("generated_mesh_instances", 9999))
	var outline_meshes := int(contract.get("outline_instances", 0))
	var practical_lights := int(contract.get("practical_light_count", 9999))
	if generated_meshes <= 0 or generated_meshes > 90:
		await _proof_fail("Generated mesh budget invalid: %d" % generated_meshes, 120)
		return false
	if outline_meshes <= 0 or outline_meshes > 24:
		await _proof_fail("Selective contour budget invalid: %d" % outline_meshes, 121)
		return false
	if practical_lights <= 0 or practical_lights > 6:
		await _proof_fail("Practical light budget invalid: %d" % practical_lights, 122)
		return false

	if not proof.has_method("set_lighting_mode"):
		await _proof_fail("Deterministic day/dusk comparison API is missing", 123)
		return false
	var store_light := proof.get_node_or_null("PracticalLights/StoreWorkLamp") as OmniLight3D
	if store_light == null:
		await _proof_fail("Store practical light is missing", 124)
		return false
	var day_energy := store_light.light_energy
	proof.call("set_lighting_mode", "dusk")
	await process_frame
	if store_light.light_energy <= day_energy:
		await _proof_fail("Dusk mode did not strengthen the practical-light hierarchy", 125)
		return false
	proof.call("set_lighting_mode", "day")
	await process_frame
	if absf(store_light.light_energy - day_energy) > 0.001:
		await _proof_fail("Day/dusk comparison does not reset deterministically", 126)
		return false
	return true

func _run() -> void:
	var packed := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if packed == null:
		await _fail("Could not load scrap_test_block.tscn")
		return

	_scene_under_test = packed.instantiate()
	root.add_child(_scene_under_test)
	await process_frame
	await physics_frame
	await process_frame

	var camera := _scene_under_test.get_node_or_null("ChinatownCamera3D")
	var player := _scene_under_test.get_node_or_null("Runner")
	var courier_bike := _scene_under_test.get_node_or_null("CourierBike")
	var scrap_hauler := _scene_under_test.get_node_or_null("ScrapHauler")
	if camera == null or player == null or courier_bike == null or scrap_hauler == null:
		await _fail("Main scene is missing camera/player/Bike/Hauler integration nodes")
		return

	if not await _verify_gears_style_proof():
		return

	# 1. CourierBike uses the strong vehicle-heading follow path.
	camera.call("reset_camera_instant", courier_bike)
	courier_bike.rotation.y = deg_to_rad(90.0)
	courier_bike.current_speed = 8.0
	courier_bike.velocity = Vector3(-8.0, 0.0, 0.0)
	for _i in range(90):
		camera.call("_process", 0.016)
	var bike_fwd: Vector3 = -courier_bike.global_transform.basis.z
	var bike_expected := wrapf(atan2(bike_fwd.x, bike_fwd.z) + PI, -PI, PI)
	if _yaw_error(float(camera.get("_current_yaw_rad")), bike_expected) >= 0.35:
		await _fail("CourierBike camera yaw did not converge to vehicle heading")
		return

	# 2. ScrapHauler has exact vehicle-heading parity.
	camera.call("reset_camera_instant", scrap_hauler)
	scrap_hauler.rotation.y = deg_to_rad(-90.0)
	scrap_hauler.current_speed = 6.0
	scrap_hauler.velocity = Vector3(6.0, 0.0, 0.0)
	for _i in range(90):
		camera.call("_process", 0.016)
	var hauler_fwd: Vector3 = -scrap_hauler.global_transform.basis.z
	var hauler_expected := wrapf(atan2(hauler_fwd.x, hauler_fwd.z) + PI, -PI, PI)
	if _yaw_error(float(camera.get("_current_yaw_rad")), hauler_expected) >= 0.35:
		await _fail("ScrapHauler did not use the vehicle-heading follow path")
		return

	# 3. On-foot sustained movement rotates camera toward movement direction.
	camera.call("reset_camera_instant", player)
	player.velocity = Vector3(0.0, 0.0, 3.5)
	for _i in range(90):
		camera.call("_process", 0.016)
	var foot_expected := wrapf(PI, -PI, PI)
	if _yaw_error(float(camera.get("_current_yaw_rad")), foot_expected) >= 0.40:
		await _fail("On-foot camera yaw did not follow sustained movement")
		return

	# 4. Physical W and touch-up both remain screen-forward after material camera yaw.
	camera.set("dynamic_yaw_enabled", false)
	camera.set("_current_yaw_rad", PI / 2.0)
	camera.call("set_target", player)
	camera.call("_process", 0.016)
	player.set_joystick_input(Vector2.ZERO)
	player.velocity = Vector3.ZERO
	_inject_key(KEY_W, true)
	player._physics_process(0.1)
	_release_key(KEY_W)
	var cam_basis: Basis = camera.global_transform.basis
	var cam_fwd_xz := Vector3(-cam_basis.z.x, 0.0, -cam_basis.z.z).normalized()
	var player_dir := Vector3(player.velocity.x, 0.0, player.velocity.z).normalized()
	if player_dir.length_squared() < 0.5 or player_dir.dot(cam_fwd_xz) <= 0.95:
		await _fail("Physical W is not live-camera-relative after camera rotation")
		return

	player.velocity = Vector3.ZERO
	player.set_joystick_input(Vector2(0.0, -1.0))
	player._physics_process(0.1)
	player.set_joystick_input(Vector2.ZERO)
	var touch_dir := Vector3(player.velocity.x, 0.0, player.velocity.z).normalized()
	if touch_dir.length_squared() < 0.5 or touch_dir.dot(cam_fwd_xz) <= 0.95:
		await _fail("Touch joystick up is not live-camera-relative after camera rotation")
		return
	camera.set("dynamic_yaw_enabled", true)

	# 5. Interaction mode freezes yaw; exit makes bounded progress and converges.
	camera.call("reset_camera_instant", player)
	var before_interaction := float(camera.get("_current_yaw_rad"))
	camera.call("set_interaction_mode", true, player)
	player.velocity = Vector3(10.0, 0.0, 10.0)
	for _i in range(30):
		camera.call("_process", 0.016)
	if _yaw_error(float(camera.get("_current_yaw_rad")), before_interaction) > 0.001:
		await _fail("Camera yaw moved during interaction mode")
		return
	camera.call("set_interaction_mode", false)
	var before_resume := float(camera.get("_current_yaw_rad"))
	camera.call("_process", 0.016)
	var resume_step := _yaw_error(float(camera.get("_current_yaw_rad")), before_resume)
	var max_yaw_speed := float(camera.get("max_yaw_speed"))
	if resume_step <= 0.0001:
		await _fail("Camera yaw stayed frozen after leaving interaction mode")
		return
	if resume_step > max_yaw_speed * 0.016 + 0.001:
		await _fail("Camera snapped when leaving interaction mode")
		return
	var resume_expected := wrapf(atan2(player.velocity.x, player.velocity.z) + PI, -PI, PI)
	for _i in range(149):
		camera.call("_process", 0.016)
	if _yaw_error(float(camera.get("_current_yaw_rad")), resume_expected) >= 0.40:
		await _fail("Camera yaw resumed but did not converge after interaction mode")
		return

	print("[DYNAMIC_CAMERA_AB] PASS")
	await _finish(0)
