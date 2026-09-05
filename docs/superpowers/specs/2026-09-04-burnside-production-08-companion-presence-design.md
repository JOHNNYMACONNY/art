# Burnside Production 08 — FB-13 / HS-7 Authored Companion Presence Design

**Status:** DESIGN APPROVED / WRITTEN SPEC REVIEW GATE  
**Repository:** `JOHNNYMACONNY/art`  
**Design baseline:** `main@17d94759667b3c4b5ea7cd6f9992f5de922927a4`  
**Exact verified gameplay/public baseline:** `3deb1cccafdaeb9f3d6b1629e94f2a262cf3259d`  
**Product anchor:** #55  
**Canonical production contract:** #118

## 1. Purpose

Production 08 should make FB-13 and HS-7 feel like actual authored companions occupying the same physical world as Runner during ordinary Gears play.

The first tracer is intentionally asymmetric:

- **FB-13** is the visibly mobile companion body.
- **HS-7** is a compact memory-bearing companion carried with Runner.

This is not a generic companion system. It is one authored presence loop for two specific characters.

The player-facing loop is:

`RUNNER + FB-13 LOCAL PRESENCE + HS-7 CARRIED PRESENCE -> MOVE THROUGH GEARS -> FB-13 MAINTAINS AUTHORED TRAILING SPACE -> MOUNT VEHICLE -> FB-13 DOCKS / HS-7 REMAINS WITH RUNNER -> DRIVE -> DISMOUNT -> FB-13 RELEASES AND REJOINS -> REPLAY RESTORES CANONICAL PAIR STATE`

## 2. Canon decisions locked for this production slice

The current playable production slice begins with both companions already reconstructed/acquired and traveling with Runner.

This decision applies to the current playable slice only. It does not establish the exact larger-game acquisition chronology, reconstruction scene, relationship history, or when each companion first became functional.

FB-13 remains a specific authored machine companion associated with its retained Thrum behavior.

HS-7 remains a specific authored memory-bearing companion. Mission 03 truth remains intact: HS-7 keeps a memory the city paid to lose, and that memory can be brought to the Silent Core.

Production 08 does not establish:

- generic robot recruitment;
- companion progression;
- companion relationship meters;
- combat roles;
- autonomous hacking roles;
- navigation authority;
- inventory utility;
- companion health/damage;
- companion death/destruction;
- additional acquisition chronology outside the current slice.

## 3. Character embodiment

### FB-13

FB-13 is the mobile embodied companion in ordinary free roam.

Its production body should read as a compact repurposed industrial companion machine consistent with the approved Gears visual direction and retained historical FB-13 identity. It should remain visually distinct from ambient Utility Crawlers and humanoid bot families.

FB-13 has no gameplay collision authority in P08. It must not shove Runner, block vehicles, obstruct NPC movement, trigger Wanted, become an interaction target, or alter mission collision.

Its movement is authored local presence, not autonomous city navigation.

### HS-7

HS-7 is visibly carried with Runner as a compact memory/core module.

The implementation should attach HS-7 to an authored carry socket on Runner's existing visible rig/satchel area. It remains physically with Runner on foot and while mounted because Runner itself remains bound to vehicle RiderSocket geometry.

HS-7 does not independently walk, hover, pathfind, teleport around the city, or become a second follower in P08.

Its presentation should preserve the established sparse cyan/memory visual language without adding new Audio.

## 4. FB-13 local follow contract

FB-13 follows Runner using a bounded desired-offset behavior on the existing Gears geography.

Normal on-foot behavior:

1. Maintain an authored trailing/side offset near Runner rather than occupying Runner's exact path.
2. Use smooth local acceleration/deceleration rather than snapping each frame.
3. Use short-range static-geometry clearance queries to avoid obvious wall/prop penetration.
4. When the preferred offset is obstructed, try one bounded alternate side offset.
5. If both local offsets are obstructed, allow FB-13 to lag temporarily rather than invoke general pathfinding.
6. Once local space becomes available, FB-13 resumes the normal follow offset.

The implementation must not use `NavigationAgent3D`, a navmesh, A*, global route planning, or a reusable companion-navigation service.

FB-13 may move vertically only as necessary for its authored compact hover/body presentation. Vertical movement must remain visually modest and must not imply unrestricted flight across level geometry.

## 5. Separation and off-camera rejoin

Ordinary physical following is preferred whenever supported by local space.

A hard authored catch-up is permitted only as a recovery mechanism when FB-13 has fallen substantially behind because of geometry, vehicle transitions, or player speed.

Rejoin contract:

1. Normal local follow remains authoritative until FB-13 is at least `18.0 m` from Runner.
2. Hard rejoin becomes eligible only if that separation persists for at least `0.75 s` and FB-13's current body position is outside the active camera viewport.
3. Recovery evaluates at most four deterministic staging candidates on a `16.0 m` ring around Runner, derived from the active camera's horizontal forward/right basis.
4. A staging candidate is valid only if it is outside the active camera viewport and passes the same bounded local static-geometry clearance used by ordinary follow behavior.
5. If no staging candidate is valid, no hard rejoin occurs; FB-13 remains where it is and eligibility is checked again later.
6. If a staging candidate is valid, FB-13 may snap only from its already-off-screen source position to that already-off-screen staging position.
7. After that snap, FB-13 enters `REJOINING` and physically moves from the staging point toward the normal authored follow offset using a bounded catch-up speed. It may become visible during this physical return; the teleport portion itself must never be visible.
8. `REJOINING` ends when FB-13 returns within `5.0 m` of Runner, at which point normal `FOLLOWING` resumes.
9. Vehicle mounting overrides `REJOINING` and transitions into the appropriate vehicle dock state.
10. Hard rejoin must not mutate Runner, vehicle, mission, Wanted, map, persistence, or Audio state.
11. Any directly visible teleport or repeated pop-in is a merge blocker.

Normal follow speed, acceleration, side-offset dimensions, and the bounded `REJOINING` catch-up speed are implementation tuning values. They may be tuned under rendered proof, but the final frozen values must be deterministic, test-covered, and recorded in the implementation contract before freeze.

## 6. Vehicle mount / dock contract

Production 08 supports exactly the retained `CourierBike` and `ScrapHauler`.

### CourierBike

Add one explicit `FB13DockSocket` using the existing rear cargo-rack area.

### ScrapHauler

Add one explicit `FB13DockSocket` using the existing cargo-bed area.

Vehicle transition behavior:

1. When the supported vehicle enters its retained mount transition, FB-13 leaves local follow/rejoin mode.
2. FB-13 moves/blends into that vehicle's authored dock socket during the retained mount transition rather than disappearing from an exposed world position.
3. While driving, FB-13 stays docked to the active vehicle.
4. HS-7 remains attached to Runner and therefore moves with Runner's retained mounted posture/RiderSocket behavior.
5. On successful dismount, FB-13 releases from the vehicle socket and resumes local follow from the vehicle's physical location.
6. A rejected dismount leaves both companion states unchanged.
7. Unsupported future vehicles receive no automatic P08 behavior.

No vehicle handling, condition, repair, collision, speed, mount range, dismount safety, radio, camera, or ownership behavior changes are authorized by this design.

## 7. Contextual authored reaction

P08 adds exactly one new contextual companion reaction: the visible FB-13 body acknowledges the existing retained Thrum world event.

The existing `FB13ThrumWorldEvent` remains the authority for:

- trigger radius;
- cooldown/hysteresis;
- retained `AudioManager` call;
- infrastructure material pulse;
- event count/payload.

P08 may listen to the existing `thrum_triggered` signal and drive a brief FB-13 body reaction such as a small brace/tilt and body-emission pulse.

This reaction:

- adds no new Audio event;
- does not retrigger or alter the retained Thrum event;
- does not alter event cooldown;
- does not change mission state;
- does not add interaction input;
- does not create a generalized companion-reaction event bus.

HS-7 receives no additional sandbox ability or reaction in this tracer. Its Mission 03 memory role remains special.

## 8. Runtime ownership and architecture

Use character-specific, bounded components.

Recommended production structure:

- `godot/scripts/world/burnside_companion_presence_runtime.gd`
  - owns P08 presence orchestration only;
  - binds Runner, FB-13 body, supported vehicle mount/dismount state, Replay/reset, and the retained FB-13 Thrum signal;
  - owns no combat, hacking, navigation, inventory, persistence, Wanted, mission, or Audio authority.

- `godot/scenes/entities/fb13_companion_body.tscn`
- `godot/scripts/entities/fb13_companion_body.gd`
  - owns FB-13 local movement, local static-geometry clearance, dock interpolation, viewport visibility/rejoin staging, and visual Thrum reaction only.

- one small HS-7 carried visual scene or bounded Runner child composition;
- `HS7CarrySocket` on Runner;
- `FB13DockSocket` on CourierBike;
- `FB13DockSocket` on ScrapHauler.

Do not create:

- `CompanionManager`;
- generic companion base classes solely for hypothetical later companions;
- companion registries;
- generic dock registries;
- shared companion save schemas;
- nav services;
- command wheels;
- companion HUD panels.

If later production proves multiple authored companions need a genuine shared abstraction, that architecture can be introduced then from real duplication evidence.

## 9. State model

The P08 runtime needs only enough state to represent current physical presence.

FB-13 externally testable presence states:

- `FOLLOWING`
- `REJOINING`
- `DOCKING_BIKE`
- `DOCKED_BIKE`
- `DOCKING_HAULER`
- `DOCKED_HAULER`

HS-7 state in P08 is always `CARRIED` during ordinary playable runtime.

No P08 companion state is written to disk.

## 10. Replay / reset

Full Replay restores canonical P08 presence state without touching durable P06 map knowledge.

Replay must:

- detach FB-13 from any vehicle socket;
- clear any in-progress dock/rejoin interpolation;
- restore FB-13 to the authored initial follow-side position near Runner;
- restore FB-13 to `FOLLOWING`;
- restore HS-7 to its Runner carry socket;
- clear transient FB-13 Thrum-body reaction state;
- leave P06 `user://burnside_mapped_knowledge.json` untouched;
- leave vehicle condition reset under retained P07 authority;
- leave Wanted reset under retained Replay authority;
- create no companion save file or schema.

## 11. Camera and readability

The retained dynamic 3/4 camera remains authoritative. P08 does not retune camera position, yaw, focus, look-ahead, FOV, or interaction framing.

Rendered proof must establish that:

- FB-13 is readable during ordinary on-foot movement without covering Runner;
- HS-7 reads as an attached authored object rather than a HUD marker or floating icon;
- FB-13 does not repeatedly cross the camera/Runner line in a distracting way;
- Bike and Hauler dock positions remain visually believable from retained driving framing;
- FB-13 does not obscure vehicle-condition tags, mission HUD, Garage affordances, or interaction targets;
- off-camera rejoin staging does not produce visible teleport/pop-in;
- mobile viewport framing remains usable;
- any implementation scale/presentation tuning is bounded to companion visuals and sockets rather than camera changes.

## 12. Performance constraints

P08 should remain cheap enough to run continuously.

Allowed recurring work:

- one local desired-offset update for FB-13;
- a small bounded set of local geometry clearance queries;
- active camera visibility checks needed for recovery;
- at most four fixed recovery-candidate checks when hard rejoin is eligible;
- simple interpolation and presentation animation.

Not allowed without new measured evidence:

- navmesh baking/runtime navigation;
- broad physics scans;
- global scene searches every frame;
- generalized perception loops;
- companion combat target acquisition;
- high-frequency allocation-heavy path queries.

## 13. Shared-scene / Audio boundary

Audio remains outside P08.

The retained FB-13 Thrum Audio behavior must remain behaviorally unchanged unless a separately authorized Audio change is proven necessary.

P08 may modify shared Runner / CourierBike / ScrapHauler scene structure only to add the approved named companion sockets/visual attachment seam. It must not mutate retained Audio resources, event IDs, mix behavior, radio behavior, vehicle feedback Audio, or Audio registries.

Before implementation mutation, refresh live Audio branches/PRs and inspect any concurrent shared-scene changes.

## 14. Required tests and proof

Implementation must be test-driven.

Focused P08 verification must cover at minimum:

1. cold start places FB-13 in `FOLLOWING` and HS-7 in the Runner carry socket;
2. FB-13 follows Runner while preserving the authored side/trailing relationship;
3. blocked preferred offset uses only the bounded alternate local behavior;
4. local obstruction does not invoke navmesh/pathfinding;
5. hard rejoin remains ineligible below `18.0 m`, before `0.75 s`, while FB-13 is visible, or when all four deterministic staging candidates are visible/blocked;
6. eligible recovery snaps only between off-screen source/staging positions, then enters `REJOINING` and physically returns before resuming `FOLLOWING` within `5.0 m`;
7. CourierBike mount transitions FB-13 into the Bike dock and retains HS-7 with Runner;
8. CourierBike dismount releases FB-13 physically from the Bike location;
9. ScrapHauler mount/dismount satisfies the equivalent contract;
10. rejected dismount does not corrupt companion state;
11. mounting during `REJOINING` cleanly transfers FB-13 into the correct dock state;
12. retained FB-13 Thrum triggers exactly once under its old rules while the body performs only its visual reaction;
13. Mission 03 / HS-7 Memory Echo ordering and authored payload remain unchanged;
14. Replay restores canonical P08 state and does not modify durable P06 mapped knowledge;
15. retained P07 vehicle condition/repair behavior remains unchanged;
16. retained P01-P07 focused regression suites remain green;
17. current camera contracts remain green;
18. literal-head Web export/static-host smoke passes;
19. exact-head rendered evidence proves on-foot, Bike-docked, Hauler-docked, Thrum reaction, physical dismount/release, off-camera recovery return, and mobile-readable states.

The final frozen candidate must be reviewed against this design/spec and the eventual implementation plan before merge.

## 15. Explicit exclusions

Production 08 excludes:

- generalized companion architecture;
- generic robot recruitment;
- companion inventory;
- companion health/damage/death;
- companion combat AI;
- companion autonomous hacking;
- universal pathfinding/navmesh AI;
- companion GPS/minimap/navigation authority;
- relationship/Standing meters;
- companion upgrade trees;
- companion persistence/save-schema expansion;
- new vehicle ownership;
- Garage expansion;
- Wanted changes;
- map-knowledge/navigation changes;
- Audio mutation;
- new companion input/command UI;
- silent canon expansion outside the current playable-slice chronology decision.

## 16. Success criteria

P08 succeeds when ordinary movement through Gears visibly communicates all of the following without explanatory UI:

- Runner is traveling with two specific companions;
- FB-13 has its own physical presence and follows in a grounded authored way;
- HS-7 is physically part of the traveling group rather than existing only in mission text;
- entering a vehicle changes companion placement intentionally rather than making characters vanish arbitrarily;
- losing local geometry does not expose obviously magical companion navigation;
- the existing FB-13 Thrum now visibly belongs to FB-13;
- Mission 03's HS-7 memory identity remains intact;
- the implementation remains small enough that deleting P08 would not require dismantling a generalized companion framework.

The target feeling is not "the game now has follower AI."

The target feeling is: **"FB-13 and HS-7 are actually here with me."**
