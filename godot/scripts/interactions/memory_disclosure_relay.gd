class_name MemoryDisclosureRelay
extends InteractableBase

## Bounded P16 physical choice target at the existing Silent Core.
## This node owns only local choice presentation and one-shot selection.

signal choice_selected(choice_id: String)

const TOON_SHADER_PATH := "res://materials/gears_toon.gdshader"
const SOOT := Color(0.094, 0.129, 0.149, 1.0)
const OFF_WHITE := Color(0.843, 0.824, 0.765, 1.0)
const SIGNAL_CYAN := Color(0.486, 0.812, 0.816, 1.0)
const HAZARD_AMBER := Color(0.95, 0.58, 0.16, 1.0)

var choice_id: String = ""
var display_text: String = "MEMORY RELAY"
var resolution: String = "DORMANT"
var _toon_shader: Shader = null
var _label: Label3D = null
var _status_label: Label3D = null
var _signal: MeshInstance3D = null

func _ready() -> void:
	interaction_radius = 2.25
	sensory_radius = 5.0
	interaction_priority = 1.65
	is_powered = false
	_build_visual()
	_refresh_visual()

func configure_relay(new_choice_id: String, new_display_text: String) -> void:
	choice_id = new_choice_id
	display_text = new_display_text
	_refresh_visual()

func can_interact(player_pos: Vector3) -> bool:
	return resolution == "READY" and super.can_interact(player_pos)

func begin_interaction(player_pos: Vector3) -> bool:
	if not can_interact(player_pos):
		return false
	resolution = "SELECTED"
	is_powered = false
	is_player_in_range = false
	_refresh_visual()
	state_changed.emit("SELECTED")
	interaction_completed.emit()
	choice_selected.emit(choice_id)
	return true

func set_choice_ready(ready: bool) -> void:
	if resolution == "RELEASED" or resolution == "SEALED" or resolution == "LOCKED":
		is_powered = false
		return
	resolution = "READY" if ready else "DORMANT"
	is_powered = ready
	if not ready:
		is_player_in_range = false
	_refresh_visual()
	state_changed.emit(resolution)

func resolve_choice(selected_choice_id: String) -> void:
	is_powered = false
	is_player_in_range = false
	if choice_id == selected_choice_id:
		resolution = "RELEASED" if choice_id == "RELEASE" else "SEALED"
	else:
		resolution = "LOCKED"
	_refresh_visual()
	state_changed.emit(resolution)

func reset_for_replay() -> void:
	resolution = "DORMANT"
	is_powered = false
	is_player_in_range = false
	_refresh_visual()
	state_changed.emit("DORMANT")

func get_status() -> Dictionary:
	return {
		"choice_id": choice_id,
		"resolution": resolution,
		"is_powered": is_powered,
		"display_text": display_text,
	}

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

func _build_visual() -> void:
	var housing_mesh := BoxMesh.new()
	housing_mesh.size = Vector3(0.62, 0.78, 0.32)
	var housing := MeshInstance3D.new()
	housing.name = "RelayHousing"
	housing.mesh = housing_mesh
	housing.position = Vector3(0.0, 0.39, 0.0)
	housing.material_override = _toon_material(OFF_WHITE)
	add_child(housing)

	var spine_mesh := BoxMesh.new()
	spine_mesh.size = Vector3(0.16, 0.62, 0.38)
	var spine := MeshInstance3D.new()
	spine.name = "RelaySpine"
	spine.mesh = spine_mesh
	spine.position = Vector3(0.19, 0.36, 0.0)
	spine.material_override = _toon_material(SOOT)
	add_child(spine)

	var signal_mesh := BoxMesh.new()
	signal_mesh.size = Vector3(0.34, 0.09, 0.04)
	_signal = MeshInstance3D.new()
	_signal.name = "RelaySignal"
	_signal.mesh = signal_mesh
	_signal.position = Vector3(-0.05, 0.48, 0.18)
	add_child(_signal)

	_label = Label3D.new()
	_label.name = "RelayChoiceLabel"
	_label.position = Vector3(0.0, 1.05, 0.0)
	_label.font_size = 15
	_label.outline_size = 6
	_label.modulate = OFF_WHITE
	_label.outline_modulate = SOOT
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_label)

	_status_label = Label3D.new()
	_status_label.name = "RelayStatusLabel"
	_status_label.position = Vector3(0.0, 0.86, 0.0)
	_status_label.font_size = 12
	_status_label.outline_size = 5
	_status_label.modulate = SIGNAL_CYAN
	_status_label.outline_modulate = SOOT
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(_status_label)

func _refresh_visual() -> void:
	if _label != null:
		_label.text = display_text
	if _status_label != null:
		_status_label.text = resolution
	if _signal != null:
		var color := SIGNAL_CYAN
		var energy := 0.12
		if resolution == "READY":
			color = HAZARD_AMBER
			energy = 0.72
		elif resolution == "RELEASED" or resolution == "SEALED":
			energy = 0.55
		elif resolution == "LOCKED":
			color = SOOT
			energy = 0.02
		_signal.material_override = _toon_material(color, energy)
