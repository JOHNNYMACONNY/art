#!/usr/bin/env python3
"""
scripts/composite_chatgpt_storefront_atlas.py
Bakes godot/textures/urban_clutter/tex_storefront_burnside.png (2048x2048)
using 100% dedicated, standalone ChatGPT-generated high-resolution assets.
Zero crops from concept art overview sheets.
"""

from PIL import Image, ImageDraw
import numpy as np
import os

atlas = Image.new("RGBA", (2048, 2048), (24, 22, 20, 255))

# =============================================================================
# ZONE 1: FASCIA SIGNBOARD (20, 20) -> (1220, 320) [1200 x 300]
# =============================================================================
# chatgpt_gen_fascia_sign.png is 2172 x 724 (3:1 panoramic aspect ratio)
fascia_raw = Image.open("docs/visual_direction/references/chatgpt_gen_fascia_sign.png")
fascia_scaled = fascia_raw.resize((1200, 300), Image.Resampling.LANCZOS)
atlas.paste(fascia_scaled, (20, 20))

# =============================================================================
# ZONE 1b: HAZARD STRIPES STRIP (20, 324) -> (1220, 356) [1200 x 32]
# =============================================================================
# Dedicated standalone ChatGPT generation: docs/visual_direction/references/hazard_strip_isolated.png (2140 x 275)
hazard_raw = Image.open("docs/visual_direction/references/hazard_strip_isolated.png")
hazard_strip = hazard_raw.resize((1200, 32), Image.Resampling.LANCZOS)
atlas.paste(hazard_strip, (20, 324))

# =============================================================================
# ZONE 2: ROOFTOP BILLBOARD "LUNG-RENEW 4.0" (1240, 20) -> (2028, 460) [788 x 440]
# =============================================================================
# chatgpt_gen_billboard.png is 1672 x 941 (16:9 widescreen)
billboard_raw = Image.open("docs/visual_direction/references/chatgpt_gen_billboard.png")
billboard_scaled = billboard_raw.resize((788, 440), Image.Resampling.LANCZOS)
atlas.paste(billboard_scaled, (1240, 20))

# =============================================================================
# ZONE 3: ROLL-UP GARAGE DOOR CURTAIN (20, 360) -> (780, 610) [760 x 250]
# =============================================================================
# chatgpt_gen_garage_shutter.png is 1536 x 1024
shutter_raw = Image.open("docs/visual_direction/references/chatgpt_gen_garage_shutter.png")
shutter_scaled = shutter_raw.resize((760, 250), Image.Resampling.LANCZOS)
atlas.paste(shutter_scaled, (20, 360))

# =============================================================================
# ZONE 3b: WORKSHOP INTERIOR BACKDROP (20, 620) -> (780, 980) [760 x 360]
# =============================================================================
# Standalone generation: chatgpt_gen_workshop_interior.png (1659 x 948)
bay_raw = Image.open("docs/visual_direction/references/chatgpt_gen_workshop_interior.png")
bay_scaled = bay_raw.resize((760, 360), Image.Resampling.LANCZOS)
atlas.paste(bay_scaled, (20, 620))

# =============================================================================
# ZONE 4: SERVICE ENTRANCE DOOR (820, 360) -> (1240, 980) [420 x 620]
# =============================================================================
# chatgpt_gen_service_door_exact.png (1032 x 1524, 1:1.48 aspect ratio)
door_raw = Image.open("docs/visual_direction/references/chatgpt_gen_service_door_exact.png")
door_scaled = door_raw.resize((420, 620), Image.Resampling.LANCZOS)
atlas.paste(door_scaled, (820, 360))

# Neon OPEN sign sub-rect for emissive mesh (885, 805) -> (1175, 905)
neon_raw = Image.open("docs/visual_direction/references/neon_open_isolated.png")
neon_scaled = neon_raw.resize((290, 100), Image.Resampling.LANCZOS)
atlas.paste(neon_scaled, (885, 805))

# =============================================================================
# ZONE 5: RIGHT SIDE WALL STENCILS & MASONRY (1260, 480) -> (1680, 1000) [420 x 520]
# =============================================================================
# chatgpt_gen_brick_wall.png is 1448 x 1086 (soot brick, "SCRAP REBUILDS KEEPS CITIES ALIVE", conduits, meters)
wall_raw = Image.open("docs/visual_direction/references/chatgpt_gen_brick_wall.png")
wall_scaled = wall_raw.resize((420, 520), Image.Resampling.LANCZOS)
atlas.paste(wall_scaled, (1260, 480))

# =============================================================================
# ZONE 5b: FRONT PILLAR POSTER "A CLEANER BRIGHTER STRONGER" (1690, 480) -> (1860, 1000) [170 x 520]
# =============================================================================
# Standalone generation: docs/visual_direction/references/pillar_poster_isolated.png (680 x 2081, 1:3.06)
poster_raw = Image.open("docs/visual_direction/references/pillar_poster_isolated.png")
poster_scaled = poster_raw.resize((170, 520), Image.Resampling.LANCZOS)
atlas.paste(poster_scaled, (1690, 480))

# =============================================================================
# ZONE 5c: ROOF PARAPET STENCIL "MOVEMENT KEEPS CITIES ALIVE" (1870, 750) -> (2028, 1000) [158 x 250]
# =============================================================================
# chatgpt_gen_sign_parapet_exact.png is 1586 x 992
parapet_raw = Image.open("docs/visual_direction/references/sign_parapet_isolated_alpha.png")
parapet_scaled = parapet_raw.resize((158, 250), Image.Resampling.LANCZOS)
atlas.paste(parapet_scaled, (1870, 750), parapet_scaled if parapet_scaled.mode == 'RGBA' else None)

# =============================================================================
# ZONE 6: SIGNAL QUOTA KIOSK (20, 1020) -> (720, 1600) [700 x 580]
# =============================================================================
# chatgpt_gen_quota_kiosk.png is 948 x 1659
kiosk_raw = Image.open("docs/visual_direction/references/chatgpt_gen_quota_kiosk.png")
kiosk_scaled = kiosk_raw.resize((700, 580), Image.Resampling.LANCZOS)
atlas.paste(kiosk_scaled, (20, 1020))

# Quota screen inset at (60, 1060) -> (680, 1340) [620 x 280]
# Standalone generation: docs/visual_direction/references/chatgpt_gen_kiosk_screen_exact.png (1866 x 843, 2.21:1)
screen_raw = Image.open("docs/visual_direction/references/chatgpt_gen_kiosk_screen_exact.png")
screen_scaled = screen_raw.resize((620, 280), Image.Resampling.LANCZOS)
atlas.paste(screen_scaled, (60, 1060))

# =============================================================================
# ZONE 7: SCRAP DUMPSTER (740, 1020) -> (1420, 1600) [680 x 580]
# =============================================================================
# chatgpt_gen_scrap_dumpster.png is 1536 x 1024
dumpster_raw = Image.open("docs/visual_direction/references/chatgpt_gen_scrap_dumpster.png")
dumpster_scaled = dumpster_raw.resize((680, 580), Image.Resampling.LANCZOS)
atlas.paste(dumpster_scaled, (740, 1020))

# =============================================================================
# ZONE 8: UTILITY POLE SIGNS & HV BOX (1440, 1020) -> (2028, 1600) [588 x 580]
# =============================================================================
pole_canvas = Image.new("RGBA", (588, 580), (32, 34, 38, 255))

# High voltage box (260 x 320) at (1470, 1270) relative to atlas -> (30, 250) on canvas
hv_raw = Image.open("docs/visual_direction/references/plate_hv_isolated_alpha.png")
hv_scaled = hv_raw.resize((260, 320), Image.Resampling.LANCZOS)
pole_canvas.paste(hv_scaled, (30, 240), hv_scaled if hv_scaled.mode == 'RGBA' else None)

# Street sign "ASHFORD AVE" (260 x 100) at (1470, 1050) relative to atlas -> (30, 30) on canvas
ashford_raw = Image.open("docs/visual_direction/references/sign_ashford_isolated_alpha.png")
ashford_scaled = ashford_raw.resize((260, 100), Image.Resampling.LANCZOS)
pole_canvas.paste(ashford_scaled, (30, 20), ashford_scaled if ashford_scaled.mode == 'RGBA' else None)

# Street sign "DISTRICT 13" (260 x 90) at (1470, 1160) relative to atlas -> (30, 140) on canvas
dist13_raw = Image.open("docs/visual_direction/references/sign_dist13_isolated_alpha.png")
dist13_scaled = dist13_raw.resize((260, 90), Image.Resampling.LANCZOS)
pole_canvas.paste(dist13_scaled, (30, 130), dist13_scaled if dist13_scaled.mode == 'RGBA' else None)

atlas.paste(pole_canvas, (1440, 1020))

# =============================================================================
# BOTTOM ROW: SEAMLESS MATERIAL TILES (Y: 1620 to 2048)
# =============================================================================
# 1. Soot Terracotta Brick Wall (0 to 680, 1620 to 2048) [680 x 428]
# Standalone generation: docs/visual_direction/references/chatgpt_gen_brick_seamless_exact.png (1254 x 1254)
brick_raw = Image.open("docs/visual_direction/references/chatgpt_gen_brick_seamless_exact.png")
brick_tile = brick_raw.resize((680, 428), Image.Resampling.LANCZOS)
atlas.paste(brick_tile, (0, 1620))

# 2. Corrugated Metal (680 to 1360, 1620 to 2048) [680 x 428]
# Standalone generation: docs/visual_direction/references/chatgpt_gen_corrugated_metal_exact.png (1254 x 1254)
corr_raw = Image.open("docs/visual_direction/references/chatgpt_gen_corrugated_metal_exact.png")
corr_tile = corr_raw.resize((680, 428), Image.Resampling.LANCZOS)
atlas.paste(corr_tile, (680, 1620))

# 3. Scrap Metal (1360 to 1700, 1620 to 2048) [340 x 428]
# Standalone generation: docs/visual_direction/references/chatgpt_gen_scrap_metal_exact.png (1254 x 1254)
scrap_raw = Image.open("docs/visual_direction/references/chatgpt_gen_scrap_metal_exact.png")
scrap_tile = scrap_raw.resize((340, 428), Image.Resampling.LANCZOS)
atlas.paste(scrap_tile, (1360, 1620))

# 4. Road Stencil "GEARS DISTRICT GD-13" (1700 to 2048, 1620 to 2048) [348 x 428]
road_canvas = Image.new("RGBA", (348, 428), (38, 40, 44, 255))
# Use clean stencil from district 13 plate or road stencil
road_stencil = dist13_scaled.resize((320, 80), Image.Resampling.LANCZOS)
road_canvas.paste(road_stencil, (14, 174))
atlas.paste(road_canvas, (1700, 1620))

# =============================================================================
# PALETTE ACCENT SWATCHES (X: 2002 to 2046)
# =============================================================================
swatches = [
    (2002, 2, 2046, 48, (28, 30, 34, 255)),      # dark_metal
    (2002, 52, 2046, 98, (48, 52, 58, 255)),     # structural_steel
    (2002, 102, 2046, 148, (245, 196, 0, 255)),  # yellow_accent
    (2002, 152, 2046, 198, (255, 220, 160, 255)),# warm_light
    (2002, 202, 2046, 248, (22, 24, 26, 255)),   # tar_roof
    (2002, 252, 2046, 298, (120, 122, 125, 255)),# concrete_curb
    (2002, 302, 2046, 348, (107, 58, 36, 255)),  # terracotta_brick
    (2002, 352, 2046, 398, (15, 15, 18, 255)),   # contact_shadow
    (2002, 402, 2046, 438, (131, 37, 26, 255)),  # red_tool_cabinet (sampled exact Snap-on red)
    (2002, 442, 2046, 478, (220, 215, 195, 255)),# weathered_cream
]
draw = ImageDraw.Draw(atlas)
for x1, y1, x2, y2, color in swatches:
    draw.rectangle([x1, y1, x2, y2], fill=color)

os.makedirs("godot/textures/urban_clutter", exist_ok=True)
atlas.save("godot/textures/urban_clutter/tex_storefront_burnside.png")
print("Saved 100% standalone ChatGPT atlas to godot/textures/urban_clutter/tex_storefront_burnside.png")
