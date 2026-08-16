# V8 01.2 WORLD DRESSING & LANDMARKS RENDERING & TELEMETRY REPORT

**Measured At Branch**: `main`  
**Timestamp**: 2026-08-16T14:14 PDT  
**Engine**: Godot 4.7.1 Stable (Official)  
**Hardware / Device**: Apple M4 (Metal 4.0 Forward+)  
**Command**: `godot --path godot/ -- ++ --run-v8-telemetry`  
**Sample Window**: 120 frames steady-state runtime  

---

## 1. TELEMETRY COMPARISON (960 × 540 Viewport, Forward+)

| Metric | V7 Baseline | V8 Style Proof (Initial) | V8 01.1B Hardened (Proof) | V8 01.2 Dressed World (6 Landmarks) | Total Delta vs V7 Base |
|---|---|---|---|---|---|
| **Total Draw Calls (Frame)** | 68 | 106 | 120 | **191** | +123 |
| **Primitives / Triangles** | 59,410 | 64,498 | 61,690 | **68,186** | **+8,776** (Only +14.7% tris over empty greybox) |
| **Total Objects in Frame** | 75 | 126 | 144 | **344** | +269 |
| **Average Frame Time** | 16.46 ms (60.8 FPS) | 16.39 ms (61.0 FPS) | 16.39 ms (61.0 FPS) | **16.44 ms (60.8 FPS)** | 0.0 ms |
| **P95 Frame Time** | 17.20 ms | 17.37 ms | 17.23 ms | **17.32 ms** | +0.12 ms |
| **Performance Status** | Base | Stable | Stable | **DEV CADENCE: STABLE \| DRAW SCALING: MEASURED \| REAL MOBILE: UNKNOWN** | — |

---

## 2. LANDMARK DRESSING SUMMARY (All 100% Non-Colliding)

1. **Cold Start Shelter (`1_ColdStartShelter`)**:
   - West base container, SW corner scrap pile A, crushed drum stack B, south backdrop fence, organic heptagon spawn grime decal.
2. **Tuner Outpost (`2_TunerOutpost`)**:
   - Protective fence backer, east electrical conduit pipe rack, flanking scrap piles A and B, base oil spill decal.
3. **Extraction Bay (`3_ExtractionBay`)**:
   - Machinery housing container flanking corroded panel, overhead pipe rack conduit, west scrap pile A, base machinery grime decal.
4. **Bike Staging Pad (`4_BikeStagingPad`)**:
   - East pipe rack, boundary corrugated fence line, bike staging pad tire wear decal.
5. **Gate Barrier Assembly (`5_GateBarrierAssembly`)**:
   - Dual heavy stanchion pipe racks flanking gate pivot, east/west corrugated perimeter fences, scrap pile B flank, road grime decal.
6. **Shortcut Ramp & Perimeter (`6_ShortcutRampAndPerimeter`)**:
   - Overhead pipe rack ramp bridge, ramp entrance guide scrap pile A, northwest and northeast perimeter container walls, north boundary fence, ramp landing decal.

---

## 3. CANONICAL DRESSED VISUAL BENCHMARK SUITE
- `res://verification/v8/v8_dressed_01_cold_start.png`
- `res://verification/v8/v8_dressed_02_tuner_approach.png`
- `res://verification/v8/v8_dressed_03_panel_extraction.png`
- `res://verification/v8/v8_dressed_04_bike_staging.png`
- `res://verification/v8/v8_dressed_05_gate_approach.png`
- `res://verification/v8/v8_dressed_06_shortcut_ramp.png`
- `res://verification/v8/v8_dressed_07_active_chase.png`
- `res://verification/v8/v8_dressed_08_quiet_aftermath.png`
