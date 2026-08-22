extends SceneTree

# Issue #13 world-authoring contract: only intentionally selected prop families
# participate in camera cutaway, via detection-only Area3D proxies.

const OCCLUSION_LAYER: int = 1 << 30
const SELECTED_SCENES: Array[String] = [
	"res://scenes/props/salvage_container.tscn",
	"res://scenes/props/corrugated_fence.tscn",
	"res://scenes/props/pipe_rack_modular.tscn",
]
const NON_SELECTED_SCENE: String = "res://scenes/props/scrap_pile_a.tscn"

var _instances: Array[Node] = []

func _init() -> void:
	call_deferred("_run")

func _finish(exit_code: int) -> void:
	for instance in _instances:
		if is_instance_valid(instance):
			instance.queue_free()
	await process_frame
	await process_frame
	quit(exit_code)

func _fail(message: String) -> void:
	push_error("[CAMERA_OCCLUDER_AUTHORING_13] %s" % message)
	await _finish(1)

func _instantiate(path: String) -> Node:
	var packed: PackedScene = load(path) as PackedScene
	if packed == null:
		return null
	var instance: Node = packed.instantiate()
	root.add_child(instance)
	_instances.append(instance)
	return instance

func _count_geometry(node: Node) -> int:
	var count: int = 1 if node is GeometryInstance3D else 0
	for child in node.get_children():
		count += _count_geometry(child)
	return count

func _run() -> void:
	for path in SELECTED_SCENES:
		var instance: Node = _instantiate(path)
		if instance == null:
			await _fail("Could not instantiate selected prop: %s" % path)
			return
		if not instance.is_in_group("camera_occluder"):
			await _fail("Selected prop is not explicitly tagged camera_occluder: %s" % path)
			return
		if _count_geometry(instance) <= 0:
			await _fail("Selected prop has no visual geometry: %s" % path)
			return

		var proxy := instance.get_node_or_null("CameraOcclusionProxy") as Area3D
		if proxy == null:
			await _fail("Selected prop has no CameraOcclusionProxy: %s" % path)
			return
		if proxy.collision_layer != OCCLUSION_LAYER:
			await _fail("Selected prop proxy is not on dedicated occlusion layer: %s" % path)
			return
		if proxy.collision_mask != 0:
			await _fail("Selected prop proxy unexpectedly queries gameplay collision: %s" % path)
			return
		if proxy.monitoring:
			await _fail("Selected prop proxy should not monitor overlaps: %s" % path)
			return

		var shape_node := proxy.get_node_or_null("CollisionShape3D") as CollisionShape3D
		if shape_node == null or shape_node.shape == null:
			await _fail("Selected prop proxy has no valid collision shape: %s" % path)
			return
		if shape_node.disabled:
			await _fail("Selected prop proxy collision shape is disabled: %s" % path)
			return

	var non_selected: Node = _instantiate(NON_SELECTED_SCENE)
	if non_selected == null:
		await _fail("Could not instantiate non-selected control prop")
		return
	if non_selected.is_in_group("camera_occluder"):
		await _fail("Non-selected scrap pile was globally opted into camera occlusion")
		return
	if non_selected.get_node_or_null("CameraOcclusionProxy") != null:
		await _fail("Non-selected scrap pile unexpectedly has an occlusion proxy")
		return

	print("[CAMERA_OCCLUDER_AUTHORING_13] PASS")
	await _finish(0)
