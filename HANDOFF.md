# HANDOFF.md — V8 M02 Mobile Safe-Area, Touch Ergonomics, Global Pointer Ownership & Adversarial Multi-Touch
**Generated**: 2026-08-16T20:50 PDT  
**Branch**: `main`  
**Repo**: https://github.com/JOHNNYMACONNY/art  
**Engine**: Godot 4.7.1 Stable (Official)  
**Current Milestone**: V8 M02 — Mobile Safe-Area, Touch Ergonomics & Device Readiness (100% CLOSED)  

---

## 1. Milestone Status Overview

| Milestone / Ticket | Description | Status | Key Deliverables |
|---|---|---|---|
| **V8 M01 (01.1 - 01.4)** | Visual Identity, Landmark Dressing, Lighting & Readability | ✅ CLOSED | Modular scrap dressing kit, 6 hero landmarks, lighting rig, dust particles, 8/8 real physics routes verified green, scored V7/V8 benchmark comparison. Commit `43ed3e5`. |
| **V8 02.1A** | Safe-Area Transform Correction | ✅ CLOSED | Corrected `aspect="keep"` uniform scale & pillarbox/letterbox offset mapper, 6 simulation profiles verified green. Commit `3151d20`. |
| **V8 02.2A** | Compact 2-Column Right-Thumb Hierarchy & Notch Rejection | ✅ CLOSED | Two-column button layout (`[E-BRAKE][ROUTE]` over `[BRAKE][GAS]`, `DISMOUNT` isolated high/right), 16px grid spacing, dynamic route invariance (0.0px movement), strict excluded notch/home-bar touch rejection, Action/Gas zone parity. |
| **V8 02.3 & 02.3B** | Global Pointer Ownership & Adversarial Multi-Touch Matrix | ✅ CLOSED | Global pointer ownership registry (`is_pointer_index_claimed`), mouse sentinel disambiguation (`MOUSE_POINTER_INDEX = -999`), 18-test adversarial matrix (A through R green), duplicate index rejection across all controls, canonical button pressed paths. |
| **V8 02.4** | Aspect-Ratio Benchmark & 8-Gameplay-State Capture Matrix | ✅ CLOSED | 8 canonical gameplay state renders (`v8_mobile_01` through `08`), multi-viewport telemetry report (`v8_02_4_aspect_benchmark_telemetry.md`), gameplay state scorecard (`v8_02_4_gameplay_state_scorecard.md`), full 19-suite regression verification (19/19 green). |

---

## 2. Global Pointer Ownership Architecture (02.3B)
- **Registry Function**: `TouchControlsUI.is_pointer_index_claimed(index: int) -> bool`
  - Prevents one physical touch index from claiming multiple logical controls simultaneously (`_joystick_touch_index`, `_gas_touch_index`, `_brake_touch_index`, `_handbrake_touch_index`, `_interaction_touch_index`).
- **Mouse Disambiguation**: `const MOUSE_POINTER_INDEX: int = -999` separates synthetic desktop/editor clicks from physical mobile touch index 0.
- **Fail-Closed Duplicate Rejection**: In `gas_button`, `brake_button`, `handbrake_button`, `_start_joystick`, and `gesture_panel`, any incoming touch with an already-claimed index is rejected.

---

## 3. 8 Canonical Mobile Gameplay States (02.4)
1. `godot/verification/v8/v8_mobile_01_cold_start.png`: Cold Start & Action Button (Foot Mode)
2. `godot/verification/v8/v8_mobile_02_tuner_active.png`: Signal Tuner Approach & Overlay
3. `godot/verification/v8/v8_mobile_03_peel_extract.png`: Corroded Panel Peel & Core Extract
4. `godot/verification/v8/v8_mobile_04_bike_mounted.png`: Bike Mounted & Staging
5. `godot/verification/v8/v8_mobile_05_driving_2col.png`: Normal Driving (2-Column Layout)
6. `godot/verification/v8/v8_mobile_06_pursuit_route.png`: Pursuit Active & Route Switch
7. `godot/verification/v8/v8_mobile_07_gate_shortcut.png`: Signal Gate / Shortcut Decision at Speed
8. `godot/verification/v8/v8_mobile_08_aftermath_replay.png`: Quiet Aftermath & Replay Overlay

---

## 4. Enumerated 19-Suite Regression Matrix (100% Green)
1. `--run-v1-assertions`: PASS (Reaction Loop & Locomotion)
2. `--run-v2-assertions`: PASS (Micro-Play Loop)
3. `--run-v3-assertions`: PASS (Courier Bike Feel & Mount/Dismount)
4. `--run-v4-assertions`: PASS (Pressure & Pursuit Mechanics)
5. `--run-v5-assertions`: PASS (Environmental Evasion Slice)
6. `--run-v6-assertions`: PASS (Golden Slice Cohesion & Full Run)
7. `--run-v7-ticket01-assertions`: PASS (Gate Collision & Peel Retest)
8. `--run-v7-ticket02-assertions`: PASS (Dismount Rejection & Multi-touch Retest)
9. `--run-v7-ticket02-1-assertions`: PASS (Chase Detour & Balance Retest)
10. `--run-v7-ticket03-assertions`: PASS (Tuner Gesture & Near-Lock Retest)
11. `--run-v7-ticket04-1-assertions`: PASS (Transmission & Handbrake)
12. `--run-v7-ticket04-2-assertions`: PASS (Handling & Drift Physics)
13. `--run-v7-ticket04-3-assertions`: PASS (Collision Response & Glance)
14. `--run-v7-ticket05-assertions`: PASS (Chinatown Camera & Look-Ahead)
15. `--run-v7-ticket06-assertions`: PASS (Audio Pressure & Instant Reset)
16. `--run-v8-safe-area-assertions`: PASS (6/6 simulated device profiles + safe-area insets)
17. `--run-v8-thumb-reach-assertions`: PASS (Dedicated 2-column thumb hierarchy & notch rejection suite)
18. `--run-v8-multitouch-assertions`: PASS (Dedicated 18-test adversarial multi-touch matrix A-R with duplicate pointer rejection)
19. `--run-v8-readability`: PASS (8/8 real gameplay physics routes & landmark framing)

---

## 5. Hardware Readiness & Evidence Classification
- `SIMULATED SAFE-AREA GEOMETRY`: **VERIFIED**
- `SIMULATED REACH GEOMETRY`: **VERIFIED**
- `SIMULATED MULTITOUCH`: **VERIFIED**
- `SIMULATED SEMANTIC EVENT EXACTNESS`: **VERIFIED**
- `GLOBAL POINTER OWNERSHIP`: **VERIFIED**
- `HUMAN THUMB COMFORT`: **UNKNOWN** (Pending hardware test)
- `REAL DEVICE UX`: **UNKNOWN** (Pending hardware test)
- `REAL MOBILE PERFORMANCE`: **UNKNOWN** (Pending hardware test)
