# Vehicle Handling Archetype Reference (GTA Lineage)

Mathematical baselines extracted from GTA III / VC / SA handling data (`handling.cfg`). Use these parameters to tune and anchor Godot vehicle resources (`godot/scripts/vehicle/`).

## Parameter Definitions
- `mass`: Vehicle weight (kg). Determines collision momentum against walls and cops.
- `drag_mult`: Air resistance factor. Governs top-speed deceleration curve.
- `traction_mult`: Grip factor. Higher = rail steering; Lower = arcade drift.
- `traction_loss`: Grip loss during sharp turns / handbrake. Controls drift initiation.
- `traction_bias`: Front/rear grip ratio (0.5 = neutral, 0.45 = rear drift slip).
- `engine_accel`: Forward force (m/s^2).
- `max_velocity`: Linear top speed cap.
- `suspension_force`: Spring stiffness. Prevents bottoming out on curb impacts.
- `suspension_damping`: Shock absorber decay. Eliminates infinite bounce.

---

## 1. Courier Bike (Light, High-Agility, High-Drift)
Matches FB-13 Mission 01 Courier Bike profile.

| Parameter | Value |
|---|---|
| Mass | 450.0 kg |
| Drag Multiplier | 1.8 |
| Traction Multiplier | 1.15 |
| Traction Loss | 0.85 |
| Traction Bias | 0.46 |
| Engine Acceleration | 32.0 m/s² |
| Max Velocity | 48.0 m/s |
| Turn Mass | 320.0 |

---

## 2. Scrap Hauler (Heavy, High-Inertia, Low-Drift Battering Ram)
Matches FB-13 Mission 02 Scrap Hauler profile.

| Parameter | Value |
|---|---|
| Mass | 2800.0 kg |
| Drag Multiplier | 2.5 |
| Traction Multiplier | 0.88 |
| Traction Loss | 0.65 |
| Traction Bias | 0.50 |
| Engine Acceleration | 14.0 m/s² |
| Max Velocity | 32.0 m/s |
| Turn Mass | 3100.0 |

---

## 3. Patrol Interceptor / Cop Cruiser (Aggressive Rammer, High Acceleration)
Matches pursuit chase AI profile.

| Parameter | Value |
|---|---|
| Mass | 1600.0 kg |
| Drag Multiplier | 2.0 |
| Traction Multiplier | 1.05 |
| Traction Loss | 0.80 |
| Traction Bias | 0.49 |
| Engine Acceleration | 26.0 m/s² |
| Max Velocity | 46.0 m/s |
| Turn Mass | 1800.0 |
