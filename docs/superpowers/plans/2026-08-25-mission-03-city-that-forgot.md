# Mission 03 — The City That Forgot Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the third connected authored mission: Civic Repossession completion unlocks Sister Kael, the player activates a bounded Silent Core interaction, an authored HS-7 Memory Echo completes, retained pursuit begins, and escape completes the mission.

**Architecture:** Follow the Mission 01/02 precedent: a small pure mission state object plus a thin production runtime adapter. Extend the existing `MemoryEchoController` with the smallest mission-safe authored-payload entrypoint while preserving the extraction-only `trigger_echo()` contract. Add one bounded `SilentCoreInteractable` to the current production scene and route it through the retained interaction selection/Action authority rather than creating parallel input/UI systems.

**Tech Stack:** Godot 4.7.1, GDScript, existing GitHub Actions Web Playtest and canonical compatibility matrix.

**Spec:** GitHub issue #56. Product direction remains issue #55.

## Global Constraints

- Mission 03 unlocks only after Mission 02 is COMPLETE.
- Reuse the single existing safe-area MissionHUD; no parallel mission HUD.
- Reuse existing Action/InteractableBase authority.
- Reuse `MemoryEchoController`; do not fork an HS-7/echo presentation system.
- Preserve Mission 01 extraction Echo semantics and reset behavior.
- Retained root pursuit/interception/retry authority remains canonical.
- No generalized mission framework, combat system, inventory, map/GPS, persistent economy, save campaign, or open-world expansion in this slice.
- Full Replay resets Mission 03 and restores the Mission 01 cold-start chain.

---

### Task 1: Pure Mission 03 state contract

**Files:**
- Create: `godot/tests/city_that_forgot_mission_contract_test.gd`
- Create after RED: `godot/scripts/missions/city_that_forgot_mission.gd`
- Modify: `godot/tests/touch_controls_event_routing_test.gd` to execute the contract.

**Interfaces:**
- Produces `Phase { LOCKED, REACH_SILENT_CORE, ECHO_ACTIVE, ESCAPE, FAILED, COMPLETE }`.
- Produces `unlock_after_civic_repossession()`, `on_silent_core_activated()`, `on_echo_completed()`, `on_intercepted()`, `on_retry_started()`, `on_escape_complete()`.

- [ ] Write a failing contract proving locked wrong-order rejection, Mission 02 unlock, Silent Core progression, Echo ordering, interception/fast retry, successful escape, and narrative-only completion.
- [ ] Push the RED commit and verify the branch workflow fails because the Mission 03 production script is missing.
- [ ] Add the minimal mission state implementation.
- [ ] Verify the contract goes green before proceeding.

### Task 2: Mission-safe authored Memory Echo payload

**Files:**
- Create: `godot/tests/memory_echo_authored_payload_contract_test.gd`
- Modify after RED: `godot/scripts/prototype/memory_echo_controller.gd`
- Modify: `godot/tests/touch_controls_event_routing_test.gd` to execute the contract.

**Interfaces:**
- Preserve `arm_for_extraction()` + `trigger_echo()` unchanged for Mission 01.
- Add a bounded authored trigger API that consumes `EchoData`, requires IDLE, increments the same trigger counter, and uses the same phase/audio/visual lifecycle.
- `reset_echo()` clears authored/extraction state identically.

- [ ] Write a failing contract proving authored payload flows through the retained controller, cannot double-trigger, and resets cleanly while original extraction behavior remains intact.
- [ ] Push RED and verify expected failure.
- [ ] Add the smallest shared internal trigger path and public authored entrypoint.
- [ ] Verify both authored and extraction contracts pass.

### Task 3: Silent Core interaction + thin Mission 03 runtime

**Files:**
- Create: `godot/scripts/interactions/silent_core_interactable.gd`
- Create: `godot/scenes/interactions/silent_core_interactable.tscn`
- Create: `godot/scripts/missions/city_that_forgot_runtime.gd`
- Modify: `godot/scripts/prototype/scrap_test_block.gd` only as needed to register the Silent Core with retained interaction targeting and expose the existing echo controller safely.
- Modify: `godot/scenes/prototype/scrap_test_block.tscn` to add the runtime and bounded Silent Core location.

**Interfaces:**
- `SilentCoreInteractable` extends `InteractableBase` and emits one activation signal only when powered and in range.
- Mission runtime observes Mission 02 COMPLETE, owns only Mission 03 state/HUD copy, enables Silent Core while appropriate, triggers the retained authored Echo, observes Echo completion, and asks root `trigger_disturbance_alert()` to start retained pursuit.
- Runtime observes root INTERCEPTED/PURSUIT_ACTIVE/EVADED for fail/retry/complete; it does not mutate pursuer mechanics.

- [ ] Extend the production-scene test first to require runtime binding, shared-HUD handoff, wrong-order Silent Core rejection, retained Action-path activation, exactly-once Echo, pursuit handoff, interception/fast retry, successful escape, and Full Replay reset.
- [ ] Push RED and verify failure is specifically missing Mission 03 runtime/Silent Core integration.
- [ ] Add the minimal interactable, scene wiring, and runtime adapter.
- [ ] Verify mobile production-scene regression and existing desktop/Web gates pass.

### Task 4: Frozen review, PR, merge, and continuity

**Files:**
- Modify production only if review finds a concrete defect.
- After gameplay merge, update `HANDOFF.md` in a separate docs-only continuity PR.

- [ ] Freeze exact gameplay head and run Standards + approved-spec review against the diff.
- [ ] If a finding exists, reproduce RED, repair, and rerun exact-head verification.
- [ ] Open PR with exact head, run PR `head`, synthetic `merge`, and canonical compatibility matrix.
- [ ] Squash-merge only with the reviewed/verified expected head SHA.
- [ ] Verify merged exact `main` Web Playtest path.
- [ ] Update `HANDOFF.md` with Mission 03 and the explicit next gate: Visual Direction / Concept Art before Gears District production.
- [ ] Stop before Open World Expansion 01 implementation.
