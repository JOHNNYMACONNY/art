# Gears District Visual Direction Package v1

**Milestone:** Visual Direction / Concept Art  
**Status:** `CANDIDATE__OWNER_APPROVAL_REQUIRED`  
**Source gameplay baseline:** `b22044670aee70ec5d349c6ac094f7b6d8323992`  
**Source continuity head:** `9cb61a2e97022e574f66b0c642d4a2315513adf8`  
**Next implementation milestone:** Open World Expansion 01 — Gears District, **blocked until this package is approved**.

## 0. Status language

- **IMPLEMENTED** — already present in the Godot production slice and treated as a compatibility boundary unless a concrete readability problem appears.
- **PROPOSED** — exploratory visual option; not canon.
- **CANDIDATE** — preferred direction under evaluation; engineering may estimate against it but must not treat it as production canon yet.
- **APPROVED** — owner-approved visual canon / implementation constraint.

**APPROVED visual rules in this document: none yet.** The complete package below is a coherent CANDIDATE for owner review.

---

# 1. Direction search

Three broad directions were considered against the current game, retained elevated 3/4 camera, FB-13 / HS-7 identity, missions, and the requirement to avoid generic neon cyberpunk.

## PROPOSED A — Civic Salvage Modernism

A heavy civic-industrial city assembled from poured concrete, utility depots, logistics buildings and salvaged additions. Strong massing and very readable from distance. Risk: can become too visually sober and lose the crime-satire voice.

## PROPOSED B — Paperwork Industrial

The city is visually dominated by permits, inventory numbers, route bands, inspection stamps, procurement plates, warning panels and contradictory civic notices. Strong satire and graphic identity. Risk: can become a wall of illegible text at gameplay camera distance.

## PROPOSED C — Utility Palimpsest

Infrastructure has been repainted, reassigned, fenced, patched and renamed for decades. Old markings remain visible beneath new systems. Memory suppression becomes physical: scrubbed plaques, painted-over route numbers, blank ad panels and replacement asset tags. Strong environmental storytelling. Risk: without discipline, layered decay becomes visual noise.

## CANDIDATE — CIVIC SALVAGE PALIMPSEST

The preferred direction combines A + B + C.

> **Visual thesis:** Gears District is a city that keeps repainting its failures instead of fixing them.

It is not a futuristic neon slum. It is a functioning industrial district maintained by institutions that are competent enough to keep machinery moving, corrupt enough to monetize every breakdown, and bureaucratic enough to issue a form explaining why the breakdown is compliant.

The player should read three things immediately from the retained elevated camera:

1. **Where can I move?** Streets, alleys, gates and route choices have strong value and shape separation.
2. **Whose territory/system is this?** Municipal, utility, corporate, commercial and criminal spaces have distinct graphic families.
3. **What happened here?** Repairs, overwritten signage, repurposed structures and removed records expose the district's history without exposition.

The supplied FB-13 visual reference is the micro-scale identity anchor: worn off-white casing, charcoal structural mass, sparse signal cyan, repair hardware, stenciled identifiers, practical asymmetry and evidence of continued use. The city should share those principles without simply making buildings look robotic.

---

# 2. Gears District identity

## 2.1 District character

**CANDIDATE:** a dense municipal-industrial district where salvage yards, machine shops, small commerce, utility infrastructure and civic service buildings have grown into each other.

The district should feel older than its current government branding. Institutions repeatedly claim ownership by painting new color bands and installing new plates over older physical systems.

### Avoid

- glass-tower skyline as the default;
- neon on every storefront;
- holograms as ambient decoration;
- random pipes covering every wall;
- uniform rust-orange color grading;
- generic post-apocalypse abandonment;
- empty megablocks built for visual scale rather than gameplay;
- visual clutter that hides road edges, interactables, vehicles or pursuit options.

## 2.2 Massing and verticality

**CANDIDATE grammar:**

- Most street walls: **2–5 storeys**.
- Garages, depots, yards and machine shops: **1–2 storeys** with strong roof equipment.
- Landmark industrial masses: **6–8-storey-equivalent** silos, stacks, cranes, signal towers or civic utility structures rather than conventional skyscrapers.
- Each building cluster gets **one dominant silhouette feature**: water tank, extraction hood, crane boom, duct stack, antenna frame, sign crown, conveyor housing or gantry.
- Height should step rather than form a flat canyon: low yard -> mid industrial block -> one vertical landmark -> low shortcut/service lane.

The skyline should be identifiable as Gears District from silhouette alone: cranes, capped stacks, relay masts, water tanks, municipal service towers and irregular roof plant.

## 2.3 Street hierarchy

Ranges are visual/gameplay targets, not locked engineering dimensions until tested in the retained world scale.

| Route type | CANDIDATE visual width | Function |
|---|---:|---|
| Industrial spine | 20–28 m | Hauler traffic, high-speed pursuit, major intersections |
| Neighborhood/commercial street | 10–16 m | Mixed vehicles, storefront access, tighter turns |
| Service road | 7–10 m | alternate route, loading access, route pressure |
| Vehicle alley / shortcut | 4.5–7 m | Courier Bike or carefully authored vehicle cut-through |
| Foot/service cut | 2.5–4 m | on-foot connection, interactables, back entrances |

### Camera/readability rules

- At major corners, preserve an open **sightline wedge** so the elevated camera can expose the next route before the turn commits.
- Overhead gantries should **frame** a route choice, not cover the player/vehicle for sustained periods.
- Primary road surfaces are visually calmer than sidewalks, walls and yard interiors.
- Alternate routes should advertise themselves through **shape + value + institution graphics**, not tiny text.
- Every important intersection needs a strong orientation object visible before entry: crane, tower, hanging lane board, painted tank, civic arch, large numbered bay or elevated pipe bridge.

## 2.4 Neighborhood transitions inside the first district

These are visual zones, not a commitment to a production map layout.

1. **Scrap Fringe** — porous fencing, piled vehicle shells, hoists, containers, weigh structures, improvised shelters.
2. **Foundry / Logistics Spine** — wider asphalt, gantries, pipe racks, loading blocks, silos, utility crossings, heavy traffic shapes.
3. **Civic Utilities Pocket** — cleaner massing, poured concrete, numbered service doors, official route bands, fenced substations; still patched and aging.
4. **Parts & Permits Strip** — 2–3 storey commercial fronts, awnings, repair bays, pawn/salvage brokers, food counters, document services, small criminal fronts.
5. **Silent Infrastructure Pocket** — reduced signage density, stripped plaques, quieter surfaces and deliberate negative space around the Silent Core / Sister Kael location.

Transitions should happen over one or two blocks through material/graphic changes rather than hard biome borders.

---

# 3. World graphic design system

Graphic design is a primary worldbuilding layer, but gameplay-critical information must not depend on reading paragraphs from the retained camera.

## 3.1 Shared DNA across institutions

All institutional families use variations of:

- a **12-column / modular sign grid**;
- bold numeric identifiers;
- rectangular plates with one clipped or stepped corner;
- tabular asset IDs;
- high-contrast field colors used in blocks, not gradients;
- physical evidence of replacement: old bolt holes, ghost lettering, overpaint, stickers, secondary inspection plates.

This makes the city feel designed by different departments from the same civic history.

## 3.2 Municipal family

**CANDIDATE umbrella institution:** **Civic Continuity Authority (CCA)**.

Visual behavior:

- warm off-white / concrete field;
- faded safety amber;
- dark charcoal type;
- occasional utility teal sub-band;
- large route or facility numbers;
- official seal based on nested brackets / ledger blocks rather than a literal gear icon.

Example departments, all **PROPOSED names** until narrative approval:

- Department of Material Recovery
- Office of Civic Memory Hygiene
- Traffic & Access Bureau
- Municipal Reclamation Service
- Public Signal & Load
- Office of Temporary Conditions

The joke is administrative certainty applied to absurd conditions, not random comedy signage.

## 3.3 Utility / infrastructure family

- teal identification bands on dark or galvanized equipment;
- white stencil IDs;
- highly legible arrows and pipe/circuit route numbers;
- hazard amber only at actual moving/electrical edges;
- maintenance dates crossed out and replaced by hand;
- phase/load diagrams that look plausible even when the public-facing language is ridiculous.

## 3.4 Echotel corporate family

**CANDIDATE:** Echotel should contrast the municipality rather than look like another cyberpunk megacorp.

- nicotine ivory / warm cream surfaces;
- restrained burgundy or oxblood brand field;
- cleaner geometry and better-maintained hardware;
- elegant but slightly dated telecom/hospitality typography;
- warm white practical illumination instead of cyan neon;
- corporate messaging about comfort, continuity and forgetting inconvenience.

Echotel should look expensive enough to promise privacy and old enough to have participated in whatever the city buried.

## 3.5 Commerce and criminal businesses

Commercial identity is local, opportunistic and materially cheap:

- one large readable storefront name or pictogram;
- hand-painted secondary pricing/service text;
- reused official sign blanks flipped, cut down or overpainted;
- old municipal vehicle panels turned into awnings/counters;
- permit stickers accumulated near doors;
- criminals spoof civic graphic conventions because looking official is cheaper than hiding.

Do not make every criminal business skulls, graffiti and red lights. Many should look like tax-compliant small businesses until the player knows what they sell.

## 3.6 Environmental satire copy bank

**PROPOSED, non-canon copy examples:**

- `CONTINUITY IS CONVENIENCE`
- `REPORT UNLICENSED MEMORY RETENTION`
- `TEMPORARY ROAD CONDITION // RENEWED ANNUALLY`
- `PUBLIC SALVAGE IS PRIVATE PROPERTY UNTIL AUCTION`
- `QUEUE HERE TO AVOID DELAY`
- `YOUR ROUTE HAS BEEN IMPROVED // CONTINUE AS INSTRUCTED`
- `NOTICE OF NOTICE // POSTING CONFIRMED`
- `PERSONAL RECOLLECTION MAY AFFECT ELIGIBILITY`
- `ECHOTEL // STAY CONNECTED. FORGET THE DETAILS.`

Copy should punch upward at institutions and systems, not at ordinary workers.

---

# 4. Palette, materials and surface rules

## 4.1 Core palette

**CANDIDATE palette; values may be tuned in-engine for lighting and accessibility.**

| Role | Hex | Use |
|---|---|---|
| Soot charcoal | `#182126` | deep structure, machinery, readable negative mass |
| Worn off-white | `#D7D2C3` | civic plates, FB-13-adjacent industrial shells, signage |
| Municipal concrete | `#827F73` | dominant neutral architecture |
| Oxidized iron | `#8A4F37` | localized exposed metal / age, not global tint |
| Faded safety amber | `#D39A2C` | hazards, route emphasis, municipal accents |
| Utility teal | `#2F7778` | infrastructure coding, secondary civic system |
| Warning vermilion | `#D24B3A` | fresh danger / enforcement; scarce |
| HS-7 signal cyan | `#7CCFD0` | memory/signal events only; scarce and meaningful |
| Echotel oxblood | `#682F38` | corporate identity |

### Saturation rule

The city is mostly neutral and material-driven. Saturated color is information. If everything glows, HS-7 and active infrastructure lose authority.

## 4.2 Concrete

- large tonal patches and repair seams are more important than micro-crack noise;
- edges accumulate grime where water/mechanical contact makes sense;
- civic structures can retain old painted bands beneath newer ones;
- avoid uniform procedural grunge.

## 4.3 Painted / rusted metal

- paint should read as a **large color block first**, wear second;
- exposed rust is concentrated at edges, fasteners, drainage paths and impact zones;
- keep enough intact paint for institution colors to remain legible;
- no orange-rust wash over every metal surface.

## 4.4 Asphalt and road surfaces

- primary lanes are lower-frequency than surrounding sidewalks/yards;
- patches, oil and repairs create navigation memory but should not compete with lane edges;
- old route paint can ghost beneath current markings;
- service alleys can carry more patchwork and material change.

## 4.5 Industrial plastic / composite

- dirty desaturated black, cream, teal or amber housings;
- sun-faded top planes and polished contact edges;
- useful for newer meters, barriers, utility cabinets and temporary civic hardware.

## 4.6 Glass

- scarce in industrial blocks;
- dirty, wired, tinted or partly covered in signage;
- Echotel and selected civic offices may use cleaner glass to communicate institutional privilege.

## 4.7 Salvage materials

Salvage should reveal provenance: recognizable vehicle panel, duct section, appliance shell, sign substrate or structural member. Prefer a few legible source forms over shapeless junk noise.

---

# 5. Lighting and weather

## Day

**CANDIDATE:** warm-grey daylight with enough directional shape to separate roofs, roads and walls. Light industrial haze is acceptable; heavy cinematic fog is not the baseline.

- clear dark vehicle/person silhouettes against mid-value ground;
- shadows support route edges instead of turning alleys into unreadable black holes;
- colored paint remains subdued but identifiable.

## Night

Night identity is **practical light**, not neon cityscape:

- sodium/amber street and yard pools;
- cool-white utility fluorescents;
- warm Echotel signage/interiors;
- occasional red enforcement/closure lights;
- HS-7 cyan reserved for signal/memory phenomena and a small number of related devices.

Target: emissive surfaces should normally occupy only a small fraction of the frame. A meaningful HS-7 event should be able to change the visual hierarchy instantly.

## Rain / wet surfaces

- road values drop darker;
- current lane paint, oil and metal edges pick up highlights;
- reflections are broken and rough, not mirror streets;
- standing water appears in drainage logic and damaged low spots;
- emissive intensity should not be cranked simply because surfaces are wet.

Rain should make navigation markings and institutional color more graphic, not turn Gears into neon cyberpunk.

---

# 6. HUD and typography relationship

## IMPLEMENTED boundary

Retain the single safe-area MissionHUD contract, mission ownership handoff, touch transparency and existing input behavior. This package does not authorize a replacement HUD system.

## CANDIDATE visual relationship

The HUD should feel like the **clean digital source template** from which the city's physical bureaucracy descended.

- Mission title: condensed civic display face, strong uppercase hierarchy.
- Objective: clean high-contrast sans; minimal ornament.
- Contact / dispatch text: humanist sans or restrained monospace depending on speaker/system.
- IDs, timestamps, HS-7 payload fragments: tabular monospace.
- Section dividers and status pills borrow the city's clipped-corner plate geometry.
- One municipal amber / utility teal accent can represent ordinary system state.
- HS-7 cyan is used only when memory/signal content is actually involved.

Physical signs are weathered, layered and patched versions of the same base design logic. HUD stays cleaner for readability.

### Typography implementation rule

Choose open-license typefaces only after an actual font/license/performance review. Direction is defined by **classification and hierarchy**, not by silently locking a third-party font at concept stage.

---

# 7. Silhouette rules

All hero silhouettes should pass a flat single-color readability check at retained gameplay camera distance.

## Vehicles

- Use a strong **three-mass read**: front / cabin-rider / rear utility mass.
- Courier Bike: narrow forward needle + exposed rider zone + oversized practical rear cargo/signal spine.
- Scrap Hauler: high blunt cab + long low load bed + exposed rear mechanical mass.
- Municipal service vehicles: roof beacon/bar + square utility body + visible side/rear tool modules.
- Civilian cars should be simpler so mission/municipal silhouettes dominate.

## Workers / pedestrians

- recognizable upper-body block: vest, shoulder tool, apron, hood, hard shell or large carried object;
- profession reads from silhouette before clothing texture;
- avoid thin antennas, straps or accessories as the only identity cue.

## Municipal equipment

- stable geometric base + one obvious function: barrier arm, lift, reel, camera mast, clamp, scanner or service boom;
- official equipment tends toward symmetrical base forms; repaired equipment can become asymmetric.

## Salvage machinery

- one dominant moving limb or jaw;
- asymmetry encouraged;
- keep the operational axis visually obvious from above.

## Props

Use a **hero / support / debris** hierarchy. One large form, one or two medium supporting forms, then restrained small debris. Do not solve density by scattering hundreds of equal-weight objects.

## Landmarks

Each landmark needs:

1. a unique roofline or vertical silhouette;
2. one institution-color block or large numeric marker;
3. one spatial function the player learns (turn, shortcut, garage, shrine, yard, crossing).

---

# 8. Five key-location concepts

These are designed as one system test, not five unrelated illustrations.

## 8.1 Current scrapyard — **Recovery Lot 13**

**Status:** CANDIDATE visual concept; name PROPOSED.

### Role
The district's open wound and the place where salvage economy, current gameplay systems and FB-13 visual DNA are most concentrated.

### Composition
- low perimeter of mismatched corrugated fencing and containers;
- recognizable weigh/inspection structure near the public entrance;
- one tall scrap crane / hoist arm as the long-range silhouette;
- existing tuner mast, extraction housing, gate and ramp concepts are visually integrated as sub-areas rather than isolated prototype props;
- stacked recognizable vehicle/industrial components form enclosure without blocking the camera.

### Graphic layer
- huge `13` bay/lot identifier visible from the road;
- Department of Material Recovery plates underneath hand-painted salvage pricing;
- auction tags, quarantine stripes and crossed-out custody labels.

### Color
Charcoal + off-white + oxidized iron, with amber hazard paint. HS-7 cyan appears only during memory/signal activity.

### Environmental joke
Official signage carefully distinguishes `RECOVERABLE MATERIAL`, `CIVIC MATERIAL`, and `MATERIAL PENDING OWNERSHIP` even though all three piles visibly contain the same junk.

## 8.2 Mayor Burn's garage — **Burn Civic Mobility & Recovery**

**Status:** CANDIDATE visual concept; business name PROPOSED.

### Role
A plausible repair/salvage garage that is also a political machine, chop shop and municipal favor exchange.

### Composition
- 1–2 storey former civic fleet-service building;
- broad bent canopy visible from the elevated camera;
- two deep garage bays with different doors and strong interior darkness;
- one oversized retired municipal vehicle panel repurposed as the shop sign;
- roofline clutter kept to one memorable stack/vent + campaign-style sign frame.

### Graphic layer
Old municipal fleet markings remain beneath Burn's branding. Campaign-style language and repair-shop pricing coexist on the same substrates.

### Color
Faded municipal amber, dirty cream, charcoal, one oxblood/red political accent.

### Environmental joke
A pristine sign reads `ETHICAL FLEET DISPOSITION` over a bay full of visibly re-numbered parts.

## 8.3 Sister Kael / Silent Core shrine — **The Quiet Relay**

**Status:** CANDIDATE visual concept; location nickname PROPOSED.

### Role
Mystery through absence. This must not read as a glowing sci-fi temple.

### Composition
- former municipal relay/pump/substation structure in heavy concrete;
- central cylindrical or faceted service core partly exposed by removed wall panels;
- cables and analog patch leads arranged with ritual care, but all components remain plausibly infrastructural;
- scraped-off department seal leaves a large ghost shape on the wall;
- open negative space around the interactable so the Action target remains unmistakable from the retained camera.

### Graphic layer
Numbered archive plates, handwritten dates, removed inventory labels, blanked civic notices. Sister Kael adds small physical tags rather than mystical symbols everywhere.

### Color / light
Almost all concrete, charcoal and old paper. Low warm work light. HS-7 cyan appears in a narrow core seam/cable response only when the Memory Echo is active.

### Environmental joke/mystery
A municipal plaque has been mechanically ground blank except for the line `RECORD RETENTION REQUIREMENT:`.

## 8.4 Major industrial intersection — **Compliance Junction 4**

**Status:** CANDIDATE visual concept; name PROPOSED.

### Role
The visual stress test for navigation, pursuit and alternate-route readability.

### Composition
- offset four-way industrial crossroads;
- overhead utility gantry frames but does not cover the central play area;
- one elevated pipe/conveyor bridge sits farther back as a skyline anchor;
- clear major road, service road and narrow cut-through each have different ground/value treatment;
- traffic islands/equipment are chunky and sparse enough for high-speed reading;
- a crane or capped stack gives the turn a long-range identifier.

### Graphic layer
Large hanging lane boards, giant `4` asset marker, current and ghost road arrows, temporary closure panels, utility route bands.

### Route language
- Main road = broad dark asphalt + off-white/amber lane logic.
- Service alternate = concrete/patchwork + teal utility band.
- Shortcut = narrower opening framed by salvaged metal and a distinct amber/black edge marker.

The player should understand the three choices without reading any small text.

## 8.5 Commercial street — **Parts & Permits Row**

**Status:** CANDIDATE visual concept; street nickname PROPOSED.

### Role
Shows that Gears is inhabited, funny and economically active rather than an endless factory yard.

### Composition
- 2–3 storey narrow mixed concrete/brick/metal fronts;
- frequent garage-width storefront modules;
- awnings and blade signs kept below the main camera sightline;
- one or two cross-block alleys visibly pierce the street wall;
- roof utilities and cable bundles make an irregular but readable silhouette;
- parked cargo, hand carts and service vehicles create activity without sealing routes.

### Businesses
PROPOSED examples:

- permit expediter / document fixer;
- used motor and battery shop;
- salvage jewelry / small-parts broker;
- late food counter built into an old utility kiosk;
- pawn / memory-media reseller;
- legitimate courier storefront that quietly sells route access.

### Graphic layer
Each frontage gets one bold identity color/sign plus smaller accumulated permit stickers. Criminal fronts deliberately borrow official visual language.

### Environmental joke
A storefront advertises `EXPRESS PERMITS // NO APPOINTMENT // NO QUESTIONS THAT REQUIRE AN APPOINTMENT`.

---

# 9. Engineering-facing visual constraints

If this package becomes APPROVED, world production should implement these as testable art/readability constraints rather than as a requirement for exact concept geometry.

1. **Route-first composition.** Player/vehicle path and road-edge readability outrank decorative density.
2. **Large-form identity.** Buildings and props must read by massing before textures or decals.
3. **Landmark cadence.** Important traversal segments should expose a recognizable landmark or institutional cue often enough that the player can build a mental map without a GPS dependency.
4. **Intersection legibility.** Major route choices must be understandable through opening width, ground treatment, large markings and silhouette; small sign text is supplementary.
5. **Sparse emissive hierarchy.** Ordinary night lighting is practical amber/white. Teal is infrastructure. HS-7 cyan is rare and event-significant.
6. **Material restraint.** Rust, grime, decals and repair history are localized by physical cause. Avoid uniform grunge.
7. **Graphic budget.** One primary readable sign/number per frontage or major asset, then secondary detail. Do not wallpaper surfaces with text.
8. **Silhouette test.** Hero vehicles, equipment and landmarks should remain distinguishable in a flat-value gameplay-distance capture.
9. **Camera protection.** Tall props, awnings and overhead structures cannot create sustained player/vehicle occlusion on retained primary routes.
10. **Performance discipline.** Prefer modular low/medium-complexity forms, instancing/reuse where appropriate and decals/material variation over dense unique geometry. Measure before increasing detail.
11. **Gameplay surfaces stay calm.** High-frequency debris and graphic noise belong mainly outside the drivable/walkable decision surface.
12. **Institution consistency.** A new sign/vehicle/prop should declare which visual family owns it: municipal, utility, Echotel, local commerce/criminal, or HS-7/memory.
13. **No silent canon expansion.** Department/business/street names in this package remain PROPOSED until narrative approval.
14. **No GTA copying.** Reference GTA-family games only for readability, immediacy, density and navigation lessons; all art, brands, map geometry, typography, signage, characters and writing remain original.

---

# 10. Concept-art validation checklist

A concept image is useful only if it answers implementation questions.

For each key-location concept, review at least:

- Does the route remain obvious at elevated 3/4 distance?
- Is the location identifiable in silhouette/value before reading text?
- Can we tell which institution/business family owns the space?
- Is there one memorable landmark rather than undifferentiated clutter?
- Are primary, alternate and shortcut paths visually distinct where applicable?
- Does the palette preserve HS-7 cyan as a scarce signal?
- Does the scene look inhabited/maintained rather than generically abandoned?
- Does the satire emerge from plausible civic/commercial design?
- Could the scene be built from modular Godot assets without unreasonable unique-asset cost?
- Does any decorative element threaten camera, touch, vehicle or mission readability?

---

# 11. Approval gate

## CANDIDATE recommendation

Adopt **Civic Salvage Palimpsest** as the district visual thesis and use the five key-location concepts as the first shared concept-art test set.

## Approval effect

If owner-approved, promote the relevant CANDIDATE sections to **APPROVED visual canon**, record any requested changes, then create the just-in-time implementation ticket for **Open World Expansion 01 — Gears District**.

Until then:

- do not start detailed Gears District production planning;
- do not replace retained camera/HUD/gameplay systems speculatively;
- do not treat proposed department/business/location names as canon;
- concept work may iterate freely within this package.
