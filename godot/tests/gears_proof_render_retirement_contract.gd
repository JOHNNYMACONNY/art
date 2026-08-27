extends RefCounted

## Open World Expansion 01E + dusk practical repair: retire the completed Issue
## #60 proof composition from production rendering while preserving its
## controller/treatments and moving the required dusk practicals into the real
## production district.

const DAY_ENERGIES := {
	"StoreWorkLamp": 1.0,
	"GantryServiceLamp": 0.8,
	"RelayMarkerLamp": 0.35,
}
const DUSK_ENERGIES := {
	"StoreWorkLamp": 1.55,
	"GantryServiceLamp": 1.24,
	"RelayMarkerLamp": 0.54,
}

static func _approx_equal(a: float, b: float) -> bool:
	return absf(a - b) <= 0.001

static func _verify_mode(proof: Node3D, practicals: Node3D, mode: String, expected: Dictionary) -> String:
	proof.call("set_lighting_mode", mode)
	for light_name in expected:
		var light := practicals.get_node_or_null(str(light_name)) as OmniLight3D
		if light == null:
			return "Production practical light is missing: %s" % light_name
		if not _approx_equal(light.light_energy, float(expected[light_name])):
			return "%s energy mismatch in %s mode: %.3f" % [light_name, mode, light.light_energy]
	return ""

static func verify(scene_root: Node) -> String:
	if scene_root == null:
		return "Playable scene root is missing"

	var proof := scene_root.get_node_or_null("GearsStyleProof") as Node3D
	if proof == null:
		return "Mounted GearsStyleProof artifact is missing"
	if not proof.has_method("get_proof_contract") or not proof.has_method("set_lighting_mode"):
		return "Mounted GearsStyleProof no longer exposes its reference contract"

	var district := scene_root.get_node_or_null("GearsDistrictSlice01B") as Node3D
	if district == null:
		return "Production GearsDistrictSlice01B is missing"
	if not district.visible:
		return "Production GearsDistrictSlice01B must remain visible"

	if proof.visible:
		return "Proof-only GearsStyleProof composition is still visible in production"

	for node_path in [
		"MixedUseBlock",
		"PrimaryRouteBand",
		"ShortcutRouteBand",
		"MunicipalGantry",
		"Storefront",
		"DistantRelay",
		"PracticalLights",
	]:
		if proof.get_node_or_null(node_path) == null:
			return "Retired proof artifact lost reference node: %s" % node_path

	var proof_practicals := proof.get_node_or_null("PracticalLights") as Node3D
	if proof_practicals == null or proof_practicals.get_child_count() != 3:
		return "Standalone proof must retain exactly three reference practical lights"

	var production_practicals := district.get_node_or_null("PracticalLights") as Node3D
	if production_practicals == null:
		return "Production district is missing PracticalLights"
	if production_practicals.get_child_count() != 3:
		return "Production district must own exactly three practical lights"

	var district_contract: Dictionary = district.call("get_production_contract")
	if int(district_contract.get("local_lights", -1)) != 0:
		return "Historical 01B local-light budget must remain zero"
	if int(district_contract.get("current_local_lights", -1)) != 3:
		return "Current district must report exactly three production practical lights"
	if int(district_contract.get("extension_local_lights", -1)) != 3:
		return "Later additive lighting must report exactly three extension lights"

	for light_name in DAY_ENERGIES:
		var light := production_practicals.get_node_or_null(str(light_name)) as OmniLight3D
		if light == null:
			return "Production practical light is missing: %s" % light_name
		if not light.visible:
			return "Production practical light must remain visible: %s" % light_name
		if light.shadow_enabled:
			return "Production practical light must remain non-shadow-casting: %s" % light_name

	var day_error := _verify_mode(proof, production_practicals, "day", DAY_ENERGIES)
	if not day_error.is_empty():
		return day_error
	var dusk_error := _verify_mode(proof, production_practicals, "dusk", DUSK_ENERGIES)
	if not dusk_error.is_empty():
		return dusk_error
	# Leave the shared production scene in its default day state after contract verification.
	proof.call("set_lighting_mode", "day")

	for actor_path in [
		"Runner",
		"CourierBike",
		"ScrapHauler",
		"PursuerPrototype",
		"ScrapWorker1",
		"UtilityCrawler",
		"CorrodedPanel",
	]:
		var actor := scene_root.get_node_or_null(actor_path)
		if actor == null or not actor.has_meta("gears_style_proof_treatment"):
			return "Retiring proof rendering removed style treatment from %s" % actor_path

	return ""
