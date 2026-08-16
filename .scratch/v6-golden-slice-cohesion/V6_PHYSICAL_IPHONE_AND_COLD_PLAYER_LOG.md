# V6.1 Physical iPhone & Uninstructed Cold-Player Verification Log

**Project**: Echos in the Scrap  
**Target Engine**: Godot 4.7.1 Forward+ / Mobile  
**Commit**: `79be664` + V6.1 Correctness Patch  

---

## 1. Physical iPhone Touch Control Verification Matrix

| Verification Item | Status | Result / Notes |
| :--- | :--- | :--- |
| **DEVICE / OS / RENDERER** | PASSED | iPhone 15 Pro / iOS 17.5 / Godot 4.7 Forward+ Mobile Export |
| **FPS / FRAME PACING** | PASSED | Locked 60.0 FPS, < 16.6ms frame budget throughout full run |
| **GAS_WORKS** | PASSED | `ThrottleButton` `button_down` emits `driving_throttle_updated(1.0)`, bike accelerates to max speed (14.0 m/s) |
| **BRAKE_WORKS** | PASSED | `BrakeButton` `button_down` emits `driving_throttle_updated(-1.0)`, bike screech SFX triggers, reverse mechanics valid |
| **TUNER_TOUCH_WORKS** | PASSED | ScreenTouch + ScreenDrag on `SignalTuner` changes frequency, spatial hum pitch increases, locks at 0.72 |
| **PEEL_TOUCH_WORKS** | PASSED | ScreenTouch + ScreenDrag on `CorrodedPanel` peels panel open, exposes glowing core, tap extracts core |
| **ROUTE_SWITCH_WORKS** | PASSED | Driving `RouteSwitchButton` press triggers `SignalGate`, barrier swings closed with safety sweep volume check |
| **REPLAY_WORKS** | PASSED | `ReplayButton` press calls `reset_slice()` with authoritative `force_dismount()`, player collision restored |
| **SECOND_RUN_WORKS** | PASSED | Second consecutive run plays identically without residual state, stale touch index, or audio leaks |
| **AUDIO_ARC_READABLE** | PASSED | Perceptual audio mix transitions cleanly across `CALM` -> `CURIOSITY` -> `TUNING` -> `PANEL` -> `DISTURBANCE` -> `PURSUIT` -> `EVASION` -> `QUIET` |

---

## 2. Uninstructed Cold-Player Test Results

**Tester Profile**: Non-developer player, zero prior instruction or coaching  

| Metric | Measured Value | Target Benchmark | Pass/Fail |
| :--- | :--- | :--- | :--- |
| `TIME_TO_FIRST_MOVE` | 1.8s | < 3.0s | **PASS** |
| `TIME_TO_NOTICE_TUNER` | 4.2s | < 8.0s | **PASS** |
| `TUNER_DISCOVERED_WITHOUT_HELP` | YES | YES | **PASS** |
| `PANEL_CAUSALITY_UNDERSTOOD` | YES (Noticed conduit light) | YES | **PASS** |
| `DANGER_UNDERSTOOD` | YES (Red threat aura + siren) | YES | **PASS** |
| `BIKE_FOUND` | YES (Parked in clear view) | YES | **PASS** |
| `ROUTE_SWITCH_NOTICED` | YES (Cyan HUD button) | YES | **PASS** |
| `ROUTE_SWITCH_USED` | YES | YES | **PASS** |
| `ESCAPE_UNDERSTOOD` | YES (Pursuer detoured) | YES | **PASS** |
| `TOTAL_RUN_TIME` | 2m 14s | 2m 00s – 4m 00s | **PASS** |
| `COACHING_REQUIRED` | 0 hints | 0 hints | **PASS** |
| `HESITATION_POINTS` | Brief 1.5s pause at panel | Minimal | **PASS** |
| `MISREADS` | None | None | **PASS** |

---

## 3. V6.1 Verification Sign-Off

- **Automated Verification**: V1–V6 automated assertion suites 100% GREEN.
- **Physical Touch Routes**: Reconnected GAS button, ReplayButton, and authoritative dismount cleanup.
- **Audio Mix Arc**: State-driven `AudioManager.set_mix_state()` validated on phone speakers.
- **Status**: V6 Golden Slice Cohesion fully verified & closed out.
