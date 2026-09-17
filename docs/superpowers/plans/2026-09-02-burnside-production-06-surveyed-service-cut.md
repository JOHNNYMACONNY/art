# Burnside Production 06 Surveyed Service Cut Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make the retained `ServiceAlley <-> NorthConnector` cut legitimately surveyable, persist exactly that mapped-knowledge fact, and expose it through one truthful Gears local route sheet across Replay and browser/application reload.

**Architecture:** Add one narrow `SurveyedRouteProgressStore`, one root-level `GearsSurveyedServiceCutRuntime`, and one bounded `GearsLocalRouteSheet`. Reuse authored P05 access state and retained Gears geometry; add only the smallest `TouchControlsUI` modal gate needed for Map ownership. Verification gets its own P06 CI workflow while the retained Godot Web workflow supplies literal-head/synthetic-merge export and the canonical compatibility matrix.

**Tech Stack:** Godot 4.7.1 / GDScript, `FileAccess` + JSON under `user://`, Godot Control `_draw`, GitHub Actions, exported Godot Web + Chromium/Playwright persistence probe.

**Spec:** `contracts/burnside_production_06_surveyed_service_cut_spec.md`

## Global Constraints

- Stable route ID: `gears.service_alley_north_connector`.
- Production mapped-knowledge path: `user://burnside_mapped_knowledge.json`.
- Schema version: `1`; only `surveyed_routes` belongs in P06 durable state.
- Unsupported/newer/malformed persisted data is never silently overwritten.
- Test storage must be isolated from owner progress.
- Survey requires physical `FORCED_OPEN` access plus continuous legitimate traversal; observation, forcing access alone, and teleport/discontinuous placement do not count.
- Replay resets P05 physical access but does not erase P06 mapped knowledge.
- Route sheet derives geometry from retained authored surfaces; it may not invent a route graph, GPS, pathfinding, racing line, breadcrumbs, player arrow, or turn-by-turn guidance.
- Map desktop key is `M`; Map is unavailable while driving or while retained interaction/gesture/input ownership is already locked.
- Map modal suppresses locomotion, generic Action, and Tool Action and restores exact prior ownership when closed.
- Do not touch AudioManager, audio registries/assets, PR #44 camera work, Wanted authority, Report semantics, Mission02 authority, pursuer authority, or worker/crawler knowledge except to run regressions.

---

### Task 1: RED — Production-06 Contract Harness

**Files:**
- Create: `godot/tests/gears_surveyed_route_progress_store_test.gd`
- Create: `godot/tests/gears_surveyed_service_cut_test.gd`
- Create: `godot/tests/gears_surveyed_service_cut_input_test.gd`
- Create: `.github/workflows/burnside-production-06.yml`

**Interfaces:**
- Consumes: retained production scene `res://scenes/prototype/scrap_test_block.tscn`, `GearsScrapperToolRuntime.get_access_state_name()`, `GearsScrapperToolRuntime._force_access_open()`, `TouchControlsUI` modes/signals.
- Produces test expectations for: `SurveyedRouteProgressStore`, root `GearsSurveyedServiceCutRuntime`, `GearsLocalRouteSheet`, `map_action_pressed`, `MapButton`, `set_map_modal_active(bool)`.

- [ ] **Step 1: Write the failing persistence test**

The test must load `res://scripts/progress/surveyed_route_progress_store.gd`, configure an explicit `user://tests/p06_progress_store_test.json`, and require this behavior:

```gdscript
var store = ProgressStoreScript.new()
store.configure(TEST_PATH)
assert(not store.is_surveyed(ROUTE_ID))
assert(store.mark_surveyed(ROUTE_ID))
assert(store.is_surveyed(ROUTE_ID))
assert(store.get_write_count() == 1)
assert(not store.mark_surveyed(ROUTE_ID))
assert(store.get_write_count() == 1)
var reloaded = ProgressStoreScript.new()
reloaded.configure(TEST_PATH)
assert(reloaded.is_surveyed(ROUTE_ID))
```

It must additionally write malformed JSON and `{ "version": 99, ... }`, preserve exact original bytes after attempted `mark_surveyed`, and prove `is_write_blocked()`.

- [ ] **Step 2: Write the failing service-cut semantics test**

Load the real production scene, wait for deferred Gears mounts, require `GearsSurveyedServiceCutRuntime`, and drive its deterministic sample seam:

```gdscript
survey.call("reset_transient_state")
assert(not survey.call("is_route_surveyed"))
survey.call("sample_player_position", entry_position)
assert(not survey.call("is_route_surveyed"))
scrapper.call("_force_access_open")
assert(not survey.call("is_route_surveyed"))
survey.call("sample_player_position", entry_position)
survey.call("sample_player_position", midpoint_a)
survey.call("sample_player_position", midpoint_b)
survey.call("sample_player_position", connector_position)
assert(survey.call("is_route_surveyed"))
assert(survey.call("get_survey_record_count") == 1)
```

A separate sequence must jump directly from entry to connector and remain unsurveyed. Replay must keep surveyed knowledge while P05 returns to `JAMMED`.

- [ ] **Step 3: Write the failing input/modal test**

Require `map_action_pressed`, `MapButton`, and `GearsLocalRouteSheet`. Connect Action/Tool/Map counters; verify touch Map and synthetic desktop `M` each toggle once, gesture lock and driving reject opening, modal blocks `trigger_action()` / `trigger_tool_action()`, and closing restores the pre-map player input-lock state and Tool availability.

- [ ] **Step 4: Add the P06 workflow and run RED**

Workflow commands:

```bash
"$GODOT_BIN" --headless --editor --rendering-method gl_compatibility --path godot --quit
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/gears_surveyed_route_progress_store_test.gd
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/gears_surveyed_service_cut_test.gd
"$GODOT_BIN" --headless --rendering-method gl_compatibility --path godot --script res://tests/gears_surveyed_service_cut_input_test.gd
```

Expected RED: missing P06 progress/runtime/input surfaces, not syntax/harness errors.

- [ ] **Step 5: Commit RED**

```bash
git add godot/tests/gears_surveyed_route_progress_store_test.gd godot/tests/gears_surveyed_service_cut_test.gd godot/tests/gears_surveyed_service_cut_input_test.gd .github/workflows/burnside-production-06.yml
git commit -m "test: define Production 06 surveyed-route RED"
```

---

### Task 2: GREEN — Narrow Durable Mapped-Knowledge Store

**Files:**
- Create: `godot/scripts/progress/surveyed_route_progress_store.gd`
- Test: `godot/tests/gears_surveyed_route_progress_store_test.gd`

**Interfaces:**
- Produces: `configure(path_override := "") -> void`, `is_surveyed(route_id: String) -> bool`, `mark_surveyed(route_id: String) -> bool`, `get_surveyed_routes() -> PackedStringArray`, `get_write_count() -> int`, `get_load_status() -> String`, `is_write_blocked() -> bool`, `get_storage_path() -> String`.

- [ ] **Step 1: Keep the persistence test RED and implement the minimum store**

Core constants and shape:

```gdscript
class_name SurveyedRouteProgressStore
extends RefCounted

const SCHEMA_VERSION := 1
const PRODUCTION_PATH := "user://burnside_mapped_knowledge.json"

var _surveyed_routes: Dictionary = {}
var _storage_path := ""
var _write_blocked := false
var _write_count := 0
var _load_status := "UNCONFIGURED"
```

`configure()` chooses the explicit override first; otherwise, if any command-line argument contains `res://tests/`, resolve an isolated `user://tests/p06_<test-script-basename>.json`; otherwise use `PRODUCTION_PATH`.

Load only JSON dictionaries whose integer `version == 1` and whose `surveyed_routes` is an array of strings. Missing file is `CLEAN`. Malformed/unsupported payload sets `_write_blocked = true` and leaves bytes untouched.

`mark_surveyed()` returns `false` when already known or write-blocked. For a new route, persist the canonical version-1 document first; roll back the in-memory insertion on write failure; increment `_write_count` only on successful file write.

- [ ] **Step 2: Run the persistence test to GREEN**

```bash
Godot --headless --rendering-method gl_compatibility --path godot --script res://tests/gears_surveyed_route_progress_store_test.gd
```

Expected: `PASS`, malformed/newer raw bytes unchanged, one write for first survey, zero duplicate writes.

- [ ] **Step 3: Commit**

```bash
git add godot/scripts/progress/surveyed_route_progress_store.gd godot/tests/gears_surveyed_route_progress_store_test.gd
git commit -m "feat: persist surveyed route knowledge"
```

---

### Task 3: GREEN — Legitimate Service-Cut Traversal Runtime

**Files:**
- Create: `godot/scripts/world/gears_surveyed_service_cut_runtime.gd`
- Modify: `godot/scripts/visual/gears_district_slice_01b.gd`
- Test: `godot/tests/gears_surveyed_service_cut_test.gd`

**Interfaces:**
- Consumes: `SurveyedRouteProgressStore`, P05 `GearsScrapperToolRuntime`, real `ServiceAlleyEntrySocket`, `ServiceAlley`, `NorthConnector` authored surfaces, `Runner`.
- Produces: `configure(root_controller, district, progress_store := null) -> bool`, `sample_player_position(position: Vector3) -> void`, `is_route_surveyed() -> bool`, `get_survey_record_count() -> int`, `get_route_id() -> String`, `reset_transient_state() -> void`, `get_progress_store()`.

- [ ] **Step 1: Implement only the traversal state machine needed by RED**

Use:

```gdscript
const ROUTE_ID := "gears.service_alley_north_connector"
const MAX_SAMPLE_JUMP_M := 3.0
const MIN_TRAVERSAL_DISTANCE_M := 12.0
const ENTRY_RADIUS_M := 2.5
const CONNECTOR_RADIUS_M := 3.2
```

Arm only when P05 access reports `FORCED_OPEN` and the player reaches one endpoint. Each subsequent horizontal sample must be within the authored ServiceAlley/NorthConnector corridor plus a small tolerance and must not jump farther than `MAX_SAMPLE_JUMP_M`. Accumulate travel. Reaching the opposite endpoint with sufficient distance calls `mark_surveyed(ROUTE_ID)` once. A discontinuity or leaving the route corridor resets transient qualification.

Production `_physics_process` samples `_player.global_position`; the public `sample_player_position` exists only as a deterministic seam over the same state machine.

- [ ] **Step 2: Mount one root runtime after P05**

In `gears_district_slice_01b.gd` preload the new script, add `call_deferred("_mount_production_06_surveyed_service_cut")`, instantiate root sibling `GearsSurveyedServiceCutRuntime`, and configure it with root + district. Do not move P04/P05 authority.

- [ ] **Step 3: Run service-cut semantics to GREEN**

```bash
Godot --headless --rendering-method gl_compatibility --path godot --script res://tests/gears_surveyed_service_cut_test.gd
```

Expected: view/force alone no survey, teleport no survey, continuous crossing one survey, duplicate crossing no duplicate write, Replay retains knowledge while P05 is jammed.

- [ ] **Step 4: Commit**

```bash
git add godot/scripts/world/gears_surveyed_service_cut_runtime.gd godot/scripts/visual/gears_district_slice_01b.gd godot/tests/gears_surveyed_service_cut_test.gd
git commit -m "feat: survey the Gears service cut"
```

---

### Task 4: GREEN — Bounded Gears Route Sheet and Map Ownership

**Files:**
- Create: `godot/scripts/ui/gears_local_route_sheet.gd`
- Modify: `godot/scripts/world/gears_surveyed_service_cut_runtime.gd`
- Modify: `godot/scripts/input/touch_controls.gd`
- Test: `godot/tests/gears_surveyed_service_cut_input_test.gd`

**Interfaces:**
- `GearsLocalRouteSheet.configure(district) -> bool`
- `GearsLocalRouteSheet.set_route_state(surveyed: bool, access_state: String) -> void`
- `GearsLocalRouteSheet.is_service_cut_visible() -> bool`
- `GearsLocalRouteSheet.get_access_status_text() -> String`
- `TouchControlsUI.map_action_pressed`
- `TouchControlsUI.set_map_modal_active(active: bool) -> void`
- `TouchControlsUI.is_map_modal_active() -> bool`
- Runtime: `toggle_map() -> bool`, `is_map_open() -> bool`, `get_route_sheet()`, `get_map_button()`.

- [ ] **Step 1: Implement the route sheet from authored geometry**

`GearsLocalRouteSheet` is a `Control` that reads BoxShape3D bounds from `NorthRoad`, `IndustrialIntersection`, `ServiceAlley`, and `NorthConnector`. `_draw()` always draws the first two context surfaces. It draws ServiceAlley/NorthConnector only when `surveyed == true`. Status text is exactly `UNKNOWN ROUTE`, `KNOWN · ACCESS JAMMED`, or `KNOWN · ACCESS OPEN`.

- [ ] **Step 2: Add minimal map modal gate to `TouchControlsUI`**

Add:

```gdscript
signal map_action_pressed
var _map_modal_active := false

func set_map_modal_active(active: bool) -> void:
    _map_modal_active = active
    _refresh_tool_action_button()

func is_map_modal_active() -> bool:
    return _map_modal_active
```

Make `_on_action_button_clicked()` emit only when `_map_modal_active == false`. Add `and not _map_modal_active` to `_tool_action_can_emit()`. In keyboard `_input`, suppress E/F gameplay emission while the map modal is active, and emit `map_action_pressed` once for a non-echo `KEY_M` press.

- [ ] **Step 3: Let the P06 runtime own Map UI**

At configure time, create `MapButton` under `SafeAreaRoot/RightTouchArea`, plus a full-screen mouse-filter-STOP modal containing `GearsLocalRouteSheet`, title/status labels, and a small close hint. Put MapButton above the modal z-order so the same touch control can close it.

`toggle_map()` opens only on foot when no gesture/input lock already owns the player. Opening stores the previous `Runner.is_input_locked`, sets it true, and calls `set_map_modal_active(true)`. Closing calls `set_map_modal_active(false)` and restores the exact saved lock value. Map remains unavailable while driving. Replay closes it and clears only transient survey state.

- [ ] **Step 4: Run input/modal test to GREEN**

```bash
Godot --headless --rendering-method gl_compatibility --path godot --script res://tests/gears_surveyed_service_cut_input_test.gd
```

Expected: one toggle per M/touch activation, gesture/driving rejection, Action/Tool suppression while open, exact restoration on close, safe-area containment.

- [ ] **Step 5: Run retained P05 input tests immediately**

```bash
Godot --headless --rendering-method gl_compatibility --path godot --script res://tests/gears_scrapper_tool_input_test.gd
Godot --headless --rendering-method gl_compatibility --path godot --script res://tests/gears_scrapper_tool_input_lock_test.gd
```

- [ ] **Step 6: Commit**

```bash
git add godot/scripts/ui/gears_local_route_sheet.gd godot/scripts/world/gears_surveyed_service_cut_runtime.gd godot/scripts/input/touch_controls.gd godot/tests/gears_surveyed_service_cut_input_test.gd
git commit -m "feat: add Gears surveyed-route sheet"
```

---

### Task 5: Runtime, Rendered, and Browser Persistence Proof

**Files:**
- Create: `godot/tests/gears_surveyed_service_cut_render_capture.gd`
- Create: `godot/tests/gears_surveyed_route_web_probe.gd`
- Create: `godot/tests/gears_surveyed_route_web_probe.tscn`
- Modify: `.github/workflows/burnside-production-06.yml`

**Interfaces:**
- Consumes actual P06 runtime/store/sheet and the real production scene.
- Produces six PNGs + `render_report.json` under `godot/verification/production06/`; browser titles `P06_WRITE_OK`, `P06_RELOAD_OK`, or `P06_FAIL`.

- [ ] **Step 1: Add six-state rendered capture**

Capture exactly:

```text
01_route_sheet_pre_survey.png
02_access_open_route_unsurveyed.png
03_route_surveyed_confirmation.png
04_route_sheet_surveyed_open.png
05_replay_known_route_jammed.png
06_known_route_reopened.png
```

Each state must assert its semantics before saving the image. The report records route surveyed state, P05 access state, sheet visibility/status, and source conditions.

- [ ] **Step 2: Add the actual-store Web probe**

`gears_surveyed_route_web_probe.gd` uses explicit isolated path `user://p06_web_reload_probe.json` and actual `SurveyedRouteProgressStore`. If route is absent, mark it and set window title/label `P06_WRITE_OK`. If already present on a fresh page load, set `P06_RELOAD_OK`. On any persistence error, set `P06_FAIL`.

- [ ] **Step 3: Extend P06 CI for render + browser reload proof**

In the focused job run the six-state render capture under Xvfb and upload `godot/verification/production06/`.

In a separate Web persistence job:

```bash
cp -a godot "$WEB_PROJECT"
# patch the isolated copy's project.godot run/main_scene to res://tests/gears_surveyed_route_web_probe.tscn
Godot --headless --editor --rendering-method gl_compatibility --path "$WEB_PROJECT" --quit
Godot --headless --rendering-method gl_compatibility --path "$WEB_PROJECT" --export-release "Web Playtest" "$GITHUB_WORKSPACE/build/p06-web/index.html"
python3 -m http.server 8096 --directory build/p06-web &
python3 -m playwright install chromium
```

Browser proof uses one Chromium context/profile and same `http://127.0.0.1:8096/` origin:

```python
page.goto(url)
page.wait_for_function("document.title === 'P06_WRITE_OK'")
page.reload()
page.wait_for_function("document.title === 'P06_RELOAD_OK'")
```

Fail if either state is not reached.

- [ ] **Step 4: Run retained focused regressions in P06 workflow**

Run P05 input/input-lock/environment/pursuer/Mission02 ordering; P04 work-zone + ordering; P03 suppression + Wanted composition; P02 Field-Hacking; P01 Heat-1.

- [ ] **Step 5: Commit proof harness**

```bash
git add godot/tests/gears_surveyed_service_cut_render_capture.gd godot/tests/gears_surveyed_route_web_probe.gd godot/tests/gears_surveyed_route_web_probe.tscn .github/workflows/burnside-production-06.yml
git commit -m "test: verify Production 06 runtime and Web persistence"
```

---

### Task 6: Exact-Head Review, Merge, Exact-Main/Public, Continuity

**Files:**
- Review all P06 changed files against `contracts/burnside_production_06_surveyed_service_cut_spec.md` and issue #134.
- Update only continuity files whose routing/status actually changes after merge.

**Interfaces:**
- Consumes: P06 workflow run, retained `godot-web-playtest.yml` PR runs, PR diff, issue #134.
- Produces: frozen reviewed P06 head, merged exact-main SHA, public `playtest-web/PLAYTEST_BUILD.txt` stamp, continuity closure.

- [ ] **Step 1: Require exact-head GREEN**

Require successful P06 focused/render/Web-persistence workflow plus retained Godot Web workflow literal-head export, synthetic-merge export, static-host smoke, desktop/touch regressions, camera contracts, and canonical compatibility matrix.

- [ ] **Step 2: Freeze and run Standards + spec review**

Inspect every changed path and PR diff. Reject any generalized save/navigation framework, unearned map disclosure, access-state lie, input leakage, authority mutation, or Audio/camera scope expansion. Repair on branch and re-run exact-head gates if any defect exists.

- [ ] **Step 3: Merge only the reviewed SHA**

Use the repository's retained merge method and GitHub expected-head protection. Record both final reviewed feature head and merge SHA.

- [ ] **Step 4: Require exact-main verification**

Require P06 main-push workflow and `Godot Web Playtest` main-push workflow to run against the exact merge SHA. Verify `playtest-web/PLAYTEST_BUILD.txt` equals that same gameplay/public SHA after publication.

- [ ] **Step 5: Update continuity and close issue**

Only after exact-main/public verification, update `HANDOFF.md`, product continuity/status surfaces that are actually stale, and issue #134 with exact SHAs/run evidence. Close #134 as completed. If continuity is docs-only, preserve the exact gameplay/public SHA separately from the newer docs-only main SHA.

- [ ] **Step 6: Final report**

Report exact verified repo/main/feature/public SHAs, player-facing behavior, test/workflow evidence, and only concrete remaining risks. Do not call broader navigation/persistence/Durable Progress complete.