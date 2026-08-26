extends Node3D

# Issue #60 — bounded in-engine visual feasibility proof.
# Additive only: this node does not own movement, camera, mission, pursuit,
# vehicle, input, retry, save, or reset behavior.

const TOON_SHADER: Shader = preload("res://materials/gears_toon.gdshader")
const OUTLINE_SHADER: Shader = preload("res://materials/gears_outline.gdshader")

const SOOT := Color("182126")
const OFF_WHITE := Color("d7d2c3")
const CONCRETE := Color("827f73")
const OXIDIZED := Color("8a4f37")
const AMBER := Color("d39a2c")
const TEAL := Color("2f7778")
const VERMILION := Color("d24b3a")
const SIGNAL_CYAN := Color("7ccfd0")
const DUSTY_GREEN := Color("66705b")
const OUTLINE_COLOR := Color("10171a")

var _built := false
var _generated_mesh_instances := 0
var _outline_instances := 0
var _practical_light_count := 0
var _toon_cache: Dictionary = {}
var _outline_material: ShaderMaterial = null
var _scene_root: Node = null
var _world_environment: WorldEnvironment = null
var _directional_light: DirectionalLight3D = null
var _practical_lights: Array[OmniLight3D] = []

func _ready() -> void:
	call_deferred("_build_and_apply")

func _build_and_apply() -> void:
	if _built:
		return
	_scene_root = get_parent()
	if _scene_root == null:
		return
	_build_primary_route()
	_build_shortcut_route()
	_build_mixed_use_block()
	_build_municipal_gantry()
	_build_storefront()
	_build_distant_relay()
	_build_practical_lights()
	_apply_actor_treatments()
	_capture_lighting_nodes()
	set_lighting_mode("day")
	_built = true

func _toon_material(color: Color, roughness: float = 0.82) -> ShaderMaterial:
	var key := "%s:%.2f" % [color.to_html(false), roughness]
	if _toon_cache.has(key):
		return _toon_cache[key] as ShaderMaterial
	var material := ShaderMaterial.new()
	material.shader = TOON_SHADER
	material.set_shader_parameter("base_color", color)
	material.set_shader_parameter("roughness_value", roughness)
	_toon_cache[key] = material
	return material

func _get_outline_material() -> ShaderMaterial:
	if _outline_material != null:
		return _outline_material
	_outline_material = ShaderMaterial.new()
	_outline_material.shader = OUTLINE_SHADER
	_outline_material.set_shader_parameter("outline_color", OUTLINE_COLOR)
	_outline_material.set_shader_parameter("outline_width", 0.035)
	return _outline_material

func _emissive_material(color: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.65
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material

func _new_group(group_name: String) -> Node3D:
	var group := Node3D.new()
	group.name = group_name
	add_child(group)
	return group

func _add_box(
	parent: Node3D,
	mesh_name: String,
	size: Vector3,
	position: Vector3,
	color: Color,
	with_outline: bool = false,
	rotation_y: float = 0.0,
	roughness: float = 0.82
) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = mesh
	instance.position = position
	instance.rotation.y = rotation_y
	instance.material_override = _toon_material(color, roughness)
	parent.add_child(instance)
	_generated_mesh_instances += 1
	if with_outline:
		var contour := MeshInstance3D.new()
		contour.name = "%sContour" % mesh_name
		contour.mesh = mesh
		contour.position = position
		contour.rotation.y = rotation_y
		contour.material_override = _get_outline_material()
		parent.add_child(contour)
		_generated_mesh_instances += 1
		_outline_instances += 1
	return instance

func _add_cylinder(
	parent: Node3D,
	mesh_name: String,
	radius: float,
	height: float,
	position: Vector3,
	color: Color,
	with_outline: bool = false
) -> MeshInstance3D:
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = height
	mesh.radial_segments = 10
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = mesh
	instance.position = position
	instance.material_override = _toon_material(color)
	parent.add_child(instance)
	_generated_mesh_instances += 1
	if with_outline:
		var contour := MeshInstance3D.new()
		contour.name = "%sContour" % mesh_name
		contour.mesh = mesh
		contour.position = position
		contour.material_override = _get_outline_material()
		parent.add_child(contour)
		_generated_mesh_instances += 1
		_outline_instances += 1
	return instance

func _add_label(
	parent: Node3D,
	label_name: String,
	text_value: String,
	position: Vector3,
	color: Color,
	font_size_value: int,
	pixel_size_value: float
) -> void:
	var label := Label3D.new()
	label.name = label_name
	label.text = text_value
	label.position = position
	label.modulate = color
	label.outline_modulate = OUTLINE_COLOR
	label.font_size = font_size_value
	label.outline_size = 10
	label.pixel_size = pixel_size_value
	parent.add_child(label)

func _build_primary_route() -> void:
	var route := _new_group("PrimaryRouteBand")
	_add_box(route, "CalmTarmac", Vector3(5.4, 0.035, 32.0), Vector3(1.7, 0.025, -5.0), SOOT.lightened(0.08))
	_add_box(route, "WestEdge", Vector3(0.11, 0.05, 32.0), Vector3(-0.92, 0.04, -5.0), OFF_WHITE.darkened(0.28))
	_add_box(route, "EastRouteBand", Vector3(0.16, 0.052, 32.0), Vector3(4.34, 0.04, -5.0), AMBER.darkened(0.12))
	_add_box(route, "RouteMarkerPlate", Vector3(1.8, 0.08, 0.55), Vector3(2.7, 0.07, 7.7), AMBER.darkened(0.08), true)

func _build_shortcut_route() -> void:
	var route := _new_group("ShortcutRouteBand")
	_add_box(route, "ShortcutSurface", Vector3(2.7, 0.04, 21.0), Vector3(-1.5, 0.035, 19.0), SOOT.lightened(0.14))
	_add_box(route, "ShortcutTealBand", Vector3(0.14, 0.055, 21.0), Vector3(-2.78, 0.045, 19.0), TEAL)
	_add_box(route, "ShortcutReturnBand", Vector3(0.10, 0.052, 21.0), Vector3(-0.22, 0.043, 19.0), OFF_WHITE.darkened(0.34))

func _build_mixed_use_block() -> void:
	var block := _new_group("MixedUseBlock")
	block.position = Vector3(-8.0, 0.0, -2.0)
	_add_box(block, "WorkshopBase", Vector3(5.3, 2.4, 5.0), Vector3(0.0, 1.2, 0.0), CONCRETE.darkened(0.12), true)
	_add_box(block, "UpperTenancy", Vector3(4.45, 2.0, 4.25), Vector3(-0.25, 3.35, -0.15), OFF_WHITE.darkened(0.05), true)
	_add_box(block, "ServiceLoft", Vector3(3.3, 1.55, 3.25), Vector3(0.35, 5.12, -0.28), TEAL.darkened(0.28), true)
	_add_box(block, "BalconySlab", Vector3(4.7, 0.18, 1.0), Vector3(0.0, 2.72, 2.45), SOOT)
	_add_box(block, "UtilitySpine", Vector3(0.75, 4.9, 0.8), Vector3(-2.35, 3.25, -1.75), SOOT.lightened(0.12), true)
	_add_box(block, "ReplacementPanel", Vector3(1.15, 0.72, 0.10), Vector3(1.25, 3.65, 2.02), AMBER.darkened(0.18))
	_add_box(block, "LocalizedWearPatch", Vector3(0.85, 0.38, 0.08), Vector3(-1.65, 0.42, 2.52), OXIDIZED)
	_add_cylinder(block, "RoofUtilityTank", 0.52, 1.2, Vector3(0.75, 6.45, -0.55), CONCRETE.darkened(0.24), true)

func _build_municipal_gantry() -> void:
	var gantry := _new_group("MunicipalGantry")
	gantry.position = Vector3(4.9, 0.0, -6.4)
	_add_box(gantry, "WestStanchion", Vector3(0.42, 4.0, 0.48), Vector3(-1.75, 2.0, 0.0), OFF_WHITE.darkened(0.12), true)
	_add_box(gantry, "EastStanchion", Vector3(0.42, 4.0, 0.48), Vector3(1.75, 2.0, 0.0), OFF_WHITE.darkened(0.12), true)
	_add_box(gantry, "CrossBeam", Vector3(4.0, 0.46, 0.55), Vector3(0.0, 3.82, 0.0), SOOT.lightened(0.08), true)
	_add_box(gantry, "CivicPlate", Vector3(1.65, 0.78, 0.16), Vector3(0.62, 3.52, 0.33), AMBER.darkened(0.08), true)
	_add_box(gantry, "InspectionTag", Vector3(0.58, 0.32, 0.18), Vector3(-1.42, 2.48, 0.30), TEAL.darkened(0.10))
	_add_label(gantry, "CivicRouteLabel", "M-7", Vector3(0.62, 3.52, 0.43), SOOT, 54, 0.006)
	_add_label(gantry, "InspectionLabel", "INSPECT", Vector3(-1.42, 2.48, 0.41), OFF_WHITE, 28, 0.004)

func _build_storefront() -> void:
	var store := _new_group("Storefront")
	store.position = Vector3(-6.25, 0.0, 0.62)
	_add_box(store, "StoreShell", Vector3(2.75, 1.85, 0.72), Vector3(0.0, 0.94, 0.0), SOOT.lightened(0.10), true)
	_add_box(store, "HeroSign", Vector3(2.35, 0.72, 0.16), Vector3(0.0, 1.96, 0.42), TEAL, true)
	_add_box(store, "SignAmberTab", Vector3(0.44, 0.90, 0.20), Vector3(-1.10, 1.96, 0.44), AMBER)
	_add_box(store, "ServiceDoor", Vector3(0.86, 1.42, 0.12), Vector3(0.68, 0.72, 0.42), OFF_WHITE.darkened(0.22))
	_add_box(store, "AftermarketSticker01", Vector3(0.50, 0.20, 0.035), Vector3(-0.72, 0.48, 0.50), VERMILION)
	_add_box(store, "AftermarketSticker02", Vector3(0.34, 0.17, 0.038), Vector3(-0.38, 0.28, 0.50), AMBER)
	# Proof-only wording. These are graphic-family samples, not canon business names.
	_add_label(store, "CommercialHeroLabel", "REPAIR", Vector3(0.12, 1.96, 0.54), OFF_WHITE, 48, 0.006)
	_add_label(store, "AftermarketLabel", "FIX/RIDE", Vector3(-0.56, 0.48, 0.55), OFF_WHITE, 22, 0.0035)
	_add_label(store, "AssetMarkingLabel", "ASSET 042", Vector3(0.68, 0.52, 0.55), SOOT, 22, 0.0035)

func _build_distant_relay() -> void:
	var relay := _new_group("DistantRelay")
	relay.position = Vector3(3.0, 0.0, -28.0)
	_add_box(relay, "RelayBase", Vector3(3.3, 1.1, 3.0), Vector3(0.0, 0.55, 0.0), CONCRETE.darkened(0.18), true)
	_add_box(relay, "RelayCore", Vector3(1.15, 6.5, 1.15), Vector3(0.0, 3.75, 0.0), SOOT.lightened(0.08), true)
	_add_box(relay, "RelayCap", Vector3(2.2, 0.65, 1.55), Vector3(0.0, 7.15, 0.0), OFF_WHITE.darkened(0.18), true)
	_add_box(relay, "WestArm", Vector3(2.8, 0.24, 0.28), Vector3(-1.25, 5.45, 0.0), SOOT)
	_add_box(relay, "EastArm", Vector3(2.8, 0.24, 0.28), Vector3(1.25, 4.65, 0.0), SOOT)
	var signal := _add_box(relay, "ScarceSignal", Vector3(0.26, 0.26, 0.26), Vector3(0.0, 7.55, 0.0), SIGNAL_CYAN)
	signal.material_override = _emissive_material(SIGNAL_CYAN, 0.55)
	_add_box(relay, "RemovedAssetPlate", Vector3(0.62, 0.32, 0.08), Vector3(0.0, 1.45, 0.60), SOOT.darkened(0.08))

func _build_practical_lights() -> void:
	var lights := _new_group("PracticalLights")
	_add_practical_light(lights, "StoreWorkLamp", Vector3(-6.15, 2.25, 1.4), Color("ffd68a"), 1.0, 5.0)
	_add_practical_light(lights, "GantryServiceLamp", Vector3(4.9, 3.6, -6.0), Color("ffe1a8"), 0.8, 4.5)
	_add_practical_light(lights, "RelayMarkerLamp", Vector3(3.0, 7.5, -28.0), SIGNAL_CYAN, 0.35, 3.0)

func _add_practical_light(
	parent: Node3D,
	light_name: String,
	position: Vector3,
	color: Color,
	energy: float,
	range_value: float
) -> void:
	var light := OmniLight3D.new()
	light.name = light_name
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light.shadow_enabled = false
	parent.add_child(light)
	_practical_lights.append(light)
	_practical_light_count += 1

func _capture_lighting_nodes() -> void:
	if _scene_root == null:
		return
	_world_environment = _scene_root.get_node_or_null("WorldEnvironment") as WorldEnvironment
	_directional_light = _scene_root.get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if _world_environment != null and _world_environment.environment != null:
		_world_environment.environment = _world_environment.environment.duplicate(true)

func set_lighting_mode(mode: String) -> void:
	var dusk := mode.to_lower() == "dusk"
	if _directional_light != null:
		if dusk:
			_directional_light.light_energy = 0.58
			_directional_light.light_color = Color("f1b77a")
		else:
			_directional_light.light_energy = 1.25
			_directional_light.light_color = Color("f5e5c9")
	if _world_environment != null and _world_environment.environment != null:
		var env := _world_environment.environment
		if dusk:
			env.background_color = Color("252b31")
			env.ambient_light_color = Color("5f6670")
			env.ambient_light_energy = 0.72
			env.glow_intensity = 0.24
			env.glow_bloom = 0.06
		else:
			env.background_color = Color("11161a")
			env.ambient_light_color = Color("697780")
			env.ambient_light_energy = 1.0
			env.glow_intensity = 0.16
			env.glow_bloom = 0.035
	if _practical_lights.size() == 3:
		if dusk:
			_practical_lights[0].light_energy = 1.55
			_practical_lights[1].light_energy = 1.24
			_practical_lights[2].light_energy = 0.54
		else:
			_practical_lights[0].light_energy = 1.0
			_practical_lights[1].light_energy = 0.8
			_practical_lights[2].light_energy = 0.35

func _style_mesh(actor: Node, path: String, color: Color, roughness: float = 0.82) -> void:
	var mesh := actor.get_node_or_null(path) as MeshInstance3D
	if mesh != null:
		mesh.material_override = _toon_material(color, roughness)

func _style_emissive(actor: Node, path: String, color: Color, energy: float) -> void:
	var mesh := actor.get_node_or_null(path) as MeshInstance3D
	if mesh != null:
		mesh.material_override = _emissive_material(color, energy)

func _style_outline(actor: Node, path: String) -> void:
	var mesh := actor.get_node_or_null(path) as MeshInstance3D
	if mesh != null:
		mesh.material_override = _get_outline_material()
		_outline_instances += 1

func _add_existing_outline(actor: Node, path: String, contour_name: String) -> void:
	var source := actor.get_node_or_null(path) as MeshInstance3D
	if source == null:
		return
	if source.mesh == null or source.get_parent() == null:
		return
	var contour := MeshInstance3D.new()
	contour.name = contour_name
	contour.mesh = source.mesh
	contour.transform = source.transform
	contour.material_override = _get_outline_material()
	source.get_parent().add_child(contour)
	_generated_mesh_instances += 1
	_outline_instances += 1

func _mark_actor(actor: Node, treatment: String) -> void:
	actor.set_meta("gears_style_proof_treatment", treatment)

func _apply_actor_treatments() -> void:
	if _scene_root == null:
		return
	var runner := _scene_root.get_node_or_null("Runner")
	if runner != null:
		_style_mesh(runner, "MeshPivot/Torso/TorsoMesh", TEAL.darkened(0.16))
		_style_mesh(runner, "MeshPivot/Torso/Satchel", OXIDIZED)
		_style_mesh(runner, "MeshPivot/Head/HeadMesh", SOOT)
		_style_mesh(runner, "MeshPivot/LeftArm/LeftArmMesh", TEAL.darkened(0.16))
		_style_mesh(runner, "MeshPivot/RightArm/RightArmMesh", TEAL.darkened(0.16))
		_style_emissive(runner, "MeshPivot/Torso/ChestRig", SIGNAL_CYAN, 0.42)
		_style_emissive(runner, "MeshPivot/Head/Visor", SIGNAL_CYAN, 0.72)
		_style_outline(runner, "MeshPivot/Torso/TorsoOutline")
		_mark_actor(runner, "player_teal_workwear_signal_cyan")
	var bike := _scene_root.get_node_or_null("CourierBike")
	if bike != null:
		_style_mesh(bike, "VisualRoot/MainChassis", SOOT)
		_style_mesh(bike, "VisualRoot/FrontTank/TankMesh", OFF_WHITE.darkened(0.05))
		_style_mesh(bike, "VisualRoot/Saddle", SOOT.darkened(0.18))
		_style_mesh(bike, "VisualRoot/CargoRack", OXIDIZED.darkened(0.12))
		_style_emissive(bike, "VisualRoot/BatteryCell", SIGNAL_CYAN, 0.62)
		_style_outline(bike, "VisualRoot/FrontTank/TankOutline")
		var bike_root := bike.get_node_or_null("VisualRoot") as Node3D
		if bike_root != null:
			_add_box(bike_root, "GearsAmberCourierPanel", Vector3(0.46, 0.12, 0.58), Vector3(0.0, 0.52, 0.46), AMBER)
		_mark_actor(bike, "courier_offwhite_charcoal_amber_signal")
	var hauler := _scene_root.get_node_or_null("ScrapHauler")
	if hauler != null:
		_style_mesh(hauler, "VisualRoot/MainChassis", SOOT)
		_style_mesh(hauler, "VisualRoot/Cabin/CabinMesh", DUSTY_GREEN)
		_style_mesh(hauler, "VisualRoot/Hood/HoodMesh", OFF_WHITE.darkened(0.12))
		_style_mesh(hauler, "VisualRoot/CargoBed", DUSTY_GREEN.darkened(0.16))
		_style_emissive(hauler, "VisualRoot/BatteryCore", SIGNAL_CYAN, 0.48)
		_style_outline(hauler, "VisualRoot/Cabin/CabinOutline")
		_style_outline(hauler, "VisualRoot/Hood/HoodOutline")
		_mark_actor(hauler, "utility_vehicle_dusty_green_offwhite")
	var pursuer := _scene_root.get_node_or_null("PursuerPrototype")
	if pursuer != null:
		_style_mesh(pursuer, "VisualRoot/BodyMesh", OFF_WHITE.darkened(0.14))
		_style_emissive(pursuer, "VisualRoot/SirenMesh", VERMILION, 1.1)
		_add_existing_outline(pursuer, "VisualRoot/BodyMesh", "GearsPursuitBodyContour")
		var pursuit_root := pursuer.get_node_or_null("VisualRoot") as Node3D
		if pursuit_root != null:
			_add_box(pursuit_root, "GearsPursuitRoofID", Vector3(0.82, 0.16, 0.92), Vector3(0.0, 1.25, 0.0), SOOT)
			_add_box(pursuit_root, "GearsPursuitFrontBand", Vector3(1.18, 0.24, 0.18), Vector3(0.0, 0.72, -1.10), VERMILION)
			_add_label(pursuit_root, "PursuitAssetLabel", "CIV 12", Vector3(0.0, 1.36, 0.0), OFF_WHITE, 26, 0.0035)
		_mark_actor(pursuer, "municipal_pursuit_offwhite_charcoal_vermilion")
	var worker := _scene_root.get_node_or_null("ScrapWorker1")
	if worker != null:
		_style_mesh(worker, "MeshPivot/Torso", DUSTY_GREEN.darkened(0.08))
		_style_mesh(worker, "MeshPivot/Helmet", AMBER.darkened(0.10))
		_style_mesh(worker, "MeshPivot/Helmet/Visor", SOOT)
		_add_existing_outline(worker, "MeshPivot/Torso", "GearsWorkerTorsoContour")
		_mark_actor(worker, "ordinary_worker_dusty_green_amber")
	var worker_2 := _scene_root.get_node_or_null("ScrapWorker2")
	if worker_2 != null:
		_style_mesh(worker_2, "MeshPivot/Torso", CONCRETE.darkened(0.22))
		_style_mesh(worker_2, "MeshPivot/Helmet", OFF_WHITE.darkened(0.10))
		_style_mesh(worker_2, "MeshPivot/Helmet/Visor", SOOT)
		_mark_actor(worker_2, "ordinary_worker_concrete_offwhite")
	var crawler := _scene_root.get_node_or_null("UtilityCrawler")
	if crawler != null:
		_style_mesh(crawler, "Chassis/Body", OFF_WHITE.darkened(0.10))
		_style_mesh(crawler, "Chassis/LeftTread", SOOT)
		_style_mesh(crawler, "Chassis/RightTread", SOOT)
		_style_mesh(crawler, "Chassis/CargoBed", TEAL.darkened(0.22))
		_style_emissive(crawler, "Chassis/BeaconMesh", AMBER, 0.65)
		_add_existing_outline(crawler, "Chassis/Body", "GearsCrawlerBodyContour")
		var crawler_chassis := crawler.get_node_or_null("Chassis") as Node3D
		if crawler_chassis != null:
			_add_box(crawler_chassis, "ReplacementPanel", Vector3(0.36, 0.16, 0.08), Vector3(0.22, 0.30, -0.61), OXIDIZED)
			_add_label(crawler_chassis, "CrawlerAssetID", "UTL-08", Vector3(0.0, 0.28, -0.66), SOOT, 22, 0.003)
		_mark_actor(crawler, "utility_crawler_offwhite_teal_repair_history")

func get_proof_contract() -> Dictionary:
	var camera: Camera3D = null
	if _scene_root != null:
		camera = _scene_root.get_node_or_null("ChinatownCamera3D") as Camera3D
	var retained_camera := false
	if camera != null:
		retained_camera = absf(camera.fov - 32.0) <= 0.05
	return {
		"version": "issue60_gears_style_proof_v1",
		"stacked_mixed_use": has_node("MixedUseBlock"),
		"primary_route": has_node("PrimaryRouteBand"),
		"shortcut_route": has_node("ShortcutRouteBand"),
		"municipal_anchor": has_node("MunicipalGantry"),
		"storefront_family": has_node("Storefront"),
		"worker_treatment": _actor_is_treated("ScrapWorker1"),
		"courier_bike_treatment": _actor_is_treated("CourierBike"),
		"utility_vehicle_treatment": _actor_is_treated("ScrapHauler"),
		"pursuit_vehicle_treatment": _actor_is_treated("PursuerPrototype"),
		"utility_robot_treatment": _actor_is_treated("UtilityCrawler"),
		"distant_landmark": has_node("DistantRelay"),
		"practical_lighting": _practical_light_count > 0,
		"uses_retained_camera": retained_camera,
		"graphic_families": ["municipal", "commercial", "aftermarket", "asset_marking"],
		"generated_mesh_instances": _generated_mesh_instances,
		"outline_instances": _outline_instances,
		"practical_light_count": _practical_light_count,
		"lighting_default": "day",
		"full_district_production": false,
		"humanoid_bot_substitute": false,
	}

func _actor_is_treated(actor_name: String) -> bool:
	if _scene_root == null:
		return false
	var actor := _scene_root.get_node_or_null(actor_name)
	return actor != null and actor.has_meta("gears_style_proof_treatment")
