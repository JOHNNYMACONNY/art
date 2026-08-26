# Visual Direction Wayfinder

**START HERE for visual-direction work.**

This file routes humans and coding agents to the current visual canon without duplicating the detailed specs. If a linked source conflicts with another source, use the precedence rules below rather than inventing a compromise.

## Current state

- **Approved direction:** Civic Salvage Palimpsest / Industrial Cel-Shaded Near Future
- **Current canon head when this wayfinder was created:** `9686f8d88a7e926de8cfd544afe392378ca917bf`
- **Current implementation gate:** Open World Expansion 01A — Gears in-engine visual style proof, issue `#60`
- **Large-scale Gears production:** wait for the bounded in-engine proof to pass
- **Gameplay foundations:** preserve existing camera, controls, vehicles, pursuit, mission HUD, retry/reset and other retained systems unless visual proof exposes a concrete readability problem

## One-paragraph visual thesis

Gears District is a dense, functioning municipal-industrial place built from repurposed advanced technology, salvage economics, small businesses, civic bureaucracy and buried infrastructure. The world is stylized and graphic rather than photoreal: broad cel-shaded value groups, selective contours, anime/mecha design discipline for people/robots/vehicles, strong physical signage and GTA-family gameplay readability without copying GTA assets, branding, characters, locations, UI, writing or map layouts. Technology is ordinary infrastructure: bought, serviced, patched, stolen, relabeled, regulated and misunderstood. The setting must not collapse into generic neon cyberpunk, glossy sci-fi futurism or post-apocalyptic ruin.

## Authority / precedence

Use the freshest directly approved source for the category being changed.

1. `GEARS_DISTRICT_VISUAL_DIRECTION_APPROVAL.md` — overall approved visual canon and production gate.
2. `GEARS_DISTRICT_HUMANOID_BOT_VISUAL_FAMILY_APPROVAL.md` — approved humanoid-bot family; wins for humanoid-bot questions.
3. `GEARS_DISTRICT_VISUAL_DIRECTION_V2_CONVERGENCE.md` — detailed converged rendering/category rules. Where v1 and v2 differ, v2 wins.
4. `GEARS_DISTRICT_VISUAL_DIRECTION_V1.md` — broader exploratory/detail source where not superseded.
5. `GEARS_DISTRICT_CONCEPT_BOARD_01_BRIEF.md` — concept-board composition/communication brief; not an authority over later approvals.
6. `REFERENCE_ATLAS.md` — provenance and extracted-reference logic. Reference material does **not** override approved canon.
7. Implementation notes/tickets — define current execution scope; they do not silently rewrite visual canon.

Proposed department, business and location names in earlier documents remain **PROPOSED** unless separately approved as narrative canon.

## Category map

| Category | Current direction | Authoritative detail |
|---|---|---|
| Rendering | Industrial cel-shaded; broad value bands; selective contours; matte/satin baseline | Approval + v2 |
| Architecture | stacked 2–5 storey mixed-use industrial/commercial/residential; bolt-on utilities; landmark infrastructure | Approval + v2 |
| District readability | elevated 3/4 camera; clear routes, shortcuts, silhouettes and orientation anchors | Approval + v1/v2 |
| Humans | anime-influenced faces/proportions; practical occupational clothing and gear; class/job/neighborhood drive silhouette | Approval + v2 |
| Compact robots | functional, characterful, repaired, serial-numbered; personality through proportion/gait/history | Approval + v2 |
| Humanoid bots | supporting family; visibly mechanical and occupational, not synthetic-human | Humanoid-bot approval |
| Civilian vehicles | retro-utility near-future; compact/boxy or strongly role-driven; modular panels/cargo/sensors | Approval + v2 |
| Courier Bike | compact modular hero bike; oversized practical tires; low center; strong cargo/signal and top silhouette | Approval + v2 |
| Enforcement | bureaucratic pursuit fleet; institutional first, threatening second; strong civic livery | Approval + v2 |
| Signage/branding | municipal, commercial, aftermarket/subculture, criminal/gray-market spoof families | Approval + v2 |
| Props/street furniture | obvious function + chunky silhouette + replaceable panels + serial/inspection graphics | v2 |
| Lighting | practical light first; warm/amber civic/industrial, restrained cool utilities; neon/emissive punctuation only | Approval + v1/v2 |
| Silent Core / Sister Kael | obsolete advanced infrastructure with ritual seriousness; sparse signal cyan; no fantasy shrine language | Approval + v2 |
| HUD relationship | retain functional HUD; physical bureaucracy and HUD share underlying graphic logic without replacing HUD contract | v1/v2 |

## Approved visual invariants

- **Readability before detail.** Hero assets should read in 3–5 major value/color masses at gameplay distance.
- **Silhouette before texture.** Player, Courier Bike, pursuit vehicle, robots and landmark anchors cannot depend on tiny details.
- **Saturation is information.** Bright color marks identity, hazard, brand, enforcement, mission or signal/memory meaning.
- **Wear follows use.** Repairs, grime, chipping and rust belong at plausible contact, drainage, impact and replacement zones.
- **Function before futurism.** Vehicles, robots, props and architecture must visibly explain what they do.
- **Practical light before neon.** Night should remain a working district, not a neon wallpaper.
- **Systems satire over random jokes.** Civic graphics and world copy target institutions, procurement, compliance and bureaucracy.
- **Mystery is rare.** HS-7/Silent Core visual phenomena stay scarce enough to reorganize the frame when they appear.
- **Humanoid bots stay mechanical.** Human-shaped because the built environment is human-shaped; not because they imitate humans.
- **GTA-family influence is experiential, not derivative.** Use clarity, immediacy, memorable silhouettes/businesses/vehicles and crime-world satire; do not copy protected visual assets or layouts.

## Avoid / drift checks

Stop and reassess if work starts trending toward any of these without explicit approval:

- neon-everywhere cyberpunk;
- glossy pristine future-city design;
- generic post-apocalyptic rust wash;
- photoreal surface detail that destroys the graphic read;
- anime characters pasted into an unrelated realistic environment;
- every civilian/robot/vehicle becoming a hero design;
- realistic synthetic-human androids as ordinary population;
- military-mech language as the default for enforcement;
- tiny typography or greeble density carrying gameplay-critical information;
- fantasy/cathedral/crystal visual language for Silent Core;
- wholesale HUD/camera/gameplay redesign justified only by art preference.

## Humanoid-bot quick router

Approved lanes:

1. municipal maintenance;
2. salvage / yard labor;
3. civic service;
4. municipal enforcement support;
5. Echotel service;
6. obsolete / reclaimed.

Normal units should expose occupational function, mechanical joints/panels, asset IDs and repair/reassignment history. Realistic human faces/skin are not the baseline. Special narrative units may break normal patterns only when authored and approved.

## Current implementation gate — Issue #60

Open World Expansion 01A should prove the approved style in the real Godot runtime at the retained elevated 3/4 camera before full district production.

Minimum proof themes:

- cel-shaded value grouping / selective contours;
- representative stacked Gears structure;
- primary route + alternate/shortcut;
- municipal silhouette anchor;
- storefront/signage treatment;
- ordinary resident/worker treatment;
- Courier Bike;
- civilian/utility vehicle;
- pursuit vehicle;
- utility robot or a humanoid maintenance/salvage substitute if that is genuinely the smaller proof;
- distant infrastructure/Silent Core-adjacent cue;
- restrained practical lighting;
- runtime captures + code verification + telemetry.

Do not expand Issue #60 into full district production.

## How to use this during implementation

For Codex or another repo-aware agent:

1. Verify repo, branch/worktree, `main`, dirty state and relevant runtime before changing anything.
2. Read this file.
3. Read only the category authority linked above that affects the task.
4. Read the current issue/ticket scope.
5. Inspect the actual Godot/runtime implementation before assuming docs match code.
6. Make the smallest reversible implementation that proves the desired player-facing result.
7. Verify gameplay/readability/performance relevant to the change.
8. If runtime reality conflicts with the visual spec, report the conflict. Do not silently rewrite canon.

Suggested agent preamble:

> Read `docs/visual_direction/README.md` first. Follow its authority map. Treat approved visual docs as creative truth and repo/runtime behavior as implementation truth. Do not reinterpret reference material against approved canon. Preserve retained gameplay systems unless an observed visual/readability problem justifies a bounded change.

## Updating visual canon

When a new visual decision is approved:

- add or update the narrowest authoritative category document;
- update this Wayfinder only if routing/status/precedence changes;
- update `REFERENCE_ATLAS.md` only when provenance or extracted reference logic changes;
- keep `PROPOSED`, `CANDIDATE`, `APPROVED`, `IMPLEMENTED`, `EXPERIMENTAL` and `UNKNOWN` explicit;
- never convert inspiration material into canon without an approval decision;
- never silently canonize names, mechanics, sentience, population behavior or narrative implications from a visual design alone.

## Files in this directory

- `README.md` — **START HERE / wayfinder**
- `REFERENCE_ATLAS.md` — reference families, provenance and extracted rules
- `GEARS_DISTRICT_VISUAL_DIRECTION_APPROVAL.md` — overall approval / production gate
- `GEARS_DISTRICT_VISUAL_DIRECTION_V2_CONVERGENCE.md` — converged detailed direction
- `GEARS_DISTRICT_VISUAL_DIRECTION_V1.md` — original detailed package
- `GEARS_DISTRICT_CONCEPT_BOARD_01_BRIEF.md` — concept-board brief
- `GEARS_DISTRICT_HUMANOID_BOT_VISUAL_FAMILY_APPROVAL.md` — humanoid-bot visual canon
- `GEARS_DISTRICT_HUMANOID_BOT_IMPLEMENTATION_NOTE.md` — bounded implementation note
