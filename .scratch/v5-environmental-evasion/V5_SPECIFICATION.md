# V5 Specification — Environmental Evasion / Scrap Route Switch

**Project:** Echos in the Scrap  
**Repository:** JOHNNYMACONNY/art  
**Target:** Godot 4.7.1 GDScript 3D (Mobile-First / WebGL2 Compatibility Safe)  

---

## 1. Objective

Provide meaningful environmental player counterplay during pursuit without adding weapons or combat systems. The player uses a signal-driven scrap route gate switch to alter chase geometry and gain separation.

---

## 2. Environmental Counterplay Mechanics

```
PURSUIT_ACTIVE (Pursuer follows player/bike down main lane)
  │
  ├─> [ REACH SIGNAL GATE AT z=12.0 ]
  ▼
RAPID_GATE_INTERACTION (0.75s quick signal tap / pulse)
  │
  ▼
GATE_TRIGGERED (Scrap barrier slams across main lane, opens shortcut)
  │
  ▼
PURSUER_REROUTED (Pursuer must take long detour, player gains +25m separation)
  │
  ▼
CLEAN_ESCAPE (Distance > 18.0m triggers CONTACT_BROKEN -> EVADED)
```

---

## 3. Signal Gate Entity (`SignalGate`)

- **Class**: `SignalGateInteractable` extending `InteractableBase`.
- **Location**: `Vector3(-1.5, 0.5, 12.0)` on scrap driving track.
- **Visuals**: Scrap mechanical gate frame with red/cyan signal light accent and rotating barrier arm.

---

## 4. Scope Exclusions (Strict V5 Boundaries)

- NO player weapons or stun guns
- NO damage or health systems
- NO multiple pursuers
- NO inventory items
- NO permanent path blocking (pursuer reroutes cleanly)
