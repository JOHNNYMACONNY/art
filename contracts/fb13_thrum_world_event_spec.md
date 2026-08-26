# World Event 01 — FB-13 Infrastructure Thrum

**State:** READY_FOR_IMPLEMENTATION  
**Baseline:** `main@172a56b3e896162eb69902f3e639b05296e3d848`  
**Product direction:** exploit existing Gears geography before adding acreage  
**Canon sources:** `skills/echos-in-the-scrap/SKILL.md`, `contracts/world-event.schema.json`, approved Gears visual-direction documents, and retained FB-13 identity from the legacy prototype

## Objective

Make FB-13 materially present in the production Godot slice through one bounded authored world event without introducing a companion-AI framework, new input, combat behavior, mission phase, route system, or additional geography.

When the player enters the existing industrial-frontage mechanism zone during a calm/non-priority audio state, FB-13 emits one characteristic low thrum and nearby municipal/utility hardware briefly resonates. The event should feel like a compact companion response to machinery, not a mission objective or magical signal phenomenon.

## Canon / semantics

The legacy prototype establishes FB-13 as a close companion whose characteristic thrum can make mechanisms resonate. `contracts/world-event.schema.json` already recognizes the semantic directive `thrum_spike`.

This Godot increment does **not** port the legacy prototype's combat-era controls or create a network/Nostr world-event runtime. It only uses the existing directive vocabulary as the authored semantic identity for a local production event.

Canonical event payload exposed by the runtime contract:

- `directive`: `thrum_spike`
- `actor`: `FB-13`
- `zone`: `gears_industrial_frontage`
- `severity`: `0.30`
- `ttl_msec`: `650`

## Trigger topology

Use the existing production mechanism:

`GearsDistrictSlice01B/IndustrialFrontage/CivicUtilityPlate`

as the authored trigger anchor.

Behavior:

1. Player enters within `5.5 m` of the anchor.
2. Event is eligible only when retained audio priority is not `DISTURBANCE`, `PURSUIT_PRESSURE`, or `MEMORY_ECHO`.
3. If armed and off cooldown, trigger exactly once.
4. Play the retained `AudioManager` FB-13 thrum event spatially at the mechanism anchor.
5. Briefly pulse only these existing mechanism meshes:
   - `GearsDistrictSlice01B/IndustrialFrontage/CivicUtilityPlate`
   - `GearsDistrictSlice01B/IndustrialFrontage/UtilitySpine`
6. Event remains disarmed while the player stays in the zone.
7. Player must leave beyond `8.0 m` and the `6.0 s` cooldown must expire before another thrum can trigger.

The event is not mission-gated. It is ambient authored world behavior and may occur during quiet traversal before, between, or after missions.

## Visual contract

- Reuse the current `gears_toon.gdshader` materials already assigned to the industrial mechanisms.
- Do not add new meshes, collision, local lights, outlines, particles, screen-space FX, HUD elements, or HS-7 cyan signal language.
- Pulse by temporarily duplicating each target's existing material, setting emission from its own current base color, then restoring the exact original material after `650 ms`.
- FB-13 resonance must remain a small infrastructure response. It must not read as a Silent Core/memory event, quest marker, nightclub/neon effect, or supernatural shockwave.

## Audio contract

Extend the existing `AudioManager.SoundEvent` enum by **appending** `FB13_THRUM`; do not reorder existing ordinals.

`FB13_THRUM` must:

- remain owned by `AudioManager.play_event()`;
- be spatial/diegetic at the mechanism anchor;
- use the retained procedural synthesis path;
- be lower and more mechanical than Memory Echo or completion chimes;
- respect the existing transient voice budget;
- increment normal `AudioManager.event_counts` exactly once per accepted trigger;
- require no new audio bus, global mix state, radio authority, or continuous loop.

## Architecture

Add one production node under the real playable scene:

`FB13ThrumWorldEvent`

with one bounded script, recommended path:

`godot/scripts/world/fb13_thrum_world_event.gd`

The node may own only:

- trigger radius / rearm hysteresis;
- cooldown;
- current pulse lifecycle;
- local event count and last-event contract snapshot;
- temporary duplicate/restore of the two target materials;
- one call into retained `AudioManager.play_event()`.

It must not own or modify:

- player movement;
- camera;
- input mapping or Action arbitration;
- mission state;
- pursuit;
- vehicles;
- radio state;
- Memory Echo state;
- HUD;
- save state;
- district geometry/collision;
- network/Nostr directives;
- generalized companion/world-event registries.

## Code-first verification

Exact-head CI must verify in the real playable scene:

- `FB13ThrumWorldEvent` exists and exposes the authored contract;
- directive/actor/zone/severity/TTL match this spec;
- trigger/rearm/cooldown radii match this spec;
- the two resonance targets are the existing production mechanism meshes and use the approved toon shader;
- entering the zone from outside triggers exactly once;
- `AudioManager.get_event_count(AudioManager.SoundEvent.FB13_THRUM)` increments exactly once;
- both target meshes temporarily receive duplicate pulse materials;
- after the TTL, both exact original material resources are restored;
- repeated evaluation while still inside does not retrigger;
- leaving beyond `8.0 m`, allowing the `6.0 s` cooldown to expire, then re-entering triggers a second time;
- `DISTURBANCE`, `PURSUIT_PRESSURE`, and `MEMORY_ECHO` suppress triggering without consuming the armed state;
- no collision/light/HUD/input/mission nodes are added by this event;
- retained 01B–01D, Burn garage, Silent Core, camera, vehicle, mission, and canonical compatibility suites remain green.

## Perceptual/audio debt

Human/windowed listening and fresh retained-camera visual observation remain useful perceptual verification debt. Code-first acceptance may prove trigger semantics, spatial event routing, material lifecycle, and ownership boundaries, but must not be represented as a human listening-quality judgment.

## Completion recommendation

After this event passes, prefer another small world-use/content increment only if it has stronger visible product value than resolving accumulated visual/performance/audio verification debt. Do not use this event as precedent for a generalized companion AI, world-event bus, combat system, or additional acreage.
