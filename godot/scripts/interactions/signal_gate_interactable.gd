class_name SignalGateInteractable
extends InteractableBase

# Echos in the Scrap - Signal Gate Interactable Node (V5.1 Physical Barrier & Route Switch)
# Features physical swinging scrap barrier mesh, collision shape blocking, and pursuit-only activation

signal gate_trigger_started
signal gate_triggered
signal gate_state_changed(new_state: String)

enum GateState {
	DORMANT,
	READY,
	TRIGGERING,
	TRIGGERED
}

@export var activation_time: float = 0.4

@onready var signal_light: OmniLight3D = $SignalLight
@onready var indicator_mesh: MeshInstance3D = $IndicatorMesh
@onready var barrier_pivot: Node3D = $BarrierPivot
@onready var barrier_body: StaticBody3D = $BarrierPivot/BarrierBody
@onready var barrier_collision: CollisionShape3D = $BarrierPivot/BarrierBody/CollisionShape3D

var current_state: GateState = GateState.DORMANT

func _ready() -> void:
	interaction_radius = 6.0
	interaction_priority = 4.0
	is_powered = false
	if barrier_collision:
		barrier_collision.disabled = true
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

@onready var sweep_area: Area3D = $BarrierPivot/SweepArea

func is_sweep_occupied() -> bool:
	if not sweep_area:
		return false
	for body in sweep_area.get_overlapping_bodies():
		if body != barrier_body and (body is CharacterBody3D or body.name == "Runner" or body.name == "CourierBike"):
			return true
	return false

func trigger_gate() -> void:
	if current_state == GateState.TRIGGERED:
		return
		
	current_state = GateState.TRIGGERED
	is_powered = false
	if barrier_collision:
		barrier_collision.disabled = true
		
	# Animate physical barrier swinging 90 deg across main scrap lane over 0.3s
	if barrier_pivot:
		var tween := create_tween()
		tween.tween_property(barrier_pivot, "rotation:y", deg_to_rad(90.0), 0.3)
		tween.finished.connect(func():
			print("[GATE] Physical scrap barrier arm swing completed! Verifying sweep safety...")
			_try_enable_collision()
		)
		
	gate_triggered.emit()
	_update_visual_state()

func _try_enable_collision() -> void:
	if is_sweep_occupied():
		print("[GATE] Safety sweep volume occupied! Delaying barrier collision enablement...")
		get_tree().create_timer(0.1).timeout.connect(_try_enable_collision)
	else:
		if barrier_collision:
			barrier_collision.disabled = false
			print("[GATE] Physical scrap barrier arm locked in solid place!")

func _update_visual_state() -> void:
	if not signal_light:
		return
		
	match current_state:
		GateState.DORMANT:
			signal_light.light_color = Color(0.25, 0.22, 0.15, 1.0) # Dim amber
			signal_light.light_energy = 0.5
		GateState.READY:
			signal_light.light_color = Color(0.1, 0.9, 1.0, 1.0) # Bright cyan pulse
			signal_light.light_energy = 3.5
		GateState.TRIGGERING:
			signal_light.light_color = Color(1.0, 1.0, 1.0, 1.0) # Intense white charge
			signal_light.light_energy = 6.0
		GateState.TRIGGERED:
			signal_light.light_color = Color(0.2, 0.35, 0.4, 1.0) # Dim cyan spent
			signal_light.light_energy = 1.0
