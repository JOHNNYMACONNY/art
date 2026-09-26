# Production 14 Implementation Plan — Scrap Bash Bar

Base: `main@9f9f922c486c39a13fd454f721b6f2bf24f87bdf`
Issue: #167

## Sequence

1. **RED**
   - Add P14 store contract test.
   - Add P14 production integration test.
   - Add P14 exact-source workflow.
   - Observe required failures before P14 APIs/runtime exist.

2. **GREEN — durable transaction**
   - Evolve `BurnsideCashProgressStore` v2 -> v3.
   - Add exact 500-Cash atomic bash-bar purchase receipt.
   - Preserve v1/v2 migration and all P12/P13 APIs.
   - Add bounded Cash runtime purchase feedback.

3. **GREEN — Bike capability/presentation**
   - Add one scene-authored `VisualRoot/ScrapBashBar` with salvage/amber materials.
   - Add install/query API to `CourierBike`.
   - Apply 0.35 load multiplier only for `head_on_ratio >= 0.70`.

4. **GREEN — Garage composition**
   - Add `BurnGarageCourierBikeScrapperModRuntime`.
   - Mount it from retained Gears production composition.
   - Share `CourierBikeClaimSocket` with legal state-based arbitration; priority 3.9.

5. **VERIFY**
   - New P14 tests.
   - Retained P07/P10/P11/P12/P13 tests.
   - Existing P13 browser-persistence workflow should also exercise the evolved Cash schema when Cash files change.
   - Godot Web Playtest / compatibility gates.
   - Review exact feature head against #167 + spec; repair only verified findings.

6. **MERGE / PUBLIC**
   - Merge only frozen reviewed head.
   - Verify exact main.
   - Verify public Pages source stamp.
   - Update HANDOFF/START_HERE only after verified production state.
   - Close #167 only after continuity.
