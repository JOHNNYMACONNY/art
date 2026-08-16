# V7 TICKET 05 SPECIFICATION: GTA/CHINATOWN WARS CAMERA TRANSITION, LOOK-AHEAD & FRAMING (REVISED)

**Status**: APPROVED / IMPLEMENTING  
**Target Subsystem**: `godot/scripts/camera/camera_3d.gd` (`ChinatownCamera3D`)  
**Target Build**: `main@5c931ef`  

---

## 1. GOAL & CONTEXT

Deliver an elevated 3/4 top-down camera system faithful to *Grand Theft Auto: Chinatown Wars* and arcade top-down action driving that provides:
- Stable, readable, and predictable spatial orientation during foot traversal, vehicle mounting/dismounting, high-speed slaloms, handbrake powerslides, pursuit evasion, and contextual tuning interactions.
- Frame-rate independent filtering (60Hz/120Hz invariant) eliminating orientation snapping, look-at jitter, FOV pumping, and whip-around disorientation.

---

## 2. OBSERVABLE PLAYER CONTRACTS (INVARIANTS)

1. **Orientation Continuity Invariant**: Target switching (Runner ↔ Bike ↔ Interaction Node) must never induce single-frame position or look-at direction steps. Camera focus point transitions continuously.
2. **Velocity Anticipation Without Whiplash**: Camera anticipates travel direction by projecting a look-ahead lead proportional to velocity, but filters rapid directional reversals (e.g. 180° handbrake turn, forward-to-reverse crossing) through smooth exponential decay rather than raw frame-to-frame tracking.
3. **Drift Stability / Decoupled Yaw**: Sharp vehicle yaw rotation (e.g. powersliding or donuts) must not whip the camera. The camera rig maintains its elevated 3/4 isometric angle (`Vector3(12, 18, 12)`) and tracks vehicle linear displacement, not vehicle yaw.
4. **Dynamic Speed Framing (Speed Breathing)**: FOV smoothly expands from `32.0°` at rest / foot traversal up to `38.0°` at top speed (`14.0 m/s`), expanding peripheral road visibility without rapid FOV pumping during gear shifts or brief brake taps.
5. **Mount / Dismount Seamlessness**: Entering or exiting the Courier Bike feels like a continuous focus shift rather than an abrupt camera cut.
6. **Contextual Interaction Focus**: Entering Signal Tuner or panel interaction gently frames the interactable object and tightens FOV to `27.2°` (`default_fov * 0.85`), returning smoothly to player focus upon interaction completion.
7. **Lag-Free Responsiveness**: Camera tracking is visibly responsive and never feels detached from vehicle input. Follow error is bounded and telemetry tracked.
8. **Chinatown Wars Perspective Rigidity**: The camera viewing vector maintains fixed isometric orientation (`camera_position = framing_center + offset`, `look_target = framing_center + fixed_height`) to preserve the game's stylized visual depth.
9. **Authoritative Instant Reset**: `reset_camera_instant(target)` clears interaction modes, resets smoothed positions/look-aheads, restores default FOV, and sets the instant camera pose without residual drift.

---

## 3. ARCHITECTURE & PIPELINE DATA FLOW

```
[Gameplay Target (Runner / Bike) OR Interaction Target]
                       │
                       ▼
┌────────────────────────────────────────────────────────┐
│ Stage 1: Focus Target Solver                           │
│ Determine raw target position & raw target velocity    │
└────────────────────────────────────────────────────────┘
                       │
                       ▼
┌────────────────────────────────────────────────────────┐
│ Stage 2: Focus Smoothing                               │
│ Exponential damping on focus position (rate = 5.0 s⁻¹) │
└────────────────────────────────────────────────────────┘
                       │
                       ├──────── Target Velocity
                       │               │
                       │               ▼
                       │    ┌──────────────────────────────────────────┐
                       │    │ Stage 3: Look-Ahead Solver               │
                       │    │ Dual-rate filtered velocity lead         │
                       │    │ (attack = 3.5 s⁻¹, reversal = 7.0 s⁻¹)   │
                       │    └──────────────────────────────────────────┘
                       │               │
                       └───────┬───────┘
                               ▼
                        FRAMING CENTER
                               │
             ┌─────────────────┴─────────────────┐
             ▼                                   ▼
      camera_position                       look_target
    = framing_center + offset          = framing_center + Vector3(0, 0.5, 0)
             │                                   │
             └─────────────────┬─────────────────┘
                               ▼
                        FIXED 3/4 BASIS
```

### FOV Channel:
- Filtered independently from speed and interaction context:
  - Target FOV: $32.0^\circ + 6.0^\circ \cdot \text{clamp}(\|v\| / 14.0, 0, 1)$ (or $27.2^\circ$ in interaction mode).
  - Exponential damping rate: $3.0\text{ s}^{-1}$ (or $4.0\text{ s}^{-1}$ in interaction mode).

---

## 4. MATHEMATICAL SPECIFICATIONS

### A. Frame-Rate Independent Exponential Damping
$$\text{val}_{t+1} = \text{val}_t + (\text{target} - \text{val}_t) \cdot (1.0 - e^{-\text{rate} \cdot \Delta t})$$

### B. Dual-Rate Velocity Look-Ahead
1. Target Lead:
   $$\vec{L}_{\text{target}} = \begin{cases} \hat{v} \cdot \min(\|v\| \cdot 0.18,\, 3.0) & \text{if } \|v\| > 0.2 \\ \vec{0} & \text{otherwise} \end{cases}$$
2. Transition Rate Selection:
   - If $\vec{L}_{\text{target}} \cdot \vec{L}_{\text{current}} < 0$ (velocity reversal / sharp turn): $\text{rate} = 7.0\text{ s}^{-1}$.
   - Otherwise (smooth expansion / tracking): $\text{rate} = 3.5\text{ s}^{-1}$.

### C. Authoritative Camera Reset
```gdscript
func reset_camera_instant(target: Node3D) -> void:
    target_node = target
    _is_interaction_mode = false
    _interaction_target = null
    fov = default_fov
    if target:
        _smoothed_focus_pos = target.global_position
    else:
        _smoothed_focus_pos = Vector3.ZERO
    _smoothed_look_ahead = Vector3.ZERO
    var framing_center := _smoothed_focus_pos
    global_position = framing_center + _camera_offset
    look_at(framing_center + Vector3(0, 0.5, 0))
```

---

## 5. AUTOMATED VERIFICATION SUITE (`--run-v7-ticket05-assertions`)

1. `TARGET_SWITCH_NO_INSTANT_TRANSFORM_CHANGE`: Calling `set_target()` on distant node changes camera transform by exactly 0 on call frame, and initiates continuous glide.
2. `MOUNT_DISMOUNT_CONTINUITY`: Mount and dismount transitions produce monotonic focus convergence with 0 orientation jumps.
3. `HANDBRAKE_180_LOOKAHEAD_REVERSAL`: 180° velocity flip at 14 m/s collapses look-ahead smoothly without overshoot.
4. `VEHICLE_YAW_CAMERA_ORIENTATION_DECOUPLING`: Full vehicle yaw rotation (drifting / donut) leaves camera basis unchanged within numerical tolerance.
5. `FOV_BOUNDS_AND_MONOTONIC_RESPONSE`: FOV strictly bounded between `27.2°` and `38.0°` without pumping or oscillation.
6. `INTERACTION_FOCUS_ENTER_EXIT`: Entering interaction mode smoothly glides focus to panel and tightens FOV; exiting returns smoothly to player.
7. `60HZ_120HZ_EQUIVALENCE`: Deterministic synthetic movement under 60Hz and 120Hz converges to within `< 0.05m`.
8. `FOLLOW_ERROR_BOUND_TELEMETRY`: Steady-state follow error at 14 m/s is logged and verified bounded ($< 3.2\text{m}$).
9. `RESET_CAMERA_INSTANT_FULL_STATE_CLEAR`: Calling `reset_camera_instant()` clears all interaction state, zeroes look-ahead, snaps position, and sets FOV to 32.0°.
10. `FORWARD_REVERSE_LOOKAHEAD_ZERO_CROSSING`: Transitioning from forward to reverse decelerates look-ahead smoothly through zero.
