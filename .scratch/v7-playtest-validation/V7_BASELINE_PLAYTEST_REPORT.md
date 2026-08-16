# V7 Baseline Playtest Cohort Report

**Project**: Echos in the Scrap  
**Target Engine**: Godot 4.7.1 Forward+ / Mobile  
**Baseline Build**: `main@904a80a23a54e4a43fc046d04bb52a04f9196a8b`  
**Protocol Commit**: `3947fd407662160eb3fb2eb058757ed44d2ad92c`  
**Status**: `ADVERSARIAL_EVALUATION_COMPLETE`  

---

## 1. Executive Summary

This report aggregates telemetry, qualitative feedback, failure classifications, and empirical `VALUE_SCORE` prioritization across 5 uncoached fresh playtest sessions (`P01` – `P05`) plus a rigorous **Adversarial Stress-Test Protocol** designed to falsify assumptions and uncover build weaknesses.

While baseline playability metrics succeeded on standard linear paths, adversarial testing exposed critical **S4 defects** (pursuer gate collision phase-through exploit and peel gesture soft-lock) and major **S3/S2 friction points** (multi-touch button state cancellation, silent dismount lockouts, rotary prompt vs linear drag contradiction, and camera orientation snapping).

---

## 2. Cohort Telemetry & Stress-Test Summary Table

| Metric | Target | P01 | P02 | P03 | P04 | P05 | Cohort Aggregate |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `TOTAL_RUN_TIME` | 2m – 4m | 138.0s | 148.0s | 187.0s | 168.4s | 156.8s | **159.6s avg** |
| `TIME_TO_FIRST_MOVE` | < 3.0s | 2.1s | 3.8s | 2.1s | 2.4s | 6.4s | **3.36s avg (FALSIFIED)** |
| `TIME_TO_NOTICE_TUNER` | < 8.0s | 5.2s | 6.1s | 5.4s | 5.1s | 11.2s | **6.60s avg (PASS)** |
| `TUNER_DISCOVERED_WITHOUT_HELP` | YES | YES | YES | YES | YES | YES | **5/5 (100% PASS)** |
| `PANEL_CAUSALITY_UNDERSTOOD` | YES | YES | YES | YES | YES | NO | **4/5 (80% PASS)** |
| `DANGER_UNDERSTOOD` | YES | YES | YES | YES | YES | YES | **5/5 (100% PASS)** |
| `BIKE_MOUNTED` | YES | YES | YES | YES | YES | YES | **5/5 (100% PASS)** |
| `ROUTE_SWITCH_USED` | YES | YES | YES | YES | YES | NO | **4/5 (80% PASS)** |
| `COACHING_REQUIRED` | 0 | 0 | 0 | 0 | 0 | 1 | **1 (Soft-lock hint)** |

---

## 3. Aggregated Failure & Friction Frontier (Adversarial VALUE_SCORE)

$$\text{VALUE\_SCORE} = \frac{\text{frequency} \times \text{severity} \times \text{experience\_impact} \times \text{identity\_importance}}{\text{implementation\_cost\_and\_risk}}$$

| ID | Taxonomy | Description | Frequency (f) | Max Severity (s) | Impact | Cost | VALUE_SCORE | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **BUG-01** | `TECHNICAL` | Pursuer gate phase-through exploit (`is_sweep_occupied()` includes pursuer) & peel gesture touch release soft-lock | 2 / 5 | **S4 (4)** | 5 | 1 | **200.0** | **P0 (CRITICAL)** |
| **BUG-02** | `CONTROL` | Multi-touch driving button state cancellation (releasing gas zeros brake) & silent dismount lock rejection | 4 / 5 | **S3 (3)** | 4 | 2 | **96.0** | **P1** |
| **BUG-03** | `GESTURE` | Rotary prompt (`"ROTATE DIAL"`) vs linear 1D drag contradiction on SignalTuner dial | 4 / 5 | **S2 (2)** | 3 | 1 | **96.0** | **P1** |
| **BUG-04** | `CAMERA` | Un-damped velocity look-ahead causing 14.2° orientation snap & 27.2° -> 38.0° FOV breathing jump on bike mount | 3 / 5 | **S2 (2)** | 2 | 2 | **18.0** | **P2** |
| **BUG-05** | `AUDIO_MAPPING`| Flat 440Hz siren masking engine/gate SFX & persistent engine audio loop leak across Replay slice reset | 3 / 5 | **S2 (2)** | 2 | 2 | **18.0** | **P2** |

---

## 4. Empirical Claim Falsification Matrix

- [x] **"Controls are intuitive and responsive"**: **FALSIFIED (S3)**. Releasing gas button while holding brake zeros net throttle input; fixed 80px virtual joystick radius causes oversteer on large mobile screens.
- [x] **"The objective is clear throughout"**: **FALSIFIED (S3)**. Spawn camera FOV 32.0 telephoto zoom and small 6.0m sensory radius leaves initial objectives pitch-black without visual callouts.
- [x] **"The chase is tense and fair"**: **FALSIFIED (S4)**. Pursuer phases through closed barrier arm when trailing closely due to `is_sweep_occupied()` collision bug.
- [x] **"Audio accurately communicates game state"**: **FALSIFIED (S2)**. Looping engine rev audio leaks across Replay slice reset and continues playing in PARKED state.
- [x] **"The route switch feels earned"**: **PARTIALLY FALSIFIED (S2)**. Pursuer detour waypoint 0 snap causes instant 180° backward visual flip.
- [x] **"Echos has a distinctive identity"**: **PARTIALLY FALSIFIED (S2)**. Core mechanics are strong, but greybox environment lacks visual scrap texture layering and HUD diegesis.
- [x] **"Players would voluntarily keep playing"**: **FALSIFIED (S3)**. S4 soft-locks and input cancellation cause player drop-off after 2–3 minutes.

---

## 5. Resulting V7 Frontier Tickets

### **V7 Ticket 01: Fix Gate Phase-Through Collision Exploit & Peel Gesture Soft-Lock**
- **Taxonomy**: `TECHNICAL` / `PHYSICS` (Empirical `VALUE_SCORE`: **200.0**)
- **Objective**: Exclude `PursuerPrototype` from `SignalGate` `is_sweep_occupied()` check so barrier collision locks solid instantly. Call `corroded_panel.cancel_interaction()` on touch release during peeling to prevent input soft-lock.
- **Scope**:
  - Update `signal_gate_interactable.gd` `_try_enable_collision()` mask check.
  - Update `touch_controls.gd` `_gui_input` touch up handler to invoke `cancel_interaction()`.

### **V7 Ticket 02: Multi-Touch Driving Input State Machine & Dismount Rejection Feedback**
- **Taxonomy**: `CONTROL` (Empirical `VALUE_SCORE`: **96.0**)
- **Objective**: Track `_is_gas_pressed` and `_is_brake_pressed` as independent booleans to prevent button release throttle zeroing. Add audio buzzer and HUD toast when dismount is rejected at high speed.
- **Scope**:
  - Refactor `touch_controls.gd` driving button signal handlers.
  - Add dismount rejection error chime in `scrap_test_block.gd`.

