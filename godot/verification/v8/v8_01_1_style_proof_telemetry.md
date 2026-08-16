# V8 01.1A REFINED STYLE PROOF RENDERING & TELEMETRY REPORT

**Measured At Branch**: `main`  
**Timestamp**: 2026-08-16T13:58 PDT  
**Engine**: Godot 4.7.1 Stable (Official)  
**Hardware / Device**: Apple M4 (Metal 4.0 Forward+)  
**Command**: `godot --path godot/ -- ++ --run-v8-telemetry`  
**Sample Window**: 120 frames steady-state runtime  

---

## 1. TELEMETRY COMPARISON (960 × 540 Viewport, Forward+)

| Metric | V7 Baseline | V8 Style Proof (Initial) | V8 Style Proof (Refined) | Refined vs Baseline Delta |
|---|---|---|---|---|
| **Total Draw Calls (Frame)** | 68 | 106 | 100 | +32 |
| **Primitives / Triangles** | 59,410 | 64,498 | 69,002 | +9,592 |
| **Total Objects in Frame** | 75 | 126 | 120 | +45 |
| **Average Frame Time** | 16.46 ms (60.8 FPS) | 16.39 ms (61.0 FPS) | 16.45 ms (60.8 FPS) | 0.0 ms |
| **P95 Frame Time** | 17.20 ms | 17.37 ms | 17.32 ms | +0.12 ms |
| **Real Mobile Performance** | UNKNOWN | UNKNOWN | UNKNOWN | Pending real mobile profiling |

---

## 2. STYLE PROOF ASSET REFINEMENTS

1. **Scrap Pile (`scrap_pile_proof.tscn`)**:
   - Distinctive scrap-industrial silhouette: angled rusted core + slanted bent sheet plate + wheel rim / pulley form + protruding rusted axle pipe.
   - Distinct junk silhouette from camera distance (not stacked primitives).
2. **Salvage Container (`salvage_container_proof.tscn`)**:
   - Added procedural normal corrugated ribs via `mat_corrugated_metal.tres`.
   - Added reinforced front/back structural frames and top roof rails using `mat_rusted_scrap.tres`.
3. **Ground Treatment (`ground_debris_proof.tscn`)**:
   - Replaced rectangular tile with organic noise-masked oil/grime decal (`mat_oil_stain.tres`).
   - Shadows disabled (`cast_shadow = 0`) on planar decals and ground flakes to prevent wasteful shadow draw calls.

---

## 3. VISUAL ASSETS CAPTURED
- `res://verification/v8/v8_proof_01_cold_start.png`: Cold start framing with Player against salvage container, scrap pile, and oil grime decal.
- `res://verification/v8/v8_proof_02_tuner_approach.png`: Tuner approach framing with Player, glowing amber dial, and flanking scrap mound with wheel rim silhouette.
