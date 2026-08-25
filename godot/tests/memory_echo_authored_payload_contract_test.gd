extends RefCounted

const ECHO_PATH := "res://scripts/prototype/memory_echo_controller.gd"

static func verify() -> String:
	var echo_script = load(ECHO_PATH)
	if echo_script == null:
		return "Memory Echo controller is missing"

	var controller = echo_script.new()
	if not controller.has_method("trigger_authored_echo"):
		return "Memory Echo controller does not expose the bounded authored-payload trigger"
	if not controller.has_method("prepare_next_echo"):
		return "Memory Echo controller lacks a non-replay way to prepare a completed Echo for the next authored beat"

	# Existing Mission 01 extraction boundary must remain fail-closed and unchanged.
	if controller.trigger_echo():
		return "Unarmed extraction Echo unexpectedly triggered"
	controller.arm_for_extraction()
	if not controller.trigger_echo():
		return "Armed extraction Echo no longer triggers"
	if controller.get_trigger_count() != 1:
		return "Extraction Echo trigger accounting changed"
	if controller.get("_echo_data") == null:
		return "Extraction Echo did not retain its data"
	if controller.get("_echo_data").content != echo_script.FIRST_ECHO_DATA["content"]:
		return "Extraction Echo no longer uses FIRST_ECHO_DATA"

	# Complete the first Echo and prepare the retained controller for a later
	# authored beat without invoking the authoritative Full Replay reset.
	controller.call("_process", 1.0)
	controller.call("_process", 2.0)
	controller.call("_process", 1.0)
	if controller.current_phase != echo_script.EchoPhase.DONE:
		return "Extraction Echo fixture did not reach DONE"
	if not controller.prepare_next_echo():
		return "Completed extraction Echo could not prepare for the next authored Echo"
	if controller.current_phase != echo_script.EchoPhase.IDLE:
		return "prepare_next_echo did not return the retained lifecycle to IDLE"
	if controller.get_trigger_count() != 1:
		return "Preparing a later Echo erased cumulative trigger accounting"
	if controller.get("_echo_data") != null:
		return "Preparing a later Echo leaked the previous payload"

	var authored_payload := {
		"echo_id": "mission03_silent_core",
		"action": "silent_core_resonance",
		"zone": "silent_core_shrine",
		"intensity": 0.95,
		"mission_ref": "mission_03_city_that_forgot",
		"content": "[HS-7] ECHOTEL // archive fragment // civic deletion order recovered // integrity unstable",
	}
	if not controller.trigger_authored_echo(authored_payload):
		return "Valid Mission 03 authored Echo payload was rejected"
	if controller.current_phase != echo_script.EchoPhase.ONSET:
		return "Authored Echo did not enter retained ONSET phase"
	if controller.get_trigger_count() != 2:
		return "Authored Echo did not preserve cumulative retained trigger accounting"
	var data = controller.get("_echo_data")
	if data == null or data.echo_id != authored_payload["echo_id"]:
		return "Authored Echo did not retain the supplied echo_id"
	if data.mission_ref != authored_payload["mission_ref"] or data.content != authored_payload["content"]:
		return "Authored Echo did not retain the supplied mission payload"
	if controller.trigger_authored_echo(authored_payload):
		return "Duplicate authored Echo triggered while retained lifecycle was active"
	if controller.get_trigger_count() != 2:
		return "Rejected duplicate authored Echo mutated trigger accounting"

	# Only the authoritative replay reset may erase cumulative trigger state.
	controller.reset_echo()
	if controller.current_phase != echo_script.EchoPhase.IDLE:
		return "Authored Echo reset did not return to IDLE"
	if controller.get_trigger_count() != 0 or controller.get("_echo_data") != null:
		return "Authoritative Echo reset leaked mission payload or trigger state"

	var incomplete_payload := authored_payload.duplicate()
	incomplete_payload.erase("content")
	if controller.trigger_authored_echo(incomplete_payload):
		return "Incomplete authored Echo payload did not fail closed"
	if controller.get_trigger_count() != 0:
		return "Rejected incomplete authored Echo mutated trigger accounting"

	return ""
