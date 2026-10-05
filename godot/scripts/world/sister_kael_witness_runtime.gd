class_name SisterKaelWitnessRuntime
extends Node3D

## Burnside Production 20 / #188
## Passive physical Sister Kael witness at the retained Silent Core.
## P16 remains the only RELEASE / SEAL writer. This runtime owns no Action,
## mission, Wanted, Field-Hacking, save, combat, or Audio authority.

const CityMissionScript = preload("res://scripts/missions/city_that_forgot_mission.gd")
const SisterKaelScene = preload("res://scenes/entities/sister_kael.tscn")

const SILENT_CORE_SOCKET_PATH := "SilentCoreSite/SilentCoreSocket"
const ACTOR_OFFSET := Vector3(0.0, -0.15, -1.60)
const REACTION_HOLD_MSEC := 3200

var _root_controller: Node = null
var _district: Node3D = null
var _city_runtime: Node = null
var _socket: Marker3D = null
var _actor: Node3D = null

var _moment_panel: PanelContainer = null
var _speaker_label: Label = null
var _line_label: Label = null

var _bound: bool = false
var _last_aftermath_state: String = ""
var _reaction_mode: String = ""
var _reaction_line: String = ""
var _reaction_count: int = 0
var _reaction_deadline_msec: int = 0

func configure(root_controller: Node, district: Node3D, city_runtime: Node) -> bool:
	if root_controller == null or district == null or city_runtime == null:
		return false
	if not city_runtime.has_method("get_aftermath_snapshot"):
		return false
	var mission = city_runtime.get("mission")
	if mission == null or not mission.has_method("get_aftermath_state_name"):
		return false

	var socket := district.get_node_or_null(SILENT_CORE_SOCKET_PATH) as Marker3D
	var safe_root := root_controller.get_node_or_null("CanvasLayer/TouchControlsUI/SafeAreaRoot") as Control
	if socket == null or safe_root == null:
		return false

	_root_controller = root_controller
	_district = district
	_city_runtime = city_runtime
	_socket = socket

	_actor = SisterKaelScene.instantiate() as Node3D
	if _actor == null:
		return false
	_actor.name = "SisterKael"
	add_child(_actor)
	_actor.global_position = _socket.global_position + ACTOR_OFFSET
	_actor.rotation.y = PI
	_actor.visible = false

	_create_reaction_ui(safe_root)
	_set_pose("UNDECIDED")

	_bound = true
	set_process(true)
	process_witness_state()
	return true

func _create_reaction_ui(safe_root: Control) -> void:
	_moment_panel = PanelContainer.new()
	_moment_panel.name = "SisterKaelWitnessMoment"
	_moment_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_moment_panel.z_index = 42
	_moment_panel.anchor_left = 0.08
	_moment_panel.anchor_top = 0.0
	_moment_panel.anchor_right = 0.92
	_moment_panel.anchor_bottom = 0.0
	_moment_panel.offset_top = 72.0
	_moment_panel.offset_bottom = 180.0
	_moment_panel.visible = false

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.018, 0.026, 0.035, 0.93)
	style.border_width_left = 2
	style.border_width_top = 2
	style.border_width_right = 2
	style.border_width_bottom = 2
	style.border_color = Color(0.12, 0.70, 0.76, 0.78)
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 14
	style.content_margin_top = 10
	style.content_margin_right = 14
	style.content_margin_bottom = 10
	_moment_panel.add_theme_stylebox_override("panel", style)
	safe_root.add_child(_moment_panel)

	var stack := VBoxContainer.new()
	stack.name = "MomentStack"
	stack.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stack.add_theme_constant_override("separation", 4)
	_moment_panel.add_child(stack)

	_speaker_label = Label.new()
	_speaker_label.name = "Speaker"
	_speaker_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_speaker_label.text = "SISTER KAEL"
	_speaker_label.add_theme_font_size_override("font_size", 12)
	_speaker_label.add_theme_color_override("font_color", Color(0.30, 0.86, 0.90, 1.0))
	stack.add_child(_speaker_label)

	_line_label = Label.new()
	_line_label.name = "Line"
	_line_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_line_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_line_label.add_theme_font_size_override("font_size", 16)
	_line_label.add_theme_constant_override("outline_size", 4)
	_line_label.add_theme_color_override("font_outline_color", Color(0.01, 0.02, 0.025, 0.96))
	_line_label.custom_minimum_size = Vector2(0.0, 54.0)
	stack.add_child(_line_label)

func _process(_delta: float) -> void:
	if not _bound:
		return
	process_witness_state()
	if is_reaction_visible() and _reaction_deadline_msec > 0 and Time.get_ticks_msec() >= _reaction_deadline_msec:
		_moment_panel.visible = false
		_reaction_deadline_msec = 0

func process_witness_state() -> void:
	if not _bound or _city_runtime == null or _actor == null:
		return
	var mission = _city_runtime.get("mission")
	if mission == null:
		_reset_transient()
		return

	var phase: int = int(mission.get("phase"))
	if phase != int(CityMissionScript.Phase.COMPLETE):
		if _actor.visible or _reaction_count != 0 or not _reaction_mode.is_empty() or is_reaction_visible():
			_reset_transient()
		return

	_actor.visible = true
	var state: String = String(mission.call("get_aftermath_state_name"))
	if state == "UNDECIDED":
		if _last_aftermath_state != "UNDECIDED":
			_last_aftermath_state = "UNDECIDED"
			_reaction_mode = ""
			_reaction_line = ""
			_reaction_deadline_msec = 0
			if _moment_panel != null:
				_moment_panel.visible = false
			if _line_label != null:
				_line_label.text = ""
			_set_pose("UNDECIDED")
		return

	if state != "RELEASED" and state != "SEALED":
		return
	if state == _last_aftermath_state:
		return

	_last_aftermath_state = state
	_trigger_reaction(state, String(mission.get("contact_line")))

func _trigger_reaction(state: String, line: String) -> void:
	_reaction_mode = state
	_reaction_line = line
	_reaction_count += 1
	_set_pose(state)
	if _speaker_label != null:
		_speaker_label.text = "SISTER KAEL"
	if _line_label != null:
		_line_label.text = line
	if _moment_panel != null:
		_moment_panel.visible = true
	_reaction_deadline_msec = Time.get_ticks_msec() + REACTION_HOLD_MSEC

func _set_pose(mode: String) -> void:
	if _actor == null:
		return
	var head := _actor.get_node_or_null("BodyRoot/Head") as Node3D
	var left_arm := _actor.get_node_or_null("BodyRoot/LeftArm") as Node3D
	var right_arm := _actor.get_node_or_null("BodyRoot/RightArm") as Node3D
	if head != null:
		head.rotation = Vector3.ZERO
	if left_arm != null:
		left_arm.rotation = Vector3(0.02, 0.0, -0.08)
	if right_arm != null:
		right_arm.rotation = Vector3(-0.02, 0.0, 0.08)

	match mode:
		"RELEASED":
			if head != null:
				head.rotation = Vector3(-0.10, 0.0, -0.05)
			if left_arm != null:
				left_arm.rotation = Vector3(0.02, 0.0, -0.14)
			if right_arm != null:
				right_arm.rotation = Vector3(-0.02, 0.0, 0.32)
		"SEALED":
			if head != null:
				head.rotation = Vector3(0.12, 0.0, 0.07)
			if left_arm != null:
				left_arm.rotation = Vector3(0.02, 0.0, -0.02)
			if right_arm != null:
				right_arm.rotation = Vector3(-0.02, 0.0, 0.02)

func _reset_transient() -> void:
	_last_aftermath_state = ""
	_reaction_mode = ""
	_reaction_line = ""
	_reaction_count = 0
	_reaction_deadline_msec = 0
	if _actor != null:
		_actor.visible = false
	_set_pose("UNDECIDED")
	if _moment_panel != null:
		_moment_panel.visible = false
	if _line_label != null:
		_line_label.text = ""

func get_actor() -> Node3D:
	return _actor

func get_reaction_mode() -> String:
	return _reaction_mode

func get_reaction_line() -> String:
	return _reaction_line

func get_reaction_count() -> int:
	return _reaction_count

func is_reaction_visible() -> bool:
	return _moment_panel != null and _moment_panel.visible

func get_pose_snapshot() -> Dictionary:
	var head: Node3D = null
	var left_arm: Node3D = null
	var right_arm: Node3D = null
	if _actor != null:
		head = _actor.get_node_or_null("BodyRoot/Head") as Node3D
		left_arm = _actor.get_node_or_null("BodyRoot/LeftArm") as Node3D
		right_arm = _actor.get_node_or_null("BodyRoot/RightArm") as Node3D
	return {
		"mode": _reaction_mode if not _reaction_mode.is_empty() else "UNDECIDED",
		"head_x": head.rotation.x if head != null else 0.0,
		"head_z": head.rotation.z if head != null else 0.0,
		"left_arm_z": left_arm.rotation.z if left_arm != null else 0.0,
		"right_arm_z": right_arm.rotation.z if right_arm != null else 0.0,
	}
