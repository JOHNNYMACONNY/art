# 03 — Interactive Spatial Audio & Signal Pitch Blend

**What to build:**
State-driven 3D audio mix engine supporting `EXPLORE`, `TUNER_ATTRACT`, `TUNING`, `SIGNAL_LOCK`, `PANEL_POWERED`, `EXTRACTION`, `LOOP_COMPLETE`. Audio static ducks as tuning accuracy increases; clear frequency pulse + electrical transfer chime on lock.

**Blocked by:** 01 — Shared Interaction Contract & Tuner State Machine

**Status:** ready-for-agent

- [ ] Audio mix states (`EXPLORE` -> `TUNING` -> `SIGNAL_LOCK`)
- [ ] Static noise attenuation decreases as frequency matches target
- [ ] Electrical transfer pulse on Signal Lock
- [ ] `AudioStreamPlayer3D` spatial positioning for Tuner and Panel
- [ ] Clean audio stream loop without clicks or pop artifacts
