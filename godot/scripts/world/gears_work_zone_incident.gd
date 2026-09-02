class_name GearsWorkZoneIncident
extends Node3D

## Burnside Production 04 / #127
## One authored Gears work-zone ambient incident.
## Owns only its local actor pair and incident-local timing/one-shot state.
## Wanted knowledge remains owned by BurnsideWantedRuntime / WantedAuthority.

const WORKER_SCENE := preload("res://scenes/entities/scrap_worker.tscn")
const CRAWLER_SCENE := preload("res://scenes/entities/utility_crawler.tscn")

const MATERIAL_SPEED_MPS := 8.0
const MATERIAL_ACTOR_DISTANCE_M := 1.25
const RECOVERY_MIN_SEC := 4.0
const RECOVERY_CLEAR_RADIUS_M := 6.0
const CROSSING_HALF_WIDTH_M := 6.5
const CROSSING_MIN_Z_M := -3.0
const CROSSING_MAX_Z_M := 2.0

enum IncidentState {
	ROUTINE,
	ALARMED,
	RECOVERING,
}

var current_state: IncidentState = IncidentState.ROUTINE
var _root_controller: Node = null
var _district: Node3D = null
var _wanted_runtime: Node = null
var _audio_mgr: Node = null
var _anchor_resolved: bool = false
var _recovery_elapsed: float = 0.0
var _report_attempt_count: int = 0
var _configured: bool = false
var _actors_spawned: bool = false

var gears_worker: CharacterBody3D = null
var gears_crawler: CharacterBody3D = null

func configure(root_controller: Node, district: Node3D, wanted_runtime: Node, audio_mgr: Node) -> bool:
	if root_controller == null or district == null:
		return false
	var intersection := district.get_node_or_null("IndustrialIntersection") as Node3D
	if intersection == null:
		return false

	_root_controller = root_controller
	_district = district
	_wanted_runtime = wanted_runtime
	_audio_mgr = audio_mgr
	global_position = Vector3(intersection.global_position.x, 0.05, intersection.global_position.z)
	_anchor_resolved = true
	_configured = true
	_spawn_actors()
	_connect_replay_reset()
	return _actors_spawned

func _ready() -> void:
	if _configured:
		_spawn_actors()
		_connect_replay_reset()

func _process(delta: float) -> void:
	if not _configured or not _actors_spawned or _root_controller == null:
		return
	var active_vehicle = null
	if _root_controller.has_method("_get_active_vehicle"):
		active_vehicle = _root_controller.call("_get_active_vehicle")
	if active_vehicle is CharacterBody3D:
		process_player_sample(active_vehicle as CharacterBody3D, true, delta)
		return
	var player := _root_controller.get_node_or_null("Runner") as CharacterBody3D
	if player != null:
		process_player_sample(player, false, delta)

func _spawn_actors() -> void:
	if _actors_spawned or not _configured:
		return

	gears_worker = WORKER_SCENE.instantiate() as CharacterBody3D
	gears_crawler = CRAWLER_SCENE.instantiate() as CharacterBody3D
	if gears_worker == null or gears_crawler == null:
		return

	gears_worker.name = "GearsWorker"
	var worker_start := global_position + Vector3(-3.5, 0.0, -1.8)
	gears_worker.global_position = worker_start
	gears_worker.set("patrol_waypoints", [
		worker_start,
		global_position + Vector3(3.5, 0.0, -1.8),
	])
	gears_worker.set("safe_anchor", global_position + Vector3(-5.7, 0.0, 1.8))
	if gears_worker.has_method("setup_audio") and _audio_mgr != null:
		gears_worker.call("setup_audio", _audio_mgr)
	add_child(gears_worker)

	gears_crawler.name = "GearsCrawler"
	var crawler_start := global_position + Vector3(2.6, 0.0, 0.8)
	gears_crawler.global_position = crawler_start
	gears_crawler.set("patrol_waypoints", [
		crawler_start,
		global_position + Vector3(-1.6, 0.0, 0.8),
	])
	gears_crawler.set("safe_anchor", global_position + Vector3(5.6, 0.0, 1.8))
	if gears_crawler.has_method("setup_audio") and _audio_mgr != null:
		gears_crawler.call("setup_audio", _audio_mgr)
	add_child(gears_crawler)

	_actors_spawned = true

func _connect_replay_reset() -> void:
	if _root_controller == null:
		return
	var touch_ui := _root_controller.get_node_or_null("CanvasLayer/TouchControlsUI")
	if touch_ui == null or not touch_ui.has_signal("replay_pressed"):
		return
	var reset_callable := Callable(self, "reset_incident")
	if not touch_ui.is_connected("replay_pressed", reset_callable):
		touch_ui.connect("replay_pressed", reset_callable)

func process_player_sample(entity: CharacterBody3D, is_vehicle: bool, delta: float) -> void:
	if entity == null or not _actors_spawned:
		return

	for actor in [gears_worker, gears_crawler]:
		if actor != null and is_instance_valid(actor) and actor.has_method("check_proximity_threat"):
			actor.call("check_proximity_threat", entity.global_position, entity.velocity)

	if current_state == IncidentState.ROUTINE:
		if _is_material_disruption(entity, is_vehicle):
			_escalate(entity.global_position)
		return

	if current_state == IncidentState.ALARMED:
		_recovery_elapsed += maxf(delta, 0.0)
		if _recovery_elapsed >= RECOVERY_MIN_SEC and _horizontal_distance(entity.global_position, global_position) > RECOVERY_CLEAR_RADIUS_M:
			current_state = IncidentState.RECOVERING
			_reset_local_actors()
			current_state = IncidentState.ROUTINE
			_recovery_elapsed = 0.0

func _is_material_disruption(entity: CharacterBody3D, is_vehicle: bool) -> bool:
	if not is_vehicle or not _inside_crossing(entity.global_position):
		return false
	var planar_velocity := entity.velocity
	planar_velocity.y = 0.0
	if planar_velocity.length() < MATERIAL_SPEED_MPS:
		return false
	for actor in [gears_worker, gears_crawler]:
		if actor == null or not is_instance_valid(actor):
			continue
		if not _inside_crossing(actor.global_position):
			continue
		if _horizontal_distance(entity.global_position, actor.global_position) <= MATERIAL_ACTOR_DISTANCE_M:
			return true
	return false

func _inside_crossing(world_pos: Vector3) -> bool:
	var local := world_pos - global_position
	return absf(local.x) <= CROSSING_HALF_WIDTH_M and local.z >= CROSSING_MIN_Z_M and local.z <= CROSSING_MAX_Z_M

func _escalate(observed_position: Vector3) -> void:
	current_state = IncidentState.ALARMED
	_recovery_elapsed = 0.0
	for actor in [gears_worker, gears_crawler]:
		if actor != null and is_instance_valid(actor) and actor.has_method("trigger_alarm"):
			actor.call("trigger_alarm")

	if _wanted_runtime == null or not is_instance_valid(_wanted_runtime):
		return
	if int(_wanted_runtime.call("get_heat_level")) > 0:
		return
	_report_attempt_count += 1
	_wanted_runtime.call("request_civic_report", observed_position)

func reset_incident() -> void:
	current_state = IncidentState.ROUTINE
	_recovery_elapsed = 0.0
	_report_attempt_count = 0
	_reset_local_actors()

func _reset_local_actors() -> void:
	for actor in [gears_worker, gears_crawler]:
		if actor != null and is_instance_valid(actor) and actor.has_method("reset_actor"):
			actor.call("reset_actor")

func get_incident_state_name() -> String:
	return IncidentState.keys()[current_state]

func get_report_attempt_count() -> int:
	return _report_attempt_count

func get_incident_contract() -> Dictionary:
	return {
		"version": "burnside_production_04_work_zone_v1",
		"material_speed_mps": MATERIAL_SPEED_MPS,
		"material_actor_distance_m": MATERIAL_ACTOR_DISTANCE_M,
		"recovery_min_sec": RECOVERY_MIN_SEC,
		"recovery_clear_radius_m": RECOVERY_CLEAR_RADIUS_M,
		"anchored_to_gears_industrial_intersection": _anchor_resolved,
		"district_path": "GearsDistrictSlice01B/IndustrialIntersection",
		"owns_wanted_authority": false,
		"report_attempt_count": _report_attempt_count,
	}

func _horizontal_distance(a: Vector3, b: Vector3) -> float:
	var delta := a - b
	delta.y = 0.0
	return delta.length()
