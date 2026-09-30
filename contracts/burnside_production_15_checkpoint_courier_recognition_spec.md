# Burnside Production 15 — Gears Checkpoint / Claimed Courier Bike Recognition

**Issue:** #172  
**Status:** DESIGN LOCKED / PRE-IMPLEMENTATION  
**Baseline main:** `10d1e0493e4ba208b7e2df906eb3b97907150195`  
**Exact retained gameplay/public baseline:** `4b563ff66d0e65f787e710af53d1c9d81209cbe3`

## Player fantasy

The city does not forget material interference the instant the chase ends.

> I smashed through this checkpoint in my claimed bike. I escaped, but when I bring the same bike back, the checkpoint remembers it.

This is one authored proof of local institutional memory. It is not a generalized police database, Reputation system, or vehicle identity framework.

## Player loop

`CLAIM COURIER BIKE -> BREACH CHECKPOINT -> LOCAL BIKE WATCHLIST -> EVADE -> CHECKPOINT REARMS -> RETURN IN SAME CLAIMED BIKE -> FLAGGED SCAN -> REPORT OR JAMMED REPORT -> REACT`

Control path:

`RETURN ON FOOT / DIFFERENT VEHICLE -> ORDINARY TOLL STANDOFF`

## Trigger and actors

Production actor:
- existing `SecurityCheckpointWorldEvent`
- existing checkpoint prop at `GearsDistrictSlice01B/StreetClutter/SecurityCheckpoint`

Recognition is armed only when a successful checkpoint ram breach is performed by:
1. the exact production Courier Bike instance; and
2. P11 authoritative claim state is `CLAIMED`.

An unclaimed Courier Bike, Scrap Hauler, Muscle Coupe, or on-foot player cannot create or satisfy this watchlist.

## State

Append one new event state after all retained enum members:

`WATCHLISTED`

Retained numeric meanings `ARMED=0`, `STANDOFF=1`, `TOLL_PAID=2`, `BREACHED=3`, `DISARMED=4` must not change.

P15 adds temporary runtime state:
- claimed-Courier watchlist flag;
- per-WATCHLISTED-encounter report-attempt flag;
- checkpoint-local feedback label.

The watchlist survives ordinary checkpoint cooldown/rearm.

The watchlist is intentionally **not Durable Progress**:
- Full Replay clears it;
- fresh relaunch clears it;
- no save file or schema is added or changed.

## Return recognition

When the checkpoint is `ARMED` and the active entity enters its retained trigger radius:
- if the temporary watchlist is set **and**
- the active vehicle is the exact production Courier Bike **and**
- P11 still reports that bike `CLAIMED`,

then enter `WATCHLISTED` instead of ordinary `STANDOFF`.

Effects:
- barrier remains closed;
- ordinary toll payment is unavailable;
- checkpoint-local visual feedback becomes visible;
- existing siren feedback may be reused without changing Audio assets/runtime;
- if authoritative P01 Heat is zero, request exactly one civic Report through `BurnsideWantedRuntime.request_civic_report(checkpoint_position)`;
- never mutate `WantedAuthority` directly.

If existing Heat is already above zero, do not request another Report.

## Field-Hacking composition

P02 Field Hacking remains authoritative over the civic Report link.

If the Report link is jammed before the return scan:
- checkpoint still enters `WATCHLISTED`;
- local recognition remains;
- no new Wanted state is created;
- local feedback reads `VEHICLE FLAGGED // LINK FAULT`.

A jam therefore blocks institutional communication, not local perception.

If reporting succeeds, local feedback reads:

`VEHICLE FLAGGED // HOLD`

## Player choices

At `WATCHLISTED`, the player may:
- back away and return on foot;
- switch to another vehicle and return;
- prepare the retained Field-Hacking report suppression before entering;
- ram/breach the checkpoint again.

The ordinary 150 toll action cannot resolve a WATCHLISTED encounter.

## Reset / rearm authority

Ordinary automatic checkpoint rearm:
- restores `ARMED`;
- restores the barrier collider;
- clears encounter-local report-attempt state and label;
- **preserves** the temporary claimed-Courier watchlist.

Full Replay:
- invokes a hard checkpoint reset;
- restores `ARMED`;
- restores the barrier;
- clears encounter-local state;
- clears the temporary watchlist.

## World / UI proof

Create exactly one runtime-owned `Label3D` near the retained checkpoint prop.

Presentation:
- hidden during ordinary behavior;
- `VEHICLE FLAGGED // HOLD` on successful report path;
- `VEHICLE FLAGGED // LINK FAULT` when the report link is suppressed.

Use retained Gears visual language and existing font/material defaults. No new HUD panel, menu, texture, or asset dependency is required.

## Authority boundaries

`SecurityCheckpointWorldEvent` owns:
- checkpoint-local temporary recognition memory;
- WATCHLISTED state;
- checkpoint-local label;
- one bounded Report request;
- retained barrier/cooldown behavior.

`BurnsideWantedRuntime` / `WantedAuthority` own:
- Report consequence;
- Heat;
- Contact;
- Search;
- Evasion.

P11 owns:
- Courier Bike durable ownership;
- recovery and ownership lifecycle.

Root `ScrapTestBlock` may expose/use only the existing active-vehicle and claimed-bike seams needed to identify the production Courier Bike and to hard-reset P15 local memory on Full Replay.

## Required runtime proof

1. First ordinary approach remains `STANDOFF` with retained toll prompt.
2. Unclaimed Courier Bike breach does not create the P15 watchlist.
3. Claimed Courier Bike breach creates exactly the local watchlist.
4. Ordinary checkpoint rearm preserves the watchlist.
5. Return in the same claimed Courier Bike enters `WATCHLISTED`.
6. WATCHLISTED return requests one civic Report when Heat is 0.
7. Reprocessing the same WATCHLISTED encounter does not spam Reports.
8. Return on foot or in a different vehicle remains ordinary `STANDOFF`.
9. Pre-jammed Report link yields WATCHLISTED local recognition with Heat remaining 0.
10. `pay_toll()` rejects WATCHLISTED state.
11. A qualifying second ram can breach WATCHLISTED.
12. Full Replay clears the temporary watchlist.
13. Retained checkpoint deferred-collider/reset-race behavior remains correct.
14. Retained P01/P02/P04/P07/P11/P14 behavior passes.
15. Web export, static-host smoke, public packaging and source-stamp provenance remain compatible.

## Explicit non-goals

- persistent police/municipal vehicle database;
- generalized Recognition ledger;
- generalized witness/camera framework;
- Heat 2–5;
- additional police units;
- vehicle plate/transponder framework;
- fines, debt, impound, insurance or recurring costs;
- new Cash source/sink;
- organizational Standing or universal Reputation;
- new checkpoint geography;
- new Audio assets or Audio-system changes;
- PR #44 camera changes;
- save migration.

## Canon / save / Audio impact

**Canon:** no new faction, government structure, relationship, geography, or major event is established. This is bounded behavior of an existing civic-security checkpoint.

**Save:** none.

**Audio:** no Audio source or asset changes. Existing checkpoint sounds may be reused.

## Acceptance gate

P15 is complete only after:

`RED -> GREEN -> exact-head VERIFY -> frozen REVIEW -> REPAIR -> FREEZE -> MERGE -> exact-main VERIFY -> PUBLIC VERIFY -> CONTINUITY -> ISSUE CLOSE -> PRODUCT RE-EVALUATION`
