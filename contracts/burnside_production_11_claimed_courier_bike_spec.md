# Burnside Production 11 — Claimed Courier Bike / Burn Garage Recovery

Authority: issue #158, product anchor #55, Burnside production contract #118,
Vehicle Sandbox Contract #103, Progression & Economy Contract #105, Production
07 vehicle condition/repair, Production 08 companion docking, and Production 10
Mayor Burn Contact.

## Player-facing chain

`BURN KNOWN -> BRING COURIER BIKE TO GARAGE -> PARK / DISMOUNT -> CLAIM -> OWNERSHIP PERSISTS -> BIKE LEFT AWAY -> RETURN TO GARAGE -> RECOVER -> RIDE OUT`

The first tracer proves Reliable Access to one favorite vehicle without weakening
ordinary Street Vehicle freedom.

## Durable ownership authority

One versioned `CourierBikeClaimProgressStore` owns exactly:

- `UNCLAIMED`
- `CLAIMED`

The store is independent from P06 mapped knowledge and P10 Burn Contact.
Ownership survives Replay, Soft Failure and reload. Unsupported/newer or malformed
data fails safe and is never silently overwritten.

No fleet database, arbitrary vehicle IDs, garage slots, generic save framework or
vehicle collection system.

## Garage claim / recovery seam

Add one passive `CourierBikeClaimSocket` to the existing Burn Garage forecourt,
spatially distinct from `MissionDestinationSocket`.

Mount one root-level `BurnGarageCourierBikeClaimRuntime` through the retained
Gears District composition seam.

### Claim eligibility

- Burn Contact is KNOWN;
- Wanted heat is 0 and state is CLEAR;
- Runner is on foot at the claim bay;
- retained Courier Bike is stopped and inside the claim radius;
- ownership is UNCLAIMED.

Claim is free for this tracer. Claiming writes CLAIMED exactly once and does not
repair the Bike or mutate player vitals, Wanted, missions, mapped knowledge or
Burn Contact.

### Recovery eligibility

- ownership is CLAIMED;
- Burn Contact remains KNOWN;
- Wanted is CLEAR;
- Runner is on foot at the claim/recovery bay;
- Courier Bike is unoccupied;
- Courier Bike is materially outside the Garage recovery radius.

Recovery reuses the existing Courier Bike instance, moves it to
`CourierBikeClaimSocket`, zeros speed/velocity, restores a legal parked state and
restores ROADWORTHY through the existing P07 condition API.

Recovery never duplicates a Bike and cannot act on a mounted/occupied Bike.
There is no remote summon: Runner must physically return to Burn's Garage.

## Replay / relaunch

Ownership is Durable Progress.

Full Replay retains CLAIMED and positions the claimed Courier Bike at the authored
Garage recovery socket after retained P07 condition reset. Fresh scene startup with
a persisted CLAIMED store establishes the same Garage recovery state.

Soft Failure never clears ownership and does not itself trigger recovery.

## Presentation

Reuse retained Action/Garage language; no menu.

- eligible claim: `CLAIM COURIER BIKE // ACTION`
- success: `BIKE // CLAIMED`
- claimed Bike away: `RECOVER COURIER BIKE // ACTION`
- Wanted active near service: `WANTED // GARAGE LOCKED`

No ownership HUD, collection screen, map summon, insurance UI or Garage network.

## Non-goals

No Scrap Hauler/Muscle Coupe ownership, prices/wallet, customization, insurance,
tow timers, destruction system, generalized identity registry, new geography,
Heat 2–5, unrelated Audio changes or PR #44 camera work.
