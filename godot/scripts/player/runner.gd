class_name PlayerRunner
extends CharacterBody3D

# Runner Locomotion & Hero Identity Script
# Screen-relative analog movement, floating left-thumb joystick support, 8-way visual facing,
# authentic skeletal animation blending (idle, walk, run, bike_ride), and mounted motorcycle riding posture.

@export var move_speed: float = 8.5
@export var acceleration: float = 40.0
@export var friction: float = 35.0

@export var material_main: Material
@export var material_visor: Material
@export var material_comm: Material

@onready var mesh_pivot: Node3D = $MeshPivot
@onready var torso_node: Node3D = $MeshPivot/Torso
@onready var head_node: Node3D = $MeshPivot/Head
@onready var left_arm: Node3D = $MeshPivot/LeftArm
@onready var right_arm: Node3D = $MeshPivot/RightArm
@onready var left_leg: Node3D = $MeshPivot/LeftLeg
@onready var right_leg: Node3D = $MeshPivot/RightLeg
@onready var anim_player: AnimationPlayer = $MeshPivot/Model/AnimationPlayer if has_node("MeshPivot/Model/AnimationPlayer") else null

var joystick_vector := Vector2.ZERO
var is_input_locked: bool = false
var is_mounted: bool = false

signal footstep_triggered

var _step_timer: float = 0.0
var _anim_time: float = 0.0

func _ready() -> void:
	_setup_mesh_materials()
	_setup_car_animations()
	_setup_bike_animations()
	_reset_standing_pose()
	if anim_player and anim_player.has_animation("idle"):
		anim_player.play("idle")

func _setup_car_animations() -> void:
	if not anim_player:
		return
	var lib := anim_player.get_animation_library("")
	if not lib:
		return
	if ResourceLoader.exists("res://scenes/player/anim_car_drive.res"):
		if lib.has_animation("car_drive"):
			lib.remove_animation("car_drive")
		lib.add_animation("car_drive", load("res://scenes/player/anim_car_drive.res"))
	if ResourceLoader.exists("res://scenes/player/anim_car_steer_left.res"):
		if lib.has_animation("car_steer_left"):
			lib.remove_animation("car_steer_left")
		lib.add_animation("car_steer_left", load("res://scenes/player/anim_car_steer_left.res"))
	if ResourceLoader.exists("res://scenes/player/anim_car_steer_right.res"):
		if lib.has_animation("car_steer_right"):
			lib.remove_animation("car_steer_right")
		lib.add_animation("car_steer_right", load("res://scenes/player/anim_car_steer_right.res"))

func _setup_bike_animations() -> void:
	if not anim_player:
		return
	var lib := anim_player.get_animation_library("")
	if not lib:
		return
	if ResourceLoader.exists("res://scenes/player/anim_bike_ride.res"):
		if lib.has_animation("bike_ride"):
			lib.remove_animation("bike_ride")
		lib.add_animation("bike_ride", load("res://scenes/player/anim_bike_ride.res"))
	if ResourceLoader.exists("res://scenes/player/anim_bike_lean_left.res"):
		if lib.has_animation("bike_lean_left"):
			lib.remove_animation("bike_lean_left")
		lib.add_animation("bike_lean_left", load("res://scenes/player/anim_bike_lean_left.res"))
	if ResourceLoader.exists("res://scenes/player/anim_bike_lean_right.res"):
		if lib.has_animation("bike_lean_right"):
			lib.remove_animation("bike_lean_right")
		lib.add_animation("bike_lean_right", load("res://scenes/player/anim_bike_lean_right.res"))

const SKIN_ATLASES = {
	"DEFAULT": preload("res://textures/urban_clutter/tex_runner_atlas.png"),
	"SILENT_CORE": preload("res://textures/urban_clutter/tex_runner_atlas_silent_core.png")
}

@export_enum("DEFAULT", "SILENT_CORE") var skin_variant: String = "DEFAULT":
	set(val):
		skin_variant = val
		if is_node_ready():
			set_skin(skin_variant)

func _setup_mesh_materials() -> void:
	var runner_mesh := find_child("Runner_Mesh", true, false) as MeshInstance3D
	if runner_mesh:
		if material_main:
			runner_mesh.set_surface_override_material(0, material_main.duplicate())
		if material_visor:
			runner_mesh.set_surface_override_material(1, material_visor.duplicate())
		if material_comm:
			runner_mesh.set_surface_override_material(2, material_comm.duplicate())
	if skin_variant != "DEFAULT":
		set_skin(skin_variant)

func set_skin(skin_id: String) -> void:
	skin_variant = skin_id
	if not SKIN_ATLASES.has(skin_id):
		return
	var atlas: Texture2D = SKIN_ATLASES[skin_id]
	var runner_mesh := find_child("Runner_Mesh", true, false) as MeshInstance3D
	if not runner_mesh:
		return
	for i in range(3):
		var mat := runner_mesh.get_surface_override_material(i)
		if mat is ShaderMaterial:
			mat.set_shader_parameter("albedo_texture", atlas)
		else:
			var base_src := material_main if i == 0 else (material_visor if i == 1 else material_comm)
			if base_src is ShaderMaterial:
				var new_mat := base_src.duplicate() as ShaderMaterial
				new_mat.set_shader_parameter("albedo_texture", atlas)
				runner_mesh.set_surface_override_material(i, new_mat)



var current_vehicle_posture: String = "none"
var current_steering: float = 0.0
var target_steering: float = 0.0

func set_vehicle_steering(steer: float) -> void:
	target_steering = clampf(steer, -1.0, 1.0)

func _physics_process(delta: float) -> void:
	if is_mounted:
		current_steering = move_toward(current_steering, target_steering, delta * 8.0)
		if current_vehicle_posture == "car":
			var target_anim := "car_drive"
			if current_steering > 0.15:
				target_anim = "car_steer_right"
			elif current_steering < -0.15:
				target_anim = "car_steer_left"
			if anim_player and anim_player.has_animation(target_anim):
				if anim_player.current_animation != target_anim:
					anim_player.play(target_anim, 0.15)
		else:
			var target_anim := "bike_ride"
			if current_steering > 0.15:
				target_anim = "bike_lean_right"
			elif current_steering < -0.15:
				target_anim = "bike_lean_left"
			if anim_player and anim_player.has_animation(target_anim):
				if anim_player.current_animation != target_anim:
					anim_player.play(target_anim, 0.15)
		return

	if is_input_locked:
		velocity = Vector3.ZERO
		_reset_standing_pose()
		if anim_player and anim_player.has_animation("idle"):
			if anim_player.current_animation != "idle":
				anim_player.play("idle", 0.2)
		return

	# Touch joystick has authority while active; otherwise accept physical/logical desktop keys.
	var input_dir := joystick_vector
	if input_dir.length() < 0.05:
		var kb_x: float = 0.0
		var kb_y: float = 0.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT) or Input.is_key_pressed(KEY_RIGHT) or Input.is_action_pressed("ui_right"):
			kb_x += 1.0
		if Input.is_physical_key_pressed(KEY_A) or Input.is_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT) or Input.is_key_pressed(KEY_LEFT) or Input.is_action_pressed("ui_left"):
			kb_x -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN) or Input.is_key_pressed(KEY_DOWN) or Input.is_action_pressed("ui_down"):
			kb_y += 1.0
		if Input.is_physical_key_pressed(KEY_W) or Input.is_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP) or Input.is_key_pressed(KEY_UP) or Input.is_action_pressed("ui_up"):
			kb_y -= 1.0
		input_dir = Vector2(kb_x, kb_y)
		if input_dir.length() > 1.0:
			input_dir = input_dir.normalized()

	if input_dir.length() > 0.05:
		# Preserve analog touch magnitude while deriving direction from the live camera basis.
		var input_strength: float = minf(input_dir.length(), 1.0)
		var normalized_input := input_dir.normalized()

		# Project the active camera's basis onto the horizontal plane. If no camera is
		# active yet, retain the historical 45-degree frame as a startup fallback.
		var camera_3d := get_viewport().get_camera_3d() if is_inside_tree() else null
		var forward_xz := Vector3(-0.707107, 0.0, -0.707107)
		var right_xz := Vector3(0.707107, 0.0, -0.707107)
		if camera_3d:
			var camera_basis := camera_3d.global_transform.basis
			var forward_candidate := Vector3(-camera_basis.z.x, 0.0, -camera_basis.z.z)
			if forward_candidate.length_squared() > 0.001:
				forward_xz = forward_candidate.normalized()
			var right_candidate := Vector3(camera_basis.x.x, 0.0, camera_basis.x.z)
			if right_candidate.length_squared() > 0.001:
				right_xz = right_candidate.normalized()

		# Screen space: Up = -Y, Down = +Y, Left = -X, Right = +X.
		var move_dir := (right_xz * normalized_input.x + forward_xz * (-normalized_input.y)).normalized()
		var target_vel := move_dir * (move_speed * input_strength)

		velocity = velocity.move_toward(target_vel, acceleration * delta)

		# 8-Way visual mesh facing direction
		if mesh_pivot:
			var target_angle := atan2(-move_dir.x, -move_dir.z)
			var snap_step: float = PI / 4.0
			var snapped_angle: float = round(target_angle / snap_step) * snap_step
			mesh_pivot.rotation.y = lerp_angle(mesh_pivot.rotation.y, snapped_angle, delta * 15.0)

		# Skeletal locomotion animation
		var cur_speed := velocity.length()
		if anim_player:
			if cur_speed < 4.5 and anim_player.has_animation("walk"):
				if anim_player.current_animation != "walk":
					anim_player.play("walk", 0.15)
				anim_player.speed_scale = clampf(cur_speed / 3.2, 0.6, 1.4)
			elif anim_player.has_animation("run"):
				if anim_player.current_animation != "run":
					anim_player.play("run", 0.15)
				anim_player.speed_scale = clampf(cur_speed / 8.5, 0.8, 1.6)

		# Compatibility procedural stride on dummy nodes
		_anim_time += delta * velocity.length() * 2.2
		var leg_swing: float = sin(_anim_time) * 0.55
		var arm_swing: float = sin(_anim_time) * 0.45
		if left_leg: left_leg.rotation.x = leg_swing
		if right_leg: right_leg.rotation.x = -leg_swing
		if left_arm: left_arm.rotation.x = -arm_swing
		if right_arm: right_arm.rotation.x = arm_swing
		if torso_node: torso_node.position.y = 1.15 + abs(sin(_anim_time * 2.0)) * 0.04
		if head_node: head_node.position = Vector3(0, 1.48 + abs(sin(_anim_time * 2.0)) * 0.03, -0.06)

		# Trigger footstep audio event periodically
		_step_timer += delta * velocity.length()
		if _step_timer > 3.0:
			_step_timer = 0.0
			emit_signal("footstep_triggered")
	else:
		velocity = velocity.move_toward(Vector3.ZERO, friction * delta)
		_step_timer = 0.0
		_reset_standing_pose()
		if anim_player and anim_player.has_animation("idle"):
			if anim_player.current_animation != "idle":
				anim_player.play("idle", 0.2)
				anim_player.speed_scale = 1.0

	move_and_slide()

func set_joystick_input(vec: Vector2) -> void:
	joystick_vector = vec

func set_mounted_posture(mounted: bool) -> void:
	set_vehicle_driving_posture(mounted, "bike")

func set_vehicle_driving_posture(mounted: bool, posture_type: String = "car") -> void:
	is_mounted = mounted
	current_vehicle_posture = posture_type if mounted else "none"
	if not mesh_pivot:
		return

	if is_instance_valid(anim_player):
		if mounted:
			if posture_type == "car" and anim_player.has_animation("car_drive"):
				anim_player.play("car_drive", 0.15)
			elif anim_player.has_animation("bike_ride"):
				anim_player.play("bike_ride", 0.15)
		elif anim_player.has_animation("idle"):
			anim_player.play("idle", 0.2)

	if mounted and posture_type == "car":
		# Automotive driving posture: reclined lumbar spine against backrest, head upright, hands at 10-and-2
		if torso_node:
			torso_node.position = Vector3(0, 0.45, -0.05)
			torso_node.rotation.x = deg_to_rad(12.0)
		if head_node:
			head_node.position = Vector3(0, 0.78, -0.04)
			head_node.rotation.x = deg_to_rad(-8.0)
		if left_arm:
			left_arm.position = Vector3(-0.24, 0.58, 0.15)
			left_arm.rotation.x = deg_to_rad(-45.0)
			left_arm.rotation.y = deg_to_rad(-12.0)
		if right_arm:
			right_arm.position = Vector3(0.24, 0.58, 0.15)
			right_arm.rotation.x = deg_to_rad(-45.0)
			right_arm.rotation.y = deg_to_rad(12.0)
		if left_leg:
			left_leg.position = Vector3(-0.18, 0.25, 0.25)
			left_leg.rotation.x = deg_to_rad(-80.0)
			left_leg.rotation.y = deg_to_rad(8.0)
		if right_leg:
			right_leg.position = Vector3(0.18, 0.25, 0.25)
			right_leg.rotation.x = deg_to_rad(-80.0)
			right_leg.rotation.y = deg_to_rad(-8.0)
		mesh_pivot.rotation.y = 0.0
	elif mounted and posture_type == "bike":
		# Riding motorcycle posture: seated, forward crouch, hands reaching forward to grips
		if torso_node:
			torso_node.position = Vector3(0, 0.48, 0.08)
			torso_node.rotation.x = deg_to_rad(-26.0)
		if head_node:
			head_node.position = Vector3(0, 0.80, -0.18)
			head_node.rotation.x = deg_to_rad(14.0)
		if left_arm:
			left_arm.position = Vector3(-0.27, 0.60, -0.06)
			left_arm.rotation.x = deg_to_rad(-65.0)
			left_arm.rotation.y = deg_to_rad(-15.0)
		if right_arm:
			right_arm.position = Vector3(0.27, 0.60, -0.06)
			right_arm.rotation.x = deg_to_rad(-65.0)
			right_arm.rotation.y = deg_to_rad(15.0)
		if left_leg:
			left_leg.position = Vector3(-0.24, 0.28, 0.12)
			left_leg.rotation.x = deg_to_rad(-70.0)
			left_leg.rotation.y = deg_to_rad(18.0)
		if right_leg:
			right_leg.position = Vector3(0.24, 0.28, 0.12)
			right_leg.rotation.x = deg_to_rad(-70.0)
			right_leg.rotation.y = deg_to_rad(-18.0)
		mesh_pivot.rotation.y = 0.0
	else:
		_reset_standing_pose()

func _reset_standing_pose() -> void:
	if torso_node:
		torso_node.position = Vector3(0, 1.15, 0)
		torso_node.rotation.x = deg_to_rad(-6.0)
	if head_node:
		head_node.position = Vector3(0, 1.48, -0.06)
		head_node.rotation.x = deg_to_rad(6.0)
	if left_arm:
		left_arm.position = Vector3(-0.28, 1.28, -0.04)
		left_arm.rotation = Vector3(deg_to_rad(8.0), 0, deg_to_rad(-4.0))
	if right_arm:
		right_arm.position = Vector3(0.28, 1.28, -0.04)
		right_arm.rotation = Vector3(deg_to_rad(-10.0), 0, deg_to_rad(4.0))
	if left_leg:
		left_leg.position = Vector3(-0.13, 0.85, 0.03)
		left_leg.rotation = Vector3(deg_to_rad(-4.0), 0, 0)
	if right_leg:
		right_leg.position = Vector3(0.13, 0.85, -0.04)
		right_leg.rotation = Vector3(deg_to_rad(6.0), 0, 0)
