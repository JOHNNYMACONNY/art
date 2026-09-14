#!/usr/bin/env python3
"""
scripts/composite_vehicles_atlas.py
Composites dedicated per-vehicle multi-side atlases:
1. tex_muscle_coupe.png (2048x2048)
2. tex_scrap_hauler.png (2048x2048)
3. tex_security_interceptor.png (2048x2048)

Uses 100% standalone ChatGPT generations with pure transparent backgrounds.
Zero manual cropping from overview concept sheets.
"""

from PIL import Image, ImageOps
import os

OUT_DIR = "godot/textures/urban_clutter"
REF_DIR = "docs/visual_direction/references"
os.makedirs(OUT_DIR, exist_ok=True)

def bake_muscle_coupe_atlas():
    atlas = Image.new("RGBA", (2048, 2048), (28, 30, 34, 255))

    # 1. Side Profile (chatgpt_gen_coupe_side_profile.png is 2172x724 RGBA)
    # Paste at top: (0, 0) to (2048, 680)
    side_raw = Image.open(f"{REF_DIR}/chatgpt_gen_coupe_side_profile.png")
    side_scaled = side_raw.resize((2048, 680), Image.Resampling.LANCZOS)
    atlas.paste(side_scaled, (0, 0), side_scaled)

    # 2. Top-Down View (chatgpt_gen_coupe_top_view.png is 887x1774 RGBA)
    # Paste at left bottom: (20, 700) to (1000, 2028) -> size 980 x 1328
    top_raw = Image.open(f"{REF_DIR}/chatgpt_gen_coupe_top_view.png")
    top_scaled = top_raw.resize((980, 1328), Image.Resampling.LANCZOS)
    atlas.paste(top_scaled, (20, 700), top_scaled)

    # 3. Front & Rear Elevations (chatgpt_gen_coupe_front_rear.png is 1254x1254 RGBA)
    # Front is top half, Rear is bottom half
    fr_raw = Image.open(f"{REF_DIR}/chatgpt_gen_coupe_front_rear.png")
    W, H = fr_raw.size
    front_half = fr_raw.crop((0, 0, W, H // 2))
    rear_half = fr_raw.crop((0, H // 2, W, H))

    # Front Elevation: (1040, 700) to (2028, 1340) -> size 988 x 640
    front_scaled = front_half.resize((988, 640), Image.Resampling.LANCZOS)
    atlas.paste(front_scaled, (1040, 700), front_scaled)

    # Rear Elevation: (1040, 1370) to (2028, 2010) -> size 988 x 640
    rear_scaled = rear_half.resize((988, 640), Image.Resampling.LANCZOS)
    atlas.paste(rear_scaled, (1040, 1370), rear_scaled)

    out_path = f"{OUT_DIR}/tex_muscle_coupe.png"
    atlas.save(out_path)
    print(f"Saved baked Muscle Coupe atlas to: {out_path} ({atlas.size})")

def bake_scrap_hauler_atlas():
    atlas = Image.new("RGBA", (2048, 2048), (35, 32, 28, 255))

    # 1. Side Profile (chatgpt_gen_hauler_side_profile.png is 2172x724 RGBA)
    # Paste at top: (0, 0) to (2048, 680)
    side_raw = Image.open(f"{REF_DIR}/chatgpt_gen_hauler_side_profile.png")
    side_scaled = side_raw.resize((2048, 680), Image.Resampling.LANCZOS)
    atlas.paste(side_scaled, (0, 0), side_scaled)

    # 2. Front & Rear Elevations (chatgpt_gen_hauler_front_rear.png is 1254x1254 RGBA)
    fr_raw = Image.open(f"{REF_DIR}/chatgpt_gen_hauler_front_rear.png")
    W, H = fr_raw.size
    front_half = fr_raw.crop((0, 0, W, H // 2))
    rear_half = fr_raw.crop((0, H // 2, W, H))

    # Front Cab: (20, 700) to (1010, 1360) -> size 990 x 660
    front_scaled = front_half.resize((990, 660), Image.Resampling.LANCZOS)
    atlas.paste(front_scaled, (20, 700), front_scaled)

    # Rear Tailgate: (20, 1380) to (1010, 2040) -> size 990 x 660
    rear_scaled = rear_half.resize((990, 660), Image.Resampling.LANCZOS)
    atlas.paste(rear_scaled, (20, 1380), rear_scaled)

    # Hopper Bed Scrap Metal Texture on Right Half (1030, 700) to (2028, 2028) -> 998 x 1328
    scrap_tile_raw = Image.open(f"{REF_DIR}/chatgpt_gen_scrap_metal_exact.png")
    scrap_scaled = scrap_tile_raw.resize((998, 1328), Image.Resampling.LANCZOS)
    atlas.paste(scrap_scaled, (1030, 700))

    out_path = f"{OUT_DIR}/tex_scrap_hauler.png"
    atlas.save(out_path)
    print(f"Saved baked Scrap Hauler atlas to: {out_path} ({atlas.size})")

def bake_security_interceptor_atlas():
    atlas = Image.new("RGBA", (2048, 2048), (24, 28, 36, 255))

    # 1. Side Profile (chatgpt_gen_interceptor_side_profile.png is 2172x724 RGBA)
    # Paste at top: (0, 0) to (2048, 680)
    side_raw = Image.open(f"{REF_DIR}/chatgpt_gen_interceptor_side_profile.png")
    side_scaled = side_raw.resize((2048, 680), Image.Resampling.LANCZOS)
    atlas.paste(side_scaled, (0, 0), side_scaled)

    # 2. Front & Rear Elevations (chatgpt_gen_interceptor_front_rear.png is 1254x1254 RGBA)
    fr_raw = Image.open(f"{REF_DIR}/chatgpt_gen_interceptor_front_rear.png")
    W, H = fr_raw.size
    front_half = fr_raw.crop((0, 0, W, H // 2))
    rear_half = fr_raw.crop((0, H // 2, W, H))

    # Front Fascia & Push Bumper: (20, 700) to (1010, 1360) -> size 990 x 660
    front_scaled = front_half.resize((990, 660), Image.Resampling.LANCZOS)
    atlas.paste(front_scaled, (20, 700), front_scaled)

    # Rear Trunk & Taillights: (20, 1380) to (1010, 2040) -> size 990 x 660
    rear_scaled = rear_half.resize((990, 660), Image.Resampling.LANCZOS)
    atlas.paste(rear_scaled, (20, 1380), rear_scaled)

    # Right Side: High-contrast Roof / Hood Identification Plate & Stencils
    roof_canvas = Image.new("RGBA", (998, 1328), (230, 235, 240, 255))
    strobe_tile = front_half.crop((150, 10, 1100, 120)).resize((900, 120), Image.Resampling.LANCZOS)
    roof_canvas.paste(strobe_tile, (49, 50), strobe_tile if strobe_tile.mode == 'RGBA' else None)

    badge = front_half.crop((400, 150, 854, 350)).resize((600, 260), Image.Resampling.LANCZOS)
    roof_canvas.paste(badge, (199, 300), badge if badge.mode == 'RGBA' else None)

    atlas.paste(roof_canvas, (1030, 700))

    out_path = f"{OUT_DIR}/tex_security_interceptor.png"
    atlas.save(out_path)
    print(f"Saved baked Security Interceptor atlas to: {out_path} ({atlas.size})")

def main():
    bake_muscle_coupe_atlas()
    bake_scrap_hauler_atlas()
    bake_security_interceptor_atlas()
    print("All vehicle multi-surface texture atlases baked successfully!")

if __name__ == '__main__':
    main()
