extends RefCounted

## Mission / Narrative 03 — The City That Forgot
##
## A bounded authored follow-on chapter. This remains specific product content,
## not a generalized mission/quest framework.

enum Phase {
	LOCKED,
	REACH_SILENT_CORE,
	ECHO_ACTIVE,
	ESCAPE,
	FAILED,
	COMPLETE,
}

enum AftermathState {
	UNDECIDED,
	RELEASED,
	SEALED,
}

var phase: Phase = Phase.LOCKED
var aftermath_state: AftermathState = AftermathState.UNDECIDED
var objective: String = ""
var contact_line: String = ""
var reward_credits: int = 0
var failure_count: int = 0

func unlock_after_civic_repossession() -> bool:
	if phase != Phase.LOCKED:
		return false
	phase = Phase.REACH_SILENT_CORE
	objective = "OBJECTIVE // REACH THE SILENT CORE"
	contact_line = "SISTER KAEL // HS-7 keeps a memory the city paid to lose. Bring it to the Core and listen before somebody remembers the receipt."
	return true

func on_silent_core_activated() -> bool:
	if phase != Phase.REACH_SILENT_CORE:
		return false
	phase = Phase.ECHO_ACTIVE
	objective = "OBJECTIVE // HOLD THE SIGNAL // HS-7 MEMORY ECHO"
	contact_line = "SISTER KAEL // Let it speak. Do not help it make the story prettier."
	return true

func on_echo_completed() -> bool:
	if phase != Phase.ECHO_ACTIVE:
		return false
	phase = Phase.ESCAPE
	objective = "OBJECTIVE // ESCAPE // BREAK CONTACT"
	contact_line = "SISTER KAEL // They heard it too. Leave the shrine before memory becomes evidence."
	return true

func on_intercepted() -> bool:
	if phase != Phase.ESCAPE:
		return false
	failure_count += 1
	phase = Phase.FAILED
	objective = "JOB BURNED // RETRY PURSUIT"
	contact_line = "SISTER KAEL // The city caught the witness. Fortunately, witnesses are repetitive."
	return true

func on_retry_started() -> bool:
	if phase != Phase.FAILED:
		return false
	phase = Phase.ESCAPE
	objective = "OBJECTIVE // ESCAPE // BREAK CONTACT"
	contact_line = "SISTER KAEL // Same memory. Same exit. Fewer mistakes."
	return true

func on_escape_complete() -> bool:
	if phase != Phase.ESCAPE:
		return false
	phase = Phase.COMPLETE
	reward_credits = 0
	objective = "THE CITY THAT FORGOT COMPLETE // RETURN TO CORE // CHOOSE MEMORY FATE"
	contact_line = "SISTER KAEL // You heard what they buried. Bring HS-7 back to the Core. Decide what deserves daylight."
	return true

func choose_memory_release() -> bool:
	if phase != Phase.COMPLETE or aftermath_state != AftermathState.UNDECIDED:
		return false
	aftermath_state = AftermathState.RELEASED
	objective = "AFTERMATH // ARCHIVE RELEASED // BREAK CIVIC CONTACT"
	contact_line = "SISTER KAEL // Daylight, then. The city can explain its own shadow."
	return true

func choose_memory_seal() -> bool:
	if phase != Phase.COMPLETE or aftermath_state != AftermathState.UNDECIDED:
		return false
	aftermath_state = AftermathState.SEALED
	objective = "AFTERMATH // ARCHIVE SEALED // LOCAL COPY RETAINED"
	contact_line = "SISTER KAEL // Keep it close. A buried truth is still a truth. It just charges rent."
	return true

func get_aftermath_state_name() -> String:
	return AftermathState.keys()[aftermath_state]

func snapshot() -> Dictionary:
	return {
		"phase": phase,
		"aftermath_state": aftermath_state,
		"aftermath_state_name": get_aftermath_state_name(),
		"objective": objective,
		"contact_line": contact_line,
		"reward_credits": reward_credits,
		"failure_count": failure_count,
	}
