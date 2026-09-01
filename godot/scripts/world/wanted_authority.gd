class_name WantedAuthority
extends RefCounted

## Burnside Production 01 / #119
## Thin authority for Heat + Contact/Search knowledge state.
## Response assets consume this state; they do not own it.

enum WantedState {
	CLEAR,
	CONTACT,
	SEARCH,
}

const HEAT_CLEAR := 0
const HEAT_ATTENTION := 1

var search_evasion_seconds: float = 6.0

var _heat_level: int = HEAT_CLEAR
var _state: WantedState = WantedState.CLEAR
var _last_known_position: Vector3 = Vector3.ZERO
var _last_known_direction: Vector3 = Vector3.ZERO
var _last_reason: String = ""
var _search_elapsed: float = 0.0

func get_heat_level() -> int:
	return _heat_level

func get_wanted_state_name() -> String:
	return WantedState.keys()[_state]

func get_last_reason() -> String:
	return _last_reason

func get_last_known_position() -> Vector3:
	return _last_known_position

func get_last_known_direction() -> Vector3:
	return _last_known_direction

## Contact is allowed to use current legitimately observed position.
## Search may only use the snapshot captured when Contact was lost.
func get_tracking_position(live_observed_position: Vector3) -> Vector3:
	if _state == WantedState.CONTACT:
		return live_observed_position
	return _last_known_position

func submit_report(
	report_source: String,
	observed_position: Vector3,
	travel_direction: Vector3,
	contact_source: String
) -> bool:
	if report_source.strip_edges().is_empty() or contact_source.strip_edges().is_empty():
		return false

	_heat_level = HEAT_ATTENTION
	_state = WantedState.CONTACT
	_last_known_position = observed_position
	_last_known_direction = _normalized_or_zero(travel_direction)
	_last_reason = "report:%s" % report_source
	_search_elapsed = 0.0
	return true

func lose_contact(
	last_observed_position: Vector3,
	last_observed_direction: Vector3,
	reason: String
) -> bool:
	if _state != WantedState.CONTACT or _heat_level <= HEAT_CLEAR:
		return false
	if reason.strip_edges().is_empty():
		return false

	_state = WantedState.SEARCH
	_last_known_position = last_observed_position
	_last_known_direction = _normalized_or_zero(last_observed_direction)
	_last_reason = "contact_lost:%s" % reason
	_search_elapsed = 0.0
	return true

func reacquire(
	source: String,
	observed_position: Vector3,
	travel_direction: Vector3
) -> bool:
	if _state != WantedState.SEARCH or _heat_level <= HEAT_CLEAR:
		return false
	if source.strip_edges().is_empty():
		return false

	_state = WantedState.CONTACT
	_last_known_position = observed_position
	_last_known_direction = _normalized_or_zero(travel_direction)
	_last_reason = "reacquire:%s" % source
	_search_elapsed = 0.0
	return true

## Returns true only on the frame this Search becomes Evasion/CLEAR.
func advance_search(delta: float) -> bool:
	if _state != WantedState.SEARCH or _heat_level <= HEAT_CLEAR:
		return false
	if delta <= 0.0:
		return false

	_search_elapsed += delta
	if _search_elapsed < search_evasion_seconds:
		return false

	_heat_level = HEAT_CLEAR
	_state = WantedState.CLEAR
	_last_reason = "evasion:search_timeout"
	_search_elapsed = 0.0
	return true

func reset() -> void:
	_heat_level = HEAT_CLEAR
	_state = WantedState.CLEAR
	_last_known_position = Vector3.ZERO
	_last_known_direction = Vector3.ZERO
	_last_reason = ""
	_search_elapsed = 0.0

func _normalized_or_zero(direction: Vector3) -> Vector3:
	var flat := direction
	flat.y = 0.0
	if flat.length_squared() <= 0.000001:
		return Vector3.ZERO
	return flat.normalized()
