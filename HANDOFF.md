# HANDOFF.md — Current Product Continuity

**Status:** `BURNSIDE_PRODUCTION_01_02_03_MERGED_VERIFIED__POST_PRODUCTION_03_REEVALUATION`  
**Verified production gameplay baseline:** `afd1db546b04221c7fb4b222b9f77311acd6d3ea`  
**Immutable Feel baseline:** `09fa2b0ab8aebc8a2ae54b989bffad7720503e48`  
**Engine:** Godot 4.7.1 Stable

> This file is continuity, not implementation authority. Refresh remote `main`, open PRs/issues and live CI before repo-sensitive work. A later docs-only continuity commit may make repository HEAD newer than the verified gameplay baseline above without changing runnable gameplay.

## Current product state

The production Godot slice now combines the retained Chinatown-Wars-style Feel foundation, three authored missions, approved Gears visual direction, the qualified first Gears production block, one bounded FB-13 world event, a bounded Heat-1 open-world Wanted loop, bounded local Field Hacking over civic reporting, and the first authored mission composition of those city systems.

Approved visual direction remains **Civic Salvage Palimpsest / Industrial Cel-Shaded Near Future**. Creative authority lives under `docs/visual_direction/`; issue #118 remains the canonical downstream Burnside player-facing production contract.

Do **not** default to more acreage. Current value comes from exploiting existing geography and joining already-proven systems into authored player situations before expanding the map.

## Burnside Production 01 — Wanted / Contact-Search

Issue #119 / PR #121: **COMPLETE / MERGED / VERIFIED**.

Merged production baseline for that slice:

`4e62e198508393821bf902da681daa776d1d8545`

Implemented free-roam loop:

`INCIDENT -> REPORT -> HEAT 1 + CONTACT -> PHYSICAL RESPONSE -> CONTACT LOSS -> SEARCH -> REACQUIRE or EVADE -> CLEAR FREE ROAM`

Retained truths:

- Heat 1 is real production behavior;
- Contact and Search are distinct;
- Search retains Heat and stored last-known information;
- hidden movement does not magically update authority knowledge;
- reacquisition requires legitimate direct observation;
- invalid/suppressed Report creates no Wanted state;
- the physical pursuer remains a response asset rather than omniscient knowledge authority;
- Wanted HUD uses the existing upper-right information lane;
- no Heat 2–5 content, generalized police director, witnesses, surveillance network or Wanted persistence was added.

Production 03 later migrated **Mission 02 only** from its historical parallel pursuit into this open-world Wanted authority. Mission 01 and Mission 03 retain their historical pursuit behavior.

## Burnside Production 02 — Field Hacking / Report Suppression

Issue #122 / PR #123: **COMPLETE / MERGED / VERIFIED**.

Frozen reviewed feature head:

`0567635aeb48a09e8a2b174b2eee125f71d1b492`

Signed merge / verified production gameplay baseline for that slice:

`7a5c36598c6d950d832f71c42e41eaacfb7b75b2`

Implemented free-roam composition:

`DISCOVER LOCAL SERVICE ACCESS -> JAM REPORT LINK -> CIVIC INCIDENT -> ALARM FAULT -> REPORT SUPPRESSED -> NO WANTED`

Recovery composition:

`SERVICE RESTORE -> SAME CIVIC INCIDENT -> REPORT SENT -> HEAT 1 + CONTACT`

Player-facing / architectural truths:

- the Access Path is physical and local at the existing Civic Utility infrastructure;
- execution is quick after legitimate access — **Access Is the Puzzle**;
- the manipulation is bounded Interference, not a universal hack mode;
- successful interference disables only the existing Civic Service Alarm's **future Report capability**;
- `WantedAuthority` is not directly mutated by hacking;
- an already-valid Wanted state cannot be erased by hacking;
- replay/service recovery deterministically restores the alarm and Access Path baseline;
- local states are readable in-world: `SERVICE TAP`, `REPORT LINK JAMMED`, `REPORT SENT`, `ALARM FAULT`;
- no generalized hacking framework, cyber minigame, remote omnipotent targeting, surveillance network, Heat escalation, companion-command framework, generalized crime/event bus, minimap or new acreage was added.

Production 03 intentionally reused this same report/interference seam inside Mission 02; it did not generalize hacking.

## Burnside Production 03 — Civic Repossession / Wanted-Field-Hacking Composition

Issue #124 / PR #125: **COMPLETE / MERGED / VERIFIED**.

Frozen reviewed feature head:

`3a2e93013b2befbb13edc652109655b66dde30a3`

Exact merge / verified production gameplay baseline:

`afd1db546b04221c7fb4b222b9f77311acd6d3ea`

Implemented authored mission composition:

Loud path:

`MISSION 02 -> STEAL SCRAP HAULER -> CIVIC REPORT SENT -> HEAT 1 + CONTACT -> CONTACT LOSS -> SEARCH -> EVADE -> GARAGE DELIVERY`

Prepared / hacked path:

`MISSION 02 -> JAM LOCAL CIVIC REPORT LINK -> STEAL SCRAP HAULER -> REPORT SUPPRESSED -> CLEAN TAKE -> GARAGE DELIVERY`

Production truths:

- Mission 02 no longer calls its historical parallel `trigger_disturbance_alert()` chase;
- Mission 02 requests the existing civic Report path through a narrow `BurnsideWantedRuntime` adapter and observes existing Wanted state;
- Mission 02 does not directly own or mutate `WantedAuthority`;
- a clean take advances directly to delivery when the bounded civic report path leaves authority CLEAR;
- a valid Report produces ordinary Heat 1 / Contact and Mission 02 remains in ESCAPE until legitimate open-world Evasion;
- pre-existing Wanted survives Mission 02 start / Hauler theft;
- mission completion does not clear valid Heat, Contact, Search, Recognition or authority knowledge;
- Mission 01 and Mission 03 retain their historical pursuit behavior;
- no save-schema, camera, audio-system, acreage, Heat 2–5, witness/surveillance, generalized crime, generalized mission or generalized hacking changes were introduced.

### Review repair

Frozen review found a real one-shot alarm edge case:

`JAM REPORT -> TRIP ALARM WHILE JAMMED -> ALARM CONSUMED/FAULTED -> TAKE HAULER`

The mission could previously strand in ESCAPE even though authority remained CLEAR. The repair treats CLEAR authority after the bounded report attempt as a valid clean take even when earlier sandbox play already consumed the suppressed one-shot alarm.

The dedicated `civic_repossession_pretriggered_suppression_test.gd` regression is retained in the Production-03 gate.

## Production 03 verification truth

### Exact frozen feature head

At exact feature head `3a2e93013b2befbb13edc652109655b66dde30a3`:

- review-repair pre-triggered suppression regression: **PASS**;
- Mission 02 model contract: **PASS**;
- Production-03 real-scene Mission/Wanted composition tracer: **PASS**;
- retained Production-02 Field Hacking report-suppression tracer: **PASS**;
- retained Production-01 real-scene Heat-1 tracer: **PASS**;
- windowed Mission-02 loud + hacked composition proof: **PASS**;
- retained Burnside Wanted 119 gate: **PASS**;
- literal-head browser/Web gate: **PASS**;
- synthetic-merge browser/Web gate: **PASS**;
- current camera contracts: **PASS**;
- canonical **29-suite** compatibility matrix: **PASS**;
- mobile touch routing, desktop controls, desktop alias ownership, desktop vehicle authority and desktop interaction-cancel regressions: **PASS**;
- frozen Standards + #124 review: **PASS** after the review repair; all blocking review threads resolved.

Rendered proof remained perceptually acceptable after the repair because the production change did not alter presentation. The visible loud state still reads `CIVIC REPOSSESSION` + `REPORT SENT` + `HEAT 1 // CONTACT`; the hacked state reads `REPORT LINK JAMMED` + `ALARM FAULT` + `CLEAN TAKE` with no Wanted HUD.

### Exact-main evidence

Merge commit:

`afd1db546b04221c7fb4b222b9f77311acd6d3ea`

Burnside Production 03 main push run `33593475464` on that exact SHA:

- exact source checkout: **PASS**;
- Mission 02 model contract: **PASS**;
- pre-triggered suppressed-report regression: **PASS**;
- Production-03 mission/Wanted composition tracer: **PASS**;
- retained Field Hacking tracer: **PASS**;
- retained Heat-1 tracer: **PASS**;
- windowed Mission-02 composition capture: **PASS**;
- rendered proof artifact upload: **PASS**.

Godot Web Playtest main push run `33593475526` on that exact SHA:

- exact source checkout: **PASS**;
- mobile touch routing: **PASS**;
- desktop controls: **PASS**;
- desktop alias ownership: **PASS**;
- desktop vehicle authority: **PASS**;
- desktop interaction cancel: **PASS**;
- Web export: **PASS**;
- static hosting smoke: **PASS**;
- browser artifact upload: **PASS**;
- source revision stamp verification: **PASS**;
- public `playtest-web` publication: **PASS**.

Public branch source stamp:

`playtest-web/PLAYTEST_BUILD.txt = afd1db546b04221c7fb4b222b9f77311acd6d3ea`

The PR-only compatibility matrix is intentionally skipped on main pushes; it passed on the exact frozen feature head before integration, alongside the literal-head and synthetic-merge Web gates.

## Retained production foundations

These remain implemented and should not be recreated because older roadmaps describe them historically:

- retained Feel tickets #12–#16 baseline behaviors and their current verified descendants;
- Mission 01 — Lira scrap job;
- Mission 02 — Mayor Burn civic repossession, now composed with ordinary open-world Wanted + Field Hacking reporting;
- Mission 03 — Sister Kael / Silent Core memory reveal, retaining its historical authored pursuit behavior;
- Open World Expansion 01A–01D / PRs #63–#66: approved visual proof, first contiguous Gears block, Mayor Burn garage, Silent Core integration;
- World Event 01 / PR #68: bounded FB-13 infrastructure thrum at existing industrial frontage;
- Issue #89 / Open World Expansion 01E: `VISUAL_PERF_CHECKPOINT_PASS`.

The yard connects into one real Gears production block with a primary industrial route/intersection, alternate service alley/rejoin, commercial and industrial frontage, Mayor Burn's garage, and a physically reachable Silent Core pocket.

FB-13 / HS-7 remain authored persistent companions in canon; World Event 01 is not precedent for a generalized companion framework.

## Verification / human-gate debt that remains explicit

Functional/code verification and perceptual qualification remain separate.

Still deferred and **not** to be represented as completed:

- native desktop average/P95 frame-time qualification on dedicated desktop hardware;
- broader fresh-player perceptual qualification;
- physical touch-conditioner A/B before changing the touch steering default;
- human/windowed listening for FB-13 thrum or any other question whose truth is actual playback quality;
- real mobile performance until measured on hardware.

Small reversible production increments may continue with this debt visible when they do not depend on those unanswered questions.

## Scope discipline

- Do not reopen retained camera, steering, vehicle feel, pursuit, audio, Signal Gate, interaction ownership or replay foundations without an observed weakness.
- Mission 01/02/03 are precedent for small authored adapters over retained production state, not a generalized quest framework.
- World Event 01 is precedent for a small local authored reaction, not a generalized event bus or companion AI.
- Production 01 is precedent for bounded information-causal Wanted behavior, not a generalized police simulation.
- Production 02 is precedent for **Access Path -> contextual Interference -> changed future consequence**, not universal hacking.
- Production 03 is precedent for authored missions colliding with ordinary city systems without mission-owned authority resets or menu-scripted branches.
- Preserve approved visual canon.
- Prefer useful density and authored systemic situations over empty acreage.
- Keep parallel Audio Production isolated unless a current gameplay slice has a concrete integration need.

## Current routing

Issue #55 is the durable product-direction anchor and should reflect this post-Production-03 baseline.

`START_HERE.md` remains directionally current and does **not** need a changelog update:

- **ACTIVE:** Audio Production in parallel; project orchestration/continuity;
- **NEXT:** authored gameplay on existing Gears geography, selected from fresh repo/product truth;
- **DEFERRED:** automatic map expansion and broad framework work.

There is **no authorized Production 04 implementation ticket yet**. Do not manufacture one from numbering momentum.

Open PR #44 remains a deferred camera-occlusion experiment and must not be mixed into the next production slice merely because it remains open.

## Next-state rule

The next production session should:

1. refresh exact `main`, open PRs/issues and live CI/public-playtest state;
2. read `START_HERE.md`, issue #55 and canonical production contract #118;
3. verify local repo/branch/HEAD/upstream/dirty state and concurrent Audio conflict surfaces before mutation;
4. compare the now-implemented Wanted + Field Hacking + Mission-02 composition against the remaining player-facing gaps in #118;
5. choose the smallest highest-value authored gameplay/systemic increment on existing Gears geography;
6. create exactly one just-in-time ticket only when that increment becomes current;
7. execute `SPEC -> RED -> GREEN -> exact-head VERIFY -> frozen Standards+Spec REVIEW -> REPAIR if needed -> MERGE -> exact-main VERIFY`;
8. update continuity only after verified changes land.

Create a new Wayfinder only if production exposes a genuinely new, foggy, multi-session cross-system design problem. Ordinary production remains downstream.

`WAYFINDER_MAP.md` remains historical architecture context, not the live status tracker.
