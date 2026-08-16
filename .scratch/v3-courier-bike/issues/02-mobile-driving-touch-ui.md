# 02 — Mobile Driving Touch UI & Input Routing

**What to build:**
Touch controls driving overlay (`DrivingControlsUI`), left joystick steering, right throttle/brake buttons, pointer isolation (steering touch cannot trigger dismount, dismount enabled only at speed <= 1.5 m/s).

**Blocked by:** 01 — Courier Bike Scene & State Machine Contract

**Status:** ready-for-agent

- [ ] Mobile driving control layout (left joystick steering, right throttle/brake buttons)
- [ ] Multitouch pointer isolation for steering vs action buttons
- [ ] Dismount button visible/active only when bike speed <= 1.5 m/s
- [ ] Seamless transition between on-foot touch UI and driving touch UI
