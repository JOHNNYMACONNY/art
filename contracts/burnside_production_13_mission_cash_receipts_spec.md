# Burnside Production 13 — Durable Mission Cash Payout Receipts

Status: DESIGN LOCKED / IMPLEMENTATION TDD

Issue: #164

## Player loop

`COMPLETE MISSION 01 -> +320 CASH ONCE -> COMPLETE MISSION 02 -> +450 CASH ONCE -> CASH PERSISTS -> REPLAY MISSIONS -> GAMEPLAY REPLAYS / PAYOUT DOES NOT`

## Authority boundary

- `BurnsideCashProgressStore` remains the only durable Cash authority.
- Mission runtimes retain mission-state/completion authority.
- Mission 01 adds only one bounded runtime completion signal.
- Mission 02 reuses `civic_repossession_completed`.
- The Cash economy runtime owns payout validation, durable receipts, balance mutation and truthful Cash feedback.
- Mission 03 remains zero-Cash and receives no receipt/coupling.

No generalized quest ledger, reward registry, repeatable jobs, inventory, XP, new currency, new shop, dynamic pricing, property economy, new geography, Audio change or PR #44 work.

## Store schema v2

P12 v1:

`{ version:1, cash, vending_hack_paid, vending_breach_paid }`

P13 v2:

`{ version:2, cash, vending_hack_paid, vending_breach_paid, mission_01_paid, mission_02_paid }`

Migration contract:

1. exact v1 Cash and vending receipts are validated before migration;
2. `mission_01_paid=false` and `mission_02_paid=false`;
3. the v2 document is persisted through the retained staging-file + atomic rename path;
4. successful migration performs exactly one durable write;
5. a failed migration write must not destroy the valid v1 document;
6. malformed documents fail closed;
7. unsupported newer versions fail closed and are never overwritten.

Exact payout contracts:

- Mission 01: 320 Cash once.
- Mission 02: 450 Cash once.
- Invalid reward values cannot consume receipts or mutate Cash.
- P12 vending remains exactly 80/120 once.
- Street Vendor remains exactly 150 debit.

## Mission 01 completion signal

`scrap_job_mission_runtime.gd` emits `scrap_job_completed` only when an authored runtime transition changes the mission from a non-COMPLETE phase into `Phase.COMPLETE`.

Direct/manual mutation of the mission phase does not emit the signal and cannot independently create Cash.

A full Replay creates a fresh Mission 01 run and re-arms the runtime completion signal, while the durable Cash receipt remains paid.

## Mission 02 completion

Reuse the existing `civic_repossession_completed` signal. Mayor Burn Contact remains a separate listener/authority and must retain existing behavior.

## Presentation

First Mission 01 payout:
`JOB PAID // +320 CASH // BALANCE X`

First Mission 02 payout:
`BURN PAID // +450 CASH // BALANCE X`

A completion whose durable receipt was already paid must not expose another +Cash event. Use:
`PAYMENT ALREADY CLEARED // BALANCE X`

The authored objective may continue to show the contract value.

## Browser persistence

Native tests are not sufficient. P13 includes an exported Web probe using the real Cash store against `user://`.

Pass A in Chromium:
- clean store;
- credit Mission 01 +320 and Mission 02 +450;
- verify balance 770 and both receipts;
- force filesystem sync.

Pass B:
- close the browser context;
- relaunch the same Chromium persistent profile at the same origin;
- verify balance 770 and both receipts reload with zero new writes.

Run this against literal PR head and synthetic merge source.

## Completion gates

- v1 -> v2 migration proof;
- exact one-time 320/450 receipts;
- legitimate Mission 01 production completion signal;
- existing Mission 02 production completion signal;
- replay/relaunch anti-farming;
- truthful duplicate-payment presentation;
- Mission 03 zero-Cash;
- P12 earn/spend behavior unchanged;
- P07/P10/P11 free-service behavior unchanged;
- browser IndexedDB persistence proof;
- literal-head and synthetic-merge Web green;
- canonical compatibility matrix green;
- frozen review has no blocking findings;
- merged main and public source stamp match exactly.
