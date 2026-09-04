# HANDOFF.md — Current Product Continuity

**Status:** `BURNSIDE_PRODUCTION_01_02_03_04_05_06_07_MERGED_VERIFIED__READY_FOR_POST_PRODUCTION_07_REEVALUATION`  
**Verified production gameplay/public baseline:** `3deb1cccafdaeb9f3d6b1629e94f2a262cf3259d`  
**Final frozen Production-07 feature head:** `b98f7e00a0865f5f9e6902cdf7dba2d66d9dec8f`  
**Immutable Feel baseline:** `09fa2b0ab8aebc8a2ae54b989bffad7720503e48`  
**Engine:** Godot 4.7.1 Stable

> Continuity only. Refresh remote `main`, open PRs/issues, CI, public-playtest state, and any concurrent Audio/shared-scene work before repo-sensitive claims. A later docs-only continuity merge may make repository HEAD newer than the exact verified gameplay/public baseline above without changing runnable gameplay.

## Current product state

Burnside now has one dense qualified Gears production block where authored missions, Heat-1 Wanted / Contact-Search, local Field Hacking, civic reporting, reactive work-zone actors, the Scrapper Tool, physical pursuer counterplay, durable mapped route knowledge, coarse vehicle condition, and one bounded Burn Garage repair loop compose in the same geography.

Approved visual direction remains **Civic Salvage Palimpsest / Industrial Cel-Shaded Near Future**. Issue #118 remains the canonical downstream Burnside player-facing production contract. Issue #55 remains the durable product-direction anchor.

Do not default to more acreage or generalized frameworks. Favor player-facing systemic density, feel, clarity, cohesion, and authored consequence.

## Production sequence — verified baselines

- **Production 01** — #119 / PR #121 — Wanted / Contact-Search — `4e62e198508393821bf902da681daa776d1d8545`.
- **Production 02** — #122 / PR #123 — Field Hacking / Report Suppression — `7a5c36598c6d950d832f71c42e41eaacfb7b75b2`.
- **Production 03** — #124 / PR #125 — Mission-02 Wanted + Field-Hacking composition — `afd1db546b04221c7fb4b222b9f77311acd6d3ea`.
- **Production 04** — #127 / PR #129 — Gears Work-Zone / Player-Reactive Ambient Incident — `7605277d920b7877715d78687ccab16a69745b2f`.
- **Production 05** — #131 / PR #132 — Gears Scrapper Tool / Street-Combat Contact Tracer — `702678cb66ab7544b43644cfa29baf5361c68dc1`.
- **Production 06** — #134 / PR #135 — Gears Surveyed Service Cut / Durable Map-Knowledge Tracer — `cfe82d2580a7300e3ebb2bf3257d08a4300bf2a4`.
- **Production 07** — #137 / PR #138 — Gears Vehicle Condition / Burn Garage Repair Tracer — `3deb1cccafdaeb9f3d6b1629e94f2a262cf3259d`.

## Retained authority truths

Wanted authority remains:

`INCIDENT -> REPORT -> HEAT 1 + CONTACT -> PHYSICAL RESPONSE -> CONTACT LOSS -> SEARCH -> REACQUIRE or EVADE -> CLEAR FREE ROAM`

Field Hacking remains local and situational:

`DISCOVER LOCAL SERVICE ACCESS -> JAM REPORT LINK -> CIVIC INCIDENT -> ALARM FAULT -> REPORT SUPPRESSED -> NO NEW WANTED`

Mission completion, Scrapper use, route surveying, map viewing, local incident recovery, vehicle repair, and Replay do not silently clear valid Heat / Contact / Search / Recognition authority.

Mission 01 and Mission 03 retain their historical authored pursuit behavior. Mission 02 remains composed with ordinary open-world Wanted + Field Hacking and the existing Burn Garage delivery socket.

## Production 05 retained result

The Scrapper Tool remains one bounded authored physical tool, not a generalized combat/inventory framework.

Primary chain:

`TAKE SCRAPPER TOOL -> FORCE JAMMED SERVICE ACCESS -> LOCAL WORK-ZONE REACTS -> EXISTING CIVIC REPORT ATTEMPT -> HEAT 1 + CONTACT -> PHYSICAL PURSUER CLOSES -> SCRAPPER IMPACT CREATES BRIEF SPACE -> USE SERVICE CUT / BREAK CONTACT`

Key boundaries retained:

- Tool Action is dedicated touch + desktop input and yields to retained gesture/input ownership.
- Forcing the authored ServiceAlley access changes physical traversal only through retained P04/P05 seams.
- Scrapper contact only creates a brief pursuer stagger/displacement window.
- No Player Health/Armor, firearms, weapon roster, generic NPC damage/death, generalized hostile combat AI, inventory/loot/RPG stats, Heat 2–5, generalized witness/crime framework, or unrelated Audio scope exists from P05.

## Production 06 retained result

Issue #134 / PR #135: **COMPLETE / MERGED / EXACT-MAIN VERIFIED / PUBLIC VERIFIED**.

Exact gameplay/public baseline:

`cfe82d2580a7300e3ebb2bf3257d08a4300bf2a4`

Player-facing contract:

`LEGITIMATELY TRAVERSE SERVICEALLEY <-> NORTHCONNECTOR -> RECORD SURVEYED ROUTE ONCE -> REPLAY/RELAUNCH RETAINS LEARNED GEOGRAPHY -> PHYSICAL ACCESS MAY RESET TO JAMMED INDEPENDENTLY`

Retained truths:

- only the authored `ServiceAlley <-> NorthConnector` cut is surveyable;
- learned map knowledge and current physical accessibility are independent truths;
- Replay can restore the barrier to `JAMMED` while surveyed route knowledge remains known;
- the route sheet is bounded and on-demand, not a generalized GPS/minimap/navigation system;
- durable P06 knowledge remains isolated in its narrow versioned `surveyed_routes` store;
- P07 does not modify `user://burnside_mapped_knowledge.json` or its schema.

## Production 07 — verified player-facing result

Issue #137 / PR #138: **COMPLETE / MERGED / EXACT-MAIN VERIFIED / PUBLIC VERIFIED** pending only this docs continuity merge and issue closure.

Frozen feature head:

`b98f7e00a0865f5f9e6902cdf7dba2d66d9dec8f`

Exact gameplay merge / verified public baseline:

`3deb1cccafdaeb9f3d6b1629e94f2a262cf3259d`

Player loop:

`DRIVE -> SIGNIFICANT IMPACTS -> BATTERED -> CRITICAL / LIMPING -> ABANDON, SWAP, OR REACH BURN'S GARAGE -> REPAIR -> ROADWORTHY`

Production truths:

- scope is exactly the retained `CourierBike` and `ScrapHauler`;
- player-readable condition states are exactly `ROADWORTHY`, `BATTERED`, and `CRITICAL`;
- no visible numeric HP exists;
- condition derives from each vehicle's real collision telemetry and uses bounded deterministic accumulation plus a 0.50-second accepted-contact cooldown;
- trivial hits are ignored and sustained wall contact cannot melt condition frame-by-frame;
- BATTERED is presentation-first;
- CRITICAL changes only usable forward maximum speed, using the approved `0.52` multiplier;
- steering, reverse, acceleration, braking, grip, mount/dismount, collision response, and retained handling authority remain intact;
- no vehicle explosion or destruction exists;
- Mayor Burn's existing `GearsDistrictSlice01B/MissionDestinationSocket` is the sole P07 repair point;
- repair requires a damaged active supported vehicle, inside the 2.6 m Garage radius, effectively stopped, with authoritative Wanted heat `0` and state `CLEAR`;
- CONTACT, SEARCH, or any other active Wanted state rejects repair;
- repair never clears, resets, or otherwise mutates Wanted authority;
- Garage repair uses the retained Action route only; no repair menu, economy, or generalized interaction/service framework was created;
- Mission 02 remains authoritative for delivery and a CRITICAL Hauler can still complete legal Garage delivery;
- Mission completion and repair affect only their own state and do not double-fire;
- full Replay resets both supported vehicle conditions to ROADWORTHY while P06 surveyed route knowledge remains durable;
- no ownership/claiming, generalized damage framework, generalized vehicle framework, generalized save framework, Garage network, economy, navigation expansion, canon change, or Audio change entered P07.

### Render/readability repair

The first fixed-size world-label repair made the old typography values visually enormous. Automation alone was not accepted as proof.

The final presentation contract keeps `fixed_size = true` and `no_depth_test = true`, but bounds the world labels to small screen-space typography. Final values are:

- CourierBike condition tag: font 6 / outline 2;
- ScrapHauler condition tag: font 6 / outline 2;
- Burn Garage affordance: font 5 / outline 2.

The frozen nine-shot proof was directly inspected after tuning. Vehicle condition tags and Garage `WANTED // SERVICE LOCKED`, `REPAIR // ACTION`, and `ROADWORTHY` states remain readable without dominating or clipping the frame.

## Production 07 verification truth

### Frozen feature head

At `b98f7e00a0865f5f9e6902cdf7dba2d66d9dec8f`:

- exact-source P07 semantics/runtime: **PASS**;
- real `move_and_slide()` collision -> BATTERED/CRITICAL tracer: **PASS**;
- sustained-contact debounce: **PASS**;
- CRITICAL forward limp, steering, and reverse runtime behavior: **PASS**;
- Burn Garage outside/moving/CONTACT/SEARCH rejection + CLEAR repair: **PASS**;
- Mission 02 composition: **PASS**;
- retained P01–P06 focused regressions: **PASS**;
- nine-state rendered proof: **PASS and directly inspected**;
- literal-head Web export/static-host smoke: **PASS**;
- synthetic-merge Web export/static-host smoke: **PASS**;
- literal-head + merge Web persistence: **PASS**;
- current camera contracts + canonical 29-suite compatibility matrix: **PASS**.

Independent frozen review was attempted through both ChatGPT Codex code review and GitHub Copilot review. Both were unavailable because their review quotas were exhausted. A fresh exact-diff senior review in the coordinating ChatGPT session found no concrete blocker but was explicitly non-independent. The owner then explicitly waived the independent-review requirement. Treat this as an **OWNER-WAIVED GATE**, not as an independent approval.

### Exact-main verification

Exact gameplay merge:

`3deb1cccafdaeb9f3d6b1629e94f2a262cf3259d`

Verification-only PR #139 was opened against the pre-P07 base solely to force the P07 pull-request workflow to execute literal head `3deb1cccafdaeb9f3d6b1629e94f2a262cf3259d`; it was closed unmerged after verification.

Production-07 exact-main run `33833338289`:

- exact source checkout at `3deb1cccafdaeb9f3d6b1629e94f2a262cf3259d`: **PASS**;
- P07 vehicle semantics: **PASS**;
- Burn Garage repair runtime: **PASS**;
- Mission 02 composition: **PASS**;
- real collision runtime tracer: **PASS**;
- retained P01–P06 matrix: **PASS**;
- exact-main rendered proof capture/upload: **PASS**;
- artifact `9922447864`, digest `sha256:c63b4096b5aeb2e72be7e47b38b40400c7e884837ad3611c7c61c3d89d91d518`.

Production-06 exact-main retained run `33833186967` additionally proved P06 persistence/survey/input plus retained P01–P05 regressions and same-origin browser relaunch persistence at the same gameplay SHA.

Godot Web Playtest main push run `33833186949`:

- exact source checkout: **PASS**;
- mobile touch routing: **PASS**;
- desktop controls / alias ownership / vehicle authority / interaction cancel: **PASS**;
- Web export: **PASS**;
- static-host smoke: **PASS**;
- source revision stamp verification: **PASS**;
- public `playtest-web` publication: **PASS**.

Public source stamp:

`playtest-web/PLAYTEST_BUILD.txt = 3deb1cccafdaeb9f3d6b1629e94f2a262cf3259d`

## Post-Production-07 re-evaluation state

Production 07 closes the immediate vehicle-consequence gap without bootstrapping ownership, maintenance, damage, or Garage networks. The player can now materially batter either retained vehicle, feel one bounded limp consequence, decide whether to ditch/swap/continue, and recover at one authored Garage while Wanted and Mission authority remain trustworthy.

**Production 08 is not selected yet.** Re-evaluate from exact runnable behavior rather than numbering momentum.

Leading credible next gaps to compare:

1. **moment-to-moment vehicle feel / authored escape pressure** — P07 gives condition meaning, but the highest-value next gain may be a small handling/encounter pressure improvement rather than ownership systems;
2. **next bounded Street-Combat depth** — P05 proves committed physical counterplay, but any increment must improve immediate fight/escape feel without creating a generic health/damage/death framework by default;
3. **authored relationship / Standing consequence** — only if one small local outcome visibly changes later interactions without a broad reputation authority system;
4. **deeper authored city mastery** — another deliberately authored shortcut/knowledge payoff only if it adds a distinct decision rather than generalizing P06 into a Service Network or GPS layer;
5. **vehicle identity / claiming** — reconsider only if current play proves ownership meaning outranks its persistence/schema/UX complexity.

Heat escalation, generalized witnesses/surveillance, transit, broader geography, generalized persistence, Garage networks, economy, companion navigation, and generalized vehicle/damage architecture remain later candidates unless current play proves they outrank smaller authored gains.

## Retained foundations / deferred lanes

Do not recreate retained Feel tickets #12–#16, Missions 01–03, Open World Expansion 01A–01D, World Event 01 / PR #68, or Productions 01–07 because older roadmaps describe them historically.

FB-13 / HS-7 remain authored persistent companions in canon. P07 does not create a generalized companion/navigation framework.

Audio Production remains a first-class parallel lane. Refresh live Audio branches/PRs before shared-scene/audio mutation. Actual perceptual audio claims require playback evidence.

PR #44 — CTW Feel 03 camera occlusion readability — remains **DEFERRED** unless fresh evidence materially changes priority.

## Verification / human-gate debt

Still not completed unless fresh evidence says otherwise:

- native desktop average/P95 frame-time qualification on dedicated desktop hardware;
- broader fresh-player perceptual qualification;
- physical touch-conditioner A/B before changing touch steering defaults;
- human/windowed listening where actual playback quality is the question;
- real mobile performance until measured on hardware.

Small reversible production increments may continue when they do not depend on those unanswered gates.

## Local worktree truth

This continuity update was executed through isolated GitHub branch/PR operations. No local checkout was established by this ChatGPT execution path; an attempted isolated container clone failed before checkout because the container could not resolve GitHub DNS and produced no verification evidence.

Until a local executor proves otherwise, local branch / HEAD / upstream / dirty state are **UNKNOWN**. Verify them before local mutation and preserve unrelated user/concurrent work.

A temporary branch `verify/p07-exact-main-base` was created only to support exact-main PR verification. The available GitHub mutation surface could close PR #139 but could not delete that branch. It is inert, points at pre-P07 `f04aeadebf208e1ba0f3cba0090638c67d468838`, and is not implementation or continuity authority.

## Next-state rule

Next production session:

1. refresh exact `main`, open PRs/issues, CI, public playtest, and concurrent Audio/shared-scene state;
2. read `START_HERE.md`, issue #55, issue #118, and this continuity file;
3. verify local repo/branch/HEAD/upstream/dirty state before local code mutation;
4. re-evaluate post-P07 player-facing gaps by **fun / feel / clarity / cohesion / value / cost / risk**;
5. select exactly one bounded next production increment only after evidence supports it;
6. create the JIT ticket/spec for that increment;
7. execute `SPEC -> RED -> GREEN -> exact-head VERIFY -> frozen REVIEW (independent when available, or explicitly owner-waived if the owner changes the gate) -> REPAIR if needed -> MERGE -> exact-main VERIFY -> PUBLIC STAMP`;
8. update continuity only after verified changes land.

Create a new Wayfinder only for a genuinely new, foggy, multi-session cross-system design problem. `WAYFINDER_MAP.md` remains historical architecture context, not the live status tracker.
