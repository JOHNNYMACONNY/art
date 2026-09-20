class_name PropStreetVendor
extends StaticBody3D

# Street Vendor Smuggler Depot Controller
# Commercial sidewalk frontage contraband trading post.
# Supports scrap-for-tune-up economy loop, melee prybar strike tampering,
# and high-speed vehicle ram destruction with knockback physics.

enum VendorState {
	READY,
	TUNED,
	DAMAGED,
	RAMMED
}

const MAX_DURABILITY: int = 3
const TUNE_UP_COST: int = 150
const TUNE_UP_DURATION: float = 8.0
const SPEED_BOOST_MULT: float = 1.35
const ACCEL_BOOST_MULT: float = 1.40
const MIN_RAM_SPEED: float = 4.5

@export var material_main: Material

var current_state: VendorState = VendorState.READY
var current_durability: int = MAX_DURABILITY
var is_rammed: bool = false
var tune_up_timer: float = 0.0

signal tune_up_purchased(cost: int, duration: float, pos: Vector3)
signal hit_received(remaining_durability: int, hit_pos: Vector3, impulse_dir: Vector3)
signal vendor_rammed(impact_speed: float, ram_dir: Vector3)
signal vendor_repaired()

var _initial_transform: Transform3D
var _shake_tween: Tween = null

@onready var visual_root: Node3D = $VisualRoot if has_node("VisualRoot") else self
@onready var interactable: Area3D = find_child("StreetVendorInteractable", true, false) as Area3D
@onready var collision_shape: CollisionShape3D = find_child("CollisionShape3D", true, false) as CollisionShape3D

func _ready() -> void:
	add_to_group("damageable")
	add_to_group("strike_target")
	add_to_group("salvage_targets")
	add_to_group("street_vendors")
	add_to_group("vendors")
	_initial_transform = global_transform
	_setup_materials()
	if interactable:
		interactable.set("vendor", self)

func _process(delta: float) -> void:
	if tune_up_timer > 0.0:
		tune_up_timer -= delta
		if tune_up_timer <= 0.0 and current_state == VendorState.TUNED:
			current_state = VendorState.READY

func _setup_materials() -> void:
	var meshes := find_children("*", "MeshInstance3D", true, false)
	for m in meshes:
		var mi := m as MeshInstance3D
		if not mi:
			continue
		var surf_count: int = mi.get_surface_override_material_count()
		if surf_count == 0 and mi.mesh:
			surf_count = mi.mesh.get_surface_count()
		for s in range(surf_count):
			if material_main:
				mi.set_surface_override_material(s, material_main.duplicate())

func can_trade() -> bool:
	return not is_rammed and current_state != VendorState.RAMMED

func is_tune_up_active() -> bool:
	return current_state == VendorState.TUNED or tune_up_timer > 0.0

func complete_authorized_tune_up(cost: int, vehicle: Node3D) -> void:
	current_state = VendorState.TUNED
	tune_up_timer = TUNE_UP_DURATION
	vehicle.apply_tune_up(TUNE_UP_DURATION, SPEED_BOOST_MULT, ACCEL_BOOST_MULT)
	_trigger_impact_reaction(Vector3.UP * 0.3)
	tune_up_purchased.emit(cost, TUNE_UP_DURATION, global_position)

func purchase_tune_up(cost: int = TUNE_UP_COST, vehicle: Node3D = null) -> Dictionary:
	if not can_trade():
		return {"success": false, "reason": "RAMMED"}
	if is_tune_up_active():
		return {"success": true, "already_active": true, "remaining": tune_up_timer}
	if vehicle != null and not vehicle.has_method("apply_tune_up"):
		return {"success": false, "reason": "UNSUPPORTED_VEHICLE"}

	current_state = VendorState.TUNED
	tune_up_timer = TUNE_UP_DURATION
	if vehicle != null:
		vehicle.apply_tune_up(TUNE_UP_DURATION, SPEED_BOOST_MULT, ACCEL_BOOST_MULT)
	_trigger_impact_reaction(Vector3.UP * 0.3)
	tune_up_purchased.emit(cost, TUNE_UP_DURATION, global_position)
	return {
		"success": true,
		"cost": cost,
		"duration": TUNE_UP_DURATION,
		"speed_mult": SPEED_BOOST_MULT,
		"accel_mult": ACCEL_BOOST_MULT
	}

func take_hit(damage: int, hit_pos: Vector3, impulse_dir: Vector3) -> void:
	if is_rammed:
		return

	current_durability = maxi(0, current_durability - damage)
	_trigger_impact_reaction(impulse_dir)

	if current_durability <= 0:
		current_state = VendorState.DAMAGED

	hit_received.emit(current_durability, hit_pos, impulse_dir)

func apply_vehicle_ram(impact_speed: float, ram_direction: Vector3, _vehicle: Node3D = null) -> bool:
	if impact_speed < MIN_RAM_SPEED:
		return false

	is_rammed = true
	current_state = VendorState.RAMMED
	tune_up_timer = 0.0

	var flat_dir := Vector3(ram_direction.x, 0.0, ram_direction.z).normalized()
	if flat_dir.length_squared() < 0.001:
		flat_dir = Vector3.FORWARD
	var slide_offset := flat_dir * minf(impact_speed * 0.35, 4.0)

	if is_instance_valid(_shake_tween) and _shake_tween.is_running():
		_shake_tween.kill()

	_shake_tween = create_tween()
	_shake_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	_shake_tween.tween_property(self, "global_position", global_position + slide_offset, 0.32)
	if visual_root and visual_root != self:
		_shake_tween.parallel().tween_property(visual_root, "rotation:y", visual_root.rotation.y + deg_to_rad(28.0), 0.32)
		_shake_tween.parallel().tween_property(visual_root, "rotation:z", visual_root.rotation.z + deg_to_rad(14.0), 0.32)

	vendor_rammed.emit(impact_speed, ram_direction)
	return true

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

func reset_vendor() -> void:
	if is_instance_valid(_shake_tween) and _shake_tween.is_running():
		_shake_tween.kill()

	global_transform = _initial_transform
	current_state = VendorState.READY
	current_durability = MAX_DURABILITY
	is_rammed = false
	tune_up_timer = 0.0

	if visual_root and visual_root != self:
		visual_root.position = Vector3.ZERO
		visual_root.rotation = Vector3.ZERO

	vendor_repaired.emit()
