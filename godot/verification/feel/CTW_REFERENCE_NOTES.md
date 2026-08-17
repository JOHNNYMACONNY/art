# CTW Behavioral Reference Notes

**Project:** ECHOES IN THE SCRAPHEAP  
**Wave:** CTW Feel Translation Wave 1  
**Ticket:** #11 baseline/reference harness

## Boundary

`Grand Theft Auto: Chinatown Wars` is used only as a **publicly observable behavioral reference**.

Allowed evidence:
- our own legitimate capture from a legally obtained copy / original hardware / lawful emulator setup;
- high-quality public gameplay footage when capture provenance is documented;
- public first-party documentation, interviews, reviews, or developer commentary;
- normalized timing and screen-space observations.

Do **not** store or infer:
- leaked/decompiled Rockstar source;
- proprietary assets, audio, video, maps, textures, or extracted game data;
- exact CTW meters, masses, torque, friction coefficients, tire constants, steering constants, or FOV degrees unless directly and legitimately documented;
- fake precision from uncertain footage.

CTW observations define **behavioral envelopes**, not implementation constants. ECHOES may intentionally diverge when that produces better control, readability, identity, accessibility, performance, or fun.

---

## Capture record template

Create one record per controlled reference clip.

```text
REFERENCE_ID:
SCENARIO: R1 | R2 | R3 | R4 | R5 | R6 | R7
SOURCE_TYPE: OWN_CAPTURE | PUBLIC_FOOTAGE | DOCUMENTATION
SOURCE_DESCRIPTION:
PLATFORM / VERSION:
CAPTURE_FPS:
VIEWPORT / ASPECT:
START_FRAME:
END_FRAME:
KNOWN_DROPPED_FRAMES:
EMULATION_SPEED_KNOWN: YES | NO | N/A
TRAFFIC / WORLD INTERFERENCE:
CAMERA CUTS / EDITS:
OTHER_UNCERTAINTY:
```

### R1 — Launch / coast / brake
Record where observable:
- frames to visible motion onset;
- normalized acceleration shape;
- coast-down time;
- stopping time;
- stopping distance in vehicle lengths or screen-height fractions;
- relative camera scale/look-ahead response.

### R2 — Constant-input ~90° turn
Record low / medium / high-speed examples where possible:
- frames to ~90° heading change;
- normalized path curvature / turn radius;
- approximate yaw-rate envelope;
- overshoot / correction behavior;
- camera anticipation / settle.

### R3 — Steering reversal / slalom
Record:
- frames from reversal input/visible steering commitment to opposite yaw response;
- heading recovery / settle time;
- correction burden;
- camera look-ahead reversal behavior.

### R4 — Handbrake / high-slip recovery
Record:
- slide onset timing;
- approximate heading-vs-travel divergence;
- rotation envelope;
- recovery/settle time;
- retained momentum ratio where footage supports it;
- camera stability during rotation.

### R5 — Collision pair
Record representative:
- glancing impact;
- near-head-on / hard impact.

Measure:
- retained screen-space speed ratio;
- orientation disturbance;
- recovery time;
- camera response.

### R6 — Forward / reverse transition
Record:
- braking-to-stop timing;
- transition delay before visible reverse;
- reverse response;
- return-to-forward timing;
- camera look-ahead zero crossing.

### R7 — Pursuit route correction
Record one short chase with a corner / obstacle / route choice:
- route correction frequency;
- pursuer line choice;
- camera readability under pressure;
- collision / correction burden;
- recovery after mistakes.

---

## Measurement units

Prefer:
- frames and seconds;
- normalized screen fractions;
- vehicle lengths;
- ratios of before/after screen-space velocity;
- approximate heading delta per frame;
- relative visible scale/FOV change in percent.

Avoid converting uncertain footage into world-space constants.

---

## ECHOES baseline provenance

The initial Wave 1 behavior baseline is captured by:

```bash
godot --headless --path godot \
  --script res://scripts/verification/ctw_feel_harness.gd -- \
  --run-ctw-feel-baseline \
  --feel-build-commit=<exact-tested-sha>
```

Windowed sanity pass:

```bash
godot --path godot \
  --script res://scripts/verification/ctw_feel_harness.gd -- \
  --run-ctw-feel-baseline \
  --feel-build-commit=<exact-tested-sha>
```

Generated local evidence:
- `baseline_summary.json`
- `baseline_E1_launch_coast_brake_trace.json`
- `baseline_E2_constant_90_turn_trace.json`
- `baseline_E3_steering_reversal_trace.json`
- `baseline_E4_handbrake_recovery_trace.json`
- `baseline_E5_collision_pair_trace.json`
- `baseline_E6_forward_reverse_trace.json`
- `baseline_E7_pursuit_route_trace.json`
- `baseline_verification.log`

These generated measurements must come from actual Godot execution. Do not hand-author numeric baseline results.
