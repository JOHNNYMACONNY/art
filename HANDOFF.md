# HANDOFF.md — Current Product Continuity

**Status:** `MISSIONS_01_02_MERGED__CODE_VERIFIED__PERCEPTUAL_GATES_DEFERRED`  
**Current gameplay baseline:** `9dd9110ae261eea456daa4a27bff9f1fd9d3f273`  
**Immutable Feel baseline:** `09fa2b0ab8aebc8a2ae54b989bffad7720503e48`  
**Engine:** Godot 4.7.1 Stable

## Current product state

The retained Chinatown-Wars-style Feel foundation now supports two connected authored crime jobs in the production Godot slice. Mission work is deliberately specific and layered over existing gameplay authorities; there is still no generalized quest framework.

### Retained Feel foundation

| Ticket | Candidate | Disposition | Production state |
|---|---|---|---|
| #12 | Touch steering conditioner | **PENDING** | Linear normalized touch steering remains the default. The `0.06` radial deadzone / `1.5` response-power experiment remains disabled pending physical touch A/B. |
| #13 | Camera occlusion cutaway experiment | **REVERTED** | The existing dynamic elevated 3/4 Chinatown-Wars-style camera follow remains retained. PR #44 is a deferred experiment, not unfinished camera work. |
| #14 | Vehicle traction, impact and audio feedback | **RETAINED** | Telemetry-driven engine/load, traction/recovery, scaled impact output and priority ducking remain active. |
| #15 | Fast pursuit retry | **RETAINED** | Retry preserves solved setup and returns directly to the pursuit loop. |
| #16 | Bounded pursuer interception | **RETAINED** | Observable-velocity destination prediction remains enabled; authored Signal Gate detours retain authority. |

Wave 1 functional closure remains represented by `godot/verification/feel/wave1_retention_summary.json` and `godot/scripts/verification/ctw_wave1_integrated_harness.gd`.

### Mission / Narrative 01 — Scrap Job

Merged in PR #51 at `42ed53fad90463bd5bf8897a766e48d9da767940`.

Authored flow:

`Lira briefing -> Courier Bike -> tuner spoof -> customs-core extraction -> pursuit complication -> Signal Gate or long road -> interception/fast retry or escape -> 320-credit payoff + aftermath`

Mission 01 reuses the retained Courier Bike, tuner, Corroded Panel, pursuit, Signal Gate, fast retry, Memory Echo, camera/audio/vehicle authority and safe-area Mission HUD. Its runtime reconciles retained one-shot world state so authored prerequisites cannot strand progression.

### Mission / Narrative 02 — Civic Repossession

Merged in PR #53 at the current gameplay baseline `9dd9110ae261eea456daa4a27bff9f1fd9d3f273`; issue #52 is complete.

Authored flow:

`Mission 01 completion -> Mayor Burn handoff -> Scrap Hauler acquisition -> retained pursuit pressure -> Signal Gate or long road -> interception/fast retry or evasion -> Burn garage delivery -> 450-credit payoff + aftermath`

Mission 02 is a second narrow authored state machine, not a mission framework. It:

- requires the retained Scrap Hauler; Courier Bike use cannot satisfy acquisition;
- reuses controller-owned pursuit, interception, Signal Gate, fast retry, camera, radio and vehicle authority;
- takes over the single existing safe-area Mission HUD only after Mission 01 completes;
- creates only a bounded authored Burn-garage delivery marker;
- treats the 450 scrap credits as presentation payoff only, with no persistent economy;
- reconciles already-occupied Hauler state at the Mission 01 -> Mission 02 handoff so a previously consumed mount signal cannot strand the job;
- relocks on Full Replay while Mission 01 returns to its cold-start authored state.

The active gameplay chain is now:

`touch / desktop intent -> foot traversal or retained vehicle authority -> retained camera / feedback / radio -> authored mission objective -> pursuit / route pressure -> interception, retry or evasion -> authored payoff / next contact`

## Verification truth

Code-first verification remains the default production gate.

For Mission 02, the final PR head passed:

- production-scene Mission 01 + Mission 02 ordering and shared-HUD assertions;
- pre-mounted Scrap Hauler handoff reconciliation;
- mobile touch routing;
- desktop controls and alias ownership;
- desktop vehicle authority;
- interaction cancel behavior;
- Web export and static-hosting smoke;
- synthetic merge verification;
- the exact-head canonical 29-suite compatibility matrix.

The merged `main` tree also passed the normal Godot Web Playtest source/build/regression/static-hosting path. Do not replace these production-scene contracts with a parallel gameplay simulator.

## Perceptual truth / deferred gates

Functional/code verification and perceptual qualification remain separate:

- **Current camera baseline:** accepted as good-enough in owner play and retained. Do not reopen it without a concrete observed weakness.
- **Touch conditioner candidate:** physical-device A/B remains pending; the experiment is disabled, so the retained linear default is not blocked.
- **Physical audio playback:** not a blocking gate under the current code-first policy; lifecycle/mix/output contracts remain automated gates.
- **Fresh-player perceptual gate:** still pending and should not be represented as completed.

## Scope discipline

- Do not reopen retained camera, steering, vehicle-feel, pursuit or audio foundations for speculative polish.
- New work should target a concrete observed weakness or the next authored product milestone.
- Mission 01 and Mission 02 are precedent for **small authored adapters over retained production state**, not authority to build a generalized quest graph/database, persistent economy, inventory, combat, wanted-system rewrite, save-slot campaign framework, or unrelated infrastructure.
- Mayor Burn and other older browser-prototype material may be used as canon evidence, but new Godot work should adapt that canon to the retained production systems rather than copy obsolete mechanics literally.
- PR #44 remains deferred/non-retained camera experimentation.

## Next-state rule

Start every new increment from current `main`, current GitHub issue/PR/CI state, and existing canon/code evidence. Prefer the smallest next gameplay or narrative slice that creates visible player value while reusing retained authorities. Preserve code-first verification and add manual/perceptual play only when it answers a genuine feel question rather than as a routine merge bottleneck.

`WAYFINDER_MAP.md` remains a historical architecture map and is not the live status tracker.
