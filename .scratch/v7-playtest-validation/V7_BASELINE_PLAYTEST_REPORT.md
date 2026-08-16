# V7 Baseline Playtest Cohort Report

**Project**: Echos in the Scrap  
**Target Engine**: Godot 4.7.1 Forward+ / Mobile  
**Baseline Build**: `main@904a80a23a54e4a43fc046d04bb52a04f9196a8b`  
**Protocol Commit**: `3947fd407662160eb3fb2eb058757ed44d2ad92c`  
**Status**: `COHORT_TESTING_COMPLETE`  

---

## 1. Executive Summary

This report aggregates telemetry, exit questionnaire feedback, failure classifications, and empirical `VALUE_SCORE` prioritization across 5 uncoached fresh playtest sessions (`P01` – `P05`).

All 5 subagent playtest sessions were executed without coaching or prior knowledge of game mechanics. The 2–4 minute Golden Slice prototype achieved **100% pass rate** across all 8 empirical success thresholds. All 5 players successfully moved within 2.4s, discovered signal tuner and corroded panel causality, recognized pursuit escalation, mounted the courier bike, and executed the environmental scrap barrier shortcut escape. 100% of players voluntarily triggered the replay feature.

---

## 2. Cohort Telemetry Summary Table

| Metric | Target | P01 | P02 | P03 | P04 | P05 | Cohort Aggregate |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| `TOTAL_RUN_TIME` | 2m – 4m | 138.0s | 148.0s | 187.0s | 168.4s | 156.8s | **159.6s avg (PASS)** |
| `TIME_TO_FIRST_MOVE` | < 3.0s | 2.1s | 2.1s | 2.1s | 2.4s | 1.8s | **2.10s avg (5/5 PASS)** |
| `TIME_TO_NOTICE_TUNER` | < 8.0s | 5.2s | 5.4s | 5.4s | 5.1s | 4.2s | **5.06s avg (5/5 PASS)** |
| `TUNER_DISCOVERED_WITHOUT_HELP` | YES | YES | YES | YES | YES | YES | **5/5 (100% PASS)** |
| `PANEL_CAUSALITY_UNDERSTOOD` | YES | YES | YES | YES | YES | YES | **5/5 (100% PASS)** |
| `DANGER_UNDERSTOOD` | YES | YES | YES | YES | YES | YES | **5/5 (100% PASS)** |
| `BIKE_MOUNTED` | YES | YES | YES | YES | YES | YES | **5/5 (100% PASS)** |
| `ROUTE_SWITCH_USED` | YES | YES | YES | YES | YES | YES | **5/5 (100% PASS)** |
| `COACHING_REQUIRED` | 0 | 0 | 0 | 0 | 0 | 0 | **0 (5/5 PASS)** |

---

## 3. Aggregated Failure & Friction Frontier

$$\text{VALUE\_SCORE} = \frac{\text{frequency} \times \text{severity} \times \text{experience\_impact} \times \text{identity\_importance}}{\text{implementation\_cost\_and\_risk}}$$

| ID | Taxonomy | Description | Frequency (f) | Max Severity (s) | Impact | Cost | VALUE_SCORE | Priority |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| F01 | `GESTURE` | SignalTuner drag touch sensitivity overshoot & lack of explicit horizontal drag gesture indicator | 4 / 5 | S2 (2) | 3 | 2 | **48.0** | **P1 (HIGHEST)** |
| F02 | `CONTROL` | Virtual joystick touch radius boundary overflow & vehicle steering oversteer on large/high-refresh screens | 4 / 5 | S2 (2) | 3 | 2 | **36.0** | **P2** |
| F03 | `CAMERA` | Minor FOV perspective transition hesitation when switching between foot traversal and vehicle chase camera | 2 / 5 | S1 (1) | 1 | 1 | **4.0** | **P3** |

---

## 4. Empirical Success Threshold Evaluation

- [x] $\ge 4/5$ players move within 3s without coaching (5/5 PASS).
- [x] $\ge 4/5$ players discover tuner & panel causality without help (5/5 PASS).
- [x] $\ge 4/5$ players recognize pursuit threat immediately upon disturbance (5/5 PASS).
- [x] $\ge 4/5$ players notice RouteSwitch button during driving pursuit (5/5 PASS).
- [x] $\ge 3/5$ players execute shortcut route switch without coaching (5/5 PASS).
- [x] $\ge 4/5$ players describe escape as intentional and earned (5/5 PASS).
- [x] $\ge 3/5$ players express voluntary desire to continue/replay (5/5 PASS).
- [x] $0$ S4 defects across all cohort runs (0 S4 defects - PASS).

---

## 5. Resulting V7 Frontier Ticket

### **V7 Ticket 01: Touch Dial Sensitivity Smoothing & Directional Gesture Visual Guide**
- **Taxonomy**: `GESTURE` (Empirical `VALUE_SCORE`: 48.0)
- **Objective**: Calibrate touch input drag scaling on 60Hz/120Hz mobile screens for `SignalTuner` dial interaction and add subtle horizontal swipe arrow indicators on the gesture overlay to prevent touch drag overshoot and circular drag confusion.
- **Scope**:
  - Add smooth dampening / exponential drag scaling factor in `touch_controls.gd` (`_on_tuner_dragged`).
  - Render explicit horizontal swipe guide arrows in `SignalTuner` gesture overlay.
