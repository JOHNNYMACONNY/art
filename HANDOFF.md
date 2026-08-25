# HANDOFF.md — Current Product Continuity

**Status:** `MISSIONS_01_02_03_MERGED__CODE_VERIFIED__DESIGN_STAGE_READY`  
**Current gameplay baseline:** `b22044670aee70ec5d349c6ac094f7b6d8323992`  
**Immutable Feel baseline:** `09fa2b0ab8aebc8a2ae54b989bffad7720503e48`  
**Engine:** Godot 4.7.1 Stable

## Current product state

The retained Chinatown-Wars-style Feel foundation now supports three connected authored crime/narrative jobs in the production Godot slice. Mission work remains deliberately specific and layered over retained gameplay authorities; there is still no generalized quest framework.

**Gameplay/world production is intentionally paused at the Visual Direction / Concept Art gate.** Do not begin Gears District expansion until that visual-direction milestone establishes the district and graphic-design rules that the map should implement. Product direction anchor: issue #55.

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

Merged in PR #53 at `9dd9110ae261eea456daa4a27bff9f1fd9d3f273`; issue #52 is complete.

Authored flow:

`Mission 01 completion -> Mayor Burn handoff -> Scrap Hauler acquisition -> retained pursuit pressure -> Signal Gate or long road -> interception/fast retry or evasion -> Burn garage delivery -> 450-credit presentation payoff + aftermath`

Mission 02 is a second narrow authored state machine, not a mission framework. It:

- requires the retained Scrap Hauler; Courier Bike use cannot satisfy acquisition;
- reuses controller-owned pursuit, interception, Signal Gate, fast retry, camera, radio and vehicle authority;
- takes over the single existing safe-area Mission HUD only after Mission 01 completes;
- creates only a bounded authored Burn-garage delivery marker;
- treats the 450 scrap credits as presentation payoff only, with no persistent economy;
- reconciles already-occupied Hauler state at the Mission 01 -> Mission 02 handoff so a previously consumed mount signal cannot strand the job;
- relocks on Full Replay while Mission 01 returns to its cold-start authored state.

### Mission / Narrative 03 — The City That Forgot

Merged in PR #57 at the current gameplay baseline `b22044670aee70ec5d349c6ac094f7b6d8323992`; issue #56 is complete.

Authored flow:

`Civic Repossession completion -> Sister Kael handoff -> reach Silent Core -> retained Action interaction -> authored HS-7 Memory Echo -> fresh retained disturbance/pursuit -> interception/fast retry or evasion -> narrative aftermath`

Mission 03 adds a lore/HS-7 escalation without introducing a second delivery job or a new gameplay framework. It:

- unlocks only after Civic Repossession reaches COMPLETE;
- takes over the same safe-area Mission HUD after the Mayor Burn payoff has had a complete presentation frame;
- adds one bounded functional `SilentCoreInteractable` placeholder in the current slice and routes activation through retained target arbitration / Action ownership;
- extends the retained `MemoryEchoController` with a validated authored-payload trigger instead of creating a parallel HS-7 system;
- preserves Mission 01 extraction Echo behavior and uses `prepare_next_echo()` for a later same-replay Echo, while `reset_echo()` remains the authoritative Full Replay reset that clears cumulative state;
- does not consume Civic Repossession's stale terminal `EVADED` pursuit state as its own success; Mission 03 waits until a fresh disturbance/pursuit has been observed before accepting interception/evasion outcomes;
- leaves root pursuit/interception/retry/evasion authority in the retained production controller;
- completes with narrative aftermath only and introduces no persistent economy;
- is composed as a peer runtime by the production scene; Mission 02 has no forward composition knowledge of Mission 03;
- relocks on Full Replay and returns HUD ownership to Mission 01 cold start.

The active authored chain is now:

`Lira scrap job -> Mayor Burn civic repossession -> Sister Kael / Silent Core memory reveal`

The retained gameplay chain remains:

`touch / desktop intent -> foot traversal or retained vehicle authority -> retained camera / feedback / radio -> authored mission objective -> interaction / pursuit / route pressure -> interception, retry or evasion -> authored payoff / next contact`

## Verification truth

Code-first verification remains the default production gate.

Mission 03 was developed and repaired through explicit RED -> GREEN cycles. Important integration/review findings included:

- production runtime missing from the real scene;
- prior Mission 02 `EVADED` state crossing the Mission 02 -> Mission 03 pursuit boundary;
- misuse of the authoritative Echo replay reset for a later same-campaign Echo;
- Mission 02 having forward composition knowledge of Mission 03.

Each finding received a focused failing contract before repair.

Final Mission 03 evidence:

- frozen branch head `c9055334103bfb68be3833d9f39220963d666160`;
- branch exact-head run #382 / `32902198301`: mobile touch routing, desktop controls, alias ownership, vehicle authority, interaction cancel, Web export and static-hosting smoke PASS;
- PR run #383 / `32902374997`: literal PR head PASS, synthetic merge PASS, current camera contracts PASS and canonical 29-suite compatibility matrix PASS;
- squash merge PR #57 -> gameplay `main` `b22044670aee70ec5d349c6ac094f7b6d8323992`;
- post-merge run #384 / `32902694060`: exact-main mobile/desktop regressions, Web export and static-hosting smoke PASS.

Do not replace these production-scene contracts with a parallel gameplay simulator.

## Perceptual truth / deferred gates

Functional/code verification and perceptual qualification remain separate:

- **Current camera baseline:** accepted as good-enough in owner play and retained. Do not reopen it without a concrete observed weakness.
- **Touch conditioner candidate:** physical-device A/B remains pending; the experiment is disabled, so the retained linear default is not blocked.
- **Physical audio playback:** not a blocking gate under the current code-first policy; lifecycle/mix/output contracts remain automated gates.
- **Fresh-player perceptual gate:** still pending and should not be represented as completed.
- **Mission 03 visual presentation:** functional placeholders are code-verified, not final art direction.

## Scope discipline

- Do not reopen retained camera, steering, vehicle-feel, pursuit or audio foundations for speculative polish.
- Mission 01/02/03 are precedent for **small authored adapters over retained production state**, not authority to build a generalized quest graph/database, persistent economy, inventory, combat, wanted-system rewrite, save-slot campaign framework, or unrelated infrastructure.
- Mayor Burn, Lira, Sister Kael, Echotel, Silent Core and other older browser-prototype material may be used as canon evidence, but new Godot work should adapt that canon to retained production systems rather than copy obsolete mechanics literally.
- PR #44 remains deferred/non-retained camera experimentation.
- Do not turn the current functional Silent Core placeholder into assumed final visual canon before the design stage.

## Current production gate — Visual Direction / Concept Art

The next milestone is **not another gameplay ticket and not Gears District implementation yet**. The design stage should establish a usable visual system for the next world-production phase.

Resolve and approve, at minimum:

- Gears District overall identity and visual thesis;
- architecture / street / alley / industrial-block grammar that works from the retained elevated 3/4 camera;
- fake civic, municipal, commercial and criminal graphic language: signage, logos, warnings, vehicle markings, billboards and environmental satire;
- palette, materials, lighting and weather language for day / night / rain;
- HUD / mission typography and graphic-design relationship to the world without replacing the retained functional UI contract prematurely;
- vehicle, prop and pedestrian silhouette direction where it affects world readability;
- representative key-location concepts: current scrapyard, Mayor Burn's garage, Sister Kael / Silent Core shrine, one industrial intersection and one commercial street;
- explicit distinction between approved visual canon and provisional exploration.

Concept art should produce concrete art/environment/UI rules that engineering can implement. It should not merely produce attractive standalone images.

## After the design gate

Once the visual-direction package is approved, return to the autonomous development loop and create a just-in-time implementation ticket for **Open World Expansion 01 — Gears District**.

The expansion should:

- make the current yard one recognizable location inside a larger contiguous district;
- prioritize dense useful streets, alleys, industrial blocks, intersections, alternate routes and mission destinations over empty acreage;
- preserve retained touch/desktop controls, camera, vehicle feel, pursuit, Signal Gate/route authority, interaction ownership and mission compatibility;
- use the approved visual rules as implementation constraints;
- be verified incrementally before new missions exploit the expanded geography.

## Next-state rule

Start every future implementation increment from current `main`, current GitHub issue/PR/CI state, existing canon/code evidence, and the approved design package. Prefer the smallest highest-value visible product increment. Manual/perceptual play is added only when it answers a genuine feel or visual-readability question rather than as a routine merge bottleneck.

`WAYFINDER_MAP.md` remains a historical architecture map and is not the live status tracker.
