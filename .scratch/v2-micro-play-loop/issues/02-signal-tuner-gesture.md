# 02 — Signal Tuner Gesture & Touch Control

**What to build:**
Touch-driven Frequency Dial gesture component (`SignalTuner` node). Player drags/rotates dial to alter tuning value (`0.0 .. 1.0`). Dwell inside target frequency band (~0.72) triggers Signal Lock. Locomotion input locks during tuning; pointer ownership prevents finger stealing.

**Blocked by:** 01 — Shared Interaction Contract & Tuner State Machine

**Status:** ready-for-agent

- [ ] `SignalTuner` node with frequency target band (~0.72)
- [ ] Touch drag gesture updates frequency value cleanly
- [ ] Dwell timer (~0.4s) inside target band triggers Signal Lock
- [ ] Locomotion pointer locked during tuning, restores cleanly on lock/cancel
- [ ] Target dial position retained on touch release
