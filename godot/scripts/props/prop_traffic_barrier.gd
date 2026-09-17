class_name PropTrafficBarrier
extends StaticBody3D

## Roadblock traffic barrier blocking shortcut corridors and arterial alleys.
## Supports foot melee strike recoil, low-speed vehicle deflection,
## and high-speed vehicle ramming destruction with tumbling launch and debris scattering.

enum BarrierState {
	INTACT,
	BREACHED
}

const MIN_RAM_SPEED: float = 5.0
const DEBRIS_COUNT: int = 4

@export var material_main: Material

var current_state: BarrierState = BarrierState.INTACT
var is_breached: bool = false
var debris_instances: Array[Node3D] = []

signal barrier_hit(hit_pos: Vector3, impulse_dir: Vector3)
signal barrier_breached(impact_speed: float, ram_dir: Vector3)
signal barrier_reset()

var _initial_transform: Transform3D
var _shake_tween: Tween = null
var _launch_tween: Tween = null

@onready var visual_root: Node3D = $Model if has_node("Model") else self
@onready var collision_shape: CollisionShape3D = find_child("CollisionShape3D", true, false) as CollisionShape3D

func _ready() -> void:
	add_to_group("damageable")
	add_to_group("strike_target")
	add_to_group("traffic_barriers")
	_initial_transform = global_transform
	_setup_materials()

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
			if material_main:
				mi.set_surface_override_material(s, material_main.duplicate())

func take_hit(_damage: int, hit_pos: Vector3, impulse_dir: Vector3) -> void:
	if is_breached:
		return
	_trigger_impact_reaction(impulse_dir)
	barrier_hit.emit(hit_pos, impulse_dir)

func _trigger_impact_reaction(impulse_dir: Vector3) -> void:
	if is_instance_valid(_shake_tween) and _shake_tween.is_running():
		_shake_tween.kill()

	if not visual_root or visual_root == self:
		return

	var punch_offset := impulse_dir.normalized() * 0.08
	punch_offset.y = 0.04

	_shake_tween = create_tween()
	_shake_tween.set_trans(Tween.TRANS_ELASTIC)
	_shake_tween.set_ease(Tween.EASE_OUT)
	_shake_tween.tween_property(visual_root, "position", visual_root.position + punch_offset, 0.06)
	_shake_tween.tween_property(visual_root, "position", Vector3.ZERO, 0.18)

func apply_vehicle_ram(impact_speed: float, ram_direction: Vector3, _vehicle: Node3D = null) -> bool:
	if is_breached:
		return false

	if impact_speed < MIN_RAM_SPEED:
		_trigger_impact_reaction(ram_direction * 0.5)
		return false

	is_breached = true
	current_state = BarrierState.BREACHED

	if collision_shape:
		collision_shape.set_deferred("disabled", true)
		collision_shape.disabled = true

	_launch_barrier(impact_speed, ram_direction)
	_spawn_debris(ram_direction, impact_speed)

	barrier_breached.emit(impact_speed, ram_direction)
	return true

func _launch_barrier(impact_speed: float, ram_direction: Vector3) -> void:
	if is_instance_valid(_shake_tween) and _shake_tween.is_running():
		_shake_tween.kill()
	if is_instance_valid(_launch_tween) and _launch_tween.is_running():
		_launch_tween.kill()

	if not visual_root or visual_root == self:
		return

	var flat_dir := Vector3(ram_direction.x, 0.0, ram_direction.z).normalized()
	if flat_dir.length_squared() < 0.001:
		flat_dir = Vector3.FORWARD

	var launch_dist: float = minf(impact_speed * 0.75, 7.0)
	var target_pos: Vector3 = visual_root.position + flat_dir * launch_dist + Vector3.UP * 0.45

	_launch_tween = create_tween()
	_launch_tween.set_parallel(true)
	_launch_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_launch_tween.tween_property(visual_root, "position", target_pos, 0.45)
	_launch_tween.tween_property(visual_root, "rotation:x", visual_root.rotation.x + deg_to_rad(65.0), 0.45)
	_launch_tween.tween_property(visual_root, "rotation:y", visual_root.rotation.y + deg_to_rad(120.0), 0.45)
	_launch_tween.tween_property(visual_root, "rotation:z", visual_root.rotation.z + deg_to_rad(-35.0), 0.45)

func _spawn_debris(ram_direction: Vector3, impact_speed: float) -> void:
	var flat_dir := Vector3(ram_direction.x, 0.0, ram_direction.z).normalized()
	if flat_dir.length_squared() < 0.001:
		flat_dir = Vector3.FORWARD

	for i in range(DEBRIS_COUNT):
		var shard := MeshInstance3D.new()
		var box_mesh := BoxMesh.new()
		box_mesh.size = Vector3(randf_range(0.18, 0.32), randf_range(0.10, 0.22), randf_range(0.12, 0.25))
		shard.mesh = box_mesh
		if material_main:
			shard.material_override = material_main

		shard.position = Vector3(randf_range(-0.5, 0.5), 0.4, randf_range(-0.2, 0.2))
		add_child(shard)
		debris_instances.append(shard)

		var angle: float = randf_range(-PI * 0.35, PI * 0.35)
		var scatter_dir: Vector3 = flat_dir.rotated(Vector3.UP, angle).normalized()
		var scatter_dist: float = randf_range(1.5, 3.5) * (impact_speed / MIN_RAM_SPEED)
		var end_pos: Vector3 = shard.position + scatter_dir * scatter_dist
		end_pos.y = 0.05

		var shard_tween := create_tween()
		shard_tween.set_parallel(true)
		shard_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		shard_tween.tween_property(shard, "position", end_pos, 0.38 + i * 0.05)
		shard_tween.tween_property(shard, "rotation", Vector3(randf_range(-PI, PI), randf_range(-PI, PI), randf_range(-PI, PI)), 0.38 + i * 0.05)
		shard_tween.chain().tween_property(shard, "scale", Vector3.ZERO, 0.6)

func reset_barrier() -> void:
	if is_instance_valid(_shake_tween) and _shake_tween.is_running():
		_shake_tween.kill()
	if is_instance_valid(_launch_tween) and _launch_tween.is_running():
		_launch_tween.kill()

	for shard in debris_instances:
		if is_instance_valid(shard):
			shard.queue_free()
	debris_instances.clear()

	global_transform = _initial_transform
	if visual_root and visual_root != self:
		visual_root.position = Vector3.ZERO
		visual_root.rotation = Vector3.ZERO
		visual_root.scale = Vector3.ONE
		visual_root.visible = true

	if collision_shape:
		collision_shape.set_deferred("disabled", false)
		collision_shape.disabled = false

	is_breached = false
	current_state = BarrierState.INTACT

	barrier_reset.emit()
