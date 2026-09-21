# HANDOFF.md — Current Product Continuity

**Status:** `BURNSIDE_P12_DURABLE_CASH_MERGED_VERIFIED_PUBLIC`  
**Current gameplay/world baseline:** `a7abf55282cff8d7daad81a9a8624ee61364d528`  
**Immutable Feel baseline:** `09fa2b0ab8aebc8a2ae54b989bffad7720503e48`  
**Engine:** Godot 4.7.1 Stable

> Continuity only. Refresh remote `main`, open PRs/issues, CI, public-playtest state, and any concurrent Audio/shared-scene work before repo-sensitive claims. A later docs-only continuity merge may make repository HEAD newer than the exact verified gameplay/public baseline above without changing runnable gameplay.

## Current product state

Burnside now has one dense qualified Gears production block where authored missions, Heat-1 Wanted / Contact-Search, local Field Hacking, civic reporting, reactive work-zone actors, the Scrapper Tool, physical pursuer counterplay, Player Health / expendable Armor / Soft Failure, durable mapped route knowledge, coarse vehicle condition, one bounded Burn Garage repair loop, and authored FB-13 / HS-7 companion presence compose in the same geography.

**Gears District Slice 01b Visual Clutter, Vehicle Fleet, Street Combat, Interceptor Ram Combat, Municipal Quota Kiosk, Scrap Dumpster Stealth, Street Vendor Smuggler Depot, Destructible Traffic Barrier Shortcut Breach, Interactive Utility Pole EMP Grid Overload, Municipal Utility Crawler Patrol & Commercial Storefront Vending Machine Contraband Hack complete.**
- **Commercial Storefront Vending Machine Contraband Hack ([`prop_vending_machine.gd`](file:///Users/bobbyinthelobby/{art/godot/scripts/props/prop_vending_machine.gd), [`prop_vending_machine.tscn`](file:///Users/bobbyinthelobby/{art/godot/scenes/props/prop_vending_machine.tscn), [`vending_machine_interactable.gd`](file:///Users/bobbyinthelobby/{art/godot/scripts/interactions/vending_machine_interactable.gd), [`vending_machine_world_event.gd`](file:///Users/bobbyinthelobby/{art/godot/scripts/world/vending_machine_world_event.gd}))**:
  - Staged on commercial storefront sidewalk paver corner at `Vector3(-6.5, 0.0, -25.0)`.
  - Target arbitration integration: `VendingMachineInteractable` (`InteractableBase`) registers into world `_interactables`, highlighted via dynamic prompt (`[E] HACK TERMINAL`, `[E] DISPENSED`, `[E] BREACHED`) on desktop and touch UI.
  - Tactical frequency hack: interacting via `[E] HACK TERMINAL` hacks contraband circuit, dispenses emergency fuel cell (+80 scrap credits or vehicle nitro surge boost +35% top speed, +40% accel for 6.0s), transitions to `VendingState.HACKED`, switches illuminated display light from cyan (`Color(0.2, 0.85, 1.0)`) to green (`Color(0.2, 1.0, 0.4)`), and plays `COMPLETION` + `AMBIENT_WORK_CLINK` SFX.
  - Foot melee strike tampering: prybar strikes (`machine.take_hit(1, ...)`) rattle reinforced cabinet, trigger elastic mesh recoil, play spark/clink sound events; 3-hit durability lifecycle (3 -> 0) shatters cash vault, transitions to `VendingState.BREACHED`, spills +120 scrap chunks, scatters 4 debris shards, trips `SIREN_ALARM`, and triggers municipal disturbance alert.
  - High-speed vehicle ram: impacts at `>= 4.5 m/s` knock chassis with 30° tilt along collision vector, scatter 4 debris shards, spill +120 scrap chunks, transition to `VendingState.BREACHED`, play `COLLISION_HEAD_ON` + `SPARK` + `SIREN_ALARM`, and trigger municipal disturbance alert. Low-speed nudges (< 4.5 m/s) deflect with zero breach.
  - Deterministic reset: `reset_vending_machine()` in `reset_slice()` restores upright transform, durability (3), cyan screen emission, clears debris shards, re-enables collision shape, and restores `READY` state cleanly.
- **World Event 04 — Municipal Utility Crawler Patrol ([`utility_crawler.gd`](file:///Users/bobbyinthelobby/{art/godot/scripts/entities/utility_crawler.gd), [`utility_crawler.tscn`](file:///Users/bobbyinthelobby/{art/godot/scenes/entities/utility_crawler.tscn), [`utility_crawler_interactable.gd`](file:///Users/bobbyinthelobby/{art/godot/scripts/interactions/utility_crawler_interactable.gd), [`utility_crawler_world_event.gd`](file:///Users/bobbyinthelobby/{art/godot/scripts/world/utility_crawler_world_event.gd}))**:
  - Waypoint patrol loop along the clear retained yard corridor (`Vector3(1.0, 0.05, 1.5)` to `Vector3(1.0, 0.05, 6.0)`), north of the Signal Tuner interaction lane.
  - Target arbitration integration: `UtilityCrawlerInteractable` (`InteractableBase`) registers into world `_interactables`, highlighted via dynamic prompt (`[E] INTERCEPT`, `[E] HARVESTED`, `[E] DISABLED`, `[E] WRECKED`).
  - Tactical scrap interception: interacting via `[E] INTERCEPT` claims +60 scrap credits, transitions to `CrawlerState.DISABLED`, halts movement, extinguishes amber beacon, and plays `COMPLETION` + `AMBIENT_WORK_CLINK` SFX.
  - Foot melee strike tampering: prybar strikes (`crawler.take_hit(1, ...)`) trigger elastic chassis recoil tween, play clink/spark audio; 2-hit lifecycle (durability 2 -> 0) disables crawler, spills +60 scrap (if unharvested), and scatters 3 scrap debris shards.
  - High-speed vehicle ram: impacts at `>= 4.5 m/s` launch/tilt chassis (35° tilt, 2.5m displacement), scatter 4-5 scrap debris chunks, grant +60 scrap (if unharvested), transition to `CrawlerState.WRECKED`, play `COLLISION_HEAD_ON` + `SPARK` + `SIREN_ALARM`, and trigger municipal disturbance alert (`trigger_disturbance_alert()`).
  - Deterministic reset: `reset_actor()` in `reset_slice()` fully restores upright transform, durability (2), amber beacon (energy 1.4), clears all debris shards, re-enables collision shape, and restores `AMBIENT` state cleanly.
- **Interactive Surveillance Utility Pole & EMP Grid Overload ([`prop_utility_pole.gd`](file:///Users/bobbyinthelobby/{art/godot/scripts/props/prop_utility_pole.gd), [`prop_utility_pole.tscn`](file:///Users/bobbyinthelobby/{art/godot/scenes/props/prop_utility_pole.tscn), [`utility_pole_interactable.gd`](file:///Users/bobbyinthelobby/{art/godot/scripts/interactions/utility_pole_interactable.gd))**:
  - Staged on sidewalk curb frontage at `Vector3(-6.2, 0.0, -18.0)`.
  - Target arbitration integration: `UtilityPoleInteractable` (`InteractableBase`) registers into world `_interactables`, highlighted via dynamic prompt (`[E] TAP GRID`, `[E] OVERLOADED`, `[E] WRECKED`, `[E] BLOWN`).
  - Tactical player interaction: `[E] TAP GRID` triggers grid overload, dims cyan optic conduit emission (from 0.7 to 0.05), spawns 5 electrical spark debris shards, broadcasts 9.0m EMP shockwave, and stuns active pursuers for 4.0s.
  - Foot melee strike tampering: prybar strikes (`pole.take_hit(1, ...)`) trigger elastic visual recoil shake, decrement durability (3 -> 0); lethal 3rd hit causes transformer blowout, detonating EMP shockwave.
  - High-speed vehicle ram: impacts at `>= 4.5 m/s` tilt pole by 22° in impact direction, blow out transformer, detonate EMP shockwave, and transition to `PoleState.RAMMED`. Low-speed nudges (< 4.5 m/s) deflect with zero damage.
  - Pursuer EMP stun integration: `pursuer.apply_emp_stun(4.0)` disables pursuer velocity, triggers cyan glitch strobe on siren light, and inhibits target interception during stun duration.
  - Deterministic reset: `reset_pole()` in `reset_slice()` fully restores upright transform, durability (3), optic emission (0.7), clears spark instances, and restores `READY` state.
- **Destructible Traffic Barrier Shortcut Breach ([`prop_traffic_barrier.gd`](file:///Users/bobbyinthelobby/{art/godot/scripts/props/prop_traffic_barrier.gd), [`prop_traffic_barrier.tscn`](file:///Users/bobbyinthelobby/{art/godot/scenes/props/prop_traffic_barrier.tscn))**:
  - Dual roadblock barricades blocking secondary alley shortcut corridor at `Vector3(-2.5, 0, -28.0)` and `Vector3(-0.5, 0, -28.0)`.
  - Melee strike tampering: prybar strikes (`barrier.take_hit(1, ...)`) trigger elastic mesh recoil, play `AMBIENT_WORK_CLINK` sound event, zero breach (collision shape remains active).
  - Low-speed vehicle nudge: impacts at `< 5.0 m/s` deflected with solid block collision, zero breach.
  - High-speed vehicle ram breach: impacts at `>= 5.0 m/s` transition barrier to `BarrierState.BREACHED`, disable `CollisionShape3D` (clearing shortcut corridor), launch barrier mesh tumbling upward and forward, scatter 4 debris shards with quadratic arc trajectory, play `COLLISION_HEAD_ON` and `SPARK` SFX, and trigger municipal disturbance alert.
  - Deterministic reset: `reset_barrier()` in `reset_slice()` restores initial transforms, clears debris instances, re-enables collision shape, and restores `INTACT` state cleanly.
- **Interactive Street Vendor Smuggler Depot ([`prop_street_vendor.gd`](file:///Users/bobbyinthelobby/{art/godot/scripts/props/prop_street_vendor.gd), [`prop_street_vendor.tscn`](file:///Users/bobbyinthelobby/{art/godot/scenes/props/prop_street_vendor.tscn))**:
  - Staged on commercial sidewalk frontage at `Vector3(-8.5, 0.0, -22.0)`.
  - Target arbitration integration: `StreetVendorInteractable` (`InteractableBase`) registers into world `_interactables`, highlighted via dynamic prompt (`[E] TUNE-UP // 150`, `[E] TUNED`, `[E] WRECKED`) on desktop and touch UI.
  - Scrap economy loop: 150 scrap trade awards temporary vehicle tune-up (+35% top speed, +40% acceleration for 8.0s on Courier Bike and Muscle Coupe), transitions to `VendorState.TUNED`, plays `COMPLETION` + `AMBIENT_WORK_CLINK` SFX.
  - Street combat melee tampering: prybar strikes (`vendor.take_hit(1, ...)`) rattle corrugated stall structure, trigger elastic mesh recoil, play spark/clink sound events, reduce durability (3 -> 0), and transition vendor to `VendorState.DAMAGED` (trade locked out).
  - High-speed vehicle ram: impacts at `>= 4.5 m/s` knock vendor stall along collision vector (`impact_speed * 0.35` slide displacement), tilt canopy fabric/mesh, play `COLLISION_HEAD_ON` + `SPARK` SFX, and transition to `VendorState.RAMMED` (trade locked out).
  - Deterministic reset: `reset_vendor()` fully restores initial transform, durability (3), canopy rotation, and clears tuned/damaged state.
- **Interactive Municipal Scrap Dumpster & Stealth Evasion ([`prop_scrap_dumpster.gd`](file:///Users/bobbyinthelobby/{art/godot/scripts/props/prop_scrap_dumpster.gd), [`prop_scrap_dumpster.tscn`](file:///Users/bobbyinthelobby/{art/godot/scenes/props/prop_scrap_dumpster.tscn))**:
  - Staged in service alley bypass at `Vector3(-10.8, 0.0, -32.5)`.
  - Target arbitration integration: `ScrapDumpsterInteractable` (`InteractableBase`) registers into world `_interactables`, highlighted via dynamic prompt (`[E] SEARCH`, `[E] HIDE`, `[E] EXIT`) on desktop and touch UI.
  - Salvage scavenging: first search loots +75 scrap credits, transitions to `DumpsterState.SCAVENGED`, plays `COMPLETION` + `AMBIENT_WORK_CLINK` SFX; single-claim rule strictly enforced.
  - Stealth evasion mechanics: when pursuers are actively hunting, action verb becomes `HIDE`; entering dumpster locks player input, suppresses player visibility and velocity, transitions to `DumpsterState.OCCUPIED_HIDING`, and triggers `pursuer.start_de_escalation()` to cool down city heat.
  - Evasion release: interacting while concealed (`[E] EXIT`) restores player visibility, unlocks locomotion, repositions runner safely outside (+1.5m Z), and restores dumpster state.
  - Street combat melee tampering: prybar strikes (`dumpster.take_hit(1, ...)`) rattle metal lid, trigger elastic mesh recoil, play spark/clink sound events, and automatically eject any hiding player.
  - High-speed vehicle ram: impacts at `>= 4.5 m/s` knock dumpster along collision vector (`impact_speed * 0.35` slide displacement), spill scrap, play `COLLISION_HEAD_ON` SFX, and eject hiding player with knockback impulse.
  - Deterministic reset: `reset_dumpster()` fully restores initial transform, durability (3), unsearched state, and clears hiding references.
- **Interactive Municipal Quota Kiosk / Civic Deposit Terminal ([`prop_quota_kiosk.gd`](file:///Users/bobbyinthelobby/{art/godot/scripts/props/prop_quota_kiosk.gd), [`prop_quota_kiosk.tscn`](file:///Users/bobbyinthelobby/{art/godot/scenes/props/prop_quota_kiosk.tscn))**:
  - Staged on commercial sidewalk frontage at `Vector3(-9.8, 0.0, -30.5)`.
  - Biometric proximity detection & dynamic scanner emission (`OmniLight3D` scanner light surges from 1.2 to 3.2 intensity on player arrival).
  - Target arbitration integration: `QuotaKioskInteractable` (`InteractableBase`) registers into world `_interactables`, highlighted via `[E] ACTION` desktop prompt and touch action button.
  - Lawful scrap deposit & civic quota clearance: `kiosk.deposit_scrap(150)` transitions to `State.FULFILLED`, screen emission flashes biometric green (`Color(0.2, 1.0, 0.4)`), plays `COMPLETION` SFX, de-escalates active pursuer heat.
  - Street combat melee tampering: striking kiosk with prybar (`kiosk.take_hit(1, ...)`) triggers elastic mesh recoil, screen security red strobe (`Color(1.0, 0.1, 0.1)`), `SIREN_ALARM`, and initiates municipal disturbance alert.
  - 3-hit terminal breach: lethal strike breaches cash box, awards +200 emergency contraband scrap, emits `kiosk_breached`.
  - Vehicle ram breach: high-speed vehicle impact (`apply_vehicle_ram(speed >= 4.5)`) shatters vault and triggers alarm.
  - Deterministic reset: `reset_kiosk()` restores cold start state cleanly.
- **Pursuit Interceptor Ram / Vehicle Melee Combat**:
  - Weaponized vehicle-on-vehicle collision reception via `pursuer.apply_vehicle_ram(impact_speed, ram_direction, vehicle_source)`.
  - Minimum ram threshold: speed-gated at `>= 4.5 m/s` (`ram_threshold_speed`). Slower nudges safely rejected without state disruption.
  - Stun state machine: transitions pursuer to `PursuerState.STUNNED` for 3.5s (`stun_recovery_time`) with knockback impulse (`velocity = flat_dir * (impact_speed * 1.1) + Vector3(0, 2.2, 0)`), yaw spin-out, and visual root elastic recoil tween.
  - Stun safety: target interception strictly inhibited while in `STUNNED` state (`intercepted_target` cannot fire).
  - Audio & visual feedback: plays `COLLISION_HEAD_ON` and `SPARK` sound events, triggers malfunction amber strobe on siren light.
  - Reboot recovery: on timer expiry, siren light restores red, recovers to `CHASING` (or `DE_ESCALATING`), and emits `stun_recovered`.
  - Vehicle kinetic momentum: `MuscleCoupe` and `ScrapHauler` retain forward momentum through ram collisions via softened `impact_decay` against dynamic ram targets.
  - Pursuit loop safety: `_process_pursuit_loop` checks `_is_vehicle_ramming` to execute offensive vehicle rams instead of false player interceptions.
- **Street Combat & Physical Tool Improvisation**:
  - Player melee strike verb (`player.strike()`) with procedural arm thrust/snap down, torso twist, 2.2m reach, 90.0° arc, 1 damage, 0.38s cooldown rejection, and `PrybarTool` industrial rebar mesh.
  - Breakable Salvage Target (`PropSalvageLockbox`): 3-hit durability, elastic hit recoil, spark VFX, `AMBIENT_WORK_CLINK` / `SPARK` SFX.
  - Municipal security alarm consequence: striking restricted lockbox triggers `alarm_triggered` + `SIREN_ALARM`, activating city disturbance alert and pursuer tracking.
  - Scrap Payoff: 3rd strike breaches lockbox, pops lid open, emits `COMPLETION`, and awards +150 scrap credits.
- **Production Vehicle Fleet (3 Classes)**:
  - Courier Bike (scout/apex banking), Scrap Hauler (heavy/payload/service alley), Muscle Coupe (high-speed scavenged V8, 21 m/s top speed, drift slip, ram breach).
- **World Events (3 Active)**:
  - WE 01 (FB-13 Infrastructure Thrum), WE 02 (Security Checkpoint Toll/Ram Breach), WE 03 (Mayor Burn Contraband Drop).
- **Authored Mission Chain (3 Missions)**:
  - Continuous 3-mission playthrough passes 100% end-to-end.
- **100% test pass across all 17 verification suites**:
  - `scrap_dumpster_integration_test.gd`, `quota_kiosk_integration_test.gd`, `vehicle_pursuer_ram_combat_test.gd`, `street_combat_integration_test.gd`, `muscle_coupe_integration_test.gd`, `camera_mount_transition_test.gd`, `continuous_golden_slice_playthrough_test.gd`, `security_checkpoint_world_event_test.gd`, `alley_contraband_drop_world_event_test.gd`, `desktop_controls_event_routing_test.gd`, `street_vendor_integration_test.gd`, `traffic_barrier_integration_test.gd`, `utility_pole_integration_test.gd`, `utility_crawler_world_event_test.gd`, `vending_machine_integration_test.gd`, `run_expansion_contract.gd`, `run_storefront_contract.gd`.

Approved visual direction remains **Civic Salvage Palimpsest / Industrial Cel-Shaded Near Future**. Issue #118 remains the canonical downstream Burnside player-facing production contract. Issue #55 remains the durable product-direction anchor.

Do not default to more acreage or generalized frameworks. Favor player-facing systemic density, feel, clarity, cohesion, and authored consequence.

## Production sequence — verified baselines

- **Production 01** — #119 / PR #121 — Wanted / Contact-Search — `4e62e198508393821bf902da681daa776d1d8545`.
- **Production 02** — #122 / PR #123 — Field Hacking / Report Suppression — `7a5c36598c6d950d832f71c42e41eaacfb7b75b2`.
- **Production 03** — #124 / PR #125 — Mission-02 Wanted + Field-Hacking composition — `afd1db546b04221c7fb4b222b9f77311acd6d3ea`.
- **Production 04** — #127 / PR #129 — Gears Work-Zone / Player-Reactive Ambient Incident — `7605277d920b7877715d78687ccab16a69745b2f`.
- **Production 05** — #131 / PR #132 — Gears Scrapper Tool / Street-Combat Contact Tracer — `702678cb66ab7544b43644cfa29baf5361c68dc1`.
- **Production 06** — #134 / PR #135 — Gears Surveyed Service Cut / Durable Map-Knowledge Tracer — `cfe82d2580a7300e3ebb2bf3257d08a4300bf2a4`.
- **Production 07** — #137 / PR #138 — Gears Vehicle Condition / Burn Garage Repair Tracer — `3deb1cccafdaeb9f3d6b1629e94f2a262cf3259d`.
- **Production 08** — #141 / PR #143 / PR #145 (review polish) — FB-13 / HS-7 Authored Companion Presence Tracer — `37c130b10db057ba923d5a9a6738081fa91e6fdf`.
- **Production 09** — #149 / PR #150 — Player Health / Armor / Soft Failure Tracer — `069e7f3c504cc5a088577bcd1c5efc21b125f23f`.
- **Production 10** — #152 / PR #154 — Mayor Burn Known Contact / Garage Armor Stash Tracer — `668e760b7da48df33552e182ff3af8bab9d53640`.
- **Production 11** — #158 / PR #159 — Claimed Courier Bike / Burn Garage Recovery Tracer — `af5eaa77101163293bd0e8cefff8ee80605306d3`.
- **Production 12** — #161 / PR #162 — Durable Cash / Street Vendor Transaction Tracer — `a7abf55282cff8d7daad81a9a8624ee61364d528`.

## Retained authority truths

Wanted authority remains:

`INCIDENT -> REPORT -> HEAT 1 + CONTACT -> PHYSICAL RESPONSE -> CONTACT LOSS -> SEARCH -> REACQUIRE or EVADE -> CLEAR FREE ROAM`

Field Hacking remains local and situational:

`DISCOVER LOCAL SERVICE ACCESS -> JAM REPORT LINK -> CIVIC INCIDENT -> ALARM FAULT -> REPORT SUPPRESSED -> NO NEW WANTED`

Mission completion, Scrapper use, route surveying, map viewing, local incident recovery, vehicle repair, and Replay do not silently clear valid Heat / Contact / Search / Recognition authority.

Mission 01 and Mission 03 retain their historical authored pursuit behavior. Mission 02 remains composed with ordinary open-world Wanted + Field Hacking and the existing Burn Garage delivery socket.

## Production 05 retained result

The Scrapper Tool remains one bounded authored physical tool, not a generalized combat/inventory framework.

Primary chain:

`TAKE SCRAPPER TOOL -> FORCE JAMMED SERVICE ACCESS -> LOCAL WORK-ZONE REACTS -> EXISTING CIVIC REPORT ATTEMPT -> HEAT 1 + CONTACT -> PHYSICAL PURSUER CLOSES -> SCRAPPER IMPACT CREATES BRIEF SPACE -> USE SERVICE CUT / BREAK CONTACT`

Key boundaries retained:

- Tool Action is dedicated touch + desktop input and yields to retained gesture/input ownership.
- Forcing the authored ServiceAlley access changes physical traversal only through retained P04/P05 seams.
- Scrapper contact only creates a brief pursuer stagger/displacement window.
- P05 itself introduced no Player Health/Armor. Production 09 now supplies the separate retained PlayerRunner survivability authority. Firearms, weapon roster, generic NPC damage/death, generalized hostile combat AI, inventory/loot/RPG stats, Heat 2–5, generalized witness/crime framework, and unrelated Audio scope remain absent.

## Production 06 retained result

Issue #134 / PR #135: **COMPLETE / MERGED / EXACT-MAIN VERIFIED / PUBLIC VERIFIED**.

Exact gameplay/public baseline:

`cfe82d2580a7300e3ebb2bf3257d08a4300bf2a4`

Player-facing contract:

`LEGITIMATELY TRAVERSE SERVICEALLEY <-> NORTHCONNECTOR -> RECORD SURVEYED ROUTE ONCE -> REPLAY/RELAUNCH RETAINS LEARNED GEOGRAPHY -> PHYSICAL ACCESS MAY RESET TO JAMMED INDEPENDENTLY`

Retained truths:

- only the authored `ServiceAlley <-> NorthConnector` cut is surveyable;
- learned map knowledge and current physical accessibility are independent truths;
- Replay can restore the barrier to `JAMMED` while surveyed route knowledge remains known;
- the route sheet is bounded and on-demand, not a generalized GPS/minimap/navigation system;
- durable P06 knowledge remains isolated in its narrow versioned `surveyed_routes` store;
- P07 does not modify `user://burnside_mapped_knowledge.json` or its schema.

## Production 07 — verified player-facing result

Issue #137 / PR #138: **COMPLETE / MERGED / EXACT-MAIN VERIFIED / PUBLIC VERIFIED** pending only this docs continuity merge and issue closure.

Frozen feature head:

`b98f7e00a0865f5f9e6902cdf7dba2d66d9dec8f`

Exact gameplay merge / verified public baseline:

`3deb1cccafdaeb9f3d6b1629e94f2a262cf3259d`

Player loop:

`DRIVE -> SIGNIFICANT IMPACTS -> BATTERED -> CRITICAL / LIMPING -> ABANDON, SWAP, OR REACH BURN'S GARAGE -> REPAIR -> ROADWORTHY`

Production truths:

- scope is exactly the retained `CourierBike` and `ScrapHauler`;
- player-readable condition states are exactly `ROADWORTHY`, `BATTERED`, and `CRITICAL`;
- no visible numeric HP exists;
- condition derives from each vehicle's real collision telemetry and uses bounded deterministic accumulation plus a 0.50-second accepted-contact cooldown;
- trivial hits are ignored and sustained wall contact cannot melt condition frame-by-frame;
- BATTERED is presentation-first;
- CRITICAL changes only usable forward maximum speed, using the approved `0.52` multiplier;
- steering, reverse, acceleration, braking, grip, mount/dismount, collision response, and retained handling authority remain intact;
- no vehicle explosion or destruction exists;
- Mayor Burn's existing `GearsDistrictSlice01B/MissionDestinationSocket` is the sole P07 repair point;
- repair requires a damaged active supported vehicle, inside the 2.6 m Garage radius, effectively stopped, with authoritative Wanted heat `0` and state `CLEAR`;
- CONTACT, SEARCH, or any other active Wanted state rejects repair;
- repair never clears, resets, or otherwise mutates Wanted authority;
- Garage repair uses the retained Action route only; no repair menu, economy, or generalized interaction/service framework was created;
- Mission 02 remains authoritative for delivery and a CRITICAL Hauler can still complete legal Garage delivery;
- Mission completion and repair affect only their own state and do not double-fire;
- full Replay resets both supported vehicle conditions to ROADWORTHY while P06 surveyed route knowledge remains durable;
- no ownership/claiming, generalized damage framework, generalized vehicle framework, generalized save framework, Garage network, economy, navigation expansion, canon change, or Audio change entered P07.

### Render/readability repair

The first fixed-size world-label repair made the old typography values visually enormous. Automation alone was not accepted as proof.

The final presentation contract keeps `fixed_size = true` and `no_depth_test = true`, but bounds the world labels to small screen-space typography. Final values are:

- CourierBike condition tag: font 6 / outline 2;
- ScrapHauler condition tag: font 6 / outline 2;
- Burn Garage affordance: font 5 / outline 2.

The frozen nine-shot proof was directly inspected after tuning. Vehicle condition tags and Garage `WANTED // SERVICE LOCKED`, `REPAIR // ACTION`, and `ROADWORTHY` states remain readable without dominating or clipping the frame.

## Production 07 verification truth

### Frozen feature head

At `b98f7e00a0865f5f9e6902cdf7dba2d66d9dec8f`:

- exact-source P07 semantics/runtime: **PASS**;
- real `move_and_slide()` collision -> BATTERED/CRITICAL tracer: **PASS**;
- sustained-contact debounce: **PASS**;
- CRITICAL forward limp, steering, and reverse runtime behavior: **PASS**;
- Burn Garage outside/moving/CONTACT/SEARCH rejection + CLEAR repair: **PASS**;
- Mission 02 composition: **PASS**;
- retained P01–P06 focused regressions: **PASS**;
- nine-state rendered proof: **PASS and directly inspected**;
- literal-head Web export/static-host smoke: **PASS**;
- synthetic-merge Web export/static-host smoke: **PASS**;
- literal-head + merge Web persistence: **PASS**;
- current camera contracts + canonical 29-suite compatibility matrix: **PASS**.

Independent frozen review was attempted through both ChatGPT Codex code review and GitHub Copilot review. Both were unavailable because their review quotas were exhausted. A fresh exact-diff senior review in the coordinating ChatGPT session found no concrete blocker but was explicitly non-independent. The owner then explicitly waived the independent-review requirement. Treat this as an **OWNER-WAIVED GATE**, not as an independent approval.

### Exact-main verification

Exact gameplay merge:

`3deb1cccafdaeb9f3d6b1629e94f2a262cf3259d`

Verification-only PR #139 was opened against the pre-P07 base solely to force the P07 pull-request workflow to execute literal head `3deb1cccafdaeb9f3d6b1629e94f2a262cf3259d`; it was closed unmerged after verification.

Production-07 exact-main run `33833338289`:

- exact source checkout at `3deb1cccafdaeb9f3d6b1629e94f2a262cf3259d`: **PASS**;
- P07 vehicle semantics: **PASS**;
- Burn Garage repair runtime: **PASS**;
- Mission 02 composition: **PASS**;
- real collision runtime tracer: **PASS**;
- retained P01–P06 matrix: **PASS**;
- exact-main rendered proof capture/upload: **PASS**;
- artifact `9922447864`, digest `sha256:c63b4096b5aeb2e72be7e47b38b40400c7e884837ad3611c7c61c3d89d91d518`.

Production-06 exact-main retained run `33833186967` additionally proved P06 persistence/survey/input plus retained P01–P05 regressions and same-origin browser relaunch persistence at the same gameplay SHA.

Godot Web Playtest main push run `33833186949`:

- exact source checkout: **PASS**;
- mobile touch routing: **PASS**;
- desktop controls / alias ownership / vehicle authority / interaction cancel: **PASS**;
- Web export: **PASS**;
- static-host smoke: **PASS**;
- source revision stamp verification: **PASS**;
- public `playtest-web` publication: **PASS**.

Public source stamp:

`playtest-web/PLAYTEST_BUILD.txt = 3deb1cccafdaeb9f3d6b1629e94f2a262cf3259d`

## Production 08 — verified player-facing result

Issue #141 / PR #143: **COMPLETE / MERGED / EXACT-MAIN VERIFIED / PUBLIC VERIFIED** pending only this docs continuity merge and issue closure.

Frozen feature head:

`892c8eb0e32602b7974f2281ce9a81d0141abcf5`

Exact gameplay merge / verified public baseline:

`fb63d9ee853aed0e49b2c6b52edfff31cf43fda7`

### World Event 02 — Security Checkpoint Toll Standoff

Production node: `SecurityCheckpointWorldEvent` attached to `scrap_test_block.tscn`.
Script: `godot/scripts/world/security_checkpoint_world_event.gd`.

Canonical local event identity:
- directive: `checkpoint_toll_standoff`;
- actor: `CIVIC_SECURITY_BARRIER`;
- zone: `gears_north_checkpoint`;
- trigger radius: `6.5 m`;
- rearm radius: `10.0 m`;
- cooldown: `8.0 s`;
- prop: `GearsDistrictSlice01B/StreetClutter/SecurityCheckpoint` at `Vector3(-4.5, 0, -42.0)`.

Production behavior:
- approaching within 6.5 m enters `STANDOFF` state and emits `SIREN_ALARM`;
- dual resolution:
  1. Peaceful toll payment (150 credits via `pay_toll()`, `[E] PAY TOLL // 150` on foot or `[F] PAY TOLL // 150` in vehicle): disables barrier collision, emits `COMPLETION` audio;
  2. High-speed vehicle ram breach (`ram_breach(speed)` at speed >= 5.0 m/s): disables barrier collision, emits `COLLISION_HEAD_ON` + `GATE_SLAM` + `SIREN_ALARM`, and triggers root pursuit authority disturbance alert;
- HUD / touch routing: wires context-aware prompts in `TouchControlsUI` (`RouteSwitchButton` in vehicle, `ActionButton` on foot) and desktop `KEY_F` keybind for vehicle route action;
- full reset restoration via `reset_world_event()` in `reset_slice()`.

### World Event 03 — Mayor Burn Contraband Alley Delivery

Production node: `AlleyContrabandDropWorldEvent` attached to `scrap_test_block.tscn`.
Script: `godot/scripts/world/alley_contraband_drop_world_event.gd`.

Canonical local event identity:
- directive: `contraband_alley_drop`;
- actor: `MAYOR_BURN_DROP`;
- zone: `gears_service_alley`;
- reward: `250 credits`;
- entry socket: `GearsDistrictSlice01B/ServiceAlleyEntrySocket` at `Vector3(-10, 0.15, -26)`;
- stash prop: `GearsDistrictSlice01B/StreetClutter/CardboardBoxStack` at `Vector3(-11.45, 0, -37.5)`;
- exit socket: `GearsDistrictSlice01B/ServiceAlleyExitSocket` at `Vector3(-10, 0.15, -44)`.

Production behavior:
- entering within 4.5 m of entry socket (or 3.0 m of stash) triggers `DISCOVERED` state and emits `SIGNAL_LOCK` audio cue;
- prompt updates to `[E] SECURE STASH` / `[F] SECURE STASH`;
- collecting stash transitions to `COLLECTED` state, awards 250 credits;
- moving to exit socket updates prompt to `[E] DELIVER DROP` / `[F] DELIVER DROP`;
- delivering drop transitions to `DELIVERED`, emits `COMPLETION` audio, and triggers root pursuit authority disturbance alert;

### Muscle Coupe Full Drive Integration (High-Performance V8 Fleet Class)

Production node: `MuscleCoupe` attached to `scrap_test_block.tscn`.
Script: `godot/scripts/vehicles/muscle_coupe.gd`.
Scene: `godot/scenes/vehicles/muscle_coupe.tscn`.

Canonical vehicle identity:
- class: `High-Performance Scavenged V8 Muscle Class`;
- max speed: `21.0 m/s` (fastest production vehicle class);
- reverse speed: `-5.0 m/s`;
- acceleration: `14.5 m/s^2`;
- braking friction: `14.0 m/s^2`;
- steering speed: `2.4 rad/s`;
- dismount speed limit: `1.5 m/s`;
- drift slip rate: `3.2` (power oversteer slip model);
- staging position: `Vector3(-3.5, 0.05, 3.0)` in scrap yard (mirrors Scrap Hauler at `Vector3(3.5, 0.05, 3.0)`).

Production behavior:
- mount / dismount: 0.20s smoothstep posture and position blend into `RiderSocket` (`Vector3(-0.36, -0.35, 0.03)` matching driver bucket seat alignment);
- posture: `player.set_vehicle_driving_posture(true, "car")` with steering wheel hand contact;
- interaction: `MountInteractable` (`Area3D`, r=3.0m sphere, priority=2.0) participating in target arbitration;
- driving physics: speed-sensitive yaw rate, chassis corner roll, heavy V8 drift slip, glance collisions with `collision_contact` signal;
- dismount rejection: rejects dismount with `TOO_FAST` at speed > 1.5 m/s, volume-cleared ground check ignoring floor geometry;
- dual world interaction: capable of high-speed ram breach at `SecurityCheckpointWorldEvent` (speed >= 5.0 m/s);
- full reset restoration via `reset_slice()`.

### Street Combat & Physical Tool Improvisation

Production implementation for Issue #55 leading combat frontier:
- Player melee strike verb on foot:
  - verb: `player.strike() -> bool`;
  - reach: `2.2 m`, strike arc: `90.0 deg`, strike damage: `1`;
  - duration: `0.28 s`, cooldown: `0.38 s`, forward impulse: `+3.6 m/s`;
  - physical representation: procedural right arm thrust/snap down + torso rotation twist + `PrybarTool` industrial rebar mesh attached to `MeshPivot/RightArm`;
  - rejection guards: strictly rejected while mounted or input-locked;
  - controls: desktop `KEY_J` or `KEY_SPACE` (on foot traversal), or touch action button fallback.
- Breakable Salvage Target (`PropSalvageLockbox`):
  - scene: `res://scenes/props/prop_salvage_lockbox.tscn` / script `res://scripts/props/salvage_lockbox.gd`;
  - staging position: `Vector3(2.5, 0.0, 6.5)` in scrap yard;
  - durability: `3` hits (`MAX_DURABILITY = 3`);
  - physical reaction: elastic impact recoil tween on `VisualRoot`, status light state transition (SECURED red -> DAMAGED hazard amber -> BREACHED dark);
  - audio events: `AMBIENT_WORK_CLINK` + `SPARK` on impact;
  - city consequence loop: striking restricted municipal lockbox emits `alarm_triggered` + `SIREN_ALARM`, initiating `current_pursuit_state = PursuitState.DISTURBANCE_ALERT` and activating pursuer tracking;
  - payoff: 3rd lethal strike breaches lockbox, pops lid open, emits `COMPLETION`, and awards `+150` scrap credits;
  - reset restoration: full reset via `reset_lockbox()` restored by `reset_slice()`.

Player loop:

`RUNNER ON FOOT -> FB-13 FOLLOWS LOCALLY / HS-7 CARRIED -> MOUNT BIKE/HAULER -> FB-13 DOCKS IN RACK/BED -> DISMOUNT -> FB-13 RELEASES TO FOLLOW -> SUSTAINED OFF-SCREEN SEPARATION -> OFF-SCREEN SNAP -> PHYSICAL REJOIN -> RETEAM`

## Current verification truth

### Vehicle Fleet, Street Combat, Props & World Events verification evidence

- `godot/tests/utility_crawler_world_event_test.gd`: **100% CONTRACT PASS** (5-stage contract: state machine/invariants/action verb arbitration, peaceful [E] INTERCEPT scrap harvest, melee tampering/2-hit disable/scrap spill/debris, vehicle ram deflection vs high-speed wreck/alarm trigger, deterministic slice reset);
- `godot/tests/utility_pole_integration_test.gd`: **100% CONTRACT PASS** (6-stage contract: state machine/invariants/action verb arbitration, melee tampering/3-hit transformer blowout, tactical TAP GRID interaction/EMP detonation, 9.0m EMP shockwave pursuer stun, vehicle ram deflection vs high-speed tilt/blowout, deterministic slice reset);
- `godot/tests/traffic_barrier_integration_test.gd`: **100% CONTRACT PASS** (6-stage contract: state machine/invariants, melee strike recoil/zero breach, low-speed vehicle deflection, high-speed vehicle ram breach/debris scatter/collision disable, alleyway dual-barrier clearance, deterministic slice reset);
- `godot/tests/street_vendor_integration_test.gd`: **100% CONTRACT PASS** (7-stage contract: state machine/invariants, proximity detection/dynamic action verbs, scrap trade/tune-up purchase, vehicle speed & acceleration physics surge, melee strike tampering/durability breakdown, vehicle ram knockback/canopy tilt/trade lockout, reset slice clean restoration);
- `godot/tests/scrap_dumpster_integration_test.gd`: **100% CONTRACT PASS** (6-stage contract: arbitration prompt, scrap scavenging payoff, stealth hiding evasion/pursuer de-escalation, melee tampering ejection, vehicle ram knockback, reset slice restoration);
- `godot/tests/quota_kiosk_integration_test.gd`: **100% CONTRACT PASS** (7-stage contract: biometric proximity detection/dynamic light, scrap deposit/quota clearance/de-escalation, melee tampering/alarm strobe, 3-hit vault breach/200 scrap payoff, vehicle ram breach, reset slice restoration);
- `godot/tests/vehicle_pursuer_ram_combat_test.gd`: **100% CONTRACT PASS** (7-stage contract: ram threshold gating, 3.5s stun state, knockback/spin-out, target lock inhibition, reboot recovery, vehicle momentum retention, pursuit loop safety);
- `godot/tests/street_combat_integration_test.gd`: **100% CONTRACT PASS** (6-stage contract: player melee strike verb, StreetCombatContract invariants, hit registration/durability decrement, security alarm disturbance sequence, lockbox breach + 150 scrap payoff, reset slice restoration);
- `godot/tests/muscle_coupe_integration_test.gd`: **100% CONTRACT PASS** (7-stage contract: hierarchy, performance constants, mounting posture, driving physics, gear transitions, dismount rejection, checkpoint ram breach, reset);
- `godot/tests/security_checkpoint_world_event_test.gd`: **100% CONTRACT PASS**;
- `godot/tests/alley_contraband_drop_world_event_test.gd`: **100% CONTRACT PASS**;
- `godot/tests/camera_mount_transition_test.gd`: **PASS** (retained FB13Thrum, SecurityCheckpoint, ContrabandDrop, MuscleCoupeContract, StreetCombatContract, BurnGarage, SilentCore, ProofRetirement);
- `godot/tests/continuous_golden_slice_playthrough_test.gd`: **100% ALL 3 MISSIONS CONTINUOUS PLAYTHROUGH PASS**;
- `godot/tests/desktop_controls_event_routing_test.gd`: **PASS**;
- `godot/scripts/verification/ctw_wave1_integrated_harness.gd`: **PASS**.

- character-specific presence: FB-13 mobile drone body + HS-7 carried memory module;
- FB-13 is collisionless with no gameplay collision authority (no physics shove, cannot block Runner, vehicles, NPCs, or objectives);
- bounded local follow: side 2.1 m, trailing 1.8 m, height 1.15 m;
- clearance queries: one preferred candidate + one alternate mirrored candidate; holds/lags if both obstructed;
- follow speed (10.5 m/s) and acceleration (28.0 m/s²) intentionally outpace Runner's 8.5 m/s sprint so straight-line running does not force recovery;
- hard recovery: eligible only when separation >= 18.0 m sustained for >= 0.75 s while FB-13 is off-screen;
- deterministic recovery staging: up to 4 deterministic candidate positions on a 16.0 m ring around Runner evaluated for off-screen and clearance;
- recovery snap is off-screen source -> off-screen staging candidate only; visible catch-up is physical `REJOINING` movement at 15.0 m/s until within 5.0 m; zero visible popping;
- explicit vehicle dock sockets: CourierBike rear cargo rack (`FB13DockSocket`) and ScrapHauler cargo bed (`FB13DockSocket`);
- docking starts on retained vehicle `state_changed("MOUNTING")` and interpolates over 0.20 s, completing before the vehicle's 0.25 s mount;
- rejected dismount keeps FB-13 docked;
- successful dismount starts on retained vehicle `state_changed("DISMOUNTING")`, releasing FB-13 physically from vehicle origin;
- HS-7 carried visual instanced under Runner `MeshPivot/Torso/HS7CarrySocket` (presentation-only, moves with torso across all postures);
- retained `FB13ThrumWorldEvent` owns trigger/Audio authority; P08 adds only a local FB-13 body reaction (tilt + emission pulse) for <= 0.65 s; exactly one `FB13_THRUM` Audio event per trigger;
- full Replay resets transient companion presence only; P06 mapped knowledge survives intact; Mission 03 Memory Echo payload/order unchanged;
- no generalized companion AI, navmesh, `NavigationAgent3D`, companion manager, inventory, combat, or audio changes.

## Production 08 verification truth

### Frozen feature head

At `892c8eb0e32602b7974f2281ce9a81d0141abcf5`:

- exact-source P08 semantics/runtime: **PASS**;
- companion vehicle docking (Bike/Hauler mount, dock, rejected dismount, release): **PASS**;
- companion Thrum composition, Replay, P06 durability, Mission 03 regression: **PASS**;
- retained P01–P07 focused regressions (18 test suites): **PASS**;
- windowed rendered proof (6 screenshots + JSON report telemetry): **PASS and directly inspected**;
- literal-head Web export/static-host smoke: **PASS**;
- synthetic-merge Web export/static-host smoke: **PASS**;
- current camera contracts + canonical 29-suite compatibility matrix: **PASS**.

Independent two-axis review (Standards + Spec) was completed on the feature diff and followed by a dedicated review-polish cycle (PR #145), resolving:
- **Standards Axis**: Godot 4 typed signals (`node.signal_name.connect(...)`), variable declaration ordering (`@onready` after regular variables), vector math deduplication for follow target offsets, space state extraction helper `_get_space_state()`, and defensive null guards on Runner dereferences.
- **Spec Axis**: Linear dock interpolation via cached `_dock_start_transform`; outward 32px viewport boundary expansion (`vp_rect.grow(32.0)`) eliminating visual pop-in / mesh boundary edge clipping; Spec line 99 remain-in-place on failed hard rejoin; strict alignment of dock release to vehicle dismount; modeled `hs7_state: "CARRIED"` in runtime snapshot; full test coverage for Spec lines 279 (alternate follow target selection) and 281 (hard rejoin suppression under full staging ring occlusion); mobile viewport framing capture (`07_mobile_viewport_framing.png` at 400x700).

### Exact-main verification

Initial gameplay merge: `fb63d9ee853aed0e49b2c6b52edfff31cf43fda7`  
Post-review polished gameplay merge (PR #145): `37c130b10db057ba923d5a9a6738081fa91e6fdf`

Production-08 exact-main run `34160830753`:

- exact source checkout at `37c130b10db057ba923d5a9a6738081fa91e6fdf`: **PASS**;
- P08 semantics / runtime / docking / thrum: **PASS**;
- retained P01–P07 matrix (including camera mount transition and dynamic camera follow): **PASS**;
- exact-main rendered proof capture/upload (7 screenshots including mobile viewport framing): **PASS**;
- artifact `production08-rendered-proof-37c130b10db057ba923d5a9a6738081fa91e6fdf`.

Godot Web Playtest main push run `34160816224`:

- exact source checkout: **PASS**;
- mobile touch routing / desktop controls / vehicle authority / interaction cancel: **PASS**;
- Web export: **PASS**;
- static-host smoke: **PASS**;
- public `playtest-web` publication: **PASS**.

Public source stamp:

`playtest-web/PLAYTEST_BUILD.txt = 37c130b10db057ba923d5a9a6738081fa91e6fdf`

## Production 09 — verified player-facing result

Issue #149 / PR #150: **COMPLETE / MERGED / VERIFIED**.

Exact gameplay merge:

`069e7f3c504cc5a088577bcd1c5efc21b125f23f`

Player-facing contract:

`DANGER -> ARMOR ABSORBS FIRST -> HEALTH TAKES READABLE DAMAGE -> ESCAPE / RECOVER -> RE-ENGAGE`

At Health depletion:

`SOFT FAILURE -> IMMEDIATE DANGER ENDS -> SAFE RECOVERY -> HORIZONTAL PROGRESS REMAINS TRUSTWORTHY`

Retained truths:

- `PlayerRunner` is the single Health / Armor arithmetic authority;
- Health is bounded to 100 and Armor to 50; current tracer begins with 25 Armor;
- Armor absorbs incoming damage first; remainder spills into Health;
- a 0.55 s damage-immunity window prevents one contact from frame-spamming damage;
- pursuer interception is the first retained real damage source at 35 damage per accepted catch;
- safe passive Health recovery begins only after 3.0 s out of immediate danger, restores 12 HP/s, caps at 65, and never restores Armor;
- repeated real catches are verified through `90 -> 55 -> 20 -> 0`;
- Soft Failure restores 60 Health / 0 Armor at retained recovery geography without calling the broad slice reset;
- pursuit-context Soft Failure returns to `RETRY_READY`; non-pursuit depletion returns to `CALM`;
- surveyed route knowledge and authored mission phase survive Soft Failure;
- `VitalsHUD` is mounted under retained `SafeAreaRoot` and is pointer-transparent;
- full manual Replay may reset default vitals, while Soft Failure preserves horizontal progression;
- no firearms, enemy shooting, generalized NPC health/death, medical inventory, armor rarity, perks, levels, loot system, or generalized damage framework entered P09.

Verification on final feature head `979f006b346931e75ff80a67953774602b625811`:

- Production 09 exact-source Health / Armor / Soft Failure gate: **PASS**;
- repeated-interception and non-pursuit-context falsification: **PASS**;
- retained street combat / touch routing / mapped-route persistence: **PASS**;
- Camera Feel, Wanted, Production 04/05/07/08 workflows: **PASS**;
- literal-head Web export: **PASS**;
- synthetic-merge Web export: **PASS**;
- canonical exact-head 29-suite compatibility matrix: **PASS**;
- direct self-review: **PASS**; no Codex review was requested.

## Post-Production-09 re-evaluation state

Production 09 closes the highest-ranked post-P08 danger/depth gap without expanding combat into an RPG or generalized hostile-AI framework. The strongest next bounded product gap is now **authored relationship / Standing consequence**.

The canonical Factions & Reputation Contract (#107) keeps this simple: meaningful Contacts and a few organizations may change concrete treatment/access; no universal morality meter, global faction matrix, point farming, territory conquest, or hidden reputation grind.

Leading credible next gaps to compare:

1. **authored relationship / Standing consequence** — one meaningful completed job should visibly change later treatment, service, access, or route opportunity; Mayor Burn and his existing Garage are the strongest retained seam;
2. **vehicle claiming / identity** — P07 gives vehicle condition and repair meaning, but ownership/claiming remains unaddressed and carries more persistence/schema/UX cost;
3. **deeper authored city mastery** — another learned shortcut/access payoff only if it creates a distinct decision rather than GPS expansion;
4. **moment-to-moment vehicle feel / authored escape pressure** — improve retained Heat-1 chase feel only from observed weakness;
5. **next combat breadth** — firearms/enemy ranged danger remain canonical later possibilities, but should not outrank the smaller relationship consequence by momentum alone.

Heat 2–5, generalized witnesses/surveillance, transit, broader geography, generalized faction/reputation architecture, generalized persistence, Garage networks, broad economy, companion navigation, generalized hostile AI, and weapon inventories remain later candidates unless current play proves they outrank smaller authored gains.

## Retained foundations / deferred lanes

Do not recreate retained Feel tickets #12–#16, Missions 01–03, Open World Expansion 01A–01D, World Event 01 / PR #68, or Productions 01–09 because older roadmaps describe them historically.

FB-13 / HS-7 companion presence is now embodied in production gameplay. Do not add generalized companion AI or navmesh frameworks.

Audio Production remains a first-class parallel lane. Refresh live Audio branches/PRs before shared-scene/audio mutation. Actual perceptual audio claims require playback evidence.

PR #44 — CTW Feel 03 camera occlusion readability — remains **DEFERRED** unless fresh evidence materially changes priority.

## Verification / human-gate debt

Still not completed unless fresh evidence says otherwise:

- native desktop average/P95 frame-time qualification on dedicated desktop hardware;
- broader fresh-player perceptual qualification;
- physical touch-conditioner A/B before changing touch steering defaults;
- human/windowed listening where actual playback quality is the question;
- real mobile performance until measured on hardware.

Small reversible production increments may continue when they do not depend on those unanswered gates. The owner explicitly chose the momentum policy: small reversible increments may merge with remaining debt visible, but map expansion must prioritize authored content on existing geography before adding acreage.

## Scope discipline

- Do not reopen retained camera, steering, vehicle feel, pursuit, audio, Signal Gate, target arbitration or replay foundations without an observed weakness.
- Mission 01/02/03 remain precedent for **small authored adapters over retained production state**, not permission to build a generalized quest graph/database, persistent economy, inventory, combat, wanted-system rewrite, save-slot campaign framework, destination framework or unrelated infrastructure.
- World Event 01 is precedent for a **small local authored reaction over retained systems**, not permission to build a generalized companion AI, network event bus or world-event registry.
- Preserve approved visual canon; do not reinterpret reference material against the approved direction.
- **3D Asset Modeling & Texturing Standard**: Enforce authentic video-game industry / GTA-grade 3D modeling and texturing across all assets, vehicles, clutter, and architecture (`docs/visual_direction/ASSET_MODELING_AND_TEXTURE_STANDARD.md`). Box primitives, stacked cubes, and flat painted-car billboard textures are strictly banned. All vehicles and complex assets must use the 4-part modular industry pipeline:
  1. Multi-material body separation (`Mat_Paint`, `Mat_Glass`, `Mat_Rubber`, `Mat_Chrome`/`Mat_Steel`, `Mat_Interior`, `Mat_Emissive`).
  2. UV seams cut along real vehicle panel shut lines (doors, hood, trunk, fenders) to eliminate curved surface stretching.
  3. Shared vehicle trim sheet (`tex_vehicle_trim.png`) for headlights, taillights, grilles, license plates, and badges.
  4. Decal & Livery Layer: pure vector stencils/markings on 100% transparent PNGs with ZERO pre-baked 3D shadows, fake lighting, or drawn wheels/windows, blended over clean car paint in Godot cel shader.
- Keep Issue #60's `GearsStyleProof` separate from production geography; it remains a bounded proof/foundation layer rather than the district scene itself.
- Prefer useful density and authored destinations/events over empty acreage.
- Do not add more Gears acreage as the automatic next step.

## Current product direction

Issue #55 remains the durable product-intent anchor even though its old “stop before Gears implementation” snapshot is now historically superseded by the approved visual package and merged 01A-01D work.

Its still-current sequencing rule is the important one:

> after the district foundation, prefer new authored missions / world events that exploit the expanded geography before expanding the map again.

World Event 01 has now exercised that rule once with a bounded FB-13 industrial-frontage reaction. The next autonomous increment must be re-evaluated from current `main` rather than automatically creating another event.

Prefer, in order:

1. a dedicated verification-debt checkpoint when the runtime/browser/windowed capability needed for retained-camera capture, measured desktop performance or human listening is actually available;
2. otherwise, another small authored mission/world event only if it has clearly stronger visible product value than the accumulated verification debt and uses existing geography without creating a generalized framework;
3. new acreage only after representative readability/performance debt is resolved or there is a concrete product requirement that outweighs that risk.

Do not choose historical open tickets merely because they remain open. Several are retained experiments, human/perceptual gates or already-landed foundations whose issue state is not the live product order.

## Production 10 — verified player-facing result

Issue #152 / PR #154: **COMPLETE / MERGED / EXACT-MAIN VERIFIED / PUBLIC VERIFIED** pending only this continuity merge and issue closure.

Exact gameplay merge:

`668e760b7da48df33552e182ff3af8bab9d53640`

Player-facing loop:

`COMPLETE CIVIC REPOSSESSION -> BURN KNOWS YOU -> RETURN TO BURN GARAGE ON FOOT -> ARMOR STASH AVAILABLE -> RESTOCK EXPENDABLE ARMOR -> LEAVE`

Wanted remains authoritative:

`ACTIVE WANTED -> BURN SERVICE LOCKED`

Retained truths:

- `MayorBurnContactProgressStore` owns one versioned durable relationship milestone: `UNESTABLISHED` -> `KNOWN`;
- Civic Repossession completion marks Burn `KNOWN` exactly once and leaves persistence/service authority outside the mission;
- `KNOWN` survives Replay and relaunch/store reconstruction;
- malformed or newer unsupported Contact data fails safe and is not silently overwritten;
- the existing Burn Garage `MissionDestinationSocket` owns the bounded armor-stash service seam;
- service requires Burn `KNOWN`, Runner on foot, Armor below `PlayerRunner.MAX_ARMOR`, Wanted heat 0/state `CLEAR`, and physical presence inside the Garage service radius;
- accepted service sets Armor exactly to MAX while leaving Health unchanged, charges no money and creates no inventory item;
- unknown Contact, mounted state, full Armor, Wanted CONTACT and Wanted SEARCH reject service;
- existing P07 vehicle repair remains separate and unchanged;
- bounded `ARMOR RESTOCKED` confirmation yields to fresh Wanted state and is cancelled by fresh damage;
- no generalized Standing/faction/reputation/contact database, economy, armor inventory, medical service, firearms or new acreage entered P10.

Feature-head verification on PR #154:

- exact-source Burn Contact / Armor Stash: **PASS**;
- exact-source P09 Health / Armor / Soft Failure: **PASS**;
- P07 semantics/runtime and retained P01-P06 regressions: **PASS**;
- Mission 02 composition: **PASS**;
- literal-head and synthetic-merge Web export/static-host smoke: **PASS**;
- exact-head canonical compatibility matrix: **PASS**.

### Public Web publication migration and exact-main verification

The retained generated-build force-push to `playtest-web` became invalid once the production Web payload exceeded GitHub's normal Git-object limit:

- `index.pck`: 237,995,244 bytes (~227 MiB);
- unpacked Web site: 279,587,872 bytes (~267 MiB).

PR #155 migrated generated public publication only to GitHub Pages Actions artifacts. No gameplay, canon, save, audio, asset or runtime code changed.

Current verified public baseline:

`86a05de0a9adaf4a8e81aa5e8a299b03ed99ed63`

Godot Web Playtest main-push run `35433857979` at that exact SHA:

- main Web export: **PASS**;
- static-host smoke: **PASS**;
- source revision stamp before packaging: **PASS**;
- public payload envelope: **PASS**;
- GitHub Pages artifact upload: **PASS**;
- Pages deployment: **PASS**;
- public `PLAYTEST_BUILD.txt` convergence to exact main SHA: **PASS**;
- public `index.html` and `index.pck` reachability check: **PASS**.

Current public provenance:

`PLAYTEST_BUILD.txt = 86a05de0a9adaf4a8e81aa5e8a299b03ed99ed63`

The newer SHA is CI/publication-only relative to P10 gameplay. Exact P10 gameplay remains `668e760b7da48df33552e182ff3af8bab9d53640`.

## Post-Production-10 re-evaluation state

Production 10 closes the smallest authored relationship/Standing consequence: completing meaningful work for Burn now produces a durable later privilege at the Garage without introducing a generalized reputation system.

Fresh current-main inspection selects **one bounded Claimed Vehicle / Garage ownership tracer** as the leading next gameplay frontier.

Why it leads:

- the canonical Vehicle Sandbox Contract distinguishes disposable Street Vehicles from deliberately Garage-owned Claimed Vehicles;
- P07 already made the Courier Bike and Scrap Hauler materially damageable/repairable at Burn's Garage;
- P10 gives Burn a durable authored relationship state and makes the Garage a stronger progression seam;
- current runtime still has no claimed-vehicle ownership/recovery persistence;
- the Courier Bike is the smallest credible first ownership proof because it is retained production, has strong player identity, integrates with FB-13 docking, and avoids Mission-02 Scrap Hauler ownership ambiguity.

Leading bounded P11 design target:

`BURN KNOWN -> BRING COURIER BIKE TO GARAGE -> CLAIM -> DURABLE OWNERSHIP -> REPLAY / RELAUNCH -> CLAIM REMAINS -> ORDINARY LOSS -> RECOVERABLE AT GARAGE`

Guardrails:

- one Courier Bike only for the first tracer;
- claim intentionally at Burn's Garage rather than on first mount;
- preserve spontaneous Street Vehicle use and swapping;
- no fleet manager, garage slot UI, vehicle catalog, broad economy, customization tree, insurance, generalized save framework or vehicle-base rewrite;
- do not silently persist ordinary P07 condition unless the approved claim/recovery contract explicitly requires a narrow rule;
- claimed ownership remains Durable Progress across Replay/Soft Failure and ordinary sandbox loss;
- Wanted, mission, companion docking, P07 repair and P10 Contact authority remain independent;
- no new acreage required.

Vehicle claiming is **SELECTED FOR JIT DESIGN / NOT YET IMPLEMENTATION-LOCKED** until the narrow P11 ticket/spec is created from refreshed main.

## Production 11 — verified player-facing result

Issue #158 / PR #159: **COMPLETE / MERGED / EXACT-MAIN VERIFIED / PUBLIC VERIFIED** pending only this continuity merge and issue closure.

Exact reviewed feature head:

`f56119aea0431050ea96cc3f5bb48917c3381728`

Exact gameplay/public main:

`af5eaa77101163293bd0e8cefff8ee80605306d3`

Player-facing loop:

`BURN KNOWN -> BRING COURIER BIKE TO BURN GARAGE -> PARK / DISMOUNT -> CLAIM -> OWNERSHIP PERSISTS -> BIKE LEFT AWAY -> RETURN TO GARAGE -> RECOVER -> RIDE OUT`

Retained truths:

- one versioned `CourierBikeClaimProgressStore` owns exactly `UNCLAIMED` / `CLAIMED`;
- deliberate claim requires Burn `KNOWN`, Wanted `CLEAR`, Runner on foot, and the stopped Courier Bike in the authored claim bay;
- claim is free in P11 and writes exactly once;
- claiming does not repair existing P07 vehicle condition or mutate vitals/Wanted/missions/mapped knowledge/Burn Contact;
- the authored `CourierBikeClaimSocket` is spatially distinct from the retained P07/P10 Garage service seam;
- recovery reuses the same production Courier Bike instance, requires the claimed Bike to be unoccupied and materially away from the Garage, and restores a legal `PARKED / ROADWORTHY` state;
- full Replay and fresh store reconstruction retain ownership and restore Reliable Access at Burn's Garage;
- Soft Failure retains ownership **without summoning the claimed Bike**;
- the strengthened P11 integration test waits through the real 0.8 s Soft Failure recovery callback and exercises retained Action target arbitration for both claim and recovery;
- ordinary Street Vehicle freedom remains intact; no fleet manager, garage slots, wallet, vehicle catalog, insurance, remote summon, customization tree, generic identity registry or generic save framework entered P11;
- Mission-02 Scrap Hauler ownership remains intentionally untouched.

TDD / frozen-review evidence:

- observed RED run `35456618741`: exact-source setup passed and the missing P11 persistence seam failed as intended;
- initial GREEN exposed a test parse error, repaired;
- frozen review correctly found a false-positive Soft Failure test and a checkout-credential hardening gap;
- repaired exact-source run `35462593934` at final head: persistence **PASS**, strengthened claim/recovery composition **PASS**, retained Garage/FB-13/survivability/P10/Mission-02 regressions **PASS**;
- CodeRabbit security finding addressed with `persist-credentials: false`;
- all review threads resolved before merge.

Final feature-head PR matrix at `f56119aea0431050ea96cc3f5bb48917c3381728`:

- exact-source P11: **PASS**;
- P07 semantics/runtime + rendered proof: **PASS**;
- P08 semantics/runtime: **PASS**;
- P09 Health / Armor / Soft Failure: **PASS**;
- P10 Burn Contact / Armor Stash: **PASS**;
- retained P01-P07 regression matrices: **PASS**;
- Wanted Heat-1 / work-zone / surveyed-service-cut / scrapper-tool: **PASS**;
- literal-head Web export/static-host smoke: **PASS**;
- synthetic-merge Web export/static-host smoke: **PASS**;
- Web persistence head + merge: **PASS**;
- Pages artifact packaging: **PASS**;
- exact-head canonical 29-suite compatibility matrix: **PASS**;
- CodeRabbit final status: **PASS**.

### Exact-main and public verification

The merge commit is one commit ahead of the fully-tested feature head with **no file diff**, proving exact merged content matches the frozen reviewed head.

Godot Web Playtest main-push run `35462826584` at `af5eaa77101163293bd0e8cefff8ee80605306d3`:

- exact source revision checkout: **PASS**;
- mobile touch / desktop controls / alias ownership / vehicle authority / interaction cancel: **PASS**;
- Web export: **PASS**;
- static-host smoke: **PASS**;
- browser artifact upload: **PASS**;
- public payload envelope: **PASS**;
- GitHub Pages artifact upload: **PASS**;
- Pages deployment: **PASS**;
- public source revision stamp verification: **PASS**.

Current public provenance:

`PLAYTEST_BUILD.txt = af5eaa77101163293bd0e8cefff8ee80605306d3`

## Post-Production-11 re-evaluation state

Production 11 closes the first Claimed Vehicle / Reliable Access ownership proof. The strongest next bounded progression gap is now **real Cash authority and one honest spend loop**.

Fresh implementation inspection shows a concrete inconsistency worth fixing before broader economy work:

- no wallet/Cash authority exists in the repo;
- `PropStreetVendor` advertises `TUNE_UP_COST = 150` and emits a purchase signal, but currently performs no debit/check;
- `PropVendingMachine` emits nominal scrap rewards of 80 for hacking and 120 for breach/ram, but no authoritative balance is credited;
- vehicle tune-up physics already exist and are verified on Courier Bike / Muscle Coupe;
- therefore the world currently presents an economy-shaped loop that is not economically real.

Leading bounded P12 design target:

`EARN REAL CASH -> BALANCE CHANGES -> APPROACH STREET VENDOR WITH VEHICLE -> PAY 150 -> BALANCE DECREASES -> TUNE-UP APPLIES -> INSUFFICIENT CASH REJECTS CLEANLY`

P12 must resolve, before implementation lock:

- whether first Cash is Durable Progress across Replay/relaunch or attempt-local disposable resource;
- if durable, how existing 80/120 vending rewards avoid replay/reset farming;
- which single earning source gives the clearest first proof without creating a generalized loot/economy framework;
- where the minimal balance presentation lives and when it recedes;
- whether the vendor transaction owns only the payment seam while retained tune-up physics stay unchanged.

Guardrails:

- one authoritative Cash balance only;
- one earning path + one Street Vendor spend path for the first tracer;
- no XP, levels, rarity tiers, shop catalog, inventory, dynamic prices, rent, fuel, maintenance chores, loot tables, broad merchant framework or economy simulation;
- do not make P07 repair or P10 relationship armor service paid retroactively;
- do not turn nominal prop reward signals into authority without anti-duplication semantics;
- no new acreage required.

P12 is **SELECTED FOR JIT DESIGN / NOT YET IMPLEMENTATION-LOCKED**.

## Production 12 — verified player-facing result

Issue #161 / PR #162: **COMPLETE / MERGED / EXACT-MAIN VERIFIED / PUBLIC VERIFIED** pending only this continuity merge and issue closure.

Final reviewed feature head:

`00357dab13786a4eae1b1a7198906316178414d7`

Exact gameplay/public main:

`a7abf55282cff8d7daad81a9a8624ee61364d528`

Player-facing loop:

`HACK / BREACH UNIQUE TERMINAL -> REAL DURABLE CASH -> STREET VENDOR -> PAY 150 -> ACTIVE VEHICLE TUNE-UP -> REAL BALANCE`

Retained truths:

- one versioned `BurnsideCashProgressStore` owns a non-negative integer Cash balance plus two durable one-time receipts for the unique vending terminal;
- first valid hack pays exactly **80 Cash** once;
- first valid breach pays exactly **120 Cash** once;
- invalid reward amounts are rejected before any balance mutation or receipt consumption;
- Cash and receipts survive Replay, Soft Failure and fresh store reconstruction;
- the physical vending machine may reset for sandbox repeatability, but already-paid receipts yield no duplicate Cash and no false “+Cash” feedback;
- the Street Vendor now requires and debits exactly **150 Cash** before applying retained tune-up physics;
- insufficient Cash, no supported active vehicle, rammed/untradeable vendor and already-active tune-up reject without debit;
- successful purchase tunes only the actual active vehicle and leaves inactive retained vehicles unchanged;
- Cash feedback uses a short-lived player-visible notice rather than relying on debug telemetry;
- P07 repair, P10 armor restock and P11 vehicle recovery remain free and independent;
- no XP, levels, inventory, shop catalog, loot economy, dynamic pricing, recurring costs, bank/debt, multiple currencies or broad reward registry entered P12.

TDD / review evidence:

- observed RED run `35501458355`: exact-source setup passed; Durable Cash persistence failed because the store did not exist;
- first GREEN established real Cash authority but exposed a player-feedback defect because the debug status label was overwritten;
- repaired branch run `35501748893`: persistence, physical earn/spend composition, truthful Cash notice and retained vendor/vending/P08–P11 regressions **PASS**;
- CodeRabbit review found the store accepted arbitrary positive reward amounts, which could consume a one-time receipt incorrectly;
- final repair `00357dab13786a4eae1b1a7198906316178414d7` added fixed 80/120 store-level reward contracts plus tests proving invalid 81/119 inputs neither mutate balance nor consume receipts;
- the stale P09 canonical header/sequence identified by the earlier P11 continuity review was also corrected on the same final branch;
- all review threads are resolved; CodeRabbit final status is **PASS**.

Final feature-head matrix:

- P12 exact-source Durable Cash / Street Vendor: **PASS**;
- P11 Claimed Courier Bike / Garage Recovery: **PASS**;
- P10 Burn Contact / Armor Stash: **PASS**;
- P09 Health / Armor / Soft Failure: **PASS**;
- P08 companion semantics/runtime: **PASS**;
- P07 semantics/runtime + rendered proof: **PASS**;
- retained P01–P07 regression matrices / Wanted / work-zone: **PASS**;
- literal-head Web export/static-host smoke: **PASS**;
- synthetic-merge Web export/static-host smoke: **PASS**;
- Pages artifact packaging: **PASS**;
- exact-head canonical 29-suite compatibility matrix: **PASS**.

### Exact-main and public verification

The squash merge and fully tested feature head have the exact same Git tree:

`5ac85615a33243cb6857615debc5697768e24146`

Godot Web Playtest main-push run `35552778723` at `a7abf55282cff8d7daad81a9a8624ee61364d528`:

- exact source revision checkout: **PASS**;
- retained mobile touch / desktop controls / alias ownership / vehicle authority / interaction cancel: **PASS**;
- Web export: **PASS**;
- static-host smoke: **PASS**;
- browser artifact upload: **PASS**;
- public payload envelope: **PASS**;
- GitHub Pages artifact upload: **PASS**;
- Pages deployment: **PASS**;
- public source revision stamp verification: **PASS**.

Current public provenance:

`PLAYTEST_BUILD.txt = a7abf55282cff8d7daad81a9a8624ee61364d528`

## Post-Production-12 re-evaluation state

Production 12 establishes the first honest authoritative Cash earn/spend loop. The next high-value economy gap is **authored mission payoffs that still advertise credits without crediting the durable Cash authority**.

Verified retained mission values:

- Scrap Job / Mission 01: **320** credits;
- Civic Repossession / Mission 02: **450** credits;
- The City That Forgot / Mission 03: intentionally **0**.

The preferred next bounded frontier is therefore **durable one-time Mission 01 + Mission 02 Cash receipts**, not broad conversion of every resettable street prop reward.

Leading P13 design target:

`COMPLETE AUTHORED JOB -> CREDIT CONTRACT PAYOUT ONCE -> CASH PERSISTS -> REPLAY MISSION FOR GAMEPLAY -> NO DUPLICATE PAYOUT / NO FALSE PAYMENT CLAIM`

Why this leads:

- mission payouts are already authored and visible to the player;
- missions are better primary Cash sources than repeatable street farming under the Progression & Economy Contract;
- durable payout receipts can prevent Replay/relaunch farming while preserving mission replayability;
- Mission 03’s zero-pay narrative scope stays intact;
- utility crawler, dumpster, lockbox and kiosk “scrap” semantics remain separate until intentionally reconciled rather than silently becoming Cash.

Guardrails for P13 JIT design:

- exactly the existing Mission 01 and Mission 02 authored payouts first;
- one durable paid receipt per mission;
- Replay may reset mission gameplay but never pays the same authored contract twice;
- payment presentation must distinguish contract completion from an already-cleared payout;
- no generalized quest ledger, repeatable-job economy, loot conversion, shop framework or reward registry;
- do not change Mission 03’s zero-Cash narrative completion;
- no new geography or unrelated Audio changes.

P13 is **SELECTED FOR JIT DESIGN / NOT YET IMPLEMENTATION-LOCKED**.

## Next-state rule

Next production session:

1. refresh exact `main`, open PRs/issues, CI/public Pages provenance and concurrent Audio/shared-scene state;
2. read `START_HERE.md`, #55, #118, the Progression & Economy Contract (#105 resolution), and this continuity file;
3. verify local repo/branch/HEAD/upstream/dirty state before local code mutation;
4. create/refine one just-in-time Production 13 ticket for **durable Mission 01 / Mission 02 Cash payout receipts**;
5. resolve payout receipt ownership, replay presentation and exact mission-completion integration before GREEN implementation;
6. keep Mission 03 at zero Cash and leave resettable street-prop scrap semantics intentionally separate;
7. execute `SPEC -> RED -> GREEN -> exact-head VERIFY -> frozen REVIEW -> REPAIR if needed -> MERGE -> exact-main VERIFY -> PUBLIC STAMP`;
8. update continuity only after verified changes land.

Create a new Wayfinder only for a genuinely new, foggy, multi-session cross-system design problem. `WAYFINDER_MAP.md` remains historical architecture context, not the live status tracker.
