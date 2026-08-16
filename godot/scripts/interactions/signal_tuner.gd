class_name SignalTuner
extends Area3D

# SignalTuner: Electrical / Perceptual Frequency Dial Mechanic for Echos in the Scrap
# State machine: DORMANT -> ATTRACTING -> READY -> TUNING -> LOCKED -> SPENT

signal frequency_changed(frequency: float, accuracy: float)
signal signal_locked(tuner: SignalTuner)
signal proximity_changed(in_range: bool, tuner: SignalTuner)
signal state_changed(new_state_name: String)
signal audio_event_triggered(event_name: String)

enum TunerState {
	DORMANT,
	ATTRACTING,
	READY,
	TUNING,
	LOCKED,
	SPENT
}

@export var sensory_radius: float = 6.0
@export var interaction_radius: float = 2.5
@export var target_frequency: float = 0.72
@export var current_frequency: float = 0.15
@export var lock_tolerance: float = 0.05
@export var dwell_time_required: float = 0.4

@onready var dial_mesh: MeshInstance3D = $MeshPivot/DialMesh
@onready var aura_mesh: MeshInstance3D = $MeshPivot/AuraMesh

var current_state: TunerState = TunerState.DORMANT
var is_player_in_range: bool = false
var _dwell_timer: float = 0.0
var _player_ref: Node3D = null

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func update_player_distance(player_pos: Vector3) -> void:
	if current_state == TunerState.LOCKED or current_state == TunerState.SPENT:
		return
		
	var dist := global_position.distance_to(player_pos)
	var was_in_range := is_player_in_range
	is_player_in_range = (dist <= interaction_radius)
	
	if is_player_in_range != was_in_range:
		proximity_changed.emit(is_player_in_range, self)
		
	if current_state != TunerState.TUNING:
		if is_player_in_range:
			_set_state(TunerState.READY)
		elif dist <= sensory_radius:
			_set_state(TunerState.ATTRACTING)
		else:
			_set_state(TunerState.DORMANT)

func begin_tuning() -> bool:
	if current_state != TunerState.READY:
		return false
	_set_state(TunerState.TUNING)
	return true

func cancel_tuning() -> void:
	if current_state == TunerState.TUNING:
		_set_state(TunerState.READY if is_player_in_range else TunerState.ATTRACTING)

func _process(delta: float) -> void:
	if current_state == TunerState.TUNING:
		var accuracy: float = 1.0 - clamp(abs(current_frequency - target_frequency) / 0.5, 0.0, 1.0)
		frequency_changed.emit(current_frequency, accuracy)
		
		if abs(current_frequency - target_frequency) <= lock_tolerance:
			_dwell_timer += delta
			audio_event_triggered.emit("TUNER_NEAR_LOCK")
			if _dwell_timer >= dwell_time_required:
				_lock_signal()
		else:
			_dwell_timer = max(0.0, _dwell_timer - delta * 2.0)

func tune_dial(delta_freq: float) -> void:
	if current_state != TunerState.TUNING:
		return
	current_frequency = clamp(current_frequency + delta_freq, 0.0, 1.0)
	if dial_mesh:
		dial_mesh.rotation.y = current_frequency * TAU
	audio_event_triggered.emit("TUNER_ROTATE")

func _lock_signal() -> void:
	_set_state(TunerState.LOCKED)
	audio_event_triggered.emit("SIGNAL_LOCK")
	signal_locked.emit(self)
	if aura_mesh:
		var mat := aura_mesh.get_surface_override_material(0) as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(0.1, 0.9, 0.4, 0.8)
			mat.emission = Color(0.1, 0.9, 0.4, 1.0)

func _on_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D:
		_player_ref = body

func _on_body_exited(body: Node3D) -> void:
	if body == _player_ref:
		_player_ref = null

func _set_state(new_state: TunerState) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	state_changed.emit(TunerState.keys()[new_state])
