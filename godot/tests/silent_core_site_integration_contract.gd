extends RefCounted

const TOON_SHADER_PATH := "res://materials/gears_toon.gdshader"
const LEGACY_SILENT_CORE_POSITION := Vector3(8.0, 0.4, -8.0)
const EXPECTED_SITE_POSITION := Vector3(6.2, 0.0, -27.4)
const PROOF_RELAY_MAX_X := 4.65
const PROOF_RELAY_MAX_Z := -26.5
const INDUSTRIAL_SOUTH_EDGE_Z := -30.0

static func _count_meshes(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _count_meshes(child)
	return count

static func _count_colliders(node: Node) -> int:
	var count := 1 if node is CollisionShape3D else 0
	for child in node.get_children():
		count += _count_colliders(child)
	return count

static func _count_local_lights(node: Node) -> int:
	var count := 1 if node is OmniLight3D or node is SpotLight3D else 0
	for child in node.get_children():
		count += _count_local_lights(child)
	return count

static func _verify_toon_mesh(root: Node, path: String) -> String:
	var mesh := root.get_node_or_null(path) as MeshInstance3D
	if mesh == null:
		return "Required Silent Core mesh missing: %s" % path
	var material := mesh.material_override as ShaderMaterial
	if material == null or material.shader == null:
		return "Silent Core mesh has no shader material: %s" % path
	if material.shader.resource_path != TOON_SHADER_PATH:
		return "Silent Core mesh is not using the approved toon shader: %s" % path
	return ""

static func _box_bounds(body: Node3D, collider: CollisionShape3D) -> Dictionary:
	var shape := collider.shape as BoxShape3D
	if shape == null:
		return {}
	var half := shape.size * 0.5
	return {
		"min_x": body.global_position.x - half.x,
		"max_x": body.global_position.x + half.x,
		"min_z": body.global_position.z - half.z,
		"max_z": body.global_position.z + half.z,
	}

static func _overlaps_xz(a: Dictionary, b: Dictionary) -> bool:
	if a.is_empty() or b.is_empty():
		return false
	return minf(float(a.max_x), float(b.max_x)) >= maxf(float(a.min_x), float(b.min_x)) - 0.05 \
	and minf(float(a.max_z), float(b.max_z)) >= maxf(float(a.min_z), float(b.min_z)) - 0.05

static func verify(scene_root: Node) -> String:
	if scene_root == null:
		return "Playable scene root is missing"

	var district := scene_root.get_node_or_null("GearsDistrictSlice01B")
	if district == null:
		return "01B production slice is missing"

	var site := district.get_node_or_null("SilentCoreSite") as Node3D
	if site == null:
		return "SilentCoreSite is missing from the production district"
	if site.position.distance_to(EXPECTED_SITE_POSITION) > 0.001:
		return "SilentCoreSite moved outside its bounded authored pocket"
	if site.get_script() != null:
		return "SilentCoreSite must remain declarative"
	if _count_meshes(site) <= 0 or _count_meshes(site) > 6:
		return "SilentCoreSite violates its bounded 1..6 mesh budget"
	if _count_colliders(site) != 2:
		return "SilentCoreSite must add exactly two bounded maintenance-apron colliders"
	if _count_local_lights(site) != 0:
		return "SilentCoreSite must not add real-time local lights"

	var intersection := district.get_node_or_null("IndustrialIntersection") as Node3D
	var intersection_collider := district.get_node_or_null("IndustrialIntersection/CollisionShape3D") as CollisionShape3D
	var walkway := site.get_node_or_null("AccessWalkway") as Node3D
	var walkway_collider := site.get_node_or_null("AccessWalkway/CollisionShape3D") as CollisionShape3D
	var pad := site.get_node_or_null("SitePadBody") as Node3D
	var pad_collider := site.get_node_or_null("SitePadBody/CollisionShape3D") as CollisionShape3D
	if intersection == null or intersection_collider == null or walkway == null or walkway_collider == null or pad == null or pad_collider == null:
		return "Silent Core maintenance-apron collision fixtures are incomplete"

	var intersection_bounds := _box_bounds(intersection, intersection_collider)
	var walkway_bounds := _box_bounds(walkway, walkway_collider)
	var pad_bounds := _box_bounds(pad, pad_collider)
	if not _overlaps_xz(intersection_bounds, walkway_bounds):
		return "Silent Core AccessWalkway does not overlap retained intersection ground"
	if not _overlaps_xz(walkway_bounds, pad_bounds):
		return "Silent Core SitePadBody does not overlap AccessWalkway"
	if float(pad_bounds.min_x) <= PROOF_RELAY_MAX_X:
		return "Silent Core site pad overlaps the proof-only relay envelope"
	if float(walkway_bounds.min_z) <= PROOF_RELAY_MAX_Z:
		return "Silent Core access walkway intrudes into the proof-only relay envelope"
	if float(pad_bounds.min_z) <= INDUSTRIAL_SOUTH_EDGE_Z:
		return "Silent Core site pad intrudes into the industrial frontage collision envelope"

	var socket := site.get_node_or_null("SilentCoreSocket") as Marker3D
	if socket == null or socket.get_script() != null:
		return "SilentCoreSocket is missing or owns behavior"
	if not _overlaps_xz(pad_bounds, {
		"min_x": socket.global_position.x,
		"max_x": socket.global_position.x,
		"min_z": socket.global_position.z,
		"max_z": socket.global_position.z,
	}):
		return "SilentCoreSocket is not located on the traversable site pad"

	for path in [
		"SilentCoreSite/AccessWalkway/WalkwayMesh",
		"SilentCoreSite/SitePadBody/SitePadMesh",
		"SilentCoreSite/RelayCabinet",
		"SilentCoreSite/RemovedAssetPlateScar",
		"SilentCoreSite/MemorySignalAperture",
	]:
		var site_error := _verify_toon_mesh(district, path)
		if site_error != "":
			return site_error

	var runtime := scene_root.get_node_or_null("CityThatForgotRuntime")
	if runtime == null:
		return "Mission 03 runtime is missing"
	var silent_core := scene_root.get_node_or_null("SilentCore")
	if silent_core == null:
		return "Mission 03 runtime did not create exactly one Silent Core"
	if scene_root.find_children("SilentCore", "", true, false).size() != 1:
		return "Production scene contains duplicate Silent Core nodes"
	if silent_core.global_position.distance_to(socket.global_position) > 0.05:
		return "Mission 03 Silent Core is not resolved to the production socket"
	if silent_core.global_position.distance_to(LEGACY_SILENT_CORE_POSITION) < 15.0:
		return "Mission 03 still resolves too close to the legacy in-yard placeholder"
	if silent_core.get_meta("destination_source", "") != "GearsDistrictSlice01B/SilentCoreSite/SilentCoreSocket":
		return "Mission 03 Silent Core does not record production-socket provenance"
	if bool(silent_core.get("is_powered")):
		return "Silent Core is powered before Mission 03 unlock"
	if _count_meshes(silent_core) <= 0 or _count_meshes(silent_core) > 5:
		return "Silent Core runtime marker violates its bounded 1..5 mesh budget"

	for path in [
		"SilentCore/SilentCoreHousing",
		"SilentCore/SilentCoreStructuralCore",
		"SilentCore/SilentCoreSignalSlot",
		"SilentCore/SilentCoreRemovedPlateScar",
	]:
		var marker_error := _verify_toon_mesh(scene_root, path)
		if marker_error != "":
			return marker_error

	return ""
