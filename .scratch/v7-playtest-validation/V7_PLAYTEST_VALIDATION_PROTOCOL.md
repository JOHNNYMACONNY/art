# V7 Specification: Playtest-Driven Vertical-Slice Validation Protocol

**Project**: Echos in the Scrap  
**Target Engine**: Godot 4.7.1 Forward+ / Mobile  
**Baseline Build**: `main@904a80a23a54e4a43fc046d04bb52a04f9196a8b`  

---

## 1. Problem Statement

Automated assertion suites and single-developer cold tests prove physical execution and system correctness, but cannot prove if the 2–4 minute Golden Slice is fun, legible, memorable, and distinctly *Echos in the Scrap* for uncoached fresh players.

---

## 2. Solution

Execute a structured 5-player baseline playtest cohort on the exact `904a80a` build without adding new mechanics or speculative polish. Capture quantitative observation telemetry, qualitative exit interview responses, classify all observed friction into a 15-category taxonomy, and prioritize remedies using an empirical `VALUE_SCORE` formula before authoring any V7 tickets.

---

## 3. Cohort & Test Environment Rules

- **Cohort Target**: Minimum 5 fresh players (mobile preferred, zero codebase/development involvement, zero prior explanation of mechanics or controls).
- **Test Protocol**:
  1. Hand device to player with sole prompt: *"Play this."*
  2. Zero initial instructions, zero tutorial popups, zero control maps provided.
  3. Observer remains silent. Zero coaching or hints unless player is hard-stuck for > 45 seconds.
  4. Record video/screen capture where practical; log real-time telemetry metrics.

---

## 4. Observation Telemetry Schema

For every playtest session, log the following standardized data fields:

### Session Metadata
- `SESSION_ID`: `P01` – `P05`
- `DEVICE`: iPhone / iPad / Android / Mac Touch
- `OS`: iOS 17.5+ / macOS 14+
- `BUILD_COMMIT`: `904a80a23a54e4a43fc046d04bb52a04f9196a8b`
- `TOTAL_RUN_TIME`: Seconds

### Quantitative Pacing & Causality Telemetry
- `TIME_TO_FIRST_MOVE`: Seconds (Target: < 3.0s)
- `TIME_TO_NOTICE_TUNER`: Seconds (Target: < 8.0s)
- `TIME_TO_BEGIN_TUNING`: Seconds
- `TUNING_ATTEMPTS`: Count
- `PANEL_FOUND_WITHOUT_HELP`: `true` / `false`
- `PANEL_CAUSALITY_UNDERSTOOD`: `true` / `false`
- `PEEL_GESTURE_UNDERSTOOD`: `true` / `false`
- `DANGER_UNDERSTOOD`: `true` / `false`
- `BIKE_FOUND`: `true` / `false`
- `BIKE_MOUNTED`: `true` / `false`
- `VEHICLE_CONTROL_ERRORS`: Count
- `ROUTE_SWITCH_NOTICED`: `true` / `false`
- `ROUTE_SWITCH_USED`: `true` / `false`
- `PURSUER_DETOUR_UNDERSTOOD`: `true` / `false`
- `INTERCEPTIONS`: Count
- `REPLAY_USED_VOLUNTARILY`: `true` / `false`

### Friction & Qualitative Log
- `COACHING_EVENTS`: List of required developer interventions
- `HESITATION_POINTS`: Timestamped list of pauses > 2.0s
- `MISREADS`: Misinterpreted visual/audio cues
- `INPUT_ERRORS`: Accidental or failed touch gestures
- `CAMERA_CONFUSION`: View occlusion or disorienting shifts
- `AUDIO_CONFUSION`: Misunderstood audio signals

---

## 5. Post-Play Interview Questionnaire

Ask these 9 questions immediately after session completion:

1. **Goal**: What did you think you were supposed to do?
2. **High Point**: What part felt best?
3. **Low Point**: What part felt weakest or confusing?
4. **Audio Legibility**: What did you think the sound was telling you?
5. **Counterplay Payoff**: Did escaping feel earned or automatic?
6. **Retention Memory**: What do you remember most?
7. **Identity**: What kind of game do you think this is?
8. **Session Desire**: Would you play another few minutes?
9. **Replay Desire**: Would you replay this slice right now?

---

## 6. Failure Taxonomy & Severity Model

### Primary Classification Taxonomy
1. `DISCOVERY` - Missed interactable objects or spatial cues
2. `CONTROL` - Virtual joystick or button touch targeting failure
3. `GESTURE` - Tuning dial or panel peel drag gesture misread
4. `TARGETING` - Interaction proxy auto-magnetism failure
5. `CAMERA` - Framing occlusion, abrupt pan, or FOV disorientation
6. `AUDIO_MAPPING` - Unclear sound event cues or spatial feedback
7. `WORLD_CAUSALITY` - Unclear conduit power flow between tuner and panel
8. `NAVIGATION` - Disorientation on track or shortcut corridor
9. `PURSUIT_TENSION` - Pursuer too fast, too slow, or non-threatening
10. `ROUTE_SWITCH` - Unnoticed or misunderstood gate slam button
11. `VISUAL_READABILITY` - Contrast, color coding, or outline legibility
12. `PACING` - Dead time or sudden difficulty spike
13. `IDENTITY` - Prototype feels generic rather than Echos in the Scrap
14. `ENDING` - Evasion aftermath feels incomplete or abrupt
15. `TECHNICAL` - Performance drop, collision glitch, or state bug

### Severity Scale
- **S0**: Informational observation / zero gameplay impact
- **S1**: Minor friction / player self-corrects in < 2s
- **S2**: Noticeable experience degradation / hesitation > 5s
- **S3**: Progression block / requires observer hint or coaching
- **S4**: Crash, soft-lock, unusable control, progression break

---

## 7. Decision Rule & Ticket Prioritization Formula

No individual anecdote triggers an immediate code edit. After capturing all 5 sessions, aggregate all observed failures and calculate:

$$\text{VALUE\_SCORE} = \frac{\text{frequency} \times \text{severity} \times \text{experience\_impact} \times \text{identity\_importance}}{\text{implementation\_cost\_and\_risk}}$$

The failure yielding the highest empirical `VALUE_SCORE` across the cohort will become **V7 Ticket 01**.

---

## 8. Success Criteria Thresholds

The V7 validation phase achieves completion when cohort data satisfies:

- $\ge 4/5$ players move within 3 seconds without coaching.
- $\ge 4/5$ players discover tuner and panel causality without help.
- $\ge 4/5$ players recognize pursuit threat immediately upon disturbance.
- $\ge 4/5$ players notice RouteSwitch button during driving pursuit.
- $\ge 3/5$ players execute shortcut route switch without coaching.
- $\ge 4/5$ players describe escape as intentional and earned.
- $\ge 3/5$ players express voluntary desire to continue/replay.
- $0$ S4 defects across all cohort runs.
