class_name UIAudioSemanticRegistry
extends RefCounted

# Audio 06 — compact UI semantic extension for the #21 registry/resolver model.
# These are metadata-only slots. Playback policy remains owned by AudioManager's
# UIAudioIdentityLayer and local-reference resolution remains dev opt-in.

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")

const SLOTS: Dictionary = {
	"ui.nav_move": {
		"slot_id": "ui.nav_move",
		"domain": "UI",
		"diegesis": "NON_DIEGETIC",
		"spatial_type": "NON_DIEGETIC_2D",
		"mix_group": "INCIDENTAL_UI",
		"playback_type": "TRANSIENT",
		"cooldown_msec": 55,
		"max_concurrency": 2,
		"gain_db": -18.0,
		"critical_essential": false,
		"asset_status": AudioRegistryScript.AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Short dry navigation tick for list/cursor movement"
	},
	"ui.nav_confirm": {
		"slot_id": "ui.nav_confirm",
		"domain": "UI",
		"diegesis": "NON_DIEGETIC",
		"spatial_type": "NON_DIEGETIC_2D",
		"mix_group": "INCIDENTAL_UI",
		"playback_type": "TRANSIENT",
		"cooldown_msec": 90,
		"max_concurrency": 2,
		"gain_db": -14.0,
		"critical_essential": false,
		"asset_status": AudioRegistryScript.AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Compact positive relay-latch confirmation"
	},
	"ui.nav_back": {
		"slot_id": "ui.nav_back",
		"domain": "UI",
		"diegesis": "NON_DIEGETIC",
		"spatial_type": "NON_DIEGETIC_2D",
		"mix_group": "INCIDENTAL_UI",
		"playback_type": "TRANSIENT",
		"cooldown_msec": 90,
		"max_concurrency": 2,
		"gain_db": -16.0,
		"critical_essential": false,
		"asset_status": AudioRegistryScript.AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Short descending release/back cue"
	},
	"ui.mode_switch": {
		"slot_id": "ui.mode_switch",
		"domain": "UI",
		"diegesis": "NON_DIEGETIC",
		"spatial_type": "NON_DIEGETIC_2D",
		"mix_group": "INCIDENTAL_UI",
		"playback_type": "TRANSIENT",
		"cooldown_msec": 120,
		"max_concurrency": 1,
		"gain_db": -15.0,
		"critical_essential": false,
		"asset_status": AudioRegistryScript.AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Two-position mechanical mode transition cue"
	},
	"ui.reject": {
		"slot_id": "ui.reject",
		"domain": "UI",
		"diegesis": "NON_DIEGETIC",
		"spatial_type": "NON_DIEGETIC_2D",
		"mix_group": "INCIDENTAL_UI",
		"playback_type": "TRANSIENT",
		"cooldown_msec": 150,
		"max_concurrency": 1,
		"gain_db": -12.0,
		"critical_essential": true,
		"asset_status": AudioRegistryScript.AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Low dry invalid/reject double-pulse"
	},
	"ui.radio_station_step": {
		"slot_id": "ui.radio_station_step",
		"domain": "UI",
		"diegesis": "NON_DIEGETIC",
		"spatial_type": "NON_DIEGETIC_2D",
		"mix_group": "INCIDENTAL_UI",
		"playback_type": "TRANSIENT",
		"cooldown_msec": 100,
		"max_concurrency": 2,
		"gain_db": -16.0,
		"critical_essential": false,
		"asset_status": AudioRegistryScript.AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Brief tuner/relay step for radio state changes"
	},
	"ui.replay_retry_confirm": {
		"slot_id": "ui.replay_retry_confirm",
		"domain": "UI",
		"diegesis": "NON_DIEGETIC",
		"spatial_type": "NON_DIEGETIC_2D",
		"mix_group": "INCIDENTAL_UI",
		"playback_type": "TRANSIENT",
		"cooldown_msec": 160,
		"max_concurrency": 1,
		"gain_db": -11.0,
		"critical_essential": true,
		"asset_status": AudioRegistryScript.AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Firm replay/retry commitment latch"
	}
}

static func has_slot(slot_id: String) -> bool:
	return SLOTS.has(slot_id)

static func get_slot(slot_id: String) -> Dictionary:
	return SLOTS.get(slot_id, {})

static func get_all_slots() -> Dictionary:
	return SLOTS
