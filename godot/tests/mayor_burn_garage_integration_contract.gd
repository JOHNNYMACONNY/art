extends RefCounted

const TOON_SHADER_PATH := "res://materials/gears_toon.gdshader"
const LEGACY_RETURN_ZONE_POSITION := Vector3(7.0, 0.08, 8.0)

const RETAINED_01B_TRANSFORMS := {
	"NorthRoad": Vector3(-4.5, -0.15, -35.0),
	"IndustrialIntersection": Vector3(-3.0, -0.16, -22.5),
	"ServiceAlley": Vector3(-10.0, -0.13, -35.0),
	"NorthConnector": Vector3(-7.25, -0.12, -45.5),
}

static func _count_type(node: Node, type_name: StringName) -> int:
	var count := 0
	if node.get_class() == type_name:
		count = 1
	for child in node.get_children():
		count += _count_type(child, type_name)
	return count

static func _count_local_lights(node: Node) -> int:
	var count := 0
	if node is OmniLight3D or node is SpotLight3D:
		count = 1
	for child in node.get_children():
		count += _count_local_lights(child)
	return count

static func _verify_toon_mesh(root: Node, path: String) -> String:
	var mesh := root.get_node_or_null(path) as MeshInstance3D
	if mesh == null:
		return "Required Mayor Burn garage mesh missing: %s" % path
	var material := mesh.material_override as ShaderMaterial
	if material == null or material.shader == null:
		return "Mayor Burn garage mesh has no shader material: %s" % path
	if material.shader.resource_path != TOON_SHADER_PATH:
		return "Mayor Burn garage mesh is not using the approved toon shader: %s" % path
	return ""

static func verify(scene_root: Node) -> String:
	if scene_root == null:
		return "Playable scene root is missing"

	var district := scene_root.get_node_or_null("GearsDistrictSlice01B")
	if district == null:
		return "01B production slice is missing from the playable scene"

	for node_name in RETAINED_01B_TRANSFORMS:
		var node := district.get_node_or_null(node_name) as Node3D
		if node == null:
			return "Retained 01B node missing: %s" % node_name
		if node.position.distance_to(RETAINED_01B_TRANSFORMS[node_name]) > 0.001:
			return "01C changed retained 01B route transform: %s" % node_name

	var garage := district.get_node_or_null("CommercialFrontage/MayorBurnGarage")
	if garage == null:
		return "MayorBurnGarage is missing from the 01B commercial frontage"
	if garage.get_script() != null:
		return "MayorBurnGarage must remain declarative and own no gameplay script"
	if _count_type(garage, &"MeshInstance3D") <= 0:
		return "MayorBurnGarage has no visible production meshes"
	if _count_type(garage, &"MeshInstance3D") > 8:
		return "MayorBurnGarage exceeds the bounded 8-mesh art budget"
	if _count_type(garage, &"CollisionShape3D") != 0:
		return "MayorBurnGarage must reuse the existing commercial-frontage collision"
	if _count_local_lights(garage) != 0:
		return "MayorBurnGarage must not add a new real-time local-light layer"

	for path in [
		"CommercialFrontage/MayorBurnGarage/GarageDoor",
		"CommercialFrontage/MayorBurnGarage/BurnHeroSign",
		"CommercialFrontage/MayorBurnGarage/CivicPermitPlate",
		"CommercialFrontage/MayorBurnGarage/RepairPatch",
	]:
		var error := _verify_toon_mesh(district, path)
		if error != "":
			return error

	var burn_label := district.get_node_or_null("CommercialFrontage/MayorBurnGarage/BurnGarageLabel") as Label3D
	if burn_label == null or "BURN" not in burn_label.text.to_upper() or "GARAGE" not in burn_label.text.to_upper():
		return "Mayor Burn garage lacks authorized gameplay-distance BURN / GARAGE wording"

	var socket := district.get_node_or_null("MissionDestinationSocket") as Marker3D
	if socket == null or socket.get_script() != null:
		return "01B MissionDestinationSocket is missing or no longer passive"

	var runtime := scene_root.get_node_or_null("CivicRepossessionRuntime")
	if runtime == null:
		return "Civic Repossession runtime is missing from the playable scene"
	var return_zone := scene_root.get_node_or_null("CivicRepossessionReturnZone") as MeshInstance3D
	if return_zone == null:
		return "Civic Repossession runtime did not create its retained return zone"
	if return_zone.global_position.distance_to(socket.global_position) > 0.05:
		return "Civic Repossession return zone is not resolved to the 01B mission destination socket"
	if return_zone.global_position.distance_to(LEGACY_RETURN_ZONE_POSITION) < 20.0:
		return "Production Mission 02 still uses the legacy in-yard Burn garage placeholder"
	if return_zone.visible:
		return "Civic Repossession return zone must remain hidden before DELIVERY"

	return ""
