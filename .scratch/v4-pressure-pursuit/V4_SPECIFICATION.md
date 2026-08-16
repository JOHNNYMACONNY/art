# V4 Specification — Pressure & Pursuit Slice

**Project:** Echos in the Scrap  
**Repository:** JOHNNYMACONNY/art  
**Target:** Godot 4.7.1 GDScript 3D (Mobile-First / WebGL2 Compatibility Safe)  

---

## 1. Objective

Prove that the existing on-foot interaction loop and courier bike driving mechanics remain readable, responsive, and satisfying when placed under environmental threat and pursuit pressure.

---

## 2. Pursuit Loop State Machine

```
CALM (free exploration, panel & tuner interactable)
  │
  ├─> [ CORE EXTRACTED ] (triggers disturbance alert)
  ▼
DISTURBANCE_ALERT (siren chime, red lighting accent, 0.5s transition)
  │
  ▼
PURSUIT_ACTIVE (PursuerPrototype pursues player at 11 m/s, pursuit UI active)
  │
  ├─> [ DISTANCE > 18m for 3.0s ]
  ▼
CONTACT_BROKEN (pursuit music fades, 2.0s decay timer)
  │
  ▼
EVADED (returns to CALM state, free exploration restored)
```

---

## 3. Threat Entity (`PursuerPrototype`)

- **Class**: `PursuerPrototype` extending `CharacterBody3D`.
- **Speed**: Max 11.0 m/s (faster than foot runner 6 m/s, slower than bike top speed 14 m/s, forcing bike escape).
- **Steering**: Direct vector pursuit toward active target (player or bike).
- **Visuals**: Dark mechanical chassis mesh with pulsing red siren accent.

---

## 4. Tension & Audio Signals

- **Spatial Alarm Siren**: `SIREN_ALARM` spatial audio event looping during active pursuit.
- **World Lighting Tension**: Ambient light shifts from neutral warm brown to cold industrial red (`Color(0.4, 0.1, 0.1)`).
- **Mobile HUD Tension Indicator**: `[ ALERT: PURSUER PROXIMITY ]` distance readout label.

---

## 5. Scope Exclusions (Strict V4 Boundaries)

- NO player weapons or combat system
- NO full police wanted / heat system
- NO multiple pursuer types or NPC pedestrians
- NO vehicle damage system
- NO quest / mission framework
