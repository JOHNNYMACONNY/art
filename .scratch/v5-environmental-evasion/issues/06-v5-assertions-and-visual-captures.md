# 06 — V5 Assertions & Visual Verification Captures

**What to build:**
Automated V5 assertions suite (`_run_v5_assertions()`) testing signal gate interaction, barrier slam, pursuer reroute, +25m separation, and exporting 6 screenshots under `godot/verification/v5/`.

**Blocked by:** Tickets 01 through 05

**Status:** ready-for-agent

- [ ] `_run_v5_assertions()` suite (`godot --path godot/ -- ++ --run-v5-assertions`)
- [ ] Assert signal gate starts ready
- [ ] Assert gate trigger slams barrier across main lane
- [ ] Assert barrier blocks pursuer direct vector pursuit
- [ ] Assert pursuer reroutes around barrier
- [ ] Assert player gains +25m separation and breaks contact
- [ ] Export 6 required V5 verification screenshots under `godot/verification/v5/`
