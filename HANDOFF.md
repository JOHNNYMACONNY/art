# HANDOFF.md — CTW Feel Translation Wave 1 Functional Retention

**Status:** `FUNCTIONAL_WAVE_VERIFIED__PERCEPTUAL_GATE_PENDING`  
**Integrated gameplay behavior:** `a10ac0ce235fa56ca8084cae05ad0959751a821b`  
**Immutable Feel baseline:** `09fa2b0ab8aebc8a2ae54b989bffad7720503e48`  
**Closure ticket:** GitHub #17 / PR #48 verification package  
**Engine:** Godot 4.7.1 Stable

## Current product state

CTW Feel Translation Wave 1 has a functionally verified retained configuration. Ticket #17 adds verification/evidence only; it does not introduce new gameplay behavior. The retained product system is:

| Ticket | Candidate | Disposition | Production state |
|---|---|---|---|
| #12 | Touch steering conditioner | **PENDING** | Linear normalized touch steering remains the default. The `0.06` radial deadzone / `1.5` response-power experiment remains disabled pending physical touch A/B. |
| #13 | Camera occlusion cutaway experiment | **REVERTED** | The existing dynamic elevated 3/4 Chinatown-Wars-style camera follow remains retained. The separate PR #44 occlusion experiment stayed test-only/unmerged. |
| #14 | Vehicle traction, impact and audio feedback | **RETAINED** | Telemetry-driven engine/load, traction/recovery, scaled impact output and priority ducking remain active. |
| #15 | Fast pursuit retry | **RETAINED** | Retry preserves solved setup and returns directly to the pursuit loop. |
| #16 | Bounded pursuer interception | **RETAINED** | Observable-velocity destination prediction remains enabled; authored Signal Gate detours retain authority. |

The integrated control loop is:

`touch / desktop intent -> normalized vehicle intent -> Courier Bike -> retained camera -> vehicle feedback -> pursuit / route pressure -> interception or evasion -> fast retry / continued control`

## Verification evidence

The Wave 1 retention package reuses the immutable Ticket #11 E1–E7 scenario implementation rather than creating a parallel gameplay simulator. On the integrated retained system:

- E1–E6 must remain within the Ticket #11 deterministic tolerance envelope.
- E7 must preserve the bike route, camera behavior, collisions, Signal Gate detour authority and non-intercepted outcome.
- Only the #16-intended pursuer distance and pursuer endpoint fields may differ from the immutable baseline.
- The committed retention contract verifies that runtime defaults match the declared ticket dispositions.
- Existing Web/PR compatibility gates continue to cover V1–V8+, mobile safe area, thumb reach, multitouch, vehicle authority, camera, pursuit/gate, Memory Echo, audio, fast retry and readability behavior.
- Existing retained rendered evidence remains authoritative for the constituent changes: the accepted camera baseline has owner play evidence, and Feel 04 already carries exact-head windowed full-slip pixel-delta proof.
- Ticket #17 deliberately does **not** add a second nested rendered playthrough sweep to Web export. That experiment created CI latency/failure without adding meaningful product confidence under the current code-first verification policy, so it was removed.
- Ticket #17 itself has no runtime gameplay/performance mutation.

The machine-readable retention record is:

`godot/verification/feel/wave1_retention_summary.json`

The integrated verifier is:

`godot/scripts/verification/ctw_wave1_integrated_harness.gd`

Exact PR/merge workflow run IDs and head SHAs remain GitHub evidence rather than being duplicated as mutable prose here.

## Perceptual truth / deferred gates

This handoff deliberately separates functional verification from human perceptual qualification:

- **Current camera baseline:** accepted as good-enough in owner play and retained. That is product-owner feel evidence, not a fresh-player cohort gate.
- **Touch conditioner candidate:** physical-device A/B is still pending. Because the candidate is disabled, this does not block the retained linear default.
- **Physical audio playback:** not claimed as performed for this closure. Under the current code-first production policy it is deferred/non-blocking, while audio lifecycle/mix/output contracts remain automated gates.
- **Fresh-player gate:** still `PENDING`. Do not classify the wave as `WAVE_1_RETAINED_AND_PERCEPTUALLY_VERIFIED` until that evidence exists.

## Scope discipline

Do not reopen retained systems merely for speculative polish. New changes should target a concrete observed weakness, regression, or next product milestone. In particular:

- PR #44 is a deferred/non-retained occlusion experiment, not evidence that the current camera follow is unfinished.
- The touch conditioner is an available experiment, not the current default.
- The retained pursuer lead changes destination selection only; speed, acceleration and physical interception rules remain separate authority.
- Wave 1 closure is not authority to add missions, combat, inventory, progression, networking, or unrelated framework work.

## Next-state rule

Use `godot/verification/feel/wave1_retention_summary.json`, current GitHub state, and current issue/spec evidence as authoritative continuity. `WAYFINDER_MAP.md` is retained as a historical architecture map and is not the live status tracker.
