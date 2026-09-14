# Chinatown Wars Reference Bar

Directory holds gold-standard reference frames, captures, and telemetry for Gauntlet Loop critic evaluations.

## Structure
- `frames/`: 1440x900 raw emulator frame captures (camera pitch, ink outline width, salvage clutter).
- `clips/`: 60 FPS gameplay videos (pursuit ramming, drift radius, camera lag).
- `telemetry/`: Measured values (0-60 speed curves, cop interception radius, collision impulse).

## Critic Verification Rule
Critic subagents must read actual image/video files in this directory before evaluating Godot renders. Never evaluate from memory or text description.
