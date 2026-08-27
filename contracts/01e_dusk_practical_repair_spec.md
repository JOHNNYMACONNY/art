# 01E Repair — Production Dusk Practicals

**State:** READY_FOR_IMPLEMENTATION  
**Baseline:** `main@da6755e7d066e16d7598d3f339b7cff3eb1adbcc`  
**Trigger evidence:** native Apple M4 / macOS / Godot 4.7.1 verification of exact baseline reported `PASS WITH FINDINGS`: day/dusk directional sun transition worked, but `StoreWorkLamp`, `GantryServiceLamp`, and `RelayMarkerLamp` were suppressed because they remained under hidden `GearsStyleProof`.

## Objective

Restore the approved dusk practical-light hierarchy without undoing Open World Expansion 01E's proof-render retirement or its structural performance win.

## Production contract

- Keep `GearsStyleProof.visible = false` in `scrap_test_block.tscn`.
- Keep the standalone proof scene and its three proof practical lights unchanged for Issue #60 reference/testing.
- Add one `PracticalLights` node under `GearsDistrictSlice01B` containing exactly three production `OmniLight3D` instances named:
  - `StoreWorkLamp`
  - `GantryServiceLamp`
  - `RelayMarkerLamp`
- Place the production practicals at authored production geography: Mayor Burn/commercial frontage, the civic industrial intersection, and the Silent Core/relay infrastructure pocket respectively.
- Preserve the approved energies:
  - day: `1.0`, `0.8`, `0.35`
  - dusk: `1.55`, `1.24`, `0.54`
- Preserve warm commercial/civic practical colors for Store/Gantry and restrained cyan for Relay.
- Update the existing `GearsStyleProof.set_lighting_mode()` authority to target production district practicals when mounted in the playable scene, with fallback to the proof scene's own practicals when inspected standalone.
- Do not add meshes, collisions, acreage, gameplay state, mission state, input, HUD, audio, save-state, pursuit or vehicle authority.

## Verification contract

Exact-head tests must prove:

1. `GearsStyleProof` remains hidden in production.
2. `GearsDistrictSlice01B` remains visible.
3. `GearsDistrictSlice01B/PracticalLights` exists with exactly the three required lights.
4. All three production practicals are visible and non-shadow-casting.
5. Day mode drives production energies to `1.0 / 0.8 / 0.35`.
6. Dusk mode drives production energies to `1.55 / 1.24 / 0.54`.
7. The proof artifact still retains its own three reference practical lights.
8. Existing 01B–01E, camera, mission, FB-13 and compatibility tests remain green.
9. Fresh published nine-state verification preserves the 01E structural win and shows a materially restored dusk practical hierarchy without visual clutter.

## Non-goals

- no re-showing proof geometry;
- no new light framework or day/night system;
- no shadow-casting practical lights;
- no new locations or acreage;
- no audio changes;
- no claim that this changes native frame-time qualification beyond the existing local evidence.
