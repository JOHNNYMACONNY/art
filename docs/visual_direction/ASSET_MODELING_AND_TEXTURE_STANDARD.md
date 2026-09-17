# 3D Asset Modeling & Texturing Production Standard

**Authority**: Immutable Project Rule for all 3D assets, vehicles, architecture, clutter, and scene geometry.

---

## 1. Core Mandate: Authentic Geometry & Form Sculpting

**BANNED**: Axis-aligned box primitives, stacked cubes, and un-beveled sharp edges masquerading as vehicles, props, or architecture.

### Video Game Industry / GTA-Grade Modeling Rules
1. **Lofted & Sculpted Cross-Sections**:
   - Every vehicle, body panel, mechanical component, or organic form must use progressive, lofted cross-sections with authentic silhouette curves (hood sweep, tumblehome / cabin inward taper, fastback rake, wheel arches, fender flares).
   - Just like the Courier Bike (`scripts/blender_build_bike.py`), which sculpted a curved 24-segment crowned tire, knobby lugs, crossed wire spokes, and a 6-ring hourglass fuel tank, all cars and vehicles must be modeled part-by-part with authentic automotive anatomy.
2. **Wheel Arches & Recessed Running Gear**:
   - Cars must have sculpted semicircular wheel wells with outward-flared fender lips.
   - Wheels (tires, rims, hubs, brake rotors/calipers) sit recessed inside the chassis wells under realistic suspension clearance.
3. **Beveled & Chamfered Edge Profiles**:
   - Hard 90-degree polygonal creases are prohibited on exterior bodywork and structural props. All vehicle body panels, bumper covers, windshield headers, and pillars must use multi-segment chamfers or bevels to catch cel-shading light steps.
4. **Separated Articulated Sub-Meshes**:
   - High-fidelity components (push bars, lightbars, exhaust manifolds, superchargers/blowers, grilles, spoilers, mirrors, spotlights) must be modeled as distinct volumetric assemblies, not flat decals painted onto a box face.

---

## 2. Texturing & UV Projection Standards (Open-World GTA / Industry Pipeline)

**NEVER slap a flat 2D concept drawing of a vehicle onto a 3D car mesh.**
Slapping 2D illustrations with pre-baked shadows, pre-drawn wheels, pre-drawn windows, and fake perspective onto curved 3D geometry causes texture stretching, misalignment, and lighting conflict.

### The 4-Part Modular Game Industry Vehicle Pipeline:

1. **Multi-Material Body Setup (Zero Giant Painted Car Pictures)**:
   Vehicles must be split into dedicated material slots by surface type:
   - `Mat_Paint` (Car Body): True automotive paint shader. Color, metallic flake, and roughness handled by material parameters / Godot cel shader. Base paint color is dynamic and un-polluted by painted shadows.
   - `Mat_Glass` (Windshield, Side Windows, Rear Glass): Dedicated dark-tinted or polarized glass material with crisp specular reflection and subtle transparency. Never a flat gray texture drawn on metal.
   - `Mat_Rubber` (Tires): Matte dark charcoal rubber material (`#141517`) with cylindrical geometry and optional tileable tread texture.
   - `Mat_Chrome` / `Mat_Steel` (Rims, Bumpers, Exhaust Pipes, Bullbars, Roll Cages): High metallic (`0.85`), low roughness (`0.25`) shader catching real specular highlights.
   - `Mat_Interior` (Cabin, Dashboard, Seats): Dark matte recessed geometry visible through window glass.
   - `Mat_Emissive` (Headlights, Taillights, Lightbar Strobes): Dedicated self-illuminating glass lenses with emission energy.

2. **UV Seams Cut Along Real Metal Seams**:
   - UV seams in Blender must strictly follow real automotive panel cuts: hood gaps, door shut lines, front/rear bumper covers, trunk lids, and roof rails.
   - Panels unwrap flat without distortion, exactly like industrial sheet-metal stamping patterns.

3. **Shared Vehicle Trim Sheet (`tex_vehicle_trim.png`)**:
   Small, high-detail automotive components across all vehicles share a unified 1024x1024 trim sheet:
   - Headlight reflectors and glass lenses (quad round, rectangular, projector).
   - Taillight ribbed lenses (red brake, amber indicator, white reverse).
   - Radiator grille mesh (hex honeycomb, horizontal steel slats, heavy industrial wire).
   - Municipal license plates ("SCRAP-8", "DZ-03", "UNIT-09").
   - Badges, manufacturer logos, and dashboard gauges.
   - Geometry maps directly to the corresponding UV quadrant of the trim sheet.

4. **Decal & Livery Layer (Secondary UV Channel / Decal Mask)**:
   - Racing stripes, fleet numbers ("07", "03", "09"), municipal satire stencils ("CIVIC DEBT ENFORCEMENT // PROTECT & INVOICE", "BURNSIDE SCRAP HAULAGE"), and hazard chevrons are stored as **pure vector decals on 100% transparent PNGs**.
   - **STRICT BAN on Pre-Baked 3D Shading in Decals**: Decals must contain ZERO painted drop shadows, ZERO fake lighting gradients, ZERO pre-drawn windows, and ZERO pre-drawn wheels.
   - Decal layers blend cleanly over the base `Mat_Paint` in the Godot cel shader via UV2 or texture alpha masking. The underlying 3D geometry and Godot world lighting handle all shading naturally.

---

## 3. Blender 3D Workflow Standard

- All master production models are authored in Blender (`bpy` scripts or direct `.blend` authoring).
- Master scene assets persist in `models_source/*.blend`.
- Game runtime exports persist as glTF 2.0 (`godot/models/*.glb`) with standard PBR / toon material bindings.
- Godot materials bind `gears_toon.gdshader` with two-tone cel shading, anisotropic filtering, negative mipmap bias, and inverted-hull dark comic ink contours.
