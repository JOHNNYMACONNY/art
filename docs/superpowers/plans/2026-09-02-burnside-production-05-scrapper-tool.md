# Burnside Production 05 — Gears Scrapper Tool Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ship one grounded Scrapper Tool that can force one jammed Gears service access, preserve local-reaction versus city-knowledge composition, and briefly disrupt the existing Heat-1 pursuer without introducing generalized combat.

**Architecture:** Add one root-level `GearsScrapperToolRuntime` sibling mounted from the retained Gears district composition seam. The runtime owns only tool possession, one pickup, one jammed access, swing timing/contact selection, held-tool presentation, and bounded calls into the existing P04 incident and pursuer. Wanted authority, player locomotion, missions, save state, generalized NPC state, and audio remain outside this runtime.

**Tech Stack:** Godot 4.7.1, GDScript, existing `SceneTree` executable test scripts, GitHub Actions on Ubuntu, `xvfb-run` for rendered proof, existing Web export/public playtest pipeline.

**Spec:** `contracts/burnside_production_05_scrapper_tool_spec.md` at approved spec commit `bf4b8ae12ff435628602c58e7cb0c8c1c9cf496f`.

## Global Constraints

- Exact selection baseline: `main@6cdccb008778f845256b28797c5a3f1a92a2de75`.
- Exact verified Production-04 gameplay/public baseline: `7605277d920b7877715d78687ccab16a69745b2f`.
- Work only on `feat/burnside-production-05-scrapper-tool`; PR #132 is the draft Production-05 PR.
- Preserve open PR #44 camera work; do not mix it into Production 05.
- Preserve Audio Production isolation; no shared Audio edit without a fresh concurrency check and a proven semantic gap.
- No production code before the relevant failing test has been observed.
- Pickup uses retained contextual `ACTION`; actual Scrapper use uses dedicated `F` / `TOOL` input and must never synthesize generic Action.
- No Player Health, Armor, NPC health/death, `Damageable`, generic damage, hostile pedestrian combat AI, inventory, weapon wheel, generalized destructibles, generalized witnesses/crime bus, Heat 2–5, vehicle condition/claiming, save-schema work, new acreage, or companion framework.
- `BurnsideWantedRuntime` / `WantedAuthority` remain sole owners of Heat, Contact, Search, Recognition, Report consequence, and Evasion.
- `GearsDistrictSlice01B.get_production_contract().owns_no_gameplay_authority` must remain true.
- `GearsWorkZoneIncident` remains the local-reaction owner and may request civic Report only through `BurnsideWantedRuntime.request_civic_report()`.
- One tool swing evaluates contact exactly once, against only the jammed access and active pursuer, with captured direction and bounded reach.
- One jammed access transitions only `JAMMED -> FORCED_OPEN` per run.
- Pursuer contact is a temporary physical motion modifier only; it cannot clear/deactivate authority or create a new combat state.
- Replay/reset must deterministically restore P05-local state without P05 clearing Wanted.

## File Map

**Create**

- `.github/workflows/burnside-production-05.yml` — exact-source P05 RED/GREEN/regression/render gate.
- `godot/scripts/world/gears_scrapper_tool_runtime.gd` — all P05-local state and explicit contact arbitration.
- `godot/scripts/interactions/scrapper_tool_pickup.gd` — one contextual world pickup, no inventory semantics.
- `godot/scenes/interactions/scrapper_tool_pickup.tscn` — pickup Area3D, simple readable mesh, bounded collision.
- `godot/tests/gears_scrapper_tool_input_test.gd` — dedicated input, pickup, Action separation, reset.
- `godot/tests/gears_scrapper_tool_environment_test.gd` — directional swing, jammed access, route change, P04/Report composition.
- `godot/tests/gears_scrapper_tool_pursuer_test.gd` — range/direction and temporary pursuer stagger without authority mutation.
- `godot/tests/gears_scrapper_tool_mission_ordering_test.gd` — P05 suppressed Report followed by Mission 02 remains non-stranding.
- `godot/tests/gears_scrapper_tool_render_capture.gd` — windowed proof for pickup, forced access, live/suppressed Report, pursuer impact/recovery.

**Modify narrowly**

- `godot/scripts/input/touch_controls.gd` — `tool_action_pressed`, `F`, Tool button routing/visibility/pointer ownership.
- `godot/scenes/prototype/scrap_test_block.tscn` — add `ToolActionButton` only.
- `godot/scripts/player/runner.gd` — pure `get_facing_direction() -> Vector3` query only.
- `godot/scripts/entities/pursuer_prototype.gd` — P05 stagger timer/velocity modifier and reset only.
- `godot/scripts/world/gears_work_zone_incident.gd` — explicit `trigger_service_access_disruption()` seam only.
- `godot/scripts/visual/gears_district_slice_01b.gd` — mount/configure the new root-level sibling; district still owns no gameplay authority.

Do not modify `godot/scripts/prototype/scrap_test_block.gd` unless execution proves a concrete composition blocker. If that occurs, stop and report the exact blocker before changing the central controller.

---

### Task 1: Establish isolated execution state and verified RED

**Files:**
- Create: `.github/workflows/burnside-production-05.yml`
- Create: `godot/tests/gears_scrapper_tool_input_test.gd`
- Create: `godot/tests/gears_scrapper_tool_environment_test.gd`
- Create: `godot/tests/gears_scrapper_tool_pursuer_test.gd`
- Create: `godot/tests/gears_scrapper_tool_mission_ordering_test.gd`

**Interfaces:**
- Consumes: approved spec only; no P05 production code.
- Produces: four independently failing real-scene tracers and an exact-source workflow that will later become the P05 GREEN gate.

- [ ] **Step 1: Verify repo/worktree/branch state before local mutation**

```bash
pwd
git rev-parse --show-toplevel
git remote -v
git fetch origin
git branch --show-current
git rev-parse HEAD
git rev-parse origin/main
git status --short
git worktree list
```

Required truth before continuing:

```text
origin/main = 6cdccb008778f845256b28797c5a3f1a92a2de75
feature branch = feat/burnside-production-05-scrapper-tool
feature branch contains bf4b8ae12ff435628602c58e7cb0c8c1c9cf496f
```

If the current checkout has unrelated dirty files, do not modify or clean them. Use an isolated worktree for the existing feature branch or stop with the exact branch/worktree conflict.

- [ ] **Step 2: Run retained baseline tests before adding RED**

Use the locally available Godot 4.7.1 binary and run the existing focused P01–P04 tracers:

```bash
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/gears_work_zone_incident_test.gd
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/gears_work_zone_mission_ordering_test.gd
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/civic_repossession_pretriggered_suppression_test.gd
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/civic_repossession_wanted_composition_test.gd
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/field_hacking_report_suppression_test.gd
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/wanted_heat1_scene_test.gd
```

Expected: all retained tests PASS before P05 changes.

- [ ] **Step 3: Write four real-scene failing tracers**

All four tests must load `res://scenes/prototype/scrap_test_block.tscn`, bind the real `BurnsideWantedRuntime`, and fail because P05 capability is absent rather than because of syntax or fixture errors.

`gears_scrapper_tool_input_test.gd` must first require:

```gdscript
var touch_ui := scene.get_node_or_null("CanvasLayer/TouchControlsUI")
if touch_ui == null or not touch_ui.has_signal("tool_action_pressed"):
    return fail("Production 05 dedicated Tool Action is absent")
var runtime := scene.get_node_or_null("GearsScrapperToolRuntime")
if runtime == null:
    return fail("Production 05 Scrapper runtime is absent")
```

The same test must later prove pickup uses existing Action, Tool input is separate, generic Action count does not increment on Tool press, tool use is unavailable while unheld/mounted/locked/cooldown, touch pointer ownership clears, and Replay restores possession/UI state.

`gears_scrapper_tool_environment_test.gd` must first require the root runtime and later prove captured-facing contact, `1.8 m` class reach, dot threshold `>= 0.5`, exactly one contact evaluation, miss safety, exactly one jammed access, `JAMMED -> FORCED_OPEN`, collision/traversal change, legitimate ServiceAlley -> NorthConnector rejoin, local actor alarm, live Report -> Heat 1 Contact, jammed Report -> local alarm + CLEAR, and pre-existing Wanted preservation.

`gears_scrapper_tool_pursuer_test.gd` must first require `PursuerPrototype.apply_scrapper_stagger()` and later prove only CHASING/DETOURING contact is accepted, displacement/interruption is brief, state/target/authority are preserved, stagger expires automatically, and repeated swings cannot create indefinite stun-lock.

`gears_scrapper_tool_mission_ordering_test.gd` must reuse the existing Production-04 Mission-02 fixture shape, replace the close-call event with P05 forced-access suppression, and prove the later Mission-02 hauler theft enters DELIVERY as CLEAN TAKE while authority remains CLEAR.

- [ ] **Step 4: Add exact-source Production-05 workflow**

Base it on `.github/workflows/burnside-production-04.yml`, keep Godot exactly `4.7.1-stable`, and trigger on both `main` and `feat/burnside-production-05-scrapper-tool` for every direct P05 dependency plus retained regression dependency. The workflow must run the four P05 tests first, then retained P04/P03/P02/P01 tests. Add rendered proof only after Task 7 creates the capture script.

Core exact-source guard:

```yaml
env:
  GODOT_RELEASE: "4.7.1-stable"
  GODOT_BIN: "${{ github.workspace }}/.godot-bin/Godot_v4.7.1-stable_linux.x86_64"
  SOURCE_SHA: ${{ github.event_name == 'pull_request' && github.event.pull_request.head.sha || github.sha }}

- name: Verify exact source
  run: |
    set -euo pipefail
    test "$(git rev-parse HEAD)" = "$SOURCE_SHA"
```

- [ ] **Step 5: Run every P05 tracer and observe correct RED before production code**

```bash
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/gears_scrapper_tool_input_test.gd
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/gears_scrapper_tool_environment_test.gd
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/gears_scrapper_tool_pursuer_test.gd
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/gears_scrapper_tool_mission_ordering_test.gd
```

Expected: each command exits non-zero for its intended missing P05 capability. A parser error, missing retained fixture, or unrelated regression is not valid RED; repair the test until the failure is capability-specific.

- [ ] **Step 6: Commit RED only**

```bash
git add .github/workflows/burnside-production-05.yml godot/tests/gears_scrapper_tool_*_test.gd
git commit -m "test: establish Production 05 RED contract"
```

Record the exact RED SHA in PR #132 and issue #131 before GREEN.

---

### Task 2: Add dedicated Tool input and contextual pickup

**Files:**
- Create: `godot/scripts/interactions/scrapper_tool_pickup.gd`
- Create: `godot/scenes/interactions/scrapper_tool_pickup.tscn`
- Create: `godot/scripts/world/gears_scrapper_tool_runtime.gd`
- Modify: `godot/scripts/input/touch_controls.gd`
- Modify: `godot/scenes/prototype/scrap_test_block.tscn`
- Modify: `godot/scripts/visual/gears_district_slice_01b.gd`
- Test: `godot/tests/gears_scrapper_tool_input_test.gd`

**Interfaces:**
- Consumes: retained `InteractableBase`, root `_active_target` / `_interactables`, `TouchControlsUI.action_button_pressed`, district sibling-mount pattern.
- Produces: `tool_action_pressed`, `set_tool_action_available(bool)`, `ScrapperToolPickup.acquire()/reset_pickup()`, root-level `GearsScrapperToolRuntime`, `has_tool()`, deterministic pickup reset.

- [ ] **Step 1: Keep input test RED while adding exact assertions**

The test must assert this contract before implementation:

```gdscript
assert_true(touch_ui.has_signal("tool_action_pressed"))
assert_true(touch_ui.get_node_or_null("ToolActionButton") != null)
assert_false(runtime.call("has_tool"))
assert_true(runtime.call("acquire_active_pickup"))
assert_true(runtime.call("has_tool"))
assert_false(runtime.call("handle_tool_action_pressed") == runtime.call("handle_action_pressed"))
```

Use signal counters to prove a Tool press increments only the Tool counter and not `action_button_pressed`.

- [ ] **Step 2: Implement the pickup as a bounded InteractableBase**

`godot/scripts/interactions/scrapper_tool_pickup.gd`:

```gdscript
class_name ScrapperToolPickup
extends InteractableBase

var _acquired := false

func acquire() -> bool:
    if _acquired:
        return false
    _acquired = true
    powered = false
    visible = false
    monitoring = false
    return true

func reset_pickup() -> void:
    _acquired = false
    powered = true
    visible = true
    monitoring = true

func is_acquired() -> bool:
    return _acquired
```

The scene uses one simple elongated industrial mesh and one bounded collision shape; no inventory metadata.

- [ ] **Step 3: Add dedicated Tool input**

In `TouchControlsUI` add:

```gdscript
signal tool_action_pressed
@onready var tool_action_button: Button = $SafeAreaRoot/RightTouchArea/ToolActionButton

func set_tool_action_available(available: bool) -> void:
    if tool_action_button != null:
        tool_action_button.visible = available
        tool_action_button.disabled = not available
```

Connect Tool button press only to `tool_action_pressed.emit()`. In desktop `_input`, accept physical/logical `KEY_F` only on foot and emit only `tool_action_pressed`. Leave `KEY_E` behavior unchanged.

- [ ] **Step 4: Mount a root-level P05 runtime without central-controller gameplay logic**

In `gears_district_slice_01b.gd`, follow the P04 deferred sibling pattern:

```gdscript
const GearsScrapperToolRuntimeScript = preload("res://scripts/world/gears_scrapper_tool_runtime.gd")

func _mount_production_05_scrapper_tool() -> void:
    var scene_root := get_parent()
    if scene_root == null or scene_root.get_node_or_null("GearsScrapperToolRuntime") != null:
        return
    var runtime := GearsScrapperToolRuntimeScript.new() as Node3D
    runtime.name = "GearsScrapperToolRuntime"
    scene_root.add_child(runtime)
    if not bool(runtime.call("configure", scene_root, self)):
        runtime.queue_free()
```

Call this from `_ready()` alongside the retained P04 deferred mount. Do not move gameplay state into the district.

- [ ] **Step 5: Implement acquisition routing in the P05 runtime**

The runtime must spawn one pickup near the existing ServiceAlley entry/work-zone seam, append that pickup to the retained root `_interactables`, connect to existing Action, and acquire only when the pickup is the root `_active_target`.

```gdscript
func _on_action_pressed() -> void:
    if _held or _pickup == null:
        return
    if _root_controller.get("_active_target") != _pickup:
        return
    if _pickup.acquire():
        _held = true
        _set_held_visual_visible(true)
        _touch_ui.call("set_tool_action_available", true)
```

Do not call the root's generic interaction handler from Tool input.

- [ ] **Step 6: Run focused input test GREEN, then retained desktop/touch contracts**

```bash
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/gears_scrapper_tool_input_test.gd
```

Then run the repository's retained mobile touch, desktop controls, alias ownership, vehicle authority, and interaction-cancel suites identified by the current compatibility matrix. Any input regression blocks the task.

- [ ] **Step 7: Commit**

```bash
git add godot/scripts/interactions/scrapper_tool_pickup.gd godot/scenes/interactions/scrapper_tool_pickup.tscn godot/scripts/world/gears_scrapper_tool_runtime.gd godot/scripts/input/touch_controls.gd godot/scenes/prototype/scrap_test_block.tscn godot/scripts/visual/gears_district_slice_01b.gd godot/tests/gears_scrapper_tool_input_test.gd
git commit -m "feat: add Scrapper Tool input and pickup"
```

---

### Task 3: Add captured-facing swing and one jammed ServiceAlley access

**Files:**
- Modify: `godot/scripts/player/runner.gd`
- Modify: `godot/scripts/world/gears_scrapper_tool_runtime.gd`
- Test: `godot/tests/gears_scrapper_tool_environment_test.gd`

**Interfaces:**
- Consumes: held-tool state, district `ServiceAlleyEntrySocket`, root active-vehicle state.
- Produces: `PlayerRunner.get_facing_direction()`, swing state/cooldown, one contact evaluation, one `JAMMED -> FORCED_OPEN` access.

- [ ] **Step 1: Add RED assertions for facing capture, range, direction, miss, and access state**

The environment test must place the player and targets deterministically and prove that a post-press player rotation does not change the captured contact direction.

- [ ] **Step 2: Add the pure PlayerRunner facing query**

```gdscript
func get_facing_direction() -> Vector3:
    if mesh_pivot == null:
        return Vector3(0.0, 0.0, -1.0)
    var facing := -mesh_pivot.global_transform.basis.z
    facing.y = 0.0
    return facing.normalized() if facing.length_squared() > 0.001 else Vector3(0.0, 0.0, -1.0)
```

Do not add attack/combat state to `PlayerRunner`.

- [ ] **Step 3: Implement one committed swing state machine in the P05 runtime**

Use exact initial tuning constants:

```gdscript
const SWING_IMPACT_SEC := 0.14
const SWING_TOTAL_SEC := 0.60
const TOOL_REACH_M := 1.8
const TOOL_FORWARD_DOT := 0.5
```

On accepted Tool input capture `player.global_position` and `player.get_facing_direction()` once. `_process(delta)` may call a focused `process_tool_state(delta)` function. Contact evaluation occurs once when elapsed time crosses `SWING_IMPACT_SEC`; recovery ends at `SWING_TOTAL_SEC`.

- [ ] **Step 4: Create exactly one authored jammed access in runtime-owned state**

At `GearsDistrictSlice01B/ServiceAlleyEntrySocket`, create one visible blocking body sized approximately across the `3.5 m` alley mouth. Store explicit state:

```gdscript
enum AccessState { JAMMED, FORCED_OPEN }
var _access_state := AccessState.JAMMED
```

A valid access contact changes state once, disables/removes blocking collision, changes the visible barrier transform/presentation, and never uses health/repeated damage.

- [ ] **Step 5: Implement closed contact arbitration**

Only these candidates exist:

```text
1. jammed service access
2. active pursuer
3. miss
```

For each candidate compute horizontal distance from captured origin and dot of normalized target direction against captured facing. Reject distance `> TOOL_REACH_M` or dot `< TOOL_FORWARD_DOT`. If both qualify, select the nearest. Increment an internal contact-evaluation counter exactly once per accepted swing so the tracer can assert no duplicate hit evaluation.

- [ ] **Step 6: Run environment test until swing/access behavior is GREEN except reporting seam assertions**

The test must now pass pickup-independent swing geometry and access traversal checks while still failing specifically on the not-yet-added P04 service-access disruption seam.

- [ ] **Step 7: Commit**

```bash
git add godot/scripts/player/runner.gd godot/scripts/world/gears_scrapper_tool_runtime.gd godot/tests/gears_scrapper_tool_environment_test.gd
git commit -m "feat: add bounded Scrapper swing and service access"
```

---

### Task 4: Compose forced access with P04 local reaction and existing Report authority

**Files:**
- Modify: `godot/scripts/world/gears_work_zone_incident.gd`
- Modify: `godot/scripts/world/gears_scrapper_tool_runtime.gd`
- Test: `godot/tests/gears_scrapper_tool_environment_test.gd`

**Interfaces:**
- Consumes: P04 `_escalate(observed_position)`, existing `BurnsideWantedRuntime.request_civic_report()`.
- Produces: `trigger_service_access_disruption(observed_position: Vector3) -> bool`.

- [ ] **Step 1: Add failing assertions for live, jammed, and pre-existing-Wanted outcomes**

The same physical access force must produce:

```text
CLEAR + live Report -> local ALARMED + Heat 1 CONTACT
CLEAR + jammed Report -> local ALARMED + CLEAR
pre-existing Wanted -> local ALARMED + same existing authority + zero redundant Report attempt
```

- [ ] **Step 2: Add one explicit P05-facing seam to `GearsWorkZoneIncident`**

```gdscript
func trigger_service_access_disruption(observed_position: Vector3) -> bool:
    if current_state != IncidentState.ROUTINE:
        return false
    _escalate(observed_position)
    return true
```

Do not duplicate actor alarm code or call WantedAuthority directly; retained `_escalate()` preserves alarm-first/report-second behavior.

- [ ] **Step 3: Call the incident seam exactly once when the access transitions to FORCED_OPEN**

The P05 runtime resolves the existing root `GearsWorkZoneIncident` and calls the new method only on the first valid force. Repeated swings against the already-open route do nothing to local/city authority.

- [ ] **Step 4: Run environment tracer and retained P04 tracer**

```bash
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/gears_scrapper_tool_environment_test.gd
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/gears_work_zone_incident_test.gd
```

Both must PASS.

- [ ] **Step 5: Commit**

```bash
git add godot/scripts/world/gears_work_zone_incident.gd godot/scripts/world/gears_scrapper_tool_runtime.gd godot/tests/gears_scrapper_tool_environment_test.gd
git commit -m "feat: compose Scrapper access with civic reporting"
```

---

### Task 5: Add bounded pursuer stagger without combat authority

**Files:**
- Modify: `godot/scripts/entities/pursuer_prototype.gd`
- Modify: `godot/scripts/world/gears_scrapper_tool_runtime.gd`
- Test: `godot/tests/gears_scrapper_tool_pursuer_test.gd`

**Interfaces:**
- Consumes: existing `PursuerState.CHASING`, `PursuerState.DETOURING`, existing chase motion loop.
- Produces: `apply_scrapper_stagger(impact_direction: Vector3) -> bool`, internal `0.30 s` modifier cleared by pursuer reset.

- [ ] **Step 1: Keep pursuer test RED on the missing method and authority invariants**

Record pre-contact pursuer state, active flag, target node, Heat, Wanted state, and recognition/contact/search state where exposed. Assert all authority values survive the physical stagger.

- [ ] **Step 2: Add minimal stagger fields and method**

Use initial values:

```gdscript
const SCRAPPER_STAGGER_SEC := 0.30
const SCRAPPER_SHOVE_SPEED_MPS := 3.3
var _scrapper_stagger_remaining := 0.0
var _scrapper_stagger_velocity := Vector3.ZERO

func apply_scrapper_stagger(impact_direction: Vector3) -> bool:
    if current_state != PursuerState.CHASING and current_state != PursuerState.DETOURING:
        return false
    var planar := impact_direction
    planar.y = 0.0
    if planar.length_squared() <= 0.001:
        return false
    _scrapper_stagger_remaining = SCRAPPER_STAGGER_SEC
    _scrapper_stagger_velocity = planar.normalized() * SCRAPPER_SHOVE_SPEED_MPS
    return true
```

In the pursuer physics loop, while stagger remains, apply only the temporary shove/interruption and decrement the timer; do not mutate pursuer state, active flag, target, detour ownership, or Wanted authority. When the timer expires, ordinary retained chase logic resumes automatically.

- [ ] **Step 3: Clear stagger in `reset_pursuer()`**

```gdscript
_scrapper_stagger_remaining = 0.0
_scrapper_stagger_velocity = Vector3.ZERO
```

- [ ] **Step 4: Wire the runtime's pursuer contact candidate to the new method**

Only invoke `apply_scrapper_stagger()` after the same captured-facing/range qualification used for all P05 contact. The `0.60 s` swing recovery must remain longer than the `0.30 s` stagger window.

- [ ] **Step 5: Run pursuer tracer and P01 Wanted tracer**

```bash
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/gears_scrapper_tool_pursuer_test.gd
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/wanted_heat1_scene_test.gd
```

Expected: PASS with chase recovery and unchanged authority.

- [ ] **Step 6: Commit**

```bash
git add godot/scripts/entities/pursuer_prototype.gd godot/scripts/world/gears_scrapper_tool_runtime.gd godot/tests/gears_scrapper_tool_pursuer_test.gd
git commit -m "feat: add bounded Scrapper pursuer stagger"
```

---

### Task 6: Close reset and Mission-02 ordering contracts

**Files:**
- Modify: `godot/scripts/world/gears_scrapper_tool_runtime.gd`
- Modify: `godot/scripts/entities/pursuer_prototype.gd`
- Test: `godot/tests/gears_scrapper_tool_input_test.gd`
- Test: `godot/tests/gears_scrapper_tool_mission_ordering_test.gd`

**Interfaces:**
- Consumes: existing Replay signal, P04 incident reset, Wanted runtime reset ownership, Mission-02 clean-take repair.
- Produces: deterministic P05 reset regardless of subscriber callback order.

- [ ] **Step 1: Assert dirty P05 state before Replay**

Create possession, forced-open access, active cooldown, and active pursuer stagger. Emit real `replay_pressed`. After frames settle, assert:

```text
held = false
pickup restored
Tool button hidden
swing idle
cooldown = 0
access = JAMMED with collision active
pursuer stagger cleared
no stale touch ownership
```

Do not assert that P05 itself cleared Wanted; Wanted reset remains its own subscriber/owner.

- [ ] **Step 2: Implement `GearsScrapperToolRuntime.reset_runtime()`**

Reset only P05-owned state and call `ScrapperToolPickup.reset_pickup()`. Restore barrier collision/presentation and held tool rest/hidden state. Never call WantedAuthority reset/clear.

- [ ] **Step 3: Run P05 Mission-02 ordering tracer**

The test sequence is:

```text
complete Mission 01 -> Mission 02 unlocked
jam CivicReportAccess through retained Action
acquire Scrapper
force jammed ServiceAlley access
verify local actors ALARMED + city CLEAR + alarm source consumed/faulted
mount Mission-02 hauler
verify Mission 02 -> DELIVERY as CLEAN TAKE
verify city remains CLEAR
```

- [ ] **Step 4: Run P03/P04 Mission ordering regressions**

```bash
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/gears_scrapper_tool_mission_ordering_test.gd
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/gears_work_zone_mission_ordering_test.gd
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/civic_repossession_pretriggered_suppression_test.gd
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/civic_repossession_wanted_composition_test.gd
```

All must PASS.

- [ ] **Step 5: Commit**

```bash
git add godot/scripts/world/gears_scrapper_tool_runtime.gd godot/scripts/entities/pursuer_prototype.gd godot/tests/gears_scrapper_tool_input_test.gd godot/tests/gears_scrapper_tool_mission_ordering_test.gd
git commit -m "fix: close Production 05 reset and mission ordering"
```

---

### Task 7: Add windowed proof, full CI coverage, and freeze exact-head candidate

**Files:**
- Create: `godot/tests/gears_scrapper_tool_render_capture.gd`
- Modify: `.github/workflows/burnside-production-05.yml`
- Modify tests only if proof reveals a real behavior defect; never weaken assertions to fit implementation.

**Interfaces:**
- Consumes: fully GREEN P05 behavior.
- Produces: rendered evidence plus exact-head CI/Web candidate suitable for Frozen Standards + #131 review.

- [ ] **Step 1: Create real-scene windowed render capture**

Capture at least these frames into `godot/verification/production05/`:

```text
01_scrapper_pickup_ready.png
02_scrapper_held.png
03_service_access_forced_report_sent.png
04_service_access_forced_report_suppressed.png
05_pursuer_scrapper_impact.png
06_pursuer_recovered.png
render_report.json
```

The capture script must verify relevant subjects are in the camera frustum and record source SHA, Godot version, display server, renderer, tool/access state, local incident state, Heat/Wanted state, pursuer state, and stagger state.

- [ ] **Step 2: Add capture/upload steps to the P05 workflow**

```yaml
- name: Capture windowed Production 05 proof
  run: |
    set -euo pipefail
    timeout 120s xvfb-run -a "$GODOT_BIN" --rendering-method gl_compatibility --path godot --script res://tests/gears_scrapper_tool_render_capture.gd
    test -s godot/verification/production05/01_scrapper_pickup_ready.png
    test -s godot/verification/production05/06_pursuer_recovered.png
    test -s godot/verification/production05/render_report.json

- name: Upload Production 05 proof
  uses: actions/upload-artifact@v4
  with:
    name: burnside-production05-proof-${{ env.SOURCE_SHA }}
    path: godot/verification/production05/
    if-no-files-found: error
    retention-days: 14
```

- [ ] **Step 3: Run complete focused P05 and retained P01–P04 matrix locally**

Run all four P05 tracers plus the six retained focused tests listed in Task 1. Then run the repository's canonical compatibility matrix, desktop controls, alias ownership, vehicle authority, interaction cancel, touch routing/safe-area, camera contracts, and Web export/hosting smoke exactly as current main documents them.

- [ ] **Step 4: Run windowed proof locally and inspect images**

Semantic test PASS is insufficient. Visually inspect that the tool silhouette is readable, the forced barrier change is obvious, local actors react, Report Sent/Suppressed reads correctly, pursuer contact creates brief physical space, and the pursuer visibly resumes chase.

If the slice is visually unreadable, repair presentation within current files first. Do not touch shared Audio unless a fresh concurrency check shows it is safe and a concrete semantic audio gap remains after visual repair.

- [ ] **Step 5: Verify exact branch head and PR diff boundaries**

```bash
git status --short
git rev-parse HEAD
git log --oneline --decorate -12
git diff --stat 6cdccb008778f845256b28797c5a3f1a92a2de75...HEAD
git diff --name-only 6cdccb008778f845256b28797c5a3f1a92a2de75...HEAD
```

Expected scope contains only the approved spec/plan, P05 workflow/tests/runtime/pickup scene, and the narrow retained files listed in this plan. Unexpected Wanted, mission, save, vehicle, generalized actor, or Audio files block freeze.

- [ ] **Step 6: Commit proof/workflow and push exact head**

```bash
git add .github/workflows/burnside-production-05.yml godot/tests/gears_scrapper_tool_render_capture.gd
git commit -m "ci: verify Production 05 rendered contact tracer"
git push origin feat/burnside-production-05-scrapper-tool
```

- [ ] **Step 7: Require exact-head CI and rendered artifact PASS**

Record the exact candidate SHA. Do not call it frozen until all P05 jobs, retained regressions, canonical compatibility matrix, literal-head Web export, synthetic-merge Web export, hosting smoke, and direct rendered-artifact inspection pass at that SHA.

- [ ] **Step 8: Freeze for Standards + #131 review**

Update PR #132 with the exact candidate SHA, RED SHA, verified tests, render artifact, scope boundary, and player-facing chains. Run Frozen Standards + #131 review. Any blocking finding enters `REPAIR -> reverify exact head -> review again`; no merge on stale evidence.

---

## Self-Review Result

- **Spec coverage:** All 20 required RED-contract items are assigned across Tasks 1–7. Input separation/pointer ownership is Task 2; directional one-contact swing and jammed access are Task 3; local/city reporting composition is Task 4; pursuer temporary physical counterplay is Task 5; reset/Mission ordering is Task 6; P01–P04 regressions, windowed proof, Web/public readiness, and exact-head freeze are Task 7.
- **Architecture boundary:** No task requires WantedAuthority, Mission implementation, save schema, vehicles, generalized combat/damage, generalized destructibles, generalized NPC combat, PR #44, or shared Audio edits.
- **Type/signature consistency:** `tool_action_pressed`, `set_tool_action_available(bool)`, `get_facing_direction() -> Vector3`, `trigger_service_access_disruption(observed_position: Vector3) -> bool`, and `apply_scrapper_stagger(impact_direction: Vector3) -> bool` are used consistently.
- **TDD:** Task 1 requires four independently observed capability-specific RED failures before any P05 production code. Each subsequent task keeps its focused test failing until the minimal production seam is added.
- **No placeholder work:** Every task has an explicit file boundary, intended interface, verification command, and commit boundary.

## Execution Boundary

The next authorized action is **RED execution in an isolated Codex worktree**. Do not start GREEN until the four P05 tests have each been observed failing for the intended missing-capability reason and the exact RED SHA is recorded.