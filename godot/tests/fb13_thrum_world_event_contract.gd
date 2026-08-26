extends RefCounted

const TOON_SHADER_PATH := "res://materials/gears_toon.gdshader"
const PRIMARY_RESONANCE_PATH := "GearsDistrictSlice01B/IndustrialFrontage/CivicUtilityPlate"
const SECONDARY_RESONANCE_PATH := "GearsDistrictSlice01B/IndustrialFrontage/UtilitySpine"

static func _count_colliders(node: Node) -> int:
	var count := 1 if node is CollisionShape3D else 0
	for child in node.get_children():
		count += _count_colliders(child)
	return count

static func _count_local_lights(node: Node) -> int:
	var count := 1 if node is OmniLight3D or node is SpotLight3D else 0
	for child in node.get_children():
		count += _count_local_lights(child)
	return count

static func _verify_toon_target(root: Node, path: String) -> String:
	var mesh := root.get_node_or_null(path) as MeshInstance3D
	if mesh == null:
		return "Required FB-13 resonance target missing: %s" % path
	var material := mesh.material_override as ShaderMaterial
	if material == null or material.shader == null:
		return "FB-13 resonance target has no shader material: %s" % path
	if material.shader.resource_path != TOON_SHADER_PATH:
		return "FB-13 resonance target is not using the approved toon shader: %s" % path
	return ""

static func verify(scene_root: Node) -> String:
	if scene_root == null:
		return "Playable scene root is missing"

	var event := scene_root.get_node_or_null("FB13ThrumWorldEvent")
	if event == null or not event.has_method("get_world_event_contract"):
		return "FB13ThrumWorldEvent production node/contract is missing"
	if _count_colliders(event) != 0:
		return "FB-13 thrum event must not add collision"
	if _count_local_lights(event) != 0:
		return "FB-13 thrum event must not add real-time local lights"

	var contract: Dictionary = event.call("get_world_event_contract")
	if contract.get("directive", "") != "thrum_spike":
		return "FB-13 world-event directive must be thrum_spike"
	if contract.get("actor", "") != "FB-13":
		return "FB-13 world-event actor identity is missing"
	if contract.get("zone", "") != "gears_industrial_frontage":
		return "FB-13 world-event zone identity is incorrect"
	if absf(float(contract.get("severity", -1.0)) - 0.30) > 0.001:
		return "FB-13 world-event severity must remain 0.30"
	if int(contract.get("ttl_msec", -1)) != 650:
		return "FB-13 world-event TTL must remain 650ms"
	if absf(float(contract.get("trigger_radius_m", 0.0)) - 5.5) > 0.001:
		return "FB-13 thrum trigger radius must remain 5.5m"
	if absf(float(contract.get("rearm_radius_m", 0.0)) - 8.0) > 0.001:
		return "FB-13 thrum rearm radius must remain 8.0m"
	if absf(float(contract.get("cooldown_sec", 0.0)) - 6.0) > 0.001:
		return "FB-13 thrum cooldown must remain 6.0s"
	if contract.get("adds_input", true) != false or contract.get("adds_mission_state", true) != false:
		return "FB-13 thrum event must not add input or mission state"
	if contract.get("primary_resonance_path", "") != PRIMARY_RESONANCE_PATH \
	or contract.get("secondary_resonance_path", "") != SECONDARY_RESONANCE_PATH:
		return "FB-13 thrum contract points at the wrong production mechanisms"

	for path in [PRIMARY_RESONANCE_PATH, SECONDARY_RESONANCE_PATH]:
		var target_error := _verify_toon_target(scene_root, path)
		if target_error != "":
			return target_error

	var player := scene_root.get_node_or_null("Runner") as Node3D
	var audio := scene_root.get_node_or_null("AudioManager") as AudioManager
	var primary := scene_root.get_node_or_null(PRIMARY_RESONANCE_PATH) as MeshInstance3D
	var secondary := scene_root.get_node_or_null(SECONDARY_RESONANCE_PATH) as MeshInstance3D
	if player == null or audio == null or primary == null or secondary == null:
		return "FB-13 thrum runtime dependencies are missing"

	var thrum_event_id := int(AudioManager.SoundEvent.get("FB13_THRUM", -1))
	if thrum_event_id < 0:
		return "AudioManager.SoundEvent.FB13_THRUM is missing"

	var original_player_position := player.global_position
	var original_primary_material := primary.material_override
	var original_secondary_material := secondary.material_override
	event.set_process(false)
	audio.reset_event_counts()
	audio.set_mix_state(AudioManager.MixState.CALM)

	# Entering from outside must trigger exactly once.
	player.global_position = primary.global_position + Vector3(0.0, 0.0, 10.0)
	event.call("_process", 0.10)
	player.global_position = primary.global_position + Vector3(0.0, 0.0, 1.0)
	event.call("_process", 0.10)
	if int(event.get("trigger_count")) != 1:
		return "FB-13 thrum did not trigger exactly once on zone entry"
	if audio.get_event_count(thrum_event_id) != 1:
		return "FB-13 thrum did not route exactly one event through retained AudioManager"
	if primary.material_override == original_primary_material or secondary.material_override == original_secondary_material:
		return "FB-13 thrum did not temporarily duplicate both resonance materials"

	# Staying in-zone must not retrigger, and both exact originals must be restored after TTL.
	event.call("_process", 0.10)
	if int(event.get("trigger_count")) != 1:
		return "FB-13 thrum retriggered while the player remained inside the zone"
	await scene_root.get_tree().create_timer(0.75).timeout
	if primary.material_override != original_primary_material or secondary.material_override != original_secondary_material:
		return "FB-13 thrum failed to restore the exact original mechanism materials after TTL"

	# Leave + cooldown + re-entry must permit a second event.
	player.global_position = primary.global_position + Vector3(0.0, 0.0, 10.0)
	event.call("_process", 6.10)
	player.global_position = primary.global_position + Vector3(0.0, 0.0, 1.0)
	event.call("_process", 0.10)
	if int(event.get("trigger_count")) != 2 or audio.get_event_count(thrum_event_id) != 2:
		return "FB-13 thrum did not rearm after leaving the zone and clearing cooldown"
	await scene_root.get_tree().create_timer(0.75).timeout

	# Priority audio states suppress without consuming the armed state.
	player.global_position = primary.global_position + Vector3(0.0, 0.0, 10.0)
	event.call("_process", 6.10)
	player.global_position = primary.global_position + Vector3(0.0, 0.0, 1.0)
	for blocked_state in [
		AudioManager.MixState.DISTURBANCE,
		AudioManager.MixState.PURSUIT_PRESSURE,
		AudioManager.MixState.MEMORY_ECHO,
	]:
		audio.current_mix_state = blocked_state
		event.call("_process", 0.10)
		if int(event.get("trigger_count")) != 2:
			return "FB-13 thrum consumed or triggered during retained priority audio state %s" % blocked_state

	audio.current_mix_state = AudioManager.MixState.CALM
	event.call("_process", 0.10)
	if int(event.get("trigger_count")) != 3 or audio.get_event_count(thrum_event_id) != 3:
		return "FB-13 thrum failed to remain armed after priority-state suppression"
	await scene_root.get_tree().create_timer(0.75).timeout

	player.global_position = original_player_position
	audio.current_mix_state = AudioManager.MixState.CALM
	event.set_process(true)
	return ""
