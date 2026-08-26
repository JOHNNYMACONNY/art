extends Node

## Bounded authored FB-13 world event. This node owns only local proximity,
## cooldown/hysteresis, one retained AudioManager event call, and temporary
## material pulse/restore on two existing industrial mechanism meshes.

signal thrum_triggered(event_payload: Dictionary)

const DIRECTIVE := "thrum_spike"
const ACTOR := "FB-13"
const ZONE := "gears_industrial_frontage"
const SEVERITY := 0.30
const TTL_MSEC := 650
const TTL_SEC := 0.65
const TRIGGER_RADIUS_M := 5.5
const REARM_RADIUS_M := 8.0
const COOLDOWN_SEC := 6.0
const PULSE_EMISSION_ENERGY := 0.72

const PLAYER_PATH := "../Runner"
const AUDIO_MANAGER_PATH := "../AudioManager"
const PRIMARY_RESONANCE_PATH := "../GearsDistrictSlice01B/IndustrialFrontage/CivicUtilityPlate"
const SECONDARY_RESONANCE_PATH := "../GearsDistrictSlice01B/IndustrialFrontage/UtilitySpine"

var trigger_count: int = 0
var last_event: Dictionary = {}

var _player: Node3D = null
var _audio: AudioManager = null
var _primary: MeshInstance3D = null
var _secondary: MeshInstance3D = null
var _armed: bool = true
var _cooldown_remaining: float = 0.0
var _pulse_generation: int = 0

func _ready() -> void:
	_resolve_dependencies()

func _resolve_dependencies() -> void:
	_player = get_node_or_null(PLAYER_PATH) as Node3D
	_audio = get_node_or_null(AUDIO_MANAGER_PATH) as AudioManager
	_primary = get_node_or_null(PRIMARY_RESONANCE_PATH) as MeshInstance3D
	_secondary = get_node_or_null(SECONDARY_RESONANCE_PATH) as MeshInstance3D

func _has_dependencies() -> bool:
	return is_instance_valid(_player) \
	and is_instance_valid(_audio) \
	and is_instance_valid(_primary) \
	and is_instance_valid(_secondary)

func _process(delta: float) -> void:
	if not _has_dependencies():
		_resolve_dependencies()
		if not _has_dependencies():
			return

	_cooldown_remaining = maxf(0.0, _cooldown_remaining - maxf(delta, 0.0))
	var distance := _player.global_position.distance_to(_primary.global_position)
	if distance >= REARM_RADIUS_M:
		_armed = true

	if not _armed or _cooldown_remaining > 0.0 or distance > TRIGGER_RADIUS_M:
		return
	if not _audio_priority_allows_thrum():
		return
	_trigger_thrum()

func _audio_priority_allows_thrum() -> bool:
	if not is_instance_valid(_audio):
		return false
	return _audio.current_mix_state not in [
		AudioManager.MixState.DISTURBANCE,
		AudioManager.MixState.PURSUIT_PRESSURE,
		AudioManager.MixState.MEMORY_ECHO,
	]

func _trigger_thrum() -> void:
	_armed = false
	_cooldown_remaining = COOLDOWN_SEC
	trigger_count += 1
	last_event = {
		"directive": DIRECTIVE,
		"actor": ACTOR,
		"zone": ZONE,
		"severity": SEVERITY,
		"ttl_msec": TTL_MSEC,
		"trigger_index": trigger_count,
	}

	_audio.play_event(AudioManager.SoundEvent.FB13_THRUM, _primary.global_position)
	_pulse_generation += 1
	var generation := _pulse_generation
	_pulse_mesh(_primary, generation)
	_pulse_mesh(_secondary, generation)
	thrum_triggered.emit(last_event.duplicate(true))

func _pulse_mesh(mesh: MeshInstance3D, generation: int) -> void:
	if mesh == null:
		return
	var original := mesh.material_override as ShaderMaterial
	if original == null or original.shader == null:
		return
	var pulse := original.duplicate() as ShaderMaterial
	if pulse == null:
		return
	var base_color_variant = pulse.get_shader_parameter("base_color")
	var base_color := base_color_variant as Color if base_color_variant is Color else Color.WHITE
	pulse.set_shader_parameter("emission_color", base_color)
	pulse.set_shader_parameter("emission_energy", PULSE_EMISSION_ENERGY)
	mesh.material_override = pulse

	var tree := get_tree()
	if tree == null:
		mesh.material_override = original
		return
	tree.create_timer(TTL_SEC).timeout.connect(func() -> void:
		if generation != _pulse_generation:
			return
		if is_instance_valid(mesh):
			mesh.material_override = original
	)

func get_world_event_contract() -> Dictionary:
	return {
		"version": "fb13_thrum_world_event_v1",
		"directive": DIRECTIVE,
		"actor": ACTOR,
		"zone": ZONE,
		"severity": SEVERITY,
		"ttl_msec": TTL_MSEC,
		"trigger_radius_m": TRIGGER_RADIUS_M,
		"rearm_radius_m": REARM_RADIUS_M,
		"cooldown_sec": COOLDOWN_SEC,
		"primary_resonance_path": "GearsDistrictSlice01B/IndustrialFrontage/CivicUtilityPlate",
		"secondary_resonance_path": "GearsDistrictSlice01B/IndustrialFrontage/UtilitySpine",
		"uses_retained_audio_manager": true,
		"adds_input": false,
		"adds_mission_state": false,
		"adds_collision": false,
		"adds_local_lights": false,
	}
