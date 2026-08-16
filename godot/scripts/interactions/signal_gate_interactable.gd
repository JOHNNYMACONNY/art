class_name SignalGateInteractable
extends InteractableBase

# Echos in the Scrap - Signal Gate Interactable Node (V5)
# Features state machine (DORMANT -> READY -> TRIGGERING -> TRIGGERED) and pursuit counterplay

signal gate_trigger_started
signal gate_triggered
signal gate_state_changed(new_state: String)

enum GateState {
	DORMANT,
	READY,
	TRIGGERING,
	TRIGGERED
}

@export var activation_time: float = 0.5

@onready var signal_light: OmniLight3D = $SignalLight
@onready var indicator_mesh: MeshInstance3D = $IndicatorMesh

var current_state: GateState = GateState.DORMANT

func _ready() -> void:
	interaction_radius = 4.0
	interaction_priority = 3.0
	is_powered = false
	_update_visual_state()

func set_pursuit_active(active: bool) -> void:
	if current_state == GateState.TRIGGERED or current_state == GateState.TRIGGERING:
		return
		
	if active:
		current_state = GateState.READY
		is_powered = true
		gate_state_changed.emit("READY")
	else:
		current_state = GateState.DORMANT
		is_powered = false
		gate_state_changed.emit("DORMANT")
	_update_visual_state()

func can_interact(player_pos: Vector3) -> bool:
	return current_state == GateState.READY and is_powered and global_position.distance_to(player_pos) <= interaction_radius

func begin_interaction(_player_pos: Vector3) -> bool:
	if current_state != GateState.READY:
		return false
		
	current_state = GateState.TRIGGERING
	gate_state_changed.emit("TRIGGERING")
	gate_trigger_started.emit()
	_update_visual_state()
	
	get_tree().create_timer(activation_time).timeout.connect(func():
		if current_state == GateState.TRIGGERING:
			trigger_gate()
	)
	return true

func trigger_gate() -> void:
	if current_state == GateState.TRIGGERED:
		return
		
	current_state = GateState.TRIGGERED
	is_powered = false
	gate_state_changed.emit("TRIGGERED")
	gate_triggered.emit()
	_update_visual_state()

func _update_visual_state() -> void:
	if not signal_light:
		return
		
	match current_state:
		GateState.DORMANT:
			signal_light.light_color = Color(0.2, 0.2, 0.25, 1.0) # Dim neutral
			signal_light.light_energy = 0.5
		GateState.READY:
			signal_light.light_color = Color(0.1, 0.9, 1.0, 1.0) # Bright cyan pulse
			signal_light.light_energy = 3.5
		GateState.TRIGGERING:
			signal_light.light_color = Color(1.0, 1.0, 1.0, 1.0) # Intense white charge
			signal_light.light_energy = 6.0
		GateState.TRIGGERED:
			signal_light.light_color = Color(0.1, 0.4, 0.5, 1.0) # Dim spent cyan
			signal_light.light_energy = 1.0
