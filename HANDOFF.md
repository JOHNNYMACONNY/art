# HANDOFF.md — V8 M02 Safe Areas & Touch Ergonomics
**Generated**: 2026-08-16T20:07 PDT  
**Branch**: `main`  
**Repo**: https://github.com/JOHNNYMACONNY/art  
**Engine**: Godot 4.7.1 Stable (Official)  
**V8 M01 Verified HEAD**: `43ed3e5aa4efdc803580baa52d31bdf2c6475e55`  
**Current Milestone**: V8 M02 — Mobile Safe-Area, Touch Ergonomics & Device Readiness  

---

## 1. Milestone Status Overview

| Milestone / Ticket | Description | Status | Key Deliverables |
|---|---|---|---|
| **V8 M01 (01.1 - 01.4)** | Visual Identity, Landmark Dressing, Lighting & Readability | ✅ CLOSED | Modular scrap dressing kit, 6 hero landmarks, lighting rig, dust particles, 8/8 real physics routes verified green, scored V7/V8 benchmark comparison. |
| **V8 02.1A & 02.2** | Safe-Area Transform Correction & Control Hierarchy | ✅ CLOSED | Corrected `aspect="keep"` uniform scale & pillarbox/letterbox offset mapper, ergonomic right-thumb hierarchy (Gas/Brake 20px gap, E-Brake 20px gap, Route Switch 20px gap, Dismount 150px safety separation), zero button overlap, 6 simulation profiles verified green. |
| **V8 02.3** | Adversarial Multi-Touch & Gesture Conflict Falsification | ⏳ READY | Simultaneous multi-finger driving, rapid transitions, boundary slide-offs, overlay pointer isolation. |
| **V8 02.4** | Aspect-Ratio Benchmark Suite, Regression Sweep & Walkthrough | ⏳ PENDING | 8 gameplay states captured across all simulated viewports, 17-suite regression verification, milestone walkthrough. |

---

## 2. Tickets V8 02.1A & 02.2 Architecture & Deliverables
1. **Mathematical Screen-to-Canvas Mapping**:
   - Correctly accounts for Godot's `aspect="keep"` uniform scale and pillarbox/letterbox offsets:
     `uniform_scale = min(screen_w / 960, screen_h / 540)`
     `offset_x = (screen_w - 960 * uniform_scale) / 2`
     `offset_y = (screen_h - 540 * uniform_scale) / 2`
     `canvas_coord = (screen_coord - offset) / uniform_scale`
   - Notches within black pillarbox bars leave 16:9 canvas 100% unobstructed.
   - Deep cutouts penetrating the canvas inset controls safely with zero clipping.
2. **Right-Thumb Ergonomic Control Hierarchy**:
   - `GAS` + `BRAKE`: 130x110px hit areas with 20px physical horizontal gap.
   - `E-BRAKE`: 280x60px spanning above Gas & Brake with 20px vertical gap.
   - `ROUTE SWITCH`: 280x60px above E-Brake with 20px vertical gap.
   - `DISMOUNT`: Anchored at top-right with 150px vertical safety separation.
3. **Deterministic Assertion Suite (`--run-v8-safe-area-assertions`)**:
   - All 6 simulated device profiles verified green (16:9 standard, 19.5:9 pillarboxed notch, 19.5:9 deep cutout, 19.5:9 right cutout, 20:9 home bar, 20:9 dual cutouts + home bar, 4:3 tablet).
   - Zero pairwise button overlap.
   - Active pointer purging verified on layout update.

---

## 3. Regression Suite Verification
All 17 automated test suites run green via `godot --headless --path godot/ -- ++ --<suite>-assertions`:
1. `--run-v1-assertions`: Reaction Loop & Locomotion
2. `--run-v2-assertions`: Micro-Play Loop (Panel & Tuner)
3. `--run-v3-assertions`: Courier Bike Feel & Mount/Dismount
4. `--run-v4-assertions`: Pressure & Pursuit Mechanics
5. `--run-v5-assertions`: Environmental Evasion Slice
6. `--run-v6-assertions`: Golden Slice Cohesion & Full Run
7. `--run-v7-ticket01-assertions`: Gate Collision & Peel Retest
8. `--run-v7-ticket02-assertions`: Dismount Rejection & Multi-touch Retest
9. `--run-v7-ticket02-1-assertions`: Chase Detour & Balance Retest
10. `--run-v7-ticket03-assertions`: Tuner Gesture & Near-Lock Retest
11. `--run-v7-ticket04-1-assertions`: Transmission & Handbrake
12. `--run-v7-ticket04-2-assertions`: Handling & Drift Physics
13. `--run-v7-ticket04-3-assertions`: Collision Response & Glance
14. `--run-v7-ticket05-assertions`: Chinatown Camera & Look-Ahead
15. `--run-v7-ticket06-assertions`: Audio Pressure & Instant Reset
16. `--run-v8-safe-area-assertions`: Mobile Safe-Area, Transform & Control Hierarchy (6/6 profiles + ergonomics PASS)
17. `--run-v8-readability`: Dynamic Readability & Route Matrix Validation (8/8 routes PASS)
