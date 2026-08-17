# Milestone V8 M02 Tickets: Mobile Safe-Area, Touch Ergonomics & Device Readiness
**Milestone**: V8 M02  
**Dependency Flow**: V8 02.1 → V8 02.2 → V8 02.3 → V8 02.4  

---

## Ticket V8 02.1: Safe-Area Foundation, Coordinate Safety & Device Simulator
- **Focus**: Core safe-area container architecture, DisplayServer integration, debug simulation API, resize state cleanup, and stretch-policy (`keep` vs `expand`) A/B experiment.
- **Tasks**:
  1. Implement `SafeAreaRoot` in `godot/scripts/ui/touch_controls_ui.gd` and `touch_controls_ui.tscn`.
  2. Implement coordinate-safe mapping from `DisplayServer.get_display_safe_area()` using Godot viewport canvas transforms.
  3. Implement deterministic safe-area override API (`set_simulated_safe_area(rect: Rect2i)`) for desktop/headless simulation.
  4. Implement dynamic resize / safe-area recomputation with active pointer state purge.
  5. Author automated test suite `--run-v8-safe-area-assertions` covering 6 simulation profiles:
     - Profile 1: 960x540 16:9 Standard (Zero insets)
     - Profile 2: 19.5:9 Left Notch / Cutout (e.g. iPhone landscape left)
     - Profile 3: 19.5:9 Right Notch / Cutout (e.g. iPhone landscape right)
     - Profile 4: 20:9 Bottom Home Indicator Inset (e.g. Modern Android / iOS bar)
     - Profile 5: 20:9 Dual Cutout + Bottom Home Bar
     - Profile 6: 4:3 Tablet Landscape (iPad sanity)
  6. Execute and document the `aspect=keep` vs `aspect=expand` stretch-policy experiment.
- **Acceptance Criteria**:
  - All interactive buttons and floating joystick regions strictly enclosed by resolved safe rect.
  - Zero layout overlap across all 6 simulation profiles.
  - Active touches cleanly purged on resize / safe-area recomputation without sticky state.
  - Decision recorded with comparative visual evidence for stretch policy.

---

## Ticket V8 02.2: Thumb Reach, Button Separation & Ergonomic Hierarchy
- **Focus**: Right-thumb button clustering, contextual route switch placement, dismount accident mitigation, and floating joystick clamping.
- **Tasks**:
  1. Calibrate right-thumb cluster: GAS + BRAKE/REVERSE as primary bottom-right anchors; E-BRAKE offset for instant natural thumb-sweep access.
  2. Implement distinct positioning and transition for contextual ROUTE SWITCH so it never overlaps or shares hit boundaries with E-BRAKE.
  3. Relocate DISMOUNT to an upper-right or isolated corner position with dedicated touch bounds to prevent panic dismounts during high-speed chases.
  4. Ensure floating joystick base and knob clamp cleanly within the resolved safe area even when first touch initiates on the extreme outer safe boundary.
  5. Validate forgiving hit boundaries vs visual asset boundaries.
- **Acceptance Criteria**:
  - One-handed right-thumb sweep comfortably toggles Gas, Brake, and E-Brake without mutual overlap.
  - Route switch appears/disappears dynamically without hitching or occluding other controls.
  - Dismount requires intentional reach.
  - Joystick never clips outside safe bounds.

---

## Ticket V8 02.3: Adversarial Multi-Touch & Gesture Conflict Falsification
- **Focus**: Multi-finger concurrency, rapid state transitions, touch boundary slide-offs, and overlay pointer isolation.
- **Tasks**:
  1. Author comprehensive multi-touch stress test matrix:
     - Simultaneous multi-touch: Steer + Gas, Steer + Brake, Steer + E-Brake, Steer + Gas + E-Brake.
     - Rapid transitions: Rapid Gas ↔ Brake switching.
     - Contextual actions: Route switch tapped while steering; Dismount tapped while steering.
     - Boundary slide-off: Dragging active touch off button boundary cleanly releases virtual input without latching.
     - Multi-finger overload: 3rd and 4th simultaneous touches ignored or handled cleanly without stealing driving pointers.
     - Interaction transition: Entering Tuner / Peel / Extract overlays cleanly drops driving pointers.
     - Replay trigger: Activating replay clears any lingering touch down states.
  2. Implement adversarial automated test suite `--run-v8-multitouch-assertions`.
- **Acceptance Criteria**:
  - 100% pass on all adversarial multi-touch scenarios.
  - Zero latched throttle/brake/steering/handbrake state.

---

## Ticket V8 02.4: Aspect-Ratio Benchmark Suite, Regression Sweep & Milestone Walkthrough
- **Focus**: Full Golden Slice verification across all aspect ratios, 16-suite regression sweep, telemetry, and evidence documentation.
- **Tasks**:
  1. Capture screenshots across all 8 gameplay states (Cold Start, Tuner Approach, Panel Extraction, Bike Mount, Full-Speed Driving, Active Chase, Gate Slam, Quiet Aftermath) at each simulated viewport.
  2. Score each profile on: Safe Area Enclosure, Thumb Reach, Control Overlap, HUD Readability, World Occlusion, Gesture Space, Player Visibility.
  3. Run complete regression suite (V1 through V8).
  4. Author `godot/verification/v8/v8_m02_walkthrough.md` and update `HANDOFF.md`.
- **Acceptance Criteria**:
  - 100% GREEN on all regression suites.
  - Comprehensive milestone walkthrough published.
