# V7 TICKET 06 TICKETS: AUDIO PRESSURE, SEMANTIC FEEDBACK & REPLAY COHESION

## TICKET 06.1 — Audio Semantic & Lifecycle Foundation
- **Target Files**:
  - `godot/scripts/audio/audio_manager.gd`
  - `godot/scripts/prototype/scrap_test_block.gd`
- **Scope**:
  - True frequency sweep synthesis `_create_sweep_wav(start_f, end_f, duration)`.
  - Expanded `SoundEvent` enum with `DISMOUNT_REJECTED`, `DISTURBANCE_ALERT`, `PURSUIT_INTERCEPTED`, `EVASION_RELEASE`, `COLLISION_GLANCE`, `COLLISION_HEAD_ON`.
  - Authoritative `reset_audio_instant()` lifecycle method.
  - Manager-owned transient player registry and throttling (max 8 concurrent voices, 0.05s general event cooldown).
  - Update `scrap_test_block.gd` interaction and pursuit call-sites to dispatch dedicated semantic events and call `reset_audio_instant()`.
- **Verification**: `--run-v7-ticket06-1-assertions`.

---

## TICKET 06.2 — Pursuit Pressure Mix
- **Target Files**:
  - `godot/scripts/audio/audio_manager.gd`
  - `godot/scripts/prototype/scrap_test_block.gd`
- **Scope**:
  - `set_pursuit_pressure(distance, pursuer_pos)` implementation.
  - Mobile-legible harmonic tension layer (`_tension_player`) with 120Hz + 240Hz dual tone loop.
  - Distance scaling ($d=20\text{m} \to P=0.0$, $d=5\text{m} \to P=1.0$).
  - Pressure hysteresis: engage below 14m, disengage above 18m.
  - Hook controller pursuit loop to update pressure continuously.
- **Verification**: `--run-v7-ticket06-2-assertions`.

---

## TICKET 06.3 — Collision Audio Feedback
- **Target Files**:
  - `godot/scripts/vehicles/courier_bike.gd`
  - `godot/scripts/audio/audio_manager.gd`
  - `godot/scripts/prototype/scrap_test_block.gd`
- **Scope**:
  - Add `collision_contact(head_on_ratio, impact_speed, collision_pos)` signal to `courier_bike.gd` (zero physics modifications).
  - Connect signal in `scrap_test_block.gd` to `audio_mgr.on_collision_contact()`.
  - Map `head_on_ratio < 0.35` to `COLLISION_GLANCE` and `head_on_ratio >= 0.35` to `COLLISION_HEAD_ON`.
  - Enforce collision sound throttling (minimum 0.15s cooldown between collision voices).
- **Verification**: `--run-v7-ticket06-3-assertions` & full 17-suite regression.
