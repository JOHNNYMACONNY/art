# 02 — Pursuit Loop State Machine

**What to build:**
`PursuitState` state machine (`CALM` -> `DISTURBANCE_ALERT` -> `PURSUIT_ACTIVE` -> `CONTACT_BROKEN` -> `EVADED`), core extraction trigger, distance-based evasion timer (3.0s at > 18.0m).

**Blocked by:** 01 — Pursuer Prototype Node & Target Pursuit

**Status:** ready-for-agent

- [ ] Pursuit loop state enum (`CALM`, `DISTURBANCE_ALERT`, `PURSUIT_ACTIVE`, `CONTACT_BROKEN`, `EVADED`)
- [ ] Core extraction event triggering disturbance alert & pursuer spawn
- [ ] Distance-gated contact break tracking (> 18.0m for 3.0s)
- [ ] Idempotent state transitions and evasion decay
