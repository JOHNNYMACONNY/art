# HANDOFF.md — Current Product Continuity

**Status:** `BURNSIDE_PRODUCTION_01_02_03_04_MERGED_VERIFIED__POST_PRODUCTION_04_REEVALUATION`  
**Verified production gameplay baseline:** `7605277d920b7877715d78687ccab16a69745b2f`  
**Immutable Feel baseline:** `09fa2b0ab8aebc8a2ae54b989bffad7720503e48`  
**Engine:** Godot 4.7.1 Stable

> This file is continuity, not implementation authority. Refresh remote `main`, open PRs/issues and live CI before repo-sensitive work. A docs-only continuity merge may make repository HEAD newer than the verified gameplay baseline above without changing runnable gameplay.

## Current product state

The production Godot slice now combines the retained Chinatown-Wars-style Feel foundation, three authored missions, approved Gears visual direction, the qualified first Gears production block, one bounded FB-13 world event, Heat-1 Wanted / Contact-Search, local Field Hacking over civic reporting, Mission-02 composition of those city systems, and one bounded player-reactive Gears work-zone ambient situation.

Approved visual direction remains **Civic Salvage Palimpsest / Industrial Cel-Shaded Near Future**. Issue #118 remains the canonical downstream Burnside player-facing production contract. Issue #55 is the durable current product-direction anchor.

Do **not** default to more acreage or generalized systems. Current value comes from adding high-impact missing player verbs to the existing Gears block and making already-proven systems collide.

## Production sequence — verified baselines

- **Production 01** — #119 / PR #121 — Open-World Wanted / Contact-Search: complete. Signed merged production baseline `4e62e198508393821bf902da681daa776d1d8545`.
- **Production 02** — #122 / PR #123 — Field Hacking / Report Suppression: complete. Verified gameplay baseline `7a5c36598c6d950d832f71c42e41eaacfb7b75b2`.
- **Production 03** — #124 / PR #125 — Civic Repossession / Wanted-Field-Hacking Composition: complete. Verified gameplay baseline `afd1db546b04221c7fb4b222b9f77311acd6d3ea`.
- **Production 04** — #127 / PR #129 — Gears Work-Zone / Player-Reactive Ambient Incident: gameplay merged, exact-main verified, public verified. Exact gameplay baseline `7605277d920b7877715d78687ccab16a69745b2f`.

## Retained systemic baseline

Wanted / authority knowledge:

`INCIDENT -> REPORT -> HEAT 1 + CONTACT -> PHYSICAL RESPONSE -> CONTACT LOSS -> SEARCH -> REACQUIRE or EVADE -> CLEAR FREE ROAM`

Field Hacking:

`DISCOVER LOCAL SERVICE ACCESS -> JAM REPORT LINK -> CIVIC INCIDENT -> ALARM FAULT -> REPORT SUPPRESSED -> NO WANTED`

with deterministic service recovery back to ordinary Report -> Heat 1 + Contact.

Mission 02 loud path:

`CIVIC REPOSSESSION -> TAKE SCRAP HAULER -> REPORT SENT -> HEAT 1 + CONTACT -> SEARCH / EVADE -> GARAGE DELIVERY`

Mission 02 prepared path:

`CIVIC REPOSSESSION -> JAM LOCAL REPORT LINK -> TAKE SCRAP HAULER -> REPORT SUPPRESSED -> CLEAN TAKE -> GARAGE DELIVERY`

Mission 01 and Mission 03 retain their historical authored pursuit behavior. Mission completion does not silently clear valid Wanted knowledge.

## Burnside Production 04 — verified player-facing result

Issue #127 / PR #129: **GAMEPLAY MERGED / EXACT-MAIN VERIFIED / PUBLIC VERIFIED**.

Original frozen gameplay candidate:

`21d18bb3f260b35c91e8283a8bb42efff0c05002`

Final reviewed PR head:

`9efc52a1a506e872cc7976adb10156a2d2ee87da`

Exact merge / verified production gameplay baseline:

`7605277d920b7877715d78687ccab16a69745b2f`

Routine:

`GEARS WORKER + UTILITY CRAWLER ROUTINE -> PLAYER PASSES / APPROACHES -> ACTORS NOTICE / YIELD -> ROUTINE RECOVERS`

Live civic reporting:

`HIGH-SPEED WORK-ZONE CLOSE CALL -> LOCAL ALARM / RETREAT -> REPORT SENT -> HEAT 1 + CONTACT`

Prepared Field Hacking:

`JAM REPORT LINK -> SAME CLOSE CALL -> LOCAL ALARM / RETREAT -> REPORT SUPPRESSED -> NO NEW WANTED`

### Production truths

- retained yard `ScrapWorker1`, `ScrapWorker2`, and `UtilityCrawler` remain present;
- one separate Gears worker/crawler pair lives in the authored industrial crossing;
- `GearsDistrictSlice01B.get_production_contract().owns_no_gameplay_authority == true` remains preserved;
- the incident runtime is a root-level sibling spatially anchored to `GearsDistrictSlice01B/IndustrialIntersection`;
- ordinary proximity/yielding does not create Wanted;
- reportable disruption requires a vehicle, horizontal speed >= 8.0 m/s, the bounded crossing corridor, <= 1.25 m actor clearance, and incident state `ROUTINE`;
- local actor alarm happens independently of whether the city successfully receives a Report;
- civic consequence goes only through existing `BurnsideWantedRuntime.request_civic_report()`;
- pre-existing Wanted survives and prevents a redundant second Report request;
- local incident recovery never clears Heat / Contact / Search / Recognition;
- Replay resets incident-local state without creating a second authority system;
- no generalized population, ambient scheduler, witness/crime architecture, traffic simulation, Heat 2–5, combat, save-schema, PR #44 camera work, or unrelated Audio Production scope entered Production 04.

### Mission-02 ordering compatibility

Production 04 can consume the same one-shot civic alarm used by Mission 02. The retained regression proves:

`JAM REPORT LINK -> WORK-ZONE SUPPRESSED REPORT -> LATER MISSION-02 HAULER THEFT -> CLEAN TAKE -> DELIVERY`

Mission 02 does not strand in ESCAPE after the shared alarm is consumed/faulted while jammed.

### Review repair

A fresh PR #129 review found one concrete CI-contract defect after the original freeze: the Production-04 workflow path filters omitted four directly depended-on scene files.

The repair at `9efc52a1a506e872cc7976adb10156a2d2ee87da` changed only `.github/workflows/burnside-production-04.yml`, adding these scene dependencies to both push and pull-request filters:

- `godot/scenes/prototype/scrap_test_block.tscn`;
- `godot/scenes/world/gears_district_slice_01b.tscn`;
- `godot/scenes/entities/scrap_worker.tscn`;
- `godot/scenes/entities/utility_crawler.tscn`.

Delta from original frozen gameplay candidate to final reviewed PR head: exactly **1 commit / 1 file / +8/-0**. No gameplay/runtime code changed. Fresh exact-head verification passed after the repair and the review thread was resolved.

## Production 04 verification truth

### Final exact PR head

At `9efc52a1a506e872cc7976adb10156a2d2ee87da`:

- Production-04 Gears work-zone tracer: **PASS**;
- Production-04 Mission-02 ordering regression: **PASS**;
- retained Production-03 pre-triggered suppression regression: **PASS**;
- retained Production-03 mission/Wanted composition: **PASS**;
- retained Production-02 Field-Hacking suppression: **PASS**;
- retained Production-01 Heat-1 tracer: **PASS**;
- windowed Gears work-zone proof + artifact upload: **PASS**;
- literal-head Web export/playtest: **PASS**;
- synthetic-merge Web export/playtest: **PASS**;
- mobile touch routing / desktop controls / alias ownership / vehicle authority / interaction cancel: **PASS**;
- current camera contracts: **PASS**;
- canonical 29-suite compatibility matrix: **PASS**;
- static hosting smoke: **PASS**;
- Frozen Standards + #127 exact-head review: **PASS** with no unresolved blocking threads.

### Exact-main evidence

Merge commit / gameplay baseline:

`7605277d920b7877715d78687ccab16a69745b2f`

Burnside Production 04 main push run `33605897520` on that exact SHA:

- exact source checkout: **PASS**;
- Gears work-zone tracer: **PASS**;
- Mission-02 ordering regression: **PASS**;
- retained Production-03 pre-triggered suppression: **PASS**;
- retained Production-03 mission/Wanted composition: **PASS**;
- retained Production-02 Field-Hacking tracer: **PASS**;
- retained Production-01 Heat-1 tracer: **PASS**;
- windowed Gears work-zone proof: **PASS**;
- rendered proof artifact upload: **PASS**.

Godot Web Playtest main push run `33605897717` on that exact SHA:

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

The canonical 29-suite matrix is intentionally PR-only on this workflow and was skipped on the main push after passing on the exact reviewed PR head.

Public branch source stamp:

`playtest-web/PLAYTEST_BUILD.txt = 7605277d920b7877715d78687ccab16a69745b2f`

## Post-Production-04 product re-evaluation

Production 04 closes the previous leading gap: the qualified Gears block now has a bounded local ambient situation that notices the player and composes with ordinary civic reporting, Wanted, and Field Hacking.

Fresh exact-main implementation sampling after the merge shows:

- `godot/scripts/player/` contains the retained `runner.gd` locomotion/mounting runtime; no production Health / Armor / weapon / physical-tool combat layer is currently represented there;
- the top-level Godot runtime has no dedicated combat script family;
- `godot/scripts/vehicles/` currently contains Courier Bike and Scrap Hauler runtimes, while the broader #118 Claimed Vehicle / condition / identity loop remains thin;
- Wanted + Field Hacking + Mission Sandbox + one player-reactive Ambient Incident are now materially represented, so another variant of those proofs has lower marginal player value.

### Leading investigation frontier

**Combat + physical-tool improvisation inside the existing Gears city consequence loop** is the current leading investigation frontier.

This is **not authorized Production 05 scope**. Before opening an implementation ticket, refresh live repo/runtime and compare the smallest credible combat/tool slice against vehicle identity/condition and learned traversal alternatives. The desired next increment should add a genuinely new player verb, remain bounded, and collide with already-proven city systems rather than require a generalized combat framework.

Other credible candidate families:

- vehicle identity / condition / claiming using existing Courier Bike + Scrap Hauler + Garage seams;
- learned traversal / Service Network / map-knowledge payoff on existing Gears geography;
- bounded relationship/Standing or world-state consequence if it can become materially player-visible cheaply;
- later Heat escalation, witnesses/surveillance, transit, broader geography, or generalized systems only when their player value clearly beats bounded alternatives.

Do not create Production 05 from numbering momentum.

## Retained production foundations

Do not recreate these because older roadmaps describe them historically:

- retained Feel tickets #12–#16 and current verified descendants;
- Mission 01 — Lira scrap job;
- Mission 02 — Mayor Burn civic repossession, composed with ordinary open-world Wanted + Field Hacking;
- Mission 03 — Sister Kael / Silent Core memory reveal, retaining historical authored pursuit behavior;
- Open World Expansion 01A–01D / PRs #63–#66;
- World Event 01 / PR #68 — bounded FB-13 infrastructure thrum;
- Issue #89 / Open World Expansion 01E — `VISUAL_PERF_CHECKPOINT_PASS`;
- Productions 01–04.

The yard connects into one real Gears production block with primary industrial routing, alternate service alley/rejoin, commercial/industrial frontage, Mayor Burn's garage, Silent Core access, and the Production-04 industrial-crossing work zone.

FB-13 / HS-7 remain authored persistent companions in canon; World Event 01 is not precedent for a generalized companion framework.

## Verification / human-gate debt

Functional/code verification and perceptual qualification remain separate. Still not completed unless fresh evidence says otherwise:

- native desktop average/P95 frame-time qualification on dedicated desktop hardware;
- broader fresh-player perceptual qualification;
- physical touch-conditioner A/B before changing touch steering default;
- human/windowed listening where actual playback quality is the question;
- real mobile performance until measured on hardware.

Small reversible production increments may continue with this debt visible when they do not depend on those unanswered questions.

## Parallel / deferred work

- Audio Production remains a first-class parallel lane. Refresh live Audio branches/PRs before touching shared scenes, actor audio wiring, registries, runtime, assets, or event semantics. Actual perceptual audio claims require playback evidence.
- PR #44 — CTW Feel 03 camera occlusion readability slice — remains **DEFERRED** and must not be absorbed into the next product slice merely because it is open.
- `START_HERE.md` remains directionally current; do not turn it into a changelog.

## Local worktree truth

This continuity update was executed through isolated GitHub branch/PR operations. No local checkout was established by this ChatGPT execution path.

Therefore until a local executor proves otherwise:

- local branch: **UNKNOWN**;
- local HEAD: **UNKNOWN**;
- local upstream: **UNKNOWN**;
- local dirty/untracked state: **UNKNOWN**.

Before local mutation verify repo, branch, HEAD, upstream, dirty/untracked state, remote, and concurrent work.

## Next-state rule

The next production session should:

1. refresh exact `main`, open PRs/issues, CI and public-playtest state;
2. read `START_HERE.md`, issue #55 and canonical production contract #118;
3. verify local repo/branch/HEAD/upstream/dirty state before local code mutation;
4. re-check the leading combat/physical-tool frontier against exact runnable implementation and concurrent Audio/shared-scene work;
5. compare it with vehicle identity/condition and learned traversal alternatives on player value / cost / risk;
6. create exactly one just-in-time implementation ticket only after one bounded increment is selected;
7. execute `SPEC -> RED -> GREEN -> exact-head VERIFY -> frozen Standards+Spec REVIEW -> REPAIR if needed -> MERGE -> exact-main VERIFY`;
8. update continuity only after verified changes land.

Create a new Wayfinder only if production exposes a genuinely new, foggy, multi-session cross-system design problem. Ordinary production remains downstream.

`WAYFINDER_MAP.md` remains historical architecture context, not the live status tracker.
