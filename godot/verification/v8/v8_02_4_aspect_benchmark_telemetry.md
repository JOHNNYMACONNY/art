# V8 02.4 Aspect-Ratio Benchmark & Safe-Area Telemetry
**Date**: 2026-08-16T20:30 PDT  
**Target Milestone**: V8 M02 — Mobile Safe-Area, Touch Ergonomics & Device Readiness  
**Target Build**: `17f0464c6dcc5796ee7f5fe15665c4b6f96b0cf8`  
**Canvas Resolution**: 960x540 (16:9 Base)  
**Stretch Mode**: `canvas_items`, `aspect="keep"`  

---

## 1. Executive Summary
This document provides empirical runtime coordinate and layout telemetry across 6 representative mobile and tablet viewport aspect ratios under simulated hardware display cutouts and system home indicator bars.

All profiles verify:
1. **Mathematical Projection Accuracy**: Inset translation correctly accounts for uniform scaling (`scale = min(win.x / 960, win.y / 540)`) and centered letterbox/pillarbox offsets (`offset = (win - 960*scale) / 2`).
2. **HUD & Control Enclosure**: All interactive controls (`GAS`, `BRAKE`, `E-BRAKE`, `ROUTE SWITCH`, `DISMOUNT`, `ACTION`, `JOYSTICK`) and status HUDs (`Tension HUD`, `Replay Panel`, `Interaction Overlays`) remain strictly inside the resolved safe rectangle.
3. **Zero Control Overlap**: Pairwise bounding box intersection is `false` across all controls under all viewports.
4. **Notch / Cutout Touch Rejection**: Touches physically inside excluded cutout regions produce zero control input.

---

## 2. Multi-Profile Telemetry Matrix

| Profile # | Display Specs | Physical Window | Hardware Insets (L, T, R, B) | Letterbox / Pillarbox Margins | Resolved Canvas Safe Rect | Enclosure Status | Control Collision | Notch Rejection |
|---|---|---|---|---|---|---|---|---|
| **Profile 1** | Standard 16:9 Baseline | 960 x 540 | (0, 0, 0, 0) | (0, 0, 0, 0) | `Rect2(0, 0, 960, 540)` | 100% PASS | 0 Intersections | N/A (No Notch) |
| **Profile 2A** | 19.5:9 Notch in Pillarbox | 2340 x 1080 | (132, 0, 0, 0) | (210, 0, 210, 0) | `Rect2(0, 0, 960, 540)` | 100% PASS | 0 Intersections | Verified (Pillarbox Protected) |
| **Profile 2B** | 19.5:9 Deep Left Cutout | 2340 x 1080 | (290, 0, 0, 0) | (210, 0, 210, 0) | `Rect2(40, 0, 920, 540)` | 100% PASS | 0 Intersections | Verified (`x < 40` Rejected) |
| **Profile 3** | 19.5:9 Deep Right Cutout | 2340 x 1080 | (0, 0, 290, 0) | (210, 0, 210, 0) | `Rect2(0, 0, 920, 540)` | 100% PASS | 0 Intersections | Verified (`x > 920` Protected) |
| **Profile 4** | 20:9 Bottom Home Bar | 2400 x 1080 | (0, 0, 0, 80) | (240, 0, 240, 0) | `Rect2(0, 0, 960, 500)` | 100% PASS | 0 Intersections | Verified (`y > 500` Protected) |
| **Profile 5** | 20:9 Dual Cutouts + Home Bar | 2400 x 1080 | (290, 0, 290, 80) | (240, 0, 240, 0) | `Rect2(25, 0, 910, 500)` | 100% PASS | 0 Intersections | Verified (All Edges Protected) |
| **Profile 6** | 4:3 Tablet / iPad | 2048 x 1536 | (0, 0, 0, 0) | (0, 192, 0, 192) | `Rect2(0, 0, 960, 540)` | 100% PASS | 0 Intersections | N/A (Fullscreen Canvas) |

---

## 3. Right-Thumb Ergonomic Geometry Verification

Under the standard baseline (960x540) and all clamped safe rects:
- **GAS Button**: `132x108` px, bottom-right anchor `[-156, -132, -24, -24]`
- **BRAKE Button**: `132x108` px, bottom-left anchor `[-304, -132, -172, -24]`
- **E-BRAKE Button**: `132x64` px, top-left anchor `[-304, -212, -172, -148]` (directly above Brake)
- **ROUTE SWITCH Button**: `132x64` px, top-right anchor `[-156, -212, -24, -148]` (directly above Gas)
- **DISMOUNT Button**: `132x56` px, high-right anchor `[-156, 24, -24, 80]` (isolated by 248px vertical margin)
- **ACTION Button (Foot Mode)**: `132x108` px, bottom-right anchor `[-156, -132, -24, -24]` (1:1 muscle memory match with Gas)

### Spacing & Separation Metrics:
- Gas ↔ Brake Horizontal Gap: **16.0 px**
- E-Brake ↔ Brake Vertical Gap: **16.0 px**
- Route Switch ↔ Gas Vertical Gap: **16.0 px**
- E-Brake ↔ Route Switch Horizontal Gap: **16.0 px**
- Dismount ↔ Driving Cluster Separation: **248.0 px** (Exceeds 100px minimum threshold)
- Route Switch Show/Hide Invariance: **0.000 px** displacement in neighboring nodes.

---

## 4. Visual Proof Artifact References
- `res://verification/v8/v8_safe_area_01_16x9_standard.png`
- `res://verification/v8/v8_safe_area_02_19_5x9_left_notch.png`
- `res://verification/v8/v8_safe_area_03_19_5x9_right_notch.png`
- `res://verification/v8/v8_safe_area_04_20x9_home_bar.png`
- `res://verification/v8/v8_safe_area_05_20x9_dual_cutout.png`
- `res://verification/v8/v8_safe_area_06_4x3_tablet.png`
