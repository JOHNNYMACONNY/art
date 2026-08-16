# 01 — Shared Interaction Contract & Tuner State Machine

**What to build:**
Base interaction interface and state machine (`DORMANT` -> `TUNER_ATTRACT` -> `TUNING` -> `SIGNAL_LOCK` -> `PANEL_POWERED`). Enables proximity detection, interaction radius checks, and target selection magnetism without teleporting the player.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] Interactive object base class / signal contract for Tuner and Panel
- [ ] Proximity detection radius vs interaction radius separation
- [ ] State transitions GATED (no IDLE to TUNING jumps)
- [ ] Magnetism target selection highlighting
