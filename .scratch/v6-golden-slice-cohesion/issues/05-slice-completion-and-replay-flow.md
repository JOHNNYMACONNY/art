# 05 — Evasion Ending Beat & Deterministic Replay Reset

**What to build:**
Non-arcade evasion ending sequence (siren stops, red threat light fades, environment settles, camera holds 1-2s, minimal `[ REPLAY SLICE ]` button) and **Deterministic Replay Reset** resetting player position, camera, bike, occupant, tuner, panel, conduit, gate, barrier, pursuer, WorldLoopState, PursuitState, audio, HUD, and touch input pointers to initial state.

**Blocked by:** 01 — Cold Player Spawn & Pacing Composition

**Status:** ready-for-agent

- [ ] Non-arcade evasion ending sequence (siren stops, threat light fades, quiet aftermath)
- [ ] No generic `[ GOLDEN SLICE COMPLETE ]` text or stats score/time grade
- [ ] Deterministic Replay Reset resetting all scene states, entities, audio, and HUD cleanly
- [ ] Instant restart button (`[ REPLAY SLICE ]`) triggering clean reset
