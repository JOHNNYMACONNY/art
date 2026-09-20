# Burnside Production 12 — Durable Cash / Street Vendor Transaction

Authority: issue #161, #55, #118, Progression & Economy Contract #105, retained
Street Vendor / Vending Machine production props, and Production 11.

## Player-facing loop

`TERMINAL -> REAL CASH -> VENDOR COST -> ACTIVE-VEHICLE TUNE-UP -> REAL BALANCE`

The current world already advertises 80/120 scrap rewards and a 150 tune-up cost.
P12 makes that presentation authoritative without building a general economy.

## Cash authority

One versioned `BurnsideCashProgressStore` owns:
- non-negative integer Cash balance;
- one durable receipt for the unique terminal hack payout;
- one durable receipt for the unique terminal breach payout.

Cash + receipts survive Replay, Soft Failure and fresh store reconstruction.
Unsupported/newer or malformed data fails safe and blocks writes.

Terminal payout values remain:
- first hack: +80;
- first breach/ram payout: +120.

Each durable receipt pays at most once even if the physical prop resets.

## Vendor transaction

Street Vendor tune-up remains 150 Cash.

Successful purchase requires a tradeable vendor, no already-active vendor tune-up,
an actual supported active vehicle, and balance >= 150.

Success:
- applies retained `apply_tune_up` only to the active vehicle;
- debits exactly 150 once;
- leaves inactive vehicles unchanged.

Failure never debits or applies a tune-up.

P07 repair, P10 armor restock and P11 recovery remain free.

## Presentation

Existing prompts remain. Transient status feedback must show truthful payout/debit
and resulting balance. Paid-out terminal receipts must not display another +Cash.

## Non-goals

No XP, levels, inventory, shop catalog, merchant framework, loot tables, dynamic
prices, rent, fuel, maintenance economy, banks/debt, multiple currencies, broad
receipt registry, new geography, unrelated Audio, or PR #44 camera work.
