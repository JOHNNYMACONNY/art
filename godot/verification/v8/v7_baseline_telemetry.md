# V7 VERIFIED BASELINE RENDERING & PERFORMANCE TELEMETRY

**Measured At Baseline SHA**: `47456504711a85a35d94f4f95e56315fbe395f70` (runtime equivalent `a546189`)  
**Timestamp**: 2026-08-16T13:50 PDT  
**Engine**: Godot 4.7.1 Stable (Official)  
**Hardware / Device**: Apple M4 (Metal 4.0 Forward+)  
**Command**: `godot --path godot/ -- ++ --run-v8-telemetry`  
**Sample Window**: 120 frames steady-state runtime  

---

## 1. RENDER & SCENE METRICS

| Metric | Measured Baseline Value |
|---|---|
| **Logical Viewport Size** | 960 × 540 |
| **Rendering Method** | Forward+ (Metal) |
| **Total Draw Calls (Frame)** | 68 |
| **Total Primitives / Triangles** | 59,410 |
| **Total Objects in Frame** | 75 |
| **Average Frame Time** | 16.46 ms (60.8 FPS) |
| **P95 Frame Time** | 17.20 ms |
| **Real Mobile Performance** | UNKNOWN (Host desktop Forward+ development baseline) |

---

## 2. BASELINE VISUAL EVIDENCE
Captured and committed at baseline SHA:
- `res://verification/v8/v7_baseline_01_cold_start.png`
- `res://verification/v8/v7_baseline_02_tuner_approach.png`
- `res://verification/v8/v7_baseline_03_panel_extraction.png`
- `res://verification/v8/v7_baseline_04_bike_staging.png`
- `res://verification/v8/v7_baseline_05_gate_approach.png`
- `res://verification/v8/v7_baseline_06_shortcut_ramp.png`
- `res://verification/v8/v7_baseline_07_active_chase.png`
- `res://verification/v8/v7_baseline_08_quiet_aftermath.png`
