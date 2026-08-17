class_name MemoryEchoController
extends Node

## Echos in the Scrap — M04A Memory Echo Controller
## State machine for the extraction Echo reveal sequence.
## Arc: IDLE → ONSET → PEAK → RELEASE → DONE
## Total window: ~1.83s. Player retains movement control throughout.
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
	ONSET,    # 0.28s — electrical crackle opens window + exposure flash
	PEAK,     # 1.10s — fractured signal ghost + glitch overlay + fragment text
	RELEASE,  # 0.45s — electrical tail, dropout to silence + alpha dissolve
	DONE
}

signal echo_phase_changed(phase: EchoPhase)
signal echo_completed

var current_phase: EchoPhase = EchoPhase.IDLE
var is_armed_for_extraction: bool = false
var _echo_data: EchoData = null
var _triggered_count: int = 0  # Counts lifetime triggers for replay re-arm check
var _phase_timer: float = 0.0

# Phase durations (seconds)
const ONSET_DURATION := 0.28
const PEAK_DURATION   := 1.10
const RELEASE_DURATION := 0.45

var _audio_mgr: AudioManager = null

# ─────────────────────────────────────────────────────────────────────────────
# Procedural Visual Overlay Nodes (04.1 / M04A)
# ─────────────────────────────────────────────────────────────────────────────

var _canvas_layer: CanvasLayer = null
var _flash_rect: ColorRect = null
var _text_container: PanelContainer = null
var _text_label: Label = null

func _ready() -> void:
	_setup_visual_overlay()

func _setup_visual_overlay() -> void:
	if _canvas_layer:
		return
	
	_canvas_layer = CanvasLayer.new()
	_canvas_layer.layer = 12
	_canvas_layer.visible = false
	add_child(_canvas_layer)
	
	# Full-screen exposure flash and chromatic scanline filter
	_flash_rect = ColorRect.new()
	_flash_rect.name = "EchoFlashRect"
	_flash_rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	_flash_rect.color = Color(0.1, 0.8, 1.0, 0.0)
	_flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_canvas_layer.add_child(_flash_rect)
	
	# Terminal HUD Fragment Text Container
	_text_container = PanelContainer.new()
	_text_container.name = "EchoTextContainer"
	_text_container.set_anchors_preset(Control.PRESET_CENTER_TOP)
	_text_container.offset_top = 80.0
	_text_container.offset_left = -320.0
	_text_container.offset_right = 320.0
	_text_container.offset_bottom = 150.0
	_text_container.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text_container.modulate.a = 0.0
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.02, 0.04, 0.08, 0.85)
	style.border_color = Color(0.2, 0.85, 1.0, 0.9)
	style.set_border_width_all(2)
	style.set_corner_radius_all(4)
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.content_margin_top = 10.0
	style.content_margin_bottom = 10.0
	_text_container.add_theme_stylebox_override("panel", style)
	_canvas_layer.add_child(_text_container)
	
	_text_label = Label.new()
	_text_label.name = "EchoTextLabel"
	_text_label.text = ""
	_text_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_text_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_text_label.add_theme_color_override("font_color", Color(0.4, 0.95, 1.0, 1.0))
	_text_label.add_theme_font_size_override("font_size", 14)
	_text_container.add_child(_text_label)

# ─────────────────────────────────────────────────────────────────────────────
# Public API
# ─────────────────────────────────────────────────────────────────────────────

## Called once per scene init to inject audio manager reference
func setup(audio_manager: AudioManager) -> void:
	_audio_mgr = audio_manager

## Explicitly arms controller for legitimate core extraction trigger (M04A trigger-gate)
func arm_for_extraction() -> void:
	is_armed_for_extraction = true

## Trigger the echo sequence. Strictly requires extraction arming (fails closed if un-armed).
## Returns false if un-armed or not in IDLE/DONE state.
func trigger_echo() -> bool:
	if not is_armed_for_extraction:
		print("[ECHO] trigger_echo rejected: controller not armed for extraction")
		return false
	if current_phase != EchoPhase.IDLE and current_phase != EchoPhase.DONE:
		print("[ECHO] trigger_echo rejected: phase is %s (not IDLE/DONE)" % EchoPhase.keys()[current_phase])
		return false
		
	# Consume arming token immediately to prevent duplicate triggering
	is_armed_for_extraction = false
	_echo_data = _build_first_echo()
	_triggered_count += 1
	print("[ECHO] Memory Echo triggered (count: %d, id: %s)" % [_triggered_count, _echo_data.echo_id])
	_enter_onset()
	return true

## Returns true if the echo has ever been triggered and has since completed.
func has_completed() -> bool:
	return current_phase == EchoPhase.DONE

## Returns total lifetime trigger count (for once-per-replay assertion).
func get_trigger_count() -> int:
	return _triggered_count

## Authoritative reset: halts voices, purges overlay, disarms, returns to IDLE.
## Must be called by reset_scene() to guarantee zero state/visual leakage.
func reset_echo() -> void:
	_phase_timer = 0.0
	is_armed_for_extraction = false
	current_phase = EchoPhase.IDLE
	_triggered_count = 0
	_echo_data = null
	
	# Stop echo voice in audio manager
	if _audio_mgr and _audio_mgr._echo_voice:
		_audio_mgr._echo_voice.stop()
		
	# Cleanly hide and reset visual overlay
	if _canvas_layer:
		_canvas_layer.visible = false
	if _flash_rect:
		_flash_rect.color = Color(0.1, 0.8, 1.0, 0.0)
		_flash_rect.modulate.a = 0.0
	if _text_container:
		_text_container.modulate.a = 0.0
	if _text_label:
		_text_label.text = ""
		
	print("[ECHO] Echo reset to IDLE cleanly (overlay purged)")

# ─────────────────────────────────────────────────────────────────────────────
# Process tick
# ─────────────────────────────────────────────────────────────────────────────

func _process(delta: float) -> void:
	if current_phase == EchoPhase.IDLE or current_phase == EchoPhase.DONE:
		return
	
	_phase_timer -= delta
	
	# Handle continuous visual transitions
	if current_phase == EchoPhase.RELEASE:
		# Smoothly dissolve overlay to 0.0 alpha
		var norm_release: float = clampf(_phase_timer / maxf(RELEASE_DURATION, 0.01), 0.0, 1.0)
		if _flash_rect:
			_flash_rect.modulate.a = norm_release * 0.4
		if _text_container:
			_text_container.modulate.a = norm_release
	
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
	
	# Visual: initial electrical crackle exposure flash
	if _canvas_layer:
		_canvas_layer.visible = true
	if _flash_rect:
		_flash_rect.color = Color(0.15, 0.85, 1.0, 0.4)
		_flash_rect.modulate.a = 1.0
	if _text_container:
		_text_container.modulate.a = 0.0
	if _text_label:
		_text_label.text = ""
		
	echo_phase_changed.emit(EchoPhase.ONSET)
	if _audio_mgr:
		_audio_mgr.set_mix_state(AudioManager.MixState.MEMORY_ECHO)

func _enter_peak() -> void:
	current_phase = EchoPhase.PEAK
	_phase_timer = PEAK_DURATION
	
	# Visual: fractured signal ghost overlay + glowing fragment text
	if _flash_rect:
		_flash_rect.color = Color(0.05, 0.25, 0.5, 0.2)
		_flash_rect.modulate.a = 0.85
	if _text_container:
		_text_container.modulate.a = 1.0
	if _text_label and _echo_data:
		_text_label.text = _echo_data.content
		
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
	
	# Visual: completely hidden before disturbance takes over
	if _canvas_layer:
		_canvas_layer.visible = false
	if _flash_rect:
		_flash_rect.modulate.a = 0.0
	if _text_container:
		_text_container.modulate.a = 0.0
	if _text_label:
		_text_label.text = ""
		
	echo_phase_changed.emit(EchoPhase.DONE)
	echo_completed.emit()
	print("[ECHO] Memory Echo complete — disturbance authorized")
