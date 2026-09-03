from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]


def replace_once(rel: str, old: str, new: str) -> None:
    path = ROOT / rel
    text = path.read_text()
    count = text.count(old)
    if count != 1:
        raise SystemExit(f"{rel}: expected exactly one guarded match, found {count}\n--- target ---\n{old}")
    path.write_text(text.replace(old, new, 1))


def append_once(rel: str, marker: str, addition: str) -> None:
    path = ROOT / rel
    text = path.read_text()
    if marker in text:
        raise SystemExit(f"{rel}: append marker already present: {marker}")
    if not text.endswith("\n"):
        text += "\n"
    path.write_text(text + addition)


CONDITION_ENUM = '''enum GearState {\n\tFORWARD,\n\tREVERSE\n}\n'''
CONDITION_ENUM_WITH_STATE = '''enum GearState {\n\tFORWARD,\n\tREVERSE\n}\n\nenum VehicleCondition {\n\tROADWORTHY,\n\tBATTERED,\n\tCRITICAL\n}\n'''

CONDITION_CONSTANTS = '''const CONDITION_MIN_IMPACT_SPEED: float = 4.0\nconst CONDITION_CONTACT_COOLDOWN_SECONDS: float = 0.50\nconst CONDITION_BATTERED_LOAD: float = 0.75\nconst CONDITION_CRITICAL_LOAD: float = 1.50\nconst CONDITION_MAX_LOAD: float = 1.50\nconst CRITICAL_SPEED_MULTIPLIER: float = 0.52\n'''

BIKE_METHODS = r'''

## Burnside Production 07 — coarse, local vehicle consequence. The internal load
## is diagnostic/accumulation state only; the player-facing model remains the
## three-state ROADWORTHY/BATTERED/CRITICAL contract.
func get_condition_name() -> String:
	return VehicleCondition.keys()[_condition]

func get_condition_load() -> float:
	return _condition_load

func get_usable_max_speed() -> float:
	return max_speed * CRITICAL_SPEED_MULTIPLIER if _condition == VehicleCondition.CRITICAL else max_speed

func apply_collision_condition(head_on_ratio: float, impact_speed: float) -> bool:
	if impact_speed < CONDITION_MIN_IMPACT_SPEED or _condition_contact_cooldown > 0.0:
		return false
	var speed_severity := clampf((impact_speed - 3.5) / 7.5, 0.0, 1.0)
	var direction_weight := lerpf(0.50, 1.0, clampf(head_on_ratio, 0.0, 1.0))
	var load_delta := speed_severity * direction_weight
	if load_delta <= 0.0:
		return false
	_condition_load = minf(_condition_load + load_delta, CONDITION_MAX_LOAD)
	_condition_contact_cooldown = CONDITION_CONTACT_COOLDOWN_SECONDS
	_refresh_condition_state()
	return true

func repair_condition() -> bool:
	if _condition == VehicleCondition.ROADWORTHY:
		return false
	_condition_load = 0.0
	_condition_contact_cooldown = 0.0
	_set_condition(VehicleCondition.ROADWORTHY)
	return true

func reset_condition() -> void:
	_condition_load = 0.0
	_condition_contact_cooldown = 0.0
	_set_condition(VehicleCondition.ROADWORTHY)

func get_condition_presentation_snapshot() -> Dictionary:
	return {
		"condition": get_condition_name(),
		"damage_tag_visible": _condition_tag.visible if _condition_tag else false,
		"damage_tag_text": _condition_tag.text if _condition_tag else "",
		"smoke_emitting": _condition_smoke.emitting if _condition_smoke else false,
		"smoke_amount": _condition_smoke.amount if _condition_smoke else 0,
	}

func _refresh_condition_state() -> void:
	var next_condition := VehicleCondition.ROADWORTHY
	if _condition_load >= CONDITION_CRITICAL_LOAD:
		next_condition = VehicleCondition.CRITICAL
	elif _condition_load >= CONDITION_BATTERED_LOAD:
		next_condition = VehicleCondition.BATTERED
	_set_condition(next_condition)

func _set_condition(next_condition: VehicleCondition) -> void:
	var changed := next_condition != _condition
	_condition = next_condition
	if _condition == VehicleCondition.CRITICAL and current_speed > get_usable_max_speed():
		current_speed = get_usable_max_speed()
	_refresh_condition_presentation()
	if changed:
		condition_changed.emit(get_condition_name())

func _ensure_condition_presentation() -> void:
	if _condition_tag == null:
		_condition_tag = Label3D.new()
		_condition_tag.name = "VehicleConditionTag"
		_condition_tag.position = Vector3(0.0, 1.35, 0.15)
		_condition_tag.font_size = 22
		_condition_tag.outline_size = 7
		_condition_tag.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		_condition_tag.modulate = Color(0.92, 0.78, 0.38, 0.95)
		_condition_tag.outline_modulate = Color(0.08, 0.08, 0.07, 0.95)
		_condition_tag.visible = false
		add_child(_condition_tag)

	if _condition_smoke == null:
		_condition_smoke = GPUParticles3D.new()
		_condition_smoke.name = "VehicleConditionSmoke"
		_condition_smoke.position = Vector3(0.0, 0.30, -0.12)
		_condition_smoke.amount = 6
		_condition_smoke.lifetime = 0.85
		_condition_smoke.randomness = 0.45
		_condition_smoke.emitting = false
		_condition_smoke.visibility_aabb = AABB(Vector3(-2.5, -1.0, -2.5), Vector3(5.0, 4.0, 5.0))
		var process_material := ParticleProcessMaterial.new()
		process_material.direction = Vector3(0.0, 1.0, 0.1)
		process_material.spread = 28.0
		process_material.initial_velocity_min = 0.35
		process_material.initial_velocity_max = 0.95
		process_material.gravity = Vector3(0.0, 0.18, 0.0)
		process_material.scale_min = 0.14
		process_material.scale_max = 0.34
		process_material.color = Color(0.14, 0.13, 0.12, 0.42)
		_condition_smoke.process_material = process_material
		var quad := QuadMesh.new()
		quad.size = Vector2(0.32, 0.32)
		var smoke_material := StandardMaterial3D.new()
		smoke_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		smoke_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		smoke_material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		smoke_material.albedo_color = Color(0.13, 0.12, 0.11, 0.34)
		quad.material = smoke_material
		_condition_smoke.draw_pass_1 = quad
		add_child(_condition_smoke)

func _refresh_condition_presentation() -> void:
	_ensure_condition_presentation()
	match _condition:
		VehicleCondition.ROADWORTHY:
			_condition_tag.visible = false
			_condition_smoke.emitting = false
		VehicleCondition.BATTERED:
			_condition_tag.text = "BATTERED"
			_condition_tag.visible = true
			_condition_smoke.amount = 6
			_condition_smoke.speed_scale = 0.8
			_condition_smoke.emitting = true
		VehicleCondition.CRITICAL:
			_condition_tag.text = "CRITICAL // LIMP"
			_condition_tag.visible = true
			_condition_smoke.amount = 12
			_condition_smoke.speed_scale = 1.15
			_condition_smoke.emitting = true
'''

HAULER_METHODS = BIKE_METHODS.replace('Vector3(0.0, 1.35, 0.15)', 'Vector3(0.0, 1.85, 0.15)').replace('Vector3(0.0, 0.30, -0.12)', 'Vector3(0.0, 0.75, -0.35)').replace('Vector3(-2.5, -1.0, -2.5), Vector3(5.0, 4.0, 5.0)', 'Vector3(-3.5, -1.0, -4.0), Vector3(7.0, 5.0, 8.0)')

# Courier Bike: local state, real collision consumption, one forward limp cap, presentation.
replace_once('godot/scripts/vehicles/courier_bike.gd', CONDITION_ENUM, CONDITION_ENUM_WITH_STATE)
replace_once(
    'godot/scripts/vehicles/courier_bike.gd',
    'signal collision_contact(head_on_ratio: float, impact_speed: float, collision_pos: Vector3)\nsignal vehicle_feedback_updated(telemetry: Dictionary, vehicle_pos: Vector3)\n',
    'signal collision_contact(head_on_ratio: float, impact_speed: float, collision_pos: Vector3)\nsignal condition_changed(condition_name: String)\nsignal vehicle_feedback_updated(telemetry: Dictionary, vehicle_pos: Vector3)\n',
)
replace_once(
    'godot/scripts/vehicles/courier_bike.gd',
    'var _slip_dust: GPUParticles3D = null\nconst GEAR_SETTLE_DURATION: float = 0.12\n',
    'var _slip_dust: GPUParticles3D = null\nvar _condition: VehicleCondition = VehicleCondition.ROADWORTHY\nvar _condition_load: float = 0.0\nvar _condition_contact_cooldown: float = 0.0\nvar _condition_smoke: GPUParticles3D = null\nvar _condition_tag: Label3D = null\nconst GEAR_SETTLE_DURATION: float = 0.12\n' + CONDITION_CONSTANTS,
)
replace_once(
    'godot/scripts/vehicles/courier_bike.gd',
    '\t_ensure_slip_dust()\n\nfunc _physics_process(delta: float) -> void:\n\tif _brake_screech_cooldown > 0.0:\n\t\t_brake_screech_cooldown -= delta\n',
    '\t_ensure_slip_dust()\n\t_ensure_condition_presentation()\n\t_refresh_condition_presentation()\n\nfunc _physics_process(delta: float) -> void:\n\tif _brake_screech_cooldown > 0.0:\n\t\t_brake_screech_cooldown -= delta\n\tif _condition_contact_cooldown > 0.0:\n\t\t_condition_contact_cooldown = maxf(_condition_contact_cooldown - delta, 0.0)\n',
)
replace_once(
    'godot/scripts/vehicles/courier_bike.gd',
    '\t\t\tvar new_forward_vel: float = current_speed\n',
    '\t\t\tif current_speed > get_usable_max_speed():\n\t\t\t\tcurrent_speed = get_usable_max_speed()\n\t\t\tvar new_forward_vel: float = current_speed\n',
)
replace_once(
    'godot/scripts/vehicles/courier_bike.gd',
    '\t\t\t\t\t\tcurrent_speed = move_toward(current_speed, 0.0, impact_decay * delta)\n\t\t\t\t\t\tcollision_contact.emit(head_on_ratio, pre_impact_speed, col.get_position())\n',
    '\t\t\t\t\t\tcurrent_speed = move_toward(current_speed, 0.0, impact_decay * delta)\n\t\t\t\t\t\tapply_collision_condition(head_on_ratio, pre_impact_speed)\n\t\t\t\t\t\tcollision_contact.emit(head_on_ratio, pre_impact_speed, col.get_position())\n',
)
replace_once(
    'godot/scripts/vehicles/courier_bike.gd',
    '\t\t\tcurrent_speed = clampf(current_speed + acceleration * throttle * delta, 0.0, max_speed)\n',
    '\t\t\tcurrent_speed = clampf(current_speed + acceleration * throttle * delta, 0.0, get_usable_max_speed())\n',
)
append_once('godot/scripts/vehicles/courier_bike.gd', 'func get_condition_name()', BIKE_METHODS)

# Scrap Hauler mirrors the bounded condition behavior locally; no shared damage base is introduced.
replace_once('godot/scripts/vehicles/scrap_hauler.gd', CONDITION_ENUM, CONDITION_ENUM_WITH_STATE)
replace_once(
    'godot/scripts/vehicles/scrap_hauler.gd',
    'signal collision_contact(head_on_ratio: float, impact_speed: float, collision_pos: Vector3)\n',
    'signal collision_contact(head_on_ratio: float, impact_speed: float, collision_pos: Vector3)\nsignal condition_changed(condition_name: String)\n',
)
replace_once(
    'godot/scripts/vehicles/scrap_hauler.gd',
    'var _brake_screech_cooldown: float = 0.0\nvar _gear_settle_timer: float = 0.0\nconst GEAR_SETTLE_DURATION: float = 0.12\n',
    'var _brake_screech_cooldown: float = 0.0\nvar _gear_settle_timer: float = 0.0\nvar _condition: VehicleCondition = VehicleCondition.ROADWORTHY\nvar _condition_load: float = 0.0\nvar _condition_contact_cooldown: float = 0.0\nvar _condition_smoke: GPUParticles3D = null\nvar _condition_tag: Label3D = null\nconst GEAR_SETTLE_DURATION: float = 0.12\n' + CONDITION_CONSTANTS,
)
replace_once(
    'godot/scripts/vehicles/scrap_hauler.gd',
    '\tif mount_interactable:\n\t\tmount_interactable.interaction_priority = 2.0\n\t\tmount_interactable.is_powered = true\n\nfunc _process(_delta: float) -> void:\n',
    '\tif mount_interactable:\n\t\tmount_interactable.interaction_priority = 2.0\n\t\tmount_interactable.is_powered = true\n\t_ensure_condition_presentation()\n\t_refresh_condition_presentation()\n\nfunc _process(_delta: float) -> void:\n',
)
replace_once(
    'godot/scripts/vehicles/scrap_hauler.gd',
    'func _physics_process(delta: float) -> void:\n\tif _brake_screech_cooldown > 0.0:\n\t\t_brake_screech_cooldown -= delta\n',
    'func _physics_process(delta: float) -> void:\n\tif _brake_screech_cooldown > 0.0:\n\t\t_brake_screech_cooldown -= delta\n\tif _condition_contact_cooldown > 0.0:\n\t\t_condition_contact_cooldown = maxf(_condition_contact_cooldown - delta, 0.0)\n',
)
replace_once(
    'godot/scripts/vehicles/scrap_hauler.gd',
    '\t\t\tvar new_forward_vel: float = current_speed\n',
    '\t\t\tif current_speed > get_usable_max_speed():\n\t\t\t\tcurrent_speed = get_usable_max_speed()\n\t\t\tvar new_forward_vel: float = current_speed\n',
)
replace_once(
    'godot/scripts/vehicles/scrap_hauler.gd',
    '\t\t\t\t\t\tcurrent_speed = move_toward(current_speed, 0.0, impact_decay * delta)\n\t\t\t\t\t\tcollision_contact.emit(head_on_ratio, pre_impact_speed, col.get_position())\n',
    '\t\t\t\t\t\tcurrent_speed = move_toward(current_speed, 0.0, impact_decay * delta)\n\t\t\t\t\t\tapply_collision_condition(head_on_ratio, pre_impact_speed)\n\t\t\t\t\t\tcollision_contact.emit(head_on_ratio, pre_impact_speed, col.get_position())\n',
)
replace_once(
    'godot/scripts/vehicles/scrap_hauler.gd',
    '\t\t\tcurrent_speed = move_toward(current_speed, max_speed, acceleration * throttle * delta)\n',
    '\t\t\tcurrent_speed = move_toward(current_speed, get_usable_max_speed(), acceleration * throttle * delta)\n',
)
append_once('godot/scripts/vehicles/scrap_hauler.gd', 'func get_condition_name()', HAULER_METHODS)

# Burn Garage runtime: one authored socket, one existing Action, read-only Wanted eligibility.
runtime_path = ROOT / 'godot/scripts/world/burn_garage_repair_runtime.gd'
if runtime_path.exists():
    raise SystemExit('burn_garage_repair_runtime.gd unexpectedly already exists')
runtime_path.write_text(r'''class_name BurnGarageRepairRuntime
extends Node3D

## Burnside Production 07 / #137
## Bounded Garage repair adapter over retained vehicle, interaction, Wanted and
## authored Gears geography. It owns vehicle repair eligibility only.

const InteractableBaseScript = preload("res://scripts/interactions/interactable_base.gd")
const REPAIR_SOCKET_PATH := "MissionDestinationSocket"
const REPAIR_RADIUS_M := 2.6
const REPAIR_STOP_SPEED_MPS := 0.35
const AFFORDANCE_RADIUS_M := 8.0
const SUCCESS_FEEDBACK_MSEC := 1200

var _root_controller: Node = null
var _district: Node3D = null
var _wanted_runtime: Node = null
var _repair_socket: Marker3D = null
var _repair_interactable: InteractableBase = null
var _affordance_label: Label3D = null
var _affordance_text: String = ""
var _success_until_msec: int = 0
var _bound: bool = false

func configure(root_controller: Node, district: Node3D, wanted_runtime: Node) -> bool:
	if root_controller == null or district == null or wanted_runtime == null:
		return false
	if not root_controller.has_method("_get_active_vehicle"):
		return false
	if not wanted_runtime.has_method("get_heat_level") or not wanted_runtime.has_method("get_wanted_state_name"):
		return false
	var socket := district.get_node_or_null(REPAIR_SOCKET_PATH) as Marker3D
	var touch_ui := root_controller.get_node_or_null("CanvasLayer/TouchControlsUI")
	var interactables = root_controller.get("_interactables")
	if socket == null or touch_ui == null or not (interactables is Array):
		return false

	_root_controller = root_controller
	_district = district
	_wanted_runtime = wanted_runtime
	_repair_socket = socket

	_repair_interactable = InteractableBaseScript.new() as InteractableBase
	if _repair_interactable == null:
		return false
	_repair_interactable.name = "BurnGarageRepairInteractable"
	_repair_interactable.interaction_radius = REPAIR_RADIUS_M
	_repair_interactable.sensory_radius = AFFORDANCE_RADIUS_M
	_repair_interactable.interaction_priority = 3.5
	_repair_interactable.is_powered = false
	add_child(_repair_interactable)
	_repair_interactable.global_position = _repair_socket.global_position
	if not interactables.has(_repair_interactable):
		interactables.append(_repair_interactable)

	_affordance_label = Label3D.new()
	_affordance_label.name = "BurnGarageRepairAffordance"
	_affordance_label.global_position = _repair_socket.global_position + Vector3(0.0, 1.15, 0.0)
	_affordance_label.font_size = 22
	_affordance_label.outline_size = 8
	_affordance_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_affordance_label.modulate = Color(0.95, 0.79, 0.30, 0.96)
	_affordance_label.outline_modulate = Color(0.08, 0.08, 0.07, 0.96)
	_affordance_label.visible = false
	add_child(_affordance_label)

	var action_callable := Callable(self, "handle_action_pressed")
	if not touch_ui.action_button_pressed.is_connected(action_callable):
		touch_ui.action_button_pressed.connect(action_callable)

	_bound = true
	set_process(true)
	return true

func _exit_tree() -> void:
	if _root_controller == null or _repair_interactable == null:
		return
	var interactables = _root_controller.get("_interactables")
	if interactables is Array:
		interactables.erase(_repair_interactable)

func _process(_delta: float) -> void:
	if not _bound or _repair_interactable == null or _repair_socket == null:
		return
	var now := Time.get_ticks_msec()
	if now < _success_until_msec:
		_repair_interactable.is_powered = false
		_set_affordance("ROADWORTHY", true)
		return

	var vehicle := _get_active_vehicle()
	if not _is_supported_vehicle(vehicle) or String(vehicle.call("get_condition_name")) == "ROADWORTHY":
		_repair_interactable.is_powered = false
		_set_affordance("", false)
		return

	_repair_interactable.is_powered = true
	_repair_interactable.update_player_distance(vehicle.global_position)
	var distance := vehicle.global_position.distance_to(_repair_socket.global_position)
	if distance > AFFORDANCE_RADIUS_M:
		_set_affordance("", false)
		return
	if distance <= REPAIR_RADIUS_M:
		if abs(float(vehicle.get("current_speed"))) > REPAIR_STOP_SPEED_MPS:
			_set_affordance("STOP TO REPAIR", true)
		elif not _wanted_is_clear():
			_set_affordance("WANTED // SERVICE LOCKED", true)
		else:
			_set_affordance("REPAIR // ACTION", true)
	else:
		_set_affordance("BURN // REPAIR", true)

func handle_action_pressed() -> bool:
	if not _bound or _root_controller == null or _repair_interactable == null:
		return false
	if _root_controller.get("_active_target") != _repair_interactable:
		return false
	return attempt_repair(_get_active_vehicle())

func attempt_repair(vehicle: Node) -> bool:
	if not _bound or vehicle == null or vehicle != _get_active_vehicle():
		return false
	if not _is_supported_vehicle(vehicle):
		return false
	if String(vehicle.call("get_condition_name")) == "ROADWORTHY":
		return false
	if not is_vehicle_in_repair_radius(vehicle):
		return false
	if abs(float(vehicle.get("current_speed"))) > REPAIR_STOP_SPEED_MPS:
		return false
	if not _wanted_is_clear():
		return false
	if not bool(vehicle.call("repair_condition")):
		return false
	_success_until_msec = Time.get_ticks_msec() + SUCCESS_FEEDBACK_MSEC
	_repair_interactable.is_powered = false
	_set_affordance("ROADWORTHY", true)
	return true

func is_vehicle_in_repair_radius(vehicle: Node) -> bool:
	return vehicle is Node3D and _repair_socket != null \
		and (vehicle as Node3D).global_position.distance_to(_repair_socket.global_position) <= REPAIR_RADIUS_M

func get_repair_socket_position() -> Vector3:
	return _repair_socket.global_position if _repair_socket != null else Vector3.INF

func get_repair_interactable() -> InteractableBase:
	return _repair_interactable

func get_affordance_text() -> String:
	return _affordance_text

func _get_active_vehicle() -> Node:
	if _root_controller == null or not _root_controller.has_method("_get_active_vehicle"):
		return null
	var vehicle = _root_controller.call("_get_active_vehicle")
	return vehicle if vehicle is Node else null

func _is_supported_vehicle(vehicle: Node) -> bool:
	return vehicle is CourierBike or vehicle is ScrapHauler

func _wanted_is_clear() -> bool:
	return _wanted_runtime != null \
		and _wanted_runtime.has_method("get_heat_level") \
		and _wanted_runtime.has_method("get_wanted_state_name") \
		and int(_wanted_runtime.call("get_heat_level")) == 0 \
		and String(_wanted_runtime.call("get_wanted_state_name")) == "CLEAR"

func _set_affordance(text: String, visible_value: bool) -> void:
	_affordance_text = text
	if _affordance_label != null:
		_affordance_label.text = text
		_affordance_label.visible = visible_value
''')

# Mount P07 through the retained spatial composition seam, keeping gameplay authority in the root runtime.
replace_once(
    'godot/scripts/visual/gears_district_slice_01b.gd',
    'const GearsSurveyedServiceCutRuntimeScript = preload("res://scripts/world/gears_surveyed_service_cut_runtime.gd")\n',
    'const GearsSurveyedServiceCutRuntimeScript = preload("res://scripts/world/gears_surveyed_service_cut_runtime.gd")\nconst BurnGarageRepairRuntimeScript = preload("res://scripts/world/burn_garage_repair_runtime.gd")\n',
)
replace_once(
    'godot/scripts/visual/gears_district_slice_01b.gd',
    '\tcall_deferred("_mount_production_06_surveyed_service_cut")\n',
    '\tcall_deferred("_mount_production_06_surveyed_service_cut")\n\tcall_deferred("_mount_production_07_burn_garage_repair")\n',
)
replace_once(
    'godot/scripts/visual/gears_district_slice_01b.gd',
    '\tif not bool(runtime.call("configure", scene_root, self)):\n\t\truntime.queue_free()\n\nfunc _box_shape(node_path: String) -> BoxShape3D:\n',
    '\tif not bool(runtime.call("configure", scene_root, self)):\n\t\truntime.queue_free()\n\nfunc _mount_production_07_burn_garage_repair() -> void:\n\tvar scene_root := get_parent()\n\tif scene_root == null or not (scene_root is Node3D):\n\t\treturn\n\tif scene_root.get_node_or_null("BurnGarageRepairRuntime") != null:\n\t\treturn\n\tvar wanted_runtime := get_tree().root.get_node_or_null("BurnsideWantedRuntime")\n\tif wanted_runtime == null:\n\t\treturn\n\tvar runtime := BurnGarageRepairRuntimeScript.new() as Node3D\n\tif runtime == null:\n\t\treturn\n\truntime.name = "BurnGarageRepairRuntime"\n\tscene_root.add_child(runtime)\n\tif not bool(runtime.call("configure", scene_root, self, wanted_runtime)):\n\t\truntime.queue_free()\n\nfunc _box_shape(node_path: String) -> BoxShape3D:\n',
)

# Existing controller already has generic active-vehicle truth; use it in the two remaining Bike-specific interaction calculations.
replace_once(
    'godot/scripts/prototype/scrap_test_block.gd',
    '\tvar best_target: InteractableBase = null\n\tvar best_score: float = -9999.0\n\tvar active_pos: Vector3 = courier_bike.global_position if (courier_bike and courier_bike.current_state == CourierBike.BikeState.DRIVING) else player.global_position\n',
    '\tvar best_target: InteractableBase = null\n\tvar best_score: float = -9999.0\n\tvar active_veh := _get_active_vehicle()\n\tvar active_pos: Vector3 = active_veh.global_position if active_veh else player.global_position\n',
)
replace_once(
    'godot/scripts/prototype/scrap_test_block.gd',
    '\tvar active_pos: Vector3 = courier_bike.global_position if (courier_bike and courier_bike.current_state == CourierBike.BikeState.DRIVING) else player.global_position\n\t\t\n\tif _active_target is MountInteractable:\n',
    '\tvar active_veh := _get_active_vehicle()\n\tvar active_pos: Vector3 = active_veh.global_position if active_veh else player.global_position\n\t\t\n\tif _active_target is MountInteractable:\n',
)
replace_once(
    'godot/scripts/prototype/scrap_test_block.gd',
    'func reset_slice() -> void:\n\tif courier_bike and courier_bike.occupant != null:\n\t\tcourier_bike.force_dismount()\n\tif scrap_hauler and scrap_hauler.occupant != null:\n\t\tscrap_hauler.force_dismount()\n\tactive_vehicle = null\n',
    'func reset_slice() -> void:\n\tif courier_bike and courier_bike.occupant != null:\n\t\tcourier_bike.force_dismount()\n\tif scrap_hauler and scrap_hauler.occupant != null:\n\t\tscrap_hauler.force_dismount()\n\tif courier_bike and courier_bike.has_method("reset_condition"):\n\t\tcourier_bike.reset_condition()\n\tif scrap_hauler and scrap_hauler.has_method("reset_condition"):\n\t\tscrap_hauler.reset_condition()\n\tactive_vehicle = null\n',
)

print('P07 GREEN guarded patches applied')
