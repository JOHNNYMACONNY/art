# World Event 04 — Municipal Utility Crawler Patrol Specification

**Status:** APPROVED / TDD_GATE_ACTIVE  
**Baseline:** `main@cc1d2ee`  
**Engine:** Godot 4.7.1 Stable  
**Product Direction:** exploit existing Gears sidewalk conduit geography and utility crawler rover asset.

## 1. Objective
Make the Municipal Utility Crawler (`utility_crawler.glb`, `utility_crawler.tscn`, `utility_crawler.gd`) interactive within the live gameplay loop of `scrap_test_block.tscn` through a bounded authored world event:
1. Tactical scrap interception via player interaction prompt (`[E] INTERCEPT`).
2. Foot melee strike tampering with 2-hit disable and scrap spill.
3. High-speed vehicle ram breach resulting in instant wreck, scattered scrap debris chunks, and municipal disturbance alarm triggering.
4. Deterministic reset restoring clean ambient waypoint patrol loop without regressions to existing ambient contracts (`v8_m07_world_assertions.gd`).

## 2. Semantics & Identity
- **Directive:** `municipal_crawler_patrol`
- **Actor:** `MUNICIPAL_UTILITY_CRAWLER`
- **Zone:** `gears_salvage_circuit`
- **Harvest Reward:** 60 scrap credits
- **Durability:** 2 strikes (prybar `take_hit(1, ...)`)
- **Min Ram Speed:** 4.5 m/s

## 3. State Lifecycle
```
             ┌───────────┐
             │  AMBIENT  │◄─────────────────────┐
             └─────┬─────┘                      │
                   │ Proximity threat           │
                   ▼                            │
             ┌───────────┐                      │
             │ YIELDING  │                      │
             └─────┬─────┘                      │
                   │ Disturbance alert          │
                   ▼                            │ reset_actor()
             ┌───────────┐                      │
             │  ALARMED  │                      │
             └─────┬─────┘                      │
                   │ [E] INTERCEPT / Melee (2)  │
                   ▼                            │
             ┌───────────┐                      │
             │ DISABLED  ├──────────────────────┤
             └───────────┘                      │
                   │ High-speed ram (>= 4.5 m/s)│
                   ▼                            │
             ┌───────────┐                      │
             │  WRECKED  ├──────────────────────┘
             └───────────┘
```

## 4. Mechanical & Audio Contract
1. **`[E] INTERCEPT`**:
   - Player in range (<= 2.5m) targets crawler.
   - Action prompt presents `[E] INTERCEPT`.
   - Interaction awards +60 scrap, transitions to `DISABLED`, dims beacon light.
   - Audio: `AudioManager.SoundEvent.COMPLETION` + `AMBIENT_WORK_CLINK`.
2. **Foot Melee Combat**:
   - Registered in groups `damageable` and `strike_target`.
   - Hit 1: decrements durability (2 -> 1), elastic recoil tween, `AMBIENT_WORK_CLINK` + `SPARK`.
   - Hit 2: decrements durability (1 -> 0), transitions to `DISABLED`, spills +60 scrap if unharvested, scatters 3-4 debris shards, `COMPLETION` + `SPARK`.
3. **Vehicle Ram Combat**:
   - Impacts at `>= 4.5 m/s` transition to `WRECKED`.
   - Launches chassis with 35° tilt and slide displacement.
   - Scatters 4-5 scrap debris chunks.
   - Shuts off beacon light.
   - Awards +60 scrap if unharvested.
   - Audio: `COLLISION_HEAD_ON` + `SPARK` + `SIREN_ALARM`.
   - Triggers `trigger_disturbance_alert()`.
4. **Deterministic Reset**:
   - `reset_actor()` resets transform, durability (2), state (`AMBIENT`), collision, amber beacon, and frees all debris instances.
