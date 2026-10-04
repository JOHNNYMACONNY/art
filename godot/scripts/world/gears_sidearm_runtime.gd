class_name GearsSidearmRuntime
extends Node3D

## Burnside Production 17 / #179
## One bounded current-run retrofit sidearm. This is deliberately not a weapon
## inventory/framework: one pickup, one held state, one hitscan, one local
## consequence seam.

const SidearmPickupScene = preload("res://scenes/interactions/sidearm_pickup.tscn")

const SIDEARM_RANGE_M := 22.0
const FIRE_COOLDOWN_SEC := 0.32
const SHOT_ORIGIN_HEIGHT_M := 0.42
const TRACE_LIFETIME_SEC := 0.12
const IMPACT_LIFETIME_SEC := 0.22

var _root_controller: Node = null
var _district: Node3D = null
var _touch_ui: Node = null
var _player: Node3D = null
var _audio_mgr: Node = null
var _pickup: SidearmPickup = null
var _held_visual: Node3D = null
var _muzzle_flash: MeshInstance3D = null
var _shot_transient_ids: Array[int] = []

var _held: bool = false
var _configured: bool = false
var _cooldown_remaining: float = 0.0
var _shot_count: int = 0
var _ballistic_query_count: int = 0
var _last_impact_name: String = "NONE"
var _last_ui_available: bool = false

func _process(delta: float) -> void:
	if _configured:
		process_weapon_state(delta)

func configure(root_controller: Node, district: Node3D) -> bool:
	if root_controller == null or district == null:
		return false

	var touch_ui := root_controller.get_node_or_null("CanvasLayer/TouchControlsUI")
	var player := root_controller.get_node_or_null("Runner") as Node3D
	if touch_ui == null or player == null:
		return false
	if not touch_ui.has_signal("action_button_pressed") 	or not touch_ui.has_signal("weapon_action_pressed") 	or not touch_ui.has_signal("replay_pressed") 	or not touch_ui.has_method("set_weapon_action_available") 	or not player.has_method("get_facing_direction"):
		return false

	var stash := district.get_node_or_null("StreetClutter/CardboardBoxStack") as Node3D
	var fallback_socket := district.get_node_or_null("ServiceAlleyEntrySocket") as Node3D
	if stash == null and fallback_socket == null:
		return false

	_root_controller = root_controller
	_district = district
	_touch_ui = touch_ui
	_player = player
	_audio_mgr = root_controller.get_node_or_null("AudioManager")

	_pickup = SidearmPickupScene.instantiate() as SidearmPickup
	if _pickup == null:
		return false
	_pickup.name = "SidearmPickup"
	_root_controller.add_child(_pickup)
	if stash != null:
		_pickup.global_position = stash.global_position + Vector3(1.05, 0.58, 0.45)
	else:
		_pickup.global_position = fallback_socket.global_position + Vector3(0.9, 0.48, -3.0)

	var interactables = _root_controller.get("_interactables")
	if interactables is Array and not interactables.has(_pickup):
		interactables.append(_pickup)

	_ensure_held_visual()
	_touch_ui.call("set_weapon_action_available", false)

	var action_callable := Callable(self, "_on_action_pressed")
	if not _touch_ui.is_connected("action_button_pressed", action_callable):
		_touch_ui.connect("action_button_pressed", action_callable)
	var fire_callable := Callable(self, "handle_weapon_action_pressed")
	if not _touch_ui.is_connected("weapon_action_pressed", fire_callable):
		_touch_ui.connect("weapon_action_pressed", fire_callable)
	var replay_callable := Callable(self, "reset_runtime")
	if not _touch_ui.is_connected("replay_pressed", replay_callable):
		_touch_ui.connect("replay_pressed", replay_callable)

	_configured = true
	_sync_weapon_availability(true)
	return true

func _body_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.13, 0.14, 0.14, 1.0)
	material.metallic = 0.72
	material.roughness = 0.5
	return material

func _grip_material() -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = Color(0.86, 0.82, 0.72, 1.0)
	material.metallic = 0.18
	material.roughness = 0.78
	return material

func _emissive_material(color: Color, energy: float = 1.6) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	material.emission_energy_multiplier = energy
	material.metallic = 0.35
	material.roughness = 0.38
	return material

func _add_box(parent: Node3D, name_value: String, size: Vector3, position_value: Vector3, material: Material) -> MeshInstance3D:
	var mesh := BoxMesh.new()
	mesh.size = size
	var node := MeshInstance3D.new()
	node.name = name_value
	node.mesh = mesh
	node.position = position_value
	node.material_override = material
	parent.add_child(node)
	return node

func _ensure_held_visual() -> void:
	if _held_visual != null or _player == null:
		return
	var holder := _player.get_node_or_null("MeshPivot") as Node3D
	if holder == null:
		holder = _player

	_held_visual = Node3D.new()
	_held_visual.name = "HeldRetrofitSidearm"
	_held_visual.position = Vector3(0.38, 1.17, -0.31)
	_held_visual.rotation = Vector3(deg_to_rad(-6.0), deg_to_rad(-8.0), deg_to_rad(-10.0))
	_held_visual.scale = Vector3(1.28, 1.28, 1.28)
	_held_visual.visible = false
	holder.add_child(_held_visual)

	var body_mat := _body_material()
	var grip_mat := _grip_material()
	var retrofit_mat := _emissive_material(Color(0.05, 0.72, 0.78, 1.0), 1.25)
	var hazard_mat := _emissive_material(Color(1.0, 0.42, 0.06, 1.0), 1.65)
	_add_box(_held_visual, "Receiver", Vector3(0.32, 0.18, 0.54), Vector3.ZERO, body_mat)
	_add_box(_held_visual, "BarrelShroud", Vector3(0.15, 0.13, 0.44), Vector3(0.02, 0.0, -0.46), body_mat)
	_add_box(_held_visual, "TopPlate", Vector3(0.25, 0.055, 0.40), Vector3(0.0, 0.115, -0.04), grip_mat)
	var grip := _add_box(_held_visual, "Grip", Vector3(0.16, 0.38, 0.20), Vector3(-0.02, -0.24, 0.10), grip_mat)
	grip.rotation = Vector3(-0.16, 0.0, 0.08)
	_add_box(_held_visual, "RetrofitCell", Vector3(0.08, 0.10, 0.25), Vector3(0.19, 0.0, 0.03), retrofit_mat)
	_add_box(_held_visual, "HazardBrace", Vector3(0.055, 0.11, 0.27), Vector3(-0.18, 0.0, -0.02), hazard_mat)

	var muzzle_mesh := SphereMesh.new()
	muzzle_mesh.radius = 0.11
	muzzle_mesh.height = 0.22
	_muzzle_flash = MeshInstance3D.new()
	_muzzle_flash.name = "MuzzleFlash"
	_muzzle_flash.position = Vector3(0.02, 0.0, -0.71)
	_muzzle_flash.mesh = muzzle_mesh
	_muzzle_flash.material_override = _emissive_material(Color(1.0, 0.58, 0.12, 1.0), 4.0)
	_muzzle_flash.visible = false
	_held_visual.add_child(_muzzle_flash)

func _on_action_pressed() -> void:
	acquire_active_pickup()

func handle_action_pressed() -> bool:
	return acquire_active_pickup()

func acquire_active_pickup() -> bool:
	if not _configured or _held or _pickup == null or not is_instance_valid(_pickup) or _player == null:
		return false
	if bool(_player.get("is_mounted")):
		return false
	if _root_controller.get("_active_target") != _pickup:
		return false
	_pickup.update_player_distance(_player.global_position)
	if not _pickup.can_interact(_player.global_position):
		return false
	if not _pickup.acquire():
		return false

	_held = true
	if _held_visual != null:
		_held_visual.visible = true
	_sync_weapon_availability(true)
	return true

func _can_fire() -> bool:
	if not _configured or not _held or _touch_ui == null or _player == null:
		return false
	if _cooldown_remaining > 0.0:
		return false
	if bool(_player.get("is_mounted")) or bool(_player.get("is_input_locked")):
		return false
	if int(_touch_ui.get("current_mode")) != int(TouchControlsUI.UIMode.FOOT_TRAVERSAL):
		return false
	if _touch_ui.has_method("is_interaction_input_locked") and bool(_touch_ui.call("is_interaction_input_locked")):
		return false
	return true

func handle_weapon_action_pressed() -> bool:
	if not _can_fire():
		return false

	var facing: Vector3 = _player.call("get_facing_direction")
	facing.y = 0.0
	if facing.length_squared() <= 0.001:
		return false
	facing = facing.normalized()

	var origin := _player.global_position + Vector3.UP * SHOT_ORIGIN_HEIGHT_M + facing * 0.28
	var endpoint := origin + facing * SIDEARM_RANGE_M

	_cooldown_remaining = FIRE_COOLDOWN_SEC
	_sync_weapon_availability(true)
	_shot_count += 1
	_flash_muzzle()
	if _audio_mgr != null and is_instance_valid(_audio_mgr):
		_audio_mgr.call("play_event", AudioManager.SoundEvent.SIDEARM_FIRE, origin)
	_resolve_ballistic_once(origin, endpoint, facing)
	_trigger_local_gunfire(origin)
	return true

func process_weapon_state(delta: float) -> void:
	_cooldown_remaining = maxf(0.0, _cooldown_remaining - maxf(delta, 0.0))
	_sync_weapon_availability()

func _weapon_ui_should_be_available() -> bool:
	if not _held or _player == null or _cooldown_remaining > 0.0:
		return false
	return not bool(_player.get("is_mounted")) and not bool(_player.get("is_input_locked"))

func _sync_weapon_availability(force: bool = false) -> void:
	if _touch_ui == null or not is_instance_valid(_touch_ui):
		return
	var available := _weapon_ui_should_be_available()
	if force or available != _last_ui_available:
		_last_ui_available = available
		_touch_ui.call("set_weapon_action_available", available)

func _resolve_ballistic_once(origin: Vector3, endpoint: Vector3, facing: Vector3) -> void:
	_ballistic_query_count += 1
	var query := PhysicsRayQueryParameters3D.create(origin, endpoint)
	query.collide_with_areas = false
	if _player is CollisionObject3D:
		query.exclude = [(_player as CollisionObject3D).get_rid()]

	var result := get_world_3d().direct_space_state.intersect_ray(query)
	var impact_pos := endpoint
	_last_impact_name = "MISS"
	var damaged := false
	var disabled_target := false

	if not result.is_empty():
		impact_pos = result.get("position", endpoint)
		var collider = result.get("collider")
		if collider is Node:
			_last_impact_name = String((collider as Node).name)
			var damage_target := _find_ballistic_damage_target(collider as Node)
			if damage_target != null:
				_last_impact_name = String(damage_target.name)
				damage_target.call("take_hit", 1, impact_pos, facing)
				damaged = true
				disabled_target = int(damage_target.get("current_durability")) <= 0

	_spawn_trace(origin, impact_pos)
	if not result.is_empty():
		_spawn_impact(impact_pos, damaged, disabled_target)

func _find_ballistic_damage_target(start: Node) -> Node:
	var node := start
	while node != null:
		# P17 intentionally proves firearm damage against the retained industrial
		# crawler only. This prevents leakage into the armored interceptor or
		# unrelated damageable props while the weapon model is still a tracer.
		if node.is_in_group("utility_crawlers") and node.has_method("take_hit"):
			return node
		node = node.get_parent()
	return null

func _trigger_local_gunfire(observed_position: Vector3) -> void:
	if _root_controller == null:
		return
	var incident := _root_controller.get_node_or_null("GearsWorkZoneIncident")
	if incident != null and incident.has_method("trigger_gunfire_incident"):
		incident.call("trigger_gunfire_incident", observed_position)

func _flash_muzzle() -> void:
	if _muzzle_flash == null or not is_instance_valid(_muzzle_flash):
		return
	_muzzle_flash.visible = true
	get_tree().create_timer(0.085).timeout.connect(Callable(self, "_hide_muzzle_flash"))

func _hide_muzzle_flash() -> void:
	if _muzzle_flash != null and is_instance_valid(_muzzle_flash):
		_muzzle_flash.visible = false

func _spawn_trace(origin: Vector3, endpoint: Vector3) -> void:
	if _root_controller == null:
		return
	var distance := origin.distance_to(endpoint)
	if distance <= 0.01:
		return
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.055, 0.055, distance)
	var tracer := MeshInstance3D.new()
	tracer.name = "SidearmTrace"
	tracer.mesh = mesh
	tracer.material_override = _emissive_material(Color(1.0, 0.56, 0.12, 1.0), 3.0)
	_root_controller.add_child(tracer)
	tracer.global_position = (origin + endpoint) * 0.5
	tracer.look_at(endpoint, Vector3.UP)
	var tracer_id := tracer.get_instance_id()
	_shot_transient_ids.append(tracer_id)
	get_tree().create_timer(TRACE_LIFETIME_SEC).timeout.connect(
		Callable(self, "_free_transient_instance").bind(tracer_id)
	)

func _spawn_impact(position_value: Vector3, damaged: bool, disabled_target: bool = false) -> void:
	if _root_controller == null:
		return
	var mesh := SphereMesh.new()
	mesh.radius = 0.20 if disabled_target else 0.13
	mesh.height = 0.40 if disabled_target else 0.26
	var marker := MeshInstance3D.new()
	marker.name = "SidearmImpact"
	marker.mesh = mesh
	var color := Color(0.10, 0.95, 1.0, 1.0) if disabled_target else (Color(0.12, 0.86, 0.92, 1.0) if damaged else Color(1.0, 0.52, 0.12, 1.0))
	marker.material_override = _emissive_material(color, 5.0 if disabled_target else 3.2)
	_root_controller.add_child(marker)
	marker.global_position = position_value
	var marker_id := marker.get_instance_id()
	_shot_transient_ids.append(marker_id)
	get_tree().create_timer(IMPACT_LIFETIME_SEC).timeout.connect(
		Callable(self, "_free_transient_instance").bind(marker_id)
	)

func _free_transient_instance(instance_id: int) -> void:
	_shot_transient_ids.erase(instance_id)
	var transient := instance_from_id(instance_id)
	if is_instance_valid(transient):
		transient.queue_free()

func _clear_shot_transients() -> void:
	for instance_id in _shot_transient_ids:
		var transient := instance_from_id(instance_id)
		if is_instance_valid(transient):
			if transient is Node3D:
				(transient as Node3D).visible = false
			transient.queue_free()
	_shot_transient_ids.clear()

func has_sidearm() -> bool:
	return _held

func get_pickup() -> SidearmPickup:
	return _pickup

func get_shot_count() -> int:
	return _shot_count

func get_ballistic_query_count() -> int:
	return _ballistic_query_count

func get_last_impact_name() -> String:
	return _last_impact_name

func get_fire_cooldown_remaining() -> float:
	return _cooldown_remaining

func reset_runtime() -> void:
	_held = false
	_cooldown_remaining = 0.0
	_shot_count = 0
	_ballistic_query_count = 0
	_last_impact_name = "NONE"
	if _pickup != null and is_instance_valid(_pickup):
		_pickup.reset_pickup()
	if _held_visual != null and is_instance_valid(_held_visual):
		_held_visual.visible = false
	if _muzzle_flash != null and is_instance_valid(_muzzle_flash):
		_muzzle_flash.visible = false
	_clear_shot_transients()
	_sync_weapon_availability(true)
