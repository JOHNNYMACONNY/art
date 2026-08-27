extends RefCounted

## Open World Expansion 01E: retire the completed Issue #60 proof composition
## from production rendering while preserving the proof artifact/controller and
## the real district slice.

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
