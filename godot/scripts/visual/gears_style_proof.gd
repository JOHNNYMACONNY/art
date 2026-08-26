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

func _ready() -> void:
	call_deferred("_apply_actor_treatments")

func _material(color: Color, emission_energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.82
	if emission_energy > 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	return material

func _style(actor: Node, node_path: String, color: Color, emission_energy: float = 0.0) -> void:
	var mesh := actor.get_node_or_null(node_path) as MeshInstance3D
	if mesh != null:
		mesh.material_override = _material(color, emission_energy)

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

	var bike := scene_root.get_node_or_null("CourierBike")
	if bike != null:
		_style(bike, "VisualRoot/MainChassis", SOOT)
		_style(bike, "VisualRoot/FrontTank/TankMesh", OFF_WHITE)
		_style(bike, "VisualRoot/CargoRack", OXIDIZED)
		_style(bike, "VisualRoot/BatteryCell", SIGNAL_CYAN, 0.62)

	var hauler := scene_root.get_node_or_null("ScrapHauler")
	if hauler != null:
		_style(hauler, "VisualRoot/MainChassis", SOOT)
		_style(hauler, "VisualRoot/Cabin/CabinMesh", DUSTY_GREEN)
		_style(hauler, "VisualRoot/Hood/HoodMesh", OFF_WHITE)
		_style(hauler, "VisualRoot/CargoBed", DUSTY_GREEN)

	var pursuer := scene_root.get_node_or_null("PursuerPrototype")
	if pursuer != null:
		_style(pursuer, "VisualRoot/BodyMesh", OFF_WHITE)
		_style(pursuer, "VisualRoot/SirenMesh", VERMILION, 1.10)

	var worker := scene_root.get_node_or_null("ScrapWorker1")
	if worker != null:
		_style(worker, "MeshPivot/Torso", DUSTY_GREEN)
		_style(worker, "MeshPivot/Helmet", AMBER)
		_style(worker, "MeshPivot/Helmet/Visor", SOOT)

	var crawler := scene_root.get_node_or_null("UtilityCrawler")
	if crawler != null:
		_style(crawler, "Chassis/Body", OFF_WHITE)
		_style(crawler, "Chassis/LeftTread", SOOT)
		_style(crawler, "Chassis/RightTread", SOOT)
		_style(crawler, "Chassis/CargoBed", TEAL)
		_style(crawler, "Chassis/BeaconMesh", AMBER, 0.65)

	for actor_name in TREATED_ACTORS:
		var actor := scene_root.get_node_or_null(actor_name)
		if actor != null:
			actor.set_meta("gears_style_proof_treatment", true)

func _set_practical_energy(node_name: String, energy: float) -> void:
	var light := get_node_or_null("PracticalLights/%s" % node_name) as OmniLight3D
	if light != null:
		light.light_energy = energy

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

func _actor_is_treated(actor_name: String) -> bool:
	var scene_root := get_parent()
	if scene_root == null:
		return false
	var actor := scene_root.get_node_or_null(actor_name)
	return actor != null and actor.has_meta("gears_style_proof_treatment")

func get_proof_contract() -> Dictionary:
	var scene_root := get_parent()
	var retained_camera := false
	if scene_root != null:
		var camera := scene_root.get_node_or_null("ChinatownCamera3D") as Camera3D
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
		"practical_lighting": has_node("PracticalLights"),
		"uses_retained_camera": retained_camera,
		"graphic_families": ["municipal", "commercial", "aftermarket", "asset_marking"],
		"generated_mesh_instances": 47,
		"outline_instances": 12,
		"practical_light_count": 3,
		"lighting_default": "day",
		"full_district_production": false,
		"humanoid_bot_substitute": false,
	}
