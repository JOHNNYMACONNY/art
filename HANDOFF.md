# HANDOFF.md — V8 M02 Safe Areas & Touch Ergonomics
**Generated**: 2026-08-16T19:53 PDT  
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
| **V8 02.1** | Safe-Area Foundation, Coordinate Safety & Device Simulator | ✅ CLOSED | `SafeAreaRoot` container hierarchy, `DisplayServer.get_display_safe_area()` viewport transform scaling, deterministic simulator API, 6 simulation profiles verified green, stretch policy A/B experiment locked (`aspect="keep"`). |
| **V8 02.2** | Thumb Reach, Button Separation & Ergonomic Hierarchy | ⏳ READY | Right-thumb cluster calibration, contextual route switch placement, separated dismount, forgiving hit areas. |
| **V8 02.3** | Adversarial Multi-Touch & Gesture Conflict Falsification | ⏳ PENDING | Simultaneous multi-finger driving, rapid transitions, boundary slide-offs, overlay pointer isolation. |
| **V8 02.4** | Aspect-Ratio Benchmark Suite, Regression Sweep & Walkthrough | ⏳ PENDING | 8 gameplay states captured across all simulated viewports, 17-suite regression verification, milestone walkthrough. |

---

## 2. Ticket V8 02.1 Architecture & Deliverables
1. **SafeAreaRoot Hierarchy**:
   - `TouchControlsUI` introduces `SafeAreaRoot` as the parent of `LeftTouchArea`, `RightTouchArea`, `DrivingOverlayPanel`, and `TensionHUDPanel`.
   - `GestureOverlayPanel` and `ReplayOverlayPanel` remain centered on the viewport.
2. **DisplayServer Integration**:
   - Uses `DisplayServer.get_display_safe_area()` combined with viewport transform matrices to convert screen pixel insets into canvas coordinates dynamically.
3. **Deterministic Simulator API**:
   - `set_simulated_safe_area(safe_rect: Rect2i, screen_size: Vector2i)` and `clear_simulated_safe_area()`.
   - Automated suite `--run-v8-safe-area-assertions` covers 6 simulation profiles (16:9 standard, 19.5:9 left notch, 19.5:9 right notch, 20:9 home bar, 20:9 dual cutout + home bar, 4:3 tablet).
4. **Active Touch State Purge**:
   - All active touches and pointer indices are immediately cleared on viewport resize or safe-area recomputation (`reset_all_input_states()`), preventing sticky inputs.
5. **Stretch-Policy Decision**:
   - Evaluated `window/stretch/aspect="keep"` vs candidate `aspect="expand"`.
   - `aspect="keep"` strictly preserves isometric Chinatown camera composition, avoids void edge exposure, and maintains consistent thumb reach across all aspect ratios.
   - **Decision: LOCK `aspect="keep"`**.

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
16. `--run-v8-safe-area-assertions`: Mobile Safe-Area & Device Simulation (6/6 profiles PASS)
17. `--run-v8-readability`: Dynamic Readability & Route Matrix Validation (8/8 routes PASS)
