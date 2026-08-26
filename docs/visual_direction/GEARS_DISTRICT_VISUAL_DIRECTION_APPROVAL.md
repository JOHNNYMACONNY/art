# Gears District Visual Direction — Owner Approval

**Milestone:** Visual Direction / Concept Art  
**Decision:** `APPROVED`  
**Approved direction:** **Civic Salvage Palimpsest / Industrial Cel-Shaded Near Future**  
**Gameplay baseline:** `b22044670aee70ec5d349c6ac094f7b6d8323992`  
**Approval evidence:** owner review of the converged v2 direction and representative visual-direction board, 2026-08-25.

This decision promotes the surviving rules in `GEARS_DISTRICT_VISUAL_DIRECTION_V1.md` and `GEARS_DISTRICT_VISUAL_DIRECTION_V2_CONVERGENCE.md` from candidate guidance to visual canon, subject to the precedence and implementation-proof rules below.

## Approved visual thesis

Gears District is a dense, working municipal-industrial district built from repurposed advanced technology, salvage economics, small businesses, civic bureaucracy and buried infrastructure. It is stylized and graphic rather than photoreal, with anime/mecha design discipline for people, robots and vehicles and strong elevated-camera readability.

The world should feel like advanced technology that arrived years ago, became ordinary infrastructure, was privatized, repaired, legislated, relabeled and kept running.

It must not collapse into generic neon cyberpunk, glossy sci-fi futurism, post-apocalyptic ruin, or a literal imitation of GTA visual assets, UI, branding, characters, locations or map layouts.

## Approved rendering target

**Industrial Cel-Shaded Near Future**

- broad, readable value/color groups;
- cel-shaded or stepped lighting on hero assets and important architecture;
- selective contour emphasis rather than outlines on every surface;
- grounded architecture/material logic;
- anime-influenced human faces, silhouettes and fashion/gear design;
- mecha-industrial robots and vehicles with obvious function;
- matte/satin materials as baseline;
- practical lighting first, emissive/neon as punctuation;
- saturation used as information;
- localized wear based on use and repair history;
- high-frequency detail subordinate to gameplay readability.

## Approved world-design rules

### Architecture

- stacked 2–5-storey mixed-use industrial/commercial/residential forms;
- bolt-on utilities, stairs, balconies, repair panels and rooftop equipment;
- infrastructure landmarks instead of a default skyscraper skyline;
- major routes remain visually calmer than sidewalks, yards and facades;
- each important block/intersection gets a readable silhouette/orientation anchor.

### Humans

- stylized anime-influenced faces and proportions without full-cartoon world rendering;
- occupation, class, neighborhood and hustle drive silhouette;
- practical layered clothing, workwear, bags, helmets and modular gear;
- prosthetics/augmentations are selective rather than universal;
- ordinary residents use simpler variants of the same design grammar.

### Robots

- compact, functional, characterful silhouettes;
- visible maintenance panels, serial IDs and replacement modules;
- personality through proportion, gait and repair history rather than decorative anthropomorphism;
- FB-13 remains a key micro-scale identity anchor: worn pale shell, dark structural core, sparse signal light, practical asymmetry.

### Vehicles

- retro-utility near-future language;
- compact/boxy or strongly role-driven silhouettes;
- modular cargo, sensor and replacement-panel logic;
- front/rear distinction readable from elevated 3/4 view;
- civilian vehicles remain simpler than mission/enforcement vehicles.

### Courier Bike

- compact modular courier machine;
- oversized practical tires;
- low center of mass;
- chunky central body/battery module;
- exposed mechanical structure where useful;
- strong cargo/signal structure and clear top silhouette;
- distinct from civilian/enforcement bikes without relying on texture detail.

### Enforcement fleet

- bureaucratic pursuit fleet: institutional first, threatening second;
- compact wedge/boxy fleet chassis;
- strong civic livery, roof IDs and readable markings;
- integrated sensors, beacons and interception hardware;
- modest armor rather than military-APC language;
- visual joke/critique: municipal authority weaponized through procurement.

### Graphic design

Four world graphic families are approved:

1. **Municipal/civic:** rigid grids, numbers, route bands, permits, stencils, clipped-corner plates, restrained off-white/charcoal/amber/teal.
2. **Commercial/neighborhood:** custom sign silhouettes, reused substrates, louder local color, retro-future/Y2K influence filtered through believable local businesses.
3. **Aftermarket/subculture:** stickers, tuner/cheap-tech/pirate-radio/streetwear wordmarks and product graphics.
4. **Criminal/gray-market spoof:** copied civic typography, altered permits, counterfeit seals and businesses that appear compliant until understood.

Hero signage communicates in this order: **shape -> color/value -> icon -> 1–3 readable words**.

### Silent Core / Sister Kael

- obsolete/advanced infrastructure whose significance outlived its understood purpose;
- quieter negative space and reduced commercial density;
- ritual conveyed through maintenance, placement, repetition and human care;
- sparse HS-7 cyan/memory phenomena remain visually special;
- no glowing crystal shrine, sci-fi cathedral, generic holographic altar or neon mysticism.

## Canon precedence

Where v1 and v2 differ, **v2 wins**. This approval document wins over both for status and gate interpretation.

Proposed names in earlier documents remain **PROPOSED** unless separately approved as narrative canon. Visual approval does not silently canonize department, business or location names.

## Engineering proof gate

Visual direction is approved. **Implementation quality is not yet proven.**

Before large-scale Gears District asset/world production, engineering must build the smallest useful in-engine style proof using the retained elevated 3/4 camera and current gameplay foundations.

The proof should test, in one representative playable slice:

- cel-shaded value grouping and selective contours;
- one stacked mixed-use Gears structure;
- one readable primary route + shortcut;
- one local storefront/signage family;
- one ordinary worker/civilian treatment;
- Courier Bike visual treatment;
- one civilian/utility vehicle;
- one municipal pursuit vehicle;
- one small utility robot;
- one infrastructure landmark/silhouette cue;
- restrained practical day/dusk lighting;
- route, player, vehicle and pursuit readability at actual gameplay camera distance.

Reuse current systems and modular assets where useful. Do not build the district just to prove the shader/style.

### Pass criteria

The proof passes when:

1. the approved identity survives actual gameplay camera distance;
2. player, vehicle, pursuit and route readability are not degraded;
3. material/shader treatment is maintainable and does not require excessive bespoke asset work;
4. performance remains within the existing development baseline on the measured desktop target;
5. the style can plausibly scale across a dense district without every asset becoming hero-detail expensive.

Real mobile performance remains `UNKNOWN` until measured on real hardware.

## Production gate

`VISUAL_DIRECTION_APPROVED__ENGINE_STYLE_PROOF_REQUIRED`

Open World Expansion 01 may now enter **bounded implementation experimentation and technical decomposition**, but full district asset/world production should wait for the in-engine style proof above.
