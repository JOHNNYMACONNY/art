class_name SilentCoreInteractable
extends InteractableBase

## Bounded Mission 03 shrine interaction. Target selection remains owned by the
## production controller; this node only owns its powered/activated state.

signal silent_core_activated

var activation_count: int = 0

func _ready() -> void:
	interaction_radius = 2.6
	sensory_radius = 5.5
	interaction_priority = 1.5
	is_powered = false
	_build_visual_marker()

func can_interact(player_pos: Vector3) -> bool:
	return activation_count == 0 and super.can_interact(player_pos)

func begin_interaction(player_pos: Vector3) -> bool:
	if not can_interact(player_pos):
		return false
	activation_count += 1
	is_powered = false
	is_player_in_range = false
	state_changed.emit("ACTIVATED")
	interaction_completed.emit()
	silent_core_activated.emit()
	return true

func set_mission_powered(powered: bool) -> void:
	is_powered = powered and activation_count == 0
	if not is_powered:
		is_player_in_range = false

func reset_for_replay() -> void:
	activation_count = 0
	is_powered = false
	is_player_in_range = false
	state_changed.emit("LOCKED")

func _build_visual_marker() -> void:
	var body := MeshInstance3D.new()
	body.name = "SilentCoreMarker"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.7
	mesh.bottom_radius = 0.9
	mesh.height = 1.1
	mesh.radial_segments = 12
	body.mesh = mesh
	body.position = Vector3(0, 0.55, 0)

	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.08, 0.12, 0.16, 1.0)
	material.metallic = 0.75
	material.roughness = 0.35
	material.emission_enabled = true
	material.emission = Color(0.08, 0.4, 0.48, 1.0)
	material.emission_energy_multiplier = 0.8
	body.material_override = material
	add_child(body)

	var label := Label3D.new()
	label.name = "SilentCoreLabel"
	label.text = "HS-7 // SILENT CORE"
	label.position = Vector3(0, 1.45, 0)
	label.font_size = 22
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
