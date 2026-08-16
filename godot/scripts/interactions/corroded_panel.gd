class_name CorrodedPanel
extends Area3D

# Corroded Panel Terminal & Extraction Gesture State Machine
# Sequence: Approach -> Magnetism Highlight -> Action -> Peel Cover -> Expose Core -> Extract

signal magnetism_changed(is_highlighted: bool, panel: CorrodedPanel)
signal extraction_step_changed(step_name: String)
signal extraction_completed
signal audio_event_triggered(event_name: String)

enum Step {
	IDLE,
	APPROACHED,
	PEELING,
	EXPOSED,
	EXTRACTED
}

@export var magnetism_radius: float = 3.5

@onready var panel_mesh: MeshInstance3D = $PanelMesh
@onready var core_mesh: MeshInstance3D = $CoreMesh
@onready var highlight_ring: MeshInstance3D = $HighlightRing
@onready var spark_particles: GPUParticles3D = $SparkParticles

var current_step: Step = Step.IDLE
var is_player_in_range: bool = false
var _player_ref: Node3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if highlight_ring:
		highlight_ring.visible = false
	if core_mesh:
		core_mesh.scale = Vector3(0.1, 0.1, 0.1)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		is_player_in_range = true
		_player_ref = body
		if current_step == Step.IDLE:
			current_step = Step.APPROACHED
			if highlight_ring:
				highlight_ring.visible = true
			emit_signal("magnetism_changed", true, self)
			emit_signal("audio_event_triggered", "PROXIMITY_HUM")

func _on_body_exited(body: Node3D) -> void:
	if body == _player_ref:
		is_player_in_range = false
		_player_ref = null
		if current_step == Step.APPROACHED:
			current_step = Step.IDLE
			if highlight_ring:
				highlight_ring.visible = false
			emit_signal("magnetism_changed", false, self)

# Starts extraction gesture loop (1-2 sec) - strictly requires APPROACHED state in range
func trigger_action() -> bool:
	if is_player_in_range and current_step == Step.APPROACHED:
		current_step = Step.PEELING
		emit_signal("extraction_step_changed", "PEEL_PANEL")
		emit_signal("audio_event_triggered", "PANEL_PEEL")
		if spark_particles:
			spark_particles.emitting = true
		return true
	return false

# Progress peel gesture (drag panel off)
func progress_peel(amount: float) -> void:
	if current_step == Step.PEELING:
		if panel_mesh:
			panel_mesh.rotation.x = lerp(panel_mesh.rotation.x, deg_to_rad(-75.0), amount)
			panel_mesh.position.z = lerp(panel_mesh.position.z, 0.8, amount)
		if amount >= 0.85:
			current_step = Step.EXPOSED
			if core_mesh:
				core_mesh.scale = Vector3(1.0, 1.0, 1.0)
			emit_signal("extraction_step_changed", "EXPOSE_CORE")
			emit_signal("audio_event_triggered", "CORE_PULL")

# Finalize core extraction gesture (tap/pull glowing core)
func complete_extraction() -> void:
	if current_step == Step.EXPOSED:
		current_step = Step.EXTRACTED
		if core_mesh:
			core_mesh.visible = false
		if highlight_ring:
			highlight_ring.visible = false
		emit_signal("extraction_step_changed", "EXTRACTED")
		emit_signal("extraction_completed")
		emit_signal("audio_event_triggered", "COMPLETION")
		emit_signal("audio_event_triggered", "SPARK")
		if spark_particles:
			spark_particles.emitting = true
