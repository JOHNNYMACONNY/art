# V7 TICKET 06 SPECIFICATION: AUDIO PRESSURE, SEMANTIC FEEDBACK & REPLAY COHESION (REVISED)

**Status**: APPROVED / SPEC-LOCKED  
**Target Subsystems**:
- `godot/scripts/audio/audio_manager.gd` (`AudioManager`)
- `godot/scripts/prototype/scrap_test_block.gd` (`ScrapTestBlock`)
- `godot/scripts/vehicles/courier_bike.gd` (`CourierBike` - neutral telemetry signal only)
**Target Build**: `main@3fd0ec2`  

---

## 1. GOAL & CONTEXT

Deliver an expressive, legible, and leak-proof audio environment where the player understands danger, vehicle traction/speed, interaction progress, rejection, and resolution purely by ear:
- 3-tier perceptual hierarchy ensuring critical signals cut cleanly over continuous state and secondary SFX.
- Continuous pursuit pressure with distance modulation and mobile-legible harmonic tension layer.
- Unambiguous semantic event separation (dedicated dismount rejection, disturbance alarm, pursuit interception, evasion release, glance vs head-on collisions).
- Truthful procedural frequency sweep synthesis replacing static single-frequency tones.
- Authoritative `reset_audio_instant()` lifecycle manager ensuring 100% leak-proof replay.

---

## 2. 3-TIER PERCEPTUAL HIERARCHY

1. **Tier 1 (CRITICAL)**: Always cuts through and remains intelligible:
   - `DISTURBANCE_ALERT`: Initial pursuit alert / alarm onset.
   - `PURSUIT_INTERCEPTED`: Caught by pursuer.
   - `DISMOUNT_REJECTED`: High-speed dismount denial (low-frequency dual-tone).
   - `COLLISION_HEAD_ON`: Heavy metallic collision crunch.
   - `SIGNAL_LOCK`: Signal tuned & locked harmonic chime.
   - `COMPLETION`: Core extracted resolution chime.
   - `GATE_SLAM`: Solid scrap barrier impact slam.
2. **Tier 2 (CONTINUOUS STATE)**: Modulated smoothly without abrupt start/stop:
   - `ENGINE_REV`: Bike throttle/speed-proportional engine revs.
   - `SIREN_ALARM`: Spatial pursuer siren (pitch & volume scaled by proximity).
   - `PURSUIT_TENSION_DRONE`: Mobile-legible harmonic tension layer active during close pursuit ($d < 15\text{m}$).
   - `PROXIMITY_HUM`: Corroded panel near-lock hum.
   - `STATIC_NOISE`: Contextual tuning static noise (attenuates as accuracy rises).
3. **Tier 3 (SECONDARY)**: Ambient and tactile feedback:
   - `FOOTSTEP`: Player walking clicks.
   - `BIKE_MOUNT` / `BIKE_DISMOUNT`: Tactile mounting clicks.
   - `COLLISION_GLANCE`: High-frequency abrasive glancing contact.
   - `PANEL_PEEL`: Physical panel drag pitch rise (1.15x to 1.30x).

---

## 3. SEMANTIC EVENT CORRECTIONS & API EXPANSIONS

### SoundEvent Enum:
```gdscript
enum SoundEvent {
	FOOTSTEP,
	PROXIMITY_HUM,
	PANEL_PEEL,
	CORE_PULL,
	SPARK,
	COMPLETION,
	SIGNAL_LOCK,
	PANEL_POWERED,
	ENGINE_REV,
	BRAKE_SCREECH,
	BIKE_MOUNT,
	BIKE_DISMOUNT,
	SIREN_ALARM,
	GATE_SLAM,
	DISMOUNT_REJECTED,
	DISTURBANCE_ALERT,
	PURSUIT_INTERCEPTED,
	EVASION_RELEASE,
	COLLISION_GLANCE,
	COLLISION_HEAD_ON
}
```

### True Procedural Sweep Synthesis:
`_create_sweep_wav(start_f: float, end_f: float, duration: float, volume: float = 0.4) -> AudioStreamWAV`:
Generates linear/exponential frequency sweep:
$$f(t) = f_{\text{start}} + (f_{\text{end}} - f_{\text{start}}) \cdot \frac{t}{T}$$
$$\phi(t) = 2\pi \int_0^t f(\tau) d\tau = 2\pi \left( f_{\text{start}} t + \frac{f_{\text{end}} - f_{\text{start}}}{2T} t^2 \right)$$

### Continuous Pursuit Pressure API:
`set_pursuit_pressure(distance: float, pursuer_pos: Vector3)`:
- Computes normalized pressure $P = \text{clamp}\left(\frac{20.0 - \text{distance}}{15.0},\, 0.0,\, 1.0\right)$.
- Siren pitch modulated: `lerpf(1.0, 1.45, P)`.
- Tension drone volume: `-30.0 dB` up to `-8.0 dB`.
- Hysteresis: Engages tension layer when $d < 14\text{m}$, disengages when $d > 18\text{m}$.

### Neutral CourierBike Collision Telemetry:
In `courier_bike.gd`:
```gdscript
signal collision_contact(head_on_ratio: float, impact_speed: float, collision_pos: Vector3)
```
In `audio_manager.gd`:
- `head_on_ratio < 0.35`: `COLLISION_GLANCE` (high abrasive scrape).
- `head_on_ratio >= 0.35` and `impact_speed > 3.0`: `COLLISION_HEAD_ON` (deep metallic crunch).
- Cooldown throttle: Minimum 0.15s between collision voices.

### Authoritative Instant Reset API:
`reset_audio_instant()`:
- Stops all continuous streams (`_engine_player`, `_hum_player`, `_siren_player`, `_static_player`, `_tension_player`).
- Retires and frees all transient audio players in `_active_transients` registry.
- Resets pitch scales, volume gains, and cooldown timers.
- Restores `current_mix_state = MixState.CALM`.

---

## 4. TICKET BREAKDOWN (POCOCK /to-tickets)

- **V7 Ticket 06.1**: Audio Semantic & Lifecycle Foundation (Sweep synthesis, transient voice registry/throttling, semantic event corrections, `reset_audio_instant`).
- **V7 Ticket 06.2**: Pursuit Pressure Mix (`set_pursuit_pressure`, tension harmonic layer, siren modulation, distance mapping with hysteresis).
- **V7 Ticket 06.3**: Collision Audio Feedback (neutral `courier_bike.gd` telemetry signal, glance/moderate/head-on classification, scrape throttling).

---

## 5. ACCEPTANCE ASSERTIONS (`--run-v7-ticket06-assertions`)

1. `SEMANTIC_EVENT_ROUTING`: Rejection, disturbance, interception, and evasion dispatch dedicated semantic events without SPARK/SIGNAL_LOCK collisions.
2. `PURSUIT_PRESSURE_DISTANCE_RESPONSE`: Proximity maps monotonically to pressure ($d = 20\text{m} \to P=0.0$, $d = 5\text{m} \to P=1.0$) with no threshold chatter.
3. `COLLISION_SEVERITY_MAPPING`: Low head-on ratio triggers `COLLISION_GLANCE`; high head-on ratio triggers `COLLISION_HEAD_ON`.
4. `COLLISION_VOICE_THROTTLING`: 50 rapid collision contacts in 1 second spawn $\le 6$ transient voice nodes.
5. `TUNING_STATIC_AND_NEAR_LOCK_LIFECYCLE`: Static volume drops continuously as accuracy increases; cancel/lock cleanses audio state cleanly.
6. `PEEL_TO_EXPOSE_PITCH_PROGRESSION`: Peel drag continuously rises 1.15 to 1.30; core expose triggers 1.50 step.
7. `PROCEDURAL_SWEEP_ACTUALLY_SWEEPS`: Verified non-zero sample frequency delta between start and end of generated sweep WAV buffer.
8. `TRANSIENT_VOICE_BUDGET`: Transient player registry caps active voices at $\le 8$ and frees on timeout.
9. `GATE_SLAM_SEMANTIC_TRIGGER`: Signal Gate trigger plays `GATE_SLAM` sweep.
10. `PURSUIT_INTERCEPT_AND_EVASION_SEMANTICS`: Interception triggers `PURSUIT_INTERCEPTED`; quiet aftermath triggers `EVASION_RELEASE`.
11. `RESET_AUDIO_INSTANT_FULL_SILENCE`: Calling `reset_audio_instant()` terminates all active players and zeroes transient registry.
12. `REPLAY_DURING_PURSUIT_AND_INTERACTION`: Calling slice reset during active pursuit or tuning leaves 0 playing streams or orphaned nodes.
