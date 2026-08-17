# Milestone V8 M02 Spec: Mobile Safe-Area, Touch Ergonomics & Device Readiness
**Milestone**: V8 M02  
**Status**: APPROVED & LOCKED  

---

## 1. Goal
Make the Golden Slice reliable, comfortable, and readable on modern landscape mobile phone and tablet viewports without changing the locked GTA/Chinatown Wars-style control model or compromising V7/V8 gameplay feel and collision.

---

## 2. Baseline Architecture
- **Logical Base**: 960x540
- **Stretch Mode**: `canvas_items`
- **Stretch Aspect**: Currently `keep` (evaluating `expand` candidate in 02.1)
- **Primary Touch Scheme**:
  - Left thumb: Floating dynamic joystick with safe-area clamping
  - Right thumb: Clustered GAS / BRAKE-REVERSE / E-BRAKE (handbrake)
  - Action/Interaction: Contextual action prompt, central tuner dial / peel / extraction overlays
  - Driving Secondary: Contextual ROUTE SWITCH, separated DISMOUNT
  - Top HUD: Tension meter, pursuit alert banner, extraction prompts, aftermath replay overlay

---

## 3. Player Contract & Invariants
1. **Safe-Area Enclosure**: Every essential interactive control stays inside the usable safe-area boundary resolved from device insets (notches, camera cutouts, home indicators, rounded corners).
2. **Control Reach & Hierarchy**:
   - Right thumb primary: GAS and BRAKE.
   - Right thumb secondary: E-BRAKE immediately reachable without hand contortion or competing with GAS/BRAKE.
   - Distinct Contextual: ROUTE SWITCH appears contextually near gate/shortcut decisions without colliding with E-BRAKE.
   - Accident Prevention: DISMOUNT separated from high-frequency driving inputs to prevent accidental exit during evasion.
3. **Floating Joystick Safe Clamping**: Joystick can be initialized anywhere on the left touch zone, but its visual base and knob clamp cleanly within the resolved safe area.
4. **Multi-Touch Concurrency**: Driving multi-touch combinations remain intact: Steer+Gas, Steer+Brake, Steer+E-Brake, Steer+Gas+E-Brake.
5. **No Pointer Latching**: Sliding fingers off buttons or screen boundaries cannot latch throttle, steering, brake, or interaction states.
6. **Overlay Pointer Isolation**: Central mini-game overlays (Tuner, Peel, Core Tap) cannot inherit or steal driving touch pointers.
7. **Dynamic Resize / Orientation State Purge**: Viewport resize, resolution change, or safe-area inset recomputation instantly clears active touch states to avoid phantom input.
8. **Desktop / Headless Emulation Compatibility**: Mouse and synthetic touch events continue to function seamlessly in desktop dev and headless regression suites.
9. **Scope Boundaries**:
   - Portrait mode is OUT OF SCOPE (landscape only).
   - Vehicle handling physics, camera tuning, audio synthesis, world dressing geometry, and greybox collision remain strictly UNTOUCHED.
10. **Device Evidence Truth**: Real-device performance is claimed ONLY when tested on physical hardware; otherwise labeled `SIMULATED MOBILE UX = VERIFIED | REAL DEVICE UX = UNKNOWN | REAL MOBILE PERFORMANCE = UNKNOWN`.

---

## 4. Architecture Design: `SafeAreaRoot`
Rather than scattering ad-hoc pixel offsets across individual controls, `TouchControlsUI` introduces a root container hierarchy:
```
TouchControlsUI (Control, Anchors Full Rect 0..1)
├── SafeAreaRoot (MarginContainer / Control, dynamically sized to resolved safe rect)
│   ├── LeftTouchArea (Floating Joystick spawning zone)
│   ├── RightTouchArea (Gas, Brake, E-Brake, Route Switch, Dismount, Action)
│   ├── DrivingOverlayPanel (Speedometer, Gear/State indicator)
│   └── TensionHUDPanel (Top tension meter & pursuit banner)
├── GestureOverlayPanel (Centered Tuner / Peel / Extract overlays)
└── ReplayOverlayPanel (Full-screen aftermath replay trigger)
```

Safe-area computation uses `DisplayServer.get_display_safe_area()` combined with viewport transform matrices to convert screen pixels to canvas coordinates accurately across any resolution or stretch setting. A deterministic test override allows headless and desktop simulation of notches, punch-holes, and home bars across 6 target aspect ratios (16:9, 19.5:9, 20:9, 4:3).
