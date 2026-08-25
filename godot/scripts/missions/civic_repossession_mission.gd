extends RefCounted

## Mission / Narrative 02 — Civic Repossession
##
## A deliberately authored follow-on job. This remains a small product slice,
## not a generalized mission/quest framework.

enum Phase {
	LOCKED,
	GET_HAULER,
	ESCAPE,
	DELIVERY,
	FAILED,
	COMPLETE,
}

enum RouteChoice {
	UNDECIDED,
	SIGNAL_GATE,
	LONG_ROAD,
}

const PAYOFF_CREDITS := 450
const REQUIRED_VEHICLE_NAME := "ScrapHauler"

var phase: Phase = Phase.LOCKED
var route_choice: RouteChoice = RouteChoice.UNDECIDED
var objective: String = ""
var contact_line: String = ""
var reward_credits: int = 0
var failure_count: int = 0

func unlock_after_scrap_job() -> bool:
	if phase != Phase.LOCKED:
		return false
	phase = Phase.GET_HAULER
	objective = "OBJECTIVE // TAKE THE SCRAP HAULER"
	contact_line = "MAYOR BURN // City repossessed its own salvage truck. Very efficient. Bring me the paperwork with wheels."
	return true

func on_vehicle_mounted(vehicle_name: String) -> bool:
	if phase != Phase.GET_HAULER or vehicle_name != REQUIRED_VEHICLE_NAME:
		return false
	phase = Phase.ESCAPE
	objective = "OBJECTIVE // LOSE THE PURSUER // SIGNAL GATE OR LONG ROAD"
	contact_line = "MAYOR BURN // Excellent. You are now driving a municipal accounting error. Try not to itemize yourself."
	return true

func on_gate_triggered() -> bool:
	if phase != Phase.ESCAPE:
		return false
	route_choice = RouteChoice.SIGNAL_GATE
	objective = "OBJECTIVE // BREAK CONTACT // SIGNAL GATE COMMITTED"
	contact_line = "MAYOR BURN // Shortcut approved retroactively. That's how infrastructure works."
	return true

func on_intercepted() -> bool:
	if phase != Phase.ESCAPE:
		return false
	failure_count += 1
	reward_credits = 0
	phase = Phase.FAILED
	objective = "JOB BURNED // RETRY PURSUIT"
	contact_line = "MAYOR BURN // They recovered the public asset. Disgusting display of municipal competence."
	return true

func on_retry_started() -> bool:
	if phase != Phase.FAILED:
		return false
	route_choice = RouteChoice.UNDECIDED
	phase = Phase.ESCAPE
	objective = "OBJECTIVE // LOSE THE PURSUER // SIGNAL GATE OR LONG ROAD"
	contact_line = "MAYOR BURN // Same truck, same debt, fewer introductions. Move."
	return true

func on_evasion_complete() -> bool:
	if phase != Phase.ESCAPE:
		return false
	if route_choice == RouteChoice.UNDECIDED:
		route_choice = RouteChoice.LONG_ROAD
	phase = Phase.DELIVERY
	objective = "OBJECTIVE // RETURN THE SCRAP HAULER TO BURN'S GARAGE"
	contact_line = "MAYOR BURN // Heat is off. Garage is open. I filed the truck as 'temporarily democratic.'"
	return true

func on_return_zone_entered() -> bool:
	if phase != Phase.DELIVERY:
		return false
	phase = Phase.COMPLETE
	reward_credits = PAYOFF_CREDITS
	objective = "CIVIC REPOSSESSION COMPLETE // %d SCRAP CREDITS CLEARED" % PAYOFF_CREDITS
	contact_line = "MAYOR BURN // Municipal property restored to its natural owner: whoever got there first."
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
