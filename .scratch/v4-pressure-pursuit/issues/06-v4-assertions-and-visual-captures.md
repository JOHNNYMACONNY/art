# 06 — V4 Assertions & Visual Verification Captures

**What to build:**
Automated V4 assertions suite (`_run_v4_assertions()`) testing disturbance trigger, pursuer spawn, active pursuit steering, contact break distance decay, evasion return to calm, 6 visual captures under `godot/verification/v4/`.

**Blocked by:** Tickets 01 through 05

**Status:** ready-for-agent

- [ ] `_run_v4_assertions()` suite (`godot --path godot/ -- ++ --run-v4-assertions`)
- [ ] Assert pursuit state starts `CALM`
- [ ] Assert core extraction triggers `DISTURBANCE_ALERT` and spawns `PursuerPrototype`
- [ ] Assert pursuer pursues target position at 11 m/s
- [ ] Assert creating distance > 18.0m transitions state to `CONTACT_BROKEN`
- [ ] Assert decay timer returns state to `CALM` (evaded)
- [ ] Export 6 required V4 verification screenshots under `godot/verification/v4/`
