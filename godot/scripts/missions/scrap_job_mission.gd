extends RefCounted

## Mission / Narrative 01
##
## Deliberately narrow authored state for the first complete scrap-job crime loop.
## This is not a general mission framework: the runtime adapter translates the
## existing golden-slice systems into these authored beats.

enum Phase {
	BRIEFING,
	GET_BIKE,
	TRAVERSE_TO_TUNER,
	SPOOF_SIGNAL,
	EXTRACT_CORE,
	PURSUIT_COMPLICATION,
	ROUTE_DECISION,
	ESCAPE,
	FAILED,
	COMPLETE,
}

enum RouteChoice {
	UNDECIDED,
	SIGNAL_GATE,
	LONG_ROAD,
}

const PAYOFF_CREDITS := 320

var phase: Phase = Phase.BRIEFING
var route_choice: RouteChoice = RouteChoice.UNDECIDED
var objective: String = ""
var contact_line: String = ""
var reward_credits: int = 0
var failure_count: int = 0
var _started: bool = false

func start() -> bool:
	if _started or phase != Phase.BRIEFING:
		return false
	_started = true
	phase = Phase.GET_BIKE
	objective = "OBJECTIVE // GET THE COURIER BIKE"
	contact_line = "LIRA // Yard auditors tagged a customs core for recycling. Recycling means us. Take the bike, lift the core, lose the invoice."
	return true

func on_courier_bike_mounted() -> bool:
	if phase != Phase.GET_BIKE:
		return false
	phase = Phase.TRAVERSE_TO_TUNER
	objective = "OBJECTIVE // RIDE TO THE TUNER MAST"
	contact_line = "LIRA // Keep it ordinary. Nothing alarms a yard like someone driving responsibly."
	return true

func on_tuner_arrived() -> bool:
	if phase != Phase.TRAVERSE_TO_TUNER:
		return false
	phase = Phase.SPOOF_SIGNAL
	objective = "OBJECTIVE // DISMOUNT // SPOOF THE YARD SIGNAL"
	contact_line = "LIRA // Their lock trusts a frequency more than a person. Be the frequency."
	return true

func on_signal_locked() -> bool:
	if phase != Phase.SPOOF_SIGNAL:
		return false
	phase = Phase.EXTRACT_CORE
	objective = "OBJECTIVE // PULL THE CUSTOMS CORE"
	contact_line = "LIRA // Good. The city sold the same lock twice. You are paying once."
	return true

func on_core_extracted() -> bool:
	if phase != Phase.EXTRACT_CORE:
		return false
	phase = Phase.PURSUIT_COMPLICATION
	objective = "OBJECTIVE // MOVE // YARD RESPONSE INBOUND"
	contact_line = "LIRA // Core is hot. Apparently municipal property gets sentimental after theft."
	return true

func on_pursuit_active() -> bool:
	if phase != Phase.PURSUIT_COMPLICATION:
		return false
	phase = Phase.ROUTE_DECISION
	objective = "OBJECTIVE // LOSE THE PURSUER // SIGNAL GATE OR LONG ROAD"
	contact_line = "LIRA // Gate or long road. Pick which lie you can drive faster."
	return true

func on_gate_triggered() -> bool:
	if phase != Phase.ROUTE_DECISION and phase != Phase.ESCAPE:
		return false
	route_choice = RouteChoice.SIGNAL_GATE
	phase = Phase.ESCAPE
	objective = "OBJECTIVE // CUT THE SHORTCUT // BREAK CONTACT"
	contact_line = "LIRA // Gate is committed. So are you, legally speaking."
	return true

func on_intercepted() -> bool:
	if phase not in [Phase.PURSUIT_COMPLICATION, Phase.ROUTE_DECISION, Phase.ESCAPE]:
		return false
	failure_count += 1
	reward_credits = 0
	phase = Phase.FAILED
	objective = "JOB BURNED // RETRY PURSUIT"
	contact_line = "LIRA // The city found its paperwork. Try not to be in it next time."
	return true

func on_retry_started() -> bool:
	if phase != Phase.FAILED:
		return false
	route_choice = RouteChoice.UNDECIDED
	phase = Phase.ROUTE_DECISION
	objective = "OBJECTIVE // LOSE THE PURSUER // SIGNAL GATE OR LONG ROAD"
	contact_line = "LIRA // Solved setup stays solved. Get gone."
	return true

func on_escape_complete() -> bool:
	if phase != Phase.ROUTE_DECISION and phase != Phase.ESCAPE:
		return false
	if route_choice == RouteChoice.UNDECIDED:
		route_choice = RouteChoice.LONG_ROAD
	phase = Phase.COMPLETE
	reward_credits = PAYOFF_CREDITS
	objective = "JOB COMPLETE // %d SCRAP CREDITS CLEARED" % PAYOFF_CREDITS
	if route_choice == RouteChoice.SIGNAL_GATE:
		contact_line = "LIRA // Core received. Municipal loss report says 'weather.' Beautiful paperwork."
	else:
		contact_line = "LIRA // Core received. Municipal loss report says 'routing delay.' Even the long road has paperwork."
	return true

func snapshot() -> Dictionary:
	return {
		"phase": phase,
		"route_choice": route_choice,
		"objective": objective,
		"contact_line": contact_line,
		"reward_credits": reward_credits,
		"failure_count": failure_count,
	}
