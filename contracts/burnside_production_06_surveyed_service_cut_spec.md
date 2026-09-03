# Burnside Production 06 — Gears Surveyed Service Cut / Durable Map-Knowledge Tracer

**Status:** `DESIGN_LOCKED__IMPLEMENTATION_AUTHORIZED`

**Authority:** issue #134, product anchor #55, Burnside Open-World Production Contract #118.

**Starting repository baseline:** `main@cd4cdbe3180c6a372ffa1cfb1cd69bdfaf256961`

**Exact retained Production-05 gameplay/public baseline:** `702678cb66ab7544b43644cfa29baf5361c68dc1`

## Goal

Add the first narrow Durable Mapped Knowledge tracer without turning Burnside into an omniscient GPS game or introducing a generalized save/navigation framework.

The player-facing promise is:

> If I physically discover and traverse the real `ServiceAlley <-> NorthConnector` service cut, the Gears local route sheet remembers that learned geography across Replay and normal application/Web reload, while the current Production-05 physical access state remains separately truthful.

Target feeling:

> “I found a way through the city that wasn’t obvious before. Now I know it, and Burnside knows that I know it.”

## Scope boundary

Production 06 owns exactly:

- one stable surveyed-route ID: `gears.service_alley_north_connector`;
- one traversal qualifier for the retained `ServiceAlley <-> NorthConnector` seam;
- one narrow versioned mapped-knowledge persistence file;
- one on-demand Gears local route sheet;
- one desktop Map key (`M`);
- one safe-area touch Map control;
- one visual/text discovery confirmation;
- focused native, rendered, Web-persistence, and retained-regression proof.

Production 06 does **not** own:

- generalized minimap/GPS/pathfinding;
- route graph or Service Network framework;
- racing lines, breadcrumbs, or turn-by-turn guidance;
- broad fog-of-war;
- mission/inventory/vehicle/checkpoint/cloud persistence;
- save slots;
- vehicle claiming/condition;
- further combat/Health/Armor/damage;
- Heat 2–5;
- witnesses/surveillance;
- Silent Core mapping;
- FB-13/HS-7 navigation;
- PR #44 camera work;
- AudioManager, audio registries, actor audio, or audio assets.

## Existing implementation authority

Retained Production-05 implementation remains authoritative for physical access:

- `GearsScrapperToolRuntime.AccessState.JAMMED`
- `GearsScrapperToolRuntime.AccessState.FORCED_OPEN`
- `GearsScrapperToolRuntime.get_access_state_name()`
- `GearsScrapperToolRuntime.is_service_access_blocking()`
- Replay/reset returns the physical barrier to `JAMMED`.

Production 06 must query that state. It must not duplicate or replace it.

The retained Gears district geometry remains authoritative for route shape:

- `GearsDistrictSlice01B/ServiceAlley`
- `GearsDistrictSlice01B/NorthConnector`
- `GearsDistrictSlice01B/NorthRoad`
- `GearsDistrictSlice01B/IndustrialIntersection`

The route sheet derives its displayed geometry from those authored collision surfaces rather than inventing a second map geometry source.

## Architecture

### `SurveyedRouteProgressStore`

Create one narrow RefCounted persistence boundary in `godot/scripts/progress/surveyed_route_progress_store.gd`.

Responsibilities:

- schema version `1` only;
- stable production file `user://burnside_mapped_knowledge.json`;
- `surveyed_routes` array/set of stable string IDs;
- idempotent `mark_surveyed(route_id)`;
- query `is_surveyed(route_id)`;
- load once on construction/configuration;
- write only supported version-1 documents;
- malformed or unsupported/newer data enters read-only/fail-safe mode and is never silently overwritten;
- test storage is automatically isolated from production owner progress, with an explicit storage-path override seam for deterministic persistence tests.

Canonical version-1 payload:

```json
{
  "version": 1,
  "surveyed_routes": [
    "gears.service_alley_north_connector"
  ]
}
```

No other durable state belongs in this file during Production 06.

### Test-storage isolation

The store must never let automated Godot test scripts read/write the production owner path by default.

If Godot command-line arguments identify execution of a `res://tests/...` script, the default path resolves to an isolated test file under `user://tests/`.

Focused Production-06 persistence tests may supply an explicit deterministic override path. Tests must delete only their own override files.

### `GearsSurveyedServiceCutRuntime`

Create one root-level runtime sibling mounted from the retained Gears district composition seam after Production 05.

Responsibilities:

- own only Production-06 route-survey transient state;
- query the real Production-05 access runtime;
- sample actual player position during production runtime;
- reject discontinuous/teleport-like samples;
- recognize a legitimate traversal between exclusive authored ServiceAlley and NorthConnector regions;
- require access to be physically `FORCED_OPEN` before a traversal can qualify;
- require minimum continuous travel distance before completion;
- record the surveyed route exactly once through `SurveyedRouteProgressStore`;
- keep mapped knowledge through Replay/reset while clearing only transient traversal state;
- create/manage the bounded route-sheet modal and Map control;
- never mutate Wanted, Report, Mission02, pursuer, worker/crawler, or Scrapper authority.

### Traversal qualification

Survey qualification uses actual authored surface footprints plus bounded continuity checks.

A sample may begin traversal only when the player occupies an exclusive side of the route:

- `ServiceAlley` footprint and not `NorthConnector` -> `ALLEY` side;
- `NorthConnector` footprint and not `ServiceAlley` -> `CONNECTOR` side.

The runtime then requires:

1. Production-05 access is `FORCED_OPEN`;
2. subsequent samples remain continuous, with no single horizontal sample jump above the teleport-rejection threshold;
3. accumulated horizontal travel reaches the minimum traversal distance;
4. the player reaches the opposite exclusive side;
5. the route is not already surveyed.

Any rejected discontinuity resets transient traversal qualification and does not grant knowledge.

Merely observing geometry, merely forcing the barrier, or directly relocating between route sides must not survey the route.

### `GearsLocalRouteSheet`

Create one bounded Control presentation in `godot/scripts/ui/gears_local_route_sheet.gd`.

Responsibilities:

- draw ordinary known Gears context from the retained authored `NorthRoad` and `IndustrialIntersection` footprints;
- before survey, omit ServiceAlley/NorthConnector geometry entirely;
- after survey, draw the real authored ServiceAlley and NorthConnector footprints/connection;
- display `KNOWN · ACCESS JAMMED` when surveyed knowledge exists but P05 is currently `JAMMED`;
- display `KNOWN · ACCESS OPEN` when surveyed knowledge exists and P05 is `FORCED_OPEN`;
- never display a jammed route as physically open;
- expose small semantic getters for deterministic tests.

This is a route sheet, not a minimap. It has no player arrow, waypoint, route planning, pathfinding, zoom, destination selection, or world-space line.

## Map input and ownership

### Desktop

`M` is the dedicated Map action. Live source inspection found no retained `M` binding conflict in the current touch/input owner.

### Touch

Production 06 creates one small `MapButton` in the retained `SafeAreaRoot/RightTouchArea` top-right lane, away from the existing Action/Tool/vehicle buttons.

### Availability

The Map action may open only when:

- current UI mode is `FOOT_TRAVERSAL`;
- retained gesture/interactions do not own input;
- the player is not already input-locked by another system.

The Map action is unavailable while driving.

### Modal ownership

While the route sheet is open:

- player locomotion is input-locked;
- generic Action emission is suppressed;
- Tool Action emission is suppressed;
- the Map control remains available to close the sheet;
- full-screen modal pointer capture prevents touch leakage into gameplay controls;
- closing restores the exact pre-map player input-lock value and ordinary dedicated action availability;
- one key/touch activation produces one open/close transition only.

`TouchControlsUI` receives only the smallest modal gate required to suppress its existing Action and Tool Action emissions. Production 06 must not turn it into a generalized modal framework.

## Replay/reset semantics

Replay/reset must:

- retain `surveyed_routes` mapped knowledge;
- reset P05 physical access to `JAMMED` through the retained P05 owner;
- clear only P06 transient traversal arming/distance/sample state;
- close the route sheet if open;
- restore map/input ownership cleanly.

A valid post-Replay state is:

`SURVEYED + JAMMED`.

That state must render as known-but-currently-blocked.

## Existing gameplay authority

Production 06 may not create or clear:

- Heat;
- Contact;
- Search;
- Recognition;
- Reports;
- Mission02 progression;
- pursuer active/stagger state;
- local worker/crawler knowledge.

Surveying is player knowledge only.

## Visual feedback

On first successful survey only, show a restrained text confirmation such as:

`ROUTE SURVEYED · SERVICE ALLEY CUT MAPPED`

No new audio is required or authorized for the first implementation.

## Required focused tests

### Semantics / persistence

1. clean store -> route unknown;
2. route sheet hides the service cut while unknown;
3. observing/standing in one route side -> no survey;
4. forcing `JAMMED -> FORCED_OPEN` alone -> no survey;
5. direct discontinuous teleport between route sides -> no survey;
6. legitimate continuous traversal -> survey recorded exactly once;
7. repeated traversal -> no duplicate state/write;
8. route sheet reveals the service cut after survey;
9. Replay retains mapped knowledge while P05 physical access returns to `JAMMED`;
10. `SURVEYED + JAMMED` -> known/blocked presentation;
11. forcing the known route open -> access presentation becomes usable without rewriting knowledge;
12. fresh store/runtime instance reloads the surveyed route;
13. malformed payload fails safely and is not overwritten;
14. newer unsupported version fails safely and is not overwritten;
15. tests use isolated deterministic storage.

### Input / UI

1. desktop `M` opens/closes once;
2. touch Map opens/closes once;
3. gesture/input lock suppresses Map opening;
4. driving suppresses Map opening;
5. map modal suppresses generic Action;
6. map modal suppresses Tool Action;
7. closing restores dedicated actions without double-fire;
8. safe-area Map control remains inside the resolved safe area.

### Retained regressions

Preserve at minimum:

- Production-05 input and retained input-lock tracers;
- Production-05 service-access/environment tracer;
- Production-05 pursuer stagger tracer;
- Production-05 Mission02 ordering tracer;
- Production-04 work-zone local reaction/report tracer;
- Production-04 Mission02 ordering regression;
- Production-03 pre-triggered suppression + mission/Wanted composition;
- Production-02 Field-Hacking report suppression;
- Production-01 Heat-1 tracer;
- current camera, desktop, touch, vehicle, and interaction contracts.

## Rendered proof

Capture six exact-head images:

1. pre-survey route sheet with service cut absent;
2. P05 access forced open while route remains unsurveyed;
3. first legitimate survey confirmation;
4. post-survey route sheet with accurate cut visible;
5. Replay state with known route + jammed access;
6. same known route after reopening access, showing current usable state.

## Web persistence proof

Production 06 adds a tiny exported Web persistence probe that uses the actual `SurveyedRouteProgressStore` against `user://`.

The CI browser proof must:

1. serve the exported probe from localhost/same origin;
2. first load: write the stable surveyed route and report success;
3. reload the same origin/runtime storage;
4. second load: read the route as surveyed without rewriting it;
5. fail if the browser filesystem is not persistent or the route is absent after reload.

Godot Web maps `user://` to browser IndexedDB; this proof is required in addition to native persistence tests and ordinary Web export/static-hosting smoke.

## Completion gate

Production 06 may merge only after:

`RED observed -> GREEN focused semantics/UI -> rendered proof -> retained regressions -> literal-head Web -> same-origin reload proof -> synthetic-merge Web -> frozen Standards + #134/spec review -> merge -> exact-main Web/public verification -> continuity update`.

Build success alone is not completion.