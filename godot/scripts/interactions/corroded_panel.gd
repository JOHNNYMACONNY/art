class_name CorrodedPanel
extends InteractableBase

# Corroded Panel Terminal & Extraction Gesture State Machine
# Sequence: Approach -> Magnetism Highlight -> Action -> Peel Cover -> Expose Core -> Extract

signal magnetism_changed(is_highlighted: bool, panel: CorrodedPanel)
signal extraction_step_changed(step_name: String)
signal extraction_completed

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
var _player_ref: Node3D = null

func _ready() -> void:
	is_powered = false # Unpowered until SignalTuner locked!
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	if highlight_ring:
		highlight_ring.visible = false
	if core_mesh:
		core_mesh.scale = Vector3(0.1, 0.1, 0.1)

func power_on() -> void:
	is_powered = true
	audio_event_triggered.emit("PANEL_POWERED", global_position)
	if is_player_in_range and current_step == Step.IDLE:
		current_step = Step.APPROACHED
		if highlight_ring:
			highlight_ring.visible = true
		magnetism_changed.emit(true, self)

func can_interact(_player_pos: Vector3) -> bool:
	return is_powered and current_step == Step.APPROACHED

func begin_interaction(_player_pos: Vector3) -> bool:
	return trigger_action()

func cancel_interaction() -> void:
	if current_step == Step.PEELING:
		current_step = Step.APPROACHED if is_player_in_range else Step.IDLE

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		is_player_in_range = true
		_player_ref = body
		if current_step == Step.IDLE and is_powered:
			current_step = Step.APPROACHED
			if highlight_ring:
				highlight_ring.visible = true
			magnetism_changed.emit(true, self)
			audio_event_triggered.emit("PROXIMITY_HUM", global_position)

func _on_body_exited(body: Node3D) -> void:
	if body == _player_ref:
		is_player_in_range = false
		_player_ref = null
		if current_step == Step.APPROACHED:
			current_step = Step.IDLE
			if highlight_ring:
				highlight_ring.visible = false
			magnetism_changed.emit(false, self)

# Starts extraction gesture loop - strictly requires is_powered and APPROACHED state
func trigger_action() -> bool:
	if is_player_in_range and current_step == Step.APPROACHED and is_powered:
		current_step = Step.PEELING
		extraction_step_changed.emit("PEEL_PANEL")
		audio_event_triggered.emit("PANEL_PEEL", global_position)
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
			extraction_step_changed.emit("EXPOSE_CORE")
			audio_event_triggered.emit("CORE_PULL", global_position)

# Finalize core extraction gesture (tap/pull glowing core)
func complete_extraction() -> void:
	if current_step == Step.EXPOSED:
		current_step = Step.EXTRACTED
		if core_mesh:
			core_mesh.visible = false
		if highlight_ring:
			highlight_ring.visible = false
		extraction_step_changed.emit("EXTRACTED")
		extraction_completed.emit()
		audio_event_triggered.emit("COMPLETION", global_position)
		audio_event_triggered.emit("SPARK", global_position)
		if spark_particles:
			spark_particles.emitting = true
