extends SceneTree

# Issue #13 deterministic rendered evidence. Uses the retained camera implementation
# plus the real authored salvage-container occluder at the project's 960x540 viewport.

const CameraScript = preload("res://scripts/camera/camera_3d.gd")
const OUTPUT_DIR: String = "res://verification/feel/camera_occlusion_13_runtime"
const SAMPLE_COUNT: int = 400

var _fixture: Node3D = null
var _camera: Camera3D = null
var _target: Node3D = null
var _container: Node3D = null

func _init() -> void:
	call_deferred("_run")

func _finish(exit_code: int) -> void:
	if is_instance_valid(_fixture):
		_fixture.queue_free()
	await process_frame
	await process_frame
	quit(exit_code)

func _fail(message: String) -> void:
	push_error("[CAMERA_OCCLUSION_RENDER_13] %s" % message)
	await _finish(1)

func _make_material(color: Color, emission_strength: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.75
	if emission_strength > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_strength
	return material

func _capture(filename: String) -> bool:
	await RenderingServer.frame_post_draw
	var image: Image = root.get_texture().get_image()
	if image == null or image.is_empty():
		return false
	var absolute_path: String = ProjectSettings.globalize_path("%s/%s" % [OUTPUT_DIR, filename])
	return image.save_png(absolute_path) == OK

func _bench_process(iterations: int) -> float:
	var started: int = Time.get_ticks_usec()
	for _i in range(iterations):
		_camera.call("_process", 0.016)
	var elapsed: int = Time.get_ticks_usec() - started
	return float(elapsed) / float(iterations)

func _run() -> void:
	var output_absolute: String = ProjectSettings.globalize_path(OUTPUT_DIR)
	var mkdir_error: Error = DirAccess.make_dir_recursive_absolute(output_absolute)
	if mkdir_error != OK and mkdir_error != ERR_ALREADY_EXISTS:
		await _fail("Could not create evidence directory: %s" % mkdir_error)
		return

	_fixture = Node3D.new()
	_fixture.name = "CameraOcclusionRenderFixture"
	root.add_child(_fixture)

	var world_environment := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.045, 0.055, 0.075, 1.0)
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_color = Color(0.42, 0.48, 0.58, 1.0)
	environment.ambient_light_energy = 1.0
	world_environment.environment = environment
	_fixture.add_child(world_environment)

	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55.0, -35.0, 0.0)
	light.light_color = Color(1.0, 0.90, 0.78, 1.0)
	light.light_energy = 1.4
	light.shadow_enabled = true
	_fixture.add_child(light)

	var floor := MeshInstance3D.new()
	var floor_mesh := PlaneMesh.new()
	floor_mesh.size = Vector2(28.0, 28.0)
	floor.mesh = floor_mesh
	floor.material_override = _make_material(Color(0.13, 0.12, 0.11, 1.0))
	_fixture.add_child(floor)

	_target = Node3D.new()
	_target.name = "ReadabilityTarget"
	_fixture.add_child(_target)
	var target_visual := MeshInstance3D.new()
	var target_mesh := CapsuleMesh.new()
	target_mesh.radius = 0.55
	target_mesh.height = 2.0
	target_visual.mesh = target_mesh
	target_visual.position = Vector3(0.0, 1.0, 0.0)
	target_visual.material_override = _make_material(Color(0.95, 0.24, 0.62, 1.0), 0.35)
	_target.add_child(target_visual)

	_camera = CameraScript.new()
	_camera.name = "EvidenceCamera"
	_camera.current = true
	_fixture.add_child(_camera)
	_camera.call("reset_camera_instant", _target)

	var packed_container: PackedScene = load("res://scenes/props/salvage_container.tscn") as PackedScene
	if packed_container == null:
		await _fail("Could not load authored salvage container")
		return
	_container = packed_container.instantiate() as Node3D
	if _container == null:
		await _fail("Could not instantiate authored salvage container")
		return
	_fixture.add_child(_container)

	await process_frame
	await physics_frame
	await physics_frame

	# Clear baseline.
	_camera.set("occlusion_enabled", false)
	_container.position = Vector3(8.0, 0.0, 0.0)
	_camera.call("_process", 0.016)
	await process_frame
	if not await _capture("01_clear_baseline.png"):
		await _fail("Could not capture clear baseline")
		return

	# Place the real container where its authored proxy intersects the retained
	# camera-to-target readability ray, but keep cutaway disabled for baseline.
	var focus_point: Vector3 = _target.global_position + Vector3(0.0, 0.5, 0.0)
	var ray_point: Vector3 = _camera.global_position.lerp(focus_point, 0.90)
	_container.position = Vector3(ray_point.x, 0.0, ray_point.z)
	await physics_frame
	await physics_frame
	_camera.call("_process", 0.016)
	await process_frame
	if not await _capture("02_occluded_without_cutaway.png"):
		await _fail("Could not capture occluded baseline")
		return

	# Candidate cutaway: same camera, target, prop and collider; visual state only changes.
	_camera.set("occlusion_enabled", true)
	var detection_started: int = Time.get_ticks_usec()
	_camera.call("_process", 0.016)
	var detection_usec: int = Time.get_ticks_usec() - detection_started
	if int(_camera.call("get_active_occluder_count")) != 1:
		await _fail("Real authored container was not detected as one active occluder")
		return
	await process_frame
	if not await _capture("03_cutaway_enabled.png"):
		await _fail("Could not capture active cutaway")
		return

	# Same-route CPU comparison. This reports script/query cost, not GPU frame time.
	_camera.set("occlusion_enabled", false)
	var disabled_usec: float = _bench_process(SAMPLE_COUNT)
	_camera.set("occlusion_enabled", true)
	_container.position = Vector3(8.0, 0.0, 0.0)
	await physics_frame
	await physics_frame
	var enabled_clear_usec: float = _bench_process(SAMPLE_COUNT)
	_container.position = Vector3(ray_point.x, 0.0, ray_point.z)
	await physics_frame
	await physics_frame
	var enabled_blocked_usec: float = _bench_process(SAMPLE_COUNT)

	# Clear and prove the configured gentler restore delay before final screenshot.
	_container.position = Vector3(8.0, 0.0, 0.0)
	await physics_frame
	await physics_frame
	var restore_elapsed: float = 0.0
	while int(_camera.call("get_active_occluder_count")) > 0 and restore_elapsed < 1.0:
		_camera.call("_process", 0.05)
		restore_elapsed += 0.05
	if int(_camera.call("get_active_occluder_count")) != 0:
		await _fail("Authored container did not restore after ray cleared")
		return
	await process_frame
	if not await _capture("04_restored_after_clear.png"):
		await _fail("Could not capture restored state")
		return

	var metrics := {
		"source_contract": "camera_occlusion_13",
		"viewport": [root.size.x, root.size.y],
		"detection_budget_frames": 1,
		"detection_cpu_usec_single": detection_usec,
		"restore_elapsed_sec": restore_elapsed,
		"configured_restore_delay_sec": float(_camera.get("occluder_restore_delay")),
		"max_occluders": int(_camera.get("max_occluders")),
		"sample_count": SAMPLE_COUNT,
		"camera_process_cpu_usec_avg_disabled": disabled_usec,
		"camera_process_cpu_usec_avg_enabled_clear": enabled_clear_usec,
		"camera_process_cpu_usec_avg_enabled_one_blocker": enabled_blocked_usec,
		"performance_scope": "CPU script/query timing in deterministic CI fixture; not target-mobile GPU proof",
	}
	var metrics_file := FileAccess.open("%s/metrics.json" % OUTPUT_DIR, FileAccess.WRITE)
	if metrics_file == null:
		await _fail("Could not open metrics evidence file")
		return
	metrics_file.store_string(JSON.stringify(metrics, "  "))
	metrics_file.close()

	print("[CAMERA_OCCLUSION_RENDER_13] metrics=%s" % metrics)
	print("[CAMERA_OCCLUSION_RENDER_13] PASS")
	await _finish(0)
