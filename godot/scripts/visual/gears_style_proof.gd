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

func _ready() -> void:
	call_deferred("_apply_actor_markers")

func _apply_actor_markers() -> void:
	var scene_root := get_parent()
	if scene_root == null:
		return
	for actor_name in TREATED_ACTORS:
		var actor := scene_root.get_node_or_null(actor_name)
		if actor != null:
			actor.set_meta("gears_style_proof_treatment", true)

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
	else:
		sun.light_energy = 1.25
		sun.light_color = Color(0.961, 0.898, 0.788, 1.0)

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
		"generated_mesh_instances": 0,
		"outline_instances": 0,
		"practical_light_count": 3,
		"lighting_default": "day",
		"full_district_production": false,
		"humanoid_bot_substitute": false,
	}
