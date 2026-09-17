# Burnside Production 05 — Gears Scrapper Tool / Street-Combat Contact Tracer

**Issue:** #131  
**Status:** `SPEC_COMMITTED__USER_REVIEW_REQUIRED`  
**Selection / branch baseline:** `main@6cdccb008778f845256b28797c5a3f1a92a2de75`  
**Verified Production-04 gameplay/public baseline:** `7605277d920b7877715d78687ccab16a69745b2f`

## Player value

Add Burnside's first production physical-tool verb without prematurely building a generalized combat system.

The player acquires one grounded industrial Scrapper Tool, uses it to force one jammed Gears service-access obstruction, triggers the existing local-reaction / civic-Report consequence chain, and can use one close physical hit against the existing Heat-1 pursuer to buy a brief escape window through the newly opened ServiceAlley / NorthConnector route.

The target feeling is:

> "That went completely sideways, and somehow I made it work."

More specifically:

`TAKE SCRAPPER TOOL -> FORCE JAMMED SERVICE ACCESS -> LOCAL WORK-ZONE REACTS -> REPORT ATTEMPT -> HEAT 1 + CONTACT -> PURSUER CLOSES -> TOOL IMPACT BUYS BRIEF SPACE -> SERVICE CUT -> BREAK CONTACT -> SEARCH / EVADE`

Prepared Field-Hacking composition remains:

`JAM REPORT LINK -> TAKE SCRAPPER TOOL -> FORCE SAME ACCESS -> LOCAL WORK-ZONE STILL REACTS -> REPORT SUPPRESSED -> NO NEW WANTED -> SERVICE CUT REMAINS USABLE`

## Canon and retained truths

Issue #118 defines Burnside Street Combat as permissive open-world violence built around movement, vehicles, geography, physical tools, and systemic improvisation. Scrapper Tools are multipurpose physical tools whose environmental function remains useful during violence.

Production 05 must preserve these already-qualified production truths:

- `PlayerRunner` owns on-foot locomotion, facing, procedural movement presentation, mounting posture, input locking, and footsteps; it is not a combat controller.
- `BurnsideWantedRuntime` / `WantedAuthority` remain sole owners of Heat, Contact, Search, Recognition, civic Report consequence, and Evasion.
- `PursuerPrototype` is already a physical collision-enabled chase entity with authored detours and deterministic recovery.
- `GearsWorkZoneIncident` already proves `LOCAL REACTION != CITY KNOWLEDGE`: actors alarm first, then the runtime may request the retained civic Report path.
- `GearsDistrictSlice01B` geometry owns no gameplay authority and already proves a legitimate rejoining `ServiceAlley -> NorthConnector` alternate route.
- the shared `Action` input is already consumed by multiple active-target runtimes and must not become the tool-attack signal.
- Production 04's shared civic-alarm / Mission-02 ordering repair must remain non-stranding.

## Architecture

Create one root-level `GearsScrapperToolRuntime` sibling composed onto existing Gears geography.

It owns only Production-05-local state:

- tool availability / held state;
- pickup lifecycle;
- swing window and cooldown;
- captured swing origin/direction;
- directional/range-bounded contact query;
- one jammed service-access obstruction;
- request to the retained P04 local-reaction seam;
- request to the pursuer's bounded physical-stagger seam;
- tool presentation and P05-local feedback;
- deterministic P05 reset.

It does **not** own:

- Wanted authority or knowledge;
- player locomotion;
- Health / Armor;
- inventory or equipment slots;
- NPC state or death;
- generalized damage;
- generalized crime/witness state;
- mission authority;
- generalized destructibles;
- generalized combat events.

Do not put Production-05 gameplay logic into `godot/scripts/prototype/scrap_test_block.gd` beyond the minimum retained composition seam that existing architecture genuinely requires.

## Scrapper Tool acquisition

Use one locally authored breaker-bar / pry-tool / industrial salvage implement.

Acquisition is an ordinary contextual world interaction, not a new inventory system.

Use one narrow `ScrapperToolPickup` participating in the retained `InteractableBase` / active-target arbitration.

Required acquisition behavior:

`NOT HELD + PICKUP IS ACTIVE TARGET + ACTION -> HELD`

After acquisition:

- the pickup becomes unavailable/hidden for the current run;
- the held tool becomes visually readable on the player;
- the dedicated Tool Action becomes available while on foot;
- no inventory screen, item slot, weapon wheel, loot ownership, save state, or equipment framework is created.

Pickup may use the retained generic Action path because it is a contextual interaction selected through existing active-target arbitration. **Swinging may not use that Action path.**

## Dedicated Tool Action input

Add one explicit `tool_action_pressed` signal to the retained touch-control surface.

Desktop default:

- `E` remains retained `ACTION`;
- `F` becomes Production-05 `TOOL`.

`F` is the selected desktop binding because current production has no retained `F` ownership while `E` is already multiplexed across ordinary interactions.

Touch:

- add one `ToolActionButton` inside the existing `SafeAreaRoot/RightTouchArea`;
- place it in the retained safe-area control lane without overlapping Action or vehicle controls;
- hide it when the Scrapper Tool is not held;
- show it only for on-foot tool use;
- hide/disable it while vehicle driving or while another retained input-lock/gesture state owns interaction;
- preserve pointer ownership and touch-release safety contracts.

Required invariant:

`tool_action_pressed` must never emit or synthesize `action_button_pressed`, and one physical press must never be processed simultaneously as ordinary Action and tool use.

## PlayerRunner seam

Add at most one pure directional query to `PlayerRunner`, preferably equivalent to:

`get_facing_direction() -> Vector3`

The query exposes the player's current horizontal facing derived from retained presentation orientation.

Do not add attack state, combat stance, damage state, cooldown, hit detection, target selection, or weapon ownership to `PlayerRunner`.

The P05 runtime owns the held-tool visual and swing state. Avoid taking ownership of the retained procedural arm animation unless windowed proof demonstrates that tool readability cannot be achieved without a narrowly justified presentation seam.

## Swing/contact model

A Scrapper swing is one committed physical action, not a damage event.

On accepted Tool Action:

1. validate tool held, on foot, player not input-locked, and cooldown clear;
2. capture player world origin and horizontal facing direction;
3. begin a readable swing presentation;
4. perform exactly one contact evaluation at the authored impact moment;
5. resolve at most one eligible contact;
6. enter a short recovery/cooldown before another accepted swing.

Contact must be both range-bounded and directional.

Initial implementation targets, explicitly tunable by RED/windowed evidence:

- impact moment: approximately `0.14 s` after accepted input;
- total swing/recovery: approximately `0.60 s`;
- maximum physical reach: approximately `1.8 m` from the captured origin;
- forward qualification: target direction dot captured facing approximately `>= 0.5`;
- exactly one contact query per accepted swing.

These are production tuning targets, not permanent canon.

The captured direction is fixed for that swing's contact evaluation. A player may continue moving normally, but rotating after button press must not sweep an arbitrary hit volume through unrelated targets.

Eligible Production-05 contacts are deliberately closed:

1. the one `JammedServiceAccess`, if still jammed;
2. the active `PursuerPrototype`, when its narrow P05 physical-contact preconditions are satisfied;
3. otherwise `MISS` / out-of-range feedback.

If more than one eligible candidate qualifies, resolve only the nearest valid candidate.

Do not create a generalized target registry, hit-point system, damage amount, damage interface, health component, combo tree, heavy/light hierarchy, aim mode, or lock-on.

## Jammed service access

Create one P05-owned authored obstruction at the existing `GearsDistrictSlice01B/ServiceAlleyEntrySocket` seam.

State is intentionally binary:

`JAMMED -> FORCED_OPEN`

Before forcing, the obstruction must block or materially restrict the ServiceAlley entry for the on-foot escape path.

A legitimate Scrapper Tool strike while `JAMMED`:

1. changes the access state exactly once to `FORCED_OPEN`;
2. visibly changes the obstruction presentation;
3. removes/disables the authored blocking collision so traversal materially changes;
4. triggers the narrow P04 local-disruption seam;
5. leaves the route open for the remainder of that run until Replay/reset.

Do not add obstruction health, repeated damage, universal destructibility, reusable door bases, route-unlock registries, map reveal, or new acreage.

The existing `ServiceAlley -> NorthConnector -> NorthRoad` route must remain physically legitimate after forcing the access.

## Production-04 local-reaction composition

Add one explicit P05-facing method to `GearsWorkZoneIncident`, equivalent to:

`trigger_service_access_disruption(observed_position: Vector3) -> bool`

This is intentionally a concrete authored seam, not a generalized event bus or witness API.

Its required ordering is:

1. reject duplicate escalation when incident-local state does not allow another escalation in the same cycle;
2. alarm the current `GearsWorker` and `GearsCrawler` through their retained `trigger_alarm()` behavior;
3. preserve that local reaction regardless of city Report outcome;
4. if existing Heat is already greater than zero, do not request another civic Report and do not mutate authority;
5. otherwise request the retained civic Report through `BurnsideWantedRuntime.request_civic_report(observed_position)`;
6. never call or mutate `WantedAuthority` directly.

Required outcomes:

### Reporting live

`FORCE ACCESS -> LOCAL ALARM / RETREAT -> REPORT SENT -> HEAT 1 + CONTACT`

### Reporting jammed

`JAM REPORT LINK -> FORCE ACCESS -> LOCAL ALARM / RETREAT -> REPORT SUPPRESSED -> CLEAR remains CLEAR`

### Pre-existing Wanted

`VALID WANTED -> FORCE ACCESS -> LOCAL ALARM / RETREAT -> NO REDUNDANT REPORT -> EXISTING HEAT / CONTACT / SEARCH / RECOGNITION PRESERVED`

Field Hacking suppresses future civic communication only. It may not suppress or erase the local worker/crawler response.

## Pursuer physical stagger

Add one explicit P05-facing method to `PursuerPrototype`, equivalent to:

`apply_scrapper_stagger(hit_direction: Vector3) -> bool`

This is a bounded physical motion modifier, not a combat/damage interface and not a new Wanted state.

A valid contact may be accepted only when the pursuer is actively participating in hostile `CHASING` or `DETOURING` behavior and is within the Scrapper Tool's directional/range contact contract.

On accepted contact:

- visibly interrupt acceleration/chase motion for a very short interval;
- create a small readable displacement away from the hit direction;
- preserve the pursuer's current chase/detour ownership and target authority;
- automatically recover into the existing chase behavior without external reactivation.

Initial feel target, tunable by windowed evidence:

- approximately `0.25–0.35 s` of meaningful motion interruption;
- approximately `1 m` class of readable physical space rather than a long stun;
- recovery must occur before the player can establish an indefinite stun-lock loop under the retained swing cooldown.

The stagger may **not**:

- set `is_active = false`;
- clear or modify Heat;
- clear Contact, Search, or Recognition;
- mutate `WantedAuthority`;
- clear `target_node` as a knowledge shortcut;
- permanently disable the pursuer;
- convert the pursuer into a Health/death target;
- replace authored detours with a combat navigation system.

Pursuer reset must clear any remaining P05 stagger timer/velocity modifier deterministically.

## Health / damage boundary

Do not add Player Health, Armor, NPC Health, NPC death, `Damageable`, damage numbers, generic hit reactions, hostile pedestrian combat AI, or combat failure-state ownership in Production 05.

The retained pursuer interception/failure pressure is the danger boundary for this contact tracer.

If RED/windowed proof demonstrates that the slice cannot credibly function without Health/Armor or broader hostile combat AI, stop and re-evaluate Production-05 scope instead of silently expanding.

## Presentation

Minimum elevated-camera reads must distinguish:

- Scrapper Tool available in world;
- tool acquired / visibly held;
- accepted swing and physical commitment;
- miss/out-of-range swing;
- service-access strike;
- service access visibly forced open;
- local worker/crawler alarm/retreat;
- Report Sent versus Report Suppressed using retained authority feedback;
- pursuer impact;
- pursuer stagger and automatic recovery.

Prefer a strong tool silhouette and simple world-space swing motion before modifying retained player limb animation.

Do not add aim mode, lock-on indicator, combo UI, damage numbers, weapon HUD, or weapon wheel.

## Audio boundary

Production-05 architecture has no required new shared Audio dependency.

Do not repurpose vehicle-collision semantic events as melee/tool events.

Before any edit to `AudioManager`, audio registries, semantic event IDs, production media, asset resolver, or actor audio:

1. refresh live open PRs/branches and current Audio Production concurrency;
2. prove the visual/physical tracer has a concrete semantic audio gap worth touching shared Audio for;
3. add only the narrow correct semantic event required by this slice.

Automated event/registry correctness does not establish perceptual audio quality. Listening/playback evidence is required for any perceptual PASS claim.

## Deterministic reset

`GearsScrapperToolRuntime.reset_runtime()` must restore all and only P05-local state:

- tool possession false;
- pickup available/visible at authored start state;
- held-tool visual hidden/restored;
- swing state idle;
- swing/cooldown timers zeroed;
- jammed service access restored with blocking collision active;
- Tool Action UI hidden and no stale input ownership;
- any P05-local contact bookkeeping cleared.

`PursuerPrototype.reset_pursuer()` must clear its P05 stagger modifier/timer as part of the pursuer's own deterministic reset.

`GearsWorkZoneIncident` continues to own/reset its actor pair and incident-local alarm state.

`BurnsideWantedRuntime` continues to own/reset Wanted and civic-report service state.

P05 may not call an authority-clearing shortcut as part of its own reset.

Replay signal ordering must be tested so that independent owners resetting in a different callback order cannot leave possession, access, stagger, cooldown, local-reaction, input, or Wanted state inconsistent.

No save-schema work enters this slice.

## Expected production file boundary

Expected new focused production files:

- `godot/scripts/world/gears_scrapper_tool_runtime.gd`;
- `godot/scripts/interactions/scrapper_tool_pickup.gd`;
- one scene/resource for the pickup/tool only if the retained scene architecture benefits from it;
- focused Production-05 tests and windowed proof capture.

Expected narrow edits:

- `godot/scripts/input/touch_controls.gd` — dedicated Tool signal/binding/pointer ownership only;
- `godot/scenes/prototype/scrap_test_block.tscn` — dedicated safe-area Tool button and minimal composition only;
- `godot/scripts/player/runner.gd` — pure facing query only if required;
- `godot/scripts/entities/pursuer_prototype.gd` — bounded P05 stagger modifier only;
- `godot/scripts/world/gears_work_zone_incident.gd` — one explicit service-access disruption seam;
- `godot/scripts/visual/gears_district_slice_01b.gd` — only the minimum sibling-mount/spatial-composition seam if required while preserving `owns_no_gameplay_authority`.

This list is a boundary, not permission to modify every listed file. The implementation should use fewer files where existing seams make that possible.

Unexpected need to modify Wanted authority, Mission-02 behavior, save schema, vehicle controllers, generalized actor AI, or shared Audio architecture is a stop/re-evaluate signal.

## Required RED contract

Before GREEN behavior implementation, the focused Production-05 tests must first fail against the selected baseline because the new capability is absent, then prove at minimum:

1. production currently lacks a physical Scrapper Tool action;
2. one authored Scrapper Tool can be acquired through retained contextual interaction without an inventory framework;
3. the dedicated Tool Action is distinct from generic Action on desktop and touch;
4. one tool press cannot double-fire generic Action;
5. touch Tool control remains inside safe-area/pointer-ownership contracts and leaves no stale pointer state;
6. tool use is accepted only while held, on foot, unlocked, and off cooldown;
7. one accepted swing captures direction, performs exactly one contact evaluation, is range-bounded and directional, and cannot hit at arbitrary distance or by post-press spin sweeping;
8. a miss/out-of-range swing produces no environment/pursuer mutation;
9. exactly one Gears service-access obstruction starts jammed and materially restricts the existing ServiceAlley entry;
10. valid tool contact forces that access exactly once and materially changes traversability;
11. the existing `ServiceAlley -> NorthConnector` route remains a legitimate rejoining route after forcing;
12. forcing the access alarms the retained P04 `GearsWorker` and `GearsCrawler` through the incident seam;
13. ordinary live reporting from CLEAR produces existing Heat 1 + Contact;
14. jammed reporting suppresses the city consequence while the local actor reaction still occurs;
15. pre-existing Wanted survives forcing the access without redundant Report or authority reset;
16. legitimate close-range tool contact can briefly disrupt active pursuer motion without clearing/deactivating Wanted or permanently disabling the pursuer;
17. pursuer stagger automatically expires and normal chase/detour behavior resumes;
18. Replay/reset clears P05 possession/access/swing/cooldown/stagger/input state deterministically without P05 clearing authority;
19. Mission-02 shared civic-report ordering remains non-stranding after a P05 suppressed Report consumes/faults the shared local alarm;
20. retained Production-01 through Production-04 focused regressions remain green after GREEN implementation.

## Verification gate

After written-spec review and approval:

`SPEC APPROVAL -> RED -> GREEN -> exact-head VERIFY -> frozen Standards + #131 REVIEW -> REPAIR if needed -> MERGE -> exact-main VERIFY -> PUBLIC PLAYTEST STAMP -> CONTINUITY UPDATE`

Focused verification must include:

- Production-05 tool acquisition / directional swing / miss / service-access / pursuer-contact tracer;
- P05 dedicated desktop + touch Tool Action and input ownership;
- P04 work-zone local reaction / civic-report behavior;
- P04 Mission-02 ordering regression extended to the P05 suppressed-report ordering where required;
- P03 Mission-02 / Wanted composition;
- P03 pre-triggered suppression regression;
- P02 Field-Hacking suppression;
- P01 Heat-1 real-scene tracer;
- retained desktop controls, alias ownership, vehicle authority, interaction cancel, touch routing and safe-area contracts;
- retained camera and district compatibility contracts;
- canonical compatibility matrix;
- windowed visual proof that acquisition, swing, forced access, local alarm, pursuer impact and recovery are readable;
- Godot Web export and public playtest source-revision stamp.

Audio listening proof is required only if P05 makes perceptual audio-quality claims.

## Scope exclusions

Do not silently add:

- generalized combat framework;
- Player Health / Armor;
- firearms;
- weapon roster, weapon wheel or ammo;
- NPC Health/death;
- `Damageable` or generic damage interfaces;
- hostile pedestrian combat AI;
- inventory, loot, rarity, stats, skill trees or RPG progression;
- generalized destructibles;
- generalized witnesses/crime/event bus;
- Heat 2–5;
- vehicle damage/condition/claiming;
- generalized route-unlock or map-discovery infrastructure;
- transit or new acreage;
- PR #44 camera-occlusion work;
- companion framework;
- unrelated Audio Production.

## Kill / repair conditions

Stop and re-scope rather than silently expand if credible implementation requires generalized combat architecture, Health/Armor, hostile-NPC combat AI, generic damage interfaces, generalized destructibles, central-controller expansion, major Audio redesign, or authority mutation.

Repair before merge if:

- tool impact feels like an arbitrary button check rather than a physical city verb;
- directional/range limits are visually misleading;
- the ServiceAlley route payoff is fake or unnecessary;
- local actors fail to react to forcing access;
- Field Hacking erases local reaction instead of only suppressing Report;
- pursuer stagger trivializes Heat or supports stun-lock;
- Tool Action double-fires generic Action;
- reset leaks possession/access/stagger/cooldown/input state;
- Mission-02 ordering regresses;
- Web/public behavior diverges from exact-head verification.

## Completion result

Production 05 is complete only when one grounded Scrapper Tool works credibly as both a physical city instrument and desperate improvised counterplay; forcing the service access creates a real route change and local consequence; Field Hacking preserves the local-vs-city knowledge distinction; the existing Heat-1 pursuer remains authoritative but physically interactable; retained regressions pass; exact-main and public playtest proof pass; and continuity is updated with verified truth only.
