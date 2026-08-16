class_name SignalTuner
extends InteractableBase

# SignalTuner: Frequency Dial Mechanic for Echos in the Scrap
# State machine: DORMANT -> ATTRACTING -> READY -> TUNING -> LOCKED -> SPENT

signal frequency_changed(frequency: float, accuracy: float)
signal signal_locked(tuner: SignalTuner)

enum TunerState {
	DORMANT,
	ATTRACTING,
	READY,
	TUNING,
	LOCKED,
	SPENT
}

@export var target_frequency: float = 0.72
@export var current_frequency: float = 0.15
@export var lock_tolerance: float = 0.05
@export var dwell_time_required: float = 0.4

@onready var dial_mesh: MeshInstance3D = $MeshPivot/DialMesh
@onready var aura_mesh: MeshInstance3D = $MeshPivot/AuraMesh

var current_state: TunerState = TunerState.DORMANT
var _dwell_timer: float = 0.0
var _drag_start_freq: float = 0.0

const DRAG_SENSITIVITY: float = 0.003

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

func can_interact(_player_pos: Vector3) -> bool:
	return is_powered and current_state == TunerState.READY

func begin_interaction(_player_pos: Vector3) -> bool:
	if not can_interact(_player_pos):
		return false
	_drag_start_freq = current_frequency
	_set_state(TunerState.TUNING)
	return true

func tune_from_accum_px(accum_px: float) -> void:
	if current_state != TunerState.TUNING:
		return
	current_frequency = clampf(_drag_start_freq + accum_px * DRAG_SENSITIVITY, 0.0, 1.0)
	if dial_mesh:
		dial_mesh.rotation.y = current_frequency * TAU

func cancel_interaction() -> void:
	if current_state == TunerState.TUNING:
		_set_state(TunerState.READY if is_player_in_range else TunerState.ATTRACTING)

func _process(delta: float) -> void:
	if current_state == TunerState.TUNING:
		var accuracy: float = 1.0 - clamp(abs(current_frequency - target_frequency) / 0.5, 0.0, 1.0)
		frequency_changed.emit(current_frequency, accuracy)
		
		if abs(current_frequency - target_frequency) <= lock_tolerance:
			_dwell_timer += delta
			audio_event_triggered.emit("TUNER_NEAR_LOCK", global_position)
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
	audio_event_triggered.emit("TUNER_ROTATE", global_position)

func _lock_signal() -> void:
	_set_state(TunerState.LOCKED)
	audio_event_triggered.emit("SIGNAL_LOCK", global_position)
	signal_locked.emit(self)
	if aura_mesh:
		var mat := aura_mesh.get_surface_override_material(0) as StandardMaterial3D
		if mat:
			mat.albedo_color = Color(0.1, 0.9, 0.4, 0.8)
			mat.emission = Color(0.1, 0.9, 0.4, 1.0)

func _set_state(new_state: TunerState) -> void:
	if current_state == new_state:
		return
	current_state = new_state
	state_changed.emit(TunerState.keys()[new_state])
