class_name SilentCoreInteractable
extends InteractableBase

## Bounded Mission 03 infrastructure interaction. Target selection remains owned
## by the production controller; this node only owns powered/activated state.

signal silent_core_activated

const TOON_SHADER_PATH := "res://materials/gears_toon.gdshader"
const SOOT := Color(0.094, 0.129, 0.149, 1.0)
const OFF_WHITE := Color(0.843, 0.824, 0.765, 1.0)
const SIGNAL_CYAN := Color(0.486, 0.812, 0.816, 1.0)

var activation_count: int = 0
var _toon_shader: Shader = null

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

func _toon_material(color: Color, emission_energy: float = 0.0) -> ShaderMaterial:
	if _toon_shader == null:
		_toon_shader = load(TOON_SHADER_PATH) as Shader
	var material := ShaderMaterial.new()
	material.shader = _toon_shader
	material.set_shader_parameter("base_color", color)
	material.set_shader_parameter("roughness_value", 0.84)
	if emission_energy > 0.0:
		material.set_shader_parameter("emission_color", color)
		material.set_shader_parameter("emission_energy", emission_energy)
	return material

func _add_box(mesh_name: String, size: Vector3, position: Vector3, color: Color, emission_energy: float = 0.0) -> MeshInstance3D:
	var box := BoxMesh.new()
	box.size = size
	var instance := MeshInstance3D.new()
	instance.name = mesh_name
	instance.mesh = box
	instance.position = position
	instance.material_override = _toon_material(color, emission_energy)
	add_child(instance)
	return instance

func _build_visual_marker() -> void:
	# Ordinary obsolete utility hardware first; signal/memory is sparse punctuation.
	_add_box("SilentCoreHousing", Vector3(0.95, 0.95, 0.25), Vector3(0.0, 0.62, -0.12), OFF_WHITE)
	_add_box("SilentCoreStructuralCore", Vector3(0.62, 0.72, 0.32), Vector3(0.0, 0.58, 0.08), SOOT)
	_add_box("SilentCoreSignalSlot", Vector3(0.38, 0.12, 0.05), Vector3(0.0, 0.62, 0.27), SIGNAL_CYAN, 0.52)
	_add_box("SilentCoreRemovedPlateScar", Vector3(0.24, 0.18, 0.04), Vector3(0.30, 0.82, 0.27), SOOT)

	var label := Label3D.new()
	label.name = "SilentCoreLabel"
	label.text = "HS-7 // CORE"
	label.position = Vector3(0, 1.25, 0)
	label.font_size = 18
	label.outline_size = 7
	label.modulate = OFF_WHITE
	label.outline_modulate = SOOT
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
