class_name RadioStationCatalog
extends RefCounted

## Radio Station Catalog for YARDLINE
## Immutable station definitions, segment metadata, and fallback properties.
## Defines the PROPOSED/EXPERIMENTAL "YARDLINE 88.3" station identity.

enum Category {
	SONG,
	DJ_LINK,
	STATION_ID,
	ADVERT,
	WORLD_REACTION,
	ECHO_INTRUSION # Inactive stub for later milestone (#25)
}

## Segment playback phases (for INTRO→BODY→OUTRO model)
enum Phase {
	INTRO,
	BODY,
	OUTRO
}

const DEFAULT_STATION_ID := "radio.yardline"

# Master Station Catalog
const STATIONS: Dictionary = {
	"radio.yardline": {
		"station_id": "radio.yardline",
		"name": "YARDLINE 88.3",
		"frequency_mhz": 88.3,
		"tagline": "Scrap Frequency / Pirate Relay",
		"description": "Autonomous underground radio relay transmitting synthesized scrap grooves and yard traffic alerts.",
		"is_experimental": true,
		"items": [
			# --- SONGS ---
			# song_01: Authored 3-phase segmented song (INTRO -> BODY -> OUTRO)
			{
				"id": "song_01_scrap_pulse",
				"category": Category.SONG,
				"title": "Scrap Pulse",
				"artist": "Null Pointer",
				"bpm": 120,
				"base_freq_hz": 220.0,
				"segments": [
					{
						"phase": Phase.INTRO,
						"semantic_slot_id": "radio.yardline.song_01.intro",
						"duration_sec": 0.5,
						"base_freq_hz": 220.0
					},
					{
						"phase": Phase.BODY,
						"semantic_slot_id": "radio.yardline.song_01.body",
						"duration_sec": 3.0,
						"base_freq_hz": 220.0
					},
					{
						"phase": Phase.OUTRO,
						"semantic_slot_id": "radio.yardline.song_01.outro",
						"duration_sec": 0.5,
						"base_freq_hz": 220.0
					}
				]
			},
			# song_02: Authored BODY-only song (Single phase)
			{
				"id": "song_02_neon_drift",
				"category": Category.SONG,
				"title": "Neon Drift",
				"artist": "Yard Unit 7",
				"bpm": 128,
				"base_freq_hz": 261.63,
				"segments": [
					{
						"phase": Phase.BODY,
						"semantic_slot_id": "radio.yardline.song_02.body",
						"duration_sec": 3.5,
						"base_freq_hz": 261.63
					}
				]
			},
			# song_03: Authored BODY-only song
			{
				"id": "song_03_rust_groove",
				"category": Category.SONG,
				"title": "Rust Groove",
				"artist": "Courier Zero",
				"bpm": 115,
				"base_freq_hz": 196.0,
				"segments": [
					{
						"phase": Phase.BODY,
						"semantic_slot_id": "radio.yardline.song_03.body",
						"duration_sec": 3.5,
						"base_freq_hz": 196.0
					}
				]
			},
			# song_04: Authored BODY-only song
			{
				"id": "song_04_signal_loss",
				"category": Category.SONG,
				"title": "Signal Loss",
				"artist": "The Resonators",
				"bpm": 130,
				"base_freq_hz": 329.63,
				"segments": [
					{
						"phase": Phase.BODY,
						"semantic_slot_id": "radio.yardline.song_04.body",
						"duration_sec": 3.5,
						"base_freq_hz": 329.63
					}
				]
			},

			# --- DJ LINKS ---
			{
				"id": "dj_01_track_intro",
				"category": Category.DJ_LINK,
				"title": "DJ Intro - Keep Moving",
				"context": "INTRO",
				"base_freq_hz": 440.0,
				"segments": [
					{
						"phase": Phase.BODY,
						"semantic_slot_id": "radio.yardline.dj_link_intro",
						"duration_sec": 1.2,
						"base_freq_hz": 440.0
					}
				]
			},
			{
				"id": "dj_02_track_outro",
				"category": Category.DJ_LINK,
				"title": "DJ Outro - Stay Tuned",
				"context": "OUTRO",
				"base_freq_hz": 440.0,
				"segments": [
					{
						"phase": Phase.BODY,
						"semantic_slot_id": "radio.yardline.dj_link_outro",
						"duration_sec": 1.0,
						"base_freq_hz": 440.0
					}
				]
			},
			{
				"id": "dj_03_sweeper",
				"category": Category.DJ_LINK,
				"title": "DJ Sweeper - Yardline Flow",
				"context": "SWEEPER",
				"base_freq_hz": 520.0,
				"segments": [
					{
						"phase": Phase.BODY,
						"semantic_slot_id": "radio.yardline.dj_sweeper",
						"duration_sec": 0.8,
						"base_freq_hz": 520.0
					}
				]
			},

			# --- STATION IDS ---
			{
				"id": "id_01_yardline_jingle",
				"category": Category.STATION_ID,
				"title": "Yardline 88.3 Signature Jingle",
				"base_freq_hz": 660.0,
				"segments": [
					{
						"phase": Phase.BODY,
						"semantic_slot_id": "radio.yardline.station_id_01",
						"duration_sec": 1.5,
						"base_freq_hz": 660.0
					}
				]
			},
			{
				"id": "id_02_yardline_sting",
				"category": Category.STATION_ID,
				"title": "Yardline Stinger",
				"base_freq_hz": 880.0,
				"segments": [
					{
						"phase": Phase.BODY,
						"semantic_slot_id": "radio.yardline.station_id_02",
						"duration_sec": 0.8,
						"base_freq_hz": 880.0
					}
				]
			},

			# --- ADVERTS ---
			{
				"id": "ad_01_scrap_parts",
				"category": Category.ADVERT,
				"title": "Yard Surplus Salvage Ad",
				"base_freq_hz": 350.0,
				"segments": [
					{
						"phase": Phase.BODY,
						"semantic_slot_id": "radio.yardline.advert_01",
						"duration_sec": 1.5,
						"base_freq_hz": 350.0
					}
				]
			},
			{
				"id": "ad_02_courier_rations",
				"category": Category.ADVERT,
				"title": "Hydro-Ration Paste Commercial",
				"base_freq_hz": 380.0,
				"segments": [
					{
						"phase": Phase.BODY,
						"semantic_slot_id": "radio.yardline.advert_02",
						"duration_sec": 1.5,
						"base_freq_hz": 380.0
					}
				]
			},

			# --- WORLD REACTIONS ---
			{
				"id": "world_01_pursuit_advisory",
				"category": Category.WORLD_REACTION,
				"title": "Security Pulse Advisory",
				"trigger_event": "PURSUIT_START",
				"base_freq_hz": 587.33,
				"segments": [
					{
						"phase": Phase.BODY,
						"semantic_slot_id": "radio.yardline.world_pursuit",
						"duration_sec": 1.5,
						"base_freq_hz": 587.33
					}
				]
			},
			{
				"id": "world_02_gate_activity",
				"category": Category.WORLD_REACTION,
				"title": "Perimeter Barrier Notice",
				"trigger_event": "GATE_SLAM",
				"base_freq_hz": 554.37,
				"segments": [
					{
						"phase": Phase.BODY,
						"semantic_slot_id": "radio.yardline.world_gate",
						"duration_sec": 1.2,
						"base_freq_hz": 554.37
					}
				]
			},

			# --- ECHO INTRUSION (STUB) ---
			{
				"id": "echo_01_intrusion_stub",
				"category": Category.ECHO_INTRUSION,
				"title": "Echo Frequency Bleed (Stub)",
				"is_active": false,
				"base_freq_hz": 110.0,
				"segments": [
					{
						"phase": Phase.BODY,
						"semantic_slot_id": "radio.yardline.echo_intrusion_stub",
						"duration_sec": 1.0,
						"base_freq_hz": 110.0
					}
				]
			}
		]
	}
}

static func get_station(station_id: String = DEFAULT_STATION_ID) -> Dictionary:
	if STATIONS.has(station_id):
		return STATIONS[station_id]
	return {}

static func get_all_stations() -> Dictionary:
	return STATIONS

static func get_items_by_category(station_id: String, category: Category) -> Array[Dictionary]:
	var station := get_station(station_id)
	if station.is_empty() or not station.has("items"):
		return []

	var results: Array[Dictionary] = []
	for item in station["items"]:
		if item.get("category") == category:
			results.append(item)
	return results

static func get_item_by_id(station_id: String, item_id: String) -> Dictionary:
	var station := get_station(station_id)
	if station.is_empty() or not station.has("items"):
		return {}

	for item in station["items"]:
		if item.get("id") == item_id:
			return item
	return {}
