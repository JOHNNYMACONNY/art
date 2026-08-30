# Visual Direction Wayfinder

**START HERE for visual-direction work.**

Project-level routing lives in `START_HERE.md`. This file routes visual/world work to approved creative authority without duplicating the detailed canon.

## Current state

- **Approved direction:** Civic Salvage Palimpsest / Industrial Cel-Shaded Near Future.
- **Visual gate:** complete.
- **Issue #60 / Open World Expansion 01A:** complete.
- **01B / PR #64:** merged — first contiguous Gears production block.
- **01C / PR #65:** merged — Mayor Burn garage integration.
- **01D / PR #66:** merged — Silent Core infrastructure integration.
- **Current visual/world NEXT:** Issue #89 — retained-camera readability & desktop performance checkpoint.
- **Large-scale expansion:** do not multiply acreage until #89 resolves the accumulated representative readability/performance debt or records an explicit blocker.
- **Gameplay foundations:** preserve retained camera, controls, vehicles, pursuit, mission HUD, retry/reset and other authorities unless evidence exposes a concrete weakness.

Humanoid bots are an **approved supporting visual family**, not a requirement for every increment.

## One-paragraph visual thesis

Gears District is a dense, functioning municipal-industrial place built from repurposed advanced technology, salvage economics, small businesses, civic bureaucracy and buried infrastructure. The world is stylized and graphic rather than photoreal: broad cel-shaded value groups, selective contours, anime/mecha design discipline for people/robots/vehicles, strong physical signage and GTA-family gameplay readability without copying GTA assets, branding, characters, locations, UI, writing or map layouts. Technology is ordinary infrastructure: bought, serviced, patched, stolen, relabeled, regulated and misunderstood. The setting must not collapse into generic neon cyberpunk, glossy sci-fi futurism or post-apocalyptic ruin.

## Authority / precedence

Use the freshest directly approved source for the category being changed.

1. `GEARS_DISTRICT_VISUAL_DIRECTION_APPROVAL.md` — overall approved visual canon.
2. `GEARS_DISTRICT_HUMANOID_BOT_VISUAL_FAMILY_APPROVAL.md` — approved humanoid-bot family; wins for humanoid-bot questions.
3. `GEARS_DISTRICT_VISUAL_DIRECTION_V2_CONVERGENCE.md` — detailed converged rendering/category rules; where v1 and v2 differ, v2 wins.
4. `GEARS_DISTRICT_VISUAL_DIRECTION_V1.md` — broader exploratory/detail source where not superseded.
5. `GEARS_DISTRICT_CONCEPT_BOARD_01_BRIEF.md` — concept-board communication brief; not authority over later approvals.
6. `REFERENCE_ATLAS.md` — provenance and extracted-reference logic. Reference material does **not** override approved canon.
7. Current implementation ticket/spec — defines execution scope only; it does not silently rewrite visual canon.

Proposed department, business and location names in earlier documents remain **PROPOSED** unless separately approved as narrative canon.

## Category map

| Category | Current direction | Authority |
|---|---|---|
| Rendering | Industrial cel-shaded; broad value bands; selective contours; matte/satin baseline | Approval + v2 |
| Architecture | stacked 2–5 storey mixed-use industrial/commercial/residential; bolt-on utilities; landmark infrastructure | Approval + v2 |
| District readability | retained elevated 3/4 camera; clear primary/alternate routes, silhouettes and orientation anchors | Approval + v1/v2 |
| Humans | anime-influenced faces/proportions; practical occupational clothing and gear | Approval + v2 |
| Compact robots | functional, repaired, serial-numbered; personality through proportion/gait/history | Approval + v2 |
| Humanoid bots | supporting family; visibly mechanical and occupational, not synthetic-human | Humanoid-bot approval |
| Civilian vehicles | retro-utility near-future; role-driven silhouettes; modular panels/cargo/sensors | Approval + v2 |
| Courier Bike | compact modular hero bike; oversized practical tires; low center; strong cargo/signal silhouette | Approval + v2 |
| Enforcement | bureaucratic pursuit fleet; institutional first, threatening second; strong civic livery | Approval + v2 |
| Signage/branding | municipal, commercial, aftermarket/subculture, criminal/gray-market spoof families | Approval + v2 |
| Props/street furniture | obvious function + chunky silhouette + replaceable panels + serial/inspection graphics | v2 |
| Lighting | practical light first; warm/amber civic/industrial, restrained cool utilities; emissive punctuation only | Approval + v1/v2 |
| Silent Core / Sister Kael | obsolete advanced infrastructure with ritual seriousness; sparse signal cyan; no fantasy shrine language | Approval + v2 |
| HUD relationship | retain functional HUD; physical bureaucracy and HUD share graphic logic without replacing HUD contract | v1/v2 |

## Approved invariants

- **Readability before detail.** Hero assets read in 3–5 major value/color masses at gameplay distance.
- **Silhouette before texture.** Player, Courier Bike, pursuit vehicle, robots and landmarks cannot depend on tiny details.
- **Saturation is information.** Bright color marks identity, hazard, brand, enforcement, mission or signal/memory meaning.
- **Wear follows use.** Repairs, grime, chipping and rust belong at plausible contact, drainage, impact and replacement zones.
- **Function before futurism.** Vehicles, robots, props and architecture visibly explain what they do.
- **Practical light before neon.** Night remains a working district, not neon wallpaper.
- **Systems satire over random jokes.** Civic graphics/world copy target institutions, procurement, compliance and bureaucracy.
- **Mystery is rare.** HS-7/Silent Core phenomena stay scarce enough to reorganize the frame when they appear.
- **Humanoid bots stay mechanical.** Human-shaped because the built environment is human-shaped, not because they imitate humans.
- **GTA-family influence is experiential, not derivative.** Use clarity, immediacy, memorable silhouettes/businesses/vehicles and crime-world satire; do not copy protected assets or layouts.

## Drift checks

Stop and reassess if work trends toward:

- neon-everywhere cyberpunk;
- glossy pristine future-city design;
- generic post-apocalyptic rust wash;
- photoreal surface detail that destroys the graphic read;
- anime characters pasted into an unrelated realistic environment;
- every civilian/robot/vehicle becoming a hero design;
- realistic synthetic-human androids as ordinary population;
- military-mech language as default enforcement;
- tiny typography or greeble density carrying gameplay-critical information;
- fantasy/cathedral/crystal language for Silent Core;
- wholesale HUD/camera/gameplay redesign justified only by art preference.

## Current implementation routing

### HISTORICAL / COMPLETE

- #60 / 01A proved the approved style in-engine.
- 01B established the first real contiguous Gears production block.
- 01C authored Mayor Burn's garage inside that geography.
- 01D authored the Silent Core infrastructure pocket inside that geography.
- 01E / Issue #89 qualified retained-camera readability and desktop render cost (`VISUAL_PERF_CHECKPOINT_PASS`).

Do not recreate these because an older document describes them as future work.

### NEXT

Exploit the qualified Gears production slice with bounded authored missions/events before authorizing further district expansion.

## Implementation use

For Codex or another repo-aware agent:

1. Verify repo, branch/worktree, `main`, dirty state, open PRs and relevant runtime evidence.
2. Read `START_HERE.md`.
3. Read this file.
4. Read only the narrow authority that affects the task.
5. Read the current issue/ticket scope.
6. Inspect actual Godot/runtime implementation before assuming docs match code.
7. Make the smallest reversible change that proves the desired player-facing result.
8. Verify gameplay/readability/performance relevant to the change.
9. If runtime reality conflicts with visual canon, report the conflict; do not silently rewrite canon.

Suggested agent preamble:

> Read `START_HERE.md`, then `docs/visual_direction/README.md`. Treat approved visual docs as creative truth and repo/runtime behavior as implementation truth. References do not override canon. Preserve retained gameplay systems unless an observed readability problem justifies a bounded change.

## Updating visual canon

When a new visual decision is approved:

- update the narrowest authoritative category document;
- update this wayfinder only if routing/status/precedence changes;
- update `REFERENCE_ATLAS.md` only when provenance or extracted-reference logic changes;
- keep `PROPOSED`, `CANDIDATE`, `APPROVED`, `IMPLEMENTED`, `EXPERIMENTAL` and `UNKNOWN` explicit;
- never convert inspiration into canon without approval;
- never silently canonize names, mechanics, sentience, population behavior or narrative implications from visual design alone.

## Files in this directory

- `README.md` — visual START HERE / authority router
- `REFERENCE_ATLAS.md` — reference families, provenance and extracted rules
- `GEARS_DISTRICT_VISUAL_DIRECTION_APPROVAL.md` — overall approval
- `GEARS_DISTRICT_VISUAL_DIRECTION_V2_CONVERGENCE.md` — converged detailed direction
- `GEARS_DISTRICT_VISUAL_DIRECTION_V1.md` — original detailed package
- `GEARS_DISTRICT_CONCEPT_BOARD_01_BRIEF.md` — concept-board brief
- `GEARS_DISTRICT_HUMANOID_BOT_VISUAL_FAMILY_APPROVAL.md` — humanoid-bot visual canon
- `GEARS_DISTRICT_HUMANOID_BOT_IMPLEMENTATION_NOTE.md` — bounded implementation note