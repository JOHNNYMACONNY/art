class_name PropScrapDumpster
extends StaticBody3D

# Municipal Scrap Dumpster Controller
# Street Combat, Scavenging, and Stealth Evasion slice.
# Supports scrap scavenging, hiding evasion, melee tampering, and vehicle ram knockback.

enum DumpsterState {
	READY,
	SCAVENGED,
	OCCUPIED_HIDING,
	DAMAGED,
	RAMMED
}

const MAX_DURABILITY: int = 3
const SCAVENGE_REWARD: int = 75
const MIN_RAM_SPEED: float = 4.5

@export var material_main: Material

var current_state: DumpsterState = DumpsterState.READY
var current_durability: int = MAX_DURABILITY
var reward_granted: int = 0
var is_rammed: bool = false
var hiding_player: CharacterBody3D = null

signal hit_received(remaining_durability: int, hit_pos: Vector3, impulse_dir: Vector3)
signal dumpster_scavenged(reward: int, pos: Vector3)
signal player_entered_hiding(player: CharacterBody3D)
signal player_exited_hiding(player: CharacterBody3D)
signal dumpster_rammed(impact_speed: float, ram_dir: Vector3)

var _initial_transform: Transform3D
var _shake_tween: Tween = null

@onready var visual_root: Node3D = $VisualRoot if has_node("VisualRoot") else self
@onready var interactable: Area3D = find_child("ScrapDumpsterInteractable", true, false) as Area3D
@onready var collision_shape: CollisionShape3D = find_child("CollisionShape3D", true, false) as CollisionShape3D

func _ready() -> void:
	add_to_group("damageable")
	add_to_group("strike_target")
	add_to_group("salvage_targets")
	add_to_group("dumpsters")
	_initial_transform = global_transform
	_setup_materials()
	if interactable:
		interactable.set("dumpster", self)

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

func can_hide() -> bool:
	return current_state != DumpsterState.OCCUPIED_HIDING and not is_rammed

func is_scavenged() -> bool:
	return current_state == DumpsterState.SCAVENGED or reward_granted > 0

func scavenge_scrap() -> int:
	if is_rammed or current_state == DumpsterState.OCCUPIED_HIDING:
		return 0
	if reward_granted > 0:
		return 0
	
	reward_granted = SCAVENGE_REWARD
	current_state = DumpsterState.SCAVENGED
	_trigger_impact_reaction(Vector3.UP * 0.5)
	dumpster_scavenged.emit(reward_granted, global_position)
	return reward_granted

func enter_hiding(player: CharacterBody3D) -> bool:
	if not can_hide() or not player:
		return false
	
	current_state = DumpsterState.OCCUPIED_HIDING
	hiding_player = player
	
	player.is_input_locked = true
	player.visible = false
	if "velocity" in player:
		player.velocity = Vector3.ZERO
	
	_trigger_impact_reaction(Vector3.DOWN * 0.4)
	player_entered_hiding.emit(player)
	return true

func exit_hiding(player: CharacterBody3D = null) -> bool:
	if current_state != DumpsterState.OCCUPIED_HIDING:
		return false
	
	var p := player if player else hiding_player
	if p:
		p.visible = true
		p.is_input_locked = false
		var exit_pos := global_position + global_transform.basis.z * 1.5
		exit_pos.y = 0.05
		p.global_position = exit_pos
		hiding_player = null
	
	current_state = DumpsterState.SCAVENGED if reward_granted > 0 else DumpsterState.READY
	_trigger_impact_reaction(Vector3.UP * 0.4)
	player_exited_hiding.emit(p)
	return true

func take_hit(damage: int, hit_pos: Vector3, impulse_dir: Vector3) -> void:
	if is_rammed:
		return
	
	if current_state == DumpsterState.OCCUPIED_HIDING:
		exit_hiding()
	
	current_durability = maxi(0, current_durability - damage)
	_trigger_impact_reaction(impulse_dir)
	
	if current_durability <= 0:
		if reward_granted == 0:
			scavenge_scrap()
		current_state = DumpsterState.DAMAGED
	
	hit_received.emit(current_durability, hit_pos, impulse_dir)

func apply_vehicle_ram(impact_speed: float, ram_direction: Vector3, _vehicle: Node3D = null) -> bool:
	if impact_speed < MIN_RAM_SPEED:
		return false
	
	var ejected_p := hiding_player
	if current_state == DumpsterState.OCCUPIED_HIDING:
		exit_hiding()
		if ejected_p and "velocity" in ejected_p:
			ejected_p.velocity += ram_direction.normalized() * 5.5
	
	if reward_granted == 0:
		scavenge_scrap()
	
	is_rammed = true
	current_state = DumpsterState.RAMMED
	
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
		_shake_tween.parallel().tween_property(visual_root, "rotation:y", visual_root.rotation.y + deg_to_rad(22.0), 0.32)
	
	dumpster_rammed.emit(impact_speed, ram_direction)
	return true

func _trigger_impact_reaction(impulse_dir: Vector3) -> void:
	if is_instance_valid(_shake_tween) and _shake_tween.is_running():
		_shake_tween.kill()
	
	if not visual_root or visual_root == self:
		return
	
	var punch_offset := impulse_dir.normalized() * 0.08
	punch_offset.y = 0.05
	
	_shake_tween = create_tween()
	_shake_tween.set_trans(Tween.TRANS_ELASTIC)
	_shake_tween.set_ease(Tween.EASE_OUT)
	_shake_tween.tween_property(visual_root, "position", visual_root.position + punch_offset, 0.06)
	_shake_tween.tween_property(visual_root, "position", Vector3.ZERO, 0.18)

func reset_dumpster() -> void:
	if is_instance_valid(_shake_tween) and _shake_tween.is_running():
		_shake_tween.kill()
	
	if current_state == DumpsterState.OCCUPIED_HIDING:
		exit_hiding()
	
	global_transform = _initial_transform
	current_state = DumpsterState.READY
	current_durability = MAX_DURABILITY
	reward_granted = 0
	is_rammed = false
	hiding_player = null
	
	if visual_root and visual_root != self:
		visual_root.position = Vector3.ZERO
		visual_root.rotation = Vector3.ZERO
