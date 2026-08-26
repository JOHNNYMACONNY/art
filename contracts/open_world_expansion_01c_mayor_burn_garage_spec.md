# Open World Expansion 01C — Mayor Burn Garage Integration

**State:** READY_FOR_IMPLEMENTATION  
**Baseline:** `main@8297f5ae54d2b66348620b25feecff6c754b988a`  
**Predecessor:** Open World Expansion 01B / PR #64  
**Creative authority:** approved Gears visual-direction documents  
**Narrative authority:** Mission/Narrative 02 — Civic Repossession

## Objective

Convert Mayor Burn's existing Mission 02 delivery placeholder into the first authored mission destination inside the expanded Gears geography, without adding acreage or changing Mission 02's state-machine semantics.

The 01B commercial frontage and passive `MissionDestinationSocket` already provide the production geography. 01C should make that frontage read as Burn's garage entrance and make the retained Civic Repossession runtime use that socket for delivery.

## Scope

1. Add a bounded `MayorBurnGarage` visual identity layer to the existing `CommercialFrontage` in `gears_district_slice_01b.tscn`.
2. Preserve the existing commercial frontage mass/collision and service-alley route.
3. Use approved Gears commercial/civic/gray-market graphic language: one hero garage-door/sign shape, one readable Burn identifier, one civic/permit spoof cue, and localized repair history.
4. Reuse `gears_toon.gdshader`; do not introduce a new shader stack or real-time local-light layer.
5. Retarget Mission 02's existing `CivicRepossessionReturnZone` to `GearsDistrictSlice01B/MissionDestinationSocket` when the production slice is present.
6. Keep the return zone presentation and completion radius behavior otherwise unchanged.
7. Preserve a legacy fallback position only for isolated/non-production fixtures where the district socket is absent.
8. Do not add new mission phases, triggers, generalized destination systems, traffic, NPC logic, camera behavior, pursuit authority, vehicle behavior, economy, save-state changes, or additional district acreage.

## Visual contract

At retained elevated-camera scale the garage should read in this order:

`garage-door mass -> Burn color/value/sign shape -> BURN / GARAGE wording -> permit/asset detail`

The location should feel like a working gray-market municipal-service garage, not a nightclub, luxury showroom, military bunker, or generic neon cyberpunk storefront.

Generic civic spoof/permit markings are allowed. Existing narrative canon explicitly identifies the destination as Burn's garage, so `BURN` / `GARAGE` wording is authorized here.

## Runtime contract

- Production destination source: `GearsDistrictSlice01B/MissionDestinationSocket`.
- `CivicRepossessionReturnZone` remains created by the thin Mission 02 runtime adapter and remains hidden until Mission 02 reaches DELIVERY.
- The runtime must place the zone at the production socket rather than the old `(7, 0.08, 8)` yard placeholder whenever the socket exists.
- The zone must remain at least 20 m from the legacy placeholder on the production scene, proving the authored geography is actually used.
- Full Replay must continue to relock Mission 02 and hide the return zone.
- Mission 01/03 composition boundaries remain unchanged.

## Bounded art budget

Incremental additions for 01C:

- new garage mesh instances: `<= 8`;
- new collision shapes: `0`;
- new local lights: `0`;
- new gameplay scripts/state machines: `0` (the existing Mission 02 adapter may be edited narrowly);
- no change to the 01B road/alley/intersection transforms.

## Code-first verification

Exact-head CI must verify:

- `MayorBurnGarage` exists under the real 01B commercial frontage;
- its representative hero meshes use the approved toon shader;
- the garage adds no collision or local lights;
- the retained 01B route/collision contract still passes;
- Mission 02 runtime creates exactly one `CivicRepossessionReturnZone`;
- in the real playable scene, that zone resolves to the district mission socket and not the legacy yard placeholder;
- the zone starts hidden;
- the mission state model and existing vehicle/pursuit/camera contracts remain green;
- full exact-head canonical compatibility remains green.

## Verification debt

Fresh retained-camera screenshots and candidate render telemetry remain explicit deferred verification debt under the owner's momentum policy. 01C should not expand into additional district acreage; a later checkpoint must resolve representative visual/performance qualification before content multiplication materially increases rework risk.

## Completion recommendation

After 01C, prefer another **location/content integration inside existing geography** over more acreage. Sister Kael / Silent Core is a likely candidate because it currently remains a functional placeholder and has strong approved visual rules, but that should be re-evaluated against current `main` and roadmap state after 01C passes.
