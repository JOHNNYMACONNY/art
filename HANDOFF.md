# HANDOFF.md — Current Product Continuity

**Status:** `BURNSIDE_PRODUCTION_01_02_03_04_05_06_07_08_MERGED_VERIFIED__TWO_AXIS_REVIEW_POLISHED__READY_FOR_POST_PRODUCTION_08_REEVALUATION`  
**Verified production gameplay/public baseline:** `37c130b10db057ba923d5a9a6738081fa91e6fdf`  
**Final frozen Production-08 feature head:** `892c8eb0e32602b7974f2281ce9a81d0141abcf5`  
**Review polish feature head:** `39082b1c676d54cf535c366ff40cfbfe3b75c873`  
**Immutable Feel baseline:** `09fa2b0ab8aebc8a2ae54b989bffad7720503e48`  
**Engine:** Godot 4.7.1 Stable

> Continuity only. Refresh remote `main`, open PRs/issues, CI, public-playtest state, and any concurrent Audio/shared-scene work before repo-sensitive claims. A later docs-only continuity merge may make repository HEAD newer than the exact verified gameplay/public baseline above without changing runnable gameplay.

## Current product state

Burnside now has one dense qualified Gears production block where authored missions, Heat-1 Wanted / Contact-Search, local Field Hacking, civic reporting, reactive work-zone actors, the Scrapper Tool, physical pursuer counterplay, durable mapped route knowledge, coarse vehicle condition, one bounded Burn Garage repair loop, and authored FB-13 / HS-7 companion presence compose in the same geography.

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
- **Production 08** — #141 / PR #143 / PR #145 (review polish) — FB-13 / HS-7 Authored Companion Presence Tracer — `37c130b10db057ba923d5a9a6738081fa91e6fdf`.

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

## Production 08 — verified player-facing result

Issue #141 / PR #143: **COMPLETE / MERGED / EXACT-MAIN VERIFIED / PUBLIC VERIFIED** pending only this docs continuity merge and issue closure.

Frozen feature head:

`892c8eb0e32602b7974f2281ce9a81d0141abcf5`

Exact gameplay merge / verified public baseline:

`fb63d9ee853aed0e49b2c6b52edfff31cf43fda7`

Player loop:

`RUNNER ON FOOT -> FB-13 FOLLOWS LOCALLY / HS-7 CARRIED -> MOUNT BIKE/HAULER -> FB-13 DOCKS IN RACK/BED -> DISMOUNT -> FB-13 RELEASES TO FOLLOW -> SUSTAINED OFF-SCREEN SEPARATION -> OFF-SCREEN SNAP -> PHYSICAL REJOIN -> RETEAM`

Production truths:

- character-specific presence: FB-13 mobile drone body + HS-7 carried memory module;
- FB-13 is collisionless with no gameplay collision authority (no physics shove, cannot block Runner, vehicles, NPCs, or objectives);
- bounded local follow: side 2.1 m, trailing 1.8 m, height 1.15 m;
- clearance queries: one preferred candidate + one alternate mirrored candidate; holds/lags if both obstructed;
- follow speed (10.5 m/s) and acceleration (28.0 m/s²) intentionally outpace Runner's 8.5 m/s sprint so straight-line running does not force recovery;
- hard recovery: eligible only when separation >= 18.0 m sustained for >= 0.75 s while FB-13 is off-screen;
- deterministic recovery staging: up to 4 deterministic candidate positions on a 16.0 m ring around Runner evaluated for off-screen and clearance;
- recovery snap is off-screen source -> off-screen staging candidate only; visible catch-up is physical `REJOINING` movement at 15.0 m/s until within 5.0 m; zero visible popping;
- explicit vehicle dock sockets: CourierBike rear cargo rack (`FB13DockSocket`) and ScrapHauler cargo bed (`FB13DockSocket`);
- docking starts on retained vehicle `state_changed("MOUNTING")` and interpolates over 0.20 s, completing before the vehicle's 0.25 s mount;
- rejected dismount keeps FB-13 docked;
- successful dismount starts on retained vehicle `state_changed("DISMOUNTING")`, releasing FB-13 physically from vehicle origin;
- HS-7 carried visual instanced under Runner `MeshPivot/Torso/HS7CarrySocket` (presentation-only, moves with torso across all postures);
- retained `FB13ThrumWorldEvent` owns trigger/Audio authority; P08 adds only a local FB-13 body reaction (tilt + emission pulse) for <= 0.65 s; exactly one `FB13_THRUM` Audio event per trigger;
- full Replay resets transient companion presence only; P06 mapped knowledge survives intact; Mission 03 Memory Echo payload/order unchanged;
- no generalized companion AI, navmesh, `NavigationAgent3D`, companion manager, inventory, combat, or audio changes.

## Production 08 verification truth

### Frozen feature head

At `892c8eb0e32602b7974f2281ce9a81d0141abcf5`:

- exact-source P08 semantics/runtime: **PASS**;
- companion vehicle docking (Bike/Hauler mount, dock, rejected dismount, release): **PASS**;
- companion Thrum composition, Replay, P06 durability, Mission 03 regression: **PASS**;
- retained P01–P07 focused regressions (18 test suites): **PASS**;
- windowed rendered proof (6 screenshots + JSON report telemetry): **PASS and directly inspected**;
- literal-head Web export/static-host smoke: **PASS**;
- synthetic-merge Web export/static-host smoke: **PASS**;
- current camera contracts + canonical 29-suite compatibility matrix: **PASS**.

Independent two-axis review (Standards + Spec) was completed on the feature diff and followed by a dedicated review-polish cycle (PR #145), resolving:
- **Standards Axis**: Godot 4 typed signals (`node.signal_name.connect(...)`), variable declaration ordering (`@onready` after regular variables), vector math deduplication for follow target offsets, space state extraction helper `_get_space_state()`, and defensive null guards on Runner dereferences.
- **Spec Axis**: Linear dock interpolation via cached `_dock_start_transform`; outward 32px viewport boundary expansion (`vp_rect.grow(32.0)`) eliminating visual pop-in / mesh boundary edge clipping; Spec line 99 remain-in-place on failed hard rejoin; strict alignment of dock release to vehicle dismount; modeled `hs7_state: "CARRIED"` in runtime snapshot; full test coverage for Spec lines 279 (alternate follow target selection) and 281 (hard rejoin suppression under full staging ring occlusion); mobile viewport framing capture (`07_mobile_viewport_framing.png` at 400x700).

### Exact-main verification

Initial gameplay merge: `fb63d9ee853aed0e49b2c6b52edfff31cf43fda7`  
Post-review polished gameplay merge (PR #145): `37c130b10db057ba923d5a9a6738081fa91e6fdf`

Production-08 exact-main run `34160830753`:

- exact source checkout at `37c130b10db057ba923d5a9a6738081fa91e6fdf`: **PASS**;
- P08 semantics / runtime / docking / thrum: **PASS**;
- retained P01–P07 matrix (including camera mount transition and dynamic camera follow): **PASS**;
- exact-main rendered proof capture/upload (7 screenshots including mobile viewport framing): **PASS**;
- artifact `production08-rendered-proof-37c130b10db057ba923d5a9a6738081fa91e6fdf`.

Godot Web Playtest main push run `34160816224`:

- exact source checkout: **PASS**;
- mobile touch routing / desktop controls / vehicle authority / interaction cancel: **PASS**;
- Web export: **PASS**;
- static-host smoke: **PASS**;
- public `playtest-web` publication: **PASS**.

Public source stamp:

`playtest-web/PLAYTEST_BUILD.txt = 37c130b10db057ba923d5a9a6738081fa91e6fdf`

## Post-Production-08 re-evaluation state

Production 08 grounds FB-13 and HS-7 as visible, physical companions in ordinary Gears play. FB-13 follows, navigates local clearance, docks in both vehicles, reacts to the civic Thrum, and recovers off-screen without pop-in. HS-7 remains physically carried with Runner across on-foot and mounted postures. All of this was accomplished without a generalized companion AI, navmesh, save schema, or audio changes.

**Production 09 is not selected yet.** Re-evaluate from exact runnable behavior rather than numbering momentum.

Leading credible next gaps to compare:

1. **next bounded Street-Combat danger/depth** — P05 proves committed physical counterplay with the Scrapper Tool, but production still has no Player Health/Armor or escalating pursuer danger;
2. **authored relationship / Standing consequence** — one small local outcome that visibly changes later interactions or gate/access decisions without a broad reputation authority system;
3. **vehicle claiming / identity** — P07 gives condition and repair meaning, but vehicle ownership/claiming remains unaddressed;
4. **deeper authored city mastery** — another deliberately authored shortcut/knowledge payoff only if it adds a distinct decision rather than generalizing into a GPS layer;
5. **moment-to-moment vehicle feel / authored escape pressure** — handling/encounter pressure improvements under Heat-1 pursuit.

Heat escalation, generalized witnesses/surveillance, transit, broader geography, generalized persistence, Garage networks, economy, companion navigation, and generalized vehicle/damage architecture remain later candidates unless current play proves they outrank smaller authored gains.

## Retained foundations / deferred lanes

Do not recreate retained Feel tickets #12–#16, Missions 01–03, Open World Expansion 01A–01D, World Event 01 / PR #68, or Productions 01–08 because older roadmaps describe them historically.

FB-13 / HS-7 companion presence is now embodied in production gameplay. Do not add generalized companion AI or navmesh frameworks.

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

## Next-state rule

Next production session:

1. refresh exact `main`, open PRs/issues, CI, public playtest, and concurrent Audio/shared-scene state;
2. read `START_HERE.md`, issue #55, issue #118, and this continuity file;
3. verify local repo/branch/HEAD/upstream/dirty state before local code mutation;
4. re-evaluate post-P08 player-facing gaps by **fun / feel / clarity / cohesion / value / cost / risk**;
5. select exactly one bounded next production increment only after evidence supports it;
6. create the JIT ticket/spec for that increment;
7. execute `SPEC -> RED -> GREEN -> exact-head VERIFY -> frozen REVIEW (independent when available, or explicitly owner-waived if the owner changes the gate) -> REPAIR if needed -> MERGE -> exact-main VERIFY -> PUBLIC STAMP`;
8. update continuity only after verified changes land.

Create a new Wayfinder only for a genuinely new, foggy, multi-session cross-system design problem. `WAYFINDER_MAP.md` remains historical architecture context, not the live status tracker.
