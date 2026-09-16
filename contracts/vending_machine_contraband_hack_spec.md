# Commercial Storefront Vending Machine Contraband Hack Specification

**Status:** APPROVED / TDD_GATE_ACTIVE  
**Baseline:** `main@e7470c6`  
**Engine:** Godot 4.7.1 Stable  
**Product Direction:** Exploit commercial storefront corner sidewalk frontage with interactive contraband vending terminal.

## 1. Objective
Deploy interactive municipal contraband vending terminal (`prop_vending_machine.glb`, `prop_vending_machine.tscn`, `prop_vending_machine.gd`) into `scrap_test_block.tscn`:
1. Player tactical interaction: `[E] HACK TERMINAL` aligns contraband frequency, dispenses emergency fuel cell / nitro surge (+80 scrap or vehicle boost), transitions to `HACKED`.
2. Foot melee strike tampering: 3-hit durability lifecycle with elastic chassis shake. Hit 3 triggers catastrophic breach, spills +120 scrap chunks, trips siren alarm and municipal disturbance alert.
3. High-speed vehicle ram combat: impacts at `>= 4.5 m/s` breach terminal, tilt chassis 30°, scatter scrap debris chunks, spill loot, trigger alarm and city disturbance alert.
4. Deterministic reset: `reset_vending_machine()` in `reset_slice()` restores clean operational state, initial transforms, screen lighting, re-enables collisions, and frees debris chunks.

## 2. Semantics & Identity
- **Directive:** `vending_machine_contraband_hack`
- **Actor:** `COMMERCIAL_VENDING_MACHINE`
- **Zone:** `commercial_frontage`
- **Location:** `Vector3(-6.5, 0.0, -25.0)`
- **Hack Reward:** 80 scrap credits (or vehicle nitro surge if vehicle present)
- **Breach Reward:** 120 scrap credits
- **Durability:** 3 strikes (prybar `take_hit(1, ...)`)
- **Min Ram Speed:** 4.5 m/s

## 3. State Lifecycle
```
             ┌───────────┐
             │   READY   │◄─────────────────────┐
             └─────┬─────┘                      │
                   │ [E] HACK TERMINAL          │
                   ▼                            │
             ┌───────────┐                      │
             │  HACKED   ├──────────────────────┤
             └─────┬─────┘                      │ reset_vending_machine()
                   │ Melee (3) / Ram (>=4.5m/s) │
                   ▼                            │
             ┌───────────┐                      │
             │ BREACHED  ├──────────────────────┘
             └───────────┘
```

## 4. Mechanical & Audio Contract
1. **`[E] HACK TERMINAL`**:
   - Player in range (<= 2.5m) targets terminal.
   - Action prompt presents `[E] HACK TERMINAL`.
   - Interaction executes terminal hack, awards +80 scrap, transitions to `HACKED`, changes screen glow from cyan to green.
   - Action prompt updates to `[E] DISPENSED`.
   - Audio: `AudioManager.SoundEvent.COMPLETION` + `AMBIENT_WORK_CLINK`.
2. **Foot Melee Combat**:
   - Registered in groups `damageable` and `strike_target`.
   - Hits 1-2: decrements durability, elastic recoil tween, `AMBIENT_WORK_CLINK` + `SPARK`.
   - Hit 3: decrements durability to 0, transitions to `BREACHED`, spills +120 scrap chunks, scatters 4 debris shards, sounds `SIREN_ALARM`, triggers municipal disturbance alert.
   - Action prompt updates to `[E] BREACHED`.
3. **Vehicle Ram Combat**:
   - Impacts at `>= 4.5 m/s` transition to `BREACHED`.
   - Tilts chassis along impact vector with slide displacement.
   - Scatters 4-5 scrap debris shards, spills +120 scrap if unlooted.
   - Screen turns red/dim.
   - Audio: `COLLISION_HEAD_ON` + `SPARK` + `SIREN_ALARM`.
   - Triggers `trigger_disturbance_alert()`.
4. **Deterministic Reset**:
   - `reset_vending_machine()` restores transform, durability (3), state (`READY`), screen emission (cyan), collision shape, and frees debris instances.
