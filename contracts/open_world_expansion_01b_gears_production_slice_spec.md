# Open World Expansion 01B — Gears Production Slice

**State:** READY_FOR_IMPLEMENTATION  
**Baseline:** `main@ade4e51c147556f3e2964a22fce7c070a5c3737e`  
**Predecessor:** Issue #60 / PR #63 — bounded in-engine style proof  
**Creative authority:** `docs/visual_direction/README.md`, `REFERENCE_ATLAS.md`, and the approved Gears visual-direction documents

## Objective

Promote the approved Gears visual language into the smallest real contiguous district-production increment beyond the retained yard without beginning full-district production.

The slice should make the current yard feel like one location inside a larger district by adding one traversable northbound block that connects directly to the existing gameplay floor and contains one readable intersection, one alternate service route, one commercial frontage, one industrial frontage, and one neutral mission-ready destination socket.

## Player-facing topology

The production increment is:

`retained yard north edge -> primary industrial road -> industrial intersection -> north continuation`

with one alternate path:

`intersection -> narrow service alley -> north connector -> primary road`

The alternate path is spatial production only. It does not introduce new route-switch logic, mission branching, traffic AI, or Signal Gate authority.

## Required production content

1. A real traversable primary-road collision surface extending beyond the current 40×40 gameplay floor.
2. One traversable industrial intersection connected to that road.
3. One narrower traversable service alley that rejoins the primary route through a second connector.
4. One stacked commercial frontage using approved Gears value/color/signage hierarchy.
5. One industrial/municipal frontage using approved repair-history and civic utility language.
6. One neutral `Marker3D` mission-destination socket with no mission ownership or trigger behavior.
7. One temporary expansion-edge safety barrier so the currently finite slice does not invite the player into missing geometry.
8. Reuse the approved lightweight toon material path and restrained accent palette; do not add a new renderer/shader stack.

## Architecture

Create a separate production scene:

`godot/scenes/world/gears_district_slice_01b.tscn`

and integrate it additively into:

`godot/scenes/prototype/scrap_test_block.tscn`

The Issue #60 `GearsStyleProof` scene remains a separate proof/foundation layer. Do not silently rewrite it into the district-production scene.

The production scene may have a tiny contract/introspection script but must not own:

- player movement;
- camera behavior;
- Courier Bike or Scrap Hauler behavior;
- pursuit/interception;
- Signal Gate/action ownership;
- mission state machines;
- retry/replay;
- HUD/input/audio authority.

## Collision and route constraints

- New collision is allowed because 01B is real traversable world production, but it must be additive and outside the retained gameplay geometry except for a small continuity seam at the existing north edge.
- Primary traversable width: at least 6.0 m.
- Service-alley traversable width: at least 3.0 m.
- New northbound traversable depth beyond the old floor edge: at least 24 m.
- Commercial/industrial building collision must remain outside the authored drive corridor.
- No new collision may alter existing yard obstacle transforms or route geometry.

## Bounded production budget

This is one block, not a district pass.

- production-scene mesh instances: `<= 36`;
- production-scene collision shapes: `<= 10`;
- real-time local lights added by 01B: `0`;
- new gameplay scripts/state machines: `0`;
- new mission triggers: `0`.

## Code-first verification

The exact-head CI gate must verify:

- the production scene loads and is integrated into the real playable scene;
- retained camera exists with unchanged 32° FOV;
- all three traversable surfaces have real `CollisionShape3D` nodes;
- primary/alley widths and northbound depth satisfy this contract;
- service alley has two route connections rather than being a dead-end decoration;
- mission socket is a passive `Marker3D`;
- the temporary expansion-edge barrier has collision;
- production mesh/collision counts remain within budget;
- no mission/camera/player/vehicle/pursuit scripts are owned by the production scene;
- existing exact-head camera and canonical compatibility suites remain green.

## Deferred perceptual/performance qualification

Owner direction explicitly prioritizes roadmap momentum. Fresh visual captures and exact candidate desktop render telemetry remain useful verification debt rather than a routine merge blocker for this incremental slice.

Do not multiply this block into full Gears District acreage before a later verification checkpoint resolves retained-camera readability and performance at representative district scale.

## Completion recommendation

On code/review pass, the next increment should remain one bounded geography/content concern at a time—preferably converting one existing authored mission destination into a real location within the expanded district before adding more acreage.
