class_name PropUtilityPole
extends StaticBody3D

## Interactive Surveillance Utility Pole & EMP Grid Overload
## Sidewalk optic conduit pole with emissive cyan data feed.
## Supports foot melee tampering (3-hit transformer blowout), tactical grid tapping ([E] TAP GRID),
## 9.0m EMP shockwave stunning active pursuers for 4.0s, and high-speed vehicle ram tilt.

enum PoleState {
	READY,
	OVERLOADED,
	DAMAGED,
	RAMMED
}

const MAX_DURABILITY: int = 3
const EMP_RADIUS: float = 9.0
const EMP_STUN_DURATION: float = 4.0
const MIN_RAM_SPEED: float = 4.5
const SPARK_DEBRIS_COUNT: int = 5

@export var material_main: Material
@export var material_optic: Material

var current_state: PoleState = PoleState.READY
var current_durability: int = MAX_DURABILITY
var is_rammed: bool = false
var is_overloaded: bool = false
var debris_instances: Array[Node3D] = []

signal grid_overloaded(shockwave_radius: float, origin_pos: Vector3)
signal hit_received(remaining_durability: int, hit_pos: Vector3, impulse_dir: Vector3)
signal pole_rammed(impact_speed: float, ram_dir: Vector3)
signal pole_reset()

var _initial_transform: Transform3D
var _shake_tween: Tween = null
var _tilt_tween: Tween = null

@onready var visual_root: Node3D = $VisualRoot if has_node("VisualRoot") else ($Model if has_node("Model") else self)
@onready var collision_shape: CollisionShape3D = find_child("CollisionShape3D", true, false) as CollisionShape3D
@onready var interactable: Area3D = find_child("UtilityPoleInteractable", true, false) as Area3D

func _ready() -> void:
	add_to_group("damageable")
	add_to_group("strike_target")
	add_to_group("utility_poles")
	_initial_transform = global_transform
	_setup_materials()
	if interactable:
		interactable.set("pole", self)

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
			if s == 1 and material_optic:
				mi.set_surface_override_material(s, material_optic.duplicate())
			elif material_main:
				mi.set_surface_override_material(s, material_main.duplicate())

func _set_optic_emission(energy: float) -> void:
	var meshes := find_children("*", "MeshInstance3D", true, false)
	for m in meshes:
		var mi := m as MeshInstance3D
		if not mi or mi in debris_instances:
			continue
		var surf_count: int = mi.get_surface_override_material_count()
		for s in range(surf_count):
			var mat = mi.get_surface_override_material(s) as ShaderMaterial
			if mat and mat.get_shader_parameter("emission_energy") != null:
				mat.set_shader_parameter("emission_energy", energy)

func take_hit(damage: int, hit_pos: Vector3, impulse_dir: Vector3) -> void:
	if is_overloaded and current_durability <= 0:
		return

	current_durability = maxi(0, current_durability - damage)
	_trigger_impact_shake(impulse_dir)
	hit_received.emit(current_durability, hit_pos, impulse_dir)

	if current_durability <= 0:
		if not is_overloaded:
			if current_state != PoleState.RAMMED:
				current_state = PoleState.DAMAGED
			overload_grid()

func _trigger_impact_shake(impulse_dir: Vector3) -> void:
	if is_instance_valid(_shake_tween) and _shake_tween.is_running():
		_shake_tween.kill()

	if not visual_root or visual_root == self:
		return

	var punch_offset := impulse_dir.normalized() * 0.08
	punch_offset.y = 0.02

	_shake_tween = create_tween()
	_shake_tween.set_trans(Tween.TRANS_ELASTIC).set_ease(Tween.EASE_OUT)
	_shake_tween.tween_property(visual_root, "position", punch_offset, 0.06)
	_shake_tween.tween_property(visual_root, "position", Vector3.ZERO, 0.2)

func overload_grid() -> bool:
	if is_overloaded:
		return false

	is_overloaded = true
	if current_state != PoleState.RAMMED:
		current_state = PoleState.OVERLOADED

	_set_optic_emission(0.05)
	_spawn_electrical_sparks()
	_stun_nearby_pursuers(EMP_RADIUS, EMP_STUN_DURATION)

	grid_overloaded.emit(EMP_RADIUS, global_position)
	return true

func _spawn_electrical_sparks() -> void:
	for i in range(SPARK_DEBRIS_COUNT):
		var spark := MeshInstance3D.new()
		var box_mesh := BoxMesh.new()
		box_mesh.size = Vector3(randf_range(0.06, 0.12), randf_range(0.06, 0.12), randf_range(0.06, 0.12))
		spark.mesh = box_mesh

		var spark_mat := StandardMaterial3D.new()
		spark_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		spark_mat.albedo_color = Color(0.1, 0.95, 1.0, 1.0)
		spark.material_override = spark_mat

		spark.position = Vector3(randf_range(-0.3, 0.3), randf_range(2.0, 4.5), randf_range(-0.3, 0.3))
		add_child(spark)
		debris_instances.append(spark)

		var angle: float = randf_range(0, TAU)
		var dir := Vector3(cos(angle), randf_range(-0.4, 0.6), sin(angle)).normalized()
		var dist: float = randf_range(1.2, 2.5)
		var end_pos: Vector3 = spark.position + dir * dist

		var t := create_tween()
		t.set_parallel(true)
		t.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		t.tween_property(spark, "position", end_pos, 0.35 + i * 0.05)
		t.chain().tween_property(spark, "scale", Vector3.ZERO, 0.25)

func _stun_nearby_pursuers(radius: float, duration: float) -> void:
	var tree := get_tree()
	if not tree:
		return
	var nodes := tree.get_nodes_in_group("pursuers")
	for p in nodes:
		if p is Node3D:
			var dist: float = global_position.distance_to(p.global_position)
			if dist <= radius:
				if p.has_method("apply_emp_stun"):
					p.apply_emp_stun(duration)
				elif p.has_method("apply_vehicle_ram"):
					p.apply_vehicle_ram(6.0, (p.global_position - global_position).normalized())

func apply_vehicle_ram(impact_speed: float, ram_direction: Vector3, _vehicle: Node3D = null) -> bool:
	if is_rammed:
		return false

	if impact_speed < MIN_RAM_SPEED:
		_trigger_impact_shake(ram_direction * 0.4)
		return false

	is_rammed = true
	current_state = PoleState.RAMMED

	if not is_overloaded:
		overload_grid()

	_tilt_pole(ram_direction)
	pole_rammed.emit(impact_speed, ram_direction)
	return true

func _tilt_pole(ram_direction: Vector3) -> void:
	if not visual_root or visual_root == self:
		return
	if is_instance_valid(_tilt_tween) and _tilt_tween.is_running():
		_tilt_tween.kill()

	var flat_dir := Vector3(ram_direction.x, 0.0, ram_direction.z).normalized()
	if flat_dir.length_squared() < 0.001:
		flat_dir = Vector3.FORWARD

	var tilt_axis := flat_dir.cross(Vector3.UP).normalized()
	var tilt_angle := deg_to_rad(22.0)
	var target_rot := Basis(tilt_axis, -tilt_angle).get_euler()

	_tilt_tween = create_tween()
	_tilt_tween.set_trans(Tween.TRANS_BOUNCE).set_ease(Tween.EASE_OUT)
	_tilt_tween.tween_property(visual_root, "rotation", target_rot, 0.45)

func reset_pole() -> void:
	if is_instance_valid(_shake_tween) and _shake_tween.is_running():
		_shake_tween.kill()
	if is_instance_valid(_tilt_tween) and _tilt_tween.is_running():
		_tilt_tween.kill()

	for d in debris_instances:
		if is_instance_valid(d):
			d.queue_free()
	debris_instances.clear()

	global_transform = _initial_transform
	if visual_root and visual_root != self:
		visual_root.position = Vector3.ZERO
		visual_root.rotation = Vector3.ZERO
		visual_root.scale = Vector3.ONE

	is_rammed = false
	is_overloaded = false
	current_durability = MAX_DURABILITY
	current_state = PoleState.READY

	_set_optic_emission(0.7)

	if collision_shape:
		collision_shape.set_deferred("disabled", false)
		collision_shape.disabled = false

	if interactable:
		interactable.set("is_powered", true)

	pole_reset.emit()
