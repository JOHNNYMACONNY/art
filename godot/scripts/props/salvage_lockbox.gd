class_name SalvageLockbox
extends StaticBody3D

# Echos in the Scrap — Breakable Salvage Lockbox / Municipal Scrap Terminal
# Street Combat & Physical Tool Improvisation slice.
# Supports multi-hit durability, physical hit reactions, breach payoff,
# and municipal disturbance alarm triggering city security pursuit.

enum State {
	SECURED,
	DAMAGED,
	BREACHED
}

const MAX_DURABILITY: int = 3
const REWARD_CREDITS: int = 150

@export var is_restricted_municipal: bool = true
@export var material_main: Material

var current_state: State = State.SECURED
var current_durability: int = MAX_DURABILITY
var reward_granted: int = 0

signal hit_received(remaining_durability: int, hit_pos: Vector3, impulse_dir: Vector3)
signal lockbox_breached(reward: int, breach_pos: Vector3)
signal alarm_triggered(source_pos: Vector3)

var _initial_transform: Transform3D
var _alarm_fired: bool = false
var _shake_tween: Tween = null

@onready var visual_root: Node3D = $VisualRoot if has_node("VisualRoot") else self
@onready var status_light: MeshInstance3D = find_child("StatusLight", true, false) as MeshInstance3D
@onready var lid_mesh: Node3D = find_child("LockboxLid", true, false) as Node3D
@onready var collision_shape: CollisionShape3D = find_child("CollisionShape3D", true, false) as CollisionShape3D

func _ready() -> void:
	add_to_group("damageable")
	add_to_group("strike_target")
	add_to_group("salvage_targets")
	_initial_transform = global_transform
	_setup_materials()
	_update_visual_state()

func _setup_materials() -> void:
	if not material_main:
		return
	var meshes := find_children("*", "MeshInstance3D", true, false)
	for m in meshes:
		var mi := m as MeshInstance3D
		if not mi or mi == status_light:
			continue
		var surf_count: int = mi.get_surface_override_material_count()
		if surf_count == 0 and mi.mesh:
			surf_count = mi.mesh.get_surface_count()
		for s in range(surf_count):
			mi.set_surface_override_material(s, material_main.duplicate())

func take_hit(damage: int, hit_pos: Vector3, impulse_dir: Vector3) -> bool:
	if current_state == State.BREACHED:
		return false

	current_durability = maxi(0, current_durability - damage)

	# Impact displacement / physical reaction
	_trigger_impact_reaction(impulse_dir)

	if current_durability <= 0:
		current_state = State.BREACHED
		reward_granted = REWARD_CREDITS
		_update_visual_state()
		hit_received.emit(current_durability, hit_pos, impulse_dir)
		lockbox_breached.emit(reward_granted, global_position)
	else:
		current_state = State.DAMAGED
		_update_visual_state()
		hit_received.emit(current_durability, hit_pos, impulse_dir)

	# Municipal alarm consequence on first strike
	if is_restricted_municipal and not _alarm_fired:
		_alarm_fired = true
		alarm_triggered.emit(global_position)

	return true

func _trigger_impact_reaction(impulse_dir: Vector3) -> void:
	if is_instance_valid(_shake_tween) and _shake_tween.is_running():
		_shake_tween.kill()

	if not visual_root:
		return

	var punch_offset := impulse_dir.normalized() * 0.08
	punch_offset.y = 0.04

	_shake_tween = create_tween()
	_shake_tween.set_trans(Tween.TRANS_ELASTIC)
	_shake_tween.set_ease(Tween.EASE_OUT)
	_shake_tween.tween_property(visual_root, "position", visual_root.position + punch_offset, 0.06)
	_shake_tween.tween_property(visual_root, "position", Vector3.ZERO, 0.18)

func _update_visual_state() -> void:
	if status_light:
		var mat := status_light.get_surface_override_material(0)
		if not mat and status_light.mesh:
			mat = status_light.mesh.surface_get_material(0)
		if mat is StandardMaterial3D:
			var active_mat := mat.duplicate() as StandardMaterial3D
			match current_state:
				State.SECURED:
					active_mat.albedo_color = Color(1.0, 0.15, 0.1, 1.0)
					active_mat.emission = Color(1.0, 0.1, 0.05, 1.0)
					active_mat.emission_energy_multiplier = 2.5
				State.DAMAGED:
					active_mat.albedo_color = Color(1.0, 0.7, 0.1, 1.0)
					active_mat.emission = Color(1.0, 0.6, 0.0, 1.0)
					active_mat.emission_energy_multiplier = 3.8
				State.BREACHED:
					active_mat.albedo_color = Color(0.15, 0.15, 0.15, 1.0)
					active_mat.emission = Color(0.05, 0.05, 0.05, 1.0)
					active_mat.emission_energy_multiplier = 0.0
			status_light.set_surface_override_material(0, active_mat)

	if lid_mesh:
		if current_state == State.BREACHED:
			lid_mesh.rotation.x = deg_to_rad(-55.0)
			lid_mesh.position.y = 0.85
		else:
			lid_mesh.rotation.x = 0.0
			lid_mesh.position.y = 0.75

func reset_lockbox() -> void:
	if is_instance_valid(_shake_tween) and _shake_tween.is_running():
		_shake_tween.kill()
	current_state = State.SECURED
	current_durability = MAX_DURABILITY
	reward_granted = 0
	_alarm_fired = false
	if visual_root:
		visual_root.position = Vector3.ZERO
	global_transform = _initial_transform
	_update_visual_state()
