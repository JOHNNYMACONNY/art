extends SceneTree

# #212: actual opening-scene camera ray and bike objective visibility.
# This is a Godot runtime/authoring contract, not human visual proof.
const OCCLUSION_LAYER: int = 1 << 30
const OPENING_SCENE := "res://scenes/prototype/scrap_test_block.tscn"

func _init() -> void:
	call_deferred("_run")

func _finish(code: int, scene: Node = null) -> void:
	if is_instance_valid(scene):
		scene.queue_free()
	await process_frame
	await process_frame
	quit(code)

func _fail(message: String, scene: Node = null) -> void:
	push_error("[OPENING_READABILITY_212] %s" % message)
	await _finish(1, scene)

func _run() -> void:
	var packed: PackedScene = load(OPENING_SCENE) as PackedScene
	if packed == null:
		await _fail("Opening scene not loadable")
		return
	var game: Node3D = packed.instantiate() as Node3D
	root.add_child(game)
	await process_frame
	await physics_frame
	await physics_frame

	var divider: StaticBody3D = game.get_node_or_null("ShortcutDividerWall") as StaticBody3D
	var camera: Camera3D = game.get_node_or_null("ChinatownCamera3D") as Camera3D
	var runner: Node3D = game.get_node_or_null("Runner") as Node3D
	var mission: Node = game.get_node_or_null("MissionScrapJobRuntime")
	var bike: Node3D = game.get("courier_bike") as Node3D
	if divider == null or camera == null or runner == null or bike == null or mission == null:
		await _fail("Opening scene lacks target/vehicle/camera/mission", game)
		return
	var visual: MeshInstance3D = divider.get_node_or_null("MeshInstance3D") as MeshInstance3D
	var collider: CollisionShape3D = divider.get_node_or_null("CollisionShape3D") as CollisionShape3D
	var proxy: Area3D = divider.get_node_or_null("CameraOcclusionProxy") as Area3D
	if not divider.is_in_group("camera_occluder") or visual == null or collider == null or proxy == null:
		await _fail("Divider is not an authored visual-only occluder", game)
		return
	if proxy.collision_layer != OCCLUSION_LAYER or proxy.collision_mask != 0 or proxy.monitoring:
		await _fail("Divider cutaway proxy has unsafe collision routing", game)
		return
	if collider.shape == null or collider.disabled:
		await _fail("Gameplay divider collision unexpectedly disabled", game)
		return
	var detection_shape: CollisionShape3D = proxy.get_node_or_null("CollisionShape3D") as CollisionShape3D
	var physical_box: BoxShape3D = collider.shape as BoxShape3D
	var detection_box: BoxShape3D = detection_shape.shape as BoxShape3D if detection_shape != null else null
	if physical_box == null or detection_box == null or detection_box.size.y <= physical_box.size.y * 3.0:
		await _fail("Camera proxy must cover perspective silhouette without resizing gameplay wall", game)
		return

	camera.call("reset_camera_instant", runner)
	await physics_frame
	camera.call("_update_occlusion_cutaway", runner.global_position + Vector3(0.0, 0.5, 0.0), 0.016)
	if visual.visible:
		await _fail("Opening divider still obscures the subject on the actual camera ray", game)
		return
	if collider.disabled:
		await _fail("Camera cutaway modified gameplay collision", game)
		return

	camera.set("occlusion_enabled", false)
	camera.call("_update_occlusion_cutaway", runner.global_position + Vector3(0.0, 0.5, 0.0), 0.016)
	if not visual.visible or collider.disabled:
		await _fail("Divider failed to restore geometry independently of collision", game)
		return

	# The marker is a world landmark only while the authored get-bike phase is active.
	if not bool(mission.get("_bound")):
		await _fail("Opening mission did not bind retained bike state", game)
		return
	var marker: Label3D = bike.get_node_or_null("OpeningCourierBikeMarker") as Label3D
	if marker == null or not marker.visible or not marker.no_depth_test:
		await _fail("Bike lacks readable opening-world objective landmark", game)
		return

	# Programmatic placement tests UI label/selection semantics only. This is
	# NOT proof of player keyboard travel or actual mounted-bike gameplay.
	var touch_ui: Node = game.get("touch_ui") as Node
	var action_button: Button = touch_ui.get("action_button") as Button if touch_ui != null else null
	var hauler: Node3D = game.get("scrap_hauler") as Node3D
	if action_button == null or hauler == null:
		await _fail("Opening action prompt or hauler missing", game)
		return
	for test_case in [
		{"vehicle": bike, "text": "[E] RIDE BIKE"},
		{"vehicle": hauler, "text": "[E] DRIVE HAULER"},
	]:
		var target: Node3D = test_case["vehicle"] as Node3D
		runner.global_position = target.global_position + Vector3(0.0, 0.0, 0.5)
		for item in game.get("_interactables"):
			if is_instance_valid(item):
				item.update_player_distance(runner.global_position)
		game.call("_evaluate_target_selection")
		if action_button.text != String(test_case["text"]):
			await _fail("Wrong available mount prompt near %s: %s" % [target.name, action_button.text], game)
			return

	print("[OPENING_READABILITY_212] PASS — cutaway+collision+objective landmark+vehicle-aware prompts")
	await _finish(0, game)
