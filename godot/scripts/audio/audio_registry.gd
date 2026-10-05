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
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:player.footstep",
		"description": "Courier reinforced work-boot footstep on salvage tarmac / dusty industrial ground"
	},
	"player.bike_mount": {
		"slot_id": "player.bike_mount",
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
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:player.bike_mount",
		"description": "Courier mounting bike chassis mechanical latch"
	},
	"player.bike_dismount": {
		"slot_id": "player.bike_dismount",
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
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:player.bike_dismount",
		"description": "Courier dismounting bike release click"
	},
	"player.signal_lock_pulse": {
		"slot_id": "player.signal_lock_pulse",
		"domain": Domain.PLAYER,
		"diegesis": Diegesis.HYBRID,
		"spatial_type": SpatialType.NON_DIEGETIC_2D,
		"mix_group": MixGroup.SIGNATURE_ECHO,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 100,
		"max_concurrency": 2,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:player.signal_lock_pulse",
		"description": "Signal tuner resonant harmonic lock confirmation"
	},
	"interaction.panel_pry": {
		"slot_id": "interaction.panel_pry",
		"domain": Domain.INTERACTION,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.INCIDENTAL_UI,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 100,
		"max_concurrency": 2,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:interaction.panel_pry",
		"description": "Corroded panel initial pry stress crack"
	},
	"interaction.panel_peel": {
		"slot_id": "interaction.panel_peel",
		"domain": Domain.INTERACTION,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.INCIDENTAL_UI,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 80,
		"max_concurrency": 3,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:interaction.panel_peel",
		"description": "Panel peeling metal groan and shear"
	},
	"interaction.wire_clip": {
		"slot_id": "interaction.wire_clip",
		"domain": Domain.INTERACTION,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.INCIDENTAL_UI,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 100,
		"max_concurrency": 2,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:interaction.wire_clip",
		"description": "Wire snip snap transient"
	},
	"interaction.wire_spark": {
		"slot_id": "interaction.wire_spark",
		"domain": Domain.INTERACTION,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.INCIDENTAL_UI,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 100,
		"max_concurrency": 3,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:interaction.wire_spark",
		"description": "Exposed wire electrical crackle / spark"
	},
	"interaction.battery_insert": {
		"slot_id": "interaction.battery_insert",
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
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:interaction.battery_insert",
		"description": "Power cell locking into junction slot"
	},
	"interaction.core_extracted": {
		"slot_id": "interaction.core_extracted",
		"domain": Domain.INTERACTION,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.SIGNATURE_ECHO,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 2,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:interaction.core_extracted",
		"description": "Memory core release pneumatic hiss and lock release"
	},
	"interaction.gate_triggered": {
		"slot_id": "interaction.gate_triggered",
		"domain": Domain.INTERACTION,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.CRITICAL_THREAT,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 200,
		"max_concurrency": 2,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:interaction.gate_triggered",
		"description": "Signal gate heavy industrial barrier slam / route-switch confirmation"
	},
	"vehicle.engine_rev": {
		"slot_id": "vehicle.engine_rev",
		"domain": Domain.VEHICLE,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.VEHICLE_FEEDBACK,
		"playback_type": PlaybackType.CONTINUOUS_LOOP,
		"is_looping": true,
		"loop_start_sec": 0.0,
		"loop_end_sec": 1.1962,
		"cooldown_msec": 0,
		"max_concurrency": 2,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:vehicle.engine_rev",
		"description": "Reclaimed electric/mechanical drivetrain turbine propulsion loop"
	},
	"vehicle.brake_screech": {
		"slot_id": "vehicle.brake_screech",
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
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:vehicle.brake_screech",
		"description": "Pneumatic / disc brake skid screech"
	},
	"vehicle.collision_glance": {
		"slot_id": "vehicle.collision_glance",
		"domain": Domain.VEHICLE,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.VEHICLE_FEEDBACK,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 100,
		"max_concurrency": 3,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:vehicle.collision_glance",
		"description": "Abrasive lateral metal scrape and body-panel shear"
	},
	"vehicle.collision_hard": {
		"slot_id": "vehicle.collision_hard",
		"domain": Domain.VEHICLE,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.VEHICLE_FEEDBACK,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 100,
		"max_concurrency": 2,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:vehicle.collision_hard",
		"description": "Heavy direct chassis crumple and structural metal crash"
	},
	"pursuit.disturbance_alert": {
		"slot_id": "pursuit.disturbance_alert",
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
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:pursuit.disturbance_alert",
		"description": "Urgent electronic security detection alert before pursuit siren escalation"
	},
	"pursuit.siren_alarm": {
		"slot_id": "pursuit.siren_alarm",
		"domain": Domain.PURSUIT,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.CRITICAL_THREAT,
		"playback_type": PlaybackType.CONTINUOUS_LOOP,
		"is_looping": true,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.7772,
		"cooldown_msec": 0,
		"max_concurrency": 2,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:pursuit.siren_alarm",
		"description": "Autonomous pursuer electronic threat siren loop"
	},
	"pursuit.pursuer_sweep": {
		"slot_id": "pursuit.pursuer_sweep",
		"domain": Domain.PURSUIT,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.CRITICAL_THREAT,
		"playback_type": PlaybackType.CONTINUOUS_LOOP,
		"is_looping": true,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.8,
		"cooldown_msec": 0,
		"max_concurrency": 2,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:pursuit.pursuer_sweep",
		"description": "Pursuer scanner radar sweep tone"
	},
	"pursuit.evaded_stinger": {
		"slot_id": "pursuit.evaded_stinger",
		"domain": Domain.PURSUIT,
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
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:pursuit.evaded_stinger",
		"description": "Calm descending electronic release cue for successful pursuit break"
	},
	"pursuit.intercepted_impact": {
		"slot_id": "pursuit.intercepted_impact",
		"domain": Domain.PURSUIT,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.CRITICAL_THREAT,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:pursuit.intercepted_impact",
		"description": "Pursuer interception chassis slam and critical impact"
	},
	"echo.onset": {
		"slot_id": "echo.onset",
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
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:echo.onset",
		"description": "Memory echo electrical carrier rupture / discovery onset"
	},
	"echo.bed_loop": {
		"slot_id": "echo.bed_loop",
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
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:echo.bed_loop",
		"description": "Finite Memory Echo peak apparition / fractured harmonic signal ghost"
	},
	"echo.completion": {
		"slot_id": "echo.completion",
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
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:echo.completion",
		"description": "Memory echo electrical shimmer resolution tail / signal dissolve"
	},
	"echo.radio_interference": {
		"slot_id": "echo.radio_interference",
		"domain": Domain.ECHO,
		"diegesis": Diegesis.HYBRID,
		"spatial_type": SpatialType.HYBRID,
		"mix_group": MixGroup.SIGNATURE_ECHO,
		"playback_type": PlaybackType.CONTINUOUS_LOOP,
		"is_looping": true,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.9579,
		"cooldown_msec": 0,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:echo.radio_interference",
		"description": "Hybrid precursor Echo RF carrier contamination loop"
	},
	"world.ambient_wind": {
		"slot_id": "world.ambient_wind",
		"domain": Domain.WORLD,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.NON_DIEGETIC_2D,
		"mix_group": MixGroup.AMBIENT_TEXTURE,
		"playback_type": PlaybackType.CONTINUOUS_LOOP,
		"is_looping": true,
		"loop_start_sec": 0.0,
		"loop_end_sec": 4.4999,
		"cooldown_msec": 0,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:world.ambient_wind",
		"description": "Dry exposed scrapyard/desert ambient wind loop"
	},
	"world.radio_chatter": {
		"slot_id": "world.radio_chatter",
		"domain": Domain.WORLD,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.RADIO_MUSIC,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 3000,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:world.radio_chatter",
		"description": "Corrupted courier transmission burst"
	},
	"world.fb13_thrum": {
		"slot_id": "world.fb13_thrum",
		"domain": Domain.WORLD,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.DIEGETIC_3D,
		"mix_group": MixGroup.AMBIENT_TEXTURE,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 200,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:world.fb13_thrum",
		"description": "FB-13 companion infrastructure thrum / mechanism resonance pulse"
	},
	"radio.yardline.song_01.intro": {
		"slot_id": "radio.yardline.song_01.intro",
		"domain": Domain.RADIO,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.NON_DIEGETIC_2D,
		"mix_group": MixGroup.RADIO_MUSIC,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:radio.yardline.song_01.intro",
		"description": "Yardline 88.3 Scrap Pulse intro segment"
	},
	"radio.yardline.song_01.body": {
		"slot_id": "radio.yardline.song_01.body",
		"domain": Domain.RADIO,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.NON_DIEGETIC_2D,
		"mix_group": MixGroup.RADIO_MUSIC,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:radio.yardline.song_01.body",
		"description": "Yardline 88.3 Scrap Pulse body segment"
	},
	"radio.yardline.song_01.outro": {
		"slot_id": "radio.yardline.song_01.outro",
		"domain": Domain.RADIO,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.NON_DIEGETIC_2D,
		"mix_group": MixGroup.RADIO_MUSIC,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:radio.yardline.song_01.outro",
		"description": "Yardline 88.3 Scrap Pulse outro segment"
	},
	"radio.yardline.song_02.body": {
		"slot_id": "radio.yardline.song_02.body",
		"domain": Domain.RADIO,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.NON_DIEGETIC_2D,
		"mix_group": MixGroup.RADIO_MUSIC,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:radio.yardline.song_02.body",
		"description": "Yardline 88.3 Neon Drift body segment"
	},
	"radio.yardline.song_03.body": {
		"slot_id": "radio.yardline.song_03.body",
		"domain": Domain.RADIO,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.NON_DIEGETIC_2D,
		"mix_group": MixGroup.RADIO_MUSIC,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:radio.yardline.song_03.body",
		"description": "Yardline 88.3 Rust Groove body segment"
	},
	"radio.yardline.song_04.body": {
		"slot_id": "radio.yardline.song_04.body",
		"domain": Domain.RADIO,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.NON_DIEGETIC_2D,
		"mix_group": MixGroup.RADIO_MUSIC,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:radio.yardline.song_04.body",
		"description": "Yardline 88.3 Signal Loss body segment"
	},
	"radio.yardline.dj_link_intro": {
		"slot_id": "radio.yardline.dj_link_intro",
		"domain": Domain.RADIO,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.NON_DIEGETIC_2D,
		"mix_group": MixGroup.RADIO_MUSIC,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:radio.yardline.dj_link_intro",
		"description": "Yardline 88.3 DJ voice intro link"
	},
	"radio.yardline.dj_link_outro": {
		"slot_id": "radio.yardline.dj_link_outro",
		"domain": Domain.RADIO,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.NON_DIEGETIC_2D,
		"mix_group": MixGroup.RADIO_MUSIC,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:radio.yardline.dj_link_outro",
		"description": "Yardline 88.3 DJ voice outro link"
	},
	"radio.yardline.dj_sweeper": {
		"slot_id": "radio.yardline.dj_sweeper",
		"domain": Domain.RADIO,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.NON_DIEGETIC_2D,
		"mix_group": MixGroup.RADIO_MUSIC,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:radio.yardline.dj_sweeper",
		"description": "Yardline 88.3 radio station sweeper sound"
	},
	"radio.yardline.station_id_01": {
		"slot_id": "radio.yardline.station_id_01",
		"domain": Domain.RADIO,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.NON_DIEGETIC_2D,
		"mix_group": MixGroup.RADIO_MUSIC,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:radio.yardline.station_id_01",
		"description": "Yardline 88.3 signature jingle ID"
	},
	"radio.yardline.station_id_02": {
		"slot_id": "radio.yardline.station_id_02",
		"domain": Domain.RADIO,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.NON_DIEGETIC_2D,
		"mix_group": MixGroup.RADIO_MUSIC,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:radio.yardline.station_id_02",
		"description": "Yardline 88.3 sting station ID"
	},
	"radio.yardline.advert_01": {
		"slot_id": "radio.yardline.advert_01",
		"domain": Domain.RADIO,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.NON_DIEGETIC_2D,
		"mix_group": MixGroup.RADIO_MUSIC,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:radio.yardline.advert_01",
		"description": "Yardline 88.3 satirical surplus salvage advert"
	},
	"radio.yardline.advert_02": {
		"slot_id": "radio.yardline.advert_02",
		"domain": Domain.RADIO,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.NON_DIEGETIC_2D,
		"mix_group": MixGroup.RADIO_MUSIC,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:radio.yardline.advert_02",
		"description": "Yardline 88.3 hydro-ration commercial advert"
	},
	"radio.yardline.world_pursuit": {
		"slot_id": "radio.yardline.world_pursuit",
		"domain": Domain.RADIO,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.NON_DIEGETIC_2D,
		"mix_group": MixGroup.RADIO_MUSIC,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:radio.yardline.world_pursuit",
		"description": "Yardline 88.3 scrap yard pursuit bulletin"
	},
	"radio.yardline.world_gate": {
		"slot_id": "radio.yardline.world_gate",
		"domain": Domain.RADIO,
		"diegesis": Diegesis.DIEGETIC,
		"spatial_type": SpatialType.NON_DIEGETIC_2D,
		"mix_group": MixGroup.RADIO_MUSIC,
		"playback_type": PlaybackType.TRANSIENT,
		"is_looping": false,
		"loop_start_sec": 0.0,
		"loop_end_sec": 0.0,
		"cooldown_msec": 0,
		"max_concurrency": 1,
		"asset_status": AssetStatus.PROCEDURAL_FALLBACK,
		"replacement_required": true,
		"production_asset_path": "",
		"source_provenance": "ORIGINAL_PROCEDURAL:RI01:radio.yardline.world_gate",
		"description": "Yardline 88.3 perimeter barrier activity alert"
	},
}

static func is_reference_allowed_for_status(status: int) -> bool:
	match status:
		AssetStatus.PROCEDURAL_FALLBACK:
			return true
		AssetStatus.REFERENCE_ONLY:
			return true
		AssetStatus.ORIGINAL_WIP:
			return true
		AssetStatus.ORIGINAL_FINAL:
			return false
		AssetStatus.LICENSED_FINAL:
			return false
		_:
			return false

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

static func get_production_asset_path(slot_id: String) -> String:
	if SLOTS.has(slot_id):
		return SLOTS[slot_id].get("production_asset_path", "")
	return ""

static func get_source_provenance(slot_id: String) -> String:
	if SLOTS.has(slot_id):
		return SLOTS[slot_id].get("source_provenance", "")
	return ""
