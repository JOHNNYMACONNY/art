# 01 — Courier Bike Scene & State Machine Contract

**What to build:**
`CourierBike` Area3D/CharacterBody3D node inheriting `InteractableBase`, implementing state machine `PARKED` -> `MOUNTING` -> `DRIVING` -> `DISMOUNTING`, mount proximity detection radius (2.5m), and priority target selection.

**Blocked by:** None — can start immediately.

**Status:** ready-for-agent

- [ ] `CourierBike` node extending `InteractableBase`
- [ ] Vehicle state machine (`PARKED` -> `MOUNTING` -> `DRIVING` -> `DISMOUNTING`)
- [ ] Mount proximity detection and priority target arbitration
- [ ] Player avatar attachment to bike pivot during mount
