# 04 — World State Causality & Panel Power Link

**What to build:**
Connecting Signal Lock event to world causality. Locking frequency on Tuner powers the Corroded Panel (`panel.is_powered = true`). Cable/pipe visual paths connect Tuner to Panel; emissive indicator lights switch from dormant orange to powered cyan.

**Blocked by:** 01 — Shared Interaction Contract & Tuner State Machine, 02 — Signal Tuner Gesture & Touch Control

**Status:** ready-for-agent

- [ ] Tuner `signal_locked` signal emits world state update
- [ ] Corroded Panel receives power, transitions from unpowered to interactable `APPROACHED` state
- [ ] Emmissive visual cables glow upon power transfer
- [ ] Panel peel gesture enabled only after power received
