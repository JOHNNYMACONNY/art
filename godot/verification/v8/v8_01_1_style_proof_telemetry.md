# V8 01.1 PHASE B MODULAR KIT RENDERING & TELEMETRY REPORT

**Measured At Branch**: `main`  
**Timestamp**: 2026-08-16T14:03 PDT  
**Engine**: Godot 4.7.1 Stable (Official)  
**Hardware / Device**: Apple M4 (Metal 4.0 Forward+)  
**Command**: `godot --path godot/ -- ++ --run-v8-telemetry`  
**Sample Window**: 120 frames steady-state runtime  

---

## 1. TELEMETRY COMPARISON (960 × 540 Viewport, Forward+)

| Metric | V7 Baseline | V8 Style Proof (Initial) | V8 Style Proof (Refined) | V8 01.1 Phase B (Full 6-Kit) | Total Delta vs V7 Base |
|---|---|---|---|---|---|
| **Total Draw Calls (Frame)** | 68 | 106 | 100 | **120** | +52 |
| **Primitives / Triangles** | 59,410 | 64,498 | 69,002 | **81,542** | +22,132 |
| **Total Objects in Frame** | 75 | 126 | 120 | **144** | +69 |
| **Average Frame Time** | 16.46 ms (60.8 FPS) | 16.39 ms (61.0 FPS) | 16.45 ms (60.8 FPS) | **16.44 ms (60.8 FPS)** | 0.0 ms |
| **P95 Frame Time** | 17.20 ms | 17.37 ms | 17.32 ms | **17.14 ms** | -0.06 ms |
| **Performance Status** | Base | Stable | Stable | **DEV CADENCE: STABLE \| DRAW SCALING: MEASURED \| REAL MOBILE: UNKNOWN** | — |

---

## 2. FULL 6-ARCHETYPE MODULAR SCRAP KIT

| Archetype Prop | Path | Key Silhouettes & Materials | Node Count | Collision |
|---|---|---|---|---|
| **Scrap Pile A** | `res://scenes/props/scrap_pile_a.tscn` | Crushed chassis core, slanted bent plate, hollow torus wheel rim, rusted axle pipe | 4 | None (Visual Only) |
| **Scrap Pile B** | `res://scenes/props/scrap_pile_b.tscn` | Engine block mass, crushed fuel drum/barrel, angled steel I-beam girder | 3 | None (Visual Only) |
| **Salvage Container** | `res://scenes/props/salvage_container.tscn` | Directional corrugated ribs, reinforced end frames, longitudinal roof rails | 3 | None (Visual Only) |
| **Pipe Rack Modular** | `res://scenes/props/pipe_rack_modular.tscn` | Dual steel stanchions, horizontal crossbar, dual industrial rusted pipes | 4 | None (Visual Only) |
| **Corrugated Fence** | `res://scenes/props/corrugated_fence.tscn` | Steel fence posts, directional corrugated sheet panel, top angle cap | 3 | None (Visual Only) |
| **Ground Debris Flat** | `res://scenes/props/ground_debris_flat.tscn` | Irregular noise-masked oil/grime decal, scattered scrap flakes (`cast_shadow = 0`) | 3 | None (Visual Only) |

---

## 3. VISUAL ASSETS CAPTURED
- `res://verification/v8/v8_proof_01_cold_start.png`: Cold Start staging with Player avatar, Courier Bike, corrugated container with corner framing, refined scrap pile with wheel rim/axle, and irregular ground grime decals.
- `res://verification/v8/v8_proof_02_tuner_approach.png`: Tuner Outpost approach with glowing amber dial framed against the organic scrap pile B with engine block and crushed barrel.
- `res://verification/v8/v8_proof_03_modular_kit_lineup.png`: Modular kit lineup at Staging Pad showing pipe rack, corrugated fence, courier bike, and player.
