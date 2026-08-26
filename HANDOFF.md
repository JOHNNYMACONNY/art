# HANDOFF.md — Current Product Continuity

**Status:** `GEARS_FOUNDATION_01A_01D_MERGED__CODE_VERIFIED__PUBLIC_PLAYTEST_CURRENT__VISUAL_PERF_DEBT_DEFERRED`  
**Current gameplay/world baseline:** `b2ac20fb09bb8ee9188525d6cf4474adddd31ad7`  
**Immutable Feel baseline:** `09fa2b0ab8aebc8a2ae54b989bffad7720503e48`  
**Engine:** Godot 4.7.1 Stable

## Current product state

The retained Chinatown-Wars-style Feel foundation, three connected authored missions, approved Gears visual direction, and the first bounded Gears world-production foundation are now integrated in the production Godot slice.

The former **Visual Direction / Concept Art gate is complete**. Approved creative truth lives under `docs/visual_direction/`, especially:

- `README.md`;
- `REFERENCE_ATLAS.md`;
- `GEARS_DISTRICT_VISUAL_DIRECTION_APPROVAL.md`;
- `GEARS_DISTRICT_HUMANOID_BOT_VISUAL_FAMILY_APPROVAL.md`;
- `GEARS_DISTRICT_VISUAL_DIRECTION_V2_CONVERGENCE.md` where later approved location language is relevant.

Approved direction: **Civic Salvage Palimpsest / Industrial Cel-Shaded Near Future**. Humanoid bots are an approved supporting family, not a requirement for every increment.

The current yard is no longer the only production geography. It now connects into one real Gears production block with a primary industrial road/intersection, alternate service alley/rejoin, commercial and industrial frontage, Mayor Burn's authored garage destination, and a physically reachable Silent Core infrastructure pocket.

Do **not** continue multiplying acreage by default. The product-direction anchor in issue #55 says that after the district foundation, prefer authored missions/world events that exploit the expanded geography before expanding the map again.

## Retained Feel foundation

| Ticket | Candidate | Disposition | Production state |
|---|---|---|---|
| #12 | Touch steering conditioner | **PENDING** | Linear normalized touch steering remains the default. The `0.06` radial deadzone / `1.5` response-power experiment remains disabled pending physical touch A/B. |
| #13 | Camera occlusion cutaway experiment | **REVERTED** | The existing dynamic elevated 3/4 Chinatown-Wars-style camera follow remains retained. PR #44 is deferred experimentation, not unfinished camera work. |
| #14 | Vehicle traction, impact and audio feedback | **RETAINED** | Telemetry-driven engine/load, traction/recovery, scaled impact output and priority ducking remain active. |
| #15 | Fast pursuit retry | **RETAINED** | Retry preserves solved setup and returns directly to the pursuit loop. |
| #16 | Bounded pursuer interception | **RETAINED** | Observable-velocity destination prediction remains enabled; authored Signal Gate detours retain authority. |

Do not reopen camera, steering, vehicle feel, pursuit, input, radio, audio, retry, or interaction ownership for speculative polish. Require a concrete observed weakness.

## Authored mission chain

The active authored chain remains:

`Lira scrap job -> Mayor Burn civic repossession -> Sister Kael / Silent Core memory reveal`

The retained gameplay chain remains:

`touch / desktop intent -> foot traversal or retained vehicle authority -> retained camera / feedback / radio -> authored objective -> interaction / pursuit / route pressure -> interception, retry or evasion -> authored payoff / next contact`

### Mission / Narrative 01 — Scrap Job

Merged in PR #51 at `42ed53fad90463bd5bf8897a766e48d9da767940`.

Authored flow:

`Lira briefing -> Courier Bike -> tuner spoof -> customs-core extraction -> pursuit complication -> Signal Gate or long road -> interception/fast retry or escape -> 320-credit payoff + aftermath`

Mission 01 remains a narrow authored state machine over retained Bike, tuner, Corroded Panel, pursuit, Signal Gate, fast retry, Memory Echo, camera/audio/vehicle and Mission HUD authorities.

### Mission / Narrative 02 — Civic Repossession

Original mission implementation merged in PR #53. Open World Expansion 01C later replaced its old in-yard delivery placeholder with the authored Gears destination.

Current authored flow:

`Mission 01 completion -> Mayor Burn handoff -> Scrap Hauler acquisition -> retained pursuit pressure -> Signal Gate or long road -> interception/fast retry or evasion -> authored Burn garage delivery -> 450-credit presentation payoff + aftermath`

Current production facts:

- the retained `CivicRepossessionRuntime` still owns only the thin Mission 02 adapter;
- its delivery zone resolves to `GearsDistrictSlice01B/MissionDestinationSocket` when production geography is present;
- the old `(7, 0.08, 8)` position survives only as an isolated-fixture fallback;
- Mayor Burn's garage is authored under the existing commercial frontage with no new gameplay state machine;
- the service alley retains at least 3.2 m effective clearance for the 1.8 m Scrap Hauler;
- Mission 01/03 composition boundaries remain unchanged.

### Mission / Narrative 03 — The City That Forgot

Original mission implementation merged in PR #57. Open World Expansion 01D later replaced its hard-coded in-yard Silent Core placeholder with an authored Gears infrastructure destination.

Current authored flow:

`Civic Repossession completion -> Sister Kael handoff -> reach Silent Core infrastructure pocket -> retained Action interaction -> authored HS-7 Memory Echo -> fresh retained disturbance/pursuit -> interception/fast retry or evasion -> narrative aftermath`

Current production facts:

- Mission 03 still uses the same `LOCKED -> REACH_SILENT_CORE -> ECHO_ACTIVE -> ESCAPE / FAILED -> COMPLETE` state model;
- the retained Action target arbitration remains authoritative;
- the retained `MemoryEchoController`, authored Echo payload, pursuit handoff, fast retry and Full Replay behavior are unchanged;
- the runtime Silent Core resolves to `GearsDistrictSlice01B/SilentCoreSite/SilentCoreSocket` when production geography is present;
- the old `(8, 0.4, -8)` position survives only as an isolated-fixture fallback;
- the Core is now a restrained toon-shaded utility module rather than a generic glowing cylinder;
- the site is ordinary obsolete telecom/relay infrastructure with removed asset-plate history, maintenance cues and sparse HS-7 cyan rather than fantasy-shrine spectacle;
- the site is physically reachable through a two-piece on-foot maintenance apron with stable >=0.25 m ground overlaps;
- no Sister Kael character model was added; existing authored narrative presentation remains authoritative.

## Approved Gears world foundation

### 01A — In-engine visual style proof

Issue #60 / PR #63 proved the approved direction in the real Godot slice at the retained 32-degree elevated 3/4 camera.

Exact reviewed candidate: `7302d2eb05b1e86eefb88c1ee5f8e10ac2852cdf`.

The proof established:

- lightweight toon treatment plus selective contours;
- stacked mixed-use salvage architecture;
- primary / shortcut route hierarchy;
- municipal, commercial, aftermarket and asset-marking graphic families;
- restrained practical day/dusk hierarchy;
- treated Runner, Courier Bike, Scrap Hauler, Pursuer, worker, utility robot and interactable families;
- bounded mesh/outline/light budgets;
- no full-district production inside the proof.

Required retained-camera screenshots and exact candidate desktop render telemetry were not captured because the candidate artifact was not deployable through the available verification surface at the time. The owner explicitly accepted this as **verification debt**, not as proof that the perceptual/performance gate had happened.

### 01B — First real production block

PR #64 merged the first contiguous Gears production geography; its squash result became `8297f5ae54d2b66348620b25feecff6c754b988a`.

Production topology:

`retained yard north edge -> industrial intersection / primary road -> north continuation`

with an alternate:

`intersection -> service alley -> north connector -> primary road`

The block includes real collision, one commercial frontage, one industrial frontage, a passive mission destination socket and a temporary finite-slice edge barrier. It deliberately does not introduce a traffic system, generalized route framework, mission framework, camera changes, or district-wide content pass.

The 01B introspection contract now reports both its historical base budget and current cumulative totals so later additive authored locations do not masquerade as regressions to the original 01B budget.

### 01C — Mayor Burn garage integration

PR #65 merged at `133ea941f7766a4c431e292628be4a57be1eb5e8`.

It:

- authored Mayor Burn's garage identity into the existing commercial frontage;
- retargeted Mission 02's existing return-zone adapter to the production mission socket;
- added no new mission phase, destination framework, acreage, local light layer or garage collision;
- repaired an inherited service-alley divider placement so effective Hauler clearance is ~3.2 m.

### 01D — Silent Core infrastructure integration

PR #66 exact reviewed head: `3ef4597a6da3a61771e64406b584e67ceaae0ca3`.  
Squash merge / current `main`: `b2ac20fb09bb8ee9188525d6cf4474adddd31ad7`.

It:

- authored a quiet Silent Core utility/relay pocket inside existing 01B geography;
- added one passive `SilentCoreSocket`;
- moved the production Mission 03 interactable to that socket while preserving a fixture-only legacy fallback;
- replaced the generic glowing-cylinder marker with four restrained toon-shaded utility meshes;
- added exactly two ground-only maintenance-apron colliders so the on-foot destination is genuinely reachable;
- requires >=0.25 m overlap at intersection -> walkway and walkway -> site-pad seams;
- added no road acreage, local lights, new mission phases, Echo system, pursuit authority, input/UI framework, economy or generalized destination system.

## Current verification truth

Code-first verification remains the default production gate.

For 01D, the final frozen exact-head evidence at `3ef4597a6da3a61771e64406b584e67ceaae0ca3` was:

- Camera Feel 30 PR run #94 / `32959370958`: **PASS**;
- Godot Web Playtest push run #477 / `32959366935`: **PASS**;
- Godot Web Playtest PR run #478 / `32959370953`: exact-head Web artifact, synthetic-merge artifact and canonical compatibility matrix **PASS**;
- fresh frozen review: **Standards PASS / Spec PASS**.

Post-merge exact-main evidence at `b2ac20fb09bb8ee9188525d6cf4474adddd31ad7`:

- Camera Feel 30 main run #95 / `32959651678`: **PASS**;
- Godot Web Playtest main run #479 / `32959651618`: **PASS**;
- non-production `playtest-web/PLAYTEST_BUILD.txt`: exact `b2ac20fb09bb8ee9188525d6cf4474adddd31ad7`.

Important RED -> GREEN history in 01D included a real review finding: the first Silent Core pocket was visually authored but outside all existing ground colliders. The repair added the smallest two-piece maintenance apron and strengthened the executable contract to prove physical ground continuity with stable overlap margins. A later review also grounded the runtime marker instead of leaving its visual mass hovering above the pad.

Do not replace these production-scene contracts with a parallel gameplay simulator.

## Perceptual / performance verification debt

Functional/code verification and perceptual qualification remain separate.

Still deferred and **not to be represented as completed**:

- fresh retained-camera captures of representative Gears traversal, Bike, Pursuer/chase, alternate route, signage/landmark, Burn garage, Silent Core, and day/dusk states;
- candidate desktop average/P95 frame-time plus draw/object cost measured against the retained baseline;
- broader fresh-player perceptual qualification;
- physical touch-conditioner A/B;
- human/windowed audio listening where a real listening question exists.

The owner explicitly chose the momentum policy: small reversible increments may merge with this verification debt visible, but the debt must be resolved **before materially multiplying district acreage/content based on unobserved readability/performance assumptions**.

## Scope discipline

- Do not reopen retained camera, steering, vehicle feel, pursuit, audio, Signal Gate, target arbitration or replay foundations without an observed weakness.
- Mission 01/02/03 remain precedent for **small authored adapters over retained production state**, not permission to build a generalized quest graph/database, persistent economy, inventory, combat, wanted-system rewrite, save-slot campaign framework, destination framework or unrelated infrastructure.
- Preserve approved visual canon; do not reinterpret reference material against the approved direction.
- Keep Issue #60's `GearsStyleProof` separate from production geography; it remains a bounded proof/foundation layer rather than the district scene itself.
- Prefer useful density and authored destinations over empty acreage.
- Do not add more Gears acreage as the automatic next step.

## Current product direction

Issue #55 remains the durable product-intent anchor even though its old “stop before Gears implementation” snapshot is now historically superseded by the approved visual package and merged 01A-01D work.

Its still-current sequencing rule is the important one:

> after the district foundation, prefer new authored missions / world events that exploit the expanded geography before expanding the map again.

Therefore the next autonomous increment should be selected from current `main` by highest visible product value and should normally be one of:

1. a small authored mission/world event that makes meaningful use of the existing road/intersection/alley/Burn/Silent-Core geography without creating a generalized framework; or
2. a dedicated verification-debt checkpoint when the runtime/browser capability needed for retained-camera capture and measured performance is available.

Do not choose historical open tickets merely because they remain open. Several are retained experiments, human/perceptual gates or already-landed foundations whose issue state is not the live product order.

## Next-state rule

On every future autonomous continuation:

1. refresh exact `main`, current PR/issue/CI/public-playtest state;
2. read the approved visual-direction canon before visual/world-sensitive work;
3. compare current runtime truth against issue #55's product intent;
4. select the smallest highest-value visible increment;
5. create/refine its just-in-time in-repo spec only when it becomes current;
6. run `SPEC -> RED -> GREEN -> exact-head VERIFY -> frozen Standards+Spec REVIEW -> REPAIR if needed -> MERGE -> exact-main VERIFY`;
7. update continuity only after verified changes land;
8. keep deferred perceptual/performance debt explicit rather than silently upgrading it to PASS.

`WAYFINDER_MAP.md` remains a historical architecture map and is not the live status tracker.
