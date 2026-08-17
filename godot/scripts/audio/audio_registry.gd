class_name AudioRegistry
extends RefCounted

## Semantic Audio Registry for ECHOES
## Maps game semantic events to typed audio metadata, domain hierarchy,
## diegetic classification, spatiality, mix groups, loop lifecycle, and asset replacement statuses.

enum Domain {
	PLAYER,
	WORLD,
	VEHICLE,
	INTERACTION,
	PURSUIT,
	ECHO,
	UI,
	RADIO
}

enum Diegesis {
	DIEGETIC,
	NON_DIEGETIC,
	HYBRID
}

enum SpatialType {
	DIEGETIC_3D,
	NON_DIEGETIC_2D,
	HYBRID
}

enum MixGroup {
	CRITICAL_THREAT,
	SIGNATURE_ECHO,
	VEHICLE_FEEDBACK,
	RADIO_MUSIC,
	AMBIENT_TEXTURE,
	INCIDENTAL_UI
}

enum PlaybackType {
	TRANSIENT,
	CONTINUOUS_LOOP
}

enum AssetStatus {
	PROCEDURAL_FALLBACK,
	REFERENCE_ONLY,
	ORIGINAL_WIP,
	ORIGINAL_FINAL,
	LICENSED_FINAL
}

# Master semantic slot table
const SLOTS: Dictionary = {
	"player.footstep": {
		"slot_id": "player.footstep",
		"sound_event": 0, # SoundEvent.FOOTSTEP
		"domain": Domain.PLAYER,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.INCIDENTAL_UI,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 120,
		"max_concurrency": 4,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Footstep impact on metal / dirt ground"
	},
	"player.bike_mount": {
		"slot_id": "player.bike_mount",
		"sound_event": 10, # SoundEvent.BIKE_MOUNT
		"domain": Domain.PLAYER,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.INCIDENTAL_UI,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 2,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Courier mounting bike chassis mechanical latch"
	},
	"player.bike_dismount": {
		"slot_id": "player.bike_dismount",
		"sound_event": 11, # SoundEvent.BIKE_DISMOUNT
		"domain": Domain.PLAYER,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.INCIDENTAL_UI,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 2,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Courier dismounting bike chassis unlatch"
	},
	"player.dismount_rejected": {
		"slot_id": "player.dismount_rejected",
		"sound_event": 14, # SoundEvent.DISMOUNT_REJECTED
		"domain": Domain.PLAYER,
		"diegesis": Diegesis.NON_DIEGETIC,
		"spatial_type": SpatialType.NON_DIEGETIC_2D,
		"mix_group": MixGroup.INCIDENTAL_UI,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 150,
		"max_concurrency": 2,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": false,
		"description": "High-speed dismount denial warning buzz"
	},
	"interaction.proximity_hum": {
		"slot_id": "interaction.proximity_hum",
		"sound_event": 1, # SoundEvent.PROXIMITY_HUM
		"domain": Domain.INTERACTION,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.AMBIENT_TEXTURE,
		"playback_type": PlaybackType.CONTINUOUS_LOOP,
		"is_looping": true,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.5,
		"cooldown_msec": 0,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Electromagnetic proximity hum near scrap core"
	},
	"interaction.panel_peel": {
		"slot_id": "interaction.panel_peel",
		"sound_event": 2, # SoundEvent.PANEL_PEEL
		"domain": Domain.INTERACTION,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.INCIDENTAL_UI,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 2,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Metal panel tearing / pry bar lever sound"
	},
	"interaction.core_pull": {
		"slot_id": "interaction.core_pull",
		"sound_event": 3, # SoundEvent.CORE_PULL
		"domain": Domain.INTERACTION,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.INCIDENTAL_UI,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 2,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Scrap core extraction friction and unseat"
	},
	"interaction.spark": {
		"slot_id": "interaction.spark",
		"sound_event": 4, # SoundEvent.SPARK
		"domain": Domain.INTERACTION,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.INCIDENTAL_UI,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 80,
		"max_concurrency": 4,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Electrical short discharge during salvage"
	},
	"interaction.completion": {
		"slot_id": "interaction.completion",
		"sound_event": 5, # SoundEvent.COMPLETION
		"domain": Domain.INTERACTION,
		"diegesis": Diegesis.HYBRID,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.INCIDENTAL_UI,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 2,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Core extraction sequence success confirmation"
	},
	"interaction.signal_lock": {
		"slot_id": "interaction.signal_lock",
		"sound_event": 6, # SoundEvent.SIGNAL_LOCK
		"domain": Domain.INTERACTION,
		"diegesis": Diegesis.HYBRID,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.INCIDENTAL_UI,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 2,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Signal acquisition sweep lock confirmation"
	},
	"interaction.panel_powered": {
		"slot_id": "interaction.panel_powered",
		"sound_event": 7, # SoundEvent.PANEL_POWERED
		"domain": Domain.INTERACTION,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.INCIDENTAL_UI,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 2,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Capacitor surge and power rail energize"
	},
	"vehicle.engine_rev": {
		"slot_id": "vehicle.engine_rev",
		"sound_event": 8, # SoundEvent.ENGINE_REV
		"domain": Domain.VEHICLE,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.VEHICLE_FEEDBACK,
		"playback_type": PlaybackType.CONTINUOUS_LOOP,
		"is_looping": true,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.5,
		"cooldown_msec": 0,
		"max_concurrency": 2,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Continuous vehicle engine drone with speed-scaled pitch"
	},
	"vehicle.brake_screech": {
		"slot_id": "vehicle.brake_screech",
		"sound_event": 9, # SoundEvent.BRAKE_SCREECH
		"domain": Domain.VEHICLE,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.VEHICLE_FEEDBACK,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 150,
		"max_concurrency": 3,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Tire slip friction / handbrake skid screech"
	},
	"vehicle.collision_glance": {
		"slot_id": "vehicle.collision_glance",
		"sound_event": 18, # SoundEvent.COLLISION_GLANCE
		"domain": Domain.VEHICLE,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.VEHICLE_FEEDBACK,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 120,
		"max_concurrency": 3,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Glancing side scrape against junk/wall"
	},
	"vehicle.collision_head_on": {
		"slot_id": "vehicle.collision_head_on",
		"sound_event": 19, # SoundEvent.COLLISION_HEAD_ON
		"domain": Domain.VEHICLE,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.VEHICLE_FEEDBACK,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 200,
		"max_concurrency": 2,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Heavy frontal collision impact crunch"
	},
	"pursuit.siren_alarm": {
		"slot_id": "pursuit.siren_alarm",
		"sound_event": 12, # SoundEvent.SIREN_ALARM
		"domain": Domain.PURSUIT,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.CRITICAL_THREAT,
		"playback_type": PlaybackType.CONTINUOUS_LOOP,
		"is_looping": true,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.6,
		"cooldown_msec": 0,
		"max_concurrency": 2,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Security scout spatial alarm siren"
	},
	"pursuit.disturbance_alert": {
		"slot_id": "pursuit.disturbance_alert",
		"sound_event": 15, # SoundEvent.DISTURBANCE_ALERT
		"domain": Domain.PURSUIT,
		"diegesis": Diegesis.HYBRID,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.CRITICAL_THREAT,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 2,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Initial scrap yard disturbance detection stinger"
	},
	"pursuit.intercepted": {
		"slot_id": "pursuit.intercepted",
		"sound_event": 16, # SoundEvent.PURSUIT_INTERCEPTED
		"domain": Domain.PURSUIT,
		"diegesis": Diegesis.HYBRID,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.CRITICAL_THREAT,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 2,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Security interceptor ramming or boxing stinger"
	},
	"pursuit.gate_slam": {
		"slot_id": "pursuit.gate_slam",
		"sound_event": 13, # SoundEvent.GATE_SLAM
		"domain": Domain.PURSUIT,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.CRITICAL_THREAT,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 2,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Gate breach or shortcut closure impact"
	},
	"pursuit.evasion_release": {
		"slot_id": "pursuit.evasion_release",
		"sound_event": 17, # SoundEvent.EVASION_RELEASE
		"domain": Domain.PURSUIT,
		"diegesis": Diegesis.NON_DIEGETIC,
		"spatial_type": SpatialType.NON_DIEGETIC_2D,
		"mix_group": MixGroup.CRITICAL_THREAT,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Pursuit evasion release rising relief sweep"
	},
	"echo.onset": {
		"slot_id": "echo.onset",
		"sound_event": 20, # SoundEvent.ECHO_ONSET
		"domain": Domain.ECHO,
		"diegesis": Diegesis.NON_DIEGETIC,
		"spatial_type": SpatialType.NON_DIEGETIC_2D,
		"mix_group": MixGroup.SIGNATURE_ECHO,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": false,
		"description": "Memory Echo onset crackle opening perception window"
	},
	"echo.peak": {
		"slot_id": "echo.peak",
		"sound_event": 21, # SoundEvent.ECHO_PEAK
		"domain": Domain.ECHO,
		"diegesis": Diegesis.NON_DIEGETIC,
		"spatial_type": SpatialType.NON_DIEGETIC_2D,
		"mix_group": MixGroup.SIGNATURE_ECHO,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": false,
		"description": "Memory Echo fractured harmonic core payload"
	},
	"echo.tail": {
		"slot_id": "echo.tail",
		"sound_event": 22, # SoundEvent.ECHO_TAIL
		"domain": Domain.ECHO,
		"diegesis": Diegesis.NON_DIEGETIC,
		"spatial_type": SpatialType.NON_DIEGETIC_2D,
		"mix_group": MixGroup.SIGNATURE_ECHO,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": false,
		"description": "Memory Echo electrical shimmer tail into quiet"
	},
	"world.ambient_work_clink": {
		"slot_id": "world.ambient_work_clink",
		"sound_event": 23, # SoundEvent.AMBIENT_WORK_CLINK
		"domain": Domain.WORLD,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.AMBIENT_TEXTURE,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 3,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Distant yard scrap sorting and tool clinks"
	},
	"world.ambient_servo_hum": {
		"slot_id": "world.ambient_servo_hum",
		"sound_event": 24, # SoundEvent.AMBIENT_SERVO_HUM
		"domain": Domain.WORLD,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.AMBIENT_TEXTURE,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 3,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"description": "Overhead crane / automated sorting servo sweep"
	}
}

# Reverse lookup table: int (sound_event) -> String (slot_id)
static var _EVENT_TO_SLOT_CACHE: Dictionary = {}

static func _static_init() -> void:
	_build_reverse_lookup()

static func _build_reverse_lookup() -> void:
	_EVENT_TO_SLOT_CACHE.clear()
	for slot_id in SLOTS.keys():
		var slot_def: Dictionary = SLOTS[slot_id]
		var ev: int = slot_def.get("sound_event", -1)
		if ev >= 0:
			_EVENT_TO_SLOT_CACHE[ev] = slot_id

static func event_to_slot_id(event: int) -> String:
	if _EVENT_TO_SLOT_CACHE.is_empty():
		_build_reverse_lookup()
	return _EVENT_TO_SLOT_CACHE.get(event, "")

static func has_slot(slot_id: String) -> bool:
	return SLOTS.has(slot_id)

static func get_slot(slot_id: String) -> Dictionary:
	if SLOTS.has(slot_id):
		return SLOTS[slot_id]
	return {}

static func get_all_slots() -> Dictionary:
	return SLOTS

static func get_slots_by_domain(domain: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot_id in SLOTS.keys():
		var slot_def: Dictionary = SLOTS[slot_id]
		if slot_def.get("domain") == domain:
			result.append(slot_def)
	return result

static func get_slots_by_diegesis(diegesis: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot_id in SLOTS.keys():
		var slot_def: Dictionary = SLOTS[slot_id]
		if slot_def.get("diegesis") == diegesis:
			result.append(slot_def)
	return result

static func get_slots_by_mix_group(mix_group: int) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot_id in SLOTS.keys():
		var slot_def: Dictionary = SLOTS[slot_id]
		if slot_def.get("mix_group") == mix_group:
			result.append(slot_def)
	return result

static func get_replacement_backlog() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for slot_id in SLOTS.keys():
		var slot_def: Dictionary = SLOTS[slot_id]
		if slot_def.get("replacement_required", false):
			result.append(slot_def)
	return result
