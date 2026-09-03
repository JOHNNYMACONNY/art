# Burnside Production 07 Vehicle Condition Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make real collisions leave the production Courier Bike and Scrap Hauler in coarse readable condition states, make CRITICAL vehicles limp without becoming unusable, and let a stopped damaged vehicle repair at Mayor Burn's existing Garage only while authoritative Wanted state is CLEAR.

**Architecture:** Keep condition local to the two retained vehicle controllers rather than creating a damage/vehicle hierarchy. Add one bounded root-level `BurnGarageRepairRuntime` mounted through the retained Gears district composition seam. It creates one passive-distance `InteractableBase` at the existing MissionDestinationSocket, reads the existing active-vehicle and Wanted seams, and uses the retained Action signal. Full Replay explicitly resets vehicle condition; P06 mapped knowledge is untouched. Verification gets a dedicated P07 workflow while the retained Godot Web workflow provides literal-head/synthetic-merge browser export and canonical compatibility coverage.

**Tech Stack:** Godot 4.7.1 / GDScript, existing `CharacterBody3D` vehicle controllers, `InteractableBase`, `BurnsideWantedRuntime`, GitHub Actions, Godot Web export.

**Spec:** `contracts/burnside_production_07_vehicle_condition_spec.md`

## Global Constraints

- Exactly three player-readable states: `ROADWORTHY`, `BATTERED`, `CRITICAL`.
- No visible numeric HP, component tree, maintenance meter, destruction/explosion, or generalized `Damageable`.
- Condition derives only from real vehicle collision telemetry and never from Audio state.
- Accepted collision hits use a 0.50 s condition cooldown so sustained wall callbacks cannot melt condition frame-by-frame.
- Initial thresholds: BATTERED at `0.75` load, CRITICAL at `1.50`, load capped at `1.50`.
- CRITICAL changes only usable forward max speed, multiplier `0.52`; reverse, steering, acceleration, braking, grip, handbrake and mount/dismount stay retained.
- Burn Garage is the sole repair point at `GearsDistrictSlice01B/MissionDestinationSocket`, radius `2.6 m`.
- Repair requires damaged active production vehicle, within radius, `abs(current_speed) <= 0.35`, heat `0`, Wanted state `CLEAR`.
- Any missing Wanted authority fails repair closed.
- Repair never mutates Wanted, Reports, Recognition, Mission state, P06 mapped knowledge, or Audio.
- Full Replay resets both vehicle conditions; fast pursuit retry and ordinary dismount do not.
- Preserve Mission 02 automatic Garage delivery and P01–P06 authority.
- Do not touch PR #44 camera work or unrelated Audio code.

---

### Task 1: RED — Production-07 Contract Harness

**Files:**
- Create: `godot/tests/vehicle_condition_semantics_test.gd`
- Create: `godot/tests/burn_garage_repair_runtime_test.gd`
- Create: `godot/tests/burn_garage_mission02_composition_test.gd`
- Create: `.github/workflows/burnside-production-07.yml`

**Interfaces required by RED:**
- `CourierBike.VehicleCondition`, `ScrapHauler.VehicleCondition`
- `condition_changed(condition_name)`
- `get_condition_name()`
- `get_condition_load()`
- `get_usable_max_speed()`
- `apply_collision_condition(head_on_ratio, impact_speed)`
- `repair_condition()`
- `reset_condition()`
- root sibling `BurnGarageRepairRuntime`
- repair runtime getters/attempt seam described below.

- [ ] **Step 1: Write failing vehicle-condition semantics test**

Load real vehicle scenes and require both scripts to start ROADWORTHY. Exercise the same public collision-condition method the real physics collision path must call.

Required assertions:

```gdscript
assert(bike.get_condition_name() == "ROADWORTHY")
assert(not bike.apply_collision_condition(1.0, 3.5))
assert(is_zero_approx(bike.get_condition_load()))

assert(bike.apply_collision_condition(1.0, 10.0))
assert(bike.get_condition_name() == "BATTERED")
var after_first := bike.get_condition_load()
assert(not bike.apply_collision_condition(1.0, 10.0)) # cooldown blocks callback spam
assert(is_equal_approx(bike.get_condition_load(), after_first))

bike.set("_condition_contact_cooldown", 0.0) # deterministic elapsed-time seam
assert(bike.apply_collision_condition(1.0, 10.0))
assert(bike.get_condition_name() == "CRITICAL")
assert(is_equal_approx(bike.get_usable_max_speed(), bike.max_speed * 0.52))
```

Matched-speed glance must add less load than head-on. Hauler state must stay independent while Bike changes. Snapshot retained movement constants before condition changes and prove BATTERED/CRITICAL do not rewrite acceleration, braking, steering export, reverse limit or max_speed itself.

Set each vehicle to DRIVING for deterministic `set_drive_inputs()` checks: CRITICAL positive throttle reaches a non-zero cap no greater than `get_usable_max_speed()`; reverse still reaches a negative speed within retained `max_reverse_speed`.

Require presentation snapshot or child nodes proving BATTERED/CRITICAL damage presentation is active and ROADWORTHY presentation is clean.

- [ ] **Step 2: Write failing Burn Garage runtime test**

Instantiate `res://scenes/prototype/scrap_test_block.tscn`, wait for deferred P04–P07 mounts, and require root `BurnGarageRepairRuntime`.

Expected deterministic runtime seam:

```gdscript
runtime.get_repair_socket_position() -> Vector3
runtime.get_repair_interactable() -> InteractableBase
runtime.get_affordance_text() -> String
runtime.attempt_repair(vehicle) -> bool
runtime.is_vehicle_in_repair_radius(vehicle) -> bool
```

Damage Bike through its collision-condition method. Prove outside radius fails. Move Bike to the real socket, set it active, prove moving fails. Put Wanted into CONTACT and SEARCH using authoritative Wanted test seams and prove repair fails with condition unchanged. Restore CLEAR and stopped state, then repair once; second attempt returns false.

Capture heat/state before and after a rejected/successful repair and prove zero Wanted mutation.

Repeat active-target resolution with a damaged Hauler to falsify the current Bike-specific target-position bug.

- [ ] **Step 3: Write failing Mission-02 composition test**

Use the real production scene and `CivicRepossessionRuntime`. Put Mission 02 in legal DELIVERY state through its retained mission seam or deterministic setup, set Hauler CRITICAL, move Hauler inside the real return-zone socket, and process one frame.

Require:

- Mission reaches COMPLETE despite CRITICAL Hauler;
- Hauler condition remains CRITICAL until explicit repair;
- P07 repair can then restore ROADWORTHY without changing Mission COMPLETE;
- repeated process/action does not duplicate Mission completion or corrupt condition;
- full Replay returns both vehicles ROADWORTHY;
- P06 mapped knowledge remains independently surveyed when pre-seeded through the retained P06 test store/runtime seam.

- [ ] **Step 4: Add P07 workflow and observe RED**

Workflow triggers on P07 spec/plan/workflow plus relevant Godot scripts/tests/scenes. It checks out exact source SHA, installs Godot 4.7.1, primes metadata, then runs:

```bash
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/vehicle_condition_semantics_test.gd
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/burn_garage_repair_runtime_test.gd
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/burn_garage_mission02_composition_test.gd
```

Expected RED is missing P07 condition/runtime surfaces, not syntax errors, missing fixtures, or workflow plumbing errors.

- [ ] **Step 5: Freeze RED evidence**

Record exact RED branch SHA and Actions run URL in issue #137 before any production implementation file is changed.

---

### Task 2: GREEN — Courier Bike Coarse Condition

**Files:**
- Modify: `godot/scripts/vehicles/courier_bike.gd`
- Test: `godot/tests/vehicle_condition_semantics_test.gd`

- [ ] **Step 1: Add local condition enum/state/constants**

Add exactly the enum and public semantic methods from the spec. Keep `_condition_load`, `_condition_contact_cooldown` and presentation nodes local to CourierBike.

- [ ] **Step 2: Route real collision telemetry through condition**

In the existing `get_slide_collision_count()` loop, call:

```gdscript
apply_collision_condition(head_on_ratio, pre_impact_speed)
collision_contact.emit(head_on_ratio, pre_impact_speed, col.get_position())
```

Do not change the neutral signal or existing Audio consumer.

Decrement the condition cooldown in `_physics_process(delta)`.

- [ ] **Step 3: Implement the single CRITICAL pressure**

Add `get_usable_max_speed()`. Use it only for forward speed target/cap and overall forward movement cap. Keep steering speed-ratio denominator on original `max_speed`; leave reverse and all other handling constants unchanged.

- [ ] **Step 4: Add restrained damaged presentation**

Create/update a small condition smoke emitter and billboard damage tag. Derive them only from condition enum. Add a test snapshot getter if needed; it is observation-only.

- [ ] **Step 5: Run vehicle semantics**

The combined test may still be RED for the Hauler, but every Bike-specific assertion must now pass. Do not proceed if Bike condition changes unrelated handling.

---

### Task 3: GREEN — Scrap Hauler Coarse Condition

**Files:**
- Modify: `godot/scripts/vehicles/scrap_hauler.gd`
- Test: `godot/tests/vehicle_condition_semantics_test.gd`

- [ ] **Step 1: Mirror the same bounded condition contract locally**

Use the same thresholds, collision load formula, cooldown and `0.52` CRITICAL forward-speed multiplier. Do not create a shared damage base solely to deduplicate this tracer.

- [ ] **Step 2: Route real Hauler collision telemetry through condition**

Call `apply_collision_condition()` from the existing real collision loop before the existing neutral signal emit. Existing collision response stays unchanged.

- [ ] **Step 3: Apply only the Hauler forward speed cap**

Use `get_usable_max_speed()` for forward target/cap only. Reverse, acceleration, braking, steering, grip and handbrake remain retained.

- [ ] **Step 4: Add same restrained presentation language**

Small smoke + damaged-state billboard, scaled appropriately but semantically identical.

- [ ] **Step 5: Run vehicle semantics to full GREEN**

```bash
Godot --headless --rendering-method gl_compatibility --path godot --script res://tests/vehicle_condition_semantics_test.gd
```

Expected: PASS for harmless impacts, severity differentiation, debounce, state progression, independent vehicles, limp cap, steering/reverse retention, repair/reset, and presentation state.

---

### Task 4: GREEN — Burn Garage Repair Runtime

**Files:**
- Create: `godot/scripts/world/burn_garage_repair_runtime.gd`
- Modify: `godot/scripts/visual/gears_district_slice_01b.gd`
- Modify: `godot/scripts/prototype/scrap_test_block.gd`
- Test: `godot/tests/burn_garage_repair_runtime_test.gd`

- [ ] **Step 1: Implement bounded root runtime**

`BurnGarageRepairRuntime` extends `Node3D` and configures with root controller + district + Wanted runtime. It resolves the existing `MissionDestinationSocket`, creates one `InteractableBase`, interaction radius `2.6`, and a small `Label3D` affordance. Append the interactable to the root `_interactables` list exactly once.

- [ ] **Step 2: Use retained Action ownership**

Connect once to `TouchControlsUI.action_button_pressed`. In handler, return immediately unless root `_active_target` is exactly the P07 repair interactable. Never synthesize Action.

- [ ] **Step 3: Implement fail-closed eligibility**

`attempt_repair(vehicle)` requires supported active vehicle, damaged state, in radius, speed <= `0.35`, valid Wanted runtime, heat 0/state CLEAR. It then calls only `vehicle.repair_condition()`.

Feedback label states: `REPAIR // ACTION`, `STOP TO REPAIR`, `WANTED // SERVICE LOCKED`; short `ROADWORTHY` success confirmation.

- [ ] **Step 4: Mount through district composition**

Preload P07 runtime in `gears_district_slice_01b.gd`, add deferred `_mount_production_07_burn_garage_repair()`, create root sibling `BurnGarageRepairRuntime`, and configure it. Preserve the district node's declarative/no-authority contract.

- [ ] **Step 5: Correct two Bike-specific active-position calculations**

In `ScrapTestBlock._evaluate_target_selection()` and `_on_action_pressed()`, replace CourierBike-specific active position with `_get_active_vehicle()` generic position. No other interaction refactor.

- [ ] **Step 6: Run Garage runtime test to GREEN**

```bash
Godot --headless --rendering-method gl_compatibility --path godot --script res://tests/burn_garage_repair_runtime_test.gd
```

Expected: outside/moving/CONTACT/SEARCH fail; CLEAR+stopped+inside succeeds exactly once; Wanted unchanged; Hauler can acquire/use repair target.

---

### Task 5: GREEN — Replay + Mission 02 Composition

**Files:**
- Modify: `godot/scripts/prototype/scrap_test_block.gd`
- Test: `godot/tests/burn_garage_mission02_composition_test.gd`
- Retain: `godot/scripts/missions/civic_repossession_runtime.gd` unchanged unless a concrete P07 regression requires the smallest compatibility repair.

- [ ] **Step 1: Reset condition only on full Replay**

Inside `reset_slice()`, call `reset_condition()` for both vehicles while retaining existing position/gear/mount reset. Do not add condition reset to `force_dismount()` or `retry_chase()`.

- [ ] **Step 2: Keep Mission delivery authority untouched**

Prefer zero Mission 02 production-code changes. Its current `_process()` delivery radius and state machine should accept the Hauler regardless of condition.

- [ ] **Step 3: Run Mission composition test to GREEN**

Expected: CRITICAL Hauler completes DELIVERY; condition remains independent; explicit repair restores only vehicle; full Replay resets condition; P06 surveyed knowledge remains known.

- [ ] **Step 4: Run all three P07 focused tests together**

All must pass on the same exact branch SHA.

---

### Task 6: Real Runtime Collision -> Condition -> Limp -> Repair Proof

**Files:**
- Create: `godot/tests/vehicle_condition_runtime_collision_test.gd` if focused semantics do not already drive the actual `_physics_process` collision path strongly enough.
- Create/Modify: P07 workflow as needed.

- [ ] **Step 1: Prove condition does not exist only behind direct method calls**

Use a bounded physical collision fixture or the production scene to drive a mounted/DRIVING vehicle into real collision geometry through `_physics_process`/`move_and_slide()`. Observe emitted collision telemetry and resulting condition state from the same impact.

- [ ] **Step 2: Prove CRITICAL movement remains controllable**

In physics runtime, apply positive throttle + steering over multiple frames and show position/yaw changes while speed stays bounded at limp cap. Apply reverse and show negative movement remains possible.

- [ ] **Step 3: Prove Garage repair from actual runtime state**

Place/drive the damaged vehicle into the real authored Garage radius, set stopped/CLEAR, route one retained Action activation, and observe ROADWORTHY.

- [ ] **Step 4: Add this test to P07 workflow**

Do not accept property-only unit coverage as the P07 runtime gate.

---

### Task 7: Retained Regression + Rendered Proof

**Files:**
- Modify only verification/export files necessary for P07 evidence.
- Do not change unrelated gameplay to make evidence easier.

- [ ] **Step 1: Run retained focused suites**

At minimum include current tests covering:

- P01 Wanted/Contact-Search;
- P02 Field Hacking;
- P03 Mission 02;
- P04 work-zone + ordering;
- P05 Scrapper input, service access, pursuer stagger, Mission ordering;
- P06 progress store, survey semantics, Map/modal input;
- Courier Bike / Hauler handling;
- mount/dismount;
- desktop/touch vehicle authority;
- interaction cancel;
- camera contracts;
- Replay/reset.

Use exact current test filenames discovered from repo; do not invent stale commands.

- [ ] **Step 2: Capture exact-head rendered states**

Produce representative image evidence for:

1. ROADWORTHY Bike;
2. real impact -> BATTERED;
3. repeated severe impact -> CRITICAL;
4. CRITICAL Bike limping/steerable;
5. damaged Hauler ordinary or pursuit driving;
6. Garage Wanted rejection;
7. CLEAR stopped repair;
8. repaired departure;
9. Replay ROADWORTHY + retained P06 map knowledge.

Prefer one composition showing `CRITICAL -> surveyed service cut -> Burn Garage` if practical.

- [ ] **Step 3: Visual review**

Reject if damage presentation obscures vehicle silhouette/route, if smoke is noisy on phone-sized viewport, or if CRITICAL feels like arbitrary immobilization rather than pressure.

---

### Task 8: Feature-Head Web + PR + Frozen Review

**Files:**
- `.github/workflows/burnside-production-07.yml`
- retained `.github/workflows/godot-web-playtest.yml` only if direct P07 dependencies need path-filter coverage.

- [ ] **Step 1: Push/freeze exact feature head**

Record exact SHA after all implementation/evidence commits.

- [ ] **Step 2: Open P07 PR against current main**

PR body links #137, spec, plan, RED evidence, focused/runtime evidence, retained regressions, rendered proof, and explicit exclusions.

- [ ] **Step 3: Require literal-head + synthetic-merge Web**

The existing Godot Web Playtest workflow must pass:

- head Web export/static-host smoke;
- merge Web export/static-host smoke;
- exact-head canonical compatibility matrix.

Ensure P07 file paths actually trigger that workflow. A compile alone is insufficient.

- [ ] **Step 4: Independent frozen-head review**

Review exact `main -> frozen head` against issue #137 + spec. Focus on reachable correctness, player-facing limp/repair behavior, Wanted authority, Mission 02 composition, P06 persistence independence, interaction ownership, and accidental framework expansion.

Any blocker requires repair on a new head followed by full affected re-verification and re-review.

---

### Task 9: Merge + Exact-Main/Public Verification

- [ ] **Step 1: Merge only after all required gates are green**

No merge while focused/runtime/render/Web/review blockers remain.

- [ ] **Step 2: Verify exact gameplay merge SHA on main**

Run fresh P07 focused/runtime workflow and retained required regressions against exact merge SHA.

- [ ] **Step 3: Verify main Web/public publication**

Require Godot Web Playtest main-push success and verify `playtest-web/PLAYTEST_BUILD.txt` equals the exact gameplay merge SHA.

- [ ] **Step 4: Update continuity separately**

Update `HANDOFF.md` / product-direction continuity only with verified facts and exact SHAs. Use a docs-only continuity PR/merge if that is still the live repository workflow.

- [ ] **Step 5: Close #137 only after continuity/public proof**

Then perform a fresh post-P07 product re-evaluation. Do not assume Production 08 is vehicle claiming.