class_name PropQuotaKiosk
extends StaticBody3D

# Municipal Signal Quota Dispensary & Civic Deposit Terminal
# Supports lawful quota deposits, biometric proximity feedback,
# street combat melee tampering (security alarms), and vehicle ram breaches.

enum State {
	READY,
	PROCESSING,
	FULFILLED,
	TAMPER_ALARM,
	BREACHED
}

const MAX_DURABILITY: int = 3
const DEFAULT_QUOTA: int = 150
const BREACH_REWARD: int = 200

@export var required_quota: int = DEFAULT_QUOTA
@export var material_main: Material
@export var material_screen: Material

var current_state: State = State.READY
var current_durability: int = MAX_DURABILITY
var deposited_quota: int = 0
var reward_granted: int = 0

var is_quota_fulfilled: bool:
	get:
		return current_state == State.FULFILLED or deposited_quota >= required_quota

var is_breached: bool:
	get:
		return current_state == State.BREACHED

signal quota_deposited(amount: int, total_deposited: int, remaining: int)
signal quota_fulfilled(total_deposited: int)
signal hit_received(remaining_durability: int, hit_pos: Vector3, impulse_dir: Vector3)
signal kiosk_breached(reward: int, breach_pos: Vector3)
signal alarm_triggered(source_pos: Vector3)

var _alarm_fired: bool = false
var _shake_tween: Tween = null
var _screen_material_instance: Material = null

const QuotaKioskInteractableScript = preload("res://scripts/interactions/quota_kiosk_interactable.gd")

@onready var visual_root: Node3D = $VisualRoot if has_node("VisualRoot") else self
@onready var scanner_light: OmniLight3D = find_child("ScannerLight", true, false) as OmniLight3D
@onready var interactable: Area3D = find_child("QuotaKioskInteractable", true, false) as Area3D

func _ready() -> void:
	add_to_group("damageable")
	add_to_group("strike_target")
	add_to_group("quota_kiosk")
	_setup_materials()
	if interactable:
		interactable.proximity_changed.connect(_on_proximity_changed)

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
			if s == 1 and material_screen:
				_screen_material_instance = material_screen.duplicate()
				mi.set_surface_override_material(s, _screen_material_instance)
			elif material_main:
				mi.set_surface_override_material(s, material_main.duplicate())

func _on_proximity_changed(in_range: bool, _target: Area3D) -> void:
	if not scanner_light or current_state == State.BREACHED:
		return
	var tween := create_tween()
	var target_energy: float = 3.2 if in_range else 1.2
	tween.tween_property(scanner_light, "light_energy", target_energy, 0.2)

func deposit_scrap(amount: int) -> Dictionary:
	if current_state == State.BREACHED:
		return {"success": false, "reason": "BREACHED"}
	if is_quota_fulfilled:
		return {"success": true, "already_fulfilled": true, "total": deposited_quota}

	deposited_quota += amount
	if deposited_quota >= required_quota:
		current_state = State.FULFILLED
		_update_screen_color(Color(0.2, 1.0, 0.4), 1.2)
		if scanner_light:
			scanner_light.light_color = Color(0.2, 1.0, 0.4)
			scanner_light.light_energy = 3.5
		quota_fulfilled.emit(deposited_quota)
	else:
		_update_screen_color(Color(0.0, 0.95, 1.0), 0.8)
		if scanner_light:
			scanner_light.light_color = Color(0.0, 0.95, 1.0)

	var remaining := maxi(0, required_quota - deposited_quota)
	quota_deposited.emit(amount, deposited_quota, remaining)
	return {
		"success": true,
		"amount": amount,
		"total": deposited_quota,
		"remaining": remaining,
		"fulfilled": is_quota_fulfilled
	}

func take_hit(damage: int, hit_pos: Vector3, impulse_dir: Vector3) -> bool:
	if current_state == State.BREACHED:
		return false

	current_durability = maxi(0, current_durability - damage)
	_trigger_impact_reaction(impulse_dir)

	if current_durability <= 0:
		current_state = State.BREACHED
		reward_granted = BREACH_REWARD
		_update_screen_color(Color(0.05, 0.05, 0.05), 0.0)
		if scanner_light:
			scanner_light.visible = false
		kiosk_breached.emit(reward_granted, global_position)
		hit_received.emit(current_durability, hit_pos, impulse_dir)
	else:
		current_state = State.TAMPER_ALARM
		_update_screen_color(Color(1.0, 0.1, 0.1), 1.5)
		if scanner_light:
			scanner_light.light_color = Color(1.0, 0.1, 0.1)
			scanner_light.light_energy = 4.0
		hit_received.emit(current_durability, hit_pos, impulse_dir)

	if not _alarm_fired:
		_alarm_fired = true
		alarm_triggered.emit(global_position)

	return true

func apply_vehicle_ram(impact_speed: float, ram_direction: Vector3, _vehicle_source: Node3D = null) -> bool:
	if impact_speed < 4.5:
		return false
	take_hit(MAX_DURABILITY, global_position, ram_direction)
	return true

func _update_screen_color(col: Color, emission_energy: float = 0.65) -> void:
	if _screen_material_instance is ShaderMaterial:
		(_screen_material_instance as ShaderMaterial).set_shader_parameter("emission_color", col)
		(_screen_material_instance as ShaderMaterial).set_shader_parameter("emission_energy", emission_energy)
	elif _screen_material_instance is StandardMaterial3D:
		(_screen_material_instance as StandardMaterial3D).emission = col
		(_screen_material_instance as StandardMaterial3D).emission_energy_multiplier = emission_energy

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

func reset_kiosk() -> void:
	if is_instance_valid(_shake_tween) and _shake_tween.is_running():
		_shake_tween.kill()
	current_state = State.READY
	current_durability = MAX_DURABILITY
	deposited_quota = 0
	reward_granted = 0
	_alarm_fired = false
	_update_screen_color(Color(0.0, 0.95, 1.0), 0.65)
	if scanner_light:
		scanner_light.visible = true
		scanner_light.light_color = Color(0.0, 0.95, 1.0)
		scanner_light.light_energy = 1.5
	if visual_root:
		visual_root.position = Vector3.ZERO
