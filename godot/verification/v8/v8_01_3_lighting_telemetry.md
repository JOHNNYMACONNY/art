# V8 01.3 Lighting, Atmosphere & Hero Landmarks Telemetry

## Environment & Build Truth
- Platform: macOS Metal 4.0 / Apple M4 (Forward+ Desktop Renderer)
- Viewport Resolution: 960x540
- Scene: `res://scenes/prototype/scrap_test_block.tscn`

## Rendering Metric Progression
| Metric | V7 Baseline (Greybox) | V8 01.1B Hardened Proof | V8 01.2 Dressed World | V8 01.3 Lit + Landmarks + Dust | Delta vs V7 Base |
|---|---|---|---|---|---|
| **Total Draw Calls (Frame)** | 68 | 120 | 191 | **216** | +148 |
| **Primitives / Triangles** | 59,410 | 61,690 | 68,186 | **68,726** | **+9,316** (+15.6%) |
| **Total Objects in Frame** | 75 | 144 | 344 | **343** | +268 |
| **Average Frame Time** | 16.46 ms (60.8 FPS) | 16.39 ms (61.0 FPS) | 16.44 ms (60.8 FPS) | **16.44 ms (60.8 FPS)** | 0.0 ms |
| **P95 Frame Time** | 17.20 ms | 17.23 ms | 17.32 ms | **17.46 ms** | +0.26 ms |

## Dynamic Readability Route Matrix
| Route | Scenario | Entities Checked | Camera Status | Result |
|---|---|---|---|---|
| 1 | Runner Cold Start -> Tuner | Player | No sustained occlusion, 100% visible | **PASS** |
| 2 | Tuner -> Extraction | Player | Unobstructed view | **PASS** |
| 3 | Extraction -> Bike | Player, Bike | Both entities visible and clear | **PASS** |
| 4 | Full-Speed Bike -> Gate | Bike | Clean camera lead, zero false collision | **PASS** |
| 5 | Full-Speed Gate -> Shortcut | Bike | Sloped route clearly readable | **PASS** |
| 6 | Chase Through Gate | Bike, Pursuer | Both tracked smoothly across gate slam | **PASS** |
| 7 | Chase Through Shortcut | Bike, Pursuer | Airborne ramp jump clear, pursuer visible | **PASS** |
| 8 | Handbrake Turn Near Props | Bike | Zero collision jitter, smooth camera reverse | **PASS** |

## Performance Status
`DEV CADENCE: STABLE | DRAW SCALING: MEASURED | REAL MOBILE: UNKNOWN`
