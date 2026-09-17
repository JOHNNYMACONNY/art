class_name GearsLocalRouteSheet
extends Control

const STATUS_UNKNOWN := "UNKNOWN ROUTE"
const STATUS_JAMMED := "KNOWN · ACCESS JAMMED"
const STATUS_OPEN := "KNOWN · ACCESS OPEN"
const CONTEXT_SURFACES := ["NorthRoad", "IndustrialIntersection"]
const SURVEYED_SURFACES := ["ServiceAlley", "NorthConnector"]
const DRAW_PADDING := 30.0

var _district: Node3D = null
var _surface_bounds: Dictionary = {}
var _surveyed := false
var _access_state := "JAMMED"
var _world_bounds := Rect2()
var _configured := false

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	resized.connect(queue_redraw)

func configure(district: Node3D) -> bool:
	if district == null:
		return false
	_district = district
	_surface_bounds.clear()
	for body_name in CONTEXT_SURFACES + SURVEYED_SURFACES:
		var bounds := _read_box_surface_bounds(String(body_name))
		if not bounds.has_area():
			return false
		_surface_bounds[String(body_name)] = bounds
	_world_bounds = _combined_world_bounds()
	_configured = _world_bounds.has_area()
	queue_redraw()
	return _configured

func _read_box_surface_bounds(body_name: String) -> Rect2:
	if _district == null:
		return Rect2()
	var body := _district.get_node_or_null(body_name) as Node3D
	var collider := _district.get_node_or_null("%s/CollisionShape3D" % body_name) as CollisionShape3D
	if body == null or collider == null:
		return Rect2()
	var shape := collider.shape as BoxShape3D
	if shape == null:
		return Rect2()
	var half := shape.size * 0.5
	return Rect2(
		Vector2(body.global_position.x - half.x, body.global_position.z - half.z),
		Vector2(shape.size.x, shape.size.z)
	)

func _combined_world_bounds() -> Rect2:
	var combined := Rect2()
	var first := true
	for value in _surface_bounds.values():
		if not (value is Rect2):
			continue
		var rect := value as Rect2
		if first:
			combined = rect
			first = false
		else:
			combined = combined.merge(rect)
	return combined

func set_route_state(surveyed: bool, access_state: String) -> void:
	_surveyed = surveyed
	_access_state = access_state
	queue_redraw()

func is_service_cut_visible() -> bool:
	return _surveyed

func get_access_status_text() -> String:
	if not _surveyed:
		return STATUS_UNKNOWN
	return STATUS_OPEN if _access_state == "FORCED_OPEN" else STATUS_JAMMED

func get_surface_world_bounds(surface_name: String) -> Rect2:
	var value = _surface_bounds.get(surface_name, Rect2())
	return value as Rect2 if value is Rect2 else Rect2()

func _map_rect() -> Rect2:
	return Rect2(
		Vector2(DRAW_PADDING, DRAW_PADDING + 24.0),
		Vector2(maxf(size.x - DRAW_PADDING * 2.0, 1.0), maxf(size.y - DRAW_PADDING * 2.0 - 54.0, 1.0))
	)

func _project_world_rect(world_rect: Rect2) -> Rect2:
	if not _world_bounds.has_area():
		return Rect2()
	var target := _map_rect()
	var scale_x := target.size.x / _world_bounds.size.x
	var scale_y := target.size.y / _world_bounds.size.y
	var scale := minf(scale_x, scale_y)
	var drawn_size := _world_bounds.size * scale
	var origin := target.position + (target.size - drawn_size) * 0.5
	var local_position := origin + (world_rect.position - _world_bounds.position) * scale
	return Rect2(local_position, world_rect.size * scale)

func _draw_surface(surface_name: String, fill: Color, outline: Color, width: float = 2.0) -> void:
	var world_rect := get_surface_world_bounds(surface_name)
	if not world_rect.has_area():
		return
	var projected := _project_world_rect(world_rect)
	draw_rect(projected, fill, true)
	draw_rect(projected, outline, false, width)

func _draw() -> void:
	if not _configured:
		return
	var panel_rect := Rect2(Vector2.ZERO, size)
	draw_rect(panel_rect, Color(0.035, 0.045, 0.05, 0.96), true)
	draw_rect(panel_rect.grow(-1.0), Color(0.18, 0.36, 0.40, 0.95), false, 2.0)

	var context_fill := Color(0.18, 0.23, 0.25, 0.65)
	var context_outline := Color(0.48, 0.58, 0.60, 0.85)
	for surface_name in CONTEXT_SURFACES:
		_draw_surface(String(surface_name), context_fill, context_outline, 2.0)

	if _surveyed:
		var route_fill := Color(0.08, 0.36, 0.39, 0.82)
		var route_outline := Color(0.20, 0.88, 0.92, 0.98)
		for surface_name in SURVEYED_SURFACES:
			_draw_surface(String(surface_name), route_fill, route_outline, 3.0)

	var font := ThemeDB.fallback_font
	draw_string(font, Vector2(DRAW_PADDING, 30.0), "GEARS · LOCAL ROUTE SHEET", HORIZONTAL_ALIGNMENT_LEFT, -1.0, 16, Color(0.78, 0.92, 0.94, 1.0))
	var status_color := Color(0.96, 0.76, 0.30, 1.0) if get_access_status_text() == STATUS_JAMMED else Color(0.62, 0.90, 0.82, 1.0)
	if not _surveyed:
		status_color = Color(0.62, 0.68, 0.70, 1.0)
	draw_string(font, Vector2(DRAW_PADDING, size.y - 18.0), get_access_status_text(), HORIZONTAL_ALIGNMENT_LEFT, -1.0, 15, status_color)
