extends SceneTree

const MISSION_PATH := "res://scripts/missions/city_that_forgot_mission.gd"
const RELAY_PATH := "res://scripts/interactions/memory_disclosure_relay.gd"

func _init() -> void:
	call_deferred("_run")

func _fail(message: String) -> void:
	push_error("[P16_MEMORY_DISCLOSURE] %s" % message)
	quit(1)

func _run() -> void:
	var mission_script = load(MISSION_PATH)
	if mission_script == null:
		_fail("Mission 03 script missing")
		return
	var mission = mission_script.new()
	if not mission.unlock_after_civic_repossession() \
	or not mission.on_silent_core_activated() \
	or not mission.on_echo_completed() \
	or not mission.on_escape_complete():
		_fail("Retained Mission 03 path could not reach COMPLETE")
		return
	if not mission.has_method("get_aftermath_state_name"):
		_fail("Mission 03 has no bounded aftermath state")
		return
	if String(mission.call("get_aftermath_state_name")) != "UNDECIDED":
		_fail("Fresh Mission 03 aftermath is not UNDECIDED")
		return
	if not mission.has_method("choose_memory_release") or not mission.has_method("choose_memory_seal"):
		_fail("Mission 03 lacks RELEASE / SEAL choice API")
		return
	if not bool(mission.call("choose_memory_release")):
		_fail("RELEASE was rejected after Mission 03 COMPLETE")
		return
	if String(mission.call("get_aftermath_state_name")) != "RELEASED":
		_fail("RELEASE did not become RELEASED")
		return
	if bool(mission.call("choose_memory_release")) or bool(mission.call("choose_memory_seal")):
		_fail("Aftermath choice was not exactly-once")
		return
	var sealed = mission_script.new()
	sealed.unlock_after_civic_repossession()
	sealed.on_silent_core_activated()
	sealed.on_echo_completed()
	sealed.on_escape_complete()
	if not bool(sealed.call("choose_memory_seal")) \
	or String(sealed.call("get_aftermath_state_name")) != "SEALED":
		_fail("SEAL did not become SEALED")
		return
	var relay_script = load(RELAY_PATH)
	if relay_script == null:
		_fail("Memory disclosure relay implementation missing")
		return
	print("[P16_MEMORY_DISCLOSURE] PASS")
	quit(0)
