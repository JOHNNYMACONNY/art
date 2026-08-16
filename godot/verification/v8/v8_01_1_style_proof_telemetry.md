# V8 01.1B HARDENED MODULAR KIT RENDERING & TELEMETRY REPORT

**Measured At Branch**: `main`  
**Timestamp**: 2026-08-16T14:08 PDT  
**Engine**: Godot 4.7.1 Stable (Official)  
**Hardware / Device**: Apple M4 (Metal 4.0 Forward+)  
**Command**: `godot --path godot/ -- ++ --run-v8-telemetry`  
**Sample Window**: 120 frames steady-state runtime  

---

## 1. TELEMETRY COMPARISON (960 × 540 Viewport, Forward+)

| Metric | V7 Baseline | V8 Style Proof (Initial) | V8 Phase B (Initial) | V8 01.1B Hardened | Total Delta vs V7 Base |
|---|---|---|---|---|---|
| **Total Draw Calls (Frame)** | 68 | 106 | 120 | **120** | +52 (All 6 archetypes staged) |
| **Primitives / Triangles** | 59,410 | 64,498 | 81,542 | **61,690** | **+2,280** (Dropped 19,852 tris) |
| **Total Objects in Frame** | 75 | 126 | 144 | **144** | +69 |
| **Average Frame Time** | 16.46 ms (60.8 FPS) | 16.39 ms (61.0 FPS) | 16.44 ms (60.8 FPS) | **16.39 ms (61.0 FPS)** | 0.0 ms |
| **P95 Frame Time** | 17.20 ms | 17.37 ms | 17.14 ms | **17.23 ms** | +0.03 ms |
| **Performance Status** | Base | Stable | Stable | **DEV CADENCE: STABLE \| DRAW SCALING: MEASURED \| REAL MOBILE: UNKNOWN** | — |

---

## 2. REPO TRUTH: 6-ARCHETYPE MODULAR SCRAP KIT

| Archetype Prop | Path | Key Silhouettes & Composition | MeshInstance3D Count | Collision |
|---|---|---|---|---|
| **Scrap Pile A** | `res://scenes/props/scrap_pile_a.tscn` | Crushed chassis base, slanted bent plate, hollow torus wheel rim (`rings=16, segs=10`), rusted axle pipe (`radial=8`) | 4 | None (Visual Only) |
| **Scrap Pile B** | `res://scenes/props/scrap_pile_b.tscn` | Heavy engine block mass, crushed fuel drum/barrel (`radial=10`), angled steel I-beam girder | 3 | None (Visual Only) |
| **Salvage Container** | `res://scenes/props/salvage_container.tscn` | Directional corrugated ribs (`mat_corrugated_metal`), front/back structural frames, roof rails | 5 | None (Visual Only) |
| **Pipe Rack Modular** | `res://scenes/props/pipe_rack_modular.tscn` | Dual steel stanchions, horizontal crossbar, dual industrial rusted pipes (`radial=8`) | 5 | None (Visual Only) |
| **Corrugated Fence** | `res://scenes/props/corrugated_fence.tscn` | Steel fence posts, directional corrugated sheet panel, top angle cap | 4 | None (Visual Only) |
| **Ground Debris Flat** | `res://scenes/props/ground_debris_flat.tscn` | Irregular 7-sided organic heptagon oil stain decal (`cast_shadow=0`), scattered scrap flakes | 3 | None (Visual Only) |

---

## 3. VISUAL ASSETS CAPTURED
- `res://verification/v8/v8_proof_01_cold_start.png`: Cold Start staging with Player avatar, Courier Bike, corrugated container with corner framing, refined scrap pile A with hollow torus wheel rim, and organic heptagon oil stain decal.
- `res://verification/v8/v8_proof_02_tuner_approach.png`: Tuner Outpost approach with glowing amber dial framed against Scrap Pile B (engine block, crushed drum, angled girder) and ground grime.
- `res://verification/v8/v8_proof_03_modular_kit_lineup.png`: Modular kit lineup at Staging Pad showing pipe rack, corrugated fence, courier bike, and player.
