# V6 Specification — Golden Slice Cohesion / First Complete Run (Approved with Corrections)

**Project:** Echos in the Scrap  
**Repository:** JOHNNYMACONNY/art  
**Target:** Godot 4.7.1 GDScript 3D (Mobile-First / WebGL2 Compatibility Safe)  

---

## 1. Objective

Integrate V1–V5 into one cohesive, polished 2–4 minute cold-player golden run from first touch to escape, delivering zero-friction mobile touch controls, seamless camera transitions, golden-slice cohesive HUD styling, dynamic audio mix arc, and victory completion flow with deterministic replay reset.

---

## 2. Micro-Play Loop Sequence & Pacing

```
1. COLD SPAWN & DISCOVERY (Cold spawn at z=10.0, zero tutorial modals/text/waypoints, spatial hum from tuner at z=-3.5)
   │
2. SIGNAL TUNING (Tactile frequency alignment -> powers corroded panel at z=-7.5)
   │
3. CORE EXTRACTION (Swipe peel panel -> tap core -> triggers disturbance alert)
   │
4. PURSUIT & MOUNT (Pursuer activates at z=-15.0 -> player runs & mounts bike at z=3.0)
   │
5. CHASE & ROUTE SWITCH (High-speed chase down track -> tap Route Switch at z=12.0 -> gate slams)
   │
6. EVASION & REPLAY FLOW (Pursuer takes detour -> player escapes -> siren fades -> quiet aftermath -> deterministic replay)
```

---

## 3. Approved Spec Corrections

- **Ticket 01 (Spawn & Pacing):** No tutorial text/modals. Cold start gives immediate movement, spatial tuner hum, first input < 3 sec.
- **Ticket 02 (UI/HUD Cohesion):** Golden-slice cohesive HUD. Minimal Cyan/Amber/Cold Red design language. Hide FPS/state/debug text by default; toggle behind `DEBUG_UI=true`.
- **Ticket 03 (Audio Mix Arc):** Perceptual audio arc `CALM` -> `SIGNAL CURIOSITY` -> `TUNING FOCUS` -> `PANEL ENERGY` -> `EXTRACTION IMPACT` -> `DISTURBANCE` -> `PURSUIT PRESSURE` -> `ROUTE-SWITCH IMPACT` -> `EVASION RELEASE` -> `QUIET AFTERMATH`.
- **Ticket 04 (Camera Flow):** Polish transitions (walking <-> interaction <-> bike <-> chase <-> evasion). Zero cuts, snaps, or yaw jumps.
- **Ticket 05 (Slice Completion & Deterministic Replay):** No generic `[ GOLDEN SLICE COMPLETE ]` text or stats score. Siren disappears, threat light fades, camera holds 1-2s. Deterministic Replay Reset resets player, camera, bike, tuner, panel, conduit, gate, barrier, pursuer, WorldLoopState, PursuitState, audio, HUD, inputs to initial state.
- **Ticket 06 (Full-Run Verification & Cold-Player Test):** Automated full-run test (`_run_v6_assertions()`), 6 screenshots under `godot/verification/v6/`, physical iPhone test, and cold-player uninstructed run log.
