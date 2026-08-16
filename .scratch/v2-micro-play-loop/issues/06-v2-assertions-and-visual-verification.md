# 06 — V2 Assertions & Visual Verification Suite

**What to build:**
Automated V2 assertions test suite (`_run_v2_assertions()`) testing initial unpowered state, tuner attraction radius, touch routing, dwell lock, panel power activation, extraction complete, and exporting 8 visual screenshots under `godot/verification/v2/`.

**Blocked by:** 01 through 05

**Status:** ready-for-agent

- [ ] Automated V2 assertions suite (`godot --path godot/ -- ++ --run-v2-assertions`)
- [ ] Assert panel initially unpowered and non-interactable
- [ ] Assert tuner lock powers panel
- [ ] Assert full loop completion (`LOOP_COMPLETE`)
- [ ] Export 8 required V2 verification screenshots:
  - `godot/verification/v2/v2_explore.png`
  - `godot/verification/v2/v2_tuner_attract.png`
  - `godot/verification/v2/v2_tuning_far.png`
  - `godot/verification/v2/v2_tuning_near.png`
  - `godot/verification/v2/v2_signal_locked.png`
  - `godot/verification/v2/v2_panel_powered.png`
  - `godot/verification/v2/v2_panel_extraction.png`
  - `godot/verification/v2/v2_loop_complete.png`
