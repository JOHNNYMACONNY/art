extends RefCounted

const AudioRegistryScript = preload("res://scripts/audio/audio_registry.gd")
const AudioManagerScript = preload("res://scripts/audio/audio_manager.gd")

const FOOTSTEP_PATH := "res://audio/player/sfx_player_footstep.wav"
const FOOTSTEP_PROVENANCE := "GTA_SA:FEET:BANK_0:SOUND_4"
const WIND_PATH := "res://audio/world/amb_world_scrapyard_wind.wav"
const WIND_PROVENANCE := "GTA_SA:SCRIPT:BANK_350:SOUND_0"
const CHATTER_SLOT := "world.radio_chatter"

static func verify(manager: Node) -> String:
	if manager == null:
		return "AudioManager is missing"

	# Footstep registry/runtime authority.
	var footstep_slot: Dictionary = AudioRegistryScript.get_slot("player.footstep")
	if footstep_slot.is_empty():
		return "player.footstep slot missing"
	if AudioManagerScript.event_to_slot_id(AudioManagerScript.SoundEvent.FOOTSTEP) != "player.footstep":
		return "FOOTSTEP event mapping changed"
	if footstep_slot.get("domain") != AudioRegistryScript.Domain.PLAYER:
		return "footstep domain changed"
	if footstep_slot.get("diegesis") != AudioRegistryScript.Diegesis.DIEGETIC:
		return "footstep diegesis changed"
	if footstep_slot.get("spatial_type") != AudioRegistryScript.SpatialType.DIEGETIC_3D:
		return "footstep must remain DIEGETIC_3D"
	if footstep_slot.get("playback_type") != AudioRegistryScript.PlaybackType.TRANSIENT:
		return "footstep must remain TRANSIENT"
	if bool(footstep_slot.get("is_looping", true)):
		return "footstep must remain non-looping"
	if int(footstep_slot.get("cooldown_msec", -1)) != 120:
		return "footstep cooldown changed"
	if int(footstep_slot.get("max_concurrency", -1)) != 4:
		return "footstep max concurrency changed"
	if footstep_slot.get("asset_status") != AudioRegistryScript.AssetStatus.LICENSED_FINAL:
		return "footstep must be production-final"
	if footstep_slot.get("replacement_required") != false:
		return "footstep must clear replacement_required"
	if AudioRegistryScript.get_production_asset_path("player.footstep") != FOOTSTEP_PATH:
		return "footstep production path mismatch"
	if AudioRegistryScript.get_source_provenance("player.footstep") != FOOTSTEP_PROVENANCE:
		return "footstep provenance mismatch"
	if not FileAccess.file_exists(FOOTSTEP_PATH):
		return "footstep production WAV missing"
	var footstep_stream := load(FOOTSTEP_PATH) as AudioStreamWAV
	if footstep_stream == null or footstep_stream.data.is_empty():
		return "footstep production WAV failed to load"
	if footstep_stream.format != AudioStreamWAV.FORMAT_16_BITS or footstep_stream.stereo:
		return "footstep must remain mono PCM16"
	if footstep_stream.mix_rate != 17000:
		return "footstep native sample rate changed"
	if absf(footstep_stream.get_length() - 0.1655) > 0.01:
		return "footstep duration mismatch"

	var transient_cache: Dictionary = manager.get("_production_transient_streams")
	if not transient_cache.has(AudioManagerScript.SoundEvent.FOOTSTEP):
		return "footstep was not loaded into production transient cache"
	if transient_cache[AudioManagerScript.SoundEvent.FOOTSTEP] != footstep_stream:
		return "footstep production cache stream mismatch"

	manager.call("reset_audio_instant")
	var footstep_pos := Vector3(5.0, 0.25, -3.0)
	manager.call("play_event", AudioManagerScript.SoundEvent.FOOTSTEP, footstep_pos)
	var active: Array = manager.get("_active_transients")
	if active.is_empty():
		return "production footstep did not create 3D transient"
	var footstep_player := active[-1] as AudioStreamPlayer3D
	if footstep_player == null or footstep_player.stream != footstep_stream:
		return "production footstep did not use selected stream"
	if footstep_player.global_position.distance_to(footstep_pos) > 0.01:
		return "production footstep lost supplied world position"
	if absf(footstep_player.unit_size - 8.0) > 0.01:
		return "production footstep unit_size must remain 8"
	if footstep_player.max_distance != 0.0:
		return "production footstep introduced unauthorized max_distance"

	manager.call("reset_audio_instant")
	var saved_footstep: AudioStream = transient_cache[AudioManagerScript.SoundEvent.FOOTSTEP]
	transient_cache.erase(AudioManagerScript.SoundEvent.FOOTSTEP)
	manager.set("_production_transient_streams", transient_cache)
	manager.call("play_event", AudioManagerScript.SoundEvent.FOOTSTEP, footstep_pos)
	active = manager.get("_active_transients")
	if active.is_empty():
		return "footstep procedural fallback is unreachable"
	var fallback_player := active[-1] as AudioStreamPlayer3D
	if fallback_player == null or fallback_player.stream == footstep_stream:
		return "footstep fallback did not replace production stream"
	if absf(fallback_player.stream.get_length() - 0.04) > 0.01:
		return "footstep fallback duration changed"
	if absf(fallback_player.unit_size - 8.0) > 0.01:
		return "footstep fallback unit_size changed"
	transient_cache[AudioManagerScript.SoundEvent.FOOTSTEP] = saved_footstep
	manager.set("_production_transient_streams", transient_cache)

	# The footstep fallback proof intentionally exercises reset_audio_instant(),
	# which synchronously stops the persistent Wind player. Re-arm it explicitly
	# before Wind assertions so this synchronous contract does not depend on the
	# deferred post-reset lifecycle callback getting a main-loop turn.
	manager.call("start_ambient_wind")

	# Wind registry/runtime authority.
	var wind_slot: Dictionary = AudioRegistryScript.get_slot("world.ambient_wind")
	if wind_slot.is_empty():
		return "world.ambient_wind slot missing"
	if wind_slot.get("domain") != AudioRegistryScript.Domain.WORLD:
		return "wind domain changed"
	if wind_slot.get("spatial_type") != AudioRegistryScript.SpatialType.NON_DIEGETIC_2D:
		return "wind must remain non-spatial 2D"
	if wind_slot.get("mix_group") != AudioRegistryScript.MixGroup.AMBIENT_TEXTURE:
		return "wind mix group changed"
	if wind_slot.get("playback_type") != AudioRegistryScript.PlaybackType.CONTINUOUS_LOOP:
		return "wind must remain CONTINUOUS_LOOP"
	if not bool(wind_slot.get("is_looping", false)):
		return "wind must remain loop-enabled"
	if absf(float(wind_slot.get("loop_end_sec", 0.0)) - 4.4999) > 0.01:
		return "wind loop metadata must align to selected source"
	if wind_slot.get("asset_status") != AudioRegistryScript.AssetStatus.LICENSED_FINAL:
		return "wind must be production-final"
	if wind_slot.get("replacement_required") != false:
		return "wind must clear replacement_required"
	if AudioRegistryScript.get_production_asset_path("world.ambient_wind") != WIND_PATH:
		return "wind production path mismatch"
	if AudioRegistryScript.get_source_provenance("world.ambient_wind") != WIND_PROVENANCE:
		return "wind provenance mismatch"
	if AudioManagerScript.EVENT_TO_SLOT_MAP.values().has("world.ambient_wind"):
		return "wind must not gain a SoundEvent mapping"
	if not FileAccess.file_exists(WIND_PATH):
		return "wind production WAV missing"
	var wind_stream := load(WIND_PATH) as AudioStreamWAV
	if wind_stream == null or wind_stream.data.is_empty():
		return "wind production WAV failed to load"
	if wind_stream.format != AudioStreamWAV.FORMAT_16_BITS or wind_stream.stereo:
		return "wind must remain mono PCM16"
	if wind_stream.mix_rate != 23300:
		return "wind native sample rate changed"
	if absf(wind_stream.get_length() - 4.4999) > 0.01:
		return "wind duration mismatch"
	if wind_stream.loop_mode != AudioStreamWAV.LOOP_FORWARD:
		return "wind stream must be forward-loop enabled"

	var wind_player := manager.get("_ambient_wind_player") as AudioStreamPlayer
	if wind_player == null:
		return "AmbientWindPlayer missing"
	if wind_player.name != "AmbientWindPlayer":
		return "wind player name changed"
	if wind_player.stream != wind_stream:
		return "wind player stream mismatch"
	if StringName(wind_player.bus) != &"Master":
		return "wind player must route to Master"
	if not wind_player.playing:
		return "wind player must start when production media is available"
	if absf(wind_player.volume_db - -18.0) > 0.01:
		return "wind calm level must be -18 dB"

	manager.call("set_mix_state", AudioManagerScript.MixState.DISTURBANCE)
	if not wind_player.playing or absf(wind_player.volume_db - -30.0) > 0.01:
		return "wind must remain playing at -30 dB during DISTURBANCE"
	manager.call("set_mix_state", AudioManagerScript.MixState.PURSUIT_PRESSURE)
	if not wind_player.playing or absf(wind_player.volume_db - -30.0) > 0.01:
		return "wind must remain playing at -30 dB during PURSUIT_PRESSURE"
	manager.call("set_mix_state", AudioManagerScript.MixState.MEMORY_ECHO)
	if not wind_player.playing or absf(wind_player.volume_db - -30.0) > 0.01:
		return "wind must remain playing at -30 dB during MEMORY_ECHO"
	manager.call("set_mix_state", AudioManagerScript.MixState.CALM)
	if not wind_player.playing or absf(wind_player.volume_db - -18.0) > 0.01:
		return "wind must restore -18 dB in CALM"

	manager.call("reset_audio_instant")
	if wind_player.playing:
		return "direct reset must stop ambient wind"
	manager.call("start_ambient_wind")
	if not wind_player.playing:
		return "explicit wind restart failed after reset"
	if absf(wind_player.volume_db - -18.0) > 0.01:
		return "wind restart after reset must use CALM level"
	var wind_player_id := wind_player.get_instance_id()
	manager.call("start_ambient_wind")
	if manager.get("_ambient_wind_player").get_instance_id() != wind_player_id:
		return "wind restart created duplicate player authority"

	# Chatter remains retention-only.
	var chatter_slot: Dictionary = AudioRegistryScript.get_slot(CHATTER_SLOT)
	if chatter_slot.is_empty():
		return "world.radio_chatter slot missing"
	if chatter_slot.get("asset_status") != AudioRegistryScript.AssetStatus.PROCEDURAL_FALLBACK:
		return "radio chatter must remain procedural/retention-only"
	if chatter_slot.get("replacement_required") != true:
		return "radio chatter must remain replacement-required"
	if not AudioRegistryScript.get_production_asset_path(CHATTER_SLOT).is_empty():
		return "radio chatter must not gain production path"
	if not AudioRegistryScript.get_source_provenance(CHATTER_SLOT).is_empty():
		return "radio chatter must not gain production provenance"
	if AudioManagerScript.EVENT_TO_SLOT_MAP.values().has(CHATTER_SLOT):
		return "radio chatter must not gain AudioManager event mapping"

	manager.call("reset_audio_instant")
	return ""
