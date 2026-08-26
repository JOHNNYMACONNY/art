# Open World Expansion 01D — Silent Core Infrastructure Integration

**State:** READY_FOR_IMPLEMENTATION  
**Baseline:** `main@133ea941f7766a4c431e292628be4a57be1eb5e8`  
**Predecessor:** Open World Expansion 01C / PR #65  
**Creative authority:** approved Gears visual-direction documents, especially the Silent Core / Sister Kael mystery language in `GEARS_DISTRICT_VISUAL_DIRECTION_V2_CONVERGENCE.md`  
**Narrative authority:** Mission/Narrative 03 — The City That Forgot

## Objective

Replace Mission 03's hard-coded in-yard Silent Core placeholder with the first authored Silent Core infrastructure location inside the existing Gears production geography, without adding acreage or changing Mission 03's state-machine, Echo, pursuit, input, HUD, replay, or interaction authority.

The location should read as ordinary obsolete telecom/relay/utility infrastructure whose importance outlived its understood purpose. It must not read as a fantasy shrine, glowing crystal altar, cathedral, holographic spectacle, or generic neon mysticism.

## Production location

Add a bounded `SilentCoreSite` to `godot/scenes/world/gears_district_slice_01b.tscn` in the quiet pocket south of the existing `IndustrialFrontage` and east of the production intersection.

Target root position:

`Vector3(6.2, 0.0, -27.4)`

This location intentionally:

- uses existing 01B geography;
- does not add road acreage;
- remains outside the retained primary-road collision corridor;
- remains outside the 01B industrial-frontage collision volume;
- stays spatially separate from the Issue #60 proof-only `DistantRelay` silhouette;
- creates a short on-foot destination from the industrial intersection rather than a vehicle-scale new route.

Because this pocket is outside the existing drivable floor surfaces, add the smallest physically traversable maintenance access needed to make it real gameplay geography: a two-piece `AccessWalkway` -> `SitePadBody` apron with one collision shape each. The walkway must overlap the existing industrial-intersection collider, the site pad must overlap the walkway, and both surfaces must remain outside the proof-relay and industrial-frontage collision envelopes. This is a maintenance apron, not new road acreage.

Add a passive `Marker3D` named `SilentCoreSocket` under `SilentCoreSite`, located on the site pad. Mission 03's production `SilentCoreInteractable` must resolve to that socket whenever the production site exists.

## Visual contract

The site should express the approved Silent Core mystery language through restraint:

1. one ordinary utility/service pad mass;
2. one narrow maintenance access surface;
3. one obsolete relay/server cabinet mass;
4. one deliberately removed or blank asset-plate scar;
5. one small maintenance/care cue;
6. one sparse HS-7 cyan signal aperture.

Use fewer colors/signs/props than adjacent commercial frontage. The signal aperture may use restrained toon-shader emission, but 01D adds no real-time local lights.

The interactable itself should stop reading as a generic glowing cylinder. Its runtime-built marker should become a compact boxy infrastructure module using the approved `gears_toon.gdshader`, with a dark structural core, worn pale housing, sparse cyan signal, and one removed/blank plate cue.

No Sister Kael character model is required. Existing authored Sister Kael HUD/dialogue remains narrative authority.

## Runtime contract

- Production socket path: `GearsDistrictSlice01B/SilentCoreSite/SilentCoreSocket`.
- Existing legacy fallback position `Vector3(8.0, 0.4, -8.0)` remains only for isolated/non-production fixtures where the district socket is absent.
- Runtime still creates exactly one `SilentCore` interactable and registers it with the retained `_interactables` array.
- The interactable starts unpowered and only powers after Mission 02 is COMPLETE through the existing Mission 03 adapter.
- The retained Action target arbitration remains authoritative.
- `MemoryEchoController`, Echo payload, pursuit handoff, fast retry, and Full Replay behavior remain unchanged.
- No new mission phases, generalized destination system, trigger volume, map/GPS, traffic, economy, save-state, camera, vehicle, pursuit, HUD, audio, or interaction framework.

## Bounded production budget

Incremental 01D site additions:

- declarative site mesh instances: `<= 6`;
- interactable runtime marker mesh instances: `<= 5`;
- new collision shapes: exactly `2`, limited to the on-foot maintenance walkway and site pad;
- new real-time local lights: `0`;
- new gameplay state machines: `0`;
- new road acreage: `0`.

## Code-first verification

Exact-head CI must verify:

- `SilentCoreSite` and passive `SilentCoreSocket` exist in the real 01B production scene;
- representative site meshes use `res://materials/gears_toon.gdshader`;
- site adds exactly the two bounded ground colliders and no local lights;
- `AccessWalkway` overlaps the retained industrial-intersection ground collider;
- `SitePadBody` overlaps `AccessWalkway`, making the Core physically reachable from retained gameplay ground;
- the site pad remains outside the industrial-frontage and proof-relay bounding envelopes;
- runtime creates exactly one `SilentCore` and resolves its global position to the production socket rather than the legacy in-yard position;
- the runtime marker uses the approved toon shader on representative housing/signal meshes;
- the runtime marker stays within its mesh budget;
- the Silent Core remains unpowered before Mission 03 unlock;
- retained Action arbitration activates it exactly once after unlock;
- authored HS-7 Echo, pursuit handoff, fast retry, Mission 03 completion, and Full Replay contracts remain green;
- 01B/01C route, Burn garage, camera, vehicle, and canonical compatibility gates remain green.

## Verification debt

Fresh retained-camera screenshots and exact candidate render telemetry remain explicit deferred verification debt under the owner's momentum policy. The change is deliberately small and reversible, and it does not authorize further acreage multiplication.

## Completion recommendation

After 01D passes, stop adding acreage. Re-evaluate the roadmap from current `main`; prefer either another authored location/use of existing geography or a dedicated verification-debt checkpoint before materially multiplying district content.
