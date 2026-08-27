extends Node

## Thin authored adapter for Mission/Narrative 03. Existing production systems
## retain authority over Action target arbitration, Memory Echo presentation,
## pursuit/interception, vehicles, camera, radio and Full Replay.

const MissionScript = preload("res://scripts/missions/city_that_forgot_mission.gd")
const CivicMissionScript = preload("res://scripts/missions/civic_repossession_mission.gd")
const ScrapTestBlockScript = preload("res://scripts/prototype/scrap_test_block.gd")
const SilentCoreScript = preload("res://scripts/interactions/silent_core_interactable.gd")
const MemoryEchoScript = preload("res://scripts/prototype/memory_echo_controller.gd")

const LEGACY_SILENT_CORE_POSITION := Vector3(8.0, 0.4, -8.0)
const DISTRICT_SILENT_CORE_SOCKET_PATH := "GearsDistrictSlice01B/SilentCoreSite/SilentCoreSocket"
const AUTHORED_ECHO_PAYLOAD := {
	"echo_id": "mission03_silent_core",
	"action": "silent_core_resonance",
	"zone": "silent_core_shrine",
	"intensity": 0.95,
	"mission_ref": "mission_03_city_that_forgot",
	"content": "[HS-7] ECHOTEL // archive fragment // civic deletion order recovered // integrity unstable",
}

var mission = MissionScript.new()
var _root_controller: Node = null
var _civic_runtime = null
var _touch_ui = null
var _silent_core = null
var _echo_controller = null
var _mission_title: Label = null
var _objective_label: Label = null
var _contact_label: Label = null
var _bound: bool = false
var _civic_complete_seen: bool = false
var _fresh_pursuit_started: bool = false

func _ready() -> void:
	_root_controller = get_parent()
	call_deferred("_try_bind_runtime")

func _process(_delta: float) -> void:
	if not _bound:
		_try_bind_runtime()
		return

	var civic_complete: bool = _civic_runtime != null \
	and _civic_runtime.mission.phase == CivicMissionScript.Phase.COMPLETE

	if mission.phase == MissionScript.Phase.LOCKED:
		if not civic_complete:
			_civic_complete_seen = false
			return
		# Preserve Civic Repossession's presentation payoff for one complete frame
		# before Sister Kael takes ownership of the same HUD.
		if not _civic_complete_seen:
			_civic_complete_seen = true
			return
		if mission.unlock_after_civic_repossession():
			_silent_core.set_mission_powered(true)
			_refresh_hud()
	elif not civic_complete:
		_reset_for_full_replay()
		return

	var root_pursuit_state := int(_root_controller.get("current_pursuit_state"))

	# Civic Repossession can legitimately leave the retained controller in its
	# terminal EVADED state while de-escalation finishes. Do not consume that old
	# terminal state as Mission 03 success. Mission 03 owns terminal pursuit
	# outcomes only after a fresh disturbance/pursuit has been observed.
	if mission.phase == MissionScript.Phase.ESCAPE and not _fresh_pursuit_started:
		if root_pursuit_state == int(ScrapTestBlockScript.PursuitState.CALM) \
		and _root_controller.has_method("trigger_disturbance_alert"):
			_root_controller.call("trigger_disturbance_alert")
			root_pursuit_state = int(_root_controller.get("current_pursuit_state"))
		if root_pursuit_state == int(ScrapTestBlockScript.PursuitState.DISTURBANCE_ALERT) \
		or root_pursuit_state == int(ScrapTestBlockScript.PursuitState.PURSUIT_ACTIVE):
			_fresh_pursuit_started = true
		else:
			return

	var changed := false
	if mission.phase == MissionScript.Phase.ESCAPE \
	and root_pursuit_state == int(ScrapTestBlockScript.PursuitState.INTERCEPTED):
		changed = mission.on_intercepted() or changed
	elif mission.phase == MissionScript.Phase.FAILED \
	and root_pursuit_state == int(ScrapTestBlockScript.PursuitState.PURSUIT_ACTIVE):
		changed = mission.on_retry_started() or changed
	elif mission.phase == MissionScript.Phase.ESCAPE \
	and root_pursuit_state == int(ScrapTestBlockScript.PursuitState.EVADED):
		changed = mission.on_escape_complete() or changed

	if changed:
		_refresh_hud()

func _try_bind_runtime() -> void:
	if _bound or _root_controller == null:
		return

	_civic_runtime = _root_controller.get_node_or_null("CivicRepossessionRuntime")
	_touch_ui = _root_controller.get_node_or_null("CanvasLayer/TouchControlsUI")
	var mission_hud := _root_controller.get_node_or_null("CanvasLayer/TouchControlsUI/SafeAreaRoot/MissionHUD")
	if _civic_runtime == null or _touch_ui == null or mission_hud == null:
		return

	_mission_title = mission_hud.find_child("MissionTitle", true, false) as Label
	_objective_label = mission_hud.find_child("ObjectiveLabel", true, false) as Label
	_contact_label = mission_hud.find_child("ContactLabel", true, false) as Label
	if _mission_title == null or _objective_label == null or _contact_label == null:
		return

	_create_silent_core()
	_register_retained_interaction_target()
	if not _silent_core.silent_core_activated.is_connected(_on_silent_core_activated):
		_silent_core.silent_core_activated.connect(_on_silent_core_activated)
	if not _touch_ui.action_button_pressed.is_connected(_on_action_pressed):
		_touch_ui.action_button_pressed.connect(_on_action_pressed)

	_bound = true
	print("[MISSION_NARRATIVE_03] Runtime bound to retained Action/Echo/pursuit systems")

func _resolve_silent_core_destination() -> Dictionary:
	if _root_controller != null:
		var socket := _root_controller.get_node_or_null(DISTRICT_SILENT_CORE_SOCKET_PATH) as Marker3D
		if socket != null:
			return {
				"global_position": socket.global_position,
				"source": DISTRICT_SILENT_CORE_SOCKET_PATH,
			}
	return {
		"global_position": LEGACY_SILENT_CORE_POSITION,
		"source": "legacy_fixture_fallback",
	}

func _create_silent_core() -> void:
	var existing := _root_controller.get_node_or_null("SilentCore")
	if existing != null and existing.get_script() == SilentCoreScript:
		_silent_core = existing
		return
	_silent_core = SilentCoreScript.new()
	_silent_core.name = "SilentCore"
	_root_controller.add_child(_silent_core)
	var destination := _resolve_silent_core_destination()
	_silent_core.global_position = destination["global_position"]
	_silent_core.set_meta("destination_source", destination["source"])

func _register_retained_interaction_target() -> void:
	var interactables = _root_controller.get("_interactables")
	if interactables is Array and not interactables.has(_silent_core):
		interactables.append(_silent_core)
		_root_controller.set("_interactables", interactables)

func _on_action_pressed() -> void:
	# The production controller still decides the active target. This adapter only
	# consumes the same Action signal when that retained decision points here.
	if not _bound or mission.phase != MissionScript.Phase.REACH_SILENT_CORE:
		return
	if _root_controller.get("_active_target") != _silent_core:
		return
	var player = _root_controller.get("player")
	if player == null:
		return
	_silent_core.begin_interaction(player.global_position)

func _on_silent_core_activated() -> void:
	if not mission.on_silent_core_activated():
		return
	_refresh_hud()
	_echo_controller = _ensure_echo_controller()
	if _echo_controller == null:
		return
	# A real Mission 01 extraction Echo can leave the retained controller at DONE.
	# Prepare that completed lifecycle for a later authored beat without invoking
	# the authoritative replay reset or erasing cumulative trigger accounting.
	if _echo_controller.current_phase == MemoryEchoScript.EchoPhase.DONE:
		if not _echo_controller.prepare_next_echo():
			push_error("[MISSION_NARRATIVE_03] Retained Memory Echo could not prepare the next authored beat")
			return
	elif _echo_controller.current_phase != MemoryEchoScript.EchoPhase.IDLE:
		push_error("[MISSION_NARRATIVE_03] Retained Memory Echo is still active")
		return
	if not _echo_controller.echo_completed.is_connected(_on_echo_completed):
		_echo_controller.echo_completed.connect(_on_echo_completed)
	if not _echo_controller.trigger_authored_echo(AUTHORED_ECHO_PAYLOAD):
		push_error("[MISSION_NARRATIVE_03] Retained Memory Echo rejected authored payload")

func _ensure_echo_controller():
	var existing = _root_controller.get("echo_controller")
	if existing != null:
		return existing
	var controller = MemoryEchoScript.new()
	controller.name = "MemoryEchoController"
	_root_controller.add_child(controller)
	controller.call("setup", _root_controller.get("audio_mgr"))
	_root_controller.set("echo_controller", controller)
	return controller

func _on_echo_completed() -> void:
	if not mission.on_echo_completed():
		return
	_fresh_pursuit_started = false
	_refresh_hud()
	# If the retained root was already connected from Mission 01 it may have
	# started the fresh disturbance first. Otherwise _process waits for any prior
	# mission de-escalation to reach CALM, then asks the canonical authority.
	var root_pursuit_state := int(_root_controller.get("current_pursuit_state"))
	if root_pursuit_state == int(ScrapTestBlockScript.PursuitState.DISTURBANCE_ALERT) \
	or root_pursuit_state == int(ScrapTestBlockScript.PursuitState.PURSUIT_ACTIVE):
		_fresh_pursuit_started = true
	elif root_pursuit_state == int(ScrapTestBlockScript.PursuitState.CALM) \
	and _root_controller.has_method("trigger_disturbance_alert"):
		_root_controller.call("trigger_disturbance_alert")
		root_pursuit_state = int(_root_controller.get("current_pursuit_state"))
		_fresh_pursuit_started = root_pursuit_state == int(ScrapTestBlockScript.PursuitState.DISTURBANCE_ALERT) \
		or root_pursuit_state == int(ScrapTestBlockScript.PursuitState.PURSUIT_ACTIVE)

func _refresh_hud() -> void:
	if _mission_title == null or _objective_label == null or _contact_label == null:
		return
	_mission_title.text = "THE CITY THAT FORGOT // SISTER KAEL"
	_objective_label.text = mission.objective
	_contact_label.text = mission.contact_line

func _reset_for_full_replay() -> void:
	mission = MissionScript.new()
	_civic_complete_seen = false
	_fresh_pursuit_started = false
	if _silent_core != null:
		_silent_core.reset_for_replay()
	print("[MISSION_NARRATIVE_03] Full replay detected; The City That Forgot relocked")
