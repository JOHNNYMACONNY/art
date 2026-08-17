# Audio Archaeology Ledger — ECHOES

## Overview
This ledger records historical mechanical audio patterns, extraction dynamics, and environmental acoustic techniques analyzed for ECHOES.
It establishes semantic gameplay interpretations, estimated implementation costs, production risks, and tracking status.

**Security & Asset Policy**:
- Zero proprietary filenames, paths, or copyrighted binary assets are referenced or stored in the repository.
- All candidate mechanics default to procedural or bespoke synthesizers, with opt-in dev reference testing.
- Status values: `PROPOSED`, `ACCEPTED`, `IMPLEMENTED`, `REJECTED`.

---

## Master Archaeology Ledger Table

| REFERENCE_CATEGORY | IMPLIED_EVENT | IMPLIED_SYSTEM | PLAYER_VALUE | ECHOES_INTERPRETATION | COST | RISK | STATUS |
|---|---|---|---|---|---|---|---|
| **Reactive Radio Programming** | DJ station interrupted by emergency dispatch / signal fade in tunnel | Radio & World Broadcast Manager | Diegetic world responsiveness and environmental immersion | Radio station frequency drift when approaching high-interference Memory Echo zones or police jamming | Medium | Audio content licensing / voice synthesis budget | `PROPOSED` |
| **Vehicle Acoustic State & Load** | Engine RPM pitch climb, exhaust backfire on deceleration, gear shift click | Vehicle Audio Feedback Loop | Immediate speed, torque, and traction readability without glancing at UI | Courier Bike electric motor coil whine escalating with velocity; Scrap Hauler diesel rumble under load | Low | Continuous loop CPU budget on mobile | `PROPOSED` |
| **Surface-Driven Audio** | Tire sound transitions across asphalt, dirt, gravel, puddle, metal grates | Surface Material Telemetry | Spatial and tactical feedback on route traction and braking distance | Distinct slip/screech profiles across scrap metal plates vs loose dirt vs scrap yard oil slicks | Medium | Surface tagging physics queries | `PROPOSED` |
| **Modular Security Dispatch** | Police radio chatter reporting suspect location, grid code, vehicle type | Threat Escalation & Interception AI | Advance warning of incoming pursuer trajectory and encirclement tactics | Security drone synthesized radio bursts announcing sector containment and shortcut blockades | Medium | Radio voice line generation & mixing priority | `PROPOSED` |
| **Functional Industrial Machinery** | Heavy stamping press, gantry crane servo, metal shearing impacts | Yard Environment Life & Rhythm | Living, functional scrap yard ambience providing rhythm and stealth masking | Rhythmic industrial cycles that player can use to mask footstep/engine noise during extraction | Low | Mix clutter during high pursuit pressure | `PROPOSED` |
| **Neighborhood Acoustic Identity** | Distinct cultural, radio, and ambient backdrop changing across zones | Biome & Zone Ambient Controller | Strong sense of place and geographical progression across the map | Sector transition from industrial smelting hum to forgotten residential antenna static | Low | Asset variety requirement | `PROPOSED` |
| **Damage & Condition Acoustics** | Squeaking brakes, scraping chassis, misfiring engine on degraded vehicle | Vehicle Damage & Health State | Tactile warning of vehicle failure before catastrophic breakdown | Chassis rattle and scraping sparks scaling with remaining bike/hauler integrity | Low | Sound clutter when stacked with siren | `PROPOSED` |
| **Echo Detection & Interference** | Static white-noise wash, comb filtering, phantom voices near anomalies | Signal Tuner & Memory Extraction | Audiovisual treasure-hunting mechanic with clear spatial orientation | Directional heterodyne frequency beat that tightens and purifies near hidden memory caches | Low | Frequency clash with pursuit drone sirens | `PROPOSED` |
| **Physicality & Exertion** | Footstep scuffs, sprint breath, vault grunt, heavy landing thud | Player Avatar Locomotion | Kinetic weight, vulnerability, and physical presence in the world | Courier boots impacting rusted iron floors, exertion breathing during sprint stamina drain | Low | Transient voice budget starvation | `PROPOSED` |
| **Audio-Native UI Identity** | Tactile click, confirmation hum, mechanical dial switch feedback | UI & Menu Design System | Premium mechanical feel reinforcing salvage and hardware aesthetic | Analog cassette click on map open, tactile switch clicks on mobile touch controls | Low | Low risk | `PROPOSED` |

---

## Slot Inventory & Backlog Status

| Slot ID | Domain | Diegesis | Mix Group | Spatial Type | Status | Replacement Required |
|---|---|---|---|---|---|---|
| `player.footstep` | `PLAYER` | `DIEGETIC` | `INCIDENTAL_UI` | `DIEGETIC_3D` | `PROCEDURAL_FALLBACK` | Yes |
| `player.bike_mount` | `PLAYER` | `DIEGETIC` | `INCIDENTAL_UI` | `DIEGETIC_3D` | `PROCEDURAL_FALLBACK` | Yes |
| `player.bike_dismount` | `PLAYER` | `DIEGETIC` | `INCIDENTAL_UI` | `DIEGETIC_3D` | `PROCEDURAL_FALLBACK` | Yes |
| `player.dismount_rejected` | `PLAYER` | `NON_DIEGETIC` | `INCIDENTAL_UI` | `NON_DIEGETIC_2D` | `PROCEDURAL_FALLBACK` | No |
| `interaction.proximity_hum` | `INTERACTION` | `DIEGETIC` | `AMBIENT_TEXTURE` | `DIEGETIC_3D` | `PROCEDURAL_FALLBACK` | Yes |
| `interaction.panel_peel` | `INTERACTION` | `DIEGETIC` | `INCIDENTAL_UI` | `DIEGETIC_3D` | `PROCEDURAL_FALLBACK` | Yes |
| `interaction.core_pull` | `INTERACTION` | `DIEGETIC` | `INCIDENTAL_UI` | `DIEGETIC_3D` | `PROCEDURAL_FALLBACK` | Yes |
| `interaction.spark` | `INTERACTION` | `DIEGETIC` | `INCIDENTAL_UI` | `DIEGETIC_3D` | `PROCEDURAL_FALLBACK` | Yes |
| `interaction.completion` | `INTERACTION` | `HYBRID` | `INCIDENTAL_UI` | `DIEGETIC_3D` | `PROCEDURAL_FALLBACK` | Yes |
| `interaction.signal_lock` | `INTERACTION` | `HYBRID` | `INCIDENTAL_UI` | `DIEGETIC_3D` | `PROCEDURAL_FALLBACK` | Yes |
| `interaction.panel_powered` | `INTERACTION` | `DIEGETIC` | `INCIDENTAL_UI` | `DIEGETIC_3D` | `PROCEDURAL_FALLBACK` | Yes |
| `vehicle.engine_rev` | `VEHICLE` | `DIEGETIC` | `VEHICLE_FEEDBACK` | `DIEGETIC_3D` | `PROCEDURAL_FALLBACK` | Yes |
| `vehicle.brake_screech` | `VEHICLE` | `DIEGETIC` | `VEHICLE_FEEDBACK` | `DIEGETIC_3D` | `PROCEDURAL_FALLBACK` | Yes |
| `vehicle.collision_glance` | `VEHICLE` | `DIEGETIC` | `VEHICLE_FEEDBACK` | `DIEGETIC_3D` | `PROCEDURAL_FALLBACK` | Yes |
| `vehicle.collision_head_on` | `VEHICLE` | `DIEGETIC` | `VEHICLE_FEEDBACK` | `DIEGETIC_3D` | `PROCEDURAL_FALLBACK` | Yes |
| `pursuit.siren_alarm` | `PURSUIT` | `DIEGETIC` | `CRITICAL_THREAT` | `DIEGETIC_3D` | `PROCEDURAL_FALLBACK` | Yes |
| `pursuit.disturbance_alert` | `PURSUIT` | `HYBRID` | `CRITICAL_THREAT` | `DIEGETIC_3D` | `PROCEDURAL_FALLBACK` | Yes |
| `pursuit.intercepted` | `PURSUIT` | `HYBRID` | `CRITICAL_THREAT` | `DIEGETIC_3D` | `PROCEDURAL_FALLBACK` | Yes |
| `pursuit.gate_slam` | `PURSUIT` | `DIEGETIC` | `CRITICAL_THREAT` | `DIEGETIC_3D` | `PROCEDURAL_FALLBACK` | Yes |
| `pursuit.evasion_release` | `PURSUIT` | `NON_DIEGETIC` | `CRITICAL_THREAT` | `NON_DIEGETIC_2D` | `PROCEDURAL_FALLBACK` | Yes |
| `echo.onset` | `ECHO` | `NON_DIEGETIC` | `SIGNATURE_ECHO` | `NON_DIEGETIC_2D` | `PROCEDURAL_FALLBACK` | No |
| `echo.peak` | `ECHO` | `NON_DIEGETIC` | `SIGNATURE_ECHO` | `NON_DIEGETIC_2D` | `PROCEDURAL_FALLBACK` | No |
| `echo.tail` | `ECHO` | `NON_DIEGETIC` | `SIGNATURE_ECHO` | `NON_DIEGETIC_2D` | `PROCEDURAL_FALLBACK` | No |
| `world.ambient_work_clink` | `WORLD` | `DIEGETIC` | `AMBIENT_TEXTURE` | `DIEGETIC_3D` | `PROCEDURAL_FALLBACK` | Yes |
| `world.ambient_servo_hum` | `WORLD` | `DIEGETIC` | `AMBIENT_TEXTURE` | `DIEGETIC_3D` | `PROCEDURAL_FALLBACK` | Yes |

