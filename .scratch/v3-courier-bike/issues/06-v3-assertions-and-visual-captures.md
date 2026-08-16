# 06 — V3 Assertions & Visual Verification Captures

**What to build:**
Automated V3 assertions suite (`_run_v3_assertions()`) testing mount/dismount state transitions, speed-gated dismount rejection, touch routing, 6 visual captures under `godot/verification/v3/` (`v3_parked.png`, `v3_mounting.png`, `v3_driving_straight.png`, `v3_cornering.png`, `v3_braking.png`, `v3_dismounted.png`).

**Blocked by:** Tickets 01 through 05

**Status:** ready-for-agent

- [ ] `_run_v3_assertions()` suite (`godot --path godot/ -- ++ --run-v3-assertions`)
- [ ] Assert bike starts PARKED; out-of-range mount rejected
- [ ] Assert mount action transitions state to DRIVING & locks foot locomotion
- [ ] Assert dismount at speed > 1.5 m/s rejected
- [ ] Assert safe dismount restores foot locomotion & places player at collision-safe offset
- [ ] Export 6 required V3 verification screenshots under `godot/verification/v3/`
