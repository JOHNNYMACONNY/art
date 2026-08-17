# CTW Feel Wave 1 — Baseline Provenance

**Ticket:** #11 — deterministic feel harness and immutable baseline  
**Gameplay behavior baseline:** `09fa2b0ab8aebc8a2ae54b989bffad7720503e48` (V8 M07)  
**Harness / CI commit tested:** `25f7ff3a7e77549b22245bf8d972b32183e5a4d0`  
**Godot:** `4.7.1.stable.official.a13da4feb`  
**Simulation:** fixed 60 Hz (`dt = 0.0166666666666667 s`)

## Verification record

GitHub Actions run `32020748815` was executed twice on the same branch head.

- First complete successful job: `95359727292`; artifact `9285301564`.
- Flake-check rerun job: `95360535202`; artifact `9285402785`.
- Both complete jobs passed:
  - deterministic E1–E7 harness execution;
  - in-run Pass A vs Pass B repeatability;
  - generated evidence validation;
  - the current 24/24 regression commands;
  - fresh windowed/Xvfb M07 rendered proof generation and PNG validation.

Final regression classification in both complete jobs:

```text
Branch under test: 25f7ff3a7e77549b22245bf8d972b32183e5a4d0
Behavior baseline: 09fa2b0ab8aebc8a2ae54b989bffad7720503e48
Godot: 4.7.1.stable.official.a13da4feb
24/24 branch regression commands exited 0.
```

No branch-only regression remained in either final complete run.

## Immutable compact baseline

`baseline_summary.json` SHA-256 was identical in both complete runs:

`207730c03831672b54ffb7786444581466da774d8222add99cd8b394b59407e3`

Raw scenario traces were also byte-identical across both runs:

| Scenario | SHA-256 |
|---|---|
| E1 launch/coast/brake | `9fb88a71800a09e0c1be247be8ac2081bdc14ac6ab0184455e226bf49cc6878a` |
| E2 constant 90° turn | `9068ea15767f061bcb368143218347dd6eaf329f36e2900de957ff879005727f` |
| E3 steering reversal | `eb3c5be57fa97e668eefaa272d48bae587627419f09898df65c8ce2a86c46490` |
| E4 handbrake recovery | `9abc37dc9cc981a46c7e36b3a6769ab6b1354a65b149b24d6b41891e086d14fa` |
| E5 collision pair | `88acf1904f2d88d6a8ed380cfbe19002a0cb22bd41f015190504e7e0bc5627b2` |
| E6 forward/reverse | `94a6a75245013cbb7b440b1782cd406280fd7258275c47feeadfbece493a6892` |
| E7 pursuit route | `00509aee003df32e07b7b4dc28cd1425b5734c88c6f0dd5f1c4ee736033de3dd` |

The raw traces are intentionally **not committed** because the compact summary is sufficient for routine candidate comparison and the harness regenerates the exact raw traces from the frozen behavior baseline. Verified raw traces remain in the cited CI artifacts for the artifact retention window.

## Fresh rendered sanity proof

The flake-check rerun deleted the committed M07 PNGs from the workspace before rendering, then regenerated and validated all seven PNGs under a windowed Xvfb session:

| Proof | Bytes |
|---|---:|
| `m07_01_ambient_cold_start.png` | 157,240 |
| `m07_02_worker_activity.png` | 213,543 |
| `m07_03_bike_yield_reaction.png` | 172,987 |
| `m07_04_hauler_yield_reaction.png` | 244,000 |
| `m07_05_disturbance_alarm_reaction.png` | 216,710 |
| `m07_06_cleared_pursuit_escape.png` | 204,407 |
| `m07_07_ambient_quiet_reset.png` | 156,537 |

This proves the measured branch still executes/rendered the current bike/pursuit/world behavior rather than passing from headless assertions alone.

## Important observations

- An earlier expanded CI attempt produced one transient M06 Assertion 4 failure (`Vehicle must drive forward with positive throttle`). It did **not** reproduce in either of the two final complete verification passes; both finished 24/24 green. Preserve this observation for future flake investigation, but it is not classified as a #11 regression.
- E7 contains **14 repeatable collision-contact signals** from the Courier Bike glancing the shortcut corridor wall. They are deliberately retained in the baseline instead of being filtered out, because they are real behavior in the measured route.
- The original E7 repeatability defect was in the harness: `PursuerPrototype.reset_pursuer()` resets position/lifecycle but not transform rotation. The harness now explicitly restores the pursuer heading before each pass. Tolerances were not weakened.
- No Courier Bike, camera, pursuer, touch, audio, world, or gameplay constants were changed by Ticket #11.

## Use by later tickets

Tickets #12–#16 compare candidate behavior to `baseline_summary.json` and this provenance record. A later baseline may supersede this one only through an intentional provenance-bearing decision; do not silently overwrite it.
