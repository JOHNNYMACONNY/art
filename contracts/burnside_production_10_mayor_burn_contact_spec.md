# Burnside Production 10 — Mayor Burn Known Contact / Garage Armor Restock

Authority: issue #152, product direction #55, Factions & Reputation Contract #107, Burnside production contract #118, and Production 09.

## Player promise

`COMPLETE CIVIC REPOSSESSION -> BURN KNOWS YOU -> GARAGE ARMOR STASH UNLOCKS`

This is an authored Contact consequence, not organization Standing or a generalized reputation system.

## Durable Contact state

Exactly two stored states exist in this tracer:

- `UNESTABLISHED`
- `KNOWN`

Civic Repossession completion promotes Mayor Burn to `KNOWN` exactly once. Full Replay and relaunch preserve that fact.

The store is narrow, versioned, fail-safe on malformed/newer data, and independent from P06 mapped knowledge.

## Garage privilege

At the existing Mayor Burn Garage service socket, a KNOWN Contact unlocks one on-foot service:

- Runner must be on foot;
- Armor must be below `PlayerRunner.MAX_ARMOR`;
- Wanted must be Heat 0 / CLEAR;
- Runner must be inside the retained Garage radius.

Successful Action restores Armor to exactly `MAX_ARMOR` and does not change Health.

The service is unavailable before KNOWN, rejects mounted use, rejects full Armor, and visibly locks during active Wanted.

No payment, inventory, item pickup, healing, menu, or new economy authority is created.

## Ownership

- `CivicRepossessionRuntime` emits one completion signal and remains mission authority.
- `MayorBurnContactProgressStore` owns only durable Burn Contact state.
- `MayorBurnContactRuntime` owns only the Garage Contact privilege/presentation.
- `PlayerRunner` remains sole Health/Armor arithmetic authority and exposes one narrow Armor-restock seam.
- `BurnsideWantedRuntime` remains read-only authority for service eligibility.
- `BurnGarageRepairRuntime` remains unchanged and authoritative for P07 vehicle repair.

## Presentation

Reuse the retained Garage and Action language:

- nearby known Contact: `BURN // ARMOR STASH`
- eligible: `RESTOCK ARMOR // ACTION`
- active Wanted: `WANTED // BURN WON'T OPEN`

No new HUD meter and no new 3D asset are required for the tracer.

## Non-goals

No organization Standing implementation, faction meter, reputation points, morality, relationship graph, territory, automatic faction math, dialogue tree, wallet/economy, armor inventory, healing service, vehicle claiming, Garage network, firearms, or new acreage.
