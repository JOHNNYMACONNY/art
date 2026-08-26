extends SceneTree

# Focused Issue #60 contract for direct invocation. The existing PR workflow
# also gates the essential integration subset through dynamic_camera_follow_test.gd
# so the style proof and retained camera behavior are verified together.
var _scene_under_test: Node = null

const REQUIRED_PROOF_NODES := [
	"MixedUseBlock",
	"PrimaryRouteBand",
	"ShortcutRouteBand",
	"MunicipalGantry",
	"Storefront",
	"DistantRelay",
	"PracticalLights",
	"Storefront/HeroSignIcon",
]

const REQUIRED_TREATED_NODES := [
	"Runner",
	"CourierBike",
	"ScrapHauler",
	"PursuerPrototype",
	"ScrapWorker1",
	"UtilityCrawler",
	"CorrodedPanel",
]

const REQUIRED_FLAGS := [
	"stacked_mixed_use",
	"primary_route",
	"shortcut_route",
	"municipal_anchor",
	"storefront_family",
	"worker_treatment",
	"courier_bike_treatment",
	"courier_repair_panel",
	"utility_vehicle_treatment",
	"pursuit_vehicle_treatment",
	"pursuit_civic_livery",
	"utility_robot_treatment",
	"utility_robot_asset_marking",
	"interactable_treatment",
	"distant_landmark",
	"practical_lighting",
	"uses_retained_camera",
]

func _init() -> void:
	call_deferred("_run")

func _finish(exit_code: int) -> void:
	if is_instance_valid(_scene_under_test):
		_scene_under_test.queue_free()
		await process_frame
		await process_frame
	quit(exit_code)

func _fail(message: String) -> void:
	push_error("[GEARS_STYLE_PROOF_60] %s" % message)
	await _finish(1)

func _run() -> void:
	var toon_shader := load("res://materials/gears_toon.gdshader") as Shader
	var outline_shader := load("res://materials/gears_outline.gdshader") as Shader
	if toon_shader == null or outline_shader == null:
		await _fail("Lightweight toon/outline shader resources are missing or invalid")
		return

	var packed := load("res://scenes/prototype/scrap_test_block.tscn") as PackedScene
	if packed == null:
		await _fail("Could not load retained scrap_test_block.tscn")
		return

	_scene_under_test = packed.instantiate()
	root.add_child(_scene_under_test)
	await process_frame
	await physics_frame
	await process_frame

	var camera := _scene_under_test.get_node_or_null("ChinatownCamera3D") as Camera3D
	if camera == null or absf(camera.fov - 32.0) > 0.05:
		await _fail("Retained elevated 3/4 gameplay camera/FOV contract is missing")
		return

	var proof := _scene_under_test.get_node_or_null("GearsStyleProof")
	if proof == null or not proof.has_method("get_proof_contract"):
		await _fail("Main playable scene has no executable GearsStyleProof contract")
		return

	for child_name in REQUIRED_PROOF_NODES:
		if proof.get_node_or_null(child_name) == null:
			await _fail("Required proof composition node is missing: %s" % child_name)
			return

	for node_name in REQUIRED_TREATED_NODES:
		var treated := _scene_under_test.get_node_or_null(node_name)
		if treated == null or not treated.has_meta("gears_style_proof_treatment"):
			await _fail("Required production node did not receive bounded proof treatment: %s" % node_name)
			return

	var contract: Dictionary = proof.call("get_proof_contract")
	for flag in REQUIRED_FLAGS:
		if contract.get(flag, false) != true:
			await _fail("Proof contract flag is not satisfied: %s" % flag)
			return

	var graphics: Array = contract.get("graphic_families", [])
	for family in ["municipal", "commercial", "aftermarket", "asset_marking"]:
		if not graphics.has(family):
			await _fail("Graphic-design proof family missing: %s" % family)
			return

	var generated_meshes := int(contract.get("generated_mesh_instances", 9999))
	var outline_meshes := int(contract.get("outline_instances", 0))
	var practical_lights := int(contract.get("practical_light_count", 9999))
	if generated_meshes <= 0 or generated_meshes > 90:
		await _fail("Proof geometry exceeds bounded experiment budget: %d meshes" % generated_meshes)
		return
	if outline_meshes <= 0 or outline_meshes > 24:
		await _fail("Selective contour treatment is absent or no longer selective: %d outlines" % outline_meshes)
		return
	if practical_lights <= 0 or practical_lights > 6:
		await _fail("Practical lighting is absent or exceeds restrained proof budget: %d lights" % practical_lights)
		return

	if not proof.has_method("set_lighting_mode"):
		await _fail("Proof does not expose deterministic day/dusk comparison mode")
		return
	proof.call("set_lighting_mode", "dusk")
	await process_frame
	proof.call("set_lighting_mode", "day")
	await process_frame

	print("[GEARS_STYLE_PROOF_60] PASS meshes=%d outlines=%d lights=%d" % [generated_meshes, outline_meshes, practical_lights])
	await _finish(0)
