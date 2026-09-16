class_name PropVendingMachine
extends StaticBody3D

## Commercial Storefront Vending Machine Contraband Terminal
## Staged on commercial sidewalk frontage at storefront corner.
## Features contraband frequency hack ([E] HACK TERMINAL), 3-hit melee tamper breach,
## high-speed vehicle ram destruction with scrap debris scatter, and deterministic reset.

enum VendingState {
	READY,
	HACKED,
	BREACHED,
	EMPTY
}

const MAX_DURABILITY: int = 3
const HACK_SCRAP_REWARD: int = 80
const BREACH_SCRAP_REWARD: int = 120
const MIN_RAM_SPEED: float = 4.5
const DEBRIS_SHARD_COUNT: int = 4

@export var material_main: Material
@export var material_screen: Material

var current_state: VendingState = VendingState.READY
var current_durability: int = MAX_DURABILITY
var is_rammed: bool = false
var is_looted: bool = false
var is_hacked: bool = false
var debris_instances: Array[Node3D] = []

signal terminal_hacked(scrap_reward: int, pos: Vector3)
signal terminal_breached(loot_reward: int, pos: Vector3)
signal hit_received(remaining_durability: int, hit_pos: Vector3, impulse_dir: Vector3)
signal vending_machine_rammed(impact_speed: float, ram_dir: Vector3)
signal vending_machine_reset()

var _initial_transform: Transform3D
var _shake_tween: Tween = null
var _ram_tween: Tween = null
var _alarm_strobe_tween: Tween = null
var _audio_mgr: Node = null

@onready var visual_root: Node3D = $VisualRoot if has_node("VisualRoot") else self
@onready var collision_shape: CollisionShape3D = find_child("CollisionShape3D", true, false) as CollisionShape3D
@onready var interactable: Area3D = find_child("VendingMachineInteractable", true, false) as Area3D
@onready var screen_light: OmniLight3D = find_child("ScreenLight", true, false) as OmniLight3D

func _ready() -> void:
	add_to_group("damageable")
	add_to_group("strike_target")
	add_to_group("vending_machines")
	add_to_group("salvage_targets")
	_initial_transform = global_transform
	_setup_materials()
	if interactable:
		interactable.set("machine", self)
	if screen_light:
		screen_light.light_color = Color(0.2, 0.85, 1.0)
		screen_light.light_energy = 1.4

func setup_audio(mgr: Node) -> void:
	_audio_mgr = mgr

func _setup_materials() -> void:
	var meshes := find_children("*", "MeshInstance3D", true, false)
	for m in meshes:
		var mi := m as MeshInstance3D
		if not mi or mi in debris_instances:
			continue
		var surf_count: int = mi.get_surface_override_material_count()
		if surf_count == 0 and mi.mesh:
			surf_count = mi.mesh.get_surface_count()
		for s in range(surf_count):
			if s == 2 and material_screen:
				mi.set_surface_override_material(s, material_screen.duplicate())
			elif material_main:
				mi.set_surface_override_material(s, material_main.duplicate())

func can_hack() -> bool:
	return current_state == VendingState.READY and not is_rammed

func hack_terminal(player: CharacterBody3D = null) -> Dictionary:
	if not can_hack():
		return {"success": false, "reason": "UNAVAILABLE"}

	current_state = VendingState.HACKED
	is_hacked = true

	if screen_light:
		screen_light.light_color = Color(0.2, 1.0, 0.4)
		screen_light.light_energy = 2.0

	_set_screen_emission(Color(0.2, 1.0, 0.4), 2.8)

	if _audio_mgr and _audio_mgr.has_method("play_event"):
		_audio_mgr.play_event(AudioManager.SoundEvent.COMPLETION, global_position)
		_audio_mgr.play_event(AudioManager.SoundEvent.AMBIENT_WORK_CLINK, global_position)

	# Check if player in vehicle or can apply vehicle nitro surge
	var nitro_applied: bool = false
	if player:
		var vehicle = player.get("current_vehicle")
		if vehicle and vehicle.has_method("apply_tune_up"):
			vehicle.apply_tune_up(6.0, 1.35, 1.40)
			nitro_applied = true

	terminal_hacked.emit(HACK_SCRAP_REWARD, global_position)
	return {
		"success": true,
		"reward": HACK_SCRAP_REWARD,
		"nitro_applied": nitro_applied
	}

func take_hit(damage: int, hit_pos: Vector3, impulse_dir: Vector3) -> void:
	if current_state == VendingState.BREACHED:
		return

	current_durability = maxi(0, current_durability - damage)
	_trigger_impact_shake(impulse_dir)
	hit_received.emit(current_durability, hit_pos, impulse_dir)

	if _audio_mgr and _audio_mgr.has_method("play_event"):
		_audio_mgr.play_event(AudioManager.SoundEvent.AMBIENT_WORK_CLINK, hit_pos)
		_audio_mgr.play_event(AudioManager.SoundEvent.SPARK, hit_pos)

	if current_durability <= 0:
		breach_terminal(impulse_dir)

func breach_terminal(impulse_dir: Vector3 = Vector3.BACK) -> void:
	if current_state == VendingState.BREACHED:
		return

	current_state = VendingState.BREACHED
	var loot_awarded: int = 0
	if not is_looted:
		is_looted = true
		loot_awarded = BREACH_SCRAP_REWARD

	_scatter_debris(impulse_dir)
	_trigger_alarm_strobe()

	if _audio_mgr and _audio_mgr.has_method("play_event"):
		_audio_mgr.play_event(AudioManager.SoundEvent.SPARK, global_position)
		_audio_mgr.play_event(AudioManager.SoundEvent.SIREN_ALARM, global_position)

	terminal_breached.emit(loot_awarded, global_position)
	_trigger_world_disturbance()

func apply_vehicle_ram(impact_speed: float, ram_dir: Vector3, vehicle_source: Node3D = null) -> void:
	if impact_speed < MIN_RAM_SPEED:
		return

	is_rammed = true
	current_state = VendingState.BREACHED
	current_durability = 0

	var loot_awarded: int = 0
	if not is_looted:
		is_looted = true
		loot_awarded = BREACH_SCRAP_REWARD

	_trigger_ram_physics(impact_speed, ram_dir)
	_scatter_debris(ram_dir)
	_trigger_alarm_strobe()

	if _audio_mgr and _audio_mgr.has_method("play_event"):
		_audio_mgr.play_event(AudioManager.SoundEvent.COLLISION_HEAD_ON, global_position)
		_audio_mgr.play_event(AudioManager.SoundEvent.SPARK, global_position)
		_audio_mgr.play_event(AudioManager.SoundEvent.SIREN_ALARM, global_position)

	vending_machine_rammed.emit(impact_speed, ram_dir)
	terminal_breached.emit(loot_awarded, global_position)
	_trigger_world_disturbance()

func _trigger_impact_shake(impulse_dir: Vector3) -> void:
	if is_instance_valid(_shake_tween) and _shake_tween.is_running():
		_shake_tween.kill()

	if not visual_root:
		return

	var recoil_offset: Vector3 = impulse_dir.normalized() * 0.08
	_shake_tween = create_tween()
	_shake_tween.tween_property(visual_root, "position", recoil_offset, 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_shake_tween.tween_property(visual_root, "position", Vector3.ZERO, 0.16).set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)

func _trigger_ram_physics(impact_speed: float, ram_dir: Vector3) -> void:
	if is_instance_valid(_ram_tween) and _ram_tween.is_running():
		_ram_tween.kill()

	var flat_dir: Vector3 = Vector3(ram_dir.x, 0.0, ram_dir.z).normalized()
	if flat_dir.length_squared() < 0.01:
		flat_dir = Vector3.FORWARD

	var slide_dist: float = clampf(impact_speed * 0.28, 0.8, 2.2)
	var target_pos: Vector3 = global_position + flat_dir * slide_dist
	var tilt_axis: Vector3 = flat_dir.cross(Vector3.UP).normalized()
	if tilt_axis.length_squared() < 0.01:
		tilt_axis = Vector3.RIGHT

	var target_basis: Basis = Basis(tilt_axis, deg_to_rad(30.0))

	_ram_tween = create_tween().set_parallel(true)
	_ram_tween.tween_property(self, "global_position", target_pos, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_ram_tween.tween_property(visual_root, "transform:basis", target_basis, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _trigger_alarm_strobe() -> void:
	if is_instance_valid(_alarm_strobe_tween) and _alarm_strobe_tween.is_running():
		_alarm_strobe_tween.kill()

	if not screen_light:
		return

	screen_light.light_color = Color(1.0, 0.1, 0.1)
	screen_light.light_energy = 2.5
	_set_screen_emission(Color(1.0, 0.1, 0.1), 3.0)

	_alarm_strobe_tween = create_tween().set_loops(4)
	_alarm_strobe_tween.tween_property(screen_light, "light_energy", 0.2, 0.12)
	_alarm_strobe_tween.tween_property(screen_light, "light_energy", 2.5, 0.12)

func _set_screen_emission(color: Color, energy: float) -> void:
	var meshes := find_children("*", "MeshInstance3D", true, false)
	for m in meshes:
		var mi := m as MeshInstance3D
		if not mi or mi in debris_instances:
			continue
		var surf_count: int = mi.get_surface_override_material_count()
		for s in range(surf_count):
			var mat = mi.get_surface_override_material(s) as ShaderMaterial
			if mat:
				if mat.get_shader_parameter("emission_color") != null:
					mat.set_shader_parameter("emission_color", color)
				if mat.get_shader_parameter("emission_energy") != null:
					mat.set_shader_parameter("emission_energy", energy)

func _scatter_debris(force_dir: Vector3) -> void:
	for i in range(DEBRIS_SHARD_COUNT):
		var shard := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(randf_range(0.12, 0.25), randf_range(0.08, 0.18), randf_range(0.12, 0.25))
		shard.mesh = box

		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(randf_range(0.2, 0.4), randf_range(0.5, 0.7), randf_range(0.6, 0.8))
		mat.roughness = 0.5
		shard.material_override = mat

		add_child(shard)
		debris_instances.append(shard)

		var spread := Vector3(randf_range(-1.2, 1.2), randf_range(0.8, 1.8), randf_range(-1.2, 1.2))
		shard.global_position = global_position + Vector3(0.0, 0.8, 0.0)

		var target_shard_pos := global_position + (force_dir.normalized() * randf_range(1.5, 3.5)) + spread
		target_shard_pos.y = maxf(0.05, global_position.y)

		var dt := create_tween().set_parallel(true)
		dt.tween_property(shard, "global_position", target_shard_pos, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		dt.tween_property(shard, "rotation", Vector3(randf_range(-3, 3), randf_range(-3, 3), randf_range(-3, 3)), 0.45)

func _trigger_world_disturbance() -> void:
	var tree := get_tree()
	if not tree:
		return
	var world = tree.get_first_node_in_group("world_root")
	if not world:
		world = get_parent()
	if world and world.has_method("trigger_disturbance_alert"):
		world.trigger_disturbance_alert()

func reset_vending_machine() -> void:
	if is_instance_valid(_shake_tween) and _shake_tween.is_running():
		_shake_tween.kill()
	if is_instance_valid(_ram_tween) and _ram_tween.is_running():
		_ram_tween.kill()
	if is_instance_valid(_alarm_strobe_tween) and _alarm_strobe_tween.is_running():
		_alarm_strobe_tween.kill()

	global_transform = _initial_transform
	if visual_root:
		visual_root.transform = Transform3D.IDENTITY

	current_state = VendingState.READY
	current_durability = MAX_DURABILITY
	is_rammed = false
	is_looted = false
	is_hacked = false

	if collision_shape:
		collision_shape.disabled = false

	if screen_light:
		screen_light.light_color = Color(0.2, 0.85, 1.0)
		screen_light.light_energy = 1.4

	_set_screen_emission(Color(0.2, 0.85, 1.0), 2.5)

	for d in debris_instances:
		if is_instance_valid(d):
			d.queue_free()
	debris_instances.clear()

	if interactable:
		interactable.set("is_powered", true)

	vending_machine_reset.emit()
