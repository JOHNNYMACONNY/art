extends RefCounted

const RadioStationCatalogScript = preload("res://scripts/audio/radio/radio_station_catalog.gd")

## Bounded category weights per ChatGPT #22 spec
## SONG=60, DJ_LINK=15, STATION_ID=10, ADVERT=10, ECHO_INTRUSION=0
## WORLD_REACTION is 100% EVENT-DRIVEN PRIORITY content (not randomly weighted)
const WEIGHT_SONG          := 60
const WEIGHT_DJ_LINK       := 15
const WEIGHT_STATION_ID    := 10
const WEIGHT_ADVERT        := 10
const WEIGHT_ECHO_INTRUSION := 0

const MAX_NON_SONG_GAP     := 2   ## Max consecutive non-song items before SONG is forced
const SONG_HISTORY_LIMIT   := 4   ## RECENT_CONTENT_WINDOW = 4 for songs
const INTERSTITIAL_HISTORY_LIMIT := 4  ## Recent interstitial window
const DEFAULT_SEED         := 1337

var _station_id: String = RadioStationCatalogScript.DEFAULT_STATION_ID
var _initial_seed: int = DEFAULT_SEED
var _rng := RandomNumberGenerator.new()
var _current_item: Dictionary = {}
var _cursor_position_sec: float = 0.0
var _is_paused: bool = false

var _song_history: Array[String] = []
var _interstitial_history: Array[String] = []
var _non_song_gap_counter: int = 0
var _last_category: int = -1

## Pending world events queue. Events are deferred (not dropped) when max-gap rule fires.
var _pending_world_events: Array[String] = []

func _init(initial_seed: int = DEFAULT_SEED, station: String = RadioStationCatalogScript.DEFAULT_STATION_ID) -> void:
	_station_id = station
	_initial_seed = initial_seed
	_rng.seed = initial_seed

func set_seed(s: int) -> void:
	_initial_seed = s
	_rng.seed = s

func get_seed() -> int:
	return _rng.seed

func get_initial_seed() -> int:
	return _initial_seed

func set_station(station: String) -> void:
	if _station_id != station:
		_station_id = station
		reset_programming_state()

func get_station_id() -> String:
	return _station_id

func reset_programming_state() -> void:
	_current_item = {}
	_cursor_position_sec = 0.0
	_is_paused = false
	_song_history.clear()
	_interstitial_history.clear()
	_non_song_gap_counter = 0
	_last_category = -1
	_pending_world_events.clear()

## Director-only reset: restores configured initial seed (or sets new_seed if provided)
## and clears all programming state.
func reset(new_seed: int = -1) -> void:
	if new_seed != -1:
		_initial_seed = new_seed
	_rng.seed = _initial_seed
	reset_programming_state()

func notify_world_event(event_name: String) -> void:
	if not _pending_world_events.has(event_name):
		_pending_world_events.append(event_name)

func get_current_item() -> Dictionary:
	return _current_item

func get_cursor_position() -> float:
	return _cursor_position_sec

func set_cursor_position(pos: float) -> void:
	_cursor_position_sec = maxf(0.0, pos)

func is_paused() -> bool:
	return _is_paused

func set_paused(paused: bool) -> void:
	_is_paused = paused

func advance_next_item() -> Dictionary:
	var next_item: Dictionary = {}

	# 1. Max-gap rule: SONG is FORCED and world events are DEFERRED (preserved in queue)
	if _non_song_gap_counter >= MAX_NON_SONG_GAP:
		next_item = _pick_item_for_category(RadioStationCatalogScript.Category.SONG)

	# 2. Check for pending reactive world events (event-driven priority content)
	# Rule: Cannot immediately repeat WORLD_REACTION after another WORLD_REACTION; preserve event in queue
	elif not _pending_world_events.is_empty() and _last_category != RadioStationCatalogScript.Category.WORLD_REACTION:
		var event_name: String = _pending_world_events.pop_front()
		var world_items: Array[Dictionary] = RadioStationCatalogScript.get_items_by_category(
			_station_id, RadioStationCatalogScript.Category.WORLD_REACTION)
		for wi in world_items:
			if wi.get("trigger_event") == event_name:
				next_item = wi.duplicate(true)
				break
		if next_item.is_empty():
			var target_category: int = _choose_next_category()
			next_item = _pick_item_for_category(target_category)

	# 3. Normal weighted category selection
	else:
		var target_category: int = _choose_next_category()
		next_item = _pick_item_for_category(target_category)

	# Fallback if all selection paths yielded empty
	if next_item.is_empty():
		var songs: Array[Dictionary] = RadioStationCatalogScript.get_items_by_category(
			_station_id, RadioStationCatalogScript.Category.SONG)
		if not songs.is_empty():
			next_item = songs[0].duplicate(true)

	# 4. Update state, anti-repeat tracking, and gap counters
	_current_item = next_item
	_cursor_position_sec = 0.0
	var cat: int = next_item.get("category", RadioStationCatalogScript.Category.SONG)
	_last_category = cat

	if cat == RadioStationCatalogScript.Category.SONG:
		_non_song_gap_counter = 0
		_song_history.append(next_item.get("id", ""))
		while _song_history.size() > 3: # Keep 3 in history to ensure non-depletion across 4 songs
			_song_history.pop_front()
	else:
		_non_song_gap_counter += 1
		_interstitial_history.append(next_item.get("id", ""))
		while _interstitial_history.size() > INTERSTITIAL_HISTORY_LIMIT:
			_interstitial_history.pop_front()

	return _current_item

func _choose_next_category() -> int:
	## Build weighted pool based on eligible categories
	## Rule: no immediate repeat of the same non-SONG category
	var total: int = WEIGHT_SONG
	if _last_category != RadioStationCatalogScript.Category.DJ_LINK:
		total += WEIGHT_DJ_LINK
	if _last_category != RadioStationCatalogScript.Category.STATION_ID:
		total += WEIGHT_STATION_ID
	if _last_category != RadioStationCatalogScript.Category.ADVERT:
		total += WEIGHT_ADVERT

	var roll: int = _rng.randi_range(0, total - 1)

	## Walk thresholds in order: SONG always eligible
	var threshold: int = WEIGHT_SONG
	if roll < threshold:
		return RadioStationCatalogScript.Category.SONG

	if _last_category != RadioStationCatalogScript.Category.DJ_LINK:
		threshold += WEIGHT_DJ_LINK
		if roll < threshold:
			return RadioStationCatalogScript.Category.DJ_LINK

	if _last_category != RadioStationCatalogScript.Category.STATION_ID:
		threshold += WEIGHT_STATION_ID
		if roll < threshold:
			return RadioStationCatalogScript.Category.STATION_ID

	if _last_category != RadioStationCatalogScript.Category.ADVERT:
		threshold += WEIGHT_ADVERT
		if roll < threshold:
			return RadioStationCatalogScript.Category.ADVERT

	return RadioStationCatalogScript.Category.SONG

func _pick_item_for_category(category: int) -> Dictionary:
	var items: Array[Dictionary] = RadioStationCatalogScript.get_items_by_category(
		_station_id, category as RadioStationCatalogScript.Category)
	if items.is_empty():
		return {}

	var candidates: Array[Dictionary] = []

	if category == RadioStationCatalogScript.Category.SONG:
		# Filter out recently played songs in history window (RECENT_CONTENT_WINDOW=4)
		for item in items:
			if not _song_history.has(item.get("id")):
				candidates.append(item)
		if candidates.is_empty():
			candidates = items.duplicate()
	else:
		# Filter out items in recent interstitial history window
		for item in items:
			if not _interstitial_history.has(item.get("id")):
				candidates.append(item)
		if candidates.is_empty():
			candidates = items.duplicate()

	var idx: int = _rng.randi_range(0, candidates.size() - 1)
	return candidates[idx].duplicate(true)

# -----------------------------------------------------------------------------
# SERIALIZATION & STATE RESTORATION
# -----------------------------------------------------------------------------

func serialize_state() -> Dictionary:
	return {
		"station_id": _station_id,
		"initial_seed": _initial_seed,
		"current_item": _current_item.duplicate(true),
		"cursor_position_sec": _cursor_position_sec,
		"is_paused": _is_paused,
		"song_history": _song_history.duplicate(),
		"interstitial_history": _interstitial_history.duplicate(),
		"non_song_gap_counter": _non_song_gap_counter,
		"last_category": _last_category,
		"rng_seed": _rng.seed,
		"rng_state": _rng.state,
		"pending_world_events": _pending_world_events.duplicate()
	}

func deserialize_state(data: Dictionary) -> bool:
	if not (data is Dictionary):
		return false
	if not data.has("station_id") or not data.has("cursor_position_sec"):
		return false

	_station_id = data.get("station_id", RadioStationCatalogScript.DEFAULT_STATION_ID)
	_initial_seed = data.get("initial_seed", DEFAULT_SEED)
	_current_item = data.get("current_item", {}).duplicate(true)
	_cursor_position_sec = data.get("cursor_position_sec", 0.0)
	_is_paused = data.get("is_paused", false)
	_song_history = Array(data.get("song_history", []), TYPE_STRING, &"", null)
	_interstitial_history = Array(data.get("interstitial_history", []), TYPE_STRING, &"", null)
	_non_song_gap_counter = data.get("non_song_gap_counter", 0)
	_last_category = data.get("last_category", -1)
	_pending_world_events = Array(data.get("pending_world_events", []), TYPE_STRING, &"", null)

	if data.has("rng_seed"):
		_rng.seed = data["rng_seed"]
	if data.has("rng_state"):
		_rng.state = data["rng_state"]

	return true
