# Burnside Production 08 Companion Presence Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make FB-13 and HS-7 visibly occupy the same ordinary Gears play-space as Runner: FB-13 follows locally and docks on the retained production vehicles, while HS-7 remains physically carried with Runner, without introducing generalized companion AI.

**Architecture:** Add one bounded `BurnsideCompanionPresenceRuntime` as the P08 orchestration seam and one character-specific `FB13CompanionBody` for local follow, off-camera recovery, docking interpolation, and Thrum presentation. HS-7 stays presentation-only and attached to a named Runner carry socket. Vehicle support is explicit through one named dock socket on CourierBike and ScrapHauler; retained vehicle `state_changed` transitions remain authoritative. No navigation service, companion manager, persistence, input, combat, hacking, Wanted, Garage, map, camera, or Audio authority is introduced.

**Tech Stack:** Godot 4.7.1 / GDScript, retained `PlayerRunner`, `CourierBike`, `ScrapHauler`, `ChinatownCamera3D`, `FB13ThrumWorldEvent`, GitHub Actions, Godot Web export.

**Spec:** `docs/superpowers/specs/2026-09-04-burnside-production-08-companion-presence-design.md`

## Global Constraints

- The current playable slice begins with FB-13 and HS-7 already reconstructed/acquired and traveling with Runner; this does not establish larger-game acquisition chronology.
- FB-13 is the mobile embodied companion; HS-7 is the carried memory-bearing companion.
- Hard recovery eligibility is `>= 18.0 m` separation sustained for `>= 0.75 s` while FB-13 is off-screen.
- Hard recovery may snap only from an off-screen source to an off-screen deterministic staging candidate on a `16.0 m` ring around Runner.
- After a hard recovery snap, FB-13 must enter `REJOINING` and physically return toward Runner; normal `FOLLOWING` resumes within `5.0 m`.
- Recovery evaluates at most four deterministic staging candidates.
- No `NavigationAgent3D`, navmesh, A*, global route planning, reusable companion navigation service, generalized `CompanionManager`, companion registry, or generic dock registry.
- FB-13 has no gameplay collision authority and must not shove/block Runner, vehicles, NPCs, missions, or interaction targets.
- CourierBike support is explicit through one `FB13DockSocket` at the existing rear cargo-rack area.
- ScrapHauler support is explicit through one `FB13DockSocket` at the existing cargo-bed area.
- HS-7 remains attached to Runner through one `HS7CarrySocket` in the existing visible torso/satchel composition.
- Existing `FB13ThrumWorldEvent` remains trigger/cooldown/Audio/infrastructure authority. P08 may consume only `thrum_triggered(event_payload: Dictionary)` for a visible FB-13 reaction.
- No new Audio event/resource/registry/mix/radio mutation.
- No companion save schema or file. Replay resets transient P08 state only and leaves `user://burnside_mapped_knowledge.json` untouched.
- Mission 03 HS-7 Memory Echo order/payload remains authoritative.
- P01-P07 Wanted, hacking, missions, combat-tool, map knowledge, vehicle handling/condition/repair, Garage, camera, input, and Replay contracts remain compatibility boundaries.
- PR #44 remains deferred.
- Before implementation mutation, reverify repo/branch/worktree/HEAD/upstream/dirty state plus open PRs and active Audio/shared-scene concurrency.

---

## File Structure

### Create

- `godot/scripts/entities/fb13_companion_body.gd` — FB-13 state, local follow, local clearance, off-camera recovery, docking interpolation, body-only Thrum reaction.
- `godot/scenes/entities/fb13_companion_body.tscn` — compact collisionless FB-13 visual body.
- `godot/scenes/entities/hs7_carried_module.tscn` — compact HS-7 carried visual with no gameplay authority.
- `godot/scripts/world/burnside_companion_presence_runtime.gd` — character-specific P08 orchestration over Runner, camera, two supported vehicles, Replay, and retained Thrum signal.
- `godot/tests/companion_presence_semantics_test.gd` — body state/follow/clearance/recovery semantics.
- `godot/tests/companion_vehicle_docking_test.gd` — Bike/Hauler mount, dock, rejected dismount, successful dismount/release.
- `godot/tests/companion_thrum_replay_mission03_test.gd` — retained Thrum composition, Replay, P06 durability, Mission 03 regression.
- `godot/tests/companion_presence_windowed_probe.gd` — rendered/runtime proof driver.
- `.github/workflows/burnside-production-08.yml` — exact-source focused P08 verification + rendered artifact.

### Modify

- `godot/scenes/player/runner.tscn` — add `HS7CarrySocket` and one HS-7 scene instance; no Runner script/locomotion rewrite.
- `godot/scenes/vehicles/courier_bike.tscn` — add `FB13DockSocket` beside existing `VisualRoot/CargoRack`.
- `godot/scenes/vehicles/scrap_hauler.tscn` — add `FB13DockSocket` beside existing `VisualRoot/CargoBed`.
- `godot/scenes/prototype/scrap_test_block.tscn` — mount one FB-13 body and one P08 runtime as root siblings.
- `godot/scripts/prototype/scrap_test_block.gd` — configure the P08 runtime after the existing dynamic Bike/Hauler construction and call `reset_presence()` from full Replay only.

### Retain unchanged unless an exact regression proves otherwise

- `godot/scripts/player/runner.gd`
- `godot/scripts/vehicles/courier_bike.gd`
- `godot/scripts/vehicles/scrap_hauler.gd`
- `godot/scripts/world/fb13_thrum_world_event.gd`
- `godot/scripts/missions/city_that_forgot_mission.gd`
- `godot/scripts/missions/city_that_forgot_runtime.gd`
- `godot/scripts/camera/camera_3d.gd`
- all Audio resources/scripts/registries.

---

### Task 1: RED — Production-08 Contract Harness

**Files:**
- Create: `godot/tests/companion_presence_semantics_test.gd`
- Create: `godot/tests/companion_vehicle_docking_test.gd`
- Create: `godot/tests/companion_thrum_replay_mission03_test.gd`
- Create: `.github/workflows/burnside-production-08.yml`

**Interfaces required by RED:**

`FB13CompanionBody`:

```gdscript
class_name FB13CompanionBody

enum PresenceState {
    FOLLOWING,
    REJOINING,
    DOCKING_BIKE,
    DOCKED_BIKE,
    DOCKING_HAULER,
    DOCKED_HAULER,
}

func configure(runner: Node3D, camera: Camera3D) -> void
func tick_presence(delta: float) -> void
func begin_dock(socket: Node3D, docking_state: PresenceState, docked_state: PresenceState) -> void
func release_from_dock(world_origin: Vector3) -> void
func reset_to_follow_position() -> void
func on_thrum_triggered(event_payload: Dictionary) -> void
func get_presence_state() -> PresenceState
func get_follow_distance() -> float
func get_hard_rejoin_count() -> int
func get_last_hard_rejoin_snapshot() -> Dictionary
func get_thrum_reaction_count() -> int
```

`BurnsideCompanionPresenceRuntime`:

```gdscript
class_name BurnsideCompanionPresenceRuntime

func configure(
    runner: PlayerRunner,
    camera: Camera3D,
    fb13: FB13CompanionBody,
    courier_bike: CourierBike,
    scrap_hauler: ScrapHauler,
    thrum_event: Node
) -> void
func reset_presence() -> void
func get_fb13() -> FB13CompanionBody
func get_hs7_socket() -> Node3D
func get_active_dock_socket() -> Node3D
func get_runtime_snapshot() -> Dictionary
```

- [ ] **Step 1: Write failing companion presence semantics test**

Instantiate the real Runner scene, a real `Camera3D`, and the future FB-13 body. Disable automatic processing in the test and drive `tick_presence()` manually. Require initial `FOLLOWING`, finite local distance, no collision authority, and deterministic side/trailing offset movement.

Required assertions include:

```gdscript
fb13.process_mode = Node.PROCESS_MODE_DISABLED
fb13.configure(runner, camera)
assert(fb13.get_presence_state() == FB13CompanionBody.PresenceState.FOLLOWING)
assert(fb13.get_follow_distance() < 8.0)
assert(fb13.find_children("*", "CollisionShape3D", true, false).is_empty())
assert(fb13.find_children("*", "Area3D", true, false).is_empty())

runner.global_position += Vector3(4.0, 0.0, 0.0)
for i in range(30):
    fb13.tick_presence(1.0 / 60.0)
assert(fb13.global_position.distance_to(runner.global_position) < 8.0)
```

Create a bounded blocking `StaticBody3D` fixture between FB-13 and the preferred offset. Verify the body uses the one alternate side candidate or lags; it must not contain/load `NavigationAgent3D` and must never instantiate a navmesh/path service.

Drive separation to `17.9 m` for >0.75 s: no hard rejoin. Drive to `18.1 m` for 0.74 s: no hard rejoin. Make source visible: no hard rejoin. Make source off-screen but all four 16 m staging candidates visible/blocked: no hard rejoin. Make one deterministic candidate off-screen and clear: exactly one hard rejoin, snapshot says both source and staging were off-screen, state becomes `REJOINING`, then physical ticks return within 5 m and state becomes `FOLLOWING`.

- [ ] **Step 2: Write failing vehicle docking test**

Instantiate `res://scenes/prototype/scrap_test_block.tscn` and require:

- root `BurnsideCompanionPresenceRuntime`;
- root/mobile `FB13CompanionBody`;
- Runner `MeshPivot/Torso/HS7CarrySocket` with one HS-7 visual child;
- Bike `FB13DockSocket`;
- Hauler `FB13DockSocket`.

Mount Bike through retained `request_mount(player)`. `state_changed("MOUNTING")` must start FB-13 docking immediately; by the retained 0.25 s mount completion, FB-13 must already be `DOCKED_BIKE` at the Bike socket and HS-7 must still be under Runner carry socket. Trigger a speed-based rejected dismount and assert FB-13 remains `DOCKED_BIKE`. Then perform legal dismount; retained `state_changed("DISMOUNTING")` must release FB-13 from the Bike's physical socket without waiting for a visible teleport. After the retained 0.2 s dismount completes, FB-13 must be in physical `FOLLOWING`/`REJOINING` from the vehicle location.

Repeat for ScrapHauler. Also begin `REJOINING` before mount and verify `MOUNTING` overrides recovery cleanly into the correct dock state.

- [ ] **Step 3: Write failing Thrum / Replay / Mission-03 composition test**

Use the production scene. Capture `FB13ThrumWorldEvent.get_world_event_contract()`, `trigger_count`, `AudioManager.event_counts[AudioManager.SoundEvent.FB13_THRUM]`, and Mission 03 authored payload/order before P08 reaction.

Trigger the retained Thrum through its real proximity path; verify:

```gdscript
var before_audio_count: int = int(audio_mgr.event_counts.get(AudioManager.SoundEvent.FB13_THRUM, 0))
# Move Runner through the retained trigger-radius path and process until the retained event fires.
assert(thrum_event.trigger_count == before_trigger_count + 1)
assert(int(audio_mgr.event_counts.get(AudioManager.SoundEvent.FB13_THRUM, 0)) == before_audio_count + 1)
assert(fb13.get_thrum_reaction_count() == before_reaction_count + 1)
```

The retained event contract must be value-equivalent before/after, and P08 must not add a second Audio call.

Seed P06 mapped knowledge using the existing P06 test/store seam. Put FB-13 in a dock/rejoin state, then invoke full `reset_slice()`. Require FB-13 `FOLLOWING`, HS-7 back at carry socket, reaction transient cleared, and mapped knowledge still surveyed.

Run Mission 03 to the HS-7 Memory Echo checkpoint using retained mission/runtime seams. Require existing objective ordering and `[HS-7] ECHOTEL // archive fragment // civic deletion order recovered // integrity unstable` payload unchanged.

- [ ] **Step 4: Add exact-source P08 workflow and observe RED**

Use the same Godot 4.7.1 install/metadata-prime pattern as current production workflows. Run:

```bash
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/companion_presence_semantics_test.gd
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/companion_vehicle_docking_test.gd
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/companion_thrum_replay_mission03_test.gd
```

Expected RED must be missing P08 nodes/classes/interfaces, not syntax errors, fixture errors, broken metadata, or stale paths.

- [ ] **Step 5: Freeze RED evidence on issue #141**

Record exact branch SHA, workflow run URL, and expected missing-P08 failure summary before any production runtime/scene implementation file is changed.

---

### Task 2: GREEN — FB-13 Collisionless Body + Local Presence

**Files:**
- Create: `godot/scenes/entities/fb13_companion_body.tscn`
- Create: `godot/scripts/entities/fb13_companion_body.gd`
- Test: `godot/tests/companion_presence_semantics_test.gd`

**Interfaces:**
- Consumes: Runner global transform; active Camera3D; World3D direct space state.
- Produces: exact `FB13CompanionBody` API from Task 1.

- [ ] **Step 1: Build a distinct compact procedural FB-13 body**

Use a `Node3D` root with small industrial mesh children, restrained warm/amber retained-Gears accents plus one FB-13 emission element. Do not add `Area3D`, `PhysicsBody3D`, `CollisionShape3D`, interaction script, Audio player, light, health, or target marker.

The scene must be readable from the retained 3/4 camera and visually distinct from `UtilityCrawler`. Keep it original/procedural using repository-owned primitives/materials.

- [ ] **Step 2: Implement deterministic follow movement**

Use local initial tuning constants:

```gdscript
const FOLLOW_SIDE_M := 2.1
const FOLLOW_TRAIL_M := 1.8
const FOLLOW_HEIGHT_M := 1.15
const FOLLOW_SPEED_MPS := 10.5
const FOLLOW_ACCEL_MPS2 := 28.0
const REJOIN_ELIGIBLE_DISTANCE_M := 18.0
const REJOIN_DELAY_SEC := 0.75
const REJOIN_STAGING_RADIUS_M := 16.0
const REJOIN_COMPLETE_DISTANCE_M := 5.0
const REJOIN_SPEED_MPS := 15.0
```

Normal FB-13 speed intentionally exceeds Runner's retained `8.5 m/s` maximum so ordinary straight-line running does not manufacture separation recovery. Compute preferred offset from Runner facing/right basis. Alternate candidate mirrors only the side component. Smooth movement with bounded velocity integration; do not parent FB-13 to Runner while following.

These non-contract follow/acceleration/catch-up values may receive bounded rendered-proof tuning before freeze; the final frozen values must be deterministic and test-covered.

- [ ] **Step 3: Add bounded clearance**

Use `get_world_3d().direct_space_state` with one short ray from current FB-13 position to preferred candidate and one small sphere `intersect_shape` at the candidate. Exclude Runner RID and active supported vehicle RID when available; set `collide_with_areas = false`. If preferred fails, test exactly one mirrored side candidate. If both fail, hold/lag.

Do not scan the scene tree each frame and do not allocate/invoke navigation resources.

- [ ] **Step 4: Implement the exact off-camera recovery contract**

Use active camera horizontal forward/right basis and deterministic staging order:

```gdscript
[
    -camera_forward,
    -camera_forward + camera_right,
    -camera_forward - camera_right,
    camera_right,
]
```

Normalize each horizontal direction and multiply by `16.0 m` around Runner. Reject any candidate visible in current viewport or failing local clearance. Source FB-13 must also be outside viewport.

Visibility check uses `camera.is_position_behind(world_pos)` plus `camera.unproject_position(world_pos)` against viewport visible rect with an 8 px inward safety margin. A point behind camera is off-screen. Do not change camera to manufacture eligibility.

On success: snapshot source/staging/visibility, snap once to staging, increment hard-rejoin count, enter `REJOINING`, then move physically at bounded rejoin speed toward normal follow until within 5 m.

- [ ] **Step 5: Run semantics test to GREEN**

```bash
Godot --headless --rendering-method gl_compatibility --path godot --script res://tests/companion_presence_semantics_test.gd
```

Expected: local follow, mirrored obstruction behavior, exact 18 m / 0.75 s gates, four-candidate cap, invisible snap only, physical rejoin, no collision authority, no navigation nodes/services.

- [ ] **Step 6: Commit FB-13 body task**

Commit only body scene/script + semantics test changes after GREEN.

---

### Task 3: GREEN — HS-7 Carry + Explicit Vehicle Dock Sockets

**Files:**
- Create: `godot/scenes/entities/hs7_carried_module.tscn`
- Modify: `godot/scenes/player/runner.tscn`
- Modify: `godot/scenes/vehicles/courier_bike.tscn`
- Modify: `godot/scenes/vehicles/scrap_hauler.tscn`
- Test: `godot/tests/companion_vehicle_docking_test.gd`

**Interfaces:**
- Produces: `Runner/MeshPivot/Torso/HS7CarrySocket`, `CourierBike/FB13DockSocket`, `ScrapHauler/FB13DockSocket`.

- [ ] **Step 1: Create HS-7 carried visual**

Create a compact `Node3D` scene using a small core/module silhouette and sparse cyan/memory emission. No collision, script authority, Audio, light, HUD marker, interaction, or independent movement.

- [ ] **Step 2: Add Runner carry socket without changing locomotion**

Under `MeshPivot/Torso`, add `HS7CarrySocket` adjacent to existing Satchel so the module reads as carried equipment rather than replacing it. Instance `hs7_carried_module.tscn` under the socket.

Do not modify `runner.gd`; mounted posture already moves Torso composition with Runner.

- [ ] **Step 3: Add CourierBike FB13DockSocket**

Add root `Node3D` `FB13DockSocket` aligned over/behind existing `VisualRoot/CargoRack`, visually separated from RiderSocket and clear of BatteryCell volume.

- [ ] **Step 4: Add ScrapHauler FB13DockSocket**

Add root `Node3D` `FB13DockSocket` aligned over existing `VisualRoot/CargoBed`, behind cabin and clear of RiderSocket/BatteryCore presentation.

- [ ] **Step 5: Run structural docking test progression**

The test must now find HS-7 and both vehicle sockets but remain RED for missing orchestration. Verify Runner, Bike, and Hauler scripts are source-unchanged in this task.

- [ ] **Step 6: Commit attachment geometry**

Commit only HS-7 visual + three scene socket changes + structural test progression.

---

### Task 4: GREEN — Bounded Presence Runtime + Vehicle Transitions

**Files:**
- Create: `godot/scripts/world/burnside_companion_presence_runtime.gd`
- Modify: `godot/scenes/prototype/scrap_test_block.tscn`
- Modify: `godot/scripts/prototype/scrap_test_block.gd`
- Test: `godot/tests/companion_vehicle_docking_test.gd`

**Interfaces:**
- Consumes: `CourierBike.state_changed(new_state: String)` and equivalent Hauler signal; Runner; active camera; three named sockets.
- Produces: `BurnsideCompanionPresenceRuntime` API from Task 1.

- [ ] **Step 1: Mount one P08 runtime and one FB-13 body**

Add declarative root siblings in `scrap_test_block.tscn`:

```text
ScrapTestBlock
├── Runner
├── FB13CompanionBody
├── FB13ThrumWorldEvent
└── BurnsideCompanionPresenceRuntime
```

After existing dynamic Bike/Hauler creation in `ScrapTestBlock._ready()`, resolve the two new root siblings and call:

```gdscript
companion_presence_runtime.configure(
    player,
    camera,
    fb13_companion_body,
    courier_bike,
    scrap_hauler as ScrapHauler,
    get_node_or_null("FB13ThrumWorldEvent")
)
```

`BurnsideCompanionPresenceRuntime._process(delta)` calls `fb13.tick_presence(delta)` exactly once while configured. Body itself does not add a second autonomous `_process` tick.

- [ ] **Step 2: Start docking on retained MOUNTING transition**

Connect once to each vehicle's existing `state_changed` signal. On `MOUNTING`, start the correct dock immediately:

```gdscript
fb13.begin_dock(
    vehicle.get_node("FB13DockSocket"),
    FB13CompanionBody.PresenceState.DOCKING_BIKE,
    FB13CompanionBody.PresenceState.DOCKED_BIKE
)
```

Use Hauler states for Hauler. `begin_dock()` cancels separation/rejoin timers, calls `reparent(socket, true)` to preserve world transform, and interpolates local transform to identity over `0.20 s`. This completes before the retained vehicle emits `mounted` at 0.25 s. Do not alter vehicle mount timing.

- [ ] **Step 3: Preserve rejected dismount semantics and release on retained DISMOUNTING**

A rejected dismount never emits `state_changed("DISMOUNTING")`, so P08 must do nothing and remain docked.

On `DISMOUNTING`, capture the current socket global position, reparent FB-13 back to the P08 root with global transform preserved, then call `release_from_dock(captured_world_origin)`. The body physically resumes follow/rejoin from the vehicle location while the retained 0.2 s Runner dismount finishes. No direct snap to Runner.

- [ ] **Step 4: Run docking test to GREEN**

```bash
Godot --headless --rendering-method gl_compatibility --path godot --script res://tests/companion_vehicle_docking_test.gd
```

Expected: Bike and Hauler MOUNTING->dock, rejected dismount retention, successful physical DISMOUNTING release, HS-7 remains with Runner, REJOINING->MOUNTING transition clean.

- [ ] **Step 5: Commit bounded runtime task**

No generic companion types or vehicle script edits are permitted unless an exact retained API defect is proven and recorded on #141 first.

---

### Task 5: GREEN — Thrum Ownership + Replay + Mission-03 Retention

**Files:**
- Modify: `godot/scripts/world/burnside_companion_presence_runtime.gd`
- Modify: `godot/scripts/entities/fb13_companion_body.gd`
- Modify: `godot/scripts/prototype/scrap_test_block.gd`
- Test: `godot/tests/companion_thrum_replay_mission03_test.gd`
- Retain: `godot/scripts/world/fb13_thrum_world_event.gd` unchanged
- Retain: Mission 03 production scripts unchanged

- [ ] **Step 1: Subscribe to retained Thrum signal without changing event authority**

At runtime configuration use generic Node-safe connection:

```gdscript
if thrum_event != null and thrum_event.has_signal("thrum_triggered"):
    var callable := Callable(self, "_on_fb13_thrum_triggered")
    if not thrum_event.is_connected("thrum_triggered", callable):
        thrum_event.connect("thrum_triggered", callable)
```

Handler calls only `fb13.on_thrum_triggered(payload)`. Do not call AudioManager, modify payload, or invoke `_trigger_thrum()`.

- [ ] **Step 2: Add body-only reaction**

For at most `0.65 s`, apply small local tilt/brace and temporary duplicate-material emission increase to one FB-13 visual child. Use generation counter so overlapping/reset reactions restore deterministically. `get_thrum_reaction_count()` increments once per retained signal.

- [ ] **Step 3: Bind full Replay only**

Add exactly one `companion_presence_runtime.reset_presence()` call to existing `reset_slice()` after retained vehicle force-dismount/reset ordering. `reset_presence()` reparents FB-13 to root, clears dock/rejoin/timers/reaction, places it at initial follow offset, sets `FOLLOWING`, and ensures HS-7 remains under `HS7CarrySocket`.

Do not call this reset from `retry_chase()`, ordinary dismount, Wanted clear, Garage repair, Mission completion, or P06 map operations.

- [ ] **Step 4: Run Thrum/Replay/Mission03 test to GREEN**

```bash
Godot --headless --rendering-method gl_compatibility --path godot --script res://tests/companion_thrum_replay_mission03_test.gd
```

Expected: one retained Thrum produces exactly one retained FB13_THRUM Audio count increment and one body reaction; event contract unchanged; Replay resets only transient presence; P06 knowledge survives; Mission 03 HS-7 ordering/payload exact.

- [ ] **Step 5: Run all focused P08 tests on one exact SHA**

All three P08 tests must pass together before presentation tuning.

---

### Task 6: Real Runtime + Rendered Player-Experience Proof

**Files:**
- Create: `godot/tests/companion_presence_windowed_probe.gd`
- Modify: `.github/workflows/burnside-production-08.yml`
- Modify only bounded companion scene transforms/materials if rendered proof exposes readability defects.

- [ ] **Step 1: Prove ordinary on-foot runtime**

Windowed probe launches real production scene, moves Runner through representative Gears space, and captures at least one frame with FB-13 physically following at readable side/trailing spacing and HS-7 visibly attached to Runner.

- [ ] **Step 2: Prove both vehicle docks**

Use retained mount APIs, wait real mount transition, capture Bike dock frame and Hauler dock frame. FB-13 must read physically secured to intended rack/bed area; HS-7 remains visible on Runner.

- [ ] **Step 3: Prove dismount and recovery**

Capture successful dismount/release and off-camera hard-recovery scenario. Instrument snapshot must prove source/staging invisibility at snap; rendered sequence must show only physical visible return with no pop-in.

- [ ] **Step 4: Prove Thrum body ownership**

Trigger retained Thrum in real frontage and capture visible FB-13 reaction alongside retained infrastructure pulse. Do not change Audio to make visual proof easier.

- [ ] **Step 5: Check 960x540 and constrained/mobile framing**

Proof must show companions do not obscure Runner, mission HUD, interaction affordances, vehicle condition tag, or Garage affordance. Tuning is limited to FB-13/HS-7 visual scale, non-contract follow speeds/offsets, and socket transforms; camera changes are out of scope.

- [ ] **Step 6: Upload exact-head proof artifact**

P08 workflow stores screenshots plus machine-readable snapshot containing source SHA, state, distances, dock parent paths, rejoin visibility snapshot, Thrum reaction count, and proof viewport dimensions.

---

### Task 7: Retained Regression + Web + Freeze

**Files:**
- Modify only P08 workflow/path filters or bounded tests required to prove candidate.

- [ ] **Step 1: Run exact current retained focused suites**

Discover filenames from current repository immediately before execution and run real retained tests covering at least:

- P01 Wanted/Contact-Search;
- P02 Field Hacking/report suppression;
- P03 Mission 02/Wanted composition;
- P04 work-zone/order regression;
- P05 Scrapper input/service/pursuer/mission ordering;
- P06 progress store/survey/map/modal input;
- P07 vehicle condition/Garage/Mission02 composition/runtime collision;
- `city_that_forgot_mission_contract_test.gd` and current Mission 03 runtime contract;
- CourierBike + ScrapHauler handling/mount/dismount;
- camera mount/current camera contracts;
- desktop/touch authority and interaction cancel;
- Replay/reset;
- `audio_first_retention_contract_test.gd` and current Audio runtime contract tests as regression-only evidence.

Do not invent stale filenames; record exact commands actually run on #141/PR.

- [ ] **Step 2: Run P08 focused workflow on literal branch head**

Require all focused tests and windowed proof green on same exact head SHA.

- [ ] **Step 3: Run current Godot Web literal-head checks**

Run repository's current Web export/static-host/browser smoke against exact branch head. Verify source revision stamp. Do not infer browser success from headless Godot success.

- [ ] **Step 4: Review exact base->head diff**

Check for accidental Audio, camera, Wanted, mission, map, save, vehicle-controller, input, or generalized companion changes. Any unexplained cross-boundary mutation blocks freeze.

- [ ] **Step 5: Freeze candidate**

Record exact candidate SHA in #141. After freeze, only concrete review/verification blockers may mutate it; any repair creates new candidate SHA and repeats exact-head proof.

- [ ] **Step 6: Independent review**

Review exact verified main base -> frozen candidate against #141, approved design, this plan, current runtime, save integrity, Web behavior, player readability, performance, and accidental scope expansion. Do not claim independent approval if reviewer/quota unavailable; any owner waiver must be explicit and recorded separately.

---

### Task 8: Merge -> Exact-Main -> Public -> Continuity

**Files:**
- Update continuity only after gameplay merge and exact-main/public proof.

- [ ] **Step 1: Merge only reviewed frozen head**

Use expected-head protection. If PR head moved after review, stop and re-review new exact head.

- [ ] **Step 2: Verify exact merged main**

Run P08 focused tests + relevant retained regression + rendered proof against exact merge SHA, not pre-merge feature SHA.

- [ ] **Step 3: Verify public Web publication**

Publish through retained workflow. Verify public `playtest-web/PLAYTEST_BUILD.txt` equals exact gameplay merge SHA and browser smoke passes against publication.

- [ ] **Step 4: Update continuity truth**

Update `HANDOFF.md`, product-direction issue #55, and retained continuity index with exact frozen feature head, gameplay merge SHA, exact-main verification, public Web run/stamp, review result or explicit owner waiver truth, P08 player loop, explicit absence of generalized companion/save/Audio/nav framework, and fresh post-P08 product re-evaluation.

- [ ] **Step 5: Close #141 only after continuity merge**

Issue closes as completed only when gameplay is merged, exact-main verified, public verified, continuity merged, and no authorized P08 work remains.

---

## Self-Review Checklist

Before implementation begins, verify this plan against approved design:

- [ ] Both companions physically present at cold start.
- [ ] FB-13 normal follow speed exceeds Runner's retained 8.5 m/s so routine running does not force hard recovery.
- [ ] FB-13 local follow uses one preferred + one alternate local candidate only.
- [ ] No navigation framework.
- [ ] Exact 18 m / 0.75 s / 16 m / four-candidate / 5 m recovery contract covered.
- [ ] Teleport portion is off-screen source -> off-screen staging only.
- [ ] Bike and Hauler explicit docks covered.
- [ ] Docking starts on retained `MOUNTING`, not the later `mounted` completion signal.
- [ ] Rejected dismount retains dock state.
- [ ] Successful `DISMOUNTING` releases physically from vehicle location.
- [ ] HS-7 remains carried through mounted posture.
- [ ] Existing Thrum owns Audio/event; P08 owns visual body reaction only.
- [ ] `AudioManager.event_counts` proves exactly one retained FB13_THRUM call per retained event in focused composition test.
- [ ] Full Replay only; no companion persistence.
- [ ] P06 knowledge survives.
- [ ] Mission 03 HS-7 memory contract retained.
- [ ] Camera unchanged.
- [ ] Audio unchanged.
- [ ] P01-P07 regressions and Web/public proof included.
- [ ] Exact-head frozen review and exact-main/public verification included.
- [ ] No placeholders or speculative generalized architecture.
