# Burnside Production 14 — Claimed Courier Bike Scrap Bash Bar

Status: DESIGN LOCKED / READY FOR SPEC TDD

## Player-facing contract

`DO PAID WORK -> BUILD CASH -> CLAIM COURIER BIKE -> RETURN TO BURN GARAGE -> FIT SCRAP BASH BAR FOR 500 CASH -> BIKE CHANGES VISIBLY -> DELIBERATE FRONTAL RAMS HURT THE BIKE LESS -> REPLAY / RELAUNCH / RECOVERY -> MOD REMAINS`

Target feeling:

> Mission money turns the Courier Bike into the player's own Burnside machine. The welded front cage is readable before impact, and its benefit is learned through street behavior rather than a stat screen.

This slice should reinforce the near-future civic-salvage dystopia: practical black-market fabrication, municipal leftovers, visible repair culture, and a machine that looks altered by use rather than by a clean upgrade menu.

## Exact modification

Name: **Scrap Bash Bar**

One modification only.

Presentation:
- permanent front-mounted welded cage / push bar on the claimed Courier Bike;
- charcoal/off-white salvage metal with one hazard-amber center plate;
- bold silhouette readable from the retained GTA-style camera;
- no menu, catalog, rarity, inventory, attachment slots, or generic mod framework;
- no new Audio work.

The bash bar is hidden until the durable purchase receipt exists.

## Exact gameplay effect

Stock Courier Bike collision-condition behavior remains the baseline.

When the Scrap Bash Bar is installed:
- only **frontal** impacts with `head_on_ratio >= 0.70` receive protection;
- computed P07 condition load for those impacts is multiplied by **0.35**;
- glancing / side impacts use the unchanged P07 condition formula;
- collision telemetry, impact speed, world ram checks, pursuer ram behavior, collision audio routing, vehicle speed loss, and world-prop thresholds are unchanged.

Observable reference case:
- `head_on_ratio = 1.0`, `impact_speed = 10.0`;
- stock Courier Bike reaches **BATTERED** from ROADWORTHY after one accepted impact;
- fitted Courier Bike remains **ROADWORTHY** after the same one impact.

This is intentionally not generic armor or extra HP. It creates one authored behavior: the claimed Bike becomes safer to use as a frontal improvised ram.

## Price / economy

Fixed price: **500 Cash**.

Why 500:
- Mission 01 + Mission 02 authored first payouts total 770;
- retained unique vending payouts can add 200;
- retained temporary Street Vendor tune-up costs 150;
- 500 is reachable without repeatable grind;
- it creates a meaningful durable-vs-temporary spend choice;
- it does not force one mission order: multiple existing payout combinations can reach the price.

No debt, upkeep, maintenance cost, insurance, fuel cost, dynamic pricing, resale, or refund.

## Durable authority / atomicity

`BurnsideCashProgressStore` remains the only durable Cash authority.

P14 evolves the Cash document from schema v2 to **schema v3** by adding exactly one payment receipt:

`courier_bike_bash_bar_paid: bool`

The receipt is a payment/entitlement receipt, not a generalized vehicle-mod inventory.

Required migration:
- valid v1 -> v3 preserves Cash + vending receipts; initializes mission receipts and bash-bar receipt false;
- valid v2 -> v3 preserves Cash + vending receipts + mission receipts; initializes bash-bar receipt false;
- valid v3 loads exactly;
- malformed / unsupported newer data fails closed and is not overwritten.

Atomic purchase API:
- exact accepted cost is 500 only;
- insufficient Cash rejects with zero mutation;
- duplicate receipt rejects with zero mutation;
- a successful call decrements Cash and sets the receipt in the same staged-file atomic persist;
- persist failure rolls both in-memory fields back.

The Bike presentation/capability is derived from the durable receipt. The runtime must never apply the mod first and debit later.

## Garage interaction seam

Reuse the existing `CourierBikeClaimSocket`.

Do not add another Garage location.

The P14 interactable:
- is available only after the Courier Bike is durably CLAIMED;
- requires Burn Contact KNOWN;
- requires Wanted heat 0 / state CLEAR;
- requires Runner on foot;
- requires the claimed Bike unoccupied, stopped, and inside the claim bay;
- is unavailable once the bash-bar receipt exists;
- uses the retained Action route;
- uses interaction priority **3.9**, below the P11 claim/recovery priority 4.0.

Arbitration invariant:
- before claim, P11 owns the bay;
- after claim while the Bike is materially away, P11 recovery owns the bay;
- after claim with the Bike physically in the bay, P11 claim/recovery is inactive and P14 may own the Action target;
- P07 repair and P10 armor remain on the spatially distinct `MissionDestinationSocket`.

No simultaneous target fight is permitted.

## Feedback

Near-bay / eligible:
- `FIT SCRAP BASH BAR // 500 CASH // ACTION`

Insufficient:
- `BASH BAR // 500 CASH // NEED <shortfall>`

Wanted:
- `WANTED // GARAGE LOCKED`

Success:
- `SCRAP BASH BAR // FITTED`
- Cash feedback: `BASH BAR FITTED // -500 // CASH <balance>`

Duplicate direct API:
- `BASH BAR ALREADY FITTED // CASH <balance>`

## Replay / recovery

Full Replay:
- preserves Cash, all existing receipts, claim, and bash-bar receipt;
- preserves / reapplies the bash-bar visual and capability;
- retains P07 Replay semantics for transient vehicle condition.

Fresh relaunch:
- reconstructs the production scene/runtime;
- reloads CLAIMED + Cash receipt from disk;
- returns the same production Courier Bike to the Garage under retained P11 behavior;
- applies the bash bar from the receipt without another debit.

P11 recovery:
- returns the same claimed Bike instance;
- retains the bash bar;
- retains the existing ROADWORTHY recovery behavior.

## Retained behavior

Must remain unchanged:
- P07 free Garage repair and coarse condition states;
- P10 free armor restock;
- P11 claim/recovery ownership behavior;
- P12 vending 80/120 once and 150 temporary tune-up;
- P13 Mission 01 +320 once / Mission 02 +450 once;
- Mission 03 zero Cash;
- Wanted authority;
- FB-13 vehicle docking;
- controls/camera/input;
- existing ram thresholds and prop consequences;
- Audio behavior.

## Explicit non-goals

No:
- second mod;
- toggle/remove/swap UI;
- customization menu/catalog/tree;
- cosmetic inventory;
- generic vehicle-mod data model;
- arbitrary vehicle IDs;
- Hauler/Coupe customization;
- fleet/storage expansion;
- repeatable Cash source;
- XP/levels/rarity;
- fuel/insurance/maintenance;
- new geography;
- Heat 2–5;
- unrelated Audio;
- PR #44 camera work.

## Required proof

Exact feature head must prove:
1. valid v1 and v2 migration to v3;
2. 499 / wrong-price / insufficient purchase rejects with zero mutation;
3. 500 purchase debits exactly once and persists receipt atomically;
4. duplicate purchase cannot double-debit;
5. unclaimed Bike rejects;
6. Wanted-active Garage rejects;
7. retained Action arbitration selects P14 only in its legal claimed-Bike-in-bay state;
8. fitted production Bike visibly shows the bash bar;
9. stock one-hit frontal reference becomes BATTERED while fitted one-hit reference remains ROADWORTHY;
10. fitted glancing/side condition behavior is not protected;
11. P07 repair remains independent/free and does not remove the mod;
12. P11 recovery retains the mod;
13. Replay retains the mod;
14. fresh production-scene reconstruction reloads Cash/claim/receipt and reapplies the mod;
15. retained P11/P12/P13/P07/P10 regressions remain green;
16. Godot Web Playtest remains green.

Implementation is not complete until frozen review is clean and exact-main/public verification passes.
