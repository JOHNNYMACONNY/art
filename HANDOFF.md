# HANDOFF.md — Current Product Continuity

**Status:** `BURNSIDE_PRODUCTION_01_02_03_04_05_06_MERGED_VERIFIED__READY_FOR_POST_PRODUCTION_06_REEVALUATION`  
**Verified production gameplay/public baseline:** `cfe82d2580a7300e3ebb2bf3257d08a4300bf2a4`  
**Final reviewed Production-06 head:** `1b5c3dfc89e9e95d66ec24a935926ad534ef2e51`  
**Immutable Feel baseline:** `09fa2b0ab8aebc8a2ae54b989bffad7720503e48`  
**Engine:** Godot 4.7.1 Stable

> Continuity only. For repo-sensitive work refresh remote `main`, open PRs/issues, CI, public-playtest state, and any concurrent Audio/shared-scene work. A docs-only continuity merge may make repository HEAD newer than the verified gameplay/public baseline without changing runnable gameplay.

## Current product state

Burnside now has one dense qualified Gears production block where authored missions, Heat-1 Wanted / Contact-Search, local Field Hacking, civic reporting, reactive work-zone actors, the Scrapper Tool, physical pursuer counterplay, and the first durable mapped-knowledge tracer compose in the same geography.

Approved visual direction remains **Civic Salvage Palimpsest / Industrial Cel-Shaded Near Future**. Issue #118 remains the canonical downstream Burnside player-facing production contract. Issue #55 remains the durable product-direction anchor.

Do not default to more acreage or generalized frameworks. Favor player-facing systemic density, feel, clarity, and authored consequence.

## Production sequence — verified baselines

- **Production 01** — #119 / PR #121 — Wanted / Contact-Search — `4e62e198508393821bf902da681daa776d1d8545`.
- **Production 02** — #122 / PR #123 — Field Hacking / Report Suppression — `7a5c36598c6d950d832f71c42e41eaacfb7b75b2`.
- **Production 03** — #124 / PR #125 — Mission-02 Wanted + Field-Hacking composition — `afd1db546b04221c7fb4b222b9f77311acd6d3ea`.
- **Production 04** — #127 / PR #129 — Gears Work-Zone / Player-Reactive Ambient Incident — `7605277d920b7877715d78687ccab16a69745b2f`.
- **Production 05** — #131 / PR #132 — Gears Scrapper Tool / Street-Combat Contact Tracer — `702678cb66ab7544b43644cfa29baf5361c68dc1`.
- **Production 06** — #134 / PR #135 — Gears Surveyed Service Cut / Durable Map-Knowledge Tracer — `cfe82d2580a7300e3ebb2bf3257d08a4300bf2a4`.

## Retained authority truths

Wanted authority remains:

`INCIDENT -> REPORT -> HEAT 1 + CONTACT -> PHYSICAL RESPONSE -> CONTACT LOSS -> SEARCH -> REACQUIRE or EVADE -> CLEAR FREE ROAM`

Field Hacking remains local and situational:

`DISCOVER LOCAL SERVICE ACCESS -> JAM REPORT LINK -> CIVIC INCIDENT -> ALARM FAULT -> REPORT SUPPRESSED -> NO NEW WANTED`

Mission completion, Scrapper use, route surveying, map viewing, local incident recovery, and Replay do not silently clear valid Heat / Contact / Search / Recognition authority.

Mission 01 and Mission 03 retain their historical authored pursuit behavior. Mission 02 remains composed with ordinary open-world Wanted + Field Hacking and must not strand when the shared civic alarm/report seam has already been consumed or faulted while jammed.

## Production 05 retained result

The Scrapper Tool remains one bounded authored physical tool, not a generalized combat/inventory framework.

Primary chain:

`TAKE SCRAPPER TOOL -> FORCE JAMMED SERVICE ACCESS -> LOCAL WORK-ZONE REACTS -> EXISTING CIVIC REPORT ATTEMPT -> HEAT 1 + CONTACT -> PHYSICAL PURSUER CLOSES -> SCRAPPER IMPACT CREATES BRIEF SPACE -> USE SERVICE CUT / BREAK CONTACT`

Key boundaries retained:

- Tool Action is dedicated touch + desktop input and yields to retained gesture/input ownership.
- Forcing the authored ServiceAlley access changes physical traversal only through the existing P04/P05 seams.
- Scrapper contact only creates a brief pursuer stagger/displacement window.
- No Player Health/Armor, firearms, weapon roster, generic damage, NPC death, generalized hostile combat AI, inventory/loot/RPG stats, Heat 2–5, generalized witness/crime framework, or unrelated Audio scope exists from P05.

## Production 06 — verified player-facing result

Issue #134 / PR #135: **COMPLETE / MERGED / EXACT-MAIN VERIFIED / PUBLIC VERIFIED**.

Final reviewed PR head:

`1b5c3dfc89e9e95d66ec24a935926ad534ef2e51`

Exact merge / verified gameplay/public baseline:

`cfe82d2580a7300e3ebb2bf3257d08a4300bf2a4`

Player-facing contract:

`LEGITIMATELY TRAVERSE SERVICEALLEY <-> NORTHCONNECTOR -> RECORD SURVEYED ROUTE ONCE -> REPLAY/RELAUNCH RETAINS LEARNED GEOGRAPHY -> PHYSICAL ACCESS MAY RESET TO JAMMED INDEPENDENTLY`

Production truths:

- only the retained `ServiceAlley <-> NorthConnector` service cut is surveyable;
- merely seeing the route or forcing the jammed access does not grant mapped knowledge;
- survey completion requires an actual bounded traversal between exclusive authored endpoint sides with distance/jump/corridor validation;
- the route is awarded once and later crossings do not duplicate progress;
- the Gears route sheet is on-demand and bounded, not a generalized minimap/GPS/pathfinding system;
- desktop Map uses the dedicated `M` seam and touch uses one safe-area-aware Map action;
- Map is unavailable while driving or while another retained interaction/input lock owns the Runner;
- the modal suppresses gameplay/tool interaction and routed touch/drag cannot claim the gameplay joystick;
- learned map knowledge and physical route accessibility are independent truths;
- Replay may restore the P05 barrier to `JAMMED` while the route remains visibly learned;
- reopening the access updates current access presentation without rewriting learned knowledge;
- mapped knowledge persists through a narrow versioned `surveyed_routes` boundary only;
- persistence uses checked staging + replacement and rolls back the in-memory award on write failure, preserving the previous valid document;
- malformed/unsupported persisted data fails safely rather than silently overwriting unknown/newer state;
- no mission saves, inventory saves, vehicle ownership saves, checkpoint/save-slot/cloud-save system, citywide Service Network graph, broad fog of war, turn-by-turn navigation, racing line, companion navigation, new acreage, Street-Combat expansion, Heat escalation, PR #44 camera work, or unrelated Audio Production entered P06.

### Review repairs

Frozen-candidate review produced two real fixes and one disproven concern:

1. **Survey endpoint ambiguity:** overlapping Alley/Connector join could qualify too early. Repaired by requiring arrival on the opposite exclusive authored surface.
2. **Map external-lock availability:** the Map action needed a single availability gate reflecting existing Runner input ownership. Repaired at the input/runtime surface.
3. **Modal touch leak:** deeper routed-event testing disproved the suspected leak. Retained `_gui_input()` ownership plus the full-screen GUI modal correctly prevents joystick acquisition; regression coverage now locks that behavior.

The durable-progress write path was also hardened before merge with atomic staging/replacement and a forced-failure preservation test.

## Production 06 verification truth

### Final exact PR head

At `1b5c3dfc89e9e95d66ec24a935926ad534ef2e51`:

- focused mapped-knowledge persistence tracer: **PASS**;
- service-cut survey semantics including exclusive-endpoint traversal: **PASS**;
- Map input/modal and real Viewport-routed touch ownership: **PASS**;
- actual production `_physics_process -> Runner.global_position` traversal path: **PASS**;
- forced atomic-write failure preserves prior valid bytes: **PASS**;
- retained Production 01–05 focused regressions: **PASS**;
- six-state rendered P06 proof: **PASS**;
- literal-head + synthetic-merge Web export/static-host smoke: **PASS**;
- literal-head + synthetic-merge same-origin browser relaunch persistence: **PASS**;
- current camera contracts: **PASS**;
- canonical 29/29 exact-head compatibility matrix: **PASS**;
- independent senior review: **APPROVE after repair**.

### Exact-main / public evidence

Gameplay/public merge baseline:

`cfe82d2580a7300e3ebb2bf3257d08a4300bf2a4`

Burnside Production 06 main push run `33780522078`:

- exact source checkout: **PASS**;
- P06 mapped-knowledge persistence: **PASS**;
- P06 survey tracer: **PASS**;
- P06 Map/input/modal tracer: **PASS**;
- retained P01–P05 focused regressions: **PASS**;
- Production-06 GREEN requirement: **PASS**;
- rendered proof capture/upload: **PASS**;
- same-origin browser relaunch persistence: **PASS**;
- rendered proof artifact `9903378705`, digest `sha256:29ff688fb027928b26b20e28694366766e0360289b8ad6ebe466cd51c59d1d8d`;
- Web persistence artifact `9903424756`, digest `sha256:b53a3025d4343e44e1313efee0d1f38bc171d2546b6eef3985b699d1918643a5`.

Godot Web Playtest main push run `33780522064`:

- exact source checkout: **PASS**;
- mobile touch routing: **PASS**;
- desktop controls / alias ownership / vehicle authority / interaction cancel: **PASS**;
- Web export: **PASS**;
- static-hosting smoke: **PASS**;
- browser artifact upload: **PASS**;
- source revision stamp verification: **PASS**;
- public `playtest-web` publication: **PASS**.

Public source stamp:

`playtest-web/PLAYTEST_BUILD.txt = cfe82d2580a7300e3ebb2bf3257d08a4300bf2a4`

The canonical compatibility matrix remains intentionally PR-only in the Web workflow; it passed 29/29 on the exact reviewed P06 head before merge.

## Post-Production-06 re-evaluation state

Production 06 closes the immediate learned-traversal gap. The player can now discover one real shortcut, have that knowledge persist across Replay/relaunch, and still receive truthful current-access state when the physical cut is jammed again.

**Production 07 is not selected yet.** Re-evaluate from exact runnable behavior rather than numbering momentum.

Leading credible next gaps to compare:

1. **vehicle identity / condition / claiming** — existing Bike + Hauler are differentiated mechanically but still thin as owned/used city objects; pursue only if a bounded player-facing identity loop beats persistence/schema complexity;
2. **next bounded Street-Combat depth** — P05 proves committed physical contact and tactical displacement, but no health/damage/death framework exists; any increment must improve fight/escape feel rather than bootstrap a combat framework;
3. **relationship / Standing / authored consequence** — only if a small local outcome can visibly change later interactions without creating a broad reputation authority system;
4. **deeper authored city mastery** — a second learned route/Old Cut may become valuable later, but do not generalize P06 into a Service Network or GPS system without evidence;
5. Heat escalation, witnesses/surveillance, transit, broader geography, generalized persistence, or companion navigation remain later candidates unless current play proves they outrank smaller authored gains.

## Retained foundations / deferred lanes

Do not recreate retained Feel tickets #12–#16, Missions 01–03, Open World Expansion 01A–01D, World Event 01 / PR #68, or Productions 01–06 because older roadmaps describe them historically.

FB-13 / HS-7 remain authored persistent companions in canon. P06 does not create a generalized companion/navigation framework.

Audio Production remains a first-class parallel lane. Refresh live Audio branches/PRs before shared-scene/audio mutation. Actual perceptual audio claims require playback evidence.

PR #44 — CTW Feel 03 camera occlusion readability — remains **DEFERRED** and must not be absorbed by momentum.

## Verification / human-gate debt

Still not completed unless fresh evidence says otherwise:

- native desktop average/P95 frame-time qualification on dedicated desktop hardware;
- broader fresh-player perceptual qualification;
- physical touch-conditioner A/B before changing touch steering defaults;
- human/windowed listening where actual playback quality is the question;
- real mobile performance until measured on hardware.

Small reversible production increments may continue when they do not depend on those unanswered gates.

## Local worktree truth

This continuity update was executed through isolated GitHub branch/PR operations. No local checkout was established by this ChatGPT execution path.

Until a local executor proves otherwise, local branch / HEAD / upstream / dirty state are **UNKNOWN**. Verify them before local mutation and preserve unrelated user/concurrent work.

## Next-state rule

Next production session:

1. refresh exact `main`, open PRs/issues, CI, public playtest, and concurrent Audio/shared-scene state;
2. read `START_HERE.md`, issue #55, issue #118, and this continuity file;
3. verify local repo/branch/HEAD/upstream/dirty state before local code mutation;
4. re-evaluate post-P06 player-facing gaps by **fun / feel / clarity / cohesion / value / cost / risk**;
5. select exactly one bounded next production increment only after evidence supports it;
6. create the JIT ticket/spec for that increment;
7. execute `SPEC -> RED -> GREEN -> exact-head VERIFY -> frozen independent REVIEW -> REPAIR if needed -> MERGE -> exact-main VERIFY -> PUBLIC STAMP`;
8. update continuity only after verified changes land.

Create a new Wayfinder only for a genuinely new, foggy, multi-session cross-system design problem. `WAYFINDER_MAP.md` remains historical architecture context, not the live status tracker.
