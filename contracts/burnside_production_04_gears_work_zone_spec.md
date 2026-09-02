# Burnside Production 04 — Gears Work-Zone / Player-Reactive Ambient Incident

**Issue:** #127  
**Status:** `SPEC_LOCKED__RED_AUTHORIZED`  
**Selection baseline:** `main@d512c532fd2c3c3ccf2d7738ff76201c129ad98f`  
**Verified gameplay baseline:** `afd1db546b04221c7fb4b222b9f77311acd6d3ea`

## Player value

Add one small piece of believable Gears street life that notices the player and can collide with the already-qualified city consequence loop.

The slice must feel like a city work shift the player can interrupt, not a spawned side activity or a generic pedestrian framework.

## Existing truth preserved

The playable root already instantiates two `ScrapWorker` actors and one `UtilityCrawler` in the retained yard/start area. `ScrapTestBlock._process()` already forwards active-player/vehicle proximity samples to those actors, giving them deterministic `AMBIENT -> YIELDING -> AMBIENT` reactions. Historical authored disturbance can also drive them into `ALARMED`.

Production 04 does **not** replace or relabel that behavior. It adds a separate authored Gears street work-zone pair and composes only that pair with ordinary civic Report authority.

## Authored location

Anchor one `GearsWorkZoneIncident` under `GearsDistrictSlice01B` at the existing `IndustrialIntersection` / `CivicCrossingBand` seam.

Required local actors:

- one `ScrapWorker` using the retained production scene/script;
- one `UtilityCrawler` using the retained production scene/script.

Their calm patrol should visibly cross or service the intersection without blocking the full route.

## State model

Incident-local state is intentionally tiny:

`ROUTINE -> ALARMED -> RECOVERING -> ROUTINE`

Actor-local `AMBIENT / YIELDING / ALARMED / RECOVERING` remains owned by the retained actor scripts.

Wanted state remains owned only by `BurnsideWantedRuntime` / `WantedAuthority`.

## Routine / yielding

Each frame, the active player entity is sampled.

- On foot or in a vehicle, normal proximity may call the retained actor `check_proximity_threat()` seam.
- Yielding alone must never request a civic Report.
- Normal passage through either road lane must remain consequence-free.

## Material disruption seam

Production 04 defines one bounded reportable event: a **high-speed close call with a work-zone actor while that actor is inside the civic crossing corridor**.

A sample is material only when all are true:

1. the active entity is a vehicle;
2. horizontal vehicle speed is at least **8.0 m/s**;
3. the sampled vehicle position is inside the bounded civic crossing corridor owned by this incident;
4. horizontal distance to either work-zone actor is at most **1.25 m**;
5. the incident is in `ROUTINE` and has not already escalated this cycle.

This is deliberately stricter than ordinary yielding. A vehicle can pass the intersection quickly without consequence if it does not buzz the worker/crawler. A slow close pass can make actors yield without creating Wanted.

## Escalation

On the first material disruption:

1. both work-zone actors enter `ALARMED` using their retained `trigger_alarm()` behavior and retreat toward authored safe anchors;
2. local reaction happens regardless of city reporting outcome;
3. if `BurnsideWantedRuntime.get_heat_level() > 0`, do **not** request another report and do not mutate authority;
4. otherwise request exactly one report through `BurnsideWantedRuntime.request_civic_report(observed_position)`;
5. do not call or mutate `WantedAuthority` directly.

Expected city outcomes:

### Reporting live

`CLOSE CALL -> LOCAL ALARM / RETREAT -> REPORT SENT -> HEAT 1 + CONTACT`

### Reporting jammed

`JAM REPORT LINK -> CLOSE CALL -> LOCAL ALARM / RETREAT -> REPORT SUPPRESSED -> CLEAR remains CLEAR`

The incident may consume the existing local one-shot civic alarm because that is the currently qualified local Report source. Production-03's consumed/suppressed Mission-02 repair must remain valid and is a required regression.

## Recovery

Local disruption does not become permanent clutter.

- Minimum alarm/recovery window: **4.0 seconds**.
- Do not reset the local actors while the sampled player entity remains within **6.0 m** of the work-zone anchor.
- Once the minimum window has elapsed and the player has left that radius, reset the two local actors to their deterministic authored routine.
- Local recovery must not call any Wanted reset/clear operation.
- Replay/reset must restore `ROUTINE`, actor initial positions/states, and incident-local one-shot flags.

Civic reporting service recovery remains owned by `BurnsideWantedRuntime`.

## Integration shape

Prefer one small `GearsWorkZoneIncident` runtime node under `GearsDistrictSlice01B`.

`ScrapTestBlock` may:

- instantiate/configure that node during `_ready()`;
- pass the current active entity + whether it is a mounted vehicle during `_process()`;
- call `reset_incident()` from the existing replay reset.

Do not add an autoload, event bus, population manager, ambient scheduler, or generalized incident manager.

## Required production contract

The focused tracer must prove:

1. `GearsDistrictSlice01B/GearsWorkZoneIncident` exists in live production and `GearsStyleProof` remains hidden;
2. retained root `ScrapWorker1`, `ScrapWorker2`, and `UtilityCrawler` remain present;
3. work-zone actor pair starts in routine/ambient state;
4. slow/ordinary passage can produce yielding without Heat;
5. high-speed close-call escalation alarms both work-zone actors;
6. live civic reporting produces Heat 1 + Contact from CLEAR;
7. jammed reporting leaves authority CLEAR while local actors still alarm;
8. pre-existing Wanted survives without a second report/reset;
9. local recovery does not clear authority state;
10. jammed work-zone report consumption followed by Mission 02 cannot strand Mission 02;
11. replay/reset restores incident-local deterministic state.

## Scope exclusions

No combat, Health/Armor, weapon work, vehicle damage/condition/claiming, Standing, Heat 2–5, generalized witnesses, generic crime architecture, traffic simulation, transit, broader geography, PR #44 camera work, new audio assets, audio retuning, or generalized mission/ambient/NPC frameworks.

## Verification

`SPEC -> RED -> GREEN -> exact-head VERIFY -> frozen Standards + #127 REVIEW -> REPAIR if needed -> MERGE -> exact-main VERIFY`
