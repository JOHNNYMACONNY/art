extends SceneTree

# Audio Production 02: exact checked-out Godot debug-loader proof.
# Only tests opt-in reference resolution. It does not listen, approve, or ship sounds.
const Resolver = preload("res://scripts/audio/audio_reference_resolver.gd")

const PILOT_IDS = [
    "player.footstep",
    "interaction.panel_peel",
    "vehicle.collision_glance",
    "vehicle.engine_rev",
    "ui.nav_confirm",
]

func _init() -> void:
    call_deferred("_run")


func _run() -> void:
    var manifest_path: String = OS.get_environment("ECHOES_REFERENCE_AUDIO_MANIFEST")
    assert(not manifest_path.is_empty(), "Explicit debug pilot manifest must be provided")
    assert(FileAccess.file_exists(manifest_path), "Debug pilot manifest missing")

    # Strict fail-closed default, even if a real candidate manifest exists.
    OS.set_environment("ECHOES_ALLOW_LOCAL_REFERENCE_AUDIO", "")
    Resolver.reset()
    assert(not Resolver.is_reference_enabled(), "Local override enabled without opt-in")
    assert(Resolver.resolve_stream("player.footstep") == null, "Unapproved audio loaded without opt-in")

    OS.set_environment("ECHOES_ALLOW_LOCAL_REFERENCE_AUDIO", "1")
    Resolver.reset()
    assert(Resolver.is_reference_enabled(), "Godot debug opt-in unavailable")
    for slot_id in PILOT_IDS:
        var sound: AudioStreamWAV = Resolver.resolve_stream(slot_id)
        assert(sound != null, "Debug WAV did not resolve for " + slot_id)
        assert(not sound.data.is_empty(), "Debug WAV resolved empty for " + slot_id)

    # Slots without recorded candidates must retain their ordinary procedural path.
    assert(Resolver.resolve_stream("pursuit.siren_alarm") == null, "Non-candidate unexpectedly replaced")
    assert(Resolver.resolve_stream("echo.radio_interference") == null, "Non-candidate unexpectedly replaced")

    OS.set_environment("ECHOES_ALLOW_LOCAL_REFERENCE_AUDIO", "")
    Resolver.reset()
    assert(Resolver.resolve_stream("ui.nav_confirm") == null, "Reset did not fail closed")
    print("AUDIO02_DEBUG_REFERENCE_PROOF_PASS: 5 opt-in streams; 2 fallbacks; reset closed")
    quit(0)
