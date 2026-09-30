# Burnside Production 15 — Checkpoint Courier Recognition Implementation Plan

**Issue:** #172  
**Branch:** `feat/production-15-checkpoint-courier-recognition`

## Goal

Add one bounded authored consequence: the existing Gears security checkpoint remembers a successful breach by the durably claimed production Courier Bike for the current session and recognizes that same bike on a later return.

## Task 1 — RED contract

Create `godot/tests/burnside_checkpoint_courier_recognition_test.gd`.

The test must instantiate the real production scene and prove:
- retained ordinary checkpoint behavior;
- unclaimed breach does not arm recognition;
- claimed breach arms recognition;
- normal rearm preserves recognition;
- same claimed Bike triggers WATCHLISTED;
- one and only one P01 civic Report request occurs;
- foot/different vehicle does not trigger recognition;
- P02 jam suppresses the Report but not local WATCHLISTED state;
- toll rejects WATCHLISTED;
- second breach remains possible;
- Full Replay clears recognition.

Use isolated P11 claim storage through the existing test-path resolver. Clean its test file before/after.

Create `.github/workflows/burnside-production-15.yml` with:
- exact-source checkout;
- P15 test;
- retained `security_checkpoint_world_event_test.gd`;
- retained P01/P02/P04/P07/P11/P14 focused regressions;
- GREEN gate.

Commit this RED state before production implementation.

## Task 2 — Checkpoint-local implementation

Modify `godot/scripts/world/security_checkpoint_world_event.gd`.

- append `WATCHLISTED` to the enum without renumbering retained states;
- bind existing `/root/BurnsideWantedRuntime`;
- add temporary claimed-Courier watchlist state;
- identify the active production Courier Bike through the root controller and retained P11 claim authority;
- on successful claimed-Courier breach, arm the local watchlist;
- preserve the watchlist across ordinary rearm;
- on matching return, enter WATCHLISTED and request at most one civic Report if Heat is zero;
- use existing Report authority only;
- add one runtime-created checkpoint-local `Label3D`;
- allow WATCHLISTED -> BREACHED for a qualifying ram;
- expose only narrow read-only helpers required by tests.

Do not change Audio sources/assets.

## Task 3 — Root integration

Modify `godot/scripts/prototype/scrap_test_block.gd` only where needed.

- allow physical checkpoint ram routing while state is WATCHLISTED;
- Full Replay calls the checkpoint hard reset that clears temporary recognition;
- preserve retained ordinary STANDOFF toll routing and existing interaction arbitration.

No generalized event bus or identity registry.

## Task 4 — GREEN / exact-head verification

Run through GitHub Actions on the exact branch head.

Required:
- P15 workflow PASS;
- Godot Web Playtest PASS;
- retained focused regression workflows triggered by shared-file path changes PASS where applicable.

If a failure is a real regression, repair narrowly. If it is pre-existing/unrelated, prove that separately rather than masking it.

## Task 5 — Frozen review

Freeze an exact SHA after all intended changes and exact-head CI are green.

Request fresh Codex review against that SHA.

Resolve legitimate findings. Re-run exact-head verification after any repair. Do not mechanically apply stale findings to changed code.

## Task 6 — Merge / exact-main / public

Merge only the reviewed frozen tree.

Verify:
- squash/merge tree equivalence to reviewed source;
- P15 exact-main workflow PASS;
- Godot Web Playtest exact-main PASS;
- public Pages deployment;
- live `PLAYTEST_BUILD.txt` equals the exact gameplay merge SHA.

Do not claim a manual public playthrough unless one actually occurs.

## Task 7 — Continuity / close / re-evaluate

Update `START_HERE.md` and `HANDOFF.md` with exact P15 evidence.

Close #172 only after continuity and public verification are complete.

Then perform a fresh post-P15 product re-evaluation rather than automatically extending recognition/checkpoint work.
