# Burnside Production 07 — Gears Vehicle Condition / Burn Garage Repair Tracer

**Status:** `DESIGN_LOCKED__IMPLEMENTATION_AUTHORIZED`

**Authority:** issue #137, product anchor #55, Burnside Open-World Production Contract #118.

**Starting docs-only repository baseline:** `main@f04aeadebf208e1ba0f3cba0090638c67d468838`

**Exact retained Production-06 gameplay/public baseline:** `cfe82d2580a7300e3ebb2bf3257d08a4300bf2a4`

## Goal

Add the first bounded physical vehicle-consequence loop using only the retained Courier Bike, Scrap Hauler, real collision telemetry, and Mayor Burn's existing Garage.

Primary loop:

`DRIVE -> SIGNIFICANT IMPACTS -> BATTERED -> CRITICAL / LIMPING -> ABANDON, SWAP, OR REACH BURN'S GARAGE -> REPAIR -> ROADWORTHY`

Target feeling:

> “I wrecked this thing escaping the city, it was barely hanging together, and I had to decide whether to ditch it or limp through the shortcut I knew back to Burn.”

Production 07 proves vehicle condition + Garage repair only. It does not implement Claimed Vehicles, maintenance, ownership persistence, player/NPC Health, or a generalized damage framework.

## Scope boundary

Production 07 owns exactly:

- coarse condition for the existing `CourierBike`;
- coarse condition for the existing `ScrapHauler`;
- exactly three player-readable condition states: `ROADWORTHY`, `BATTERED`, `CRITICAL`;
- condition accumulation from each vehicle's existing real collision telemetry;
- a bounded sustained-contact debounce;
- one CRITICAL mechanical consequence: reduced usable forward maximum speed;
- restrained world-readable damaged-vehicle presentation;
- one Burn Garage repair runtime at the existing MissionDestinationSocket;
- read-only Wanted eligibility for repair;
- full-Replay condition reset;
- focused semantic/runtime/render/Web/regression evidence.

Production 07 does **not** own:

- Claimed Vehicle ownership, storage, recovery, customization, insurance, scarcity or title;
- vehicle ownership persistence;
- repair economy or prices;
- fuel, oil, tires, component damage, engine simulation, wheel loss, fire or explosions;
- a generic `Damageable`, Health, Armor, NPC death, hostile pedestrian combat AI, firearms or inventory;
- Heat 2–5, witnesses, surveillance, or changes to Wanted/Recognition/Report authority;
- generalized vehicle or save-system rewrites;
- new geography, second Garage, PR #44 camera work, companion navigation, or unrelated Audio changes.

## Existing implementation authority

The retained vehicle controllers remain authoritative for handling and collision response:

- `godot/scripts/vehicles/courier_bike.gd`
- `godot/scripts/vehicles/scrap_hauler.gd`

Both already emit:

```gdscript
collision_contact(head_on_ratio, impact_speed, collision_pos)
```

Production 07 consumes the same real collision values inside each vehicle controller before the neutral telemetry signal continues to existing Audio/verification consumers. Condition may never be inferred from Audio state or from a presentation event.

The retained handling models remain authoritative. P07 may alter only the usable **forward maximum speed** while a vehicle is CRITICAL. Steering logic continues to normalize against each vehicle's ordinary `max_speed`; reverse limits, acceleration, braking, grip, steering coefficients, handbrake behavior, mount/dismount rules and collision response remain unchanged.

## Vehicle condition model

Each production vehicle owns a small local condition state. Do not create a base class or generalized damage framework solely for P07.

Required public semantic seam in both vehicle scripts:

```gdscript
enum VehicleCondition {
    ROADWORTHY,
    BATTERED,
    CRITICAL,
}

signal condition_changed(condition_name: String)

func get_condition_name() -> String
func get_condition_load() -> float
func get_usable_max_speed() -> float
func apply_collision_condition(head_on_ratio: float, impact_speed: float) -> bool
func repair_condition() -> bool
func reset_condition() -> void
```

`get_condition_load()` is diagnostic/test introspection only. No numeric HP or load meter is exposed to the player.

### Initial tuning constants

Use one shared behavioral envelope in both controllers, duplicated locally rather than generalized prematurely:

```gdscript
const CONDITION_MIN_IMPACT_SPEED := 4.0
const CONDITION_CONTACT_COOLDOWN_SECONDS := 0.50
const CONDITION_BATTERED_LOAD := 0.75
const CONDITION_CRITICAL_LOAD := 1.50
const CONDITION_MAX_LOAD := 1.50
const CRITICAL_SPEED_MULTIPLIER := 0.52
```

The first candidate deterministic load function is:

```gdscript
if impact_speed < CONDITION_MIN_IMPACT_SPEED:
    return false
if _condition_contact_cooldown > 0.0:
    return false

var speed_severity := clampf((impact_speed - 3.5) / 7.5, 0.0, 1.0)
var direction_weight := lerpf(0.50, 1.0, clampf(head_on_ratio, 0.0, 1.0))
var load_delta := speed_severity * direction_weight
if load_delta <= 0.0:
    return false

_condition_load = minf(_condition_load + load_delta, CONDITION_MAX_LOAD)
_condition_contact_cooldown = CONDITION_CONTACT_COOLDOWN_SECONDS
_refresh_condition_state()
return true
```

This intentionally makes head-on impacts more consequential than glances while retaining speed as the primary severity source. A severe head-on impact can produce BATTERED; repeated legitimate severe impacts can produce CRITICAL. One sustained collision cannot contribute every physics frame because accepted condition hits arm the cooldown.

The cooldown is decremented by normal vehicle physics time. A deterministic test seam may set or advance the private cooldown only to represent elapsed time between distinct impacts; production damage still enters through the real collision path.

### State thresholds

- load `< 0.75` -> `ROADWORTHY`;
- load `>= 0.75` and `< 1.50` -> `BATTERED`;
- load `>= 1.50` -> `CRITICAL`.

The internal load is capped at `1.50`. CRITICAL is not a destruction threshold.

## Condition behavior

### ROADWORTHY

Ordinary retained production handling and presentation.

### BATTERED

No mechanical handling penalty. Presentation must make the abuse perceptible without creating a numeric maintenance UI.

### CRITICAL

Only the usable forward maximum speed changes:

```gdscript
usable_max_speed = max_speed * CRITICAL_SPEED_MULTIPLIER
```

Requirements:

- steering stays available;
- steering coefficients and speed-normalization denominator stay on the retained ordinary `max_speed` contract;
- reverse remains available at the retained `max_reverse_speed`;
- acceleration/braking/grip/handbrake values stay unchanged;
- mounted/dismounted behavior stays unchanged;
- entering CRITICAL never sets speed to zero or immobilizes the vehicle;
- current forward speed is bounded to the usable CRITICAL cap as physics continues;
- CRITICAL remains fast enough to limp through ordinary Gears routes and reach the Garage.

## Damaged-vehicle presentation

Use restrained local world presentation in each vehicle controller, independent of Audio:

- ROADWORTHY: no damage marker/smoke;
- BATTERED: small dark mechanical smoke plus a restrained billboard condition tag while damaged;
- CRITICAL: denser smoke plus `CRITICAL // LIMP` tag.

The tag exists to make the three-state tracer unambiguous during this production slice; it is not a numeric HP HUD and may be revisited in a later presentation pass.

Presentation must be derived from the authoritative condition enum and never drive condition or handling.

## Burn Garage repair runtime

Create one bounded root-level runtime:

`godot/scripts/world/burn_garage_repair_runtime.gd`

Mount it as a root sibling through the retained `GearsDistrictSlice01B` spatial composition seam, following Productions 04–06.

Responsibilities:

- resolve `GearsDistrictSlice01B/MissionDestinationSocket` as the sole repair location;
- create one bounded `InteractableBase` repair target centered on that authored socket;
- append only that target to the retained root `_interactables` list;
- connect to the existing `TouchControlsUI.action_button_pressed` signal;
- read the retained root `_active_target` and `_get_active_vehicle()` seams;
- read `BurnsideWantedRuntime.get_wanted_state_name()` and `get_heat_level()` only;
- repair only the currently active damaged Courier Bike or Scrap Hauler;
- own a small in-world repair affordance label at the Garage;
- never create a second Wanted, Mission, vehicle, input, or persistence authority.

Initial constants:

```gdscript
const REPAIR_RADIUS_M := 2.6
const REPAIR_STOP_SPEED_MPS := 0.35
const AFFORDANCE_RADIUS_M := 8.0
```

### Repair eligibility

Repair succeeds only when all are true:

1. active vehicle is `CourierBike` or `ScrapHauler`;
2. `get_condition_name() != "ROADWORTHY"`;
3. vehicle is within `REPAIR_RADIUS_M` of MissionDestinationSocket;
4. `abs(current_speed) <= REPAIR_STOP_SPEED_MPS`;
5. Wanted reports both heat `0` and state `CLEAR`;
6. `repair_condition()` returns `true`.

Any missing Wanted authority fails closed.

Repair rejection never mutates condition or Wanted.

### Repair affordance

The retained Garage already carries `BURN // GARAGE` and `RIDE/FIX` authored signage. P07 adds only a small context label around the repair socket when a damaged active vehicle approaches:

- eligible: `REPAIR // ACTION`;
- moving: `STOP TO REPAIR`;
- Wanted active: `WANTED // SERVICE LOCKED`.

A successful repair gives one short `ROADWORTHY` confirmation. No menu and no cost are introduced.

## Active-vehicle interaction correction

Current root target-selection/action-position code still calculates interaction position from the Courier Bike specifically in two places even though `_get_active_vehicle()` already exists.

Production 07 must replace those two Bike-specific calculations with:

```gdscript
var active_veh := _get_active_vehicle()
var active_pos := active_veh.global_position if active_veh else player.global_position
```

This is a bounded correctness repair required so the Scrap Hauler can use the same retained interaction ownership at Burn Garage. Do not otherwise refactor the interaction system.

## Mission 02 composition

`CivicRepossessionRuntime` remains authoritative for Mission 02.

Its retained Garage delivery is automatic while phase is `DELIVERY`, the Hauler is within `RETURN_ZONE_RADIUS == 2.6`, and the authored return zone resolves to the same MissionDestinationSocket.

P07 must not intercept or replace that delivery check.

Required composition behavior:

- a BATTERED or CRITICAL Hauler still satisfies Mission 02 Garage delivery;
- P07 condition never changes Mission phase directly;
- Mission delivery may complete independently of the P07 Action repair;
- repair after/around legal delivery changes only vehicle condition;
- one Action press cannot invoke Mission completion twice because Mission 02 retains its one-way state machine authority;
- existing Wanted/Field-Hacking ordering remains unchanged.

## Replay and persistence

P07 condition is transient runtime state.

Full `ScrapTestBlock.reset_slice()` must call `reset_condition()` on both production vehicles after retained movement/mount reset.

Do **not** reset condition in ordinary dismount or fast `retry_chase()`; those are not full Replay.

Do not write P07 state to disk.

Do not modify `SurveyedRouteProgressStore`, its schema, or `user://burnside_mapped_knowledge.json`.

A required post-Replay composition state is:

`Bike ROADWORTHY + Hauler ROADWORTHY + P06 surveyed route still known`.

## Input ownership

Repair uses only the existing Action signal and retained active-target selection.

Do not synthesize `InputEventAction`, call Action twice, add a new button, or create a new generalized interaction layer.

Desktop and touch continue to converge on `TouchControlsUI.action_button_pressed` through their retained ownership paths.

## Required focused tests

### Vehicle semantics

1. both vehicles start ROADWORTHY;
2. impact below `4.0 m/s` contributes no load;
3. one accepted meaningful impact contributes bounded positive load;
4. immediate repeat during cooldown contributes nothing;
5. one severe head-on impact can produce BATTERED;
6. after elapsed cooldown, another severe impact can produce CRITICAL;
7. matched-speed glance contributes less load than head-on;
8. Bike and Hauler loads/states remain independent;
9. BATTERED usable max speed equals retained `max_speed`;
10. CRITICAL usable max speed equals `max_speed * 0.52`;
11. CRITICAL does not modify reverse limit, acceleration, braking, steering exports or grip constants;
12. CRITICAL `set_drive_inputs` still accelerates forward to a non-zero limp cap;
13. CRITICAL reverse remains available;
14. `repair_condition()` restores ROADWORTHY once and is idempotent when already ROADWORTHY;
15. reset restores ROADWORTHY.

### Runtime / Garage

1. root runtime mounts at the authored Garage socket;
2. damaged Bike outside repair radius cannot repair;
3. damaged Hauler can become the active Garage target through generic active-vehicle selection;
4. moving damaged vehicle is rejected without mutation;
5. CONTACT rejects repair;
6. SEARCH rejects repair;
7. CLEAR + stopped + in radius repairs exactly once;
8. repair does not change heat/Wanted state;
9. repair Action does not synthesize or duplicate generic Action;
10. Mission 02 delivery remains completable with CRITICAL Hauler at the same Garage;
11. Mission completion and P07 repair affect only their own state;
12. full Replay resets both vehicle conditions;
13. full Replay retains P06 surveyed knowledge.

### Retained regressions

Run relevant exact-head regressions for:

- P01 Wanted / Contact-Search;
- P02 Field Hacking;
- P03 Mission 02 composition;
- P04 work-zone + Mission ordering;
- P05 Scrapper input lock, service access, pursuer stagger and Mission ordering;
- P06 mapped-knowledge persistence, survey semantics and Map/modal input;
- Courier Bike and Scrap Hauler handling;
- mount/dismount;
- desktop vehicle authority;
- touch vehicle routing;
- camera contracts;
- interaction cancel;
- Replay/reset;
- canonical compatibility matrix.

## Runtime / rendered proof

Capture exact-head representative states:

1. ROADWORTHY Bike;
2. real meaningful collision -> BATTERED;
3. repeated legitimate severe collision -> CRITICAL;
4. CRITICAL Bike visibly limping but steerable;
5. damaged Hauler in ordinary/pursuit driving;
6. damaged vehicle at Garage while Wanted -> service locked / repair rejected;
7. CLEAR + stopped damaged vehicle -> repair;
8. repaired ROADWORTHY vehicle leaving Garage;
9. Replay -> both conditions ROADWORTHY while P06 mapped route stays known.

Where practical, include:

`CRITICAL VEHICLE -> SURVEYED SERVICE CUT -> BURN GARAGE`

## Web / public gate

Before merge:

- dedicated P07 exact-head semantic/runtime workflow;
- literal feature-head Web export + static-host smoke;
- synthetic-merge Web export;
- canonical compatibility matrix;
- rendered proof;
- frozen independent review against issue #137 + this spec.

After merge:

- exact-main P07 focused verification;
- retained regressions;
- Web export/public publication;
- `playtest-web/PLAYTEST_BUILD.txt` equals the exact gameplay merge SHA.

Only then update continuity and close #137.

## Completion gate

Production 07 may merge only after:

`RED observed -> GREEN focused semantics/runtime -> real collision/runtime proof -> rendered proof -> retained regressions -> literal-head Web -> synthetic-merge Web -> frozen independent review -> merge -> exact-main verification -> public stamp -> continuity update`.

Build success alone is not completion.