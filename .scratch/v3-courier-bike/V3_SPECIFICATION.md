# V3 Specification — Courier Bike Vehicle Feel Slice

**Project:** Echos in the Scrap  
**Repository:** JOHNNYMACONNY/art  
**Target:** Godot 4.7.1 GDScript 3D (Mobile-First / WebGL2 Compatibility Safe)  

---

## 1. Objective

Deliver a high-feel, tactile mobile courier bike driving prototype that seamlessly integrates with the existing on-foot locomotion and interaction systems. The slice proves that driving through compact scrap geometry feels as responsive, readable, and satisfying on a mobile touchscreen as the on-foot controls.

---

## 2. Vehicle State Machine

```
PARKED (unoccupied, interactable mount prompt)
  │
  ├─> [ MOUNT BIKE ] (player in range <= 2.5m, tap action)
  ▼
MOUNTING (0.25s transition, input locked, player avatar attaches to bike pivot)
  │
  ▼
DRIVING (mobile UI switches to steering joystick + throttle/brake, speed responsive)
  │
  ├─> [ DISMOUNT ] (speed <= 1.5 m/s, tap action)
  ▼
DISMOUNTING (0.25s transition, player unbinds to collision-safe offset, foot controls restored)
  │
  ▼
PARKED
```

---

## 3. Mobile Driving Control Layout

- **Left Touch Area**: Left-thumb analog joystick driving steering angle (`-1.0 .. +1.0`).
- **Right Touch Area**:
  - `THROTTLE` button (accelerate forward, max speed 14 m/s).
  - `BRAKE / REVERSE` button (decelerate / reverse).
  - `DISMOUNT` button (active when bike speed <= 1.5 m/s).

---

## 4. Camera & Visual Identity

- **Chinatown Perspective Camera**: 3/4 low-FOV top-down camera tracks bike position.
- **Dynamic Speed FOV**: Blends from 32° (traversal) up to 38° at maximum speed (14 m/s) with 0.3s damping.
- **Graphic Inverted-Hull Outlines**: Inverted-hull dark contour mesh on courier bike when targeted / active.
- **Scrap Driving Track**: Open scrap lane, narrow cornering channel, ramp/elevation step.

---

## 5. Audio Mix

- **Engine Hum / Rev**: Pitch scales dynamically from 0.8 (idle) up to 2.2 at top speed.
- **Brake Screech**: Noise stream triggered on hard braking at speed > 5 m/s.
- **Mount/Dismount Transient**: Spatial click sound emitted at bike position.

---

## 6. Scope Exclusions (Strict V3 Boundaries)

- NO police or heat/wanted system
- NO enemy AI or NPC pedestrians
- NO combat or weapons
- NO traffic vehicles
- NO vehicle damage system
- NO multiple vehicles or vehicle customization
- NO quest/mission framework
