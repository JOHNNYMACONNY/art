class_name MemoryEchoController
extends Node

## Echos in the Scrap — M04 Memory Echo Controller
## State machine for the extraction Echo reveal sequence.
## Arc: IDLE → ONSET → PEAK → RELEASE → DONE
## Total window: ~1.8–2.0s. Player retains movement control throughout.
##
## Canon safety (04.3): content payload is deliberately fragmentary and
## tagged PROPOSED. No lore facts, names, factions, or timeline committed.
## Placeholder implementation names must not become canon by accident.

# ─────────────────────────────────────────────────────────────────────────────
# Data boundary (04.2): local/runtime only — no Nostr, AI, networking, persistence.
# ─────────────────────────────────────────────────────────────────────────────

class EchoData:
	var echo_id: String = ""
	var action: String = ""
	var zone: String = ""
	var intensity: float = 0.0
	var mission_ref: String = ""
	var content: String = ""

	func _init(p_id: String, p_action: String, p_zone: String,
			p_intensity: float, p_mission: String, p_content: String) -> void:
		echo_id = p_id
		action = p_action
		zone = p_zone
		intensity = p_intensity
		mission_ref = p_mission
		content = p_content

## First slice echo: deliberately abstract signal fragment, explicitly PROPOSED.
## No committed narrative, dates, names, or factions.
const FIRST_ECHO_DATA := {
	"echo_id": "echo_v8_m04_00",
	"action": "core_extraction",
	"zone": "scrap_sector", # [PROPOSED] provisional label, not canon
	"intensity": 0.85,
	"mission_ref": "", # External mission ingestion out of scope (04.2)
	"content": "[PROPOSED] signal // fragment 0x--- // memory location unknown // do not retransmit"
}

# ─────────────────────────────────────────────────────────────────────────────
# Phase state machine
# ─────────────────────────────────────────────────────────────────────────────

enum EchoPhase {
	IDLE,
	ONSET,    # 0.28s — electrical crackle opens the window
	PEAK,     # 1.10s — fractured signal ghost
	RELEASE,  # 0.45s — electrical tail, dropout to silence
	DONE
}

signal echo_phase_changed(phase: EchoPhase)
signal echo_completed

var current_phase: EchoPhase = EchoPhase.IDLE
var _echo_data: EchoData = null
var _triggered_count: int = 0  # Counts lifetime triggers for replay re-arm check
var _phase_timer: float = 0.0

# Phase durations (seconds)
const ONSET_DURATION := 0.28
const PEAK_DURATION   := 1.10
const RELEASE_DURATION := 0.45

var _audio_mgr: AudioManager = null

# ─────────────────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────────────────

## Called once per scene init to inject audio manager reference
func setup(audio_manager: AudioManager) -> void:
	_audio_mgr = audio_manager

## Trigger the echo sequence. Safe to call only from IDLE/DONE.
## Returns false if echo was not in a triggerable state (guards extraction-once semantics).
func trigger_echo() -> bool:
	if current_phase != EchoPhase.IDLE and current_phase != EchoPhase.DONE:
		return false
	_echo_data = _build_first_echo()
	_triggered_count += 1
	print("[ECHO] Memory Echo triggered (count: %d, id: %s)" % [_triggered_count, _echo_data.echo_id])
	_enter_onset()
	return true

## Returns true if the echo has ever been triggered and has since completed.
## Used by replay re-arm logic.
func has_completed() -> bool:
	return current_phase == EchoPhase.DONE

## Returns total lifetime trigger count (for once-per-replay assertion).
func get_trigger_count() -> int:
	return _triggered_count

## Authoritative reset: kills all timers, stops echo audio, returns to IDLE.
## Must be called by reset_scene() to guarantee no state leakage.
func reset_echo() -> void:
	_phase_timer = 0.0
	# Stop echo voice in audio manager
	if _audio_mgr and _audio_mgr._echo_voice:
		_audio_mgr._echo_voice.stop()
	current_phase = EchoPhase.IDLE
	_triggered_count = 0
	_echo_data = null
	print("[ECHO] Echo reset to IDLE")

# ─────────────────────────────────────────────────────────────────────────────
# Process tick
# ─────────────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if current_phase == EchoPhase.IDLE or current_phase == EchoPhase.DONE:
		return
	
	_phase_timer -= delta
	if _phase_timer <= 0.0:
		match current_phase:
			EchoPhase.ONSET:
				_enter_peak()
			EchoPhase.PEAK:
				_enter_release()
			EchoPhase.RELEASE:
				_on_release_complete()

# ─────────────────────────────────────────────────────────────────────────────
# Internal phase transitions
# ─────────────────────────────────────────────────────────────────────────────

func _build_first_echo() -> EchoData:
	var d := EchoData.new(
		FIRST_ECHO_DATA["echo_id"],
		FIRST_ECHO_DATA["action"],
		FIRST_ECHO_DATA["zone"],
		FIRST_ECHO_DATA["intensity"],
		FIRST_ECHO_DATA["mission_ref"],
		FIRST_ECHO_DATA["content"]
	)
	return d

func _enter_onset() -> void:
	current_phase = EchoPhase.ONSET
	_phase_timer = ONSET_DURATION
	echo_phase_changed.emit(EchoPhase.ONSET)
	# Audio: set MEMORY_ECHO mix state, which plays ECHO_ONSET via set_mix_state
	if _audio_mgr:
		_audio_mgr.set_mix_state(AudioManager.MixState.MEMORY_ECHO)

func _enter_peak() -> void:
	current_phase = EchoPhase.PEAK
	_phase_timer = PEAK_DURATION
	echo_phase_changed.emit(EchoPhase.PEAK)
	if _audio_mgr:
		_audio_mgr.play_event(AudioManager.SoundEvent.ECHO_PEAK, Vector3.ZERO)

func _enter_release() -> void:
	current_phase = EchoPhase.RELEASE
	_phase_timer = RELEASE_DURATION
	echo_phase_changed.emit(EchoPhase.RELEASE)
	if _audio_mgr:
		_audio_mgr.play_event(AudioManager.SoundEvent.ECHO_TAIL, Vector3.ZERO)

func _on_release_complete() -> void:
	current_phase = EchoPhase.DONE
	_phase_timer = 0.0
	echo_phase_changed.emit(EchoPhase.DONE)
	echo_completed.emit()
	print("[ECHO] Memory Echo complete — disturbance authorized")
