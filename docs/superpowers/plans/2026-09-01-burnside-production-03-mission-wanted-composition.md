# Burnside Production 03 Mission/Wanted Composition Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make Mission 02 — Civic Repossession use the existing civic Report/Field-Hacking/Wanted sandbox so jamming the local report link creates a clean Hauler theft while a live report creates normal Heat 1 + Contact/Search/Evasion.

**Architecture:** Keep `BurnsideWantedRuntime` as the single open-world authority adapter. Add only a narrow mission-facing report/state seam there; reuse `CivicServiceAlarm` for the theft report attempt; adapt Mission 02's small state machine/runtime to branch on real Wanted state instead of starting the legacy pursuit. Mission 01/03, audio, saves, Gears geography, and generalized police/hacking architecture remain untouched.

**Tech Stack:** Godot 4.7.1 Stable, GDScript, GitHub Actions/Xvfb verification.

**Spec:** GitHub Issue #124 — Burnside Production 03 — Civic Repossession / Wanted-Field-Hacking Mission Composition.

## Global Constraints

- Base exact remote `main`: `d96eb0cd8918a79f346829d59d2bebbf471ce639`; gameplay parent `7a5c36598c6d950d832f71c42e41eaacfb7b75b2` is already runtime-verified.
- Work only on `chatgpt/burnside-production-03-mission-wanted-composition` until reviewed/merged.
- No new framework, acreage, Heat 2–5, generalized witnesses/surveillance, vehicle-recognition system, save schema, or audio-system changes.
- Mission completion must never clear valid Wanted knowledge.
- Production code follows RED -> observed expected failure -> minimal GREEN.
- The connected chat environment has no local Git worktree; local dirty/upstream state is therefore UNKNOWN. Remote mutation is isolated to the exact-base feature branch and must not be represented as local-worktree proof.

---

### Task 1: RED — Mission 02 must compose the existing civic Report/Wanted seam

**Files:**
- Create: `godot/tests/civic_repossession_wanted_composition_test.gd`
- Create: `.github/workflows/burnside-production-03.yml`

**Interfaces:**
- Consumes current autoload `BurnsideWantedRuntime`, production scene `res://scenes/prototype/scrap_test_block.tscn`, `MissionCivicRepossessionRuntime`, `CivicServiceAlarm`, `CivicReportAccess`, and real `ScrapHauler`.
- Requires future runtime methods `request_civic_report(observed_position: Vector3) -> bool`, `get_heat_level() -> int`, and `get_wanted_state_name() -> String`.

- [ ] **Step 1: Write the failing production-scene tracer**

The test must instantiate the real production scene and fail until the new mission-facing Wanted seam exists. Minimum assertions:

```gdscript
if not _runtime.has_method("request_civic_report"):
    await _fail("Mission-facing civic report seam is absent")
    return
if not _runtime.has_method("get_heat_level") or not _runtime.has_method("get_wanted_state_name"):
    await _fail("Mission-facing Wanted read seam is absent")
    return
```

After the seam exists, the same tracer must exercise two fresh/replayed paths:

```text
LIVE REPORT: unlock Mission 02 -> mount real ScrapHauler -> Heat 1 + CONTACT -> Mission 02 remains ESCAPE -> force legitimate Contact loss/Search expiry through existing authority seam -> Mission 02 reaches DELIVERY.
JAMMED REPORT: replay -> unlock Mission 02 -> physically jam CivicReportAccess -> mount real ScrapHauler -> Heat 0/CLEAR -> Mission 02 reaches DELIVERY without legacy pursuit.
```

It must also assert that `current_pursuit_state` stays the retained legacy CALM value after Mission-02 Hauler mount on both paths, proving Mission 02 no longer calls `trigger_disturbance_alert()`.

- [ ] **Step 2: Add a branch/PR workflow that runs the RED tracer plus retained Production-01/02 contracts**

Use Godot 4.7.1 with the same pinned download/hash pattern as `.github/workflows/burnside-wanted-119.yml`. Run:

```bash
$GODOT_BIN --headless --rendering-method gl_compatibility --path godot --script res://tests/civic_repossession_wanted_composition_test.gd
$GODOT_BIN --headless --rendering-method gl_compatibility --path godot --script res://tests/field_hacking_report_suppression_test.gd
$GODOT_BIN --headless --rendering-method gl_compatibility --path godot --script res://tests/wanted_heat1_scene_test.gd
```

- [ ] **Step 3: Push the RED-only test/workflow commit and verify expected failure**

Expected focused failure:

```text
[CIVIC_REPOSSESSION_WANTED_COMPOSITION] Mission-facing civic report seam is absent
```

No gameplay file may change before this failure is observed on the exact RED head.

---

### Task 2: GREEN — Expose the smallest civic-report/Wanted adapter seam

**Files:**
- Modify: `godot/scripts/interactions/civic_service_alarm.gd`
- Modify: `godot/scripts/world/wanted_heat1_runtime.gd`
- Test: `godot/tests/civic_repossession_wanted_composition_test.gd`
- Retain: `godot/tests/field_hacking_report_suppression_test.gd`

**Interfaces:**
- `CivicServiceAlarm.trigger_report(observed_position: Vector3) -> bool` performs the same one-shot alarm state transition currently owned by `begin_interaction`, preserving `report_enabled` suppression.
- `BurnsideWantedRuntime.request_civic_report(observed_position: Vector3) -> bool` delegates to the bound alarm only.
- `BurnsideWantedRuntime.get_heat_level() -> int` and `get_wanted_state_name() -> String` are read-only adapters over `wanted_authority`.

- [ ] **Step 1: Add/extend RED assertions for direct alarm-trigger equivalence**

The tracer must prove a jammed alarm `trigger_report()` emits no Wanted and a restored/live alarm creates Heat 1 + Contact using the existing `_on_report_requested` path.

- [ ] **Step 2: Implement `CivicServiceAlarm.trigger_report()` minimally**

`begin_interaction()` should validate proximity then call the shared one-shot method. The shared method sets `is_triggered`, updates the label/state, emits `report_requested` only when `report_enabled`, emits `interaction_completed`, and returns `false` if already triggered.

- [ ] **Step 3: Implement the three narrow `BurnsideWantedRuntime` methods**

They must return safe `false`/`0`/`CLEAR` values when unbound rather than exposing private nodes or generalized event APIs.

- [ ] **Step 4: Run focused + retained Field-Hacking/Wanted tests**

Expected: adapter-specific assertions GREEN; Mission-02 composition assertions may remain RED until Task 3.

---

### Task 3: GREEN — Migrate only Mission 02 from forced legacy pursuit to real Wanted state

**Files:**
- Modify: `godot/scripts/missions/civic_repossession_mission.gd`
- Modify: `godot/scripts/missions/civic_repossession_runtime.gd`
- Modify: `godot/tests/civic_repossession_mission_contract_test.gd`
- Test: `godot/tests/civic_repossession_wanted_composition_test.gd`

**Interfaces:**
- Add `CivicRepossessionMission.on_clean_take() -> bool`, valid only from `ESCAPE`, which advances directly to `DELIVERY`, records no fabricated route choice, and gives clear report-suppression copy.
- `civic_repossession_runtime.gd` obtains `/root/BurnsideWantedRuntime`, calls `request_civic_report(_scrap_hauler.global_position)` exactly once on accepted Hauler mount, then branches on `get_heat_level()`/`get_wanted_state_name()`.

- [ ] **Step 1: Update the pure mission contract first and observe RED**

Add a second fixture:

```gdscript
var quiet = mission_script.new()
quiet.unlock_after_scrap_job()
quiet.on_vehicle_mounted("ScrapHauler")
if not quiet.on_clean_take():
    return "Report-suppressed Hauler theft did not advance to delivery"
if quiet.phase != mission_script.Phase.DELIVERY:
    return "Clean Hauler theft did not enter DELIVERY"
```

The existing loud/evasion fixture remains and must still reach DELIVERY through `on_evasion_complete()`.

- [ ] **Step 2: Implement `on_clean_take()` with no new phase enum**

Keep `LOCKED/GET_HAULER/ESCAPE/DELIVERY/FAILED/COMPLETE`; the quiet path is `GET_HAULER -> ESCAPE -> DELIVERY` synchronously after the report outcome is known.

- [ ] **Step 3: Replace Mission-02 legacy-pursuit coupling in the runtime**

Remove Mission 02's call to `trigger_disturbance_alert()` and its dependency on root `current_pursuit_state` for normal escape completion. On Hauler mount:

```text
mission.on_vehicle_mounted -> BurnsideWantedRuntime.request_civic_report(hauler position) ->
if Heat == 0 and state == CLEAR: mission.on_clean_take + show garage zone
else: remain ESCAPE and let BurnsideWantedRuntime own Contact/Search/Evasion
```

During `ESCAPE`, when the open-world runtime reports Heat 0/CLEAR after a loud report, call the existing `on_evasion_complete()` and show the garage zone. Do not reset or mutate Wanted from Mission 02.

- [ ] **Step 4: Preserve Signal Gate mission bookkeeping only**

Keep `_signal_gate.gate_triggered -> mission.on_gate_triggered()` while Mission 02 is ESCAPE. Do not add new pursuer routing behavior in this ticket.

- [ ] **Step 5: Run focused model + production-scene tests**

Expected: both live-report and jammed-report Mission-02 paths GREEN; legacy `current_pursuit_state` remains CALM on Mission-02 theft.

---

### Task 4: Exact-head verification, review, merge protection, exact-main proof

**Files:**
- Modify only if concrete verification/review findings require repair.
- Do not update `HANDOFF.md` or Issue #55 before the gameplay merge is verified on main.

**Interfaces:**
- Frozen feature head is the exact SHA after all repairs and before final review.

- [ ] **Step 1: Run focused Production-03 workflow on exact feature head**

Require GREEN for the new tracer plus retained Production-01/02 tests.

- [ ] **Step 2: Open the PR and run current PR compatibility workflows**

Verify Mission 01/03, mobile touch routing, desktop controls/aliases/vehicle authority, interaction cancel, replay, current camera contracts, current legacy compatibility matrix, Web export/browser smoke, and any path-triggered Wanted tests.

- [ ] **Step 3: Add windowed X11 proof if the focused workflow lacks sufficient player-facing evidence**

Capture/read both mission outcomes at retained production camera/HUD scale:

```text
REPORT SENT -> HEAT 1 // CONTACT/SEARCH -> eventual DELIVERY
REPORT LINK JAMMED / ALARM FAULT -> CLEAN TAKE -> DELIVERY
```

- [ ] **Step 4: Freeze the exact head and perform Standards + #124 spec review**

Reject scope leak into Mission 01/03, audio, generalized Wanted/hacking, saves, or acreage. Repair only concrete findings and rerun affected gates.

- [ ] **Step 5: Merge with exact-head protection and verify exact merged main**

Use `expected_head_sha` on merge. Verify the resulting main SHA, required main-push Web Playtest workflow, and public playtest source stamp if the existing publication workflow runs.

- [ ] **Step 6: Only after exact-main verification, update continuity**

Refresh Issue #55/HANDOFF only with verified facts, close #124 as completed, and record the exact frozen feature head + merged main SHA.
