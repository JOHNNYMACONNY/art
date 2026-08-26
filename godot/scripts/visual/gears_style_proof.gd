extends Node3D

# Issue #60: bounded additive visual proof. Gameplay and camera remain owned by
# the existing slice; this node only creates visual geometry/material treatment.

var scene_root = null
var toon_shader = null
var outline_shader = null
var outline_material = null
var material_cache = {}
var generated_mesh_instances = 0
var outline_instances = 0
var practical_lights = []
var built = false

func _ready():
	call_deferred("_build_proof")

func _build_proof():
	if built:
		return
	scene_root = get_parent()
	toon_shader = load("res://materials/gears_toon.gdshader")
	outline_shader = load("res://materials/gears_outline.gdshader")
	if scene_root == null or toon_shader == null or outline_shader == null:
		return
	_build_routes()
	_build_mixed_use()
	_build_gantry()
	_build_storefront()
	_build_relay()
	_build_lights()
	_treat_actors()
	set_lighting_mode("day")
	built = true

func _c(r, g, b):
	return Color(float(r) / 255.0, float(g) / 255.0, float(b) / 255.0, 1.0)

func _mat(color):
	var key = color.to_html(false)
	if material_cache.has(key):
		return material_cache[key]
	var material = ShaderMaterial.new()
	material.shader = toon_shader
	material.set_shader_parameter("base_color", color)
	material.set_shader_parameter("roughness_value", 0.82)
	material_cache[key] = material
	return material

func _outline_mat():
	if outline_material != null:
		return outline_material
	outline_material = ShaderMaterial.new()
	outline_material.shader = outline_shader
	outline_material.set_shader_parameter("outline_color", _c(16, 23, 26))
	outline_material.set_shader_parameter("outline_width", 0.035)
	return outline_material

func _emissive(color, energy):
	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.65
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	return material

func _group(group_name):
	var node = Node3D.new()
	node.name = group_name
	add_child(node)
	return node

func _box(parent_node, mesh_name, size, pos, color, outlined = false):
	var mesh = BoxMesh.new()
	mesh.size = size
	var instance = MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = mesh
	instance.position = pos
	instance.material_override = _mat(color)
	parent_node.add_child(instance)
	generated_mesh_instances += 1
	if outlined:
		var contour = MeshInstance3D.new()
		contour.name = mesh_name + "Contour"
		contour.mesh = mesh
		contour.position = pos
		contour.material_override = _outline_mat()
		parent_node.add_child(contour)
		generated_mesh_instances += 1
		outline_instances += 1
	return instance

func _label(parent_node, label_name, text_value, pos, color, font_size_value):
	var label = Label3D.new()
	label.name = label_name
	label.text = text_value
	label.position = pos
	label.modulate = color
	label.outline_modulate = _c(16, 23, 26)
	label.outline_size = 10
	label.font_size = font_size_value
	label.pixel_size = 0.006
	parent_node.add_child(label)

func _build_routes():
	var soot = _c(24, 33, 38)
	var off_white = _c(215, 210, 195)
	var amber = _c(211, 154, 44)
	var teal = _c(47, 119, 120)
	var primary = _group("PrimaryRouteBand")
	_box(primary, "CalmTarmac", Vector3(5.4, 0.035, 32.0), Vector3(1.7, 0.025, -5.0), soot)
	_box(primary, "WestEdge", Vector3(0.11, 0.05, 32.0), Vector3(-0.92, 0.04, -5.0), off_white)
	_box(primary, "EastRouteBand", Vector3(0.16, 0.052, 32.0), Vector3(4.34, 0.04, -5.0), amber)
	_box(primary, "RouteMarkerPlate", Vector3(1.8, 0.08, 0.55), Vector3(2.7, 0.07, 7.7), amber, true)
	var shortcut = _group("ShortcutRouteBand")
	_box(shortcut, "ShortcutSurface", Vector3(2.7, 0.04, 21.0), Vector3(-1.5, 0.035, 19.0), soot)
	_box(shortcut, "ShortcutTealBand", Vector3(0.14, 0.055, 21.0), Vector3(-2.78, 0.045, 19.0), teal)
	_box(shortcut, "ShortcutReturnBand", Vector3(0.10, 0.052, 21.0), Vector3(-0.22, 0.043, 19.0), off_white)

func _build_mixed_use():
	var block = _group("MixedUseBlock")
	block.position = Vector3(-8.0, 0.0, -2.0)
	_box(block, "WorkshopBase", Vector3(5.3, 2.4, 5.0), Vector3(0.0, 1.2, 0.0), _c(130, 127, 115), true)
	_box(block, "UpperTenancy", Vector3(4.45, 2.0, 4.25), Vector3(-0.25, 3.35, -0.15), _c(215, 210, 195), true)
	_box(block, "ServiceLoft", Vector3(3.3, 1.55, 3.25), Vector3(0.35, 5.12, -0.28), _c(47, 119, 120), true)
	_box(block, "BalconySlab", Vector3(4.7, 0.18, 1.0), Vector3(0.0, 2.72, 2.45), _c(24, 33, 38))
	_box(block, "UtilitySpine", Vector3(0.75, 4.9, 0.8), Vector3(-2.35, 3.25, -1.75), _c(40, 48, 52), true)
	_box(block, "ReplacementPanel", Vector3(1.15, 0.72, 0.10), Vector3(1.25, 3.65, 2.02), _c(211, 154, 44))
	_box(block, "LocalizedWearPatch", Vector3(0.85, 0.38, 0.08), Vector3(-1.65, 0.42, 2.52), _c(138, 79, 55))
	var tank_mesh = CylinderMesh.new()
	tank_mesh.top_radius = 0.52
	tank_mesh.bottom_radius = 0.52
	tank_mesh.height = 1.2
	tank_mesh.radial_segments = 10
	var tank = MeshInstance3D.new()
	tank.name = "RoofUtilityTank"
	tank.mesh = tank_mesh
	tank.position = Vector3(0.75, 6.45, -0.55)
	tank.material_override = _mat(_c(100, 99, 92))
	block.add_child(tank)
	generated_mesh_instances += 1

func _build_gantry():
	var gantry = _group("MunicipalGantry")
	gantry.position = Vector3(4.9, 0.0, -6.4)
	_box(gantry, "WestStanchion", Vector3(0.42, 4.0, 0.48), Vector3(-1.75, 2.0, 0.0), _c(215, 210, 195), true)
	_box(gantry, "EastStanchion", Vector3(0.42, 4.0, 0.48), Vector3(1.75, 2.0, 0.0), _c(215, 210, 195), true)
	_box(gantry, "CrossBeam", Vector3(4.0, 0.46, 0.55), Vector3(0.0, 3.82, 0.0), _c(24, 33, 38), true)
	_box(gantry, "CivicPlate", Vector3(1.65, 0.78, 0.16), Vector3(0.62, 3.52, 0.33), _c(211, 154, 44), true)
	_box(gantry, "InspectionTag", Vector3(0.58, 0.32, 0.18), Vector3(-1.42, 2.48, 0.30), _c(47, 119, 120))
	_label(gantry, "CivicRouteLabel", "M-7", Vector3(0.62, 3.52, 0.43), _c(24, 33, 38), 54)
	_label(gantry, "InspectionLabel", "INSPECT", Vector3(-1.42, 2.48, 0.41), _c(215, 210, 195), 28)

func _build_storefront():
	var store = _group("Storefront")
	store.position = Vector3(-6.25, 0.0, 0.62)
	_box(store, "StoreShell", Vector3(2.75, 1.85, 0.72), Vector3(0.0, 0.94, 0.0), _c(35, 44, 49), true)
	_box(store, "HeroSign", Vector3(2.35, 0.72, 0.16), Vector3(0.0, 1.96, 0.42), _c(47, 119, 120), true)
	_box(store, "SignAmberTab", Vector3(0.44, 0.90, 0.20), Vector3(-1.10, 1.96, 0.44), _c(211, 154, 44))
	_box(store, "ServiceDoor", Vector3(0.86, 1.42, 0.12), Vector3(0.68, 0.72, 0.42), _c(170, 166, 154))
	_box(store, "AftermarketSticker01", Vector3(0.50, 0.20, 0.035), Vector3(-0.72, 0.48, 0.50), _c(210, 75, 58))
	_box(store, "AftermarketSticker02", Vector3(0.34, 0.17, 0.038), Vector3(-0.38, 0.28, 0.50), _c(211, 154, 44))
	# Proof-only graphic samples; not canon business/asset naming decisions.
	_label(store, "CommercialHeroLabel", "REPAIR", Vector3(0.12, 1.96, 0.54), _c(215, 210, 195), 48)
	_label(store, "AftermarketLabel", "FIX/RIDE", Vector3(-0.56, 0.48, 0.55), _c(215, 210, 195), 22)
	_label(store, "AssetMarkingLabel", "ASSET 042", Vector3(0.68, 0.52, 0.55), _c(24, 33, 38), 22)

func _build_relay():
	var relay = _group("DistantRelay")
	relay.position = Vector3(3.0, 0.0, -28.0)
	_box(relay, "RelayBase", Vector3(3.3, 1.1, 3.0), Vector3(0.0, 0.55, 0.0), _c(110, 108, 99), true)
	_box(relay, "RelayCore", Vector3(1.15, 6.5, 1.15), Vector3(0.0, 3.75, 0.0), _c(30, 39, 44), true)
	_box(relay, "RelayCap", Vector3(2.2, 0.65, 1.55), Vector3(0.0, 7.15, 0.0), _c(180, 176, 164), true)
	_box(relay, "WestArm", Vector3(2.8, 0.24, 0.28), Vector3(-1.25, 5.45, 0.0), _c(24, 33, 38))
	_box(relay, "EastArm", Vector3(2.8, 0.24, 0.28), Vector3(1.25, 4.65, 0.0), _c(24, 33, 38))
	var signal = _box(relay, "ScarceSignal", Vector3(0.26, 0.26, 0.26), Vector3(0.0, 7.55, 0.0), _c(124, 207, 208))
	signal.material_override = _emissive(_c(124, 207, 208), 0.55)
	_box(relay, "RemovedAssetPlate", Vector3(0.62, 0.32, 0.08), Vector3(0.0, 1.45, 0.60), _c(15, 20, 23))

func _build_lights():
	var lights_group = _group("PracticalLights")
	_add_light(lights_group, "StoreWorkLamp", Vector3(-6.15, 2.25, 1.4), _c(255, 214, 138), 1.0, 5.0)
	_add_light(lights_group, "GantryServiceLamp", Vector3(4.9, 3.6, -6.0), _c(255, 225, 168), 0.8, 4.5)
	_add_light(lights_group, "RelayMarkerLamp", Vector3(3.0, 7.5, -28.0), _c(124, 207, 208), 0.35, 3.0)

func _add_light(parent_node, light_name, pos, color, energy, range_value):
	var light = OmniLight3D.new()
	light.name = light_name
	light.position = pos
	light.light_color = color
	light.light_energy = energy
	light.omni_range = range_value
	light.shadow_enabled = false
	parent_node.add_child(light)
	practical_lights.append(light)

func set_lighting_mode(mode):
	if scene_root == null:
		return
	var dusk = str(mode).to_lower() == "dusk"
	var sun = scene_root.get_node_or_null("DirectionalLight3D")
	if sun != null:
		if dusk:
			sun.light_energy = 0.58
			sun.light_color = _c(241, 183, 122)
		else:
			sun.light_energy = 1.25
			sun.light_color = _c(245, 229, 201)
	if practical_lights.size() == 3:
		if dusk:
			practical_lights[0].light_energy = 1.55
			practical_lights[1].light_energy = 1.24
			practical_lights[2].light_energy = 0.54
		else:
			practical_lights[0].light_energy = 1.0
			practical_lights[1].light_energy = 0.8
			practical_lights[2].light_energy = 0.35

func _style(actor, node_path, color):
	var mesh = actor.get_node_or_null(node_path)
	if mesh != null and mesh is MeshInstance3D:
		mesh.material_override = _mat(color)

func _style_emission(actor, node_path, color, energy):
	var mesh = actor.get_node_or_null(node_path)
	if mesh != null and mesh is MeshInstance3D:
		mesh.material_override = _emissive(color, energy)

func _style_existing_outline(actor, node_path):
	var mesh = actor.get_node_or_null(node_path)
	if mesh != null and mesh is MeshInstance3D:
		mesh.material_override = _outline_mat()
		outline_instances += 1

func _clone_outline(actor, node_path, contour_name):
	var source = actor.get_node_or_null(node_path)
	if source == null or not (source is MeshInstance3D):
		return
	if source.mesh == null or source.get_parent() == null:
		return
	var contour = MeshInstance3D.new()
	contour.name = contour_name
	contour.mesh = source.mesh
	contour.transform = source.transform
	contour.material_override = _outline_mat()
	source.get_parent().add_child(contour)
	generated_mesh_instances += 1
	outline_instances += 1

func _mark(actor, treatment):
	actor.set_meta("gears_style_proof_treatment", treatment)

func _treat_actors():
	var runner = scene_root.get_node_or_null("Runner")
	if runner != null:
		_style(runner, "MeshPivot/Torso/TorsoMesh", _c(39, 100, 101))
		_style(runner, "MeshPivot/Torso/Satchel", _c(138, 79, 55))
		_style(runner, "MeshPivot/Head/HeadMesh", _c(24, 33, 38))
		_style_emission(runner, "MeshPivot/Torso/ChestRig", _c(124, 207, 208), 0.42)
		_style_emission(runner, "MeshPivot/Head/Visor", _c(124, 207, 208), 0.72)
		_style_existing_outline(runner, "MeshPivot/Torso/TorsoOutline")
		_mark(runner, "player_teal_workwear_signal_cyan")
	var bike = scene_root.get_node_or_null("CourierBike")
	if bike != null:
		_style(bike, "VisualRoot/MainChassis", _c(24, 33, 38))
		_style(bike, "VisualRoot/FrontTank/TankMesh", _c(215, 210, 195))
		_style(bike, "VisualRoot/CargoRack", _c(138, 79, 55))
		_style_emission(bike, "VisualRoot/BatteryCell", _c(124, 207, 208), 0.62)
		_style_existing_outline(bike, "VisualRoot/FrontTank/TankOutline")
		var bike_root = bike.get_node_or_null("VisualRoot")
		if bike_root != null:
			_box(bike_root, "GearsAmberCourierPanel", Vector3(0.46, 0.12, 0.58), Vector3(0.0, 0.52, 0.46), _c(211, 154, 44))
		_mark(bike, "courier_offwhite_charcoal_amber_signal")
	var hauler = scene_root.get_node_or_null("ScrapHauler")
	if hauler != null:
		_style(hauler, "VisualRoot/MainChassis", _c(24, 33, 38))
		_style(hauler, "VisualRoot/Cabin/CabinMesh", _c(102, 112, 91))
		_style(hauler, "VisualRoot/Hood/HoodMesh", _c(215, 210, 195))
		_style(hauler, "VisualRoot/CargoBed", _c(84, 94, 75))
		_style_existing_outline(hauler, "VisualRoot/Cabin/CabinOutline")
		_style_existing_outline(hauler, "VisualRoot/Hood/HoodOutline")
		_mark(hauler, "utility_vehicle_dusty_green_offwhite")
	var pursuer = scene_root.get_node_or_null("PursuerPrototype")
	if pursuer != null:
		_style(pursuer, "VisualRoot/BodyMesh", _c(185, 181, 169))
		_style_emission(pursuer, "VisualRoot/SirenMesh", _c(210, 75, 58), 1.1)
		_clone_outline(pursuer, "VisualRoot/BodyMesh", "GearsPursuitBodyContour")
		var pursuit_root = pursuer.get_node_or_null("VisualRoot")
		if pursuit_root != null:
			_box(pursuit_root, "GearsPursuitRoofID", Vector3(0.82, 0.16, 0.92), Vector3(0.0, 1.25, 0.0), _c(24, 33, 38))
			_box(pursuit_root, "GearsPursuitFrontBand", Vector3(1.18, 0.24, 0.18), Vector3(0.0, 0.72, -1.10), _c(210, 75, 58))
		_mark(pursuer, "municipal_pursuit_offwhite_charcoal_vermilion")
	var worker = scene_root.get_node_or_null("ScrapWorker1")
	if worker != null:
		_style(worker, "MeshPivot/Torso", _c(102, 112, 91))
		_style(worker, "MeshPivot/Helmet", _c(211, 154, 44))
		_clone_outline(worker, "MeshPivot/Torso", "GearsWorkerTorsoContour")
		_mark(worker, "ordinary_worker_dusty_green_amber")
	var crawler = scene_root.get_node_or_null("UtilityCrawler")
	if crawler != null:
		_style(crawler, "Chassis/Body", _c(215, 210, 195))
		_style(crawler, "Chassis/LeftTread", _c(24, 33, 38))
		_style(crawler, "Chassis/RightTread", _c(24, 33, 38))
		_style(crawler, "Chassis/CargoBed", _c(47, 119, 120))
		_style_emission(crawler, "Chassis/BeaconMesh", _c(211, 154, 44), 0.65)
		_clone_outline(crawler, "Chassis/Body", "GearsCrawlerBodyContour")
		var crawler_root = crawler.get_node_or_null("Chassis")
		if crawler_root != null:
			_box(crawler_root, "ReplacementPanel", Vector3(0.36, 0.16, 0.08), Vector3(0.22, 0.30, -0.61), _c(138, 79, 55))
		_mark(crawler, "utility_crawler_offwhite_teal_repair_history")

func _treated(actor_name):
	if scene_root == null:
		return false
	var actor = scene_root.get_node_or_null(actor_name)
	return actor != null and actor.has_meta("gears_style_proof_treatment")

func get_proof_contract():
	var retained_camera = false
	if scene_root != null:
		var camera = scene_root.get_node_or_null("ChinatownCamera3D")
		if camera != null:
			retained_camera = abs(camera.fov - 32.0) <= 0.05
	return {
		"version": "issue60_gears_style_proof_v1",
		"stacked_mixed_use": has_node("MixedUseBlock"),
		"primary_route": has_node("PrimaryRouteBand"),
		"shortcut_route": has_node("ShortcutRouteBand"),
		"municipal_anchor": has_node("MunicipalGantry"),
		"storefront_family": has_node("Storefront"),
		"worker_treatment": _treated("ScrapWorker1"),
		"courier_bike_treatment": _treated("CourierBike"),
		"utility_vehicle_treatment": _treated("ScrapHauler"),
		"pursuit_vehicle_treatment": _treated("PursuerPrototype"),
		"utility_robot_treatment": _treated("UtilityCrawler"),
		"distant_landmark": has_node("DistantRelay"),
		"practical_lighting": practical_lights.size() > 0,
		"uses_retained_camera": retained_camera,
		"graphic_families": ["municipal", "commercial", "aftermarket", "asset_marking"],
		"generated_mesh_instances": generated_mesh_instances,
		"outline_instances": outline_instances,
		"practical_light_count": practical_lights.size(),
		"lighting_default": "day",
		"full_district_production": false,
		"humanoid_bot_substitute": false
	}
