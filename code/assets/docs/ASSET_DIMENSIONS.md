# OPTIMAL SPRITE & ASSET DIMENSIONS — ECHOES IN THE SCRAPHEAP

For a 960x540 canvas retro pixel-art aesthetic (matching the canvas scale), here are the exact optimal pixel dimensions and grid metrics for every category:

## 1. Character Sprites (Sheet format: horizontal strip of walk/action frames)
- **JMac (Player)**: `24 × 24` px per frame (4-frame walk strip: `96 × 24` px total)
- **FB-13 (Companion Drone)**: `16 × 16` px per frame (4-frame float strip: `64 × 16` px)
- **HS-7 (Core Module)**: `16 × 16` px (static/pulsing 2-frame strip: `32 × 16` px)
- **Civilians & Police**: `24 × 24` px per frame (4-frame animation strip: `96 × 24` px)
- **NPC Portraits (Dialogue)**: `64 × 64` px individual portraits (Burn, Lira, Kael)

## 2. Vehicles (Top-down / 3/4 angle)
- **Mayor Burn's Sedan / Police Cruiser**: `48 × 32` px (supports rotation or 4 directional headings)
- **Courier Bike / Transport**: `36 × 24` px

## 3. Environment Tiles & Structures
- **World Ground Tiles**: `32 × 32` px seamless tiles (asphalt, concrete, rust plates)
- **Building Footprints**: Multiples of 32px (e.g., Garage: `160 × 128` px, Relay Station: `128 × 96` px)

## 4. UI, HUD & Particles
- **HUD HP Bar Container**: `180 × 14` px
- **Dialogue Panel**: `780 × 110` px
- **Projectiles / Particles**: `6 × 6` px (tracers, sparks)
