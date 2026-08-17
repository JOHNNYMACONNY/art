# HANDOFF.md — V8 M02 Mobile Safe-Area, Touch Ergonomics & Multi-Touch Falsification
**Generated**: 2026-08-16T20:25 PDT  
**Branch**: `main`  
**HEAD**: `90b679a8932313a78e4c73e6da3711d3d121e3d3`  
**Repo**: https://github.com/JOHNNYMACONNY/art  
**Engine**: Godot 4.7.1 Stable (Official)  
**Current Milestone**: V8 M02 — Mobile Safe-Area, Touch Ergonomics & Device Readiness  

---

## 1. Milestone Status Overview

| Milestone / Ticket | Description | Status | Key Deliverables |
|---|---|---|---|
| **V8 M01 (01.1 - 01.4)** | Visual Identity, Landmark Dressing, Lighting & Readability | ✅ CLOSED | Modular scrap dressing kit, 6 hero landmarks, lighting rig, dust particles, 8/8 real physics routes verified green, scored V7/V8 benchmark comparison. Commit `43ed3e5`. |
| **V8 02.1A** | Safe-Area Transform Correction | ✅ CLOSED | Corrected `aspect="keep"` uniform scale & pillarbox/letterbox offset mapper, 6 simulation profiles verified green. Commit `3151d20`. |
| **V8 02.2A** | Compact 2-Column Right-Thumb Hierarchy & Notch Rejection | ✅ CLOSED | Two-column button layout (`[E-BRAKE][ROUTE]` over `[BRAKE][GAS]`, `DISMOUNT` isolated high/right), 16px grid spacing, dynamic route invariance (0.0px movement), strict excluded notch/home-bar touch rejection, Action/Gas zone parity. |
| **V8 02.3** | Adversarial Multi-Touch & Gesture Conflict Falsification | ✅ CLOSED | 18-test adversarial matrix (A through R): independent steering/driving ownership, 3-finger simultaneous releases, brake precedence, rapid alternation, boundary slide-off, route/dismount isolation, tuner/peel/core gesture isolation, instant replay reset, layout update pointer purging, duplicate index defense. |
| **V8 02.4** | Aspect-Ratio Benchmark Suite, Regression Sweep & Walkthrough | ⏳ READY | 8 gameplay states captured across all simulated viewports, full 19-suite regression verification, milestone walkthrough. |

---

## 2. Tickets V8 02.2A & 02.3 Architecture & Deliverables

### A. Compact 2-Column Right-Thumb Hierarchy (02.2A)
- **Geometry @ 960x540**:
  - `GAS`: 132x108 at `[-156, -132, -24, -24]` (right column, bottom row)
  - `BRAKE`: 132x108 at `[-304, -132, -172, -24]` (left column, bottom row)
  - `E-BRAKE`: 132x64 at `[-304, -212, -172, -148]` (left column, top row — directly above Brake)
  - `ROUTE SWITCH`: 132x64 at `[-156, -212, -24, -148]` (right column, top row — directly above Gas, contextual)
  - `DISMOUNT`: 132x56 at `[-156, 24, -24, 80]` (isolated high/right, 248px vertical safety separation)
  - `ACTION` (Foot Mode): 132x108 at `[-156, -132, -24, -24]` (identical muscle-memory position to Gas)
- **Dynamic Invariance**:
  - Toggling `ROUTE SWITCH` visibility produces **0.000px displacement** in neighboring controls.
- **Physical Margins (16px Grid)**:
  - Gas ↔ Brake horizontal gap: **16.0 px**
  - Handbrake ↔ Brake vertical gap: **16.0 px**
  - Route Switch ↔ Gas vertical gap: **16.0 px**
  - Handbrake ↔ Route Switch horizontal gap: **16.0 px**
  - Dismount ↔ Driving cluster separation: **248.0 px**
- **Excluded Notch/Home-Bar Rejection**:
  - Touches in excluded notch/cutout regions (`left_safe_bounds.has_point(pos) == false`) are completely ignored and spawn zero joystick instances.

### B. Adversarial Multi-Touch & Gesture Matrix (02.3)
Dedicated suite `--run-v8-multitouch-assertions` tests 18 adversarial scenarios:
- **Test A (Steer + Gas)**: Independent ownership and throttle +1.0 output.
- **Test B (Steer + Brake)**: Independent ownership and throttle -1.0 output.
- **Test C (Steer + E-Brake)**: Independent ownership and handbrake true output.
- **Test D (Steer + Gas + E-Brake)**: 3 simultaneous touches maintain state across all 3 release orders (Gas first, E-Brake first, Steer first).
- **Test E (Gas + Brake Priority)**: Brake takes absolute precedence (-1.0); releasing brake reverts to +1.0 throttle without re-tapping.
- **Test F (Rapid Alternation)**: 20 rapid transitions yield zero latched throttle or stuck state.
- **Test G (Boundary Slide-Off)**: Dragging outside button boundaries and releasing clears pointer state cleanly.
- **Test H (Route Switch while Steering)**: Route switch triggers cleanly with zero disturbance to active steering.
- **Test I (E-Brake vs Route Switch Isolation)**: Boundary corner touches trigger only the target action without cross-activation.
- **Test J (Dismount while Steering)**: High-speed dismount rejection toast does not disturb steering control.
- **Test K (3rd/4th Touch Overload)**: Spurious extra touches cannot steal or perturb owned pointers.
- **Test L (Mode Switch Mid-Touch)**: Vehicle ↔ Foot transition instantly purges incompatible inputs.
- **Test M (Tuner Overlay Isolation)**: Drag and outside release emit signal cleanly and leave zero driving state.
- **Test N (Peel Overlay Isolation)**: Drag and outside release emit signal cleanly.
- **Test O (Core Tap Isolation)**: Core pull button operates independently without drag interference.
- **Test P (Replay Reset)**: Replay trigger resets all inputs, steering, throttle, and pointer indices.
- **Test Q (Safe-Area Change Mid-Touch)**: Safe area recomputation purges all active pointers immediately.
- **Test R (Duplicate Index Defense)**: Fail-closed single pointer ownership.

---

## 3. Enumerated Regression Suite (19/19 Suites Verified Green)
All 19 test suites run cleanly via `godot --headless --path godot/ -- ++ --<suite>`:
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
16. `--run-v8-safe-area-assertions`: Mobile Safe-Area, Transform & Layout Invariants (6/6 profiles PASS)
17. `--run-v8-thumb-reach-assertions`: Dedicated Thumb Reach & Control Hierarchy (2-column layout PASS)
18. `--run-v8-multitouch-assertions`: Adversarial Multi-Touch & Gesture Conflict Suite (18/18 tests A-R PASS)
19. `--run-v8-readability`: Dynamic Readability & Route Matrix Validation (8/8 real physics routes PASS)

---

## 4. Verification Evidence & Artifacts
- Visual proof screenshots exported:
  - `godot/verification/v8/v8_safe_area_01_16x9_standard.png`
  - `godot/verification/v8/v8_safe_area_02_19_5x9_left_notch.png`
  - `godot/verification/v8/v8_safe_area_03_19_5x9_right_notch.png`
  - `godot/verification/v8/v8_safe_area_04_20x9_home_bar.png`
  - `godot/verification/v8/v8_safe_area_05_20x9_dual_cutout.png`
  - `godot/verification/v8/v8_safe_area_06_4x3_tablet.png`
- Verified status vocabulary:
  - `SIMULATED SAFE-AREA GEOMETRY`: **VERIFIED**
  - `SIMULATED REACH GEOMETRY`: **VERIFIED**
  - `SIMULATED MULTITOUCH`: **VERIFIED**
  - `HUMAN THUMB COMFORT`: UNKNOWN (Pending hardware test)
  - `REAL DEVICE UX`: UNKNOWN (Pending hardware test)
  - `REAL MOBILE PERFORMANCE`: UNKNOWN (Pending hardware test)
