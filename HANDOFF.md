# HANDOFF.md — Current Product Continuity

**Status:** `BURNSIDE_P20_SISTER_KAEL_WITNESS_MERGED_VERIFIED_PUBLIC`  
**Current gameplay/world baseline:** `e4029fd06bfafc3fdc8ac158b7c39a17372a8d34`  
**Immutable Feel baseline:** `09fa2b0ab8aebc8a2ae54b989bffad7720503e48`  
**Engine:** Godot 4.7.1 Stable

> Continuity only. Refresh remote `main`, open PRs/issues, CI, public-playtest state, and any concurrent Audio/shared-scene work before repo-sensitive claims. A later docs-only continuity merge may make repository HEAD newer than the exact verified gameplay/public baseline above without changing runnable gameplay.

## Current product state

Burnside now has one dense qualified Gears production block where authored missions, Heat-1 Wanted / Contact-Search, local Field Hacking, civic reporting, reactive work-zone actors, the Scrapper Tool, physical pursuer counterplay, Player Health / expendable Armor / Soft Failure, durable mapped route knowledge, coarse vehicle condition, one bounded Burn Garage repair loop, authored FB-13 / HS-7 companion presence, one authoritative durable Cash loop with one-time authored Mission 01 / Mission 02 payouts, one durable claimed-Courier-Bike Scrap Bash Bar modification, one bounded checkpoint-local memory of a claimed Bike breach, one physical Mission-03 memory-disclosure aftermath choice, one session-local Gears retrofit sidearm with bounded gunfire consequence, one physical Mayor Burn Garage presence with a bounded KNOWN-contact face-to-face encounter, one bounded ranged sidearm suppression response against the retained physical Wanted pursuer, and one physically present Sister Kael who silently witnesses and automatically reacts to the retained Mission-03 RELEASE / SEAL aftermath choice compose in the same geography.

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
- **Production 13** — #164 / PR #165 — Durable Mission 01 / Mission 02 Cash Payout Receipts — `3225b00318351f351c76d4ce3dc2894766ce654c`.
- **Production 14** — #167 / PR #170 — Claimed Courier Bike / Burn Garage Scrap Bash Bar — `4b563ff66d0e65f787e710af53d1c9d81209cbe3`.
- **Production 15** — #172 / PR #173 — Gears Checkpoint / Claimed Courier Bike Recognition — `9708686f5f5a8cd9f606b238186aca9f3e999cc1`.
- **Production 16** — #175 / PR #176 — The City That Forgot / Memory Disclosure Choice — `b96f81264144386bd3fc3a1c77d330b7af3af531`.
- **Production 17** — #179 / PR #180 — Gears Retrofit Sidearm / Gunfire Consequence Tracer — `ecaaa903a5fe5bb1e180a9b64b1ed23ae4ebc90e`.
- **Production 18** — #182 / PR #183 — Mayor Burn Physical Garage Presence / Known-Contact Encounter — `1cdbda2fcbcb53ec62af73514b3b396554277017`.

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
- P05 itself introduced no Player Health/Armor. Production 09 now supplies the separate retained PlayerRunner survivability authority. Production 17 now adds one bounded session-local retrofit sidearm; weapon rosters, generic NPC damage/death, generalized hostile combat AI, inventory/loot/RPG stats, Heat 2–5, generalized witness/crime frameworks, and unrelated Audio expansion remain absent.

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
5. **next combat breadth** — this historical pre-P17 lane is now partially fulfilled by P17's one bounded sidearm; enemy ranged danger and broader weapon breadth remain future possibilities and must still earn priority from play.

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

## Production 13 — verified player-facing result

Issue #164 / PR #165: **COMPLETE / MERGED / EXACT-MAIN VERIFIED / PUBLIC VERIFIED / CONTINUITY UPDATED / ISSUE CLOSED**.

Final reviewed feature head:

`8bdc08ecba0526e0f72ee7b53a1a1c771fe9b575`

Exact gameplay/public main:

`3225b00318351f351c76d4ce3dc2894766ce654c`

Exact source tree shared by the final reviewed feature head and squash merge:

`611d22e8963860d763c1d27aaa451c41eacd8796`

Player-facing loop:

`COMPLETE MISSION 01 -> +320 CASH ONCE -> COMPLETE MISSION 02 -> +450 CASH ONCE -> CASH PERSISTS -> REPLAY / RELAUNCH -> MISSIONS REMAIN PLAYABLE -> PAYOUT DOES NOT REPEAT`

Retained truths:

- `BurnsideCashProgressStore` remains the only durable Cash authority;
- its schema evolves from v1 to v2 by adding exactly `mission_01_paid` and `mission_02_paid` beside retained `cash`, `vending_hack_paid`, and `vending_breach_paid`;
- valid v1 migration preserves existing Cash and vending receipts exactly, initializes the two mission receipts false, and persists through the retained staging + atomic-rename path;
- malformed data fails closed; unsupported newer schema fails closed and is not overwritten;
- Mission 01 / Scrap Job pays exactly **320 Cash once**;
- Mission 02 / Civic Repossession pays exactly **450 Cash once**;
- first-time completion of both authored paid missions therefore yields **770 Cash** total;
- Mission 03 / The City That Forgot remains intentionally **0 Cash**;
- Mission 01 adds one bounded production completion signal; Mission 02 reuses retained `civic_repossession_completed`;
- mission runtimes retain mission authority; Cash runtime owns only payout validation, durable receipt consumption, balance mutation, and payout feedback;
- first payment notices remain `JOB PAID // +320 CASH // BALANCE X` and `BURN PAID // +450 CASH // BALANCE X`;
- replay/relaunch after a durable receipt reports `PAYMENT ALREADY CLEARED // BALANCE X` and never falsely presents another +320 or +450;
- a fresh production scene and newly configured Cash runtime reload 770 + both receipts and reject both duplicate payouts;
- invalid mission reward values cannot mutate Cash or consume receipts;
- manual/test-only Mission 01 phase mutation does not independently grant Cash;
- P12 vending hack remains +80 once, vending breach +120 once, and Street Vendor tune-up exactly 150 debit;
- P07 Garage repair, P10 Burn armor restock, and P11 claimed Courier Bike recovery remain free;
- Mayor Burn Contact remains independent of Mission 02 Cash payout;
- Full Replay and Soft Failure preserve durable Cash mission receipts;
- no repeatable mission economy, generalized reward/quest ledger, XP/levels, inventory, extra currency, new shop/geography, or unrelated Audio change entered P13;
- PR #44 remains deferred.

### TDD / frozen review truth

Observed intended RED workflow run `36087421215` failed because the P13 Cash-store Mission 01 API and bounded Mission 01 completion signal did not yet exist. A retained Mission 03 contract was also initially invoked through the wrong SceneTree harness shape; that was a test-harness/configuration issue, not a Mission 03 regression.

Frozen review then found and repaired three concrete issues before the final head:

1. P13 workflow dependency/path coverage was broadened to include relevant mission constants, composition sources, and retained tests;
2. browser persistence proof now waits for actual `FS.syncfs` completion before publishing `P13_WRITE_OK`;
3. the replay proof now destroys the original production scene, instantiates a fresh scene/runtime, reloads durable receipts, and replays both missions through fresh production runtimes.

Final frozen-head evidence:

- Burnside Production 13 run `36126903937`: **SUCCESS**;
- retained Burnside Production 12 regression run `36126903938`: **SUCCESS**;
- Godot Web Playtest run `36126903993`: **SUCCESS**, including literal-head and synthetic-merge Web, current camera contracts, canonical compatibility matrix, retained combat/checkpoint/survivability, and Pages packaging;
- CodeRabbit final status: **SUCCESS**;
- previously posted inline review threads: **RESOLVED**;
- Copilot review was unavailable because its review quota was exhausted; this is neither an approval nor a blocker.

### Exact-main and public verification

The final reviewed feature head `8bdc08ecba0526e0f72ee7b53a1a1c771fe9b575` and squash merge `3225b00318351f351c76d4ce3dc2894766ce654c` resolve to the exact same Git tree:

`611d22e8963860d763c1d27aaa451c41eacd8796`

Burnside Production 13 main-push run `36127323010` at the exact gameplay merge:

- exact source checkout: **PASS**;
- P13 schema v2 / migration / receipt tracer: **PASS**;
- production mission payout / replay tracer: **PASS**;
- retained P12 Cash earn/spend regressions: **PASS**;
- retained mission/service regressions: **PASS**;
- same-origin browser relaunch persistence: **PASS**.

Godot Web Playtest main-push run `36127322961` at the same gameplay SHA:

- exact source checkout: **PASS**;
- retained mobile touch / desktop controls / alias ownership / vehicle authority / interaction cancel: **PASS**;
- Web export: **PASS**;
- static-host smoke: **PASS**;
- browser artifact upload: **PASS**;
- public payload envelope: **PASS**;
- GitHub Pages artifact upload: **PASS**;
- Pages deployment: **PASS**;
- deployment-time public HTTP source-stamp verification: **PASS**.

The canonical 29-suite compatibility job is intentionally pull-request-only in the retained Web workflow, so it is **SKIPPED on main push by workflow design**, not reported as an exact-main execution. It passed on the frozen P13 source tree in run `36126903993`; exact Git-tree equality proves the same reviewed source tree was squash-merged.

Latest verified public provenance:

`PLAYTEST_BUILD.txt = 3225b00318351f351c76d4ce3dc2894766ce654c`

GitHub Pages deployment URL:

`https://johnnymaconny.github.io/art/`

## Production 14 — verified player-facing result

Issue #167 / PR #170: **COMPLETE / MERGED / EXACT-MAIN VERIFIED / PUBLIC VERIFIED / CONTINUITY UPDATED / ISSUE CLOSED**.

Final reviewed feature head:

`a534d7a0e945e9330c7ab6bc84ce37ac159ecc01`

Exact gameplay/public main:

`4b563ff66d0e65f787e710af53d1c9d81209cbe3`

Exact Git tree shared by the final reviewed feature head and squash merge:

`40b3af0a6d8e92e218e234e8cbbfe2681250a70e`

Player-facing loop:

`DO PAID WORK -> BUILD CASH -> CLAIM COURIER BIKE -> RETURN TO BURN GARAGE -> FIT SCRAP BASH BAR FOR 500 CASH -> BIKE CHANGES VISIBLY -> QUALIFYING FORWARD FRONTAL IMPACTS DAMAGE CONDITION LESS -> REPLAY / RECOVERY / RELAUNCH -> CLAIMED BIKE RETAINS MOD`

Retained truths:

- Scrap Bash Bar costs exactly **500 Cash once**;
- durable Cash schema is **v3** with exactly one new receipt: `courier_bike_bash_bar_paid`;
- v1 and v2 migrate to v3; malformed or unsupported-newer documents fail closed and are not silently overwritten;
- purchase is atomic through the retained staged-file write: success debits 500 and grants the receipt together; persistence failure rolls back Cash and receipt in memory;
- Bike ownership and bash-bar ownership remain separate durable facts;
- P11 retains initial claim, recovery and claimed-bike lifecycle authority;
- P14 owns only modification eligibility, purchase request, durable entitlement application and modification feedback;
- the Scrap Bash Bar is physically composed into the production Courier Bike as a welded salvage front cage with hazard-amber center plate;
- qualifying protection requires the bar installed, `is_forward_impact == true`, and `head_on_ratio >= 0.70`;
- qualifying condition load multiplier is exactly **0.35**;
- glancing, side and reverse/rear impacts remain unchanged;
- P07 vehicle condition remains authoritative and Garage repair remains free;
- P10 Burn armor restock remains free;
- P11 Courier Bike recovery remains free;
- P12 vending hack remains +80 Cash once, vending breach +120 Cash once, and Street Vendor tune-up remains exactly 150 Cash;
- P13 Mission 01 remains +320 Cash once, Mission 02 +450 Cash once, Mission 03 zero Cash, and mission payout receipts persist;
- Full Replay, Soft Failure and fresh relaunch preserve durable Cash receipts;
- Audio is unchanged;
- PR #44 remains deferred;
- P14 did not introduce generalized vehicle customization, upgrade catalogs/trees, multiple Bike mods, vehicle HP, XP, levels, additional currencies, repeatable mission payouts, new shops, new Garage geography or generalized entitlement registries.

### Frozen review truth

The earlier Codex review on `6e749efa39` identified one legitimate P2: reversing squarely into a wall could receive front-bash-bar protection because collision alignment was absolute-valued.

Repair on final head `a534d7a0e945e9330c7ab6bc84ce37ac159ecc01`:

- collision condition application gained explicit forward-impact authority;
- bash-bar protection now additionally requires `is_forward_impact`;
- `godot/tests/burnside_courier_bike_scrap_bash_bar_direction_test.gd` proves real physical square forward collision receives protection while the equivalent reverse/rear collision remains BATTERED;
- the stale inline review thread was replied to with exact repair evidence and resolved;
- fresh Codex review on `a534d7a0e9` found no major issues;
- CodeRabbit reviewed through the exact final head with no actionable comments;
- Copilot review quota remained unavailable and was not treated as approval or a blocker.

Final frozen-head evidence:

- Burnside Production 14 PR run `36279985596`: **SUCCESS**, including schema v3 / atomic purchase, production Garage / visual / capability / relaunch, physical forward/rear direction regression, retained P07/P10/P11 and retained P12/P13 regressions, plus rendered stock/fitted proof;
- Godot Web Playtest PR run `36279985565`: **SUCCESS**;
- P04/P05/P06/P07/P08/P10/P11/P12/P13 PR compatibility workflows on the final P14 line: **SUCCESS**;
- canonical compatibility matrix passed on the frozen PR source tree;
- rendered artifact `production14-rendered-proof-a534d7a0e945e9330c7ab6bc84ce37ac159ecc01` was produced from the exact final feature head.

### Exact-main and public verification

The final reviewed feature head and squash merge resolve to the same Git tree `40b3af0a6d8e92e218e234e8cbbfe2681250a70e`. The 14-file PR patch set also matches the squash-merge patch set exactly.

Burnside Production 14 main-push run `36541872852` at exact gameplay merge `4b563ff66d0e65f787e710af53d1c9d81209cbe3`:

- exact source checkout: **PASS**;
- P14 schema v3 / atomic purchase tracer: **PASS**;
- P14 production Garage / visual / capability / relaunch tracer: **PASS**;
- P14 physical forward / rear impact direction tracer: **PASS**;
- retained P07 / P10 / P11 regressions: **PASS**;
- retained P12 / P13 Cash regressions: **PASS**;
- rendered before/after Scrap Bash Bar proof: **PASS**.

Retained main-push evidence:

- Burnside Production 13 run `36541872866`: **SUCCESS**, including same-origin browser Cash persistence;
- Burnside Production 06 run `36541872894`: **SUCCESS**, including retained P01–P05 authority regressions and Web persistence;
- Burnside Production 04 / 05 exact-main runs: **SUCCESS**.

Godot Web Playtest main-push run `36541872845`:

- exact source checkout: **PASS**;
- retained touch / desktop controls / alias ownership / vehicle authority / interaction cancel: **PASS**;
- Web export: **PASS**;
- static-host smoke: **PASS**;
- browser artifact upload: **PASS**;
- public payload envelope: **PASS**;
- GitHub Pages artifact upload: **PASS**;
- Pages deployment: **PASS**;
- deployment-time public HTTP source-stamp verification: **PASS**.

The canonical compatibility matrix is intentionally pull-request-only in the retained Web workflow, so it is **SKIPPED on main push by workflow design**. It passed on the frozen P14 source tree, and exact Git-tree equality establishes source equivalence to the squash merge.

Latest verified public provenance:

`PLAYTEST_BUILD.txt = 4b563ff66d0e65f787e710af53d1c9d81209cbe3`

The publish job created the Pages deployment for that exact SHA and then fetched the public `PLAYTEST_BUILD.txt`, which returned that exact SHA.

GitHub Pages deployment URL:

`https://johnnymaconny.github.io/art/`

No manual interactive public play smoke is claimed in this closeout; public verification here is deployment, payload and live source-stamp evidence plus exact-main runtime/Web verification.

## Production 15 — verified player-facing result

Issue #172 / PR #173: **COMPLETE / MERGED / EXACT-MAIN VERIFIED / PUBLIC VERIFIED / ISSUE CLOSED**.

Final reviewed feature head:

`e689c905e5578c717df60a10ea0283f2fb19e871`

Exact gameplay/public main:

`9708686f5f5a8cd9f606b238186aca9f3e999cc1`

Exact Git tree shared by the final reviewed feature head and squash merge:

`cc52e106e51037a73ea1da0c52dc7c88c936b921`

Player-facing loop:

`CLAIM COURIER BIKE -> BREACH GEARS CHECKPOINT -> EVADE -> CHECKPOINT REARMS -> RETURN IN SAME CLAIMED BIKE -> VEHICLE FLAGGED // HOLD -> CIVIC REPORT OR FIELD-HACKED REPORT SUPPRESSION -> BACK OUT / SWITCH VEHICLE / BREACH AGAIN`

Retained truths:

- checkpoint recognition is **local, temporary session memory**, not Durable Progress;
- only a breach by the durably claimed production Courier Bike arms the watchlist;
- ordinary rearm preserves the local watchlist; Full Replay / slice reset and relaunch clear it;
- on-foot and different-vehicle returns retain ordinary toll behavior;
- WATCHLISTED blocks ordinary toll clearance and keeps the physical barrier closed;
- the checkpoint requests at most one civic Report during the WATCHLISTED encounter;
- P02 Field Hacking can suppress that Report but does not erase checkpoint-local recognition;
- a physical WATCHLISTED re-breach remains possible through the production root collision route;
- P01 Wanted / Contact / Search / Evasion authority remains external and unchanged;
- P11 remains sole durable Courier Bike ownership/recovery authority;
- no generalized vehicle-ID registry, reputation/Standing system, Heat 2–5, save migration, new Cash work, new geography, Audio change or PR #44 camera work entered P15.

Review/repair truth:

- initial Codex review on `6f03afe68f` identified one legitimate P2: a jammed WATCHLISTED scan could lead to a second civic Report request on same-encounter re-breach;
- repair on `e689c905e5578c717df60a10ea0283f2fb19e871` makes the WATCHLISTED scan own the attempt and causes re-breach to skip a duplicate request;
- production-scene tests count actual civic Report calls and route WATCHLISTED re-breach through `ScrapTestBlock._check_checkpoint_ram_breach(...)`;
- stale-label regressions cover ordinary rearm, different-vehicle return and on-foot return;
- fresh Codex review on exact repaired head found no major issues;
- the only inline review thread is resolved/outdated;
- CodeRabbit status passed; Copilot quota unavailability was not treated as approval or a blocker.

Exact-main verification:

- Burnside Production 15 run `36667174266`: **SUCCESS**, including exact-source P15 recognition, retained checkpoint/P01/P02/P04 authority regressions, retained vehicle/P11/P14 regressions and windowed ordinary-vs-WATCHLISTED proof;
- Burnside Production 14 run `36667174320`: **SUCCESS**, including retained exact-source behavior and rendered before/after proof;
- Burnside Production 13 run `36667174267`: **SUCCESS**, including same-origin browser Cash persistence;
- Burnside Production 04 run `36667174357`: **SUCCESS**;
- Godot Web Playtest run `36667174349`: **SUCCESS**, including exact-source checkout, retained input/control checks, Web export, static-host smoke, public package, Pages deployment and live source-stamp verification;
- the canonical compatibility matrix is intentionally pull-request-only on main push and was therefore skipped by workflow design; it passed on the exact repaired PR head before merge.

Latest verified public provenance:

`PLAYTEST_BUILD.txt = 9708686f5f5a8cd9f606b238186aca9f3e999cc1`

The Pages publish job created the deployment for that exact SHA and fetched the public source stamp, which returned that exact SHA.

No manual interactive public playthrough is claimed in this closeout.

## Production 16 — verified player-facing result

Issue #175 / PR #176 gameplay: **COMPLETE / MERGED / EXACT-MAIN VERIFIED / PUBLIC VERIFIED / CONTINUITY UPDATED / ISSUE CLOSED**.

Final reviewed feature head:

`f924a86706219b98b8476a1d5bef1d7dc5da6fad`

Exact gameplay/public main:

`b96f81264144386bd3fc3a1c77d330b7af3af531`

Exact Git tree shared by the final reviewed feature head and squash merge:

`8fb5a7c4a104b30e42d5992df23c09fccfe8534d`

Player-facing loop:

`COMPLETE MISSION 03 ESCAPE -> RETURN TO SILENT CORE -> WAIT FOR RETAINED PURSUIT TO REACH CALM -> CHOOSE RELEASE OR SEAL -> LOCAL WORLD FEEDBACK -> EXISTING CIVIC AUTHORITY REACTS IF RELEASED`

RELEASE:

- physical `RELEASE / PUBLIC RELAY`;
- commits session-local aftermath `RELEASED`;
- requests exactly one retained civic Report;
- live clear-state reporting composes with P01 Heat 1 / Contact;
- P02 Field Hacking can suppress an accepted jammed Report without undoing RELEASED;
- refused/already-latched attempts report `CIVIC REPORT BLOCKED`, not false suppression;
- a last-moment CALM guard prevents stale READY/target state from consuming the choice while the retained pursuit is active.

SEAL:

- physical `SEAL / LOCAL VAULT`;
- commits session-local aftermath `SEALED`;
- requests no civic Report;
- uses the same last-moment CALM guard, including stale-active-target protection.

Retained truths:

- Mission 03 still reaches its retained `COMPLETE` phase after legitimate escape; P16 adds an independent `UNDECIDED / RELEASED / SEALED` aftermath state;
- Full Replay restores `UNDECIDED` and dormant relays;
- the production controller retains sole target-arbitration authority;
- P01 retains Wanted / Report authority;
- P02 retains report-suppression authority;
- P08 retains HS-7 physical carried-presence authority;
- the recovered civic deletion-order fragment may be released through local civic infrastructure or retained locally;
- P16 does **not** establish the erased event, new factions/government structure or large-scale political consequences;
- no generalized branching-dialogue framework, morality meter, reputation system, Heat 2–5, persistent police database, save migration, new Cash work, new geography, Audio change or PR #44 camera work entered P16.

Review/repair truth:

- Codex identified a valid RELEASE-before-CALM race; repaired by CALM-gated readiness plus a final RELEASE authority check;
- review identified misleading Report-result feedback; repaired using the actual request result and explicit SUPPRESSED vs BLOCKED outcomes;
- review identified a same-frame stale-ready SEAL race; repaired with the same final CALM authority check and a production-scene regression;
- a later pre-existing-Wanted BLOCKED finding was rechecked against current source and found stale because BLOCKED classification is unconditional whenever no contact is created and the attempt is not an accepted jammed suppression;
- all inline review threads are resolved;
- final Codex review on exact frozen head `f924a86706219b98b8476a1d5bef1d7dc5da6fad` reported: **“Didn't find any major issues.”**

Frozen-head verification:

- Burnside Production 16 PR run `36963303931`: **SUCCESS**, including exact-source P16 behavior, retained Mission/Wanted/P15 regressions and windowed production rendered proof;
- Godot Web Playtest PR run `36963303932`: **SUCCESS**, including literal-head and synthetic-merge Web exports, retained camera/combat/checkpoint/player-survivability checks and the canonical 29-suite legacy compatibility matrix.

Exact-main verification:

- Burnside Production 16 main run `36963878009`: **SUCCESS**, including exact-source P16 behavior, retained regressions and windowed rendered proof;
- Godot Web Playtest main run `36963877996`: **SUCCESS**, including retained input/control checks, Web export, static-host smoke, public package and Pages deployment;
- the canonical compatibility matrix is intentionally PR-only on main push and therefore skipped by workflow design; it passed on the exact frozen PR head before merge.

Latest verified public provenance:

`PLAYTEST_BUILD.txt = b96f81264144386bd3fc3a1c77d330b7af3af531`

The Pages publish job created the deployment for that exact SHA and fetched the public source stamp, which returned that exact SHA.

GitHub Pages deployment URL:

`https://johnnymaconny.github.io/art/`

No manual interactive public playthrough is claimed in this closeout.

## Production 17 — verified player-facing result

Issue #179 / PR #180 gameplay: **COMPLETE / MERGED / EXACT-MAIN VERIFIED / PUBLIC VERIFIED / CONTINUITY UPDATED / ISSUE CLOSED**.

Final reviewed feature head: `3f7b2ce0bc3c0c0f07fa379f4a6cef941004f502`  
Exact gameplay/public main: `ecaaa903a5fe5bb1e180a9b64b1ed23ae4ebc90e`

Player loop:

`FIND SIDEARM -> TAKE -> MOVE + FIRE -> UTILITY CRAWLER / WORLD IMPACT -> LOCAL ALARM -> ONE CIVIC REPORT IF LIVE -> HEAT 1 / CONTACT OR FIELD-HACKED SUPPRESSION -> IMPROVISE / ESCAPE`

Retained boundaries:

- possession is current-run only; Full Replay restores pickup/unheld state and clears cooldown/shot feedback;
- desktop left-click and bounded mobile FIRE retain Action / Tool / Strike / vehicle / gesture ownership and reject synthetic touch duplication;
- one accepted shot = one 22 m hitscan query with 0.32 s cooldown;
- firearm damage is limited to the retained Utility Crawler 2 -> 1 -> 0 / DISABLED seam; no Security Interceptor firearm damage or human NPC health/death;
- first bounded local gunfire alarms the work zone and requests at most one civic Report; pre-existing Heat creates no redundant Report; P17 never owns Heat;
- Field Hacking can suppress city knowledge while local ALARMED reaction remains;
- no weapon roster/wheel, ammo/reload economy, generalized inventory, generalized witness bus, hostile pedestrian combat AI, Heat 2–5, save migration, new geography or PR #44 camera work entered P17.

Review / verification:

- first Codex review on `faed6888e609c384dfa6d717621045124049dbdf` found two valid P2 issues: replay-retained shot VFX and FIRE remaining enabled during cooldown;
- both were repaired and regression-covered; both threads are resolved;
- fresh Codex review on exact frozen head `3f7b2ce0bc3c0c0f07fa379f4a6cef941004f502` found no major issues;
- frozen P17 run `37168489393`: **SUCCESS**;
- frozen Web run `37168489367`: **SUCCESS**, including canonical compatibility matrix and browser head/merge exports;
- exact-main P17 run `37169218818`: **SUCCESS** on `ecaaa903a5fe5bb1e180a9b64b1ed23ae4ebc90e`;
- exact-main proof artifact `11290149880`, digest `sha256:439c9e02eee68814edacd6344df1766c4bcdc742097ac09de86ca26af55c44c2`, reports that exact source SHA and was directly inspected;
- exact-main Web run `37169218797`: **SUCCESS**, including export, static-host smoke, package and Pages publish;
- all eight workflows triggered by the gameplay merge completed **SUCCESS**.

Latest verified public provenance:

`PLAYTEST_BUILD.txt = ecaaa903a5fe5bb1e180a9b64b1ed23ae4ebc90e`

The Pages publish job verified that source stamp, and an independent live fetch returned the same exact SHA.

Audio qualification: `SIDEARM_FIRE` routing/ordinal compatibility is technically verified and Audio Runtime 31 run `37169218808` is **SUCCESS**. Perceptual firearm-audio quality is **NOT VERIFIED** because no trustworthy listening pass occurred.

No manual interactive public playthrough is claimed in this closeout.

## Production 18 — verified player-facing result

Issue #182 / PR #183 gameplay: **COMPLETE / MERGED / EXACT-MAIN VERIFIED / PUBLIC VERIFIED / CONTINUITY UPDATED / ISSUE CLOSED**.

Final reviewed feature head: `057c787692eb57c438bb825f406742341279cdc7`  
Exact gameplay/public main: `1cdbda2fcbcb53ec62af73514b3b396554277017`

Player loop:

`COMPLETE CIVIC REPOSSESSION -> BURN BECOMES KNOWN -> RETURN TO BURN GARAGE ON FOOT -> SEE BURN PHYSICALLY -> ACTION -> SHORT FACE-TO-FACE EXCHANGE -> EXISTING GARAGE SERVICES REMAIN AUTHORITATIVE -> LEAVE`

Wanted case:

`APPROACH BURN WITH ACTIVE WANTED -> BURN REFUSES THE MOMENT -> EVADE -> RETURN CLEAR`

Verified retained boundaries:

- Mayor Burn is physically present at the retained Garage even before KNOWN; the Contact interaction remains unavailable until the retained `MayorBurnContactProgressStore` says KNOWN.
- P18 creates no second relationship/save authority and no save migration.
- Wanted remains sole authority for CLEAR / CONTACT / SEARCH; P18 does not mutate or clear Heat.
- Ordinary desktop/mobile Action converges on the same bounded encounter through retained active-target arbitration.
- FIRE / Tool / Strike / browser-emulated touch mouse cannot synthesize the Burn encounter.
- The Burn target uses a tighter local radius and higher immediate priority without replacing retained Armor restock, Garage repair, Courier Bike claim or Scrap Bash Bar service ownership.
- Leaving the encounter radius, incompatible Wanted-state change, or Full Replay cancels transient character presentation cleanly; durable KNOWN survives Replay.
- The locked three-line clear-state exchange and Wanted refusal are implemented verbatim.
- The actor is original/procedural primitive geometry with no real-person likeness or third-party character dependency.
- No generalized dialogue system, NPC framework, branching tree, human Health/death, weapon expansion, Heat 2–5, new geography, Audio event, voice pipeline or PR #44 camera work entered P18.

Review / verification:

- fresh Codex review on exact frozen head `057c787692eb57c438bb825f406742341279cdc7`: **no major issues**;
- exact-head P18 run `37173732796`: **SUCCESS**;
- exact-head Godot Web Playtest `37173732833`: **SUCCESS**;
- exact-head shared P04/P05/P06/P07/P10/P11/P14/P17 workflows: **SUCCESS**;
- exact-head rendered artifact `11292631859`, digest `sha256:ae470215302c23a7cb30654c1629f0ccbe3153a654e36b71da13d7d49510dedf`, was directly inspected;
- exact-main P18 run `37174463092`: **SUCCESS**;
- exact-main P04 `37174463094`, P05 `37174463038`, P06 `37174463062`, P14 `37174463090`, P17 `37174463068`: **SUCCESS**;
- exact-main Godot Web Playtest `37174463130`: **SUCCESS**, including Web export, static-host smoke, public package, Pages deploy and public source-revision verification;
- exact-main rendered artifact `11292717945`, digest `sha256:74fb5a846feef7448cf68f4da8d2ec48a597924de410d5996862177b7471b1da`, reports the exact gameplay SHA and all four captures were directly inspected.

Latest verified public provenance:

`PLAYTEST_BUILD.txt = 1cdbda2fcbcb53ec62af73514b3b396554277017`

The live public source stamp was independently fetched after Pages publication and matches exact gameplay/main.

No manual interactive public playthrough is claimed in this closeout.

Audio qualification is unchanged by P18. P18 introduced no Audio event or voice pipeline. P17 `SIDEARM_FIRE` technical routing remains verified; perceptual firearm-audio quality remains **NOT VERIFIED** without an actual listening pass.

## Production 19 — verified player-facing result

Issue #184 / PR #187 gameplay: **GAMEPLAY MERGED / EXACT-MAIN VERIFIED / PUBLIC VERIFIED / CONTINUITY UPDATE IN PROGRESS**.

Final reviewed feature head:

`948fce608216d5a6d6f0cd2aa1cb40421f8a0bd2`

Exact gameplay/public main:

`d8ec7918e8980029f0ed9821e109cc0c65cbb42c`

Player-facing loop:

`HEAT 1 + CONTACT -> PURSUER CLOSES -> SIDEARM HIT -> BRIEF HESITATION -> PLAYER USES PHYSICAL COVER / ROUTE -> RETAINED LOS AUTHORITY DECIDES CONTACT OR SEARCH`

Verified retained boundaries:

- one valid sidearm ray may request a bounded nonlethal response from the active pursuer only while it is CHASING / DETOURING;
- suppression lasts **0.18 s** and translates at **35% of retained current speed**;
- P19 applies no displacement impulse, does not reset `current_speed`, does not change chase/detour state, does not change `target_node`, and clears the local interception timer only while the modifier is active;
- the hit reaction is visually readable through a bounded 12-degree body roll plus temporary amber siren emphasis, then restores retained pursuit presentation;
- repeated perfect FIRE at the retained 0.32 s cooldown cannot win a max-speed open-road foot chase by itself: the resulting average pursuer translation remains about 9.8 m/s versus Runner 8.5 m/s;
- retained P05 Scrapper remains the stronger close-range body-space verb: 0.30 s with physical shove/displacement; valid Scrapper contact supersedes P19 suppression;
- rejected zero-direction Scrapper input does not mutate an active P19 suppression modifier;
- P17 remains sole owner of sidearm acquisition, FIRE input, one-shot/one-ray resolution, cooldown, local gunfire consequence and `SIDEARM_FIRE` technical audio routing;
- retained Utility Crawler damage remains the first closed ballistic target path; P19 adds only the retained `pursuers` group + `apply_sidearm_suppression()` fallback and no generalized damage/target registry;
- Wanted remains sole authority for Heat / CONTACT / SEARCH / Evasion; P19 never directly writes or clears any of those states;
- retained physical LOS loss must persist through the existing 0.8 s grace before CONTACT -> SEARCH; direct observation reacquisition remains retained Wanted behavior;
- Full Replay/pursuer reset clears transient P19 presentation/state; EMP, vehicle stun and de-escalation retain their existing authority;
- no save migration, human Health/death expansion, weapon roster, ammo/reload, enemy firearms, Heat 2–5, generalized witnesses/NPC/combat framework, new geography, unrelated Audio or PR #44 work entered P19.

Review / verification:

- RED exact head `0a9b3d28c972dec147db055ff9842d948b9f4ece`, run `37176711031`, failed for the intended missing `apply_sidearm_suppression` seam while retained regressions remained green;
- frozen feature head `948fce608216d5a6d6f0cd2aa1cb40421f8a0bd2`;
- fresh Codex review on that exact frozen head: **“Didn't find any major issues.”**
- no unresolved review threads remained; Copilot quota exhaustion was non-substantive and was not treated as approval;
- exact frozen-head push P19 run `37183679547`: **SUCCESS**;
- exact frozen-head proof artifact `11296106706`, digest `sha256:13121c3c1ddaa4fab79493195f1026acc82abd17fe149bb0a33a5b4faba03d35`;
- PR P19 run `37183755892`: **SUCCESS**;
- PR retained P17 run `37183755873`: **SUCCESS**;
- PR retained P05 run `37183755899`: **SUCCESS**, including retained P01 Wanted, P02 Field Hacking, P03 Mission/Wanted, P04 work-zone and P05 tool/route regressions;
- PR Godot Web Playtest `37183755847`: **SUCCESS**, including literal-head and synthetic-merge browser exports, current camera/combat/checkpoint/player-survivability checks and canonical 29-suite compatibility matrix;
- exact-main P19 run `37183995961`: **SUCCESS**;
- exact-main retained P05 run `37183996014`: **SUCCESS**;
- exact-main retained P17 run `37183995975`: **SUCCESS**;
- exact-main Godot Web Playtest `37183996008`: **SUCCESS**, including exact-source checkout, mobile/desktop input regressions, Web export, static-host smoke, public package and Pages deployment;
- exact-main P19 proof artifact `11296535829`, digest `sha256:347f1ede5a4615e32f58309bb92017bbc290cbe86c324e2052fff9f91c0f1460`, reports exact source SHA `d8ec7918e8980029f0ed9821e109cc0c65cbb42c`;
- the exact-main five-frame proof was directly inspected: CONTACT approach; readable sidearm suppression while CONTACT remains; physical cover with direct observation broken but CONTACT still inside retained grace; the same geometry becoming SEARCH only after retained Wanted authority advances; and physical reacquisition restoring CONTACT.

Latest verified public provenance:

`PLAYTEST_BUILD.txt = d8ec7918e8980029f0ed9821e109cc0c65cbb42c`

The Pages publish job completed for that exact gameplay SHA, and an independent live fetch returned the same exact source stamp.

No manual interactive public playthrough is claimed in this closeout.

Audio qualification is unchanged by P19. P19 introduced no new Audio event and no voice pipeline. P17 `SIDEARM_FIRE` technical routing remains verified; perceptual firearm-audio quality remains **NOT VERIFIED** without an actual listening pass.

## Production 20 — verified player-facing result

Issue #188 / PR #190 gameplay: **GAMEPLAY MERGED / EXACT-MAIN VERIFIED / PUBLIC VERIFIED / CONTINUITY UPDATE IN PROGRESS**.

Final reviewed feature head:

`2caad64b5fe7f5bdb779fdbf07100f3e11b7d2f1`

Exact gameplay/public main:

`e4029fd06bfafc3fdc8ac158b7c39a17372a8d34`

Player-facing loop:

`MISSION 03 COMPLETE -> RETURN TO SILENT CORE -> SISTER KAEL PHYSICALLY PRESENT -> RETAINED RELEASE / SEAL RELAY COMMITS P16 OUTCOME -> KAEL AUTOMATICALLY REACTS -> LEAVE`

Verified retained boundaries:

- P16 remains the sole `UNDECIDED / RELEASED / SEALED` writer; P20 only reads Mission 03 phase + aftermath state;
- Sister Kael is a passive physical witness and is never added to `_interactables`;
- Kael owns no `InteractableBase`, Action target, mission, Wanted, Field-Hacking, save, combat or Audio authority;
- retained RELEASE / SEAL relays remain the only aftermath Action targets;
- P01/P02 remain sole civic Report / Wanted / Field-Hacking authorities;
- P08 remains sole HS-7 carried-presence authority;
- P18 Mayor Burn and P19 pursuer suppression remain bounded and unchanged;
- P20 reuses retained P16 `mission.contact_line` rather than creating a duplicate dialogue/choice/relationship authority;
- RELEASE and SEAL receive materially distinct bounded Kael poses;
- Full Replay clears P20 transient presentation and hides Kael until Mission 03 is COMPLETE;
- no save migration, generalized NPC/dialogue/relationship system, human Health/death expansion, enemy firearms, Heat 2–5, new geography, PR #44 work or new Audio event entered P20.

Review / verification:

- valid RED exact head `9e25bbf14827e817784df4f7214dd8ae0fb40d4d`, run `37249559659`, failed for the intended missing SisterKaelWitnessRuntime seam while retained regressions passed;
- original green candidate `214d53aac7c60776c47363e0f7456687a20e79c6` exposed a canonical Ticket06 headless-audio precondition failure in Godot Web PR verification;
- rerun evidence changed the classification from apparent shared baseline failure to a head-only failure: exact P20 head failed `Pre-check static` while untouched base passed;
- the repair was test/harness-only: Ticket06 Test 11 now creates expensive synthetic transient fixtures before arming tuning static immediately before reset preconditions; Test 5 remains the independent tuning-lifecycle contract and Test 11 still requires live engine/siren/static/transients before proving authoritative reset silence;
- repaired frozen candidate `2caad64b5fe7f5bdb779fdbf07100f3e11b7d2f1`;
- fresh exact-head Codex review on `2caad64b5f`: **“Didn't find any major issues.”**
- unresolved review threads: **0**;
- repaired PR P20 run `37264305473`: **SUCCESS**;
- repaired PR Godot Web Playtest `37264305476`: **SUCCESS**, including exact-head canonical compatibility matrix, head + synthetic-merge Web export, static-host smoke and packaging;
- repaired feature proof artifact `11325617280`, digest `sha256:03f8f2e96c5e305d0f1acdd39e51497e22d259f47db0ee8150bb239ad69b5b01`;
- gameplay PR #190 merged with expected-head protection to exact main `e4029fd06bfafc3fdc8ac158b7c39a17372a8d34`;
- exact-main P20 run `37264749982`: **SUCCESS**; its retained suite explicitly passed P16 memory disclosure, P18 Mayor Burn, P19 sidearm/pursuer suppression, companion/HS-7 and input regressions;
- exact-main P20 proof artifact `11325523981`, digest `sha256:7fe14b5a5a0f0b85c67a3ca3da2caff79e30b30f1d894e9899eb450b1a2d2e91`;
- exact-main Godot Web Playtest `37264750000`: **SUCCESS**, including exact-source checkout, mobile/desktop routing regressions, Web export, static-host smoke, source-stamped package and Pages deployment;
- all other workflows triggered by the merge (P04, P05, P06, P14, P17, P18) completed **SUCCESS**.

Latest verified public provenance:

`PLAYTEST_BUILD.txt = e4029fd06bfafc3fdc8ac158b7c39a17372a8d34`

The Pages publish job completed for that exact gameplay SHA, and an independent fresh live fetch returned the same exact source stamp.

No manual interactive public playthrough is claimed in this closeout.

Audio qualification: P20 introduced no Audio dependency. P17 `SIDEARM_FIRE` technical routing remains verified; perceptual firearm-audio quality remains **NOT VERIFIED** without an actual listening/playback pass.

## Post-Production-20 re-evaluation state

P20 closes the bounded authored-character consequence gap at the Silent Core without creating another interaction authority.

Fresh re-evaluation found a higher-priority non-feature blocker before any numbered P21 gameplay slice:

**Release Integrity 01 — #191 — GTA reference-audio containment / public decontamination**

Status: `SELECTED__JIT_DESIGN_PENDING__BLOCKS_NEXT_FEATURE_PRODUCTION`

Why it outranks adjacent gameplay candidates:

1. **release/IP integrity** — the repository is public, and current tracked audio contracts/registries explicitly identify multiple production paths as `GTA_SA:...` sources while some classify them as `LICENSED_FINAL`; at least `godot/audio/echo/loop_echo_radio_interference.wav` is directly verified as a tracked binary in the public repo. This conflicts with the current owner rule that GTA/Rockstar audio is private local reference only and must not be committed, published, redistributed or become a release dependency;
2. **perceptual audio / output qualification** — issue #31 remains open and human listening quality is still unverified, but first the tracked/public reference boundary must be made trustworthy;
3. **Lira physical presence / authored consequence** — still valuable, but another static-character slice has lower marginal value immediately after P18/P20;
4. **Heat 2+ / broader police escalation** — high eventual systemic value, but materially greater AI/authority/content cost and risk;
5. **human combat expansion / enemy firearms** — broader architecture and content surface than current evidence justifies;
6. **more geography** — lower value until a gameplay need demonstrates that existing Gears density is insufficient.

#191 should restore the intended split:

`PUBLIC/TRACKED = ORIGINAL | PROCEDURAL | LICENSED-SAFE`

`LOCAL PRIVATE DEV = OPTIONAL GTA REFERENCE OVERRIDE`

Do not infer that successful P20 public deployment makes the current audio provenance release-ready. The exact P20 gameplay/public build is verified as behavior/provenance truth; the separate audio distribution risk is now explicit and blocks the next feature production slice.

## Next-state rule

Next production session:

1. refresh exact repo/main, #191, open PRs/issues, CI/public Pages provenance and concurrent Audio/shared-scene work;
2. keep exact runnable/gameplay/public P20 baseline `e4029fd06bfafc3fdc8ac158b7c39a17372a8d34` distinct from any later docs-only continuity HEAD;
3. confirm PR #190 remains merged and #188 is closed/completed after this continuity lands;
4. read `START_HERE.md`, #55, #118 and #191 before new feature work;
5. perform #191 JIT design by enumerating affected tracked binaries, registry/runtime ownership, safe procedural/original fallbacks, local-reference override behavior and Web packaging;
6. do not delete semantic Audio ownership or weaken reset/mix/routing regressions merely to remove third-party binaries;
7. do not select/implement numbered P21 gameplay until #191 is resolved and the playable product is re-evaluated again;
8. PR #44 remains deferred unless fresh evidence independently makes camera occlusion the highest-value current gap.

Create a new Wayfinder only for a genuinely new, foggy, multi-session cross-system design problem. `WAYFINDER_MAP.md` remains historical architecture context, not the live status tracker.
