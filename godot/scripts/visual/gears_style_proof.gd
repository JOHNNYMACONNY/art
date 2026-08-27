extends Node3D

# Issue #60 controller only. Visual composition lives declaratively in
# gears_style_proof.tscn so proof geometry stays inspectable and reversible.

const TREATED_ACTORS := [
	"Runner",
	"CourierBike",
	"ScrapHauler",
	"PursuerPrototype",
	"ScrapWorker1",
	"UtilityCrawler",
]

const SOOT := Color(0.094, 0.129, 0.149, 1.0)
const OFF_WHITE := Color(0.843, 0.824, 0.765, 1.0)
const OXIDIZED := Color(0.541, 0.310, 0.216, 1.0)
const AMBER := Color(0.827, 0.604, 0.173, 1.0)
const TEAL := Color(0.184, 0.467, 0.471, 1.0)
const VERMILION := Color(0.824, 0.294, 0.227, 1.0)
const SIGNAL_CYAN := Color(0.486, 0.812, 0.816, 1.0)
const DUSTY_GREEN := Color(0.400, 0.439, 0.357, 1.0)
const OUTLINE_COLOR := Color(0.025, 0.031, 0.035, 1.0)

var _toon_shader: Shader = null
var _outline_shader: Shader = null
var _outline_material: ShaderMaterial = null
var _runtime_generated_mesh_count := 0
var _actor_outline_count := 0

func _ready() -> void:
	call_deferred("_apply_actor_treatments")

func _material(color: Color, emission_energy: float = 0.0) -> ShaderMaterial:
	if _toon_shader == null:
		_toon_shader = load("res://materials/gears_toon.gdshader") as Shader
	var material := ShaderMaterial.new()
	material.shader = _toon_shader
	material.set_shader_parameter("base_color", color)
	material.set_shader_parameter("roughness_value", 0.82)
	if emission_energy > 0.0:
		material.set_shader_parameter("emission_color", color)
		material.set_shader_parameter("emission_energy", emission_energy)
	return material

func _get_outline_material() -> ShaderMaterial:
	if _outline_material != null:
		return _outline_material
	if _outline_shader == null:
		_outline_shader = load("res://materials/gears_outline.gdshader") as Shader
	_outline_material = ShaderMaterial.new()
	_outline_material.shader = _outline_shader
	_outline_material.set_shader_parameter("outline_color", OUTLINE_COLOR)
	_outline_material.set_shader_parameter("outline_width", 0.035)
	return _outline_material

func _style(actor: Node, node_path: String, color: Color, emission_energy: float = 0.0) -> void:
	var mesh := actor.get_node_or_null(node_path) as MeshInstance3D
	if mesh != null:
		mesh.material_override = _material(color, emission_energy)

func _style_existing_outline(actor: Node, node_path: String) -> void:
	var mesh := actor.get_node_or_null(node_path) as MeshInstance3D
	if mesh == null:
		return
	if not mesh.has_meta("gears_style_proof_outline"):
		_actor_outline_count += 1
		mesh.set_meta("gears_style_proof_outline", true)
	mesh.material_override = _get_outline_material()

func _clone_outline(actor: Node, source_path: String, contour_name: String) -> void:
	var source := actor.get_node_or_null(source_path) as MeshInstance3D
	if source == null or source.mesh == null:
		return
	var parent := source.get_parent()
	if parent == null:
		return
	var existing := parent.get_node_or_null(contour_name) as MeshInstance3D
	if existing != null:
		existing.material_override = _get_outline_material()
		if not existing.has_meta("gears_style_proof_outline"):
			_actor_outline_count += 1
			existing.set_meta("gears_style_proof_outline", true)
		return
	var contour := MeshInstance3D.new()
	contour.name = contour_name
	contour.mesh = source.mesh
	contour.transform = source.transform
	contour.material_override = _get_outline_material()
	contour.set_meta("gears_style_proof_outline", true)
	parent.add_child(contour)
	_runtime_generated_mesh_count += 1
	_actor_outline_count += 1

func _add_overlay_box(parent: Node, node_name: String, size: Vector3, position: Vector3, color: Color) -> void:
	var existing := parent.get_node_or_null(node_name) as MeshInstance3D
	if existing != null:
		return
	var box := BoxMesh.new()
	box.size = size
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	mesh.mesh = box
	mesh.position = position
	mesh.material_override = _material(color)
	parent.add_child(mesh)
	_runtime_generated_mesh_count += 1

func _add_overlay_label(parent: Node, node_name: String, text_value: String, position: Vector3, color: Color) -> void:
	if parent.get_node_or_null(node_name) != null:
		return
	var label := Label3D.new()
	label.name = node_name
	label.text = text_value
	label.position = position
	label.modulate = color
	label.outline_modulate = OUTLINE_COLOR
	label.font_size = 22
	label.outline_size = 8
	label.pixel_size = 0.0035
	parent.add_child(label)

func _apply_actor_treatments() -> void:
	var scene_root := get_parent()
	if scene_root == null:
		return

	var runner := scene_root.get_node_or_null("Runner")
	if runner != null:
		_style(runner, "MeshPivot/Torso/TorsoMesh", TEAL)
		_style(runner, "MeshPivot/Torso/Satchel", OXIDIZED)
		_style(runner, "MeshPivot/Head/HeadMesh", SOOT)
		_style(runner, "MeshPivot/Torso/ChestRig", SIGNAL_CYAN, 0.42)
		_style(runner, "MeshPivot/Head/Visor", SIGNAL_CYAN, 0.72)
		_style_existing_outline(runner, "MeshPivot/Torso/TorsoOutline")

	var bike := scene_root.get_node_or_null("CourierBike")
	if bike != null:
		_style(bike, "VisualRoot/MainChassis", SOOT)
		_style(bike, "VisualRoot/FrontTank/TankMesh", OFF_WHITE)
		_style(bike, "VisualRoot/CargoRack", OXIDIZED)
		_style(bike, "VisualRoot/BatteryCell", SIGNAL_CYAN, 0.62)
		_style_existing_outline(bike, "VisualRoot/FrontTank/TankOutline")
		var bike_root := bike.get_node_or_null("VisualRoot")
		if bike_root != null:
			_add_overlay_box(bike_root, "GearsAmberCourierPanel", Vector3(0.46, 0.12, 0.58), Vector3(0.0, 0.52, 0.46), AMBER)

	var hauler := scene_root.get_node_or_null("ScrapHauler")
	if hauler != null:
		_style(hauler, "VisualRoot/MainChassis", SOOT)
		_style(hauler, "VisualRoot/Cabin/CabinMesh", DUSTY_GREEN)
		_style(hauler, "VisualRoot/Hood/HoodMesh", OFF_WHITE)
		_style(hauler, "VisualRoot/CargoBed", DUSTY_GREEN)
		_style_existing_outline(hauler, "VisualRoot/Cabin/CabinOutline")
		_style_existing_outline(hauler, "VisualRoot/Hood/HoodOutline")

	var pursuer := scene_root.get_node_or_null("PursuerPrototype")
	if pursuer != null:
		_style(pursuer, "VisualRoot/BodyMesh", OFF_WHITE)
		_style(pursuer, "VisualRoot/SirenMesh", VERMILION, 1.10)
		_clone_outline(pursuer, "VisualRoot/BodyMesh", "GearsPursuitBodyContour")
		var pursuit_root := pursuer.get_node_or_null("VisualRoot")
		if pursuit_root != null:
			_add_overlay_box(pursuit_root, "GearsPursuitRoofID", Vector3(0.82, 0.16, 0.92), Vector3(0.0, 1.25, 0.0), SOOT)
			_add_overlay_box(pursuit_root, "GearsPursuitFrontBand", Vector3(1.18, 0.24, 0.18), Vector3(0.0, 0.72, -1.10), VERMILION)
			# Proof-only generic asset copy; not a narrative/canon department or vehicle name.
			_add_overlay_label(pursuit_root, "PursuitAssetLabel", "UNIT 12", Vector3(0.0, 1.36, 0.0), OFF_WHITE)

	var worker := scene_root.get_node_or_null("ScrapWorker1")
	if worker != null:
		_style(worker, "MeshPivot/Torso", DUSTY_GREEN)
		_style(worker, "MeshPivot/Helmet", AMBER)
		_style(worker, "MeshPivot/Helmet/Visor", SOOT)
		_clone_outline(worker, "MeshPivot/Torso", "GearsWorkerTorsoContour")

	var crawler := scene_root.get_node_or_null("UtilityCrawler")
	if crawler != null:
		_style(crawler, "Chassis/Body", OFF_WHITE)
		_style(crawler, "Chassis/LeftTread", SOOT)
		_style(crawler, "Chassis/RightTread", SOOT)
		_style(crawler, "Chassis/CargoBed", TEAL)
		_style(crawler, "Chassis/BeaconMesh", AMBER, 0.65)
		_clone_outline(crawler, "Chassis/Body", "GearsCrawlerBodyContour")
		var crawler_root := crawler.get_node_or_null("Chassis")
		if crawler_root != null:
			_add_overlay_box(crawler_root, "GearsReplacementPanel", Vector3(0.36, 0.16, 0.08), Vector3(0.22, 0.30, -0.61), OXIDIZED)
			# Proof-only generic asset ID; not narrative canon.
			_add_overlay_label(crawler_root, "CrawlerAssetID", "UTL-08", Vector3(0.0, 0.28, -0.66), SOOT)

	var panel := scene_root.get_node_or_null("CorrodedPanel")
	if panel != null:
		_style(panel, "PanelMesh", OXIDIZED)
		_style(panel, "CoreMesh", AMBER, 0.72)
		_clone_outline(panel, "PanelMesh", "GearsInteractablePanelContour")
		panel.set_meta("gears_style_proof_treatment", true)

	for actor_name in TREATED_ACTORS:
		var actor := scene_root.get_node_or_null(actor_name)
		if actor != null:
			actor.set_meta("gears_style_proof_treatment", true)

func _resolve_practical_light(node_name: String) -> OmniLight3D:
	var scene_root := get_parent()
	if scene_root != null:
		var production_light := scene_root.get_node_or_null(
			"GearsDistrictSlice01B/PracticalLights/%s" % node_name
		) as OmniLight3D
		if production_light != null:
			return production_light
	return get_node_or_null("PracticalLights/%s" % node_name) as OmniLight3D

func _set_practical_energy(node_name: String, energy: float) -> void:
	var active_light := _resolve_practical_light(node_name)
	if active_light != null:
		active_light.light_energy = energy
	# Keep the hidden Issue #60 reference light in sync so standalone/reference
	# contracts remain deterministic. Its hidden parent means this does not add a
	# second rendered light in production.
	var reference_light := get_node_or_null("PracticalLights/%s" % node_name) as OmniLight3D
	if reference_light != null and reference_light != active_light:
		reference_light.light_energy = energy

func set_lighting_mode(mode: String) -> void:
	var scene_root := get_parent()
	if scene_root == null:
		return
	var sun := scene_root.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	var dusk := mode.to_lower() == "dusk"
	if sun == null:
		return
	if dusk:
		sun.light_energy = 0.58
		sun.light_color = Color(0.945, 0.718, 0.478, 1.0)
		_set_practical_energy("StoreWorkLamp", 1.55)
		_set_practical_energy("GantryServiceLamp", 1.24)
		_set_practical_energy("RelayMarkerLamp", 0.54)
	else:
		sun.light_energy = 1.25
		sun.light_color = Color(0.961, 0.898, 0.788, 1.0)
		_set_practical_energy("StoreWorkLamp", 1.0)
		_set_practical_energy("GantryServiceLamp", 0.8)
		_set_practical_energy("RelayMarkerLamp", 0.35)

func _node_is_treated(node_name: String) -> bool:
	var scene_root := get_parent()
	if scene_root == null:
		return false
	var node := scene_root.get_node_or_null(node_name)
	return node != null and node.has_meta("gears_style_proof_treatment")

func _count_meshes(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D:
		count = 1
	for child in node.get_children():
		count += _count_meshes(child)
	return count

func _count_outlines(node: Node) -> int:
	var count := 0
	if node is MeshInstance3D and node.name.ends_with("Contour"):
		count = 1
	for child in node.get_children():
		count += _count_outlines(child)
	return count

func _scene_has_node(path: String) -> bool:
	var scene_root := get_parent()
	return scene_root != null and scene_root.get_node_or_null(path) != null

func get_proof_contract() -> Dictionary:
	var scene_root := get_parent()
	var retained_camera := false
	if scene_root != null:
		var camera := scene_root.get_node_or_null("ChinatownCamera3D") as Camera3D
		if camera != null:
			retained_camera = absf(camera.fov - 32.0) <= 0.05
	var practicals := get_node_or_null("PracticalLights")
	var practical_count := 0
	if practicals != null:
		practical_count = practicals.get_child_count()
	return {
		"version": "issue60_gears_style_proof_v1",
		"stacked_mixed_use": has_node("MixedUseBlock"),
		"primary_route": has_node("PrimaryRouteBand"),
		"shortcut_route": has_node("ShortcutRouteBand"),
		"municipal_anchor": has_node("MunicipalGantry"),
		"storefront_family": has_node("Storefront"),
		"worker_treatment": _node_is_treated("ScrapWorker1"),
		"courier_bike_treatment": _node_is_treated("CourierBike"),
		"courier_repair_panel": _scene_has_node("CourierBike/VisualRoot/GearsAmberCourierPanel"),
		"utility_vehicle_treatment": _node_is_treated("ScrapHauler"),
		"pursuit_vehicle_treatment": _node_is_treated("PursuerPrototype"),
		"pursuit_civic_livery": _scene_has_node("PursuerPrototype/VisualRoot/GearsPursuitRoofID") and _scene_has_node("PursuerPrototype/VisualRoot/GearsPursuitFrontBand"),
		"utility_robot_treatment": _node_is_treated("UtilityCrawler"),
		"utility_robot_asset_marking": _scene_has_node("UtilityCrawler/Chassis/GearsReplacementPanel") and _scene_has_node("UtilityCrawler/Chassis/CrawlerAssetID"),
		"interactable_treatment": _node_is_treated("CorrodedPanel"),
		"distant_landmark": has_node("DistantRelay"),
		"practical_lighting": practical_count > 0,
		"uses_retained_camera": retained_camera,
		"graphic_families": ["municipal", "commercial", "aftermarket", "asset_marking"],
		"generated_mesh_instances": _count_meshes(self) + _runtime_generated_mesh_count,
		"outline_instances": _count_outlines(self) + _actor_outline_count,
		"practical_light_count": practical_count,
		"lighting_default": "day",
		"full_district_production": false,
		"humanoid_bot_substitute": false,
	}
