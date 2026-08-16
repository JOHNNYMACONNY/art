# 06 — Full-Run Verification & Cold-Player Test

**What to build:**
Automated full-run test suite `_run_v6_assertions()` using actual input/event routes, 6 visual captures under `godot/verification/v6/`, physical iPhone verification, and uninstructed cold-player run log.

**Blocked by:** 05 — Evasion Ending Beat & Deterministic Replay Reset

**Status:** ready-for-agent

- [ ] Automated assertion suite `_run_v6_assertions()` in `scrap_test_block.gd`
- [ ] Test execution command `godot --path godot/ -- ++ --run-v6-assertions`
- [ ] 6 visual captures under `godot/verification/v6/`
- [ ] Physical iPhone verification gate
- [ ] Uninstructed cold-player run log (record TIME_TO_FIRST_MOVE, TIME_TO_NOTICE_TUNER, etc.)
- [ ] 100% green verification across V1–V6 test suites
