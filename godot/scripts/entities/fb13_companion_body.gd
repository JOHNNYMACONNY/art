class_name FB13CompanionBody
extends Node3D

enum PresenceState {
	FOLLOWING,       # 0
	REJOINING,       # 1
	DOCKING_BIKE,    # 2
	DOCKED_BIKE,     # 3
	DOCKING_HAULER,  # 4
	DOCKED_HAULER,   # 5
}

const FOLLOW_SIDE_M := 2.1
const FOLLOW_TRAIL_M := 1.8
const FOLLOW_HEIGHT_M := 1.15
const FOLLOW_SPEED_MPS := 10.5
const FOLLOW_ACCEL_MPS2 := 28.0
const REJOIN_ELIGIBLE_DISTANCE_M := 18.0
const REJOIN_DELAY_SEC := 0.75
const REJOIN_STAGING_RADIUS_M := 16.0
const REJOIN_COMPLETE_DISTANCE_M := 5.0
const REJOIN_SPEED_MPS := 15.0

const DOCK_INTERPOLATION_DURATION := 0.20
const THRUM_REACTION_DURATION := 0.65

var current_state: PresenceState = PresenceState.FOLLOWING

var _runner: Node3D = null
var _camera: Camera3D = null
var _active_vehicle: Node3D = null

var _velocity := Vector3.ZERO
var _separation_timer: float = 0.0

var _hard_rejoin_count: int = 0
var _last_hard_rejoin_snapshot: Dictionary = {}

var _thrum_reaction_count: int = 0
var _thrum_reaction_timer: float = 0.0

var _dock_socket: Node3D = null
var _dock_target_state: PresenceState = PresenceState.DOCKED_BIKE
var _dock_timer: float = 0.0

var _sphere_shape: SphereShape3D = null
var _shape_query: PhysicsShapeQueryParameters3D = null
var _dock_start_transform: Transform3D = Transform3D.IDENTITY
var _eye_mat: StandardMaterial3D = null
var _default_emission_energy: float = 2.0

@onready var _visual_root: Node3D = get_node_or_null("VisualRoot")
@onready var _eye_mesh: MeshInstance3D = get_node_or_null("VisualRoot/Eye")

func _init() -> void:
	_sphere_shape = SphereShape3D.new()
	_sphere_shape.radius = 0.4
	_shape_query = PhysicsShapeQueryParameters3D.new()
	_shape_query.shape = _sphere_shape
	_shape_query.collide_with_areas = false
	_shape_query.collide_with_bodies = true

func _ready() -> void:
	if _eye_mesh:
		var mat: Material = _eye_mesh.get_surface_override_material(0)
		if mat == null and _eye_mesh.mesh and _eye_mesh.mesh.material:
			mat = _eye_mesh.mesh.material
		if mat is StandardMaterial3D:
			_eye_mat = mat.duplicate() as StandardMaterial3D
			_eye_mesh.set_surface_override_material(0, _eye_mat)
			_default_emission_energy = _eye_mat.emission_energy_multiplier

func configure(runner: Node3D, camera: Camera3D) -> void:
	_runner = runner
	_camera = camera
	current_state = PresenceState.FOLLOWING
	_velocity = Vector3.ZERO
	_separation_timer = 0.0
	reset_to_follow_position()

func set_active_vehicle(vehicle: Node3D) -> void:
	_active_vehicle = vehicle

func get_presence_state() -> PresenceState:
	return current_state

func get_follow_distance() -> float:
	if _runner and is_instance_valid(_runner):
		return global_position.distance_to(_runner.global_position)
	return 0.0

func get_hard_rejoin_count() -> int:
	return _hard_rejoin_count

func get_last_hard_rejoin_snapshot() -> Dictionary:
	return _last_hard_rejoin_snapshot

func get_thrum_reaction_count() -> int:
	return _thrum_reaction_count

func on_thrum_triggered(_event_payload: Dictionary) -> void:
	_thrum_reaction_count += 1
	_thrum_reaction_timer = THRUM_REACTION_DURATION
	_apply_thrum_visual(true)

func reset_to_follow_position() -> void:
	current_state = PresenceState.FOLLOWING
	_velocity = Vector3.ZERO
	_separation_timer = 0.0
	_thrum_reaction_timer = 0.0
	_dock_socket = null
	_dock_timer = 0.0
	_apply_thrum_visual(false)
	if _runner and is_instance_valid(_runner):
		var target := _compute_preferred_follow_target()
		global_position = target

func begin_dock(socket: Node3D, docking_state: PresenceState, docked_state: PresenceState) -> void:
	current_state = docking_state
	_dock_socket = socket
	_dock_target_state = docked_state
	_dock_timer = 0.0
	_separation_timer = 0.0
	_velocity = Vector3.ZERO
	if socket != null:
		reparent(socket, true)
	_dock_start_transform = transform

func release_from_dock(world_origin: Vector3) -> void:
	_dock_socket = null
	_dock_timer = 0.0
	global_position = world_origin
	_velocity = Vector3.ZERO
	_separation_timer = 0.0
	current_state = PresenceState.FOLLOWING

func tick_presence(delta: float) -> void:
	_update_thrum_reaction(delta)

	match current_state:
		PresenceState.FOLLOWING:
			_tick_following(delta)
		PresenceState.REJOINING:
			_tick_rejoining(delta)
		PresenceState.DOCKING_BIKE, PresenceState.DOCKING_HAULER:
			_tick_docking(delta)
		PresenceState.DOCKED_BIKE, PresenceState.DOCKED_HAULER:
			_tick_docked(delta)

func _tick_docking(delta: float) -> void:
	_dock_timer += delta
	var t := clampf(_dock_timer / DOCK_INTERPOLATION_DURATION, 0.0, 1.0)
	transform = _dock_start_transform.interpolate_with(Transform3D.IDENTITY, t)
	if t >= 1.0:
		transform = Transform3D.IDENTITY
		current_state = _dock_target_state

func _tick_docked(_delta: float) -> void:
	transform = Transform3D.IDENTITY

func _tick_following(delta: float) -> void:
	if _runner == null or not is_instance_valid(_runner):
		return

	var sep_dist := get_follow_distance()
	if sep_dist >= REJOIN_ELIGIBLE_DISTANCE_M and _is_point_off_screen(global_position):
		_separation_timer += delta
		if _separation_timer >= REJOIN_DELAY_SEC:
			if _try_hard_rejoin():
				return
	else:
		_separation_timer = 0.0

	var target := _select_follow_target()
	_move_towards(target, FOLLOW_SPEED_MPS, FOLLOW_ACCEL_MPS2, delta)

func _tick_rejoining(delta: float) -> void:
	if _runner == null or not is_instance_valid(_runner):
		return

	if get_follow_distance() < REJOIN_COMPLETE_DISTANCE_M:
		current_state = PresenceState.FOLLOWING
		_separation_timer = 0.0
		_tick_following(delta)
		return

	var target := _select_follow_target()
	_move_towards(target, REJOIN_SPEED_MPS, FOLLOW_ACCEL_MPS2, delta)

func _move_towards(target_pos: Vector3, max_speed: float, accel: float, delta: float) -> void:
	var to_target := target_pos - global_position
	var dist := to_target.length()
	if dist > 0.05:
		var desired_dir := to_target.normalized()
		var target_vel := desired_dir * minf(dist * 4.0, max_speed)
		_velocity = _velocity.move_toward(target_vel, accel * delta)
	else:
		_velocity = _velocity.move_toward(Vector3.ZERO, accel * delta)

	var step := _velocity * delta
	if step.length_squared() > 0.00001:
		step = _clamp_movement_by_clearance(step)
		global_position += step

	if _velocity.length_squared() > 0.1:
		var look_dir := Vector3(_velocity.x, 0.0, _velocity.z).normalized()
		var target_rot_y := atan2(-look_dir.x, -look_dir.z)
		rotation.y = lerp_angle(rotation.y, target_rot_y, 10.0 * delta)

func _clamp_movement_by_clearance(step: Vector3) -> Vector3:
	if not is_inside_tree():
		return step
	var world := get_world_3d()
	if world == null:
		return step
	var space_state := world.direct_space_state
	if space_state == null:
		return step

	var ray := PhysicsRayQueryParameters3D.create(global_position, global_position + step.normalized() * (step.length() + 0.35))
	ray.collide_with_areas = false
	ray.collide_with_bodies = true
	ray.exclude = _get_collision_exclusions()
	var hit := space_state.intersect_ray(ray)
	if not hit.is_empty():
		var hit_dist := global_position.distance_to(hit.position)
		if hit_dist > 0.35:
			return step.normalized() * (hit_dist - 0.35)
		return Vector3.ZERO
	return step

func _select_follow_target() -> Vector3:
	var preferred := _compute_preferred_follow_target()
	if _is_candidate_clear(preferred):
		return preferred

	var alternate := _compute_alternate_follow_target()
	if _is_candidate_clear(alternate):
		return alternate

	return global_position

func _compute_follow_target(lateral_sign: float = 1.0) -> Vector3:
	var fwd := _get_runner_forward()
	var right := _get_runner_right()
	return _runner.global_position - fwd * FOLLOW_TRAIL_M + right * (FOLLOW_SIDE_M * lateral_sign) + Vector3.UP * FOLLOW_HEIGHT_M

func _compute_preferred_follow_target() -> Vector3:
	return _compute_follow_target(1.0)

func _compute_alternate_follow_target() -> Vector3:
	return _compute_follow_target(-1.0)

func _get_runner_forward() -> Vector3:
	if _runner == null or not is_instance_valid(_runner):
		return Vector3(0, 0, -1)
	var pivot := _runner.get_node_or_null("MeshPivot") as Node3D
	var runner_basis: Basis = pivot.global_transform.basis if pivot else _runner.global_transform.basis
	var fwd_dir := Vector3(-runner_basis.z.x, 0.0, -runner_basis.z.z)
	if fwd_dir.length_squared() > 0.001:
		return fwd_dir.normalized()
	return Vector3(0, 0, -1)

func _get_runner_right() -> Vector3:
	if _runner == null or not is_instance_valid(_runner):
		return Vector3(1, 0, 0)
	var pivot := _runner.get_node_or_null("MeshPivot") as Node3D
	var runner_basis: Basis = pivot.global_transform.basis if pivot else _runner.global_transform.basis
	var right_dir := Vector3(runner_basis.x.x, 0.0, runner_basis.x.z)
	if right_dir.length_squared() > 0.001:
		return right_dir.normalized()
	return Vector3(1, 0, 0)

func _get_collision_exclusions() -> Array[RID]:
	var exclude: Array[RID] = []
	if _runner is CollisionObject3D:
		exclude.append((_runner as CollisionObject3D).get_rid())
	if _active_vehicle is CollisionObject3D:
		exclude.append((_active_vehicle as CollisionObject3D).get_rid())
	return exclude

func _is_spatial_point_vacant(space_state: PhysicsDirectSpaceState3D, pos: Vector3, exclusions: Array[RID]) -> bool:
	if _shape_query == null:
		return true
	_shape_query.transform = Transform3D(Basis.IDENTITY, pos)
	_shape_query.exclude = exclusions
	var shape_hits := space_state.intersect_shape(_shape_query, 1)
	return shape_hits.is_empty()

func _is_candidate_clear(target_pos: Vector3) -> bool:
	if not is_inside_tree():
		return true
	var world := get_world_3d()
	if world == null:
		return true
	var space_state := world.direct_space_state
	if space_state == null:
		return true

	var exclusions := _get_collision_exclusions()

	var ray := PhysicsRayQueryParameters3D.create(global_position, target_pos)
	ray.collide_with_areas = false
	ray.collide_with_bodies = true
	ray.exclude = exclusions
	var ray_hit := space_state.intersect_ray(ray)
	if not ray_hit.is_empty():
		return false

	return _is_spatial_point_vacant(space_state, target_pos, exclusions)

func _is_staging_candidate_clear(candidate_pos: Vector3) -> bool:
	if not is_inside_tree():
		return true
	var world := get_world_3d()
	if world == null:
		return true
	var space_state := world.direct_space_state
	if space_state == null:
		return true

	var exclusions := _get_collision_exclusions()
	return _is_spatial_point_vacant(space_state, candidate_pos, exclusions)

func _is_point_off_screen(world_pos: Vector3) -> bool:
	if _camera == null or not is_instance_valid(_camera):
		return false
	if _camera.is_position_behind(world_pos):
		return true
	var viewport := _camera.get_viewport()
	if viewport == null:
		return false
	var screen_pos: Vector2 = _camera.unproject_position(world_pos)
	var vp_rect: Rect2 = viewport.get_visible_rect()
	return not vp_rect.grow(32.0).has_point(screen_pos)

func _try_hard_rejoin() -> bool:
	if _camera == null or not is_instance_valid(_camera):
		return false
	if not _is_point_off_screen(global_position):
		return false

	var cam_basis := _camera.global_transform.basis
	var cam_fwd := Vector3(-cam_basis.z.x, 0.0, -cam_basis.z.z)
	if cam_fwd.length_squared() > 0.001:
		cam_fwd = cam_fwd.normalized()
	else:
		cam_fwd = Vector3(0, 0, -1)

	var cam_right := Vector3(cam_basis.x.x, 0.0, cam_basis.x.z)
	if cam_right.length_squared() > 0.001:
		cam_right = cam_right.normalized()
	else:
		cam_right = Vector3(1, 0, 0)

	var candidate_dirs: Array[Vector3] = [
		-cam_fwd,
		(-cam_fwd + cam_right).normalized(),
		(-cam_fwd - cam_right).normalized(),
		cam_right
	]

	var source_pos := global_position
	var source_dist := get_follow_distance()

	for dir in candidate_dirs:
		var candidate_pos: Vector3 = _runner.global_position + dir * REJOIN_STAGING_RADIUS_M
		candidate_pos.y = _runner.global_position.y + FOLLOW_HEIGHT_M
		if not _is_point_off_screen(candidate_pos):
			continue
		if not _is_staging_candidate_clear(candidate_pos):
			continue

		global_position = candidate_pos
		_velocity = Vector3.ZERO
		_separation_timer = 0.0
		_hard_rejoin_count += 1
		_last_hard_rejoin_snapshot = {
			"source_position": source_pos,
			"staging_position": candidate_pos,
			"source_off_screen": true,
			"staging_off_screen": true,
			"separation_distance": source_dist,
			"timestamp": Time.get_ticks_msec()
		}
		current_state = PresenceState.REJOINING
		return true

	return false

func _update_thrum_reaction(delta: float) -> void:
	if _thrum_reaction_timer > 0.0:
		_thrum_reaction_timer -= delta
		if _thrum_reaction_timer <= 0.0:
			_thrum_reaction_timer = 0.0
			_apply_thrum_visual(false)

func _apply_thrum_visual(active: bool) -> void:
	if _visual_root:
		_visual_root.rotation.z = deg_to_rad(10.0) if active else 0.0
		_visual_root.position.y = -0.08 if active else 0.0
	if _eye_mat:
		_eye_mat.emission_energy_multiplier = _default_emission_energy * (2.5 if active else 1.0)
