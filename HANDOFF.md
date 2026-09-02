# HANDOFF.md — Current Product Continuity

**Status:** `BURNSIDE_PRODUCTION_01_02_03_04_05_MERGED_VERIFIED__READY_FOR_POST_PRODUCTION_05_REEVALUATION`  
**Verified production gameplay/public baseline:** `702678cb66ab7544b43644cfa29baf5361c68dc1`  
**Final reviewed Production-05 head:** `e757a6fdfa492ba7cdf62f0a04c00adb829a8ca3`  
**Immutable Feel baseline:** `09fa2b0ab8aebc8a2ae54b989bffad7720503e48`  
**Engine:** Godot 4.7.1 Stable

> This file is continuity, not implementation authority. Refresh remote `main`, open PRs/issues and live CI before repo-sensitive work. A docs-only continuity merge may make repository HEAD newer than the verified gameplay/public baseline above without changing runnable gameplay.

## Current product state

The production Godot slice now combines the retained Chinatown-Wars-style Feel foundation, three authored missions, approved Gears visual direction, the qualified first Gears production block, one bounded FB-13 world event, Heat-1 Wanted / Contact-Search, local Field Hacking over civic reporting, Mission-02 composition of those city systems, one bounded player-reactive Gears work-zone incident, and the first bounded physical-tool / street-combat contact tracer.

Approved visual direction remains **Civic Salvage Palimpsest / Industrial Cel-Shaded Near Future**. Issue #118 remains the canonical downstream Burnside player-facing production contract. Issue #55 remains the durable product-direction anchor.

Do **not** default to more acreage or generalized frameworks. The current production block is valuable because multiple authored city systems now collide in the same geography.

## Production sequence — verified baselines

- **Production 01** — #119 / PR #121 — Open-World Wanted / Contact-Search: complete. Verified gameplay baseline `4e62e198508393821bf902da681daa776d1d8545`.
- **Production 02** — #122 / PR #123 — Field Hacking / Report Suppression: complete. Verified gameplay baseline `7a5c36598c6d950d832f71c42e41eaacfb7b75b2`.
- **Production 03** — #124 / PR #125 — Civic Repossession / Wanted-Field-Hacking Composition: complete. Verified gameplay baseline `afd1db546b04221c7fb4b222b9f77311acd6d3ea`.
- **Production 04** — #127 / PR #129 — Gears Work-Zone / Player-Reactive Ambient Incident: complete. Verified gameplay/public baseline `7605277d920b7877715d78687ccab16a69745b2f`.
- **Production 05** — #131 / PR #132 — Gears Scrapper Tool / Street-Combat Contact Tracer: complete. Verified gameplay/public baseline `702678cb66ab7544b43644cfa29baf5361c68dc1`.

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

## Burnside Production 04 — retained player-facing result

Issue #127 / PR #129: **COMPLETE / MERGED / EXACT-MAIN VERIFIED / PUBLIC VERIFIED**.

Exact gameplay/public baseline:

`7605277d920b7877715d78687ccab16a69745b2f`

Routine:

`GEARS WORKER + UTILITY CRAWLER ROUTINE -> PLAYER PASSES / APPROACHES -> ACTORS NOTICE / YIELD -> ROUTINE RECOVERS`

Live civic reporting:

`HIGH-SPEED WORK-ZONE CLOSE CALL -> LOCAL ALARM / RETREAT -> REPORT SENT -> HEAT 1 + CONTACT`

Prepared Field Hacking:

`JAM REPORT LINK -> SAME CLOSE CALL -> LOCAL ALARM / RETREAT -> REPORT SUPPRESSED -> NO NEW WANTED`

Production truths retained:

- local actor alarm remains distinct from city knowledge;
- civic consequence goes only through existing `BurnsideWantedRuntime.request_civic_report()`;
- pre-existing Wanted survives and blocks redundant replacement authority;
- local incident recovery never clears Heat / Contact / Search / Recognition;
- Replay resets incident-local state without creating a second authority system;
- Mission 02 remains non-stranding when the shared civic alarm was previously consumed/faulted while jammed;
- no generalized population, witness/crime architecture, traffic simulation, Heat 2–5, save-schema, PR #44 camera work, or unrelated Audio Production scope entered Production 04.

## Burnside Production 05 — verified player-facing result

Issue #131 / PR #132: **COMPLETE / MERGED / EXACT-MAIN VERIFIED / PUBLIC VERIFIED / CLOSED**.

Final reviewed PR head:

`e757a6fdfa492ba7cdf62f0a04c00adb829a8ca3`

Exact merge / verified gameplay/public baseline:

`702678cb66ab7544b43644cfa29baf5361c68dc1`

Primary authored chain:

`TAKE SCRAPPER TOOL -> FORCE JAMMED SERVICE ACCESS -> LOCAL WORK-ZONE REACTS -> EXISTING CIVIC REPORT ATTEMPT -> HEAT 1 + CONTACT -> PHYSICAL PURSUER CLOSES -> SCRAPPER IMPACT CREATES BRIEF SPACE -> USE SERVICE CUT / BREAK CONTACT`

Prepared Field-Hacking chain:

`JAM REPORT LINK -> TAKE SCRAPPER TOOL -> FORCE SAME SERVICE ACCESS -> LOCAL WORK-ZONE STILL REACTS -> REPORT SUPPRESSED -> NO NEW WANTED -> SERVICE CUT REMAINS USABLE`

Existing-Wanted composition:

`VALID HEAT 1 ALREADY ACTIVE -> SCRAPPER CANNOT CLEAR HEAT / RECOGNITION / SEARCH KNOWLEDGE -> TOOL MAY ONLY ALTER PURSUER IMMEDIATE MOTION -> AUTHORITY REMAINS AUTHORITATIVE`

### Production truths

- one locally authored Scrapper Tool is physically acquired without an inventory framework;
- Tool Action is a dedicated touch + desktop input seam and does not synthesize the shared Action contract;
- Tool Action is unavailable while driving and now yields to retained gesture/input locks;
- the tool swing is committed, directional and range-bounded rather than an arbitrary proximity trigger;
- one authored ServiceAlley access is physically jammed and becomes materially traversable only after a valid tool force;
- forcing the access composes through the existing Production-04 local reaction and civic Report seam;
- local worker/crawler reaction remains visible even when Field Hacking suppresses the future civic Report;
- ordinary CLEAR reporting produces the existing Heat 1 + Contact authority path;
- a jammed Report produces no new Wanted;
- pre-existing Wanted survives tool/environment interaction;
- a legitimate close-range Scrapper contact gives the active pursuer only a brief physical stagger/displacement window;
- Scrapper contact does not deactivate the pursuer, clear Heat, clear Contact/Search/Recognition, create Health/damage/death semantics, or permanently disable pursuit;
- Replay restores tool possession/availability, jammed access, local incident state, pursuer stagger state, tool cooldown/input ownership, and the existing authority reset baseline;
- Mission-02 shared civic-report ordering remains non-stranding;
- no generalized combat framework, Player Health/Armor, firearms, weapon roster, ammo, hostile NPC combat AI, NPC death, generic damage interface, inventory/loot/RPG stats, generalized witnesses/crime/event bus, Heat 2–5, vehicle claiming/condition, generalized map discovery, new acreage, transit, PR #44 camera work, companion framework, save work, or unrelated Audio Production entered Production 05.

### Review repair

The frozen Standards/#131 review found one real contract defect after the initial Task-7 candidate: the new Tool Action could still fire while a retained gesture/input lock owned interaction.

A focused RED tracer reproduced the exact failure. The repair added one shared Tool-action availability predicate at the input surface plus a fail-closed runtime check. Final candidate `e757a6fdfa492ba7cdf62f0a04c00adb829a8ca3` proves:

- touch Tool affordance hides/disables under the retained gesture lock;
- touch Tool signal does not emit while locked;
- desktop `F` Tool signal does not emit while locked;
- direct Scrapper runtime calls fail closed while locked;
- releasing the retained lock restores exactly one dedicated Tool signal without synthesizing generic Action.

No locomotion, mission, Wanted, camera, audio, save, or generalized combat authority changed in that repair.

## Production 05 verification truth

### Final exact PR head

At `e757a6fdfa492ba7cdf62f0a04c00adb829a8ca3`:

- Production-05 dedicated input tracer: **PASS**;
- Production-05 retained input-lock tracer: **PASS**;
- Production-05 environment/service-access tracer: **PASS**;
- Production-05 pursuer stagger tracer: **PASS**;
- Production-05 Mission-02 ordering tracer: **PASS**;
- retained Production-04 work-zone + Mission-02 regressions: **PASS**;
- retained Production-03 suppression + Mission/Wanted composition: **PASS**;
- retained Production-02 Field-Hacking suppression: **PASS**;
- retained Production-01 Heat-1 tracer: **PASS**;
- six-frame windowed Production-05 rendered proof: **PASS / visually reviewed**;
- proof artifact `9869502734`, digest `sha256:a6c9aea3baa0776b13a4487fc8a5092767b17782443c1dbaa3e66a3d9ff47b29`;
- literal-head Web export + static-hosting smoke: **PASS**;
- synthetic-merge Web export + static-hosting smoke: **PASS**;
- mobile touch routing / desktop controls / alias ownership / vehicle authority / interaction cancel: **PASS**;
- current camera contracts: **PASS**;
- canonical **29/29** exact-head compatibility commands: **PASS**;
- frozen Standards + #131 review: **PASS after repair**.

### Exact-main evidence

Merge commit / gameplay baseline:

`702678cb66ab7544b43644cfa29baf5361c68dc1`

Burnside Production 05 main push run `33693702457` on that exact SHA:

- exact source checkout: **PASS**;
- P05 dedicated input tracer: **PASS**;
- P05 retained input-lock tracer: **PASS**;
- P05 environment/service-access tracer: **PASS**;
- P05 pursuer tracer: **PASS**;
- P05 Mission-02 ordering tracer: **PASS**;
- retained Production 01-04 focused regressions: **PASS**;
- Production-05 GREEN requirement: **PASS**;
- windowed rendered proof capture: **PASS**;
- proof artifact upload: **PASS**.

Godot Web Playtest main push run `33693702455` on that exact SHA:

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

The canonical compatibility matrix is intentionally PR-only in the Web workflow and was skipped on the main push after passing 29/29 on the exact reviewed PR head.

Public branch source stamp:

`playtest-web/PLAYTEST_BUILD.txt = 702678cb66ab7544b43644cfa29baf5361c68dc1`

## Post-Production-05 re-evaluation state

Production 05 closes the previous highest-value gap: the existing Gears geography now supports a grounded physical city tool that can change traversal, provoke local consequence, compose with Field Hacking/Wanted, and buy tactical space against the existing Heat-1 physical pursuer.

The next production increment is **not selected yet**. Do not manufacture Production 06 from numbering momentum.

Fresh next-session re-evaluation should compare at minimum:

1. **vehicle identity / condition / claiming** — two differentiated drivable vehicles already exist, but ownership/condition/identity remains thin and could make the sandbox feel more lived-in if bounded without save/schema sprawl;
2. **learned traversal / Service Network / map knowledge** — Production 05 made the ServiceAlley route materially actionable, increasing the potential value of authored discovery/knowledge without requiring more acreage;
3. **next bounded Street-Combat depth** — Production 05 proves physical contact and tactical displacement, but there is still no Player Health/Armor, hostile pedestrian combat AI, weapon framework, or generalized damage system; any next combat increment must earn its added complexity through player feel rather than framework momentum;
4. **relationship / Standing / consequence** — only if a small authored change can become materially player-visible without creating another broad authority framework;
5. later Heat escalation, witnesses/surveillance, transit, broader geography, or generalized systems only when their player value clearly beats smaller authored alternatives.

Before selecting anything, refresh exact `main`, current open PRs/issues, runnable behavior, and any concurrent Audio/shared-scene work. Small experiments are allowed; architecture is not locked permanently.

## Retained production foundations

Do not recreate these because older roadmaps describe them historically:

- retained Feel tickets #12–#16 and current verified descendants;
- Mission 01 — Lira scrap job;
- Mission 02 — Mayor Burn civic repossession, composed with ordinary open-world Wanted + Field Hacking;
- Mission 03 — Sister Kael / Silent Core memory reveal, retaining historical authored pursuit behavior;
- Open World Expansion 01A–01D / PRs #63–#66;
- World Event 01 / PR #68 — bounded FB-13 infrastructure thrum;
- Issue #89 / Open World Expansion 01E — `VISUAL_PERF_CHECKPOINT_PASS`;
- Productions 01–05.

The yard connects into one real Gears production block with primary industrial routing, alternate service alley/rejoin, commercial/industrial frontage, Mayor Burn's garage, Silent Core access, the Production-04 industrial-crossing work zone, and the Production-05 forced ServiceAlley access/tool loop.

FB-13 / HS-7 remain authored persistent companions in canon; nothing in Production 05 creates a generalized companion framework.

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
4. re-evaluate the post-Production-05 gaps against exact runnable behavior rather than roadmap momentum;
5. rank vehicle identity/condition, learned traversal/Service Network, bounded Street-Combat depth and other credible alternatives by player value / cost / risk;
6. create exactly one just-in-time implementation ticket only after one bounded increment is selected;
7. execute `SPEC -> RED -> GREEN -> exact-head VERIFY -> frozen Standards+Spec REVIEW -> REPAIR if needed -> MERGE -> exact-main VERIFY -> PUBLIC STAMP`;
8. update continuity only after verified changes land.

Create a new Wayfinder only if production exposes a genuinely new, foggy, multi-session cross-system design problem. Ordinary production remains downstream.

`WAYFINDER_MAP.md` remains historical architecture context, not the live status tracker.
