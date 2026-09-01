# HANDOFF.md — Current Product Continuity

**Status:** `BURNSIDE_PRODUCTION_01_02_MERGED_VERIFIED__POST_PRODUCTION_02_REEVALUATION`  
**Verified production gameplay baseline:** `7a5c36598c6d950d832f71c42e41eaacfb7b75b2`  
**Immutable Feel baseline:** `09fa2b0ab8aebc8a2ae54b989bffad7720503e48`  
**Engine:** Godot 4.7.1 Stable

> This file is continuity, not implementation authority. Refresh remote `main`, open PRs/issues and live CI before repo-sensitive work. A later docs-only continuity commit may make repository HEAD newer than the verified gameplay baseline above without changing runnable gameplay.

## Current product state

The production Godot slice now combines the retained Chinatown-Wars-style Feel foundation, three authored missions, approved Gears visual direction, the qualified first Gears production block, one bounded FB-13 world event, a bounded Heat-1 free-roam Wanted loop, and one bounded Field Hacking composition over that Wanted/reporting seam.

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
- retained Mission 01/02/03 pursuit behavior was not migrated into the open-world authority;
- Wanted HUD uses the existing upper-right information lane;
- no Heat 2–5 content, generalized police director, witnesses, surveillance network or Wanted persistence was added.

## Burnside Production 02 — Field Hacking / Report Suppression

Issue #122 / PR #123: **COMPLETE / MERGED / VERIFIED**.

Frozen reviewed feature head:

`0567635aeb48a09e8a2b174b2eee125f71d1b492`

Signed merge / verified production gameplay baseline:

`7a5c36598c6d950d832f71c42e41eaacfb7b75b2`

Implemented composition:

`DISCOVER LOCAL SERVICE ACCESS -> JAM REPORT LINK -> CIVIC INCIDENT -> ALARM FAULT -> REPORT SUPPRESSED -> NO WANTED`

Recovery composition:

`SERVICE RESTORE -> SAME CIVIC INCIDENT -> REPORT SENT -> HEAT 1 + CONTACT`

Player-facing / architectural truths:

- the Access Path is physical and local at the existing Civic Utility infrastructure;
- execution is quick after legitimate access — **Access Is the Puzzle**;
- the manipulation is bounded Interference, not a universal hack mode;
- the new `CivicReportAccess` service tap uses retained interaction arbitration;
- successful interference disables only the existing Civic Service Alarm's **future Report capability**;
- `WantedAuthority` was not changed for hacking;
- an already-valid Wanted state cannot be erased by hacking;
- replay/service recovery deterministically restores the alarm and Access Path baseline;
- local states are readable in-world: `SERVICE TAP`, `REPORT LINK JAMMED`, `REPORT SENT`, `ALARM FAULT`;
- retained missions, mission pursuit, camera, controls, vehicles, interaction ownership/cancel behavior, saves and Gears geography remain compatibility boundaries;
- no generalized hacking framework, cyber minigame, remote omnipotent targeting, surveillance network, Heat escalation, companion-command framework, generalized crime/event bus, minimap or new acreage was added.

Primary implementation files added/changed for Production 02:

- `godot/scripts/interactions/civic_report_access.gd`;
- `godot/scenes/interactions/civic_report_access.tscn`;
- `godot/scripts/world/wanted_heat1_runtime.gd`;
- local Civic Service Alarm presentation;
- Field Hacking contract/runtime proof and Wanted render-proof tests/workflow.

## Production 02 verification truth

### Intentional RED

The new Field Hacking contract was committed before implementation and failed for the intended missing behavior:

`Physical civic report Access Path is absent`

After initial GREEN, human visual review rejected the first rendered proof because the local civic status labels were technically present but too small at the retained production camera. A second intentional RED required readable world-space label scale and failed for the intended reason before the presentation repair.

### Frozen exact-head evidence

At exact feature head `0567635aeb48a09e8a2b174b2eee125f71d1b492`:

- Heat-1 knowledge contract: **PASS**;
- retained real-scene Heat-1 tracer: **PASS**;
- Field Hacking report-suppression tracer: **PASS**;
- Wanted HUD regression: **PASS**;
- retained desktop authority regression: **PASS**;
- windowed X11 runtime capture: **PASS**;
- visual inspection of hacked and restored frames: **PASS** after readability repair;
- mobile touch routing: **PASS**;
- desktop controls: **PASS**;
- desktop alias ownership: **PASS**;
- desktop vehicle authority: **PASS**;
- desktop interaction cancel: **PASS**;
- Web export + static hosting smoke + artifact upload: **PASS**.

PR #123 verification on the same frozen head:

- current camera contracts: **PASS**;
- canonical **29-suite** legacy compatibility matrix: **PASS**;
- literal-head browser/Web gate: **PASS**;
- synthetic-merge browser/Web gate: **PASS**;
- frozen Standards+Spec review: **PASS** with seven intended changed files and no scope leak.

### Exact-main evidence

Signed merge commit:

`7a5c36598c6d950d832f71c42e41eaacfb7b75b2`

Godot Web Playtest main push run `33567860268` on that exact SHA:

- verified source checkout: **PASS**;
- mobile touch routing: **PASS**;
- desktop controls: **PASS**;
- desktop alias ownership: **PASS**;
- desktop vehicle authority: **PASS**;
- desktop interaction cancel: **PASS**;
- Web export: **PASS**;
- static hosting smoke: **PASS**;
- browser artifact upload: **PASS**;
- public `playtest-web` publication: **PASS**.

Public branch source stamp:

`playtest-web/PLAYTEST_BUILD.txt = 7a5c36598c6d950d832f71c42e41eaacfb7b75b2`

The PR-only compatibility matrix is intentionally skipped on main pushes; it passed on the exact frozen feature head before integration.

## Retained production foundations

These remain implemented and should not be recreated because older roadmaps describe them historically:

- retained Feel tickets #12–#16: linear touch steering baseline, retained elevated camera, vehicle feedback, fast pursuit retry, bounded pursuer interception;
- Mission 01 — Lira scrap job;
- Mission 02 — Mayor Burn civic repossession, using the authored Gears garage destination;
- Mission 03 — Sister Kael / Silent Core memory reveal, using the authored Silent Core infrastructure pocket;
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
- Preserve approved visual canon.
- Prefer useful density and authored systemic situations over empty acreage.
- Keep parallel Audio Production isolated unless a current gameplay slice has a concrete integration need.

## Current routing

Issue #55 is the durable product-direction anchor and has been refreshed after Production 02.

`START_HERE.md` remains directionally current:

- **ACTIVE:** Audio Production in parallel; project orchestration/continuity;
- **NEXT:** authored gameplay on existing Gears geography, selected from fresh repo/product truth;
- **DEFERRED:** automatic map expansion and broad framework work.

There is **no authorized Production 03 implementation ticket yet**. Do not manufacture one from numbering momentum.

## Next-state rule

The next production session should:

1. refresh exact `main`, open PRs/issues and live CI/public-playtest state;
2. read `START_HERE.md`, issue #55 and canonical production contract #118;
3. verify local repo/branch/HEAD/upstream/dirty state and concurrent Audio conflict surfaces before mutation;
4. compare the now-implemented Wanted + Field Hacking compositions against the remaining player-facing gaps in #118;
5. choose the smallest highest-value authored gameplay/systemic increment on existing Gears geography;
6. create exactly one just-in-time ticket only when that increment becomes current;
7. execute `SPEC -> RED -> GREEN -> exact-head VERIFY -> frozen Standards+Spec REVIEW -> REPAIR if needed -> MERGE -> exact-main VERIFY`;
8. update continuity only after verified changes land.

Create a new Wayfinder only if production exposes a genuinely new, foggy, multi-session cross-system design problem. Ordinary production remains downstream.

`WAYFINDER_MAP.md` remains historical architecture context, not the live status tracker.