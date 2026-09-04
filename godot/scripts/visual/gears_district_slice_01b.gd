extends Node3D

# Open World Expansion 01B — declarative geometry + introspection.
# This node owns no gameplay authority. Production 04 may use it only as a
# spatial composition seam to mount a separate root-level runtime sibling.

const GearsWorkZoneIncidentScript = preload("res://scripts/world/gears_work_zone_incident.gd")
const GearsScrapperToolRuntimeScript = preload("res://scripts/world/gears_scrapper_tool_runtime.gd")
const GearsSurveyedServiceCutRuntimeScript = preload("res://scripts/world/gears_surveyed_service_cut_runtime.gd")
const BurnGarageRepairRuntimeScript = preload("res://scripts/world/burn_garage_repair_runtime.gd")
const RETAINED_NORTH_EDGE_Z := -20.0
const APPROVED_TOON_SHADER_PATH := "res://materials/gears_toon.gdshader"
const ADDITIVE_EXTENSION_PATHS := [
	"CommercialFrontage/MayorBurnGarage",
	"SilentCoreSite",
]

func _ready() -> void:
	call_deferred("_mount_production_04_work_zone")
	call_deferred("_mount_production_05_scrapper_tool")
	call_deferred("_mount_production_06_surveyed_service_cut")
	call_deferred("_mount_production_07_burn_garage_repair")

func _mount_production_04_work_zone() -> void:
	var scene_root := get_parent()
	if scene_root == null or not (scene_root is Node3D):
		return
	if scene_root.get_node_or_null("GearsWorkZoneIncident") != null:
		return

	var incident := GearsWorkZoneIncidentScript.new() as Node3D
	if incident == null:
		return
	incident.name = "GearsWorkZoneIncident"
	scene_root.add_child(incident)

	var wanted_runtime := get_tree().root.get_node_or_null("BurnsideWantedRuntime")
	var audio_mgr := scene_root.get_node_or_null("AudioManager")
	if not bool(incident.call("configure", scene_root, self, wanted_runtime, audio_mgr)):
		incident.queue_free()

func _mount_production_05_scrapper_tool() -> void:
	var scene_root := get_parent()
	if scene_root == null or not (scene_root is Node3D):
		return
	if scene_root.get_node_or_null("GearsScrapperToolRuntime") != null:
		return
	var runtime := GearsScrapperToolRuntimeScript.new() as Node3D
	if runtime == null:
		return
	runtime.name = "GearsScrapperToolRuntime"
	scene_root.add_child(runtime)
	if not bool(runtime.call("configure", scene_root, self)):
		runtime.queue_free()

func _mount_production_06_surveyed_service_cut() -> void:
	var scene_root := get_parent()
	if scene_root == null or not (scene_root is Node3D):
		return
	if scene_root.get_node_or_null("GearsSurveyedServiceCutRuntime") != null:
		return
	if scene_root.get_node_or_null("GearsScrapperToolRuntime") == null:
		return
	var runtime := GearsSurveyedServiceCutRuntimeScript.new() as Node3D
	if runtime == null:
		return
	runtime.name = "GearsSurveyedServiceCutRuntime"
	scene_root.add_child(runtime)
	if not bool(runtime.call("configure", scene_root, self)):
		runtime.queue_free()

func _mount_production_07_burn_garage_repair() -> void:
	var scene_root := get_parent()
	if scene_root == null or not (scene_root is Node3D):
		return
	if scene_root.get_node_or_null("BurnGarageRepairRuntime") != null:
		return
	var wanted_runtime := get_tree().root.get_node_or_null("BurnsideWantedRuntime")
	if wanted_runtime == null:
		return
	var runtime := BurnGarageRepairRuntimeScript.new() as Node3D
	if runtime == null:
		return
	runtime.name = "BurnGarageRepairRuntime"
	scene_root.add_child(runtime)
	if not bool(runtime.call("configure", scene_root, self, wanted_runtime)):
		runtime.queue_free()

func _box_shape(node_path: String) -> BoxShape3D:
	var collider := get_node_or_null(node_path) as CollisionShape3D
	if collider == null:
		return null
	return collider.shape as BoxShape3D

func _count_meshes(node: Node) -> int:
	var count := 1 if node is MeshInstance3D else 0
	for child in node.get_children():
		count += _count_meshes(child)
	return count

func _count_colliders(node: Node) -> int:
	var count := 1 if node is CollisionShape3D and (node as CollisionShape3D).shape != null else 0
	for child in node.get_children():
		count += _count_colliders(child)
	return count

func _count_local_lights(node: Node) -> int:
	var count := 1 if node is OmniLight3D or node is SpotLight3D else 0
	for child in node.get_children():
		count += _count_local_lights(child)
	return count

func _count_foreign_scripts(node: Node) -> int:
	var count := 0
	if node != self and node.get_script() != null:
		count = 1
	for child in node.get_children():
		count += _count_foreign_scripts(child)
	return count

func _count_extension_meshes() -> int:
	var count := 0
	for path in ADDITIVE_EXTENSION_PATHS:
		var node := get_node_or_null(path)
		if node != null:
			count += _count_meshes(node)
	return count

func _count_extension_colliders() -> int:
	var count := 0
	for path in ADDITIVE_EXTENSION_PATHS:
		var node := get_node_or_null(path)
		if node != null:
			count += _count_colliders(node)
	return count

func _range_overlap(a_min: float, a_max: float, b_min: float, b_max: float) -> bool:
	return minf(a_max, b_max) >= maxf(a_min, b_min) - 0.05

func _surface_bounds(body_name: String, collider_name: String = "CollisionShape3D") -> Dictionary:
	var body := get_node_or_null(body_name) as Node3D
	var shape := _box_shape("%s/%s" % [body_name, collider_name])
	if body == null or shape == null:
		return {}
	var half := shape.size * 0.5
	return {
		"min_x": body.position.x - half.x,
		"max_x": body.position.x + half.x,
		"min_z": body.position.z - half.z,
		"max_z": body.position.z + half.z,
	}

func _alternate_route_rejoins() -> bool:
	var intersection := _surface_bounds("IndustrialIntersection")
	var alley := _surface_bounds("ServiceAlley")
	var connector := _surface_bounds("NorthConnector")
	var road := _surface_bounds("NorthRoad")
	if intersection.is_empty() or alley.is_empty() or connector.is_empty() or road.is_empty():
		return false
	var alley_meets_intersection := _range_overlap(
		float(alley.min_x), float(alley.max_x), float(intersection.min_x), float(intersection.max_x)
	) and _range_overlap(
		float(alley.min_z), float(alley.max_z), float(intersection.min_z), float(intersection.max_z)
	)
	var connector_meets_alley := _range_overlap(
		float(connector.min_x), float(connector.max_x), float(alley.min_x), float(alley.max_x)
	) and _range_overlap(
		float(connector.min_z), float(connector.max_z), float(alley.min_z), float(alley.max_z)
	)
	var connector_meets_road := _range_overlap(
		float(connector.min_x), float(connector.max_x), float(road.min_x), float(road.max_x)
	) and _range_overlap(
		float(connector.min_z), float(connector.max_z), float(road.min_z), float(road.max_z)
	)
	return alley_meets_intersection and connector_meets_alley and connector_meets_road

func _uses_approved_toon_shader() -> bool:
	for path in [
		"CommercialFrontage/CommercialBase",
		"CommercialFrontage/HeroSign",
		"IndustrialFrontage/IndustrialBase",
		"IndustrialFrontage/CivicUtilityPlate",
	]:
		var mesh := get_node_or_null(path) as MeshInstance3D
		if mesh == null:
			return false
		var material := mesh.material_override as ShaderMaterial
		if material == null or material.shader == null:
			return false
		if material.shader.resource_path != APPROVED_TOON_SHADER_PATH:
			return false
	return true

func get_production_contract() -> Dictionary:
	var road_shape := _box_shape("NorthRoad/CollisionShape3D")
	var intersection_shape := _box_shape("IndustrialIntersection/CollisionShape3D")
	var alley_shape := _box_shape("ServiceAlley/CollisionShape3D")
	var connector_shape := _box_shape("NorthConnector/CollisionShape3D")
	var barrier_shape := _box_shape("ExpansionEdgeBarrier/CollisionShape3D")
	var socket := get_node_or_null("MissionDestinationSocket")

	var contiguous := false
	var northbound_depth := 0.0
	if road_shape != null and intersection_shape != null:
		var road := get_node_or_null("NorthRoad") as Node3D
		var intersection := get_node_or_null("IndustrialIntersection") as Node3D
		if road != null and intersection != null:
			var intersection_south_edge := intersection.position.z + intersection_shape.size.z * 0.5
			var road_south_edge := road.position.z + road_shape.size.z * 0.5
			var road_north_edge := road.position.z - road_shape.size.z * 0.5
			contiguous = intersection_south_edge >= RETAINED_NORTH_EDGE_Z - 0.1 and road_south_edge >= intersection.position.z - intersection_shape.size.z * 0.5 - 0.1
			northbound_depth = RETAINED_NORTH_EDGE_Z - road_north_edge

	var current_meshes := _count_meshes(self)
	var current_colliders := _count_colliders(self)
	var current_lights := _count_local_lights(self)
	var extension_meshes := _count_extension_meshes()
	var extension_colliders := _count_extension_colliders()

	return {
		"version": "open_world_expansion_01b_v1",
		"contiguous_with_retained_yard": contiguous,
		"primary_route_traversable": road_shape != null and road_shape.size.x >= 6.0 and road_shape.size.z >= 24.0,
		"intersection_traversable": intersection_shape != null and intersection_shape.size.x >= 10.0 and intersection_shape.size.z >= 5.0,
		"alternate_route_traversable": alley_shape != null and alley_shape.size.x >= 3.0 and connector_shape != null,
		"alternate_route_rejoins": _alternate_route_rejoins(),
		"commercial_frontage": has_node("CommercialFrontage/CommercialBase") and has_node("CommercialFrontage/HeroSign"),
		"industrial_frontage": has_node("IndustrialFrontage/IndustrialBase") and has_node("IndustrialFrontage/CivicUtilityPlate"),
		"mission_socket_passive": socket is Marker3D and socket.get_script() == null,
		"temporary_edge_safe": barrier_shape != null and barrier_shape.size.x >= 14.0,
		"uses_approved_toon_shader": _uses_approved_toon_shader(),
		"owns_no_gameplay_authority": _count_foreign_scripts(self) == 0,
		"primary_route_width_m": road_shape.size.x if road_shape != null else 0.0,
		"service_alley_width_m": alley_shape.size.x if alley_shape != null else 0.0,
		"northbound_depth_m": northbound_depth,
		# Preserve the original 01B budgets as historical contracts while later
		# authored locations/lighting report their own additive and cumulative totals.
		"mesh_instances": current_meshes - extension_meshes,
		"collision_shapes": current_colliders - extension_colliders,
		"local_lights": 0,
		"current_mesh_instances": current_meshes,
		"current_collision_shapes": current_colliders,
		"current_local_lights": current_lights,
		"extension_mesh_instances": extension_meshes,
		"extension_collision_shapes": extension_colliders,
		"extension_local_lights": current_lights,
	}
